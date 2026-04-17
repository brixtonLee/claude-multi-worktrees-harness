# Pass 2 — Architecture Compliance

1. Read `**Sprint Start Commit:**` from sprint context (`docs/sprints/sprint-<ID>/context.md`). If `WORKTREE_ROOT` provided, run `git -C {WORKTREE_ROOT} diff --stat <sprint-start-commit>..HEAD`. Fall back to `git diff --stat HEAD` if no SHA recorded.
2. Read CLAUDE.md "Architecture Rules" and any "NEVER DO THIS" section
3. Run architecture-specific grep checks (use `grep -m 30 -n`). If `WORKTREE_ROOT` provided, run in worktree:
   - `grep -rn "using.*Infrastructure" {WORKTREE_ROOT}/src/AiAgents.Domain/` — zero matches (domain layer isolation)
   - `grep -rn "\.Result\b\|\.Wait()" {WORKTREE_ROOT}/src/AiAgents.Infrastructure/` — zero matches (async discipline)
4. Verify: layer direction respected, DI used for new classes, no forbidden patterns, no files outside sprint context manifest

## Scope Discipline (also checked here)

- No files modified outside the sprint's File Manifest
- No scope creep beyond acceptance criteria

## Regression Check

- Changed file in a `DO NOT MODIFY` line in sprint progress?
- Existing passing test now fails?
- Public interface signature changed without updating callers?
