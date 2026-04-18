# Claude Code Hook Scripts

Hook scripts for Claude Code on Windows (native Git Bash execution). These run as PreToolUse, PostToolUse, and lifecycle hooks configured in `~/.claude/settings.json`.

All hooks receive JSON on stdin from Claude Code and communicate back via exit codes and stdout/stderr. They execute inside PowerShell but are **invoked by Git Bash**, so the `settings.json` command strings use `$HOME` (not `%USERPROFILE%`).

---

## pipe-guard.ps1

**Hook type:** PreToolUse
**Matcher:** `Bash`
**Exit codes:** `0` = allow, `2` = block

Guards against dangerous Bash command patterns that bypass the static permission rules in `settings.json`. Inspects the command string from the Bash tool input and blocks patterns like piped commands, shell injection, or disallowed operators.

**Settings.json configuration:**

```json
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$HOME/.claude/pipe-guard.ps1\""
    }
  ]
}
```

**Smoke test:**

```powershell
# Should BLOCK (pipe operator)
echo '{"tool_name":"Bash","tool_input":{"command":"find . -name *.cs | xargs grep Invoice"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/pipe-guard.ps1"; echo "Exit: $LASTEXITCODE"

# Should PASS (simple command)
echo '{"tool_name":"Bash","tool_input":{"command":"dotnet build"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/pipe-guard.ps1"; echo "Exit: $LASTEXITCODE"
```

---

## pre-read-guard.ps1

**Hook type:** PreToolUse
**Matcher:** `Read`
**Exit codes:** `0` = allow, `2` = block

Protects context budget by blocking two categories of wasteful reads:

1. **Build artifacts** — Files inside `bin/`, `obj/`, `target/`, `node_modules/`, `dist/`, `build/`, `.venv/`, `__pycache__/`. These are generated or vendored and should not consume context.
2. **Large files without offset** — Files over 1000 lines where no `offset` parameter is specified. Forces Claude to grep first, then read a targeted section.

**Settings.json configuration:**

```json
{
  "matcher": "Read",
  "hooks": [
    {
      "type": "command",
      "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$HOME/.claude/pre-read-guard.ps1\""
    }
  ]
}
```

**Smoke tests:**

```powershell
# Should BLOCK (build artifact)
echo '{"tool_name":"Read","tool_input":{"file_path":"src/App/bin/Debug/net8.0/App.dll"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/pre-read-guard.ps1"; echo "Exit: $LASTEXITCODE"

# Should BLOCK (obj directory)
echo '{"tool_name":"Read","tool_input":{"file_path":"src/App/obj/project.assets.json"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/pre-read-guard.ps1"; echo "Exit: $LASTEXITCODE"

# Should PASS (normal source file)
echo '{"tool_name":"Read","tool_input":{"file_path":"src/App/Services/MyService.cs"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/pre-read-guard.ps1"; echo "Exit: $LASTEXITCODE"

# Should BLOCK (large file, no offset — use a file >1000 lines)
echo '{"tool_name":"Read","tool_input":{"file_path":"large-file.cs"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/pre-read-guard.ps1"; echo "Exit: $LASTEXITCODE"

# Should PASS (large file WITH offset)
echo '{"tool_name":"Read","tool_input":{"file_path":"large-file.cs","offset":50,"limit":20}}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/pre-read-guard.ps1"; echo "Exit: $LASTEXITCODE"
```

---

## post-edit-diff.ps1

**Hook type:** PostToolUse
**Matcher:** `Edit|Write|MultiEdit`
**Exit codes:** `0` always (advisory, never blocks)

Surfaces the git diff of the edited file back to Claude after every edit. Claude reads this output and can self-correct if something looks wrong. Includes heuristic warnings:

- **Large change** (>200 lines modified) — warns to verify sprint scope
- **New imports** — surfaces added `using`/`import`/`use` statements for review
- **Deletion-heavy** (>50 lines removed, less than half added back) — flags potentially accidental deletions

For new (untracked) files, shows file size and a 30-line preview instead of a diff.

**Settings.json configuration:**

```json
{
  "matcher": "Edit|Write|MultiEdit",
  "hooks": [
    {
      "type": "command",
      "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$HOME/.claude/post-edit-diff.ps1\""
    }
  ]
}
```

**Smoke tests:**

```powershell
cd <project-root>

# Make a small edit to test diff output
Add-Content "README.md" "`n"

# Should show diff stats + diff body
echo '{"tool_name":"Edit","tool_input":{"file_path":"README.md"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/post-edit-diff.ps1"; echo "Exit: $LASTEXITCODE"

git checkout -- README.md

# Test with a new (untracked) file
"hello world" | Set-Content "test-new.cs"
echo '{"tool_name":"Write","tool_input":{"file_path":"test-new.cs"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/post-edit-diff.ps1"; echo "Exit: $LASTEXITCODE"
Remove-Item "test-new.cs"

