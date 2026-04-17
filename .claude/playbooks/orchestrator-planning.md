# Orchestrator Playbook — Planning Phase

> Loaded when: ExitPlanMode entry point, new task to plan. Active sprints may exist.
> All CLAUDE.md rules apply. Follow Plan Mode Context Strategy from CLAUDE.md.

---

## Step -1 — Integration Branch Setup (MANDATORY)

### 1. Fetch Latest

`git fetch origin` — always fetch before any branch operations.

### 2. Resolve Integration Branch

Read `## Integration Branch` section in `docs/sprints/registry.md`.

**If Status is `active`:**
- Verify branch exists: `git branch --list <branch-name>` — if missing, STOP and alert user
- Check out and fast-forward to latest target: `git checkout <branch-name>` then `git merge origin/<target> --ff-only`
  - If ff-only fails (integration branch has diverged) → warn user, do NOT force reset
- Integration branch is the base for new sprints

**If Status is `inactive`:**
- Determine target branch (default: `develop`)
- Create integration branch from latest remote target: `git checkout -b integration/<target>-<YYYYMMDD> origin/<target>`
- Update registry `## Integration Branch`:
  - **Branch:** `integration/<target>-<YYYYMMDD>`
  - **Target:** `<target>`
  - **Base Commit:** output of `git rev-parse HEAD`
  - **Created:** today's date
  - **Status:** `active`
- Integration branch is the base for new sprints

---

## Step 0 — Multi-Sprint Collision Check (MANDATORY)

1. Read `docs/sprints/registry.md` — get all active sprints and their File Reservations
2. After the user describes the new sprint's scope, build a preliminary file manifest
3. Compare preliminary manifest against File Reservations table:
   - **Hard collision** (same file + overlapping lines or both create) → Read `.claude/playbooks/collision-templates.md`, use HARD template. Log to conflict-log BEFORE presenting options.
   - **Soft collision** (same file, non-overlapping lines) → Read `.claude/playbooks/collision-templates.md`, use SOFT template. Log with `auto-proceed`.
   - **Domain proximity** (same directory, different files) → Read `.claude/playbooks/collision-templates.md`, use PROXIMITY template. Log with `auto-proceed`.
4. **Planning stability check:** Run `tail -40 docs/archived-sprints.md` — count consecutive archived sprints with 0 subtasks complete. If >= 2 consecutive, read `.claude/playbooks/collision-templates.md` for STABILITY WARNING template, log as `advisory`.

## Step 0.5 — Sprint Start Validation (MANDATORY)

1. Validate `docs/sprints/registry.md` structure — ensure all table headings present
2. Check `docs/sprints/conflict-log.md` for recent entries with non-empty "Post-ship note" fields — alert user if any reference files relevant to the new sprint
3. Check `docs/manual-qa-checklist.md` for unchecked items from previous sprints — report count

---

## Step 1 — Explore and Decompose

> **Context budget enforcement:** Follow CLAUDE.md "Plan Mode Context Strategy" strictly. All findings go to `docs/sprints/exploration-notes.md` — not held in context.

### 10-Step Exploration Workflow

1. **Tree-first:** `tree -L 2 [relevant directories]` — understand structure before reading any files
2. **Grep for patterns:** `grep -rn -m 5 "[pattern]" [directory]` — find existing conventions, not file contents
3. **Write to exploration-notes.md:** Create `docs/sprints/exploration-notes.md` — dump structure + grep findings
4. **Pin line ranges:** For each candidate file, `grep -n "[target]" file.cs` — record exact line numbers in exploration-notes
5. **Scoped reads only:** Read ONLY the pinned line ranges (±10 lines for context). Never full files > 50 lines.
6. **SPEC lookup (targeted):** `grep -n "##" docs/SPEC.md` → read only the section relevant to the task. Distill key details into exploration-notes.
7. **Recent history (tail):** `tail -40 docs/completed-sprints.md` — check what previous sprints delivered. `tail -40 docs/archived-sprints.md` — check for related abandoned work.
8. **Tech debt scan:** `grep -B2 -A6 "[keyword]" docs/tech-debt.md` — check for relevant items. Mark addressed items as Resolved.
9. **Decompose:** Using exploration-notes as reference, decompose task into subtasks with parallel groups. For subtasks involving SPEC synchronization checklists, ensure ALL steps are represented.
10. **Context checkpoint:** If context > 50% used, `/compact` now — exploration-notes.md survives and recovery will resume planning from notes.

