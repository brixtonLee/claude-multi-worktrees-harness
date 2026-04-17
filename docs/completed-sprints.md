# Completed Sprints

> **Purpose:** Record of successfully SHIP'd sprints. Provides delivery history and cross-sprint continuity.
> ORCHESTRATOR appends here during Sprint End Checklist (step 5) on SHIP verdict.
> ORCHESTRATOR reads this during planning (Step 1) to understand what previous sprints delivered.
> **During execution:** Do NOT read this file.

---

## Format

```
### [YYYY-MM-DD] Completed Sprint: [Sprint Goal]
**Verdict:** SHIP | SHIP WITH FOLLOW-UPS
**Subtasks completed:** [N]
**Key files delivered:** [list from sprint context.md manifest]
**Summary:** [1-2 sentences of what was delivered]
```

---

## Entries

<!-- Append new entries below. Never delete past entries. -->

### [2026-04-10] Completed Sprint: Fix Daily Summary Timezone Error + Startup Run
**Verdict:** SHIP
**Subtasks completed:** 2
**Key files delivered:** IDailySummaryService.cs, DailySummaryService.cs, DailyAlertSummaryCronService.cs
**Summary:** Fixed Npgsql timezone error by converting all DateTimeOffset values to UTC before EF Core queries. Added optional periodStart/periodEnd parameters to IDailySummaryService. Extracted send logic in DailyAlertSummaryCronService and added immediate startup run covering UTC 00:00 to now.

### [2026-04-10] Completed Sprint: Fix Resolved Events Sent as Firing in Lark Routing
**Verdict:** SHIP
**Subtasks completed:** 1
**Key files delivered:** LarkRoutingCardBuilder.cs, LarkRoutingNotificationProvider.cs
**Summary:** Added `BuildResolvedEventCardMessage` to `LarkRoutingCardBuilder` with green header template and `[Source] ✅ Title` format. Updated `LarkRoutingNotificationProvider` to route resolved events to the new builder based on `AlertEvent.Status`. Resolved events now display as visually distinct standalone cards in routing channels.

### [2026-04-10] Completed Sprint: Remove Severity Color Header from Lark Card
**Verdict:** SHIP
**Subtasks completed:** 1
**Key files delivered:** LarkNotificationHandler.cs, SendLarkMessageParameters.cs, LarkNotificationService.cs, SeverityEvaluationDetailFormatter.cs
**Summary:** Removed severity-based color template and [severity] tag from firing notification card header. Kept `LarkCardHeader.Template` property for use by routing resolved cards. Deleted `GetSeverityTitleTag()` and `GetSeverityHeaderColor()` methods.

### [2026-04-09] Completed Sprint: Add Calculated Severity to Lark Card Header
**Verdict:** SHIP
**Subtasks completed:** 1
**Key files delivered:** LarkSendCardMessageRequest.cs, SendLarkMessageParameters.cs, LarkNotificationService.cs, LarkNotificationHandler.cs, SeverityEvaluationDetailFormatter.cs
**Summary:** Wired existing SeverityEvaluationDetailFormatter.GetSeverityTitleTag() and GetSeverityHeaderColor() into firing Lark notification pipeline. Firing cards now show severity tag in title (e.g. [High]) and colored header (red/orange/yellow/green by severity level). Null-safe — cards without severity match default to blue header with no tag. Also added missing formatter methods that were absent from committed HEAD.

### [2026-04-09] Completed Sprint: Add Severity Rule Details to Firing Alert Event Notification
**Verdict:** SHIP
**Subtasks completed:** 6
**Key files delivered:** SeverityEvaluationDetail.cs (new), SeverityEvaluationDetailFormatter.cs (new), ISeverityRuleEngine.cs, SeverityRuleEngineService.cs, SendLarkNotificationParameters.cs, EventProcessingService.cs, LarkNotificationHandler.cs, SeverityRuleReprocessingService.cs, SeverityRuleEngineServiceTests.cs
**Summary:** Propagated severity rule evaluation details (rule name, score formula, field scores, final score) from the severity engine through SendLarkNotificationParameters to firing Lark notifications. Changed CalculateAlertEventSeverityScoreAsync return type from bool to SeverityEvaluationResult? to expose evaluation data. Backward compatible — notifications without matching severity rules show no severity section.

### [2026-04-09] Completed Sprint: Daily Alert Summary Cron Job
**Verdict:** SHIP
**Subtasks completed:** 6
**Key files delivered:** DailyAlertSummaryDto.cs, IDailySummaryService.cs, DailyAlertSummaryCronConfig.cs, DailySummaryService.cs, DailyAlertSummaryCronService.cs, LarkDailySummaryCardBuilder.cs, DependencyInjection.cs, appsettings.json
**Summary:** New BackgroundService that fires daily at 9 AM (configurable) and sends a Lark card via the main bot with per-source metrics: firing/resolved/unresolved events today, duplicate events with title breakdown (from KafkaEventLog), unresolved YTD, and oldest unresolved timestamp.

### [2026-04-08] Completed Sprint: Separate Lark Bot Credentials for Duplicate/Error Notifications
**Verdict:** SHIP
**Subtasks completed:** 1
**Key files delivered:** LarkBotConfig.cs, LarkAuthService.cs, LarkNotificationService.cs, LarkNotificationHandler.cs, DependencyInjection.cs, appsettings.json (main + test)
**Summary:** Added `DuplicateAppId`/`DuplicateAppSecret`/`DuplicateGroupId` to `LarkBotConfig`. Registered keyed "Duplicate" `ILarkAuth` + `ILarkNotification` with separate bot credentials. `LarkNotificationHandler` uses the duplicate notification service for duplicate/error messages, main service for firing/resolved. Fallback to main bot when duplicate config is empty.

