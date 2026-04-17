# Sprint 006 Context — Change Daily Summary Duplicate Events Query

## Sprint Info
**ID:** 006
**Branch:** sprint/006
**Worktree:** ../vsh-alert-wt-006
**Merge Target:** release/2026.04.10-0.1.12

## Current State
**Last Verdict:** SHIP — Change daily summary duplicate events query — 2026-04-10
**Date:** 2026-04-10
**Sprint Start Commit:** bfd44dc
**Baseline Build:** pass
**Baseline Tests:** pass

## File Manifest
### To Modify
- `VSH.AlertCollectorAPI.Application/Dtos/Cron/DailyAlertSummaryDto.cs` — Add MatchingEventId, FirstEventTimestamp, LastEventTimestamp to DuplicateEventDetailDto
- `VSH.AlertCollectorAPI.Infrastructure/Services/Cron/DailySummaryService.cs:L58-74` — Rewrite duplicate query (Phase 1: LEFT JOIN + GROUP BY)
- `VSH.AlertCollectorAPI.Infrastructure/Services/Cron/DailySummaryService.cs:L95-123` — Rewrite assembly loop (Phase 2: dictionary-based lookup)
- `VSH.AlertCollectorAPI.Infrastructure/Notifications/Lark/Utilities/LarkDailySummaryCardBuilder.cs:L113-116` — Add timestamps to duplicate detail lines

### To Read (reference only)
- `VSH.AlertCollectorAPI.Domain/Entities/Events/KafkaEventLog.cs` — EventId, MatchingEventId, Source, EventStartTimestamp fields
- `VSH.AlertCollectorAPI.Domain/Entities/Events/AlertEvent.cs` — EventId (unique), Title field for join
