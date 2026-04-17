# Sprint 003 Context — Fix Resolved Events Sent as Firing in Lark Routing

## Sprint Info
**ID:** 003
**Branch:** sprint/003
**Worktree:** ../vsh-alert-wt-003
**Merge Target:** develop

## Current State
**Last Verdict:** SHIP — Fix resolved events sent as firing in Lark routing — 2026-04-10
**Date:** 2026-04-10
**Sprint Start Commit:** 9af2c5f
**Baseline Build:** pass
**Baseline Tests:** pass

## File Manifest
### To Modify
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Utilities/LarkRoutingCardBuilder.cs` — add BuildResolvedEventCardMessage with green header + source prefix
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Providers/LarkRoutingNotificationProvider.cs:L63` — branch on AlertEvent.Status to select correct card builder

### To Read (reference only)
- `VSH.AlertCollectorAPI.Infrastructure/Services/Notifications/LarkNotificationHandler.cs:L120-160` — resolved reply format reference (title pattern, resolved emoji)
- `VSH.AlertCollectorAPI.Application/Helpers/EventSourceDisplayNameHelper.cs` — source display name utility
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Dtos/LarkSendCardMessageRequest.cs:L33-36` — LarkCardHeader record with Template property
