# session-start-init.ps1
# SessionStart hook.
# Initializes session state:
#   - Creates ~/.claude/observability directory
#   - Detects active sprint from registry.md if not already marked
#   - Initializes .current-agent marker to "main"
#   - Writes a session_start event to the global sessions feed
#
# Always exits 0 — bootstrap failures must not block the session.

$ErrorActionPreference = 'SilentlyContinue'

try {

$RawInput = [Console]::In.ReadToEnd()
$Input_Data = $null
try {
    $Input_Data = $RawInput | ConvertFrom-Json -ErrorAction Stop
} catch {
    $Input_Data = [PSCustomObject]@{ session_id = "unknown" }
}

$session_id = if ($Input_Data.session_id) { $Input_Data.session_id } else { "unknown" }
$cwd = Get-Location

# === Ensure global observability directory exists ===
$globalDir = Join-Path $env:USERPROFILE ".claude/observability"
New-Item -ItemType Directory -Path $globalDir -Force -ErrorAction SilentlyContinue | Out-Null

# === If inside a repo, bootstrap sprint markers ===
$repo_root = ""
try {
    $repo_root = git rev-parse --show-toplevel 2>$null
} catch {}

if ($LASTEXITCODE -eq 0 -and $repo_root) {
    $sprints_dir = Join-Path $repo_root "docs/sprints"
    $marker = Join-Path $sprints_dir ".active-sprint"

    # If no active-sprint marker exists, try to infer from registry.md
    $registryFile = Join-Path $sprints_dir "registry.md"
    if (-not (Test-Path $marker) -and (Test-Path $registryFile)) {
        $active_sprint = ""
        $inActiveSection = $false

        foreach ($line in (Get-Content $registryFile)) {
            if ($line -match '^## Active Sprints') {
                $inActiveSection = $true
                continue
            }
            if ($line -match '^## ' -and $line -notmatch '^## Active Sprints') {
                $inActiveSection = $false
            }
            if ($inActiveSection -and $line -match '^\|\s*(\d+)\s*\|') {
                $active_sprint = $Matches[1].Trim()
                break
            }
        }

        if ($active_sprint) {
            New-Item -ItemType Directory -Path $sprints_dir -Force -ErrorAction SilentlyContinue | Out-Null
            Set-Content -Path $marker -Value $active_sprint -NoNewline -ErrorAction SilentlyContinue
        }
    }

    # If an active sprint is marked, ensure its .current-agent defaults to "main"
    if (Test-Path $marker) {
        $sprint_id = (Get-Content $marker -ErrorAction SilentlyContinue).Trim()
        if ($sprint_id) {
            $sprint_subdir = Join-Path $sprints_dir "sprint-$sprint_id"
            $agent_marker = Join-Path $sprint_subdir ".current-agent"
            if ((Test-Path $sprint_subdir) -and -not (Test-Path $agent_marker)) {
                Set-Content -Path $agent_marker -Value "main" -NoNewline -ErrorAction SilentlyContinue
            }
        }
    }
}

# === Write session_start event ===
$ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$event = [PSCustomObject]@{
    type       = "session_start"
    ts         = $ts
    session_id = $session_id
    cwd        = [string]$cwd
} | ConvertTo-Json -Compress -Depth 3

if ($event) {
    Add-Content -Path (Join-Path $globalDir "sessions.jsonl") -Value $event -ErrorAction SilentlyContinue
}

} catch {
    # Bootstrap must never block session
}

exit 0
