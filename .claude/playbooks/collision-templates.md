# Collision Templates

> Read this file ONLY when a collision is detected. Do NOT preload.

---

## HARD — File Reservation Conflict

```
══════════════════════════════════════════════════════
 SPRINT COLLISION: HARD — FILE RESERVATION CONFLICT
══════════════════════════════════════════════════════

You're planning "[new sprint goal]" (sprint <NEW_ID>).
Sprint <EXISTING_ID> ("[existing goal]") is currently [phase] ([progress]).

Conflicting file reservations:

  [file path]
    Sprint <EXISTING_ID> holds:  L[range]  ([op] — [description])
    Sprint <NEW_ID> wants:       L[range]  ([op] — [description])
    Overlap:                     L[range]

Choose how to proceed:

  (1) Wait        — pause new sprint until <EXISTING_ID> ships
  (2) Stack       — branch new sprint off <EXISTING_ID>'s branch (serial dependency)
  (3) Split lines — narrow new sprint to non-overlapping range
  (4) Force       — proceed with known overlap, accept merge conflict at ship time

Recommendation: [context-specific recommendation]

Which option? [1/2/3/4]
```
→ Log to conflict-log BEFORE presenting options (severity: `hard`, resolution: pending)
→ Update conflict-log entry with user's choice after they respond

---

## SOFT — Same File, No Line Overlap

```
══════════════════════════════════════════════════════
 SPRINT COLLISION: SOFT — SAME FILE, NO LINE OVERLAP
══════════════════════════════════════════════════════

You're planning "[new sprint goal]" (sprint <NEW_ID>).
Sprint <EXISTING_ID> ("[existing goal]") is currently [phase].

Shared file, non-overlapping regions:

  [file path]
    Sprint <EXISTING_ID> holds:  L[range]  ([op])
    Sprint <NEW_ID> wants:       L[range]  ([op])
    Gap:                         [N] lines apart, no overlap

Risk: Low. Git auto-merges non-overlapping hunks.

  (1) Proceed    — register both, no action needed
  (2) Wait       — hold new sprint until <EXISTING_ID> ships

Proceeding with (1) unless you say otherwise.
```
→ Log to conflict-log with severity `soft`, resolution `auto-proceed`

---

## PROXIMITY — Same Directory, Different Files

```
══════════════════════════════════════════════════════
 SPRINT ADVISORY: DOMAIN PROXIMITY
══════════════════════════════════════════════════════

You're planning "[new sprint goal]" (sprint <NEW_ID>).
Sprint <EXISTING_ID> ("[existing goal]") is currently [phase].

Both sprints create/modify files in the same directory:

  [directory path]
    Sprint <EXISTING_ID>: [file(s)]  ([op])
    Sprint <NEW_ID>:      [file(s)]  ([op])

No file conflict — different files, zero merge risk.

Proceeding with planning.
```
→ Log to conflict-log with severity `domain-proximity`, resolution `auto-proceed`

---

## STABILITY WARNING — Consecutive Archive Failures

```
══════════════════════════════════════════════════════
 PLANNING STABILITY WARNING
══════════════════════════════════════════════════════

The last [N] sprints were archived with 0 subtasks complete:
  [list archived sprints]

Consider:
  (a) Ship an active sprint before starting another
  (b) Narrow scope to a single subtask
  (c) Proceed anyway

This is advisory only — not blocking.
```
→ Log to conflict-log with severity `advisory`

---

## CODER DRIFT — Unreserved File, No Cross-Sprint

```
══════════════════════════════════════════════════════
 DRIFT DETECTED — CODER TOUCHED UNRESERVED FILE
══════════════════════════════════════════════════════

Sprint <A>, Subtask [N] modified:
  [file]:L[range] — [coder's reason]

Cross-sprint check: No other sprint reserves this file.

  (1) Accept — add to sprint <A>'s File Reservations
  (2) Revert — rework coder to undo
  (3) Review — show diff before deciding

Which option? [1/2/3]
```
→ Log to conflict-log with severity `coder-drift`

---

## CODER DRIFT ESCALATED — Cross-Sprint Conflict

```
══════════════════════════════════════════════════════
 DRIFT ALERT — CROSS-SPRINT CONFLICT FROM CODER CHANGE
══════════════════════════════════════════════════════

Sprint <A>, Subtask [N] modified:
  [file]:L[range] — [coder's reason]

Cross-sprint check:
  Sprint <B> reserves [file]:L[range]

╔══════════════════════════════════════════════════╗
║  This unplanned change conflicts with sprint <B> ║
╚══════════════════════════════════════════════════╝

  (1) Revert — rework coder to undo unexpected change only
  (2) Accept + pause sprint <B> — mark as "needs rebase"
  (3) Accept + rebase now — rebase sprint <B>'s worktree immediately
  (4) Review — show diff before deciding

Recommendation: [context-specific]

Which option? [1/2/3/4]
```
→ Log to conflict-log with severity `coder-drift (escalated)`

---

## SHIP REBASE — Post-Merge Cross-Sprint Impact

```
══════════════════════════════════════════════════════
 SPRINT SHIPPED: REBASE CHECK
══════════════════════════════════════════════════════

Sprint <SHIPPED> ("[goal]") shipped to <merge-target>.

Files modified by sprint <SHIPPED>:
  [file list with change type]

Checking impact on other active sprints...

  Sprint <ACTIVE> ("[goal]") — branch: sprint/<n>
    Shared file: [file path]
      Sprint <SHIPPED> modified L[range]
      Sprint <ACTIVE> reserved  L[range]
    Status: Rebase needed

  (1) Auto-rebase sprint <ACTIVE> onto updated <merge-target>
  (2) Manual rebase — resolve in worktree
  (3) Skip — defer to ship time (accept risk)
  (4) Spawn conflict-resolution coder

Recommendation: [context-specific]

Which option? [1/2/3/4]
```

---

## REBASE CONFLICT — Manual Resolution Required

```
══════════════════════════════════════════════════════
 REBASE CONFLICT — MANUAL RESOLUTION REQUIRED
══════════════════════════════════════════════════════

Attempted auto-rebase of sprint <ACTIVE>.

CONFLICT in [file path]:
  Sprint <SHIPPED> modified L[range]
  Sprint <ACTIVE> modified  L[range]

Sprint <ACTIVE> is PAUSED. Choose:

  (1) Resolve manually — open worktree at [path], then: git rebase --continue
  (2) Abort rebase — keep old base, resolve at ship time
  (3) Spawn conflict-resolution coder — agent attempts resolution (shows diff before committing)

Which option? [1/2/3]
```
→ Log to conflict-log with resolution `rebase-conflict`, update after user resolves

---

## INTEGRATION BRANCH SYNC — Target Branch Has Diverged

```
══════════════════════════════════════════════════════
 INTEGRATION BRANCH SYNC ADVISORY
══════════════════════════════════════════════════════

Integration branch: <branch>
Target branch:      <target>
Base commit:        <base-commit>

Target branch has <N> new commit(s) since integration branch was created:
  <list of commit subjects, max 5>

Active sprints on this integration branch: <count>

  (1) Rebase integration branch onto <target> (only if 0 active sprints)
  (2) Merge <target> into integration branch (safe with active sprints)
  (3) Proceed — accept divergence, sync later

Recommendation: (2) if active sprints exist, (1) if none.

Which option? [1/2/3]
```
→ Log to conflict-log with severity `advisory`, collision type `integration-sync`