### Pin Line Numbers (Step 1.5)

For each file in planned subtasks, run `grep -n` or scoped `Read` to pin exact line ranges. Do this in the main session — no sub-agent needed.

Skip line ranges only when: file is new, change is file-wide, or file is <50 lines.

---

## Step 2 — Create Sprint and Write Context

Execute Sprint Lifecycle → Create Sprint (orchestrator.md Section 1). Then write sprint context:

`docs/sprints/sprint-<ID>/context.md`:
```markdown
# Sprint <ID> Context — [Sprint Goal]

## Sprint Info
**ID:** <ID>
**Branch:** sprint/<n>
**Worktree:** ../ai-agents-wt-<ID>
**Merge Target:** integration/<target>-<date> | <target-branch>

## Current State
**Last Verdict:** none
**Date:** [YYYY-MM-DD]
**Sprint Start Commit:** [SHA from git rev-parse HEAD]
**Sprint Started At:** [ISO 8601 timestamp, e.g. 2026-04-10T14:30:00Z]
**Baseline Build:** pass | fail — [summary if fail]
**Baseline Tests:** pass | fail — [N passed, M failed if fail]
**Compaction Count:** 0

## File Manifest
### To Modify
- `path/to/file.cs:L50-85` — [why, line range for localized changes]
- `path/to/file.cs` — [why, full file for broad changes or small files]

### To Create
- `path/to/file.cs` — [why]

### To Read (reference only)
- `path/to/file.cs:L100-150` — [what it contains]
```

## Step 3 — Write Sprint Plan

`docs/sprints/sprint-<ID>/plan.md`:
```markdown
# Sprint <ID> Plan — [Task Name]

## Task: [name]
**Complexity:** [trivial/small/medium/large]
**Scope:** [1-sentence scope boundary — what is IN and OUT]
**Approach:** [1-sentence implementation strategy]

### Subtasks
- [ ] 1. [subtask] — layer: [layer] — files: [list] — parallel-group: [A/B/sequential] — check-profile: [query/service/endpoint/background/full]

### Key Details (distilled from SPEC)
[Actual content the CODER needs — not "see section X" but the details themselves]

### Acceptance Criteria
- [ ] [criterion]

### Sprint Contract — Testable Behaviors (medium/large only)
[Concrete, runnable checks — see Step 3.5]

### Rework Items
[empty — populated by orchestrator if VERIFIER returns REWORK]
```

`docs/sprints/sprint-<ID>/progress.md`:
```markdown
# Sprint <ID> Progress

> **Purpose:** Completed subtask archive for this sprint.
> **Updated by:** ORCHESTRATOR after each subtask completes.

---

## Entries

<!-- Append new entries below. -->
```

Create empty `docs/sprints/sprint-<ID>/cost.jsonl` (JSONL is headerless — no initial content needed).

Update `docs/sprints/registry.md`:
- Add row to Active Sprints table
- Add rows to File Reservations table from manifest
- Add row to Rebase Status table

If any of these conditions are true, append to `docs/decisions-log.md`:
- The approach deviates from an existing codebase pattern
- A SPEC requirement is intentionally deferred or descoped
- Multiple valid implementation strategies existed and one was chosen
- A tech-debt item influenced the sprint scope

### Step 3.5 — Sprint Contract (medium/large complexity only)

Write testable behaviors in the sprint plan under Sprint Contract. Each behavior must be a concrete, runnable check. Tailor to the specific subtasks. Skip for trivial/small tasks.

## Step 4 — Verify Completeness

Self-check before proceeding:
- Sprint plan has ALL distilled details (no "see SPEC" references)?
- Sprint context lists EVERY file to create, modify, and read?
- "To Modify" entries include line ranges for localized changes?
- Parallel groups have no file overlap?
- Acceptance criteria are concrete and verifiable?
- Sprint contract (if applicable) has runnable commands?
- Sprint contract behaviors collectively cover all acceptance criteria?
- No sprint contract test is unrelated to any acceptance criterion?
- File Reservations in registry match the sprint manifest exactly?
- No unresolved File Reservation overlaps with other active sprints?
- SPEC synchronization checklists (e.g., calculated fields) are fully represented?
- Each subtask has a `check-profile` annotation?

## Step 5 — Clean Up and Proceed to Execution

1. **Delete** `docs/sprints/exploration-notes.md` — all findings are now in sprint docs
2. Read `.claude/playbooks/orchestrator-execution.md`
3. Immediately proceed to execution. Do NOT stop.
