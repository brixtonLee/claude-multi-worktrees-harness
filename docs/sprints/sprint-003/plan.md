# Sprint 003 Plan — Fix Resolved Events Sent as Firing in Lark Routing

## Task: Fix resolved event card in Lark routing pipeline
**Complexity:** small
**Scope:** Add resolved-specific card builder to LarkRoutingCardBuilder and route to it from LarkRoutingNotificationProvider. IN: routing card for resolved events. OUT: main Lark path (SendResolvedEventReplyAsync), EventProcessingService, daily summary cards.
**Approach:** Add `BuildResolvedEventCardMessage` static method with green header template and `[Source] checkmark Title` format. Route in provider based on AlertEvent.Status.

### Subtasks
- [x] 1. Add resolved card builder and status-based routing — layer: infrastructure — files: LarkRoutingCardBuilder.cs, LarkRoutingNotificationProvider.cs — parallel-group: sequential — check-profile: service

### Key Details
- `LarkRoutingCardBuilder.cs`: Add new static method `BuildResolvedEventCardMessage(AlertEvent alertEvent, string chatId)`:
  - Add `using VSH.AlertCollectorAPI.Application.Helpers;` for `EventSourceDisplayNameHelper`
  - Header title: `$"[{EventSourceDisplayNameHelper.GetDisplayName(alertEvent.Source)}] {GetStatusEmoji(alertEvent.Status)} {alertEvent.Title ?? "Alert Event"}"` — matches resolved reply format from LarkNotificationHandler:L155
  - Header template: `"green"` — visually distinct resolved header
  - Body: reuse existing `BuildCardContent(alertEvent)` which already handles resolved (shows end timestamp + duration)
  - Card structure identical to `BuildFiringEventCardMessage` except header title format and Template color
- `LarkRoutingNotificationProvider.cs:L63`: Replace `BuildFiringEventCardMessage` with ternary:
  - `parameters.AlertEvent.Status is AlertStatus.Resolved ? LarkRoutingCardBuilder.BuildResolvedEventCardMessage(...) : LarkRoutingCardBuilder.BuildFiringEventCardMessage(...)`
  - Add `using VSH.AlertCollectorAPI.Domain.Entities.Events;` for `AlertStatus` enum
- `EventSourceDisplayNameHelper.GetDisplayName` accepts `EventSource?` — handle null source with fallback "Unknown"

### Acceptance Criteria
- [ ] Resolved events produce a standalone card with green header in routing channels
- [ ] Resolved card title includes source prefix: `[Source] checkmark Title`
- [ ] Firing events continue to use existing card builder (unchanged)
- [x] Build passes, all tests pass

### Rework Items

