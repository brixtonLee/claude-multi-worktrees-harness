# Sprint 004 Plan — Fix Daily Summary Timezone Error + Startup Run

## Task: Fix Daily Summary Timezone Error + Add Startup Run
**Complexity:** small
**Scope:** Fix Npgsql UTC error in DailySummaryService queries; add immediate startup execution to DailyAlertSummaryCronService with UTC 00:00-to-now range. OUT: card builder changes, config changes.
**Approach:** Convert DateTimeOffset values to UTC before EF Core queries; parameterize time range in interface/service; extract send logic in cron service and call once on startup.

### Subtasks
- [x] 1. Fix UTC conversion + parameterize time range — layer: Application+Infrastructure — files: `IDailySummaryService.cs`, `DailySummaryService.cs` — parallel-group: A — check-profile: service
- [x] 2. Add startup run + extract send helper — layer: Infrastructure — files: `DailyAlertSummaryCronService.cs` — parallel-group: sequential (depends on subtask 1) — check-profile: background

### Key Details

**Bug: Npgsql timezone error**
- `DailySummaryService.GetDailySummaryAsync()` creates `DateTimeOffset` with +08:00 offset (Asia/Kuala_Lumpur)
- Npgsql 6.0+ rejects non-UTC `DateTimeOffset` for `timestamptz` columns
- Fix: call `.ToUniversalTime()` on `todayStart`, `todayEnd`, `yearStart` before use in queries

**Feature: Startup run**
- `DailyAlertSummaryCronService.ExecuteAsync` currently waits for next cron time before first send
- Add immediate send on startup using UTC midnight today → DateTime.UtcNow as the period
- Extract shared send logic into `SendDailySummaryAsync(DateTimeOffset? periodStart, DateTimeOffset? periodEnd, CancellationToken)` private method

**Interface change**
- `IDailySummaryService.GetDailySummaryAsync` gains optional `periodStart`/`periodEnd` params
- When null → existing timezone-based full-day logic (with UTC fix)
- When provided → use directly as query boundaries for "today" metrics

### Acceptance Criteria
- [ ] No Npgsql timezone error when querying daily summary
- [ ] On startup, daily summary Lark card is sent immediately with UTC 00:00-to-now data
- [ ] Scheduled cron behavior unchanged (full timezone day)
- [x] Solution builds cleanly
- [x] All existing tests pass

### Rework Items
