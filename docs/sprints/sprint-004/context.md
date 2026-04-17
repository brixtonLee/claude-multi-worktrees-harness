# Sprint 004 Context — Fix Daily Summary Timezone Error + Startup Run

## Sprint Info
**ID:** 004
**Branch:** sprint/004
**Worktree:** ../vsh-alert-wt-004
**Merge Target:** develop

## Current State
**Last Verdict:** SHIP — Fix daily summary timezone error + startup run — 2026-04-10
**Date:** 2026-04-10
**Sprint Start Commit:** 9af2c5f
**Baseline Build:** pass
**Baseline Tests:** pass

## File Manifest
### To Modify
- `Application/Interfaces/Cron/IDailySummaryService.cs` — Add optional `periodStart`/`periodEnd` params to interface (small file, 8 lines)
- `Infrastructure/Services/Cron/DailySummaryService.cs:L25-33` — Fix DateTimeOffset UTC conversion + accept optional time range params
- `Infrastructure/Background/DailyAlertSummaryCronService.cs:L33-94` — Add immediate startup run + extract send helper method

### To Read (reference only)
- `Infrastructure/Configurations/DailyAlertSummaryCronConfig.cs` — Config shape: CronHourUtc, CronMinuteUtc, TimeZoneId
- `Application/Dtos/Cron/DailyAlertSummaryDto.cs` — DTO shape for return value
- `Infrastructure/Notifications/Lark/Utilities/LarkDailySummaryCardBuilder.cs` — Card builder (no changes needed)