### [2026-04-08] Completed Sprint: Separate Duplicate Event Lark Channel
**Verdict:** SHIP
**Subtasks completed:** 1
**Key files delivered:** LarkBotConfig.cs, LarkNotificationService.cs, appsettings.json (main + test)
**Summary:** Added `DuplicateGroupId` to `LarkBotConfig` with fallback to `GroupId`. Duplicate and error Lark notifications now route to a separate group chat, while firing/resolved notifications remain on the original channel.

### [2026-04-08] Completed Sprint: Refactor Duplicate Lark Bot Config to Separate Sections
**Verdict:** SHIP WITH FOLLOW-UPS
**Subtasks completed:** 1
**Key files delivered:** LarkBotConfig.cs, LarkAuthService.cs, LarkNotificationService.cs, DependencyInjection.cs, appsettings.json (main + test)
**Summary:** Replaced double constructors + `Duplicate*` config properties with two separate appsettings sections (`LarkBotConfig` + `DuplicateLarkBot`) binding to the same class. Keyed DI factories now use named options via `IOptionsSnapshot.Get("Duplicate")` + `Options.Create()` with fallback to main config.

### [2026-04-06] Completed Sprint: Lark Topic + Resolved Notification
**Verdict:** SHIP
**Subtasks completed:** 2
**Key files delivered:** SendLarkNotificationParameters.cs, UnifiedEvent.cs, EventSourceDisplayNameHelper.cs, BitTopicKafkaConsumerService.cs, GrafanaTopicKafkaConsumerService.cs, LarkNotificationService.cs, LarkNotificationHandler.cs
**Summary:** Added Kafka topic name display in Lark notification card bodies and [Grafana]/[BIT] source badge prefixes to card titles. (Retroactive entry — original SHIP flow did not record this.)

### [2026-04-10] Completed Sprint: Remove Severity Color Header from Lark Card
**Verdict:** SHIP
**Subtasks completed:** 1
**Key files delivered:** LarkNotificationHandler.cs, SendLarkMessageParameters.cs, LarkNotificationService.cs, SeverityEvaluationDetailFormatter.cs
**Summary:** Removed calculated severity tag and color template from firing notification card header. Title reverted to original `[Source] {emoji} {Title}` format. Deleted unused GetSeverityTitleTag and GetSeverityHeaderColor methods. LarkCardHeader.Template property retained for Sprint 003 usage.

### [2026-04-10] Completed Sprint: Severity Rule Audit Notifications via Lark
**Verdict:** SHIP
**Subtasks completed:** 3
**Key files delivered:** SeverityRuleAuditSnapshotMapper.cs, LarkAuditCardBuilder.cs, SeverityRuleAuditNotificationService.cs, SeverityRuleCommandService.cs, DependencyInjection.cs, appsettings.json
**Summary:** Implemented audit notification pipeline for severity rule CRUD operations. All 5 mutations (Create/Update/Delete/Enable/Disable) fire fire-and-forget Lark card messages to a dedicated audit channel with before/after rule snapshots. Uses Audit-keyed Lark services with fallback to main bot config. Reused existing ISeverityRuleAuditNotification interface and SeverityRuleAuditEventDto DTOs.

### [2026-04-10] Completed Sprint: Change Daily Summary Duplicate Events Query
**Verdict:** SHIP
**Subtasks completed:** 3
**Key files delivered:** DailyAlertSummaryDto.cs, DailySummaryService.cs, LarkDailySummaryCardBuilder.cs
**Summary:** Rewrote daily summary duplicate events query from ProcessingStatus.Duplicate filter to LINQ LEFT JOIN kafka_event_logs to alert_events on EventId, GROUP BY (MatchingEventId, Source) HAVING COUNT > 1. Added first/last event timestamps to Lark card duplicate detail lines.

### [2026-04-10] Completed Sprint: Seed Alert Event Routing Rules
**Verdict:** SHIP
**Subtasks completed:** 1
**Key files delivered:** AlertEventRoutingRuleSeedingHelper.cs, Program.cs, appsettings.json
**Summary:** Created alert event routing rule seeding helper with 4 sample rules (high severity filter, Kafka source, BIT source, low severity score range). Follows NotificationChannelSeedingHelper clear-then-seed pattern. Integrated into Program.cs dev-only startup with `Seeding:SeedAlertEventRoutingRulesOnStartup` config flag.

### [2026-04-16] Completed Sprint: Convert 3 Agents to Claude Native tool_use
**Verdict:** SHIP
**Subtasks completed:** 3
**Key files delivered:** ExpenseClaimProcessingAgent.cs, ReceiptCategorizationAgent.cs, BankReconciliationAgent.cs, ReceiptCategorizationAgentTests.cs, BankReconciliationAgentTests.cs
**Summary:** Converted 3 agents from inline skill injection (BuildSkillAwarePromptAsync) to Claude's native tool_use feature (BuildSoulPromptAsync + BuildSkillToolsAsync + CompleteWithToolLoopAsync), matching the InvoiceProcessingAgent pattern. Removed manual skill lookups from ReceiptCategorizationAgent. Added lazy skillTools initialization to BankReconciliationAgent. Updated test mocks.
