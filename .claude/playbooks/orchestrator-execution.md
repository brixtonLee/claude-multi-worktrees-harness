# Orchestrator Playbook — Execution Phase

> Loaded when: Active sprint with unchecked subtasks in registry.
> All CLAUDE.md rules apply.

---

## Parallelization Rules

Parallel ONLY if: different files (zero overlap) AND no data dependencies.

- **Trivial** (1 file, ≤20 lines): Single CODER → VERIFIER, maxTurns 12
- **Small** (≤2 files, ≤50 lines): Single CODER → VERIFIER, maxTurns 15
- **Medium** (3–5 files): Parallel CODERs → VERIFIER, maxTurns 20
- **Large** (>5 files): Parallel CODERs → user review → VERIFIER, maxTurns 25

Max 4 parallel CODERs per sprint.

Cross-sprint parallelization is automatic — different worktrees, zero file contention.

---

## Session Path Resolution (once per execution phase)

Before spawning the first CODER, resolve the current session:

1. List `~/.claude/projects/<slug>/<sessionId>/subagents/` — note the path for agentId capture
2. Record the current `sessionId` (from the session JSONL filename matching this conversation)
3. Store both values for use in agent records and sprint-summary

The session ID is the UUID in the JSONL filename at `~/.claude/projects/<slug>/<sessionId>.jsonl`.

---

## Spawn CODERs

Read ONLY the active sprint's docs: `docs/sprints/sprint-<ID>/context.md` + `plan.md`. Do not read SPEC.md or explore.

Use `Task` tool. For parallel subtasks, spawn simultaneously:

```
Task(subagent_type="coder", description="Coder: Sprint <ID> Subtask N — [short desc]", prompt="
SPRINT: <ID>
WORKTREE_ROOT: [absolute path to ../ai-agents-wt-<ID>]
maxTurns: [from complexity tier]
check-profile: [from plan.md subtask annotation]
Task: [name]
Subtask: [N] — [description]
Layer: [layer]
Files to modify: [{WORKTREE_ROOT}/path:Lnn]
Files to read first: [{WORKTREE_ROOT}/path:Lnn]
Key details: [from sprint plan.md]
Acceptance criteria for this subtask: [relevant subset]
Constraints: [task-specific]
")
```

---

## After Each CODER Returns

Execute ALL steps in this order, no skipping. Steps 1–2 persist state to disk FIRST so that PreCompact captures accurate status if compaction triggers mid-processing.

1. **Parse structured return** — extract `Files Changed`, `Unexpected Files`, `Status`
2. **Checkpoint to disk** (atomic — do both before any other processing):
   a. **Check off subtask** in `docs/sprints/sprint-<ID>/plan.md` (`- [ ]` → `- [x]`)
   b. **Append to progress** in `docs/sprints/sprint-<ID>/progress.md`:
      ```
      ### [YYYY-MM-DD] [Task Name] — Subtask N: [Name]
      **Files changed:** [list from coder return]
      **What was done:** [1-3 sentences]
      ```
3. **Drift check** — if `Unexpected Files` is non-empty:
   a. Check unexpected files against File Reservations for ALL other active sprints
   b. **Cross-sprint conflict found:** Read `.claude/playbooks/collision-templates.md`, use CODER DRIFT ESCALATED template. Log with severity `coder-drift (escalated)`.
   c. **No cross-sprint conflict:** Read `.claude/playbooks/collision-templates.md`, use CODER DRIFT template. Log with severity `coder-drift`.
4. **Capture agentId** — list `~/.claude/projects/<slug>/<sessionId>/subagents/agent-*.meta.json`, diff with pre-dispatch listing to find the new file. Extract agentId from filename (e.g., `agent-a1b1afe4ed258c7fe.meta.json` → `a1b1afe4ed258c7fe`).
5. **Append agent record to cost log** — write one JSON line to `docs/sprints/sprint-<ID>/cost.jsonl`:
    ```json
    {"type":"agent","sprintId":"<ID>","sessionId":"[UUID]","agentId":"[agent-ID]","agentType":"coder","subtask":"N — [name]","complexityTier":"[tier]","maxTurns":[N],"checkProfile":"[profile]","status":"[done|blocked|partial]","filesChanged":[N],"filesCreated":[N],"buildPassed":[bool],"testsPassed":[bool],"isRework":false,"reworkPass":null}
    ```
6. **Update registry** — Active Sprints progress column
7. If CODER status is `blocked` — STOP and assess before spawning next CODER
8. If build failure reported — spawn fix CODER before proceeding

### Dispatch Order

Process subtasks in numerical order. When you encounter a parallel group:
1. Spawn all subtasks in that group simultaneously
2. Wait for all to complete (Parallel Group Checkpoint below)
3. Continue to the next subtask/group

When you encounter a `sequential` subtask:
1. Spawn one CODER
2. Wait for completion, check off subtask
3. Continue to the next subtask/group

### Parallel Group Checkpoint

After ALL CODERs in a parallel group complete:
1. Update sprint context Current State: `**Group [A] complete:** [1-2 sentences]`
2. Safe compaction point — docs contain everything needed to resume.
3. If compacting here, **increment `Compaction Count`** in sprint context.md before compacting.

---

## Drift Detection

**Triggers:**
- After every 3 completed subtasks (within a sprint)
- **Once before spawning VERIFIER** — regardless of subtask count

### Intra-Sprint Drift

1. `git -C <worktree-path> diff --name-only <sprint-start-commit>..HEAD` — verify no files modified outside manifest
2. Run project-specific drift checks from CLAUDE.md. Use `grep -m 30 -n`.
3. Project-specific checks (run in worktree):
   - `grep -rn "using.*Infrastructure" {WORKTREE_ROOT}/src/AiAgents.Domain/` — zero matches (domain layer isolation)
   - `grep -rn "\.Result\b\|\.Wait()" {WORKTREE_ROOT}/src/AiAgents.Infrastructure/` — zero matches (async discipline)

If drift detected: STOP, report violation, spawn CODER to fix.

### Cross-Sprint Drift

Triggered after every coder return with non-empty `Unexpected Files`. See "After Each CODER Returns" step 2 above for the full flow. All cross-sprint drift events are logged to `docs/sprints/conflict-log.md`.

---

## Spawn VERIFIER

After all CODERs complete:

```
Task(subagent_type="verifier", description="Verifier: Sprint <ID> [task name]", prompt="
SPRINT: <ID>
WORKTREE_ROOT: [absolute path to ../ai-agents-wt-<ID>]
Task: [name]
Files changed: [paths from CODER results]
Acceptance criteria: [from sprint plan.md]
Sprint contract: [from sprint plan.md — include if present]
Active sprints with shared files: [from registry — list sprint IDs and shared file paths]
")
```

### After VERIFIER Returns

**Capture agentId** (same subagents dir diff as coder step 4b).

**Append agent record to cost log** — write one JSON line to `docs/sprints/sprint-<ID>/cost.jsonl`:
```json
{"type":"agent","sprintId":"<ID>","sessionId":"[UUID]","agentId":"[agent-ID]","agentType":"verifier","subtask":"verification","complexityTier":"[tier]","maxTurns":null,"checkProfile":null,"status":"[done]","filesChanged":0,"filesCreated":0,"buildPassed":[bool],"testsPassed":[bool],"isRework":false,"reworkPass":null}
```

### Handle Verdict

- **SHIP / SHIP WITH FOLLOW-UPS** → Read `.claude/playbooks/orchestrator-shipping.md`
- **REWORK** → Read `.claude/playbooks/orchestrator-rework.md`
