# Pass 1 — Build & Test Gate

Run build, test, and format commands from CLAUDE.md "Build Commands" (each as separate tool call). If `WORKTREE_ROOT` is provided, run in worktree (e.g., `dotnet build {WORKTREE_ROOT}/AiAgents.sln`).

If ANY fails:
- Read sprint context (`docs/sprints/sprint-<ID>/context.md`) for `**Baseline Build:**` and `**Baseline Tests:**`
- If the same tests were already failing at sprint start → pre-existing, NOT grounds for REWORK
- If only new failures → return `REWORK` immediately with failure details
- If mix of pre-existing + new → REWORK only for new failures, note pre-existing as context

## Pass 2.5 — Runtime Verification (when sprint contract includes runtime checks)

If sprint plan (`docs/sprints/sprint-<ID>/plan.md`) Sprint Contract includes curl/endpoint/DB checks:
1. Ensure app is running (`curl -s localhost:PORT/health` or equivalent)
2. Execute each runtime check from the sprint contract
3. If app isn't running and contract requires it, attempt `dotnet run` in background
4. If runtime checks can't be executed (no server, no seed data), note as WARN — not automatic PASS

This pass catches bugs where code compiles and tests pass but the feature doesn't work end-to-end.
