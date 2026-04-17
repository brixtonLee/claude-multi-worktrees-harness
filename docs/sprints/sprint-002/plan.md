# Sprint 002 Plan — Remove Severity Color Header from Lark Card

## Task: Remove calculated severity tag and color header from Lark message card
**Complexity:** small
**Scope:** Remove severity-based color template and [severity] tag from firing notification card header. Keep original `[Source] {emoji} {Title}` format. IN: firing notification title + header color. OUT: severity evaluation detail in card body (keep as-is), resolved/duplicate/error cards (already unaffected).
**Approach:** Delete the severity-to-color/tag mapping methods, remove HeaderColor from the DTO chain, and simplify the title construction in LarkNotificationHandler.

### Subtasks
- [x] 1. Remove severity from Lark card header — layer: infrastructure+application — files: LarkNotificationHandler.cs, SendLarkMessageParameters.cs, LarkNotificationService.cs, LarkSendCardMessageRequest.cs, SeverityEvaluationDetailFormatter.cs — parallel-group: sequential — check-profile: service

### Key Details
- `LarkNotificationHandler.cs:L72-78`: `severityTag` and `headerColor` variables must be deleted. Title on L77-78 must become `$"[{source}] {emoji} {title}"` without the severity tag suffix.
- `LarkNotificationHandler.cs:L86`: Remove `HeaderColor: headerColor` from SendLarkMessageParameters.
- `SendLarkMessageParameters.cs:L7`: Remove `string? HeaderColor = null`.
- `LarkNotificationService.cs:L192,L221`: Remove `Template: parameters.HeaderColor` from both `ReturnLarkSendCardMessageRequest` and `ReturnLarkReplyCardMessageRequest`.
- `LarkSendCardMessageRequest.cs:L35`: **KEEP** `string? Template = null` on `LarkCardHeader` — needed by sprint 003 for resolved card `Template: "green"`. Only remove severity-based usage paths.
- `SeverityEvaluationDetailFormatter.cs:L46-81`: Delete `GetSeverityTitleTag()` and `GetSeverityHeaderColor()` methods entirely.
- `LarkRoutingCardBuilder.cs` and `LarkDailySummaryCardBuilder.cs` construct `LarkCardHeader` without `Template` — `Template` property is KEPT (sprint 003 needs it), so no breaking changes here.

### Acceptance Criteria
- [ ] Firing notification title is `[Source] {emoji} {Title}` with no severity tag
- [ ] No color template applied to firing notification card header (Lark defaults to blue)
- [ ] Resolved/duplicate/error cards unaffected
- [x] Build passes, all tests pass
- [x] No dangling references to GetSeverityTitleTag, GetSeverityHeaderColor, HeaderColor

### Rework Items
