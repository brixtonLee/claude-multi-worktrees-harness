# log-tool-call.ps1
# PostToolUse hook (matcher: ".*")
# Writes one enriched JSONL event per tool call to:
#   - docs/sprints/sprint-<ID>/cost.jsonl  (per-sprint)
#   - ~/.claude/observability/tool-calls.jsonl  (global)
#
# Never blocks — always exits 0 even on errors (telemetry must not kill flow).

$ErrorActionPreference = 'SilentlyContinue'

try {

$RawInput = [Console]::In.ReadToEnd()
$Input_Data = $null
try {
    $Input_Data = $RawInput | ConvertFrom-Json -ErrorAction Stop
} catch {
    exit 0
}

# Best-effort extraction; missing fields default to sane values
$tool_name       = if ($Input_Data.tool_name)       { $Input_Data.tool_name }       else { "unknown" }
$session_id      = if ($Input_Data.session_id)       { $Input_Data.session_id }       else { "unknown" }
$transcript_path = if ($Input_Data.transcript_path)  { $Input_Data.transcript_path }  else { "" }
$cwd             = if ($Input_Data.cwd)              { $Input_Data.cwd }              else { "" }
$tool_input      = if ($Input_Data.tool_input)       { $Input_Data.tool_input }       else { [PSCustomObject]@{} }
$tool_response   = if ($Input_Data.tool_response)    { [string]$Input_Data.tool_response } else { "" }

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

# === Agent attribution via session_id ===
$session_fp = "session:" + $session_id.Substring(0, [math]::Min(8, $session_id.Length))

# === Response size (char count as token proxy, ~4 chars/token) ===
$response_chars = $tool_response.Length
$response_tokens_est = [math]::Floor($response_chars / 4)

# === Tool-specific metadata extraction ===
$meta = @{}
switch ($tool_name) {
    'Read' {
        $meta = @{
            file   = if ($tool_input.file_path) { $tool_input.file_path } else { "" }
            offset = $tool_input.offset
            limit  = $tool_input.limit
        }
    }
    'Grep' {
        $meta = @{
            pattern     = if ($tool_input.pattern)     { $tool_input.pattern }     else { "" }
            path        = if ($tool_input.path)        { $tool_input.path }        else { "" }
            output_mode = if ($tool_input.output_mode) { $tool_input.output_mode } else { "files_with_matches" }
        }
    }
    'Glob' {
        $meta = @{
            pattern = if ($tool_input.pattern) { $tool_input.pattern } else { "" }
        }
    }
    { $_ -in 'Edit','Write','MultiEdit' } {
        $meta = @{
            file = if ($tool_input.file_path) { $tool_input.file_path } else { "" }
        }
    }
    'Bash' {
        $cmd = if ($tool_input.command) { $tool_input.command } else { "" }
        if ($cmd.Length -gt 200) { $cmd = $cmd.Substring(0, 200) }
        $meta = @{
            command = $cmd
            timeout = $tool_input.timeout
        }
    }
    'Task' {
        $desc = if ($tool_input.description) { $tool_input.description } else { "" }
        if ($desc.Length -gt 100) { $desc = $desc.Substring(0, 100) }
        $meta = @{
            subagent    = if ($tool_input.subagent_type) { $tool_input.subagent_type } else { "" }
            description = $desc
        }
    }
    default {
        $meta = @{}
    }
}

# === Build the event ===
$ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$event = [PSCustomObject]@{
    type                = "tool_call"
    ts                  = $ts
    session_id          = $session_id
    session_fp          = $session_fp
    sprint_id           = $sprint_id
    transcript_path     = $transcript_path
    cwd                 = $cwd
    tool                = $tool_name
    meta                = $meta
    response_tokens_est = $response_tokens_est
    response_chars      = $response_chars
} | ConvertTo-Json -Compress -Depth 5

# === Write to sprint-specific cost.jsonl ===
if ($sprint_id -ne "unassigned" -and $repo_root) {
    $costDir = Join-Path $repo_root "docs/sprints/sprint-$sprint_id"
    if (-not (Test-Path $costDir)) {
        New-Item -ItemType Directory -Path $costDir -Force | Out-Null
    }
    $costFile = Join-Path $costDir "cost.jsonl"
    Add-Content -Path $costFile -Value $event -ErrorAction SilentlyContinue
}

# === Write to global observability feed ===
$globalDir = Join-Path $env:USERPROFILE ".claude/observability"
if (-not (Test-Path $globalDir)) {
    New-Item -ItemType Directory -Path $globalDir -Force | Out-Null
}
Add-Content -Path (Join-Path $globalDir "tool-calls.jsonl") -Value $event -ErrorAction SilentlyContinue

} catch {
    # Telemetry must never block flow
}

exit 0
