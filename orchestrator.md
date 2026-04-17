# Orchestrator Playbook — Phase Router

You (the main Claude Code session) execute this playbook directly. This is NOT a sub-agent — you read this file and follow the instructions yourself.

All CLAUDE.md rules apply.

## CRITICAL RULES

1. **NEVER edit source files directly.** `Write`/`Edit` are ONLY for `docs/` files. ALL source code changes go through CODER sub-agents.
2. **ALWAYS spawn CODER and VERIFIER sub-agents.** No exceptions. No inlining. No skipping VERIFIER for any task size.
3. **Planning flows directly into execution.** After writing sprint docs, immediately spawn CODERs. Do NOT stop for `/compact` or user re-entry.
4. **NEVER spawn agents via Bash.** ALWAYS use the `Task` tool with `subagent_type`. Bash is for build/test/grep only.
5. **You ARE the orchestrator.** Do NOT spawn an orchestrator sub-agent. Sub-agents cannot spawn other sub-agents.
6. **ALWAYS log collisions** to `docs/sprints/conflict-log.md`. Every collision event — hard, soft, advisory — gets logged. No exceptions.

---

## Mode Detection

**Primary path (ExitPlanMode entry):**
- Route to **Planning mode** — user hooks trigger orchestrator after every ExitPlanMode.

**Recovery path (after /compact or new session):**
1. Run `git branch --show-current` to identify the current branch
2. Read `docs/sprints/registry.md` — match the branch to an active sprint's Branch column
3. If a matching sprint is found, route by its verdict:
   - `Last Verdict: REWORK` → **Rework mode**
   - Unchecked subtasks remain → **Execution mode**
   - All subtasks complete → spawn VERIFIER
4. If no matching sprint (e.g., on `develop` or `main`) → **Planning mode**
5. User message matches "check registry" → **Execution mode** (read registry to identify sprint)

Only THIS session's sprint verdict matters. Other active sprints are ignored.

---

## Phase Loading

Based on mode detection, read ONLY the playbook you need. Do NOT preload other phases.

- **Planning** → `.claude/playbooks/orchestrator-planning.md` — No active sprints, new task
- **Execution** → `.claude/playbooks/orchestrator-execution.md` — Active sprint with unchecked subtasks
- **Ship/Archive** → `.claude/playbooks/orchestrator-shipping.md` — VERIFIER returned SHIP, or user requests archive
- **Rework** → `.claude/playbooks/orchestrator-rework.md` — VERIFIER returned REWORK

**Collision templates** are in `.claude/playbooks/collision-templates.md` — read ONLY when a collision is detected during any phase, not preemptively. Once the collision is resolved (user has chosen an option and the resolution is logged), the template content is no longer needed — do not retain it in context.

**Verdict calibration templates** are in `.claude/references/verify/verdict-calibration.md` — loaded by the VERIFIER agent when making the final verdict decision, not at the start of verification.

---

## 1. Sprint Lifecycle (quick reference)

### Initialize Integration Branch (optional — multi-session mode)
1. Read `## Integration Branch` in registry
2. If Status is `active` → reuse existing integration branch, skip to Create Sprint
3. If Status is `inactive` and user requests integration branch (or multiple sessions expected):
   - Determine target branch (user specifies, default: `develop`)
   - Create branch: `git branch integration/<target>-<YYYYMMDD> <target>`
   - Update registry `## Integration Branch`: set Branch, Target, Base Commit (`git rev-parse <target>`), Created, Status `active`
4. If Status is `inactive` and no integration branch requested → skip (legacy flow)

### Create Sprint
1. Next sprint ID from registry (3-digit zero-padded: 001, 002, ...)
2. Determine branch base:
   - Read `## Integration Branch` in registry — if Status is `active`, use that branch as base
   - Otherwise, use the target branch (e.g., `develop`)
