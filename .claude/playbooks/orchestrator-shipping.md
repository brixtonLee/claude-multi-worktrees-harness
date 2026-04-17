# Orchestrator Playbook — Shipping Phase

> Loaded when: VERIFIER returned SHIP/SHIP WITH FOLLOW-UPS, or user requests sprint archive.
> All CLAUDE.md rules apply.

---

## SHIP / SHIP WITH FOLLOW-UPS — Sprint End Checklist

> MANDATORY: Execute every step in order. Do not skip. Do not proceed to step N+1 until step N is done.

1. [ ] Update sprint context: set `Last Verdict: SHIP — [task] — [date]`
2. [ ] If VERIFIER returned follow-ups → append each to `docs/tech-debt.md` using its format template
3. [ ] **Acceptance Criteria Reconciliation** (MANDATORY — do not skip even during collision handling):
   a. Read ALL acceptance criteria from `docs/sprints/sprint-<ID>/plan.md`
   b. For each criterion, classify:
      - **Verifier-confirmed** (build/test results, code patterns, static checks) → check off in plan.md (`- [ ]` → `- [x]`)
      - **Requires runtime/manual verification** (visual output, external service behavior, end-to-end flows) → leave unchecked
   c. Collect ALL unchecked criteria → append to `docs/manual-qa-checklist.md` using its format template
   d. **Self-check:** count unchecked criteria in plan.md — must equal count in new manual-qa entry. If mismatch, fix before proceeding.
4. [ ] Run build + test in worktree (see CLAUDE.md Build Commands) — record results
5. [ ] Execute Ship Sprint flow:
   - Run drift detection (see execution playbook)
   - Run cross-sprint rebase check (below)
   - Determine merge target: read `**Merge Target**` from `docs/sprints/sprint-<ID>/context.md`
   - Merge to target: `git checkout <merge-target> && git merge sprint/<n>`
   - Update registry (remove sprint row, clean file reservations, clean rebase status)
   - Remove worktree: `git worktree remove ../ai-agents-wt-<ID>`
   - Delete sprint branch: `git branch -d sprint/<n>`
6. [ ] Append completed sprint entry to `docs/completed-sprints.md` using its format template
6b. [ ] **Generate sprint metadata summary (JSONL)** — see Cost & Scoring Report section below
7. [ ] Report to user: delivered items, files changed, test results, any QA items, any rebase impacts on other sprints. Suggest running `/harness-score <ID>` for full score breakdown.

After completing ALL 7 steps, confirm: **"Sprint End Checklist: ALL 7 STEPS COMPLETE"**

---

## Ship-Time Cross-Sprint Check

After merging a sprint's branch to its merge target (integration branch or target branch):

1. `git diff --name-only <sprint-start-commit>..HEAD` for the shipped sprint
2. For each other active sprint in registry:
   - Compare shipped files against that sprint's File Reservations
   - If overlap found → Read `.claude/playbooks/collision-templates.md`, use SHIP REBASE template
3. Mark "Needs Rebase: yes" in registry Rebase Status table
4. Log to conflict-log with severity `ship-rebase`
5. If clean rebase: update line references in affected sprint's `context.md`, log resolution `rebase-clean`
6. If conflict rebase → Read `.claude/playbooks/collision-templates.md`, use REBASE CONFLICT template. Log with resolution `rebase-conflict`, update after user resolves.

---

## Conflict Logging

### When to Log

Every collision event, regardless of severity or resolution. The log is append-only and permanent.

### How to Log

Append to `docs/sprints/conflict-log.md` using the format template defined in that file.

Required fields: timestamp, collision type, trigger, sprints involved, files, severity, resolution, decided-by, detail.

Leave "Post-ship note" as `_(none)_`.

### Post-Ship Annotation

If a shipped sprint causes issues traceable to a collision resolution, annotate the original conflict-log entry's "Post-ship note" field with the issue description and link to the problematic file(s). This is the ONLY case where an existing entry is modified.

### What Gets Logged

1. Hard collision at planning → log before presenting options, update resolution after user chooses
2. Soft collision at planning → log with resolution `auto-proceed`
3. Domain proximity at planning → log with resolution `auto-proceed`
4. Coder drift (no cross-sprint) → log with resolution after user chooses
5. Coder drift (cross-sprint) → log with resolution after user chooses
6. Ship-time rebase needed → log with rebase result (`rebase-clean` or `rebase-conflict`)
7. Ship-time rebase conflict → log with resolution after user chooses
8. Planning stability warning triggered → log with severity `advisory`
9. Sprint archived due to collision → log with archive reason

---

## Archive Sprint

1. Append to `docs/archived-sprints.md` (same format as current, add worktree + branch info)
2. Remove sprint from `registry.md` Active Sprints + File Reservations + Rebase Status
3. Remove worktree: `git worktree remove ../ai-agents-wt-<ID>` (use `--force` if uncommitted changes)
4. Log to `docs/sprints/conflict-log.md` if archive was triggered by a collision
5. Clean up any stale `.coder-scratch.md` or `.verifier-scratch.md` in the worktree before removal
6. **Generate sprint metadata summary** — follow the Cost & Scoring Report section below, with outcome `"ARCHIVED"`

---

---

## Cost & Scoring Report

> Referenced by: Sprint End Checklist step 6b, Archive Sprint step 6.

Execute ALL sub-steps in order:

### Step A — Gather Sprint Metadata

1. Read `docs/sprints/conflict-log.md` — count entries matching this sprint ID, classify by severity (hard/soft/drift/escalated)
2. Read `docs/sprints/sprint-<ID>/plan.md` — count planned files from File Manifest, compare with actual files changed from progress.md
3. Read `docs/sprints/sprint-<ID>/context.md` — get complexity tier, compaction count, sprint started at

### Step B — Write Sprint Summary Record

Aggregate metadata into the sprint-summary JSONL record:

```json
{"type":"sprint-summary","sprintId":"<ID>","sessionId":"[UUID]","goal":"[goal]","complexityTier":"[tier]","outcome":"[SHIP|SHIP WITH FOLLOW-UPS|ARCHIVED]","startedAt":"[ISO]","completedAt":"[ISO]","agents":{"totalSpawns":[N],"coderSpawns":[N],"verifierSpawns":[N],"reworkCoderSpawns":[N]},"reworkLoops":[N],"compactionCount":[N],"files":{"changed":[N],"created":[N],"planned":[N],"driftFiles":[N]},"subtasks":{"total":[N],"completed":[N]},"collisions":{"count":[N],"hard":[N],"soft":[N],"drifts":[N]}}
```

Append as the **last line** of `docs/sprints/sprint-<ID>/cost.jsonl`.

> **Note:** Token totals, cost estimates, and scoring are NOT computed here. They are derived from Claude session JSONL by `scripts/harness-score.ps1`. Use `/harness-score <ID>` to compute scores after shipping.

---

## Keep Sprint Docs

`docs/sprints/sprint-<ID>/` directory is kept for historical reference after both ship and archive.
