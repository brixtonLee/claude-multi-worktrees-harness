# Sprint 005 Context — Severity Rule Audit Notifications via Lark

## Sprint Info
**ID:** 005
**Branch:** sprint/005
**Worktree:** ../vsh-alert-wt-005
**Merge Target:** develop

## Current State
**Last Verdict:** SHIP — Severity Rule Audit Notifications via Lark — 2026-04-10
**Group A complete:** Snapshot mapper, card builder, audit notification service, config, and DI registration created.
**Date:** 2026-04-10
**Sprint Start Commit:** 95c84e7
**Baseline Build:** pass
**Baseline Tests:** pending (skipped — build clean)

## File Manifest
### To Modify
- `VSH.AlertCollectorAPI/appsettings.json:L49-55` — add AuditLarkBot config section after DuplicateLarkBot
- `VSH.AlertCollectorAPI.Infrastructure/StartUp/DependencyInjection.cs:L131-163` — add Audit-keyed Lark services + ISeverityRuleAuditNotification registration
- `VSH.AlertCollectorAPI.Infrastructure/Services/SeverityRules/SeverityRuleCommandService.cs:L60-104` — add IServiceScopeFactory constructor parameter
- `VSH.AlertCollectorAPI.Infrastructure/Services/SeverityRules/SeverityRuleCommandService.cs:L135-241` — add audit call after CreateRuleInternalAsync transaction
- `VSH.AlertCollectorAPI.Infrastructure/Services/SeverityRules/SeverityRuleCommandService.cs:L272-582` — add beforeSnapshot capture + audit call after UpdateRuleInternalAsync transaction
- `VSH.AlertCollectorAPI.Infrastructure/Services/SeverityRules/SeverityRuleCommandService.cs:L584-631` — add audit calls in Delete/Enable/Disable methods

### To Create
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Utilities/LarkAuditCardBuilder.cs` — static card builder for audit events
- `VSH.AlertCollectorAPI.Application/Helpers/SeverityRuleAuditSnapshotMapper.cs` — static mapper: entity/response → SeverityRuleAuditSnapshotDto
- `VSH.AlertCollectorAPI.Infrastructure/Services/SeverityRules/SeverityRuleAuditNotificationService.cs` — implements ISeverityRuleAuditNotification

### To Read (reference only)
- `VSH.AlertCollectorAPI.Application/Interfaces/SeverityRules/ISeverityRuleAuditNotification.cs` — existing interface (no changes)
- `VSH.AlertCollectorAPI.Application/Dtos/Audit/SeverityRuleAuditEventDto.cs` — existing DTOs (no changes)
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Utilities/LarkRoutingCardBuilder.cs` — card builder pattern reference
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Dtos/LarkSendCardMessageRequest.cs` — Lark card DTOs reference
- `VSH.AlertCollectorAPI.Application/Common/Result.cs` — Result discriminated union pattern
- `VSH.AlertCollectorAPI.Application/Dtos/LarkNotificationResult.cs` — LarkNotificationResult record (IsSuccess, ErrorMessage)
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Configurations/LarkBotConfig.cs` — config class reused for Audit
- `VSH.AlertCollectorAPI.Domain/Entities/Rules/AlertSeverityRule.cs:L1-52` — entity properties for FromEntity mapper
- `VSH.AlertCollectorAPI.Application/Dtos/Responses/SeverityRules/AlertSeverityRuleDetailsResponse.cs:L1-19` — response record for FromResponse mapper