# Test no-op (clean file)
echo '{"tool_name":"Edit","tool_input":{"file_path":"README.md"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/post-edit-diff.ps1"; echo "Exit: $LASTEXITCODE"
```

**Known issue:** Path normalization mismatch between `git rev-parse --show-toplevel` (Git Bash-style `/c/Users/...`) and `Resolve-Path` (Windows-style `C:\Users\...`). Fix by using `Resolve-Path` on both sides with `OrdinalIgnoreCase` comparison.

---

## log-tool-call.ps1

**Hook type:** PostToolUse
**Matcher:** `.*` (fires on every tool call)
**Exit codes:** `0` always (telemetry must never block flow)

Writes one enriched JSONL event per tool call to two locations:

- **Per-sprint:** `docs/sprints/sprint-<ID>/cost.jsonl`
- **Global:** `~/.claude/observability/tool-calls.jsonl`

Each event captures timestamp, session ID, sprint ID, tool name, tool-specific metadata (file paths, commands truncated to 200 chars, Task descriptions truncated to 100 chars), and estimated response tokens (~4 chars/token).

**Settings.json configuration:**

```json
{
  "matcher": ".*",
  "hooks": [
    {
      "type": "command",
      "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$HOME/.claude/log-tool-call.ps1\""
    }
  ]
}
```

**Smoke tests:**

```powershell
cd <project-root>

# Log a Bash tool call
echo '{"tool_name":"Bash","tool_input":{"command":"dotnet build"},"session_id":"test-001","tool_response":"Build succeeded."}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/log-tool-call.ps1"; echo "Exit: $LASTEXITCODE"

# Log an Edit tool call
echo '{"tool_name":"Edit","tool_input":{"file_path":"src/MyService.cs"},"session_id":"test-001","tool_response":"OK"}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/log-tool-call.ps1"; echo "Exit: $LASTEXITCODE"

# Log a Task (sub-agent) tool call
echo '{"tool_name":"Task","tool_input":{"subagent_type":"coder","description":"Implement duplicate detection"},"session_id":"test-001","tool_response":"completed"}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/log-tool-call.ps1"; echo "Exit: $LASTEXITCODE"

# Verify output
Get-Content "$HOME/.claude/observability/tool-calls.jsonl" | Select-Object -Last 3
```

---

## session-start-init.ps1

**Hook type:** SessionStart
**Exit codes:** `0` always (bootstrap must never block session)

Runs once when a Claude Code session begins. Performs three initialization tasks:

1. **Observability directory** — Creates `~/.claude/observability/` if it doesn't exist, ensuring `log-tool-call.ps1` and `reconcile-cost.ps1` have a write target.
2. **Sprint auto-detection** — If no `docs/sprints/.active-sprint` marker exists, parses `docs/sprints/registry.md` for the first sprint under `## Active Sprints` and writes the marker file.
3. **Agent marker** — Sets `docs/sprints/sprint-<ID>/.current-agent` to `"main"` if it doesn't exist, initializing the agent role for the orchestrator/coder/verifier pipeline.

Writes a `session_start` event to `~/.claude/observability/sessions.jsonl`.

**Settings.json configuration:**

```json
{
  "hooks": [
    {
      "type": "command",
      "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$HOME/.claude/session-start-init.ps1\""
    }
  ]
}
```

**Smoke tests:**

```powershell
cd <project-root>

# Basic session start
echo '{"session_id":"smoke-001"}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/session-start-init.ps1"; echo "Exit: $LASTEXITCODE"

# Verify event was written
Get-Content "$HOME/.claude/observability/sessions.jsonl" | Select-Object -Last 1 | ConvertFrom-Json

# Verify observability directory exists
Test-Path "$HOME/.claude/observability"

# Test sprint auto-detection (temporarily remove marker)
$marker = "docs/sprints/.active-sprint"
$backup = $null
if (Test-Path $marker) { $backup = Get-Content $marker; Remove-Item $marker }

echo '{"session_id":"smoke-002"}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/session-start-init.ps1"; echo "Exit: $LASTEXITCODE"

if (Test-Path $marker) { echo "Detected: $(Get-Content $marker)" }
if ($backup) { Set-Content -Path $marker -Value $backup -NoNewline }
```

---

## reconcile-cost.ps1

**Hook type:** SessionEnd
**Exit codes:** `0` always (reconciliation is best-effort)

Runs once when a Claude Code session ends. Joins two data sources to produce a session summary:

1. **Session JSONL** (`~/.claude/projects/<hash>/<session_id>.jsonl`) — Claude Code's transcript with actual token usage per turn (input, output, cache read, cache creation).
2. **Tool-calls JSONL** (`~/.claude/observability/tool-calls.jsonl`) — Events from `log-tool-call.ps1`, filtered to the current session.

The summary includes total token usage, tool call counts sorted by frequency, and discipline metrics (grep/read/edit/bash/task ratios with estimated response tokens).

