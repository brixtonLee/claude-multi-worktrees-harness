# pipe-guard.ps1 - PreToolUse hook for Bash commands
# Enforces CLAUDE.md shell rules: no pipes, no chaining, no redirection
# Exit 0 = allow, Exit 2 = block (stderr = reason shown to agent)
#
# ALLOW list (commands that pass through regardless of metacharacters):
#   - dotnet test/build/run/format/restore ... 2>&1 | tail -N  (output truncation pattern)
#   - Single commands with 2>/dev/null suffix only
#
# Block list (always blocked, no exceptions):
#   - Any pipe | (except whitelisted patterns)
#   - && || ; chaining
#   - Shell redirections > >> < 2>&1 (except 2>/dev/null)
#   - bash -c / sh -c / zsh -c shell escapes
#   - $() or backtick command substitution
#   - for/while/if/case/until control flow
#   - cd (use full paths instead)

# -- Fail-closed trap ----------------------------------------------------------
# If pipe-guard crashes for ANY reason, block the command (exit 2) rather than
# silently allowing it through (exit 1 = non-blocking passthrough in Claude Code).
$LogFile = "$env:USERPROFILE\.claude\pipe-guard-debug.log"
trap {
    $ErrMsg = $_.ToString()
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | TRAP_ERROR=$ErrMsg"
    [Console]::Error.WriteLine("BLOCKED: pipe-guard.ps1 internal error - failing closed. Error: $ErrMsg")
    exit 2
}

$ErrorActionPreference = 'Stop'

# -- Read input from stdin (Claude Code pipes JSON via stdin) ------------------
$Raw = [Console]::In.ReadToEnd()

# -- Proof-of-life log - written immediately so we know the hook ran ----------
Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | HOOK_STARTED | RAW=$Raw"

if ([string]::IsNullOrEmpty($Raw)) {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=0 | REASON=empty_input"
    exit 0
}

# -- Extract command from JSON -------------------------------------------------
$Command = ""
try {
    $Parsed = $Raw | ConvertFrom-Json -ErrorAction Stop
    $Command = $Parsed.tool_input.command
    # Fallback: some versions use top-level .command
    if ([string]::IsNullOrEmpty($Command)) {
        $Command = $Parsed.command
    }
} catch {
    # Fallback: regex extraction for malformed JSON
    if ($Raw -match '"command"\s*:\s*"((?:[^"\\]|\\.)*)"') {
        $Command = $Matches[1]
        $Command = $Command -replace '\\n', "`n"
        $Command = $Command -replace '\\"', '"'
        $Command = $Command -replace '\\\\', '\'
    }
}

if ([string]::IsNullOrEmpty($Command)) {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=0 | REASON=no_command_found"
    exit 0
}

# Log the extracted command
Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | CMD=$Command"

# -- WHITELIST: Safe compound patterns that are explicitly allowed -------------

# Pattern: dotnet <verb> [args] 2>&1 | tail -N
if ($Command -match '^dotnet\s+(test|build|run|format|restore|ef)\s+.*2>&1\s*\|\s*tail\s+-\d+$') {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=0 | REASON=whitelist_dotnet_tail"
    exit 0
}
# Pattern: dotnet <verb> [args] | tail -N (without 2>&1)
if ($Command -match '^dotnet\s+(test|build|run|format|restore|ef)\s+.*\|\s*tail\s+-\d+$') {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=0 | REASON=whitelist_dotnet_tail_no_redir"
    exit 0
}
# Pattern: cargo <verb> [args] 2>&1 | tail -N
if ($Command -match '^cargo\s+(test|build|run|check|clippy|bench)\s+.*2>&1\s*\|\s*tail\s+-\d+$') {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=0 | REASON=whitelist_cargo_tail"
    exit 0
}
# Pattern: cargo <verb> [args] | tail -N
if ($Command -match '^cargo\s+(test|build|run|check|clippy|bench)\s+.*\|\s*tail\s+-\d+$') {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=0 | REASON=whitelist_cargo_tail_no_redir"
    exit 0
}

