---
type: reference
project: hawkeye/vsh-alert-collector-api
status: active
date: 2026-04-13
---

# Event Processing Flow

End-to-end flow from Kafka ingestion to Lark notification.

---

## 1. Ingestion — Kafka Consumers

Two background services consume from Kafka topics:

| Consumer | Source | Message Type | Key Behavior |
|----------|--------|-------------|--------------|
| `GrafanaTopicKafkaBackgroundService` | Grafana | `GrafanaMessageDto` | One alert per Grafana message |
| `BitTopicKafkaBackgroundService` | BIT | `BitMessageDto` | Explodes `server_list` — creates one `AlertEvent` **per server** |

Both consumers follow the same pattern via `BaseKafkaConsumerService<T>`:

1. Consume raw Kafka message
2. Deserialize to source-specific DTO (`GrafanaMessageDto` / `BitMessageDto`)
3. Call `IAlertEventAdd` (keyed `"Kafka"`) to persist each alert as an `AlertEvent` entity in PostgreSQL
4. PostgreSQL **NOTIFY trigger** fires on insert → sends `{id}` payload to `alert_events_channel`

---

## 2. Event Listener — PostgreSQL LISTEN/NOTIFY

`EventListenerService` maintains a persistent PostgreSQL connection with `LISTEN alert_events_channel`.

On notification received:
1. Deserialize payload → extract `AlertEvent.Id`
2. Spawn background task (fire-and-forget with cancellation):
   - Create scoped DI container
   - Load `AlertEvent` by ID via `IAlertEventLookup`
   - Skip if `alertEvent.Processed == true` (idempotency guard)
   - Call `EventProcessingService.ProcessEventAsync(alertEvent, correlationId)`

---

## 3. Event Processing Pipeline

`EventProcessingService.ProcessEventAsync` is the core orchestrator. Steps execute in order:

### Step 1 — Map to UnifiedEvent

```
IUnifiedEventMapper.MapAlertEventToUnifiedEvent(alertEvent)
```

Converts the persisted `AlertEvent` entity → `UnifiedEvent` DTO (Application layer record with Labels dictionary, Values dictionary, Source, Severity, etc.).

### Step 2 — Severity Evaluation

```
ISeverityRuleEngine.GetMatchingSeverityRuleAsync(unifiedEvent)
ISeverityRuleEngine.CalculateAlertEventSeverityScoreAsync(unifiedEvent, severityRule)
```

1. Find the first matching `AlertSeverityRule` based on source, labels, and field conditions
2. If matched → calculate severity score using the rule's formula and field weights → produces `SeverityEvaluationDetail` (rule name, field scores, final score, calculated severity)
3. If no match → log and continue (severity remains as-is from ingestion)

### Step 3 — Route to Configured Channels

```
IEventRoutingService.RouteAlertEventAsync(alertEvent)
```

Evaluates all active `AlertEventRoutingRule` entries. For each matching rule:
- Resolve the target notification channel (Lark group, etc.)
- Send via `LarkRoutingNotificationProvider` using `LarkRoutingCardBuilder`
- This path uses `AlertEvent` entity directly (not `UnifiedEvent`)
- Card format is **source-agnostic** — same card for BIT and Grafana

### Step 4 — Lark Notification (Primary Bot)

Branching logic based on event source and status:

```
Is BIT event with state=part_recover or recover?
  YES → SendResolvedEventReplyAsync (reply to original firing card)
  NO  → Is status Firing?
          YES → SendFiringEventNotificationAsync (new card)
          NO  → Is status Resolved?
                  YES → SendResolvedEventReplyAsync (reply to original firing card)
```

#### Firing Path — `SendFiringEventNotificationAsync`

1. Generate card body via `UnifiedEvent.CreateLarkNotificationMessage()` (unified format for all sources)
2. Append `SeverityEvaluationDetail` (if available) or "no matching rule" note
3. Build Lark card with title: `[Source] {StatusEmoji} {AlertTitle}`
4. Send via `ILarkNotification.SendCardMessageAsync()` → Lark API
5. Store `{messageId, alertEventId}` in `LarkAlertEvent` table (for reply linkage)
6. Log to `NotificationLog`

#### Resolved / Recovery Path — `SendResolvedEventReplyAsync`

