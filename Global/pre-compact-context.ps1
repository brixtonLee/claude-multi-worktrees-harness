# pre-compact-context.ps1
# Dynamic PreCompact hook: injects active sprint state + static resume instructions
# Called by Claude Code before compaction to preserve sprint-specific context

$ErrorActionPreference = 'SilentlyContinue'

$Output = ""

# 1. Static resume instructions (always included)
$ResumePath = Join-Path $env:USERPROFILE ".claude/post-compact-resume.md"
if (Test-Path $ResumePath) {
    $Output += Get-Content $ResumePath -Raw
    $Output += "`n---`n"
}

# 2. Find active sprints from registry
$RegistryPath = "docs/sprints/registry.md"
$GitRoot = ""

if (-not (Test-Path $RegistryPath)) {
    # Try worktree-relative path
    try {
        $GitRoot = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0 -and $GitRoot) {
            $RegistryPath = Join-Path $GitRoot "docs/sprints/registry.md"
        }
    } catch {}
}

if (Test-Path $RegistryPath) {
    $RegistryContent = Get-Content $RegistryPath

    # Extract sprint IDs from Active Sprints table (rows matching | NNN |)
    $SprintIds = @()
    foreach ($line in $RegistryContent) {
        if ($line -match '^\|\s*(\d{3})\s*\|') {
            $SprintIds += $Matches[1]
        }
    }

    foreach ($Id in $SprintIds) {
        $ContextPath = "docs/sprints/sprint-$Id/context.md"
        $PlanPath    = "docs/sprints/sprint-$Id/plan.md"

        # Try worktree-relative if direct path fails
        if (-not (Test-Path $ContextPath) -and $GitRoot) {
            $ContextPath = Join-Path $GitRoot "docs/sprints/sprint-$Id/context.md"
            $PlanPath    = Join-Path $GitRoot "docs/sprints/sprint-$Id/plan.md"
        }

        if (Test-Path $ContextPath) {
            $Output += "## Active Sprint $Id - Context`n"
            $Output += Get-Content $ContextPath -Raw
            $Output += "`n"
        }
        if (Test-Path $PlanPath) {
            $Output += "## Active Sprint $Id - Plan`n"
            $Output += Get-Content $PlanPath -Raw
            $Output += "`n---`n"
        }
    }
}

# 3. Check for exploration-notes.md (mid-planning compaction)
$ExplorationPath = "docs/sprints/exploration-notes.md"
if (-not (Test-Path $ExplorationPath) -and $GitRoot) {
    $ExplorationPath = Join-Path $GitRoot "docs/sprints/exploration-notes.md"
}
if (Test-Path $ExplorationPath) {
    $Output += "## Mid-Planning State - Exploration Notes`n"
    $Output += "Planning was in progress when compaction triggered. Resume from exploration-notes.md.`n"
    $Output += Get-Content $ExplorationPath -Raw
    $Output += "`n"
}

# Emit all collected context
Write-Output $Output
