# Sprint 007 Plan — Seed Alert Event Routing Rules

## Task: Seed Alert Event Routing Rules
**Complexity:** small
**Scope:** Create seeding helper + integrate into Program.cs startup. OUT: no new endpoints, no routing engine changes.
**Approach:** Follow NotificationChannelSeedingHelper pattern — static class, clear-then-seed, ILogger, Program.cs integration with config flag.

### Subtasks
- [x] 1. Create AlertEventRoutingRuleSeedingHelper.cs + modify Program.cs + appsettings — layer: API — files: [Helpers/AlertEventRoutingRuleSeedingHelper.cs (create), Program.cs:L208-210, appsettings.Development.json] — parallel-group: sequential — check-profile: service

### Key Details

**Entity constructor** (`AlertEventRoutingRule`):
```csharp
AlertEventRoutingRule(
    string ruleName,
    string? description,
    bool isEnabled,
    int priority,
    long notificationChannelId,   // FK → NotificationChannel
    decimal? minSeverityScore,     // null = no lower bound
    decimal? maxSeverityScore,     // null = no upper bound
    EventSeverity[]? matchSeverities,  // Low, Medium, High, VeryHigh
    EventSource? matchSource)          // Kafka=1, Bit=2, Rest=3, Pe=4
```

**Seeding pattern** (from NotificationChannelSeedingHelper):
1. Delete all existing routing rules → `SaveChangesAsync()`
2. Get notification channels → find "Lark Bot - Default" by name
3. Create rules with channel ID → `AddAsync()` + `SaveChangesAsync()` per rule

**Sample seed data:**

| Rule Name | Priority | Source | Severities | Score Range | Description |
|-----------|----------|--------|------------|-------------|-------------|
| High Severity — All Sources | 1 | null | High, VeryHigh | null | Route all high/very-high severity alerts |
| Kafka Source Alerts | 2 | Kafka | null | null | Route all Kafka-sourced alerts |
| BIT Source Alerts | 3 | Bit | null | null | Route all BIT-sourced alerts |
| Low Severity — Score Filter | 4 | null | Low | 0-30 | Route low severity with score ≤ 30 |

**Program.cs integration** (after L208, before L210):
- Config flag: `Seeding:SeedAlertEventRoutingRulesOnStartup` (default false)
- Resolve: IAlertEventRoutingRuleRepository, INotificationChannelRepository, IUnitOfWork
- Dev-only block (inside `builder.Environment.IsDevelopment()`)

### Acceptance Criteria
- [x] AlertEventRoutingRuleSeedingHelper.cs exists with static SeedAlertEventRoutingRulesAsync method
- [x] Method follows clear-then-seed pattern (delete existing, create new)
- [x] 4 routing rules seeded covering different scenarios (severity filter, source filter, score range)
- [x] Program.cs calls helper inside IsDevelopment() block with config flag check
- [x] appsettings.json has SeedAlertEventRoutingRulesOnStartup flag (in main appsettings, follows existing convention)
- [x] Solution builds with no errors
- [x] All existing tests pass (pre-existing failures only, no new)

### Rework Items
[empty — populated by orchestrator if VERIFIER returns REWORK]
