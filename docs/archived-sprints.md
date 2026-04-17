# Archived Sprints

> **Purpose:** Record of abandoned/archived sprints (superseded or user-cancelled). Completed sprints go to `completed-sprints.md`.
> ORCHESTRATOR appends here during Sprint Collision Check (incomplete archive).
> ORCHESTRATOR reads this during planning to check for related abandoned work.
> **During execution:** Do NOT read this file.

---

## Format

```
### [YYYY-MM-DD] Archived Sprint: [Sprint Goal]
**Reason:** [Superseded by new sprint / User decision]
**Status at archive:** [X of Y subtasks complete]
**Last Verdict:** [from sprint context.md]
**Unchecked subtasks:**
- [ ] [remaining subtask descriptions]
**Files that were in-progress:**
- [file list from sprint context.md manifest]
```

---

## Entries

<!-- Append new entries below. Never delete past entries. -->

### [2026-04-02] Archived Sprint: Fix duplicate detection race condition, add pipeline milestone logging, add routing dispatch resilience
**Reason:** Superseded by new sprint (logging/observability + Grafana error/no_data handling)
**Status at archive:** 0 of 5 subtasks complete
**Last Verdict:** none
**Unchecked subtasks:**
- [ ] 1. Thread correlationId through event processing (interface + service + caller)
- [ ] 2. Fix GrafanaTopicKafkaConsumerService Task.Run bug + upgrade log levels
- [ ] 3. Fix BitTopicKafkaConsumerService Task.Run bug + upgrade log levels
- [ ] 4. Add error resilience to EventRoutingService dispatch loop
- [ ] 5. Build + test verification
**Files that were in-progress:**
- `VSH.AlertCollectorAPI.Application/Interfaces/AlertEvents/IEventProcessing.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Services/AlertEvents/EventProcessingService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Services/AlertEvents/EventListenerService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Kafka/Consumers/GrafanaTopicKafkaConsumerService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Kafka/Consumers/BitTopicKafkaConsumerService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Services/Notifications/EventRoutingService.cs`

### [2026-04-02] Archived Sprint: Logging/Observability Improvements + Grafana error/no_data Handling
**Reason:** Superseded by new sprint (error Lark notifications + duplicate bug fix + pipeline error logging)
**Status at archive:** 0 of 5 subtasks complete
**Last Verdict:** none
**Unchecked subtasks:**
- [ ] 1. Phase 1: Explicit Grafana error/no_data handling in GrafanaMessageMapperService + DI update
- [ ] 2. Phase 2: Duplicate detection logging enhancements in both Kafka consumers
- [ ] 3. Phase 3: CorrelationId threading to event routing
- [ ] 4. Phase 4: EventListenerService bridge log
- [ ] 5. Build + test + format verification
**Files that were in-progress:**
- `VSH.AlertCollectorAPI.Infrastructure/Services/Mappers/GrafanaMessageMapperService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/StartUp/DependencyInjection.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Kafka/Consumers/GrafanaTopicKafkaConsumerService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Kafka/Consumers/BitTopicKafkaConsumerService.cs`
- `VSH.AlertCollectorAPI.Application/Interfaces/Notifications/IEventRoutingService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Services/Notifications/EventRoutingService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Services/AlertEvents/EventProcessingService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Services/AlertEvents/EventListenerService.cs`

### [2026-04-02] Archived Sprint: Firing + Error Lark Notifications from Kafka Consumers
**Reason:** Superseded by new sprint (comprehensive error logging across Kafka consumer + event processing pipeline)
**Status at archive:** 0 of 6 subtasks complete
**Last Verdict:** none
**Unchecked subtasks:**
- [ ] 1. Populate AlertEvent navigation properties in AlertEventAddService
- [ ] 2. Error notification Lark card builder (SendErrorEventMessageParameters + ILarkNotification + LarkNotificationService)
- [ ] 3. Implement SendErrorEventNotificationAsync in LarkNotificationHandler
- [ ] 4. Add firing + error notifications to GrafanaTopicKafkaConsumerService
- [ ] 5. Add firing + error notifications to BitTopicKafkaConsumerService
- [ ] 6. Remove duplicate firing notification from EventProcessingService
**Files that were in-progress:**
- `VSH.AlertCollectorAPI.Infrastructure/Services/AlertEvents/AlertEventAddService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Dtos/SendLarkMessageParameters.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Interfaces/ILarkNotification.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Services/LarkNotificationService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Services/Notifications/LarkNotificationHandler.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Kafka/Consumers/GrafanaTopicKafkaConsumerService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Kafka/Consumers/BitTopicKafkaConsumerService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Services/AlertEvents/EventProcessingService.cs`

### [2026-04-02] Archived Sprint: Comprehensive Error Logging for Kafka Consumers & Event Processing Pipeline
**Reason:** Superseded by new sprint (focused error logging — narrower scope, excludes BitTimeParser/EventRoutingService/JSON deserialization wrapping)
**Status at archive:** 0 of 8 subtasks complete
**Last Verdict:** none
**Unchecked subtasks:**
- [ ] 1. Background services — wrap ExecuteAsync + Task.Run with try-catch
- [ ] 2. BitTimeParser — add ILogger overloads for parse failure visibility
- [ ] 3. Kafka consumers — adopt KafkaConsumerLoggingHelper, JSON error handling, finally block safety
- [ ] 4. Lark error card infrastructure
- [ ] 5. LarkNotificationHandler — implement SendErrorEventNotificationAsync
- [ ] 6. Add error Lark notifications to both Kafka consumers' catch blocks
- [ ] 7. EventProcessingService — outer try-catch + wrap fire-and-forget
- [ ] 8. EventRoutingService — outer try-catch, per-provider try-catch, SaveChanges safety
**Files that were in-progress:**
- `VSH.AlertCollectorAPI.Infrastructure/Kafka/Background/GrafanaTopicKafkaBackgroundService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Kafka/Background/BitTopicKafkaBackgroundService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Kafka/Utilities/BitTimeParser.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Kafka/Consumers/GrafanaTopicKafkaConsumerService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Kafka/Consumers/BitTopicKafkaConsumerService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Dtos/SendLarkMessageParameters.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Interfaces/ILarkNotification.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Services/LarkNotificationService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Services/Notifications/LarkNotificationHandler.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Services/AlertEvents/EventProcessingService.cs`
- `VSH.AlertCollectorAPI.Infrastructure/Services/Notifications/EventRoutingService.cs`
