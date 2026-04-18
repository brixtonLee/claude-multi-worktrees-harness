# Sprint Registry

> **Purpose:** Central dashboard for all active sprints. Primary entry point for context recovery and collision detection.
> **Updated by:** ORCHESTRATOR on sprint create, subtask completion, ship, and archive.
> **Convention:** One row per active sprint. Remove row on ship or archive. File Reservations are the collision detection mechanism.
> **On sprint ship/archive:** Remove the sprint's rows from all three tables. Do NOT remove table headers or this Format Reference section.

## Format Reference

<!-- ORCHESTRATOR: Use these examples when adding rows. On ship/archive, remove only the sprint's rows — leave headers and this section intact. -->

**Active Sprints row:**
```
| 001 | sprint/daily-summary | ../vsh-alert-wt-001 | Daily alert summary cron | executing | 4/6 | 2026-04-09 |
```

**File Reservations row:**
```
| Infrastructure/StartUp/DependencyInjection.cs | 001 | modify | L487-490 |
| Infrastructure/Background/DailyAlertSummaryCronService.cs | 001 | create | — |
```

**Rebase Status row:**
```
| 001 | 81ac9f3 | no | — |
| 002 | 81ac9f3 | yes | Sprint 001 shipped, modified DependencyInjection.cs |
```

**Integration Branch (active):**
```
- **Branch:** integration/develop-20260410
- **Target:** develop
- **Base Commit:** 58eda3a
- **Created:** 2026-04-10
- **Status:** active
```

**Clean state** (after all sprints shipped — tables have headers only, no data rows):
```
| ID | Branch | Worktree | Goal | Phase | Progress | Started |
|----|--------|----------|------|-------|----------|---------|

| File Path | Sprint | Op | Lines |
|-----------|--------|----|-------|

| Sprint | Base Commit | Needs Rebase | Reason |
|--------|-------------|--------------|--------|
```

---

## Integration Branch

<!-- When multi-session collaboration is active, one integration branch is used by all sessions. -->
<!-- If Status is inactive, sprints merge directly to their target branch (legacy flow). -->
<!-- Status: inactive | active -->

- **Branch:** integration/master-20260416
- **Target:** master
- **Base Commit:** eb4b6d4
- **Created:** 2026-04-16
- **Status:** active

---

## Active Sprints

| ID | Branch | Worktree | Goal | Phase | Progress | Started |
|----|--------|----------|------|-------|----------|---------|
| 009 | sprint/invoice-solid-refactor | ../ai-agents-wt-009 | InvoiceProcessingAgent SOLID refactor | executing | 0/5 | 2026-04-18 |

<!-- Phases: planning | executing | verifying | rework | shipping -->

## File Reservations

| File Path | Sprint | Op | Lines |
|-----------|--------|----|-------|
| src/AiAgents.Application/Agents/InvoiceProcessingAgent.cs | 009 | modify | — |
| src/AiAgents.Application/Agents/BankReconciliationAgent.cs | 009 | modify | L22,33,38 |
| src/AiAgents.Application/Agents/ReceiptCategorizationAgent.cs | 009 | modify | L20,29,34,148 |
| src/AiAgents.Application/Common/Helpers/DuplicateDetector.cs | 009 | modify | L6 |
| src/AiAgents.Application/Common/Helpers/CrossVerificationTrigger.cs | 009 | modify | L21,28 |
| src/AiAgents.Application/Common/Interfaces/IDuplicateDetector.cs | 009 | modify | L3 |
| src/AiAgents.Application/DependencyInjection/ApplicationServiceRegistration.cs | 009 | modify | L34-39 |
| tests/AiAgents.Application.Tests/Agents/InvoiceProcessingAgentTests.cs | 009 | modify | L24 |
| tests/AiAgents.Application.Tests/Agents/BankReconciliationAgentTests.cs | 009 | modify | — |
| tests/AiAgents.Application.Tests/Agents/ReceiptCategorizationAgentTests.cs | 009 | modify | — |
| tests/AiAgents.Application.Tests/Helpers/CrossVerificationTriggerTests.cs | 009 | modify | — |
| src/AiAgents.Application/Common/Interfaces/IInvoiceDuplicateChecker.cs | 009 | create | — |
| src/AiAgents.Application/Common/Interfaces/ITransactionDuplicateChecker.cs | 009 | create | — |
| src/AiAgents.Application/Common/Interfaces/IReceiptDuplicateChecker.cs | 009 | create | — |
| src/AiAgents.Application/Common/Interfaces/ICrossVerificationTrigger.cs | 009 | create | — |
| src/AiAgents.Application/Common/Interfaces/IInvoicePersistenceService.cs | 009 | create | — |
| src/AiAgents.Application/Common/Helpers/InvoicePersistenceService.cs | 009 | create | — |

<!-- Op: create | modify. Lines: L50-85 or "—" for create/full-file changes. -->
<!-- Before registering a new sprint, check this table for overlaps. -->

## Rebase Status

| Sprint | Base Commit | Needs Rebase | Reason |
|--------|-------------|--------------|--------|
| 009 | 32b29d2 | no | — |

<!-- Updated after a sprint ships. "Needs Rebase: yes" means the sprint's worktree must rebase onto the merge target (integration branch if active, otherwise target branch) before continuing. -->
