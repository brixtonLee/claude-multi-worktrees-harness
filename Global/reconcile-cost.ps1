# reconcile-cost.ps1
# SessionEnd hook.
# Reads the just-finished session's JSONL and joins it with tool-call telemetry
# to produce a session-summary event.
#
# Written to:
#   - docs/sprints/sprint-<ID>/cost.jsonl (if sprint is active)
#   - ~/.claude/observability/sessions.jsonl (always)
#
# Always exits 0 — reconciliation is best-effort.

$ErrorActionPreference = 'SilentlyContinue'

try {

$RawInput = [Console]::In.ReadToEnd()
$Input_Data = $null
try {
    $Input_Data = $RawInput | ConvertFrom-Json -ErrorAction Stop
} catch {
    exit 0
}

$session_id = if ($Input_Data.session_id) { $Input_Data.session_id } else { "" }
if ([string]::IsNullOrEmpty($session_id) -or $session_id -eq "unknown") {
    exit 0
}

# === Locate the session JSONL file ===
$session_file = ""
$projects_dir = Join-Path $env:USERPROFILE ".claude/projects"

if (Test-Path $projects_dir) {
    # Search across all project hashes for matching session file
    $candidate = Get-ChildItem -Path $projects_dir -Recurse -Depth 2 -Filter "$session_id.jsonl" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($candidate) {
        $session_file = $candidate.FullName
    }
}

# === Extract usage totals from session JSONL (if found) ===
$usage_summary = @{
    input_tokens   = 0
    output_tokens  = 0
    cache_read     = 0
    cache_creation = 0
    turns          = 0
}
$tool_counts = @()

if ($session_file -and (Test-Path $session_file)) {
    $inputTok = 0; $outputTok = 0; $cacheRead = 0; $cacheCreate = 0; $turnCount = 0
    $toolMap = @{}

    foreach ($line in [System.IO.File]::ReadLines($session_file)) {
        $line = $line.Trim()
        if ([string]::IsNullOrEmpty($line)) { continue }
        try {
            $entry = $line | ConvertFrom-Json -ErrorAction Stop
        } catch { continue }

        if ($entry.type -eq 'assistant' -and $null -ne $entry.message) {
            $u = $entry.message.usage
            if ($null -ne $u) {
                $turnCount++
                $inputTok    += if ($u.input_tokens)                 { $u.input_tokens }                 else { 0 }
                $outputTok   += if ($u.output_tokens)                { $u.output_tokens }                else { 0 }
                $cacheRead   += if ($u.cache_read_input_tokens)      { $u.cache_read_input_tokens }      else { 0 }
                $cacheCreate += if ($u.cache_creation_input_tokens)   { $u.cache_creation_input_tokens }   else { 0 }
            }

            if ($null -ne $entry.message.content) {
                foreach ($block in $entry.message.content) {
                    if ($block.type -eq 'tool_use' -and $block.name) {
                        if ($toolMap.ContainsKey($block.name)) {
                            $toolMap[$block.name]++
                        } else {
                            $toolMap[$block.name] = 1
                        }
                    }
                }
            }
        }
    }

    $usage_summary = @{
        input_tokens   = $inputTok
        output_tokens  = $outputTok
        cache_read     = $cacheRead
        cache_creation = $cacheCreate
        turns          = $turnCount
    }

    $tool_counts = $toolMap.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
        @{ tool = $_.Key; count = $_.Value }
    }
}

# === Identify active sprint ===
$sprint_id = "unassigned"
$repo_root = ""
try {
    $repo_root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and $repo_root) {
        $marker = Join-Path $repo_root "docs/sprints/.active-sprint"
        if (Test-Path $marker) {
            $sprint_id = (Get-Content $marker).Trim()
            if ([string]::IsNullOrEmpty($sprint_id)) { $sprint_id = "unassigned" }
        }
    } else {
        $repo_root = ""
    }
} catch {
    $repo_root = ""
}

# === Compute discipline metrics from global tool-calls feed (this session only) ===
$global_tool_log = Join-Path $env:USERPROFILE ".claude/observability/tool-calls.jsonl"
$discipline = @{
    grep_count                = 0
    read_count                = 0
    edit_count                = 0
    bash_count                = 0
    task_count                = 0
    total_response_tokens_est = 0
}

if (Test-Path $global_tool_log) {
    foreach ($line in [System.IO.File]::ReadLines($global_tool_log)) {
        $line = $line.Trim()
        if ([string]::IsNullOrEmpty($line)) { continue }
        try {
            $entry = $line | ConvertFrom-Json -ErrorAction Stop
        } catch { continue }

        if ($entry.type -eq "tool_call" -and $entry.session_id -eq $session_id) {
            switch ($entry.tool) {
                'Grep'      { $discipline.grep_count++ }
                'Read'      { $discipline.read_count++ }
                { $_ -in 'Edit','Write','MultiEdit' } { $discipline.edit_count++ }
                'Bash'      { $discipline.bash_count++ }
                'Task'      { $discipline.task_count++ }
            }
            $discipline.total_response_tokens_est += if ($entry.response_tokens_est) { $entry.response_tokens_est } else { 0 }
        }
    }
}

# === Build the session_end event ===
$ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$event = [PSCustomObject]@{
    type        = "session_end"
    ts          = $ts
    session_id  = $session_id
    sprint_id   = $sprint_id
    usage       = $usage_summary
    tool_counts = $tool_counts
    discipline  = $discipline
} | ConvertTo-Json -Compress -Depth 5

# === Write to sprint cost.jsonl ===
if ($sprint_id -ne "unassigned" -and $repo_root) {
    $costDir = Join-Path $repo_root "docs/sprints/sprint-$sprint_id"
    if (-not (Test-Path $costDir)) {
        New-Item -ItemType Directory -Path $costDir -Force | Out-Null
    }
    Add-Content -Path (Join-Path $costDir "cost.jsonl") -Value $event -ErrorAction SilentlyContinue
}

# === Write to global sessions feed ===
$globalDir = Join-Path $env:USERPROFILE ".claude/observability"
if (-not (Test-Path $globalDir)) {
    New-Item -ItemType Directory -Path $globalDir -Force | Out-Null
}
Add-Content -Path (Join-Path $globalDir "sessions.jsonl") -Value $event -ErrorAction SilentlyContinue

} catch {
    # Reconciliation is best-effort
}

exit 0