3. Create worktree: `git worktree add ../ai-agents-wt-<ID> -b sprint/<n> <base-branch>`
4. Create `docs/sprints/sprint-<ID>/` with `context.md`, `plan.md`, `progress.md`
5. Register in `registry.md` (Active Sprints + File Reservations + Rebase Status)
6. Run collision check against existing File Reservations

### Ship Sprint → read `.claude/playbooks/orchestrator-shipping.md`
### Archive Sprint → read `.claude/playbooks/orchestrator-shipping.md`

---

## 2. Sub-Agent Return Budgets

Sub-agent returns enter the orchestrator's context window **verbatim**. Return formats are defined in each agent's `.md` file. The orchestrator does NOT inline return formats in dispatch prompts — agents follow their own.

- **CODER (standard):** target 400–600 tokens, hard max 1,000
- **CODER (rework):** target 300–500 tokens, hard max 800
- **VERIFIER (SHIP):** target 300–500 tokens, hard max 800
- **VERIFIER (REWORK):** target 500–800 tokens, hard max 1,200

If a return exceeds the hard max → subtask was too large or needs further decomposition.

---

## 3. CODER maxTurns Tiering

Override the agent's frontmatter `maxTurns` in the dispatch prompt based on complexity:

- **Trivial** (1 file, ≤20 lines): maxTurns 12
- **Small** (≤2 files, ≤50 lines): maxTurns 15
- **Medium** (3–5 files): maxTurns 20
- **Large** (>5 files): maxTurns 25

---

## 4. CODER Check Profiles

Include `check-profile` in the dispatch prompt so coders only run relevant self-checks:

- **`query`** — Domain layer isolation, proper DI usage, no direct DbContext in services
- **`service`** — Service interfaces, DI registration, CancellationToken threading, error handling
- **`endpoint`** — DTO conventions, controller service injection, validation
- **`background`** — Cancellation handling, scoped service resolution, error logging
- **`full`** — All checks (use for cross-cutting changes)

---

## 5. Context Recovery (after /compact or new session)

Recovery relies on `plan.md` and `progress.md` being up-to-date on disk. The execution playbook guarantees this: after each coder returns, subtask check-off and progress append happen **before** any other processing (drift checks, cost logging, etc.). This means PreCompact always captures accurate subtask status.

1. **Identify this session's sprint:** Run `git branch --show-current`, then read `docs/sprints/registry.md` and match the branch to an active sprint's Branch column.
1b. Check `## Integration Branch` — if Status is `active`, verify branch exists: `git branch --list integration/*`. If missing, alert user and halt.
2. Check for `docs/sprints/sprint-<ID>/exploration-notes.md` — if exists, planning was interrupted:
   - Read exploration-notes.md
   - Resume planning from where it left off (write sprint docs from notes)
   - Keep exploration-notes.md in the sprint folder as persistent planning record
3. Clean up stale agent scratch files in worktrees: `.coder-scratch.md`, `.verifier-scratch.md`
4. Check Rebase Status — if THIS session's sprint has "Needs Rebase: yes", resolve before continuing
5. **Process only this session's sprint** (ignore other active sprints — they belong to other sessions):
   a. Read `docs/sprints/sprint-<ID>/context.md` — note `Sprint Started At` and `Compaction Count` for cost tracking
   b. Read `docs/sprints/sprint-<ID>/plan.md`
   c. Route by this sprint's state:
      - `Last Verdict: REWORK` → read `.claude/playbooks/orchestrator-rework.md`
      - Has unchecked subtasks → find the first unchecked subtask and read its `parallel-group` annotation:
        - If parallel group (A, B, C...): find all unchecked subtasks in that same group → spawn them in parallel
        - If `sequential`: spawn that single CODER
        - If no annotation: spawn as single CODER
      - All subtasks complete → spawn VERIFIER
   d. After current group/subtask completes, continue to next per dispatch order
6. If on `develop`, `main`, or an unrecognized branch with no matching sprint → route to Planning mode