Writes to:
- `docs/sprints/sprint-<ID>/cost.jsonl` — alongside per-call events from `log-tool-call.ps1`
- `~/.claude/observability/sessions.jsonl` — alongside `session_start` events from `session-start-init.ps1`

**Settings.json configuration:**

```json
{
  "hooks": [
    {
      "type": "command",
      "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$HOME/.claude/reconcile-cost.ps1\""
    }
  ]
}
```

**Smoke tests:**

```powershell
cd <project-root>

# Seed some tool call events for a test session
echo '{"tool_name":"Bash","tool_input":{"command":"dotnet build"},"session_id":"reconcile-test-001","tool_response":"Build succeeded."}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/log-tool-call.ps1"

echo '{"tool_name":"Edit","tool_input":{"file_path":"src/Test.cs"},"session_id":"reconcile-test-001","tool_response":"OK"}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/log-tool-call.ps1"

echo '{"tool_name":"Read","tool_input":{"file_path":"src/Test.cs"},"session_id":"reconcile-test-001","tool_response":"file content here"}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/log-tool-call.ps1"

# Run reconciliation
echo '{"session_id":"reconcile-test-001"}' | powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/reconcile-cost.ps1"; echo "Exit: $LASTEXITCODE"

# Verify summary
Get-Content "$HOME/.claude/observability/sessions.jsonl" | Select-Object -Last 1 | ConvertFrom-Json | ConvertTo-Json -Depth 5
```

**Performance note:** Reads the entire `tool-calls.jsonl` on every session end. Consider implementing log rotation for long-running projects.

---

## statusline.ps1 / statusline-command.ps1

**Hook type:** PostToolUse (`statusline.ps1`, matcher `.*`) and StatusLine (`statusline-command.ps1`)

These power the Claude Code status line display. `statusline.ps1` updates state after each tool call, and `statusline-command.ps1` renders the status bar content.

**Settings.json configuration:**

```json
"PostToolUse": [
  {
    "matcher": ".*",
    "hooks": [
      {
        "type": "command",
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$HOME/.claude/statusline.ps1\""
      }
    ]
  }
],
"statusLine": {
  "type": "command",
  "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$HOME/.claude/statusline-command.ps1\""
}
```

---

## orchestrator-gate.ps1

**Hook type:** PostToolUse
**Matcher:** `ExitPlanMode`

Fires when Claude exits plan mode. Gates the transition from planning to execution in the orchestrator/coder/verifier pipeline, ensuring plans are validated before spawning sub-agents.

**Settings.json configuration:**

```json
{
  "matcher": "ExitPlanMode",
  "hooks": [
    {
      "type": "command",
      "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$HOME/.claude/orchestrator-gate.ps1\""
    }
  ]
}
```

---

## pre-compact-context.ps1

**Hook type:** PreCompact

Fires before Claude auto-compacts the context window (triggered by `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=75`). Use this to preserve critical state into scratch files or summaries before compaction discards older context.

**Settings.json configuration:**

```json
"PreCompact": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$HOME/.claude/pre-compact-context.ps1\""
      }
    ]
  }
]
```

---

## Hook Execution Flow

```
SessionStart
  └── session-start-init.ps1 (bootstrap observability, detect sprint, set agent marker)

For each tool call:
  ├── PreToolUse
  │     ├── pipe-guard.ps1 (Bash only — block dangerous patterns)
  │     ├── pre-read-guard.ps1 (Read only — block artifacts, large files)
  │     └── pre-edit-manifest-check.ps1 (Edit/Write/MultiEdit — scope guard)
  │
  │  [tool executes]
  │
  └── PostToolUse
        ├── orchestrator-gate.ps1 (ExitPlanMode only)
        ├── statusline.ps1 (all tools — update status bar state)
        ├── log-tool-call.ps1 (all tools — JSONL telemetry)
        └── post-edit-diff.ps1 (Edit/Write/MultiEdit — diff + heuristics)

PreCompact
  └── pre-compact-context.ps1 (preserve state before context compaction)

SessionEnd
  └── reconcile-cost.ps1 (join session transcript + tool telemetry → summary)
```

## File Locations

| File | Path |
|---|---|
| Hook scripts | `~/.claude/*.ps1` |
| Global settings | `~/.claude/settings.json` |
| Project settings | `<project>/.claude/settings.local.json` |
| Tool call telemetry | `~/.claude/observability/tool-calls.jsonl` |
| Session summaries | `~/.claude/observability/sessions.jsonl` |
| Sprint cost data | `<project>/docs/sprints/sprint-<ID>/cost.jsonl` |
| Active sprint marker | `<project>/docs/sprints/.active-sprint` |
| Agent role marker | `<project>/docs/sprints/sprint-<ID>/.current-agent` |

## Windows Path Notes

All hook commands in `settings.json` use `$HOME` (not `%USERPROFILE%`) because Claude Code executes hooks through Git Bash, which does not expand `%VAR%` cmd.exe syntax. Inside the `.ps1` scripts themselves, `$env:USERPROFILE` works fine since it's PowerShell-native.
