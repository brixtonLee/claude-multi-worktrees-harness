# CLAUDE.md
 
## ⛔ ABSOLUTE — Bash Tool Rules (ENFORCED BY pipe-guard.ps1)

Every Bash tool call must be ONE atomic command — a single binary with its flags and arguments.
No shell scripting. No shell interpreter features. Just the binary itself.

These apply in ALL modes: plan, execution, sub-agents, every Bash call.
Violations are **blocked by pipe-guard.ps1** — not warned, not prompted, hard-blocked.

| ❌ NEVER | ✅ ALWAYS |
|----------|-----------|
| `cmd1 && cmd2` | Two separate Bash tool calls |
| `cmd1 \| cmd2` | Two separate Bash tool calls |
| `cmd1 ; cmd2` | Two separate Bash tool calls |
| `cmd1 \|\| cmd2` | Two separate Bash tool calls |
| `cd /path && dotnet build` | `dotnet build /full/path/to/Solution.sln` |
| `cd /path` (any use of cd) | Pass full paths directly to commands |
| `start=$(grep -n ...)` | Call 1: `grep -n ...` → read output → Call 2 |
| `for f in a b c; do ...; done` | Separate Bash call per item |
| `bash -c "..."` / `sh -c "..."` | Direct command with full path |
| `> file`, `>> file`, `< file` | Use `Write`/`Edit`/`Read` tools |
| `2>&1` (standalone) | Not needed — pipe-guard blocks it |

**Only allowed redirection:** `2>/dev/null` as a suffix to a single command.
**Whitelisted compound:** `dotnet/cargo <verb> [args] 2>&1 | tail -N` — output truncation only.

**Self-check before every Bash call:**
> "Can this run as a standalone executable with no shell interpreter?"
> YES → valid · NO (needs shell to interpret `|` `&&` `$()` etc.) → split into separate calls

**Before every Bash call: if you see `&&`, `|`, `;`, `cd`, `$()` — STOP. Split or use full path.**

---

## Git Command Rules

- **ALWAYS** commit at sprint end — never leave a SHIP'd sprint uncommitted
- **NEVER** force push, hard reset, or delete remote branches
- **NEVER** commit to `main`/`master` directly — always on a feature/sprint branch
- **ALWAYS** use `git pull --rebase` before pushing to avoid merge commits on linear branches
- **ALWAYS** run build + test AFTER any rebase/merge conflict resolution before committing
- Commit messages follow: `sprint-{N}: [one-line summary]`
- If merge conflict occurs mid-sprint, STOP and present conflict files to user — do NOT auto-resolve source files
- Git stash is allowed for context switching between sprints

---

## Anti-Hallucination Rules

- Never assume a class, method, or namespace exists — verify with grep/read first
- Never fabricate NuGet package names — check `.csproj` first
- If a build fails twice on the same issue, STOP and present findings to user
- Never invent API endpoints — read the controller first

---

## Tool Restrictions

- Use `Edit` for all code modifications — never `sed`/`awk`/bash string manipulation
- Use `Read` before editing any file — never edit blind
- Never create files outside the solution directory without confirmation

---

## Context Window Conservation

- **grep**: Always `grep -m 30 -n` to cap output
- **git diff**: `git diff --stat` first, then `git diff -- <specific-file>` for files in scope
- **Read**: For files > 200 lines, use `offset`/`limit`. When line ranges provided (e.g., `file.cs:L85-105`), read only those ranges.
- **2-attempt rule**: After 2 failed attempts, STOP and ask user
- **No speculative reads**: Only files in the active sprint's `active-context.md` manifest or subtask prompt
- **tech-debt.md**: Write-only during execution
- **SPEC.md**: Never read directly during planning — delegate to scout sub-agent
- **Sprint path**: Always use `docs/sprints/sprint-{N}/` — never a bare `docs/sprint/`

---

## Communication Style

- Be direct. No filler.
- Status: `done` / `failed — reason` / `in progress`
- Show code changes, don't describe them. Explain WHY not WHAT.
- One question at a time. MYR unless stated otherwise.