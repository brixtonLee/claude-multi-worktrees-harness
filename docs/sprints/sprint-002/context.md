# Sprint 002 Context — Remove Severity Color Header from Lark Card

## Sprint Info
**ID:** 002
**Branch:** sprint/002
**Worktree:** ../vsh-alert-wt-002
**Merge Target:** develop

## Current State
**Last Verdict:** SHIP — Remove severity color header from Lark card — 2026-04-10
**Date:** 2026-04-10
**Sprint Start Commit:** 9af2c5f
**Baseline Build:** pass
**Baseline Tests:** pass

## File Manifest
### To Modify
- `VSH.AlertCollectorAPI.Infrastructure/Services/Notifications/LarkNotificationHandler.cs:L72-87` — remove severityTag/headerColor vars and simplify title + SendLarkMessageParameters
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Dtos/SendLarkMessageParameters.cs:L7` — remove HeaderColor parameter
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Services/LarkNotificationService.cs:L187-222` — remove Template from LarkCardHeader in both builder methods
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Dtos/LarkSendCardMessageRequest.cs:L33-36` — KEEP Template on LarkCardHeader (sprint 003 needs it) — only remove severity-based usage paths
- `VSH.AlertCollectorAPI.Application/Helpers/SeverityEvaluationDetailFormatter.cs:L46-81` — delete GetSeverityTitleTag and GetSeverityHeaderColor methods
