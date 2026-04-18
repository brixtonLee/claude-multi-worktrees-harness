# Sprint 001 Plan — Add Calculated Severity to Lark Card Header

## Task: Wire severity title tag and header color into Lark card
**Complexity:** small
**Scope:** Add calculated severity to firing Lark card title (e.g., `[High]`) and header color. OUT: resolved replies, duplicate cards, error cards.
**Approach:** Use existing `SeverityEvaluationDetailFormatter.GetSeverityTitleTag()` and `GetSeverityHeaderColor()` — already implemented but unused. Thread header color through DTOs to Lark card builder.

### Subtasks
- [x] 1. Wire severity into Lark card header pipeline — layer: Infrastructure — files: LarkSendCardMessageRequest.cs, SendLarkMessageParameters.cs, LarkNotificationService.cs, LarkNotificationHandler.cs — parallel-group: sequential

### Key Details

**LarkCardHeader DTO** (`LarkSendCardMessageRequest.cs:L33`):
Currently `LarkCardHeader(LarkCardTitle Title)`. Lark API supports a `template` field on header for color styling. Add optional `string? Template = null`. Serializes to `"template": "red"` via existing `SnakeCaseLower` JSON policy. Null omits the field (Lark defaults to blue).

**SendLarkMessageParameters** (`SendLarkMessageParameters.cs:L3`):
Add `string? HeaderColor = null` — backward compatible default.

**LarkNotificationService card builders** (`LarkNotificationService.cs`):
- `ReturnLarkSendCardMessageRequest` (L186): Pass `parameters.HeaderColor` as `Template` in `LarkCardHeader`
- `ReturnLarkReplyCardMessageRequest` (L214): Same change

**LarkNotificationHandler.SendFiringEventNotificationAsync** (`LarkNotificationHandler.cs:L62-78`):
- Call `SeverityEvaluationDetailFormatter.GetSeverityTitleTag(detail)` → append to title if non-null
- Call `SeverityEvaluationDetailFormatter.GetSeverityHeaderColor(detail)` → pass as `HeaderColor`
- Title format: `[{Source}] {emoji} {Title} [High]` (tag appended at end)

**Existing utility methods** (read-only, DO NOT MODIFY):
- `GetSeverityTitleTag(SeverityEvaluationDetail?)` → returns `"[High]"`, `"[Very High]"`, etc. or null
- `GetSeverityHeaderColor(SeverityEvaluationDetail?)` → returns `"red"`, `"orange"`, `"yellow"`, `"green"`, or null

### Acceptance Criteria
- [ ] Firing Lark card title includes severity tag when severity was calculated (e.g., `[Grafana] fire-emoji Alert Name [High]`)
- [ ] Firing Lark card title has no severity tag when no severity rule matched
- [ ] Firing Lark card header is colored based on severity (red=VeryHigh, orange=High, yellow=Medium, green=Low)
- [ ] Firing Lark card header defaults to blue (no template) when no severity rule matched
- [ ] Resolved reply cards are unchanged (no severity tag, no color)
- [ ] Duplicate and error cards are unchanged
- [ ] Build passes, tests pass

### Rework Items
