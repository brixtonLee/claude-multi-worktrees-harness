# Sprint 007 Context — Seed Alert Event Routing Rules

## Sprint Info
**ID:** 007
**Branch:** sprint/7
**Worktree:** ../vsh-alert-wt-007
**Merge Target:** release/2026.04.10-0.1.12

## Current State
**Last Verdict:** SHIP — Seed Alert Event Routing Rules — 2026-04-10
**Date:** 2026-04-10
**Sprint Start Commit:** da6de90
**Sprint Started At:** 2026-04-10T08:17:59Z
**Baseline Build:** pass
**Baseline Tests:** pass
**Compaction Count:** 0

## File Manifest
### To Modify
- `VSH.AlertCollectorAPI/Program.cs:L208-210` — insert routing rule seeding block after notification channel seeding
- `VSH.AlertCollectorAPI/appsettings.Development.json` — add SeedAlertEventRoutingRulesOnStartup flag

### To Create
- `VSH.AlertCollectorAPI/Helpers/AlertEventRoutingRuleSeedingHelper.cs` — seeding helper

### To Read (reference only)
- `VSH.AlertCollectorAPI/Helpers/NotificationChannelSeedingHelper.cs` — template pattern
- `VSH.AlertCollectorAPI.Domain/Entities/Notifications/AlertEventRoutingRule.cs` — entity constructor
- `VSH.AlertCollectorAPI.Domain/Entities/AlertEnums.cs` — EventSeverity enum values
- `VSH.AlertCollectorAPI.Domain/Entities/Events/EventSource.cs` — EventSource enum values
- `VSH.AlertCollectorAPI.Application/Interfaces/Repositories/Notifications/IAlertEventRoutingRuleRepository.cs` — repository interface