1. Look up original firing event: `IAlertEventLookup.GetFiringAlertEventByEventIdAsync(matchingEventId)`
2. Look up stored Lark message ID: `ILarkAlertEvent.GetMessageIdByAlertEventIdAsync(firingEvent.Id)`
3. If either lookup fails → log warning, skip (no card to reply to)
4. Generate card body via `UnifiedEvent.CreateLarkNotificationMessage()`
5. Prepend: `Resolving Firing Event ID: {firingEventId}`
6. Reply as thread on original card via `ILarkNotification.ReplyMessageAsync()`
7. Log to `NotificationLog`

### Step 5 — Mark Processed

```
IAlertEvent.ProcessAlertEvent(alertEvent)
```

Sets `alertEvent.Processed = true` in the database (prevents re-processing on duplicate NOTIFY).

---

## 4. Notification Architecture Summary

Two independent Lark notification paths:

| Path | Triggered By | Card Builder | Card Format | Target |
|------|-------------|-------------|-------------|--------|
| **Primary Bot** | `LarkNotificationHandler` | `UnifiedEvent.CreateLarkNotificationMessage()` | Unified (same for BIT & Grafana) | Fixed Lark group |
| **Routing** | `EventRoutingService` → `LarkRoutingNotificationProvider` | `LarkRoutingCardBuilder.BuildCardContent(AlertEvent)` | Source-agnostic | Configurable Lark groups per routing rule |

---

## 5. Reply Linkage

The resolved reply mechanism depends on a three-part lookup chain:

```
Resolved Event
  └─ MatchingEventId ──→ AlertEvent (firing, same fingerprint)
                            └─ AlertEvent.Id ──→ LarkAlertEvent.MessageId
                                                   └─ Lark API: ReplyMessageAsync(messageId)
```

If any link is broken (no firing event found, no stored Lark message ID), the reply is skipped with a warning log.

---

## 6. BIT vs Grafana Differences

| Aspect | Grafana (Kafka) | BIT |
|--------|----------------|-----|
| Kafka consumer | `GrafanaTopicKafkaConsumerService` | `BitTopicKafkaConsumerService` |
| Message explosion | 1 alert per message | 1 alert **per server** in `server_list` |
| Labels | All Grafana labels (env, server, kafka_topic, etc.) | Fixed set (biz, type, state, platform, sname, dc_type, region, etc.) |
| Metrics (Values) | CPU, Memory, IOPS, DiskFreePct | None |
| Environment field | `Labels["env"]` | `Labels["dc_type"]` (fallback) |
| Server field | `Labels["server"]` | `{platform} {sname}` |
| Recovery detection | `Status == Resolved` | `Labels["state"]` is `part_recover` or `recover` |
| Severity mapping | 4 levels (critical/high/warn/info) | 2 levels (error/default) |

---

## 7. Flow Diagram

```
Kafka
 ├── GrafanaTopicKafkaConsumerService ──┐
 └── BitTopicKafkaConsumerService ──────┤
                                        ▼
                              AlertEvent persisted to PostgreSQL
                                        │
                              PG NOTIFY trigger fires
                                        │
                                        ▼
                              EventListenerService (LISTEN)
                                        │
                              Load AlertEvent by ID
                              Skip if already processed
                                        │
                                        ▼
                              EventProcessingService.ProcessEventAsync
                                        │
                        ┌───────────────┼───────────────────┐
                        ▼               ▼                   ▼
                  Map to          Severity              Route to
                UnifiedEvent     Evaluation          Routing Rules
                                        │                   │
                                        ▼                   ▼
                              Lark Notification     LarkRoutingNotificationProvider
                              (Primary Bot)         (per routing rule → Lark group)
                                        │
                  ┌─────────────────────┼─────────────────────┐
                  ▼                     ▼                     ▼
           BIT Recovery            Firing               Resolved
          (part_recover/        (new card)           (reply to original)
           recover)                  │                     │
              │                     ▼                     ▼
              │              SendCardMessage         ReplyMessage
              │              + store messageId       (thread on original)
              │
              ▼
         ReplyMessage
      (thread on original)
                                        │
                                        ▼
                              Mark AlertEvent as Processed
```

---

## 8. Key File Index

