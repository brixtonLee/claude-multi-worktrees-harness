# Conflict Log

> **Purpose:** Audit trail of all sprint collisions and their resolutions. Used for post-ship debugging and error source identification.
> **Updated by:** ORCHESTRATOR when any collision is detected and resolved.
> **Convention:** Append-only. Never delete or modify existing entries — except the "Post-ship note" field, which may be annotated retroactively if a collision resolution caused issues.
> **During execution:** Agents do NOT read this file. Context comes from sprint docs and registry.

---

## Log Format

```
### [YYYY-MM-DD HH:MM] [Collision Type] -- Sprint [IDs]
**Trigger:** planning | ship | coder-return
**Sprints:**
  - Sprint [ID] ("[goal]") — [status at time of collision]
**File(s):**
  - `path/to/file.cs` — Sprint [A]: [op] L[range] vs Sprint [B]: [op] L[range]
**Severity:** hard | soft | domain-proximity | coder-drift | coder-drift (escalated) | ship-rebase | archive | advisory
**Resolution:** wait | stack | split-lines | force | accept | revert | rebase-clean | rebase-conflict | auto-proceed
**Decided by:** user (option N) | orchestrator-auto
**Detail:** [what specifically was done]
**Post-ship note:** _(none)_
```

### Collision Types

| Type | Trigger | Severity | Default Action |
|------|---------|----------|----------------|
| File reservation overlap (same lines) | planning | hard | Block — user must choose |
| File reservation overlap (different lines) | planning | soft | Auto-proceed, logged |
| Same directory, different files | planning | domain-proximity | Auto-proceed, logged |
| Coder touched unreserved file (no cross-sprint) | coder-return | coder-drift | Prompt — accept/revert |
| Coder touched unreserved file (cross-sprint) | coder-return | coder-drift (escalated) | Block — user must choose |
| Shipped sprint changed reserved file | ship | ship-rebase | Prompt — rebase/skip |
| Sprint archived due to collision | planning | archive | Logged with archive reason |
| Planning stability warning | planning | advisory | Logged, no action needed |

---

## Entries

<!-- Append new entries below this line. Never delete past entries. -->

### [2026-04-09 00:00] Coder Drift -- Sprint 001
**Trigger:** coder-return
**Sprints:**
  - Sprint 001 ("Add calculated severity to Lark card header") — executing
**File(s):**
  - `Application/Helpers/SeverityEvaluationDetailFormatter.cs` — Sprint 001: modify (full file) — added methods missing from committed HEAD
**Severity:** coder-drift
**Resolution:** accept
**Decided by:** user (option 1)
**Detail:** Coder added FormatNoMatchForLarkNotification(), GetSeverityTitleTag(), GetSeverityHeaderColor(), and "Calculated Severity" line to FormatForLarkNotification(). These methods existed as uncommitted staged changes in the main working tree but were absent from committed HEAD (aac84e2). File added to sprint 001 File Reservations.
**Post-ship note:** _(none)_

### [2026-04-10 00:00] Semantic Dependency -- Sprint 002 vs Sprint 003
**Trigger:** planning
**Sprints:**
  - Sprint 002 ("Remove severity color header from Lark card") — executing (0/1)
  - Sprint 003 ("Fix resolved events sent as firing in Lark routing") — planning
**File(s):**
  - `Infrastructure/Notifications/Lark/Dtos/LarkSendCardMessageRequest.cs` — Sprint 002: remove `Template` from LarkCardHeader vs Sprint 003: needs `Template: "green"` on resolved card
**Severity:** hard
**Resolution:** split-lines
**Decided by:** orchestrator-auto
**Detail:** Sprint 002 originally planned to remove `LarkCardHeader.Template` entirely. Modified sprint 002 plan to keep `Template` property on `LarkCardHeader` — only remove severity-based color usage from firing cards (delete HeaderColor from SendLarkMessageParameters + LarkNotificationService). Sprint 003 will use `Template: "green"` for resolved routing cards. Execution order: sprint 002 first, then sprint 003.
**Post-ship note:** _(none)_
