# Sprint 001 Context — Add Calculated Severity to Lark Card Header

## Sprint Info
**ID:** 001
**Branch:** sprint/severity-lark-card
**Worktree:** ../vsh-alert-wt-001

## Current State
**Last Verdict:** SHIP — Add calculated severity to Lark card header — 2026-04-09
**Date:** 2026-04-09
**Sprint Start Commit:** aac84e2
**Baseline Build:** pass
**Baseline Tests:** pass

## File Manifest
### To Modify
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Dtos/LarkSendCardMessageRequest.cs:L33-35` — Add optional `Template` field to `LarkCardHeader` for Lark card header color
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Dtos/SendLarkMessageParameters.cs:L3-5` — Add optional `HeaderColor` to `SendLarkMessageParameters`
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Services/LarkNotificationService.cs:L186-193,L214-221` — Wire `Template` in `ReturnLarkSendCardMessageRequest` and `ReturnLarkReplyCardMessageRequest`
- `VSH.AlertCollectorAPI.Infrastructure/Services/Notifications/LarkNotificationHandler.cs:L62-78` — Use `GetSeverityTitleTag()` and `GetSeverityHeaderColor()` when building firing notification card

### To Create
_(none)_

### To Modify (added via drift — accepted)
- `VSH.AlertCollectorAPI.Application/Helpers/SeverityEvaluationDetailFormatter.cs` — Added FormatNoMatchForLarkNotification, GetSeverityTitleTag, GetSeverityHeaderColor (missing from committed HEAD)

### To Read (reference only)
- `VSH.AlertCollectorAPI.Application/Dtos/SeverityEvaluationDetail.cs` — Record with `CalculatedSeverity` field
