# CLAUDE.md

This file governs **how Claude Code operates** on this codebase.

## Agent Flow

You (the main Claude Code session) ARE the orchestrator. Do NOT spawn an orchestrator sub-agent — sub-agents cannot spawn other sub-agents, so nesting the orchestrator breaks the entire pipeline.

```
/plan → you (main agent) enter plan mode
      → ExitPlanMode triggers execution
      → read orchestrator.md in project root for phase router
      → phase router tells you which playbook to load
      → Integration Branch Check → Multi-Sprint Collision Check → read registry → create worktree + sprint docs
      → immediately proceed to execution (no /compact pause)
      → spawn coder(s) via Task tool → spawn verifier via Task tool → REWORK loop if needed → SHIP
```

### After ExitPlanMode

1. Read `orchestrator.md` in the project root — it contains the phase router
2. Follow the router to load ONLY the playbook for your current phase
3. Do NOT read all playbooks — load one phase at a time

### Agent Architecture

| Role | Location | Spawned How |
|------|----------|-------------|
| Orchestrator (YOU) | `orchestrator.md` (project root) → `.claude/playbooks/` | Not spawned — you ARE this role |
| Coder | `.claude/agents/coder.md` | `Task(subagent_type="coder", ...)` |
| Verifier | `.claude/agents/verifier.md` | `Task(subagent_type="verifier", ...)` |

### Shared State Files

| File | Purpose | Updated By |
|------|---------|------------|
| `docs/sprints/registry.md` | Central sprint dashboard + file reservations + integration branch tracking | Orchestrator |
| `docs/sprints/conflict-log.md` | Collision audit trail (append-only) | Orchestrator |
| `docs/sprints/sprint-<ID>/context.md` | Per-sprint working state | Orchestrator |
| `docs/sprints/sprint-<ID>/plan.md` | Per-sprint task breakdown + sprint contract | Orchestrator |
| `docs/sprints/sprint-<ID>/progress.md` | Per-sprint completed work (append-only) | Orchestrator |
| `docs/sprints/sprint-<ID>/exploration-notes.md` | Planning scratchpad (persisted in sprint folder) | Orchestrator |
| `docs/completed-sprints.md` | Delivery history (SHIP'd sprints only) | Orchestrator |
| `docs/archived-sprints.md` | Sprint history (abandoned only) | Orchestrator |
| `docs/decisions-log.md` | Architecture decisions | Any role |
| `docs/tech-debt.md` | Out-of-scope issues | Verifier |
| `docs/manual-qa-checklist.md` | Post-SHIP acceptance criteria needing manual verification | Orchestrator |

### Context Recovery (after /compact or new session)

1. Run `git branch --show-current` → match to an active sprint in `docs/sprints/registry.md`
   - If Integration Branch Status is `active`, verify the branch exists locally
2. Check for `docs/sprints/sprint-<ID>/exploration-notes.md` — if exists, planning was interrupted → resume planning
3. Clean up stale agent scratch files: `.coder-scratch.md`, `.verifier-scratch.md` from previous sessions
4. Check Rebase Status — resolve pending rebases for THIS session's sprint only
5. Process only this session's sprint (other active sprints belong to other sessions):
   a. Read `docs/sprints/sprint-<ID>/context.md` + `plan.md`
   b. Route by sprint state: REWORK verdict → rework phase; unchecked subtasks → execution; all complete → spawn VERIFIER
   c. Spawn CODERs per dispatch order
6. If no matching sprint found → route to Planning mode

---

## Plan Mode Context Strategy

Planning must complete with enough context remaining for the full execution cycle (coder→verifier→rework). These rules prevent plan-mode exploration from consuming the context window.

### Exploration Budget

| Action | Max Context Cost | Technique |
|--------|-----------------|-----------|
| Source file exploration | 30 lines per file | `grep -m 30 -n` or scoped `Read` with line range |
| SPEC.md lookup | Section headers + target section only | `grep -n "##"` to find sections, then read 30-50 lines |
| Growing docs (archived/completed sprints) | Last 40 lines | `tail -40` — never full read |
| tech-debt.md | Relevant items only | `grep -B2 -A6 "keyword"` |
| Directory structure | 2 levels | `tree -L 2` or `find -maxdepth 2` |

### Externalize-First Rule (MANDATORY)

All exploration findings go to `docs/sprints/sprint-<ID>/exploration-notes.md` immediately — not held in context.

```markdown
# Exploration Notes — [date]
## Structure
[tree output, key directories]
## Patterns Found
[grep results, line ranges, existing conventions]
## Dependencies
[what connects to what]
## Candidate Files
[file:Lnn — why it's in scope]
```

After sprint docs (`context.md` + `plan.md`) are written with all findings distilled into them, `exploration-notes.md` remains in the sprint folder as a persistent record of planning research.

### Context Checkpoints

| Checkpoint | Action |
|------------|--------|
| After exploration, before writing sprint docs | If context > 50%, write `sprint-<ID>/exploration-notes.md` and `/compact` — recovery reads the notes |
| After sprint docs written | Safe to proceed — all state is in docs |
| After parallel group completes | Safe compaction point — progress is in sprint docs |

### Anti-Patterns (NEVER do these in plan mode)

- ❌ Read full `docs/SPEC.md` — use targeted grep + scoped read
- ❌ Read full source files > 50 lines — use `grep -n` to pin line ranges, then read only those ranges
- ❌ Read `coder.md` or `verifier.md` — these are execution-phase references
- ❌ Hold multiple full files in context simultaneously — externalize to `sprint-<ID>/exploration-notes.md`
- ❌ Read `docs/completed-sprints.md` or `docs/archived-sprints.md` in full — use `tail -40`
- ❌ Read collision templates preemptively — load only when a collision is detected

---

## Sub-Agent Return Budgets

See `orchestrator.md` Section 2 for return budget table. Sub-agent returns enter the orchestrator's context window verbatim.

---

## Build Commands

```bash
dotnet build AiAgents.sln
dotnet test AiAgents.sln --verbosity quiet
dotnet format AiAgents.sln --verify-no-changes --severity warn
```

Build fails → fix before moving on. Tests fail → fix or justify. NEVER skip.

Database migration commands: see `README.md`.

---

## Safety Rules

- Never run raw SQL DELETE/DROP/TRUNCATE without explicit user confirmation
- Never modify or delete applied EF Core migrations
- Never change connection strings or credentials in committed code
- Never modify files outside `AiAgents.sln` scope
