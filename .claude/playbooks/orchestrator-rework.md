# Orchestrator Playbook — Rework Phase

> Loaded when: VERIFIER returned REWORK.
> All CLAUDE.md rules apply.

---

## Rework Flow

1. Update sprint context: `Last Verdict: REWORK — [task] — [date]`
2. Write blocker items to sprint plan under "Rework Items"
3. If rework items reference files NOT in sprint context's File Manifest → add them to the manifest AND update File Reservations in registry
4. Spawn CODER in rework mode:
   ```
   Task(subagent_type="coder", description="Coder: Sprint <ID> Rework — fix [issue]", prompt="
   REWORK pass [1|2|3]
   SPRINT: <ID>
   WORKTREE_ROOT: [absolute path]
   maxTurns: [15 for small rework, 20 for medium]
   check-profile: [from original subtask or 'full' if cross-cutting]
   Rework items from VERIFIER:
   - [paste verbatim]
   Files to fix: [paths from rework items]
   Original acceptance criteria: [from sprint plan.md]
   ")
   ```
5. **Capture agentId** (same subagents dir diff as execution step 4b).
6. **Append rework agent record to cost log** — write one JSON line to `docs/sprints/sprint-<ID>/cost.jsonl`:
   ```json
   {"type":"agent","sprintId":"<ID>","sessionId":"[UUID]","agentId":"[agent-ID]","agentType":"coder","subtask":"rework — [issue]","complexityTier":"[tier]","maxTurns":[N],"checkProfile":"[profile]","status":"[done|blocked]","filesChanged":[N],"filesCreated":[N],"buildPassed":[bool],"testsPassed":[bool],"isRework":true,"reworkPass":[1|2|3]}
   ```
6. After fix, re-spawn VERIFIER
7. Maximum 3 REWORK loops. After 3 failures, STOP and present rollback options:

   **Option A — Stash and reset:** `git -C <worktree> stash` changes since sprint start commit. Stash can be inspected later with `git stash show -p`.
   **Option B — Continue manually:** User takes over from current state. Leave all docs intact.
   **Option C — Archive and restart:** Run Archive Sprint flow (`.claude/playbooks/orchestrator-shipping.md`), then begin fresh sprint with narrower scope.

   Present all three options and wait for user choice.