# -- BLOCK: bash -c / sh -c / zsh -c shell escape -----------------------------
if ($Command -match '^(bash|sh|zsh)\s+-c') {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=2 | REASON=shell_escape"
    [Console]::Error.WriteLine("BLOCKED: Shell escape via -c detected.`nPer CLAUDE.md: run commands directly as separate Bash tool calls.`nWRONG: bash -c `"cd /path && dotnet build`"`nRIGHT: dotnet build /full/path/to/Solution.sln")
    exit 2
}

# -- BLOCK: cd command --------------------------------------------------------
if ($Command -match '^\s*cd(\s|$)') {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=2 | REASON=cd_detected"
    [Console]::Error.WriteLine("BLOCKED: cd detected. Pass full paths directly to commands instead.`nPer CLAUDE.md: no command chaining - cd is only useful as cd && <cmd>.`nWRONG: cd /path/to/project && dotnet test AiAgents.sln`nRIGHT: dotnet test /path/to/project/AiAgents.sln --verbosity quiet")
    exit 2
}

# -- BLOCK: command substitution $() or backticks -----------------------------
if ($Command.Contains('$(') -or $Command.Contains('`')) {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=2 | REASON=command_substitution"
    [Console]::Error.WriteLine("BLOCKED: Command substitution or backtick detected.`nPer CLAUDE.md: use separate Bash tool calls - capture output in subsequent calls.`nWRONG: start=$(grep -n 'method' file.cs)`nRIGHT: Call 1 - grep -n 'method' file.cs  (then read output and use it)")
    exit 2
}

# -- BLOCK: shell control flow ------------------------------------------------
if ($Command -match '^\s*(for|while|if|case|until)\s') {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=2 | REASON=control_flow"
    [Console]::Error.WriteLine("BLOCKED: Shell control flow (for/while/if/case/until) detected.`nPer CLAUDE.md: use separate Bash tool calls for each step - no inline scripting.`nWRONG: for f in a b c; do dotnet build f; done`nRIGHT: Call 1 - dotnet build a    Call 2 - dotnet build b    Call 3 - dotnet build c")
    exit 2
}

# -- BLOCK: pipes (|) ---------------------------------------------------------
# Remove || (logical OR) first to avoid false positive, then check remaining |
$Stripped = $Command -replace '\|\|', '__LOGICAL_OR__'
if ($Stripped.Contains('|')) {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=2 | REASON=pipe_detected"
    [Console]::Error.WriteLine("BLOCKED: Pipe (|) detected. Run each command as a separate Bash tool call.`nPer CLAUDE.md: pipes are not allowed - use separate calls and process output directly.`nWRONG: grep -n 'method' file.cs | cut -d: -f1`nRIGHT: Call 1 - grep -n 'method' file.cs  (then extract line numbers from output)")
    exit 2
}

# -- BLOCK: command chaining (&&) ---------------------------------------------
if ($Command.Contains('&&')) {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=2 | REASON=and_chaining"
    [Console]::Error.WriteLine("BLOCKED: Command chaining (&&) detected. Run each command as a separate Bash tool call.`nPer CLAUDE.md: && chaining is not allowed.`nWRONG: dotnet build && dotnet test`nRIGHT: Call 1 - dotnet build    Call 2 - dotnet test")
    exit 2
}

# -- BLOCK: command chaining (||) ---------------------------------------------
if ($Command.Contains('||')) {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=2 | REASON=or_chaining"
    [Console]::Error.WriteLine("BLOCKED: Command chaining (||) detected. Run each command as a separate Bash tool call.`nPer CLAUDE.md: || chaining is not allowed.")
    exit 2
}

# -- BLOCK: semicolon command separator (;) -----------------------------------
# Strip quoted strings first to avoid false positives on ; inside strings
$SemiCheck = $Command
$SemiCheck = $SemiCheck -replace "'[^']*'", ''
$SemiCheck = $SemiCheck -replace '"[^"]*"', ''
if ($SemiCheck.Contains(';')) {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=2 | REASON=semicolon"
    [Console]::Error.WriteLine("BLOCKED: Semicolon (;) command separator detected. Run each command as a separate Bash tool call.`nPer CLAUDE.md: ; chaining is not allowed.")
    exit 2
}

# -- BLOCK: shell redirection -------------------------------------------------
# Allowed:  2>/dev/null  (stderr suppression only)
# Blocked:  > >> < 2>&1 &> and all others
$RedirCheck = $Command -replace '2>/dev/null', ''

if ($RedirCheck.Contains('>>')) {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=2 | REASON=append_redirect"
    [Console]::Error.WriteLine("BLOCKED: Shell redirection (>>) detected. Only 2>/dev/null is allowed.`nPer CLAUDE.md: use Edit/Write tools to write file content, not shell redirection.")
    exit 2
}
# Check > but not => or -> or >= or <=
if ($RedirCheck -match '[^=!<>-]>' -or $RedirCheck -match '^>') {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=2 | REASON=output_redirect"
    [Console]::Error.WriteLine("BLOCKED: Shell redirection (>) detected. Only 2>/dev/null is allowed.`nPer CLAUDE.md: use Edit/Write tools to write file content, not shell redirection.")
    exit 2
}
if ($RedirCheck -match '[^<]<' -or $RedirCheck -match '^<') {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=2 | REASON=input_redirect"
    [Console]::Error.WriteLine("BLOCKED: Shell redirection (<) detected. Only 2>/dev/null is allowed.`nPer CLAUDE.md: use Read tool to read file content, not shell redirection.")
    exit 2
}
if ($RedirCheck.Contains('2>&1')) {
    Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=2 | REASON=stderr_redirect"
    [Console]::Error.WriteLine("BLOCKED: Shell redirection (2>&1) detected. Only 2>/dev/null is allowed.`nPer CLAUDE.md: whitelisted pattern is: dotnet/cargo test ... 2>&1 | tail -N only.")
    exit 2
}

# -- All checks passed --------------------------------------------------------
Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EXIT=0 | REASON=all_checks_passed"
exit 0