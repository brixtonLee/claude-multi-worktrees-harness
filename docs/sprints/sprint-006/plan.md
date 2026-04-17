# Sprint 006 Plan — Change Daily Summary Duplicate Events Query

## Task: Rewrite duplicate events query to use kafka_event_logs GROUP BY matching_event_id
**Complexity:** small
**Scope:** Change duplicate event detection from ProcessingStatus.Duplicate filter to GROUP BY matching_event_id HAVING COUNT > 1, joining alert_events on event_id for titles. Add first/last timestamps to Lark card. IN: duplicate query + DTO + Lark card. OUT: unresolved logic, other daily summary sections.
**Approach:** LINQ query syntax with explicit LEFT JOIN on EventId (no FK nav prop exists), GroupBy + Having, then in-memory dictionary assembly for per-source structure.

### Subtasks
- [x] 1. Update DuplicateEventDetailDto — layer: Application — files: `Application/Dtos/Cron/DailyAlertSummaryDto.cs` — parallel-group: A — check-profile: query
- [x] 2. Rewrite duplicate query + assembly in DailySummaryService — layer: Infrastructure — files: `Infrastructure/Services/Cron/DailySummaryService.cs` — parallel-group: sequential — check-profile: query
- [x] 3. Update LarkDailySummaryCardBuilder duplicate section — layer: Infrastructure — files: `Infrastructure/Notifications/Lark/Utilities/LarkDailySummaryCardBuilder.cs` — parallel-group: sequential — check-profile: service

### Key Details

**Current duplicate query (lines 58-74):** Filters `KafkaEventLogs` by `ProcessingStatus == Duplicate`, groups by Source → AlertEvent.Title via FK nav prop.

**New duplicate query:** LINQ LEFT JOIN `kafka_event_logs` to `alert_events` ON `kel.EventId equals ae.EventId` (string field, no FK), group by `{MatchingEventId, Source}`, select groups with `Count() > 1`. Returns `MatchingEventId`, `EventTitle` (MAX), `DuplicateCount`, `FirstEventTimestamp` (MIN), `LastEventTimestamp` (MAX).

**Why EventId join not AlertEventId FK:** Duplicate KafkaEventLog rows have `AlertEventId == null` (only set via `LinkToAlertEvent` for successfully processed events). The EventId string field matches between both tables (AlertEvent.EventId has a unique index).

**DuplicatesToday semantic:** `Sum(DuplicateCount - 1)` = extra events beyond the first per group (matches old semantic of "how many duplicates were there").

**Lark card format change:** Detail lines become `- {EventTitle}: {Count} ({first:HH:mm} ~ {last:HH:mm})`

### Acceptance Criteria
- [x] DuplicateEventDetailDto has MatchingEventId, FirstEventTimestamp, LastEventTimestamp fields
- [x] Duplicate query joins kafka_event_logs to alert_events on EventId, groups by MatchingEventId+Source, filters HAVING COUNT > 1
- [x] DuplicatesToday per source = Sum(DuplicateCount - 1) for that source
- [x] Lark card duplicate detail lines show timestamps
- [x] Solution builds with no errors
- [ ] All existing tests pass

### Rework Items