| Layer | File | Purpose |
|-------|------|---------|
| **Domain** | `Domain/Entities/Events/AlertEvent.cs` | Core alert event entity |
| **Domain** | `Domain/Entities/Events/AlertStatus.cs` | Firing / Resolved enum |
| **Domain** | `Domain/Entities/EventSource.cs` | Kafka / Bit enum |
| **Application** | `Application/Dtos/UnifiedEvent.cs` | Unified event DTO + card message builder |
| **Application** | `Application/Dtos/SeverityEvaluationDetail.cs` | Severity score result |
| **Application** | `Application/Dtos/SendLarkNotificationParameters.cs` | Parameters for Lark handler |
| **Application** | `Application/Interfaces/AlertEvents/IEventProcessing.cs` | Processing pipeline interface |
| **Application** | `Application/Interfaces/AlertEvents/IEventListener.cs` | PG LISTEN interface |
| **Application** | `Application/Interfaces/AlertEvents/IAlertEventAdd.cs` | Event persistence interface |
| **Application** | `Application/Interfaces/AlertEvents/IAlertEventLookup.cs` | Event lookup interface |
| **Application** | `Application/Interfaces/AlertEvents/ILarkAlertEvent.cs` | Lark message ID storage interface |
| **Application** | `Application/Interfaces/Notifications/ILarkNotificationHandler.cs` | Primary bot interface |
| **Application** | `Application/Interfaces/Notifications/IEventRoutingService.cs` | Routing service interface |
| **Application** | `Application/Interfaces/SeverityRules/ISeverityRuleEngine.cs` | Severity engine interface |
| **Infrastructure** | `Infrastructure/Kafka/Background/GrafanaTopicKafkaBackgroundService.cs` | Grafana Kafka hosted service |
| **Infrastructure** | `Infrastructure/Kafka/Background/BitTopicKafkaBackgroundService.cs` | BIT Kafka hosted service |
| **Infrastructure** | `Infrastructure/Kafka/Consumers/GrafanaTopicKafkaConsumerService.cs` | Grafana message consumer |
| **Infrastructure** | `Infrastructure/Kafka/Consumers/BitTopicKafkaConsumerService.cs` | BIT message consumer |
| **Infrastructure** | `Infrastructure/Services/AlertEvents/AlertEventAddService.cs` | Persists AlertEvent to DB |
| **Infrastructure** | `Infrastructure/Services/AlertEvents/EventListenerService.cs` | PG LISTEN/NOTIFY listener |
| **Infrastructure** | `Infrastructure/Services/AlertEvents/EventProcessingService.cs` | Core processing pipeline |
| **Infrastructure** | `Infrastructure/Services/AlertEvents/UnifiedEventMapperService.cs` | AlertEvent → UnifiedEvent mapper |
| **Infrastructure** | `Infrastructure/Services/AlertEvents/AlertEventLookupService.cs` | Event lookup (by ID, by MatchingEventId) |
| **Infrastructure** | `Infrastructure/Services/Mappers/GrafanaMessageMapperService.cs` | Grafana DTO → AlertEvent mapper |
| **Infrastructure** | `Infrastructure/Services/Mappers/BitMessageMapperService.cs` | BIT DTO → AlertEvent mapper |
| **Infrastructure** | `Infrastructure/Services/SeverityRules/SeverityRuleEngineService.cs` | Severity rule matching + scoring |
| **Infrastructure** | `Infrastructure/Services/Notifications/EventRoutingService.cs` | Routes events to notification channels |
| **Infrastructure** | `Infrastructure/Services/Notifications/LarkNotificationHandler.cs` | Primary bot: firing cards + resolved replies |
| **Infrastructure** | `Infrastructure/Notifications/Providers/LarkRoutingNotificationProvider.cs` | Routing: sends to configured Lark groups |
| **Infrastructure** | `Infrastructure/Notifications/Lark/Utilities/LarkRoutingCardBuilder.cs` | Builds structured Lark cards for routing |
| **Infrastructure** | `Infrastructure/Notifications/Lark/Services/LarkNotificationService.cs` | Lark API client (send/reply cards) |
| **Infrastructure** | `Infrastructure/Databases/Repositories/AlertEvents/LarkAlertEventRepository.cs` | Stores/retrieves Lark message IDs |
