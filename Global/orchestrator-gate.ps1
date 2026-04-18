# orchestrator-gate.ps1
# PostToolUse hook for ExitPlanMode — injects orchestrator instructions directly
# so the model does NOT need a separate Read call to begin the planning sequence.

$ErrorActionPreference = 'Stop'

$OrchestratorFile = "orchestrator.md"
if (-not (Test-Path $OrchestratorFile)) {
    Write-Output ""
    Write-Output "=========================================="
    Write-Output " ORCHESTRATOR GATE - ERROR"
    Write-Output "=========================================="
    Write-Output ""
    Write-Output "ERROR: orchestrator.md not found in project root."
    Write-Output "Cannot proceed. Ask user to verify file exists."
    Write-Output ""
    Write-Output "=========================================="
    exit 0
}

$Collision = $false
$SprintSummaries = [System.Collections.ArrayList]::new()
$Details = [System.Collections.ArrayList]::new()
$ReservationCount = 0

# --- Try registry-based detection first ---
$RegistryFile = "docs/sprints/registry.md"
if (Test-Path $RegistryFile) {
    $Content = Get-Content $RegistryFile -Raw

    # Extract Active Sprints section
    $InActiveSection = $false
    $ActiveLines = [System.Collections.ArrayList]::new()
    $InReservationSection = $false
    $ReservationLines = [System.Collections.ArrayList]::new()

    foreach ($line in (Get-Content $RegistryFile)) {
        if ($line -match '^## Active Sprints') {
            $InActiveSection = $true
            $InReservationSection = $false
            continue
        }
        if ($line -match '^## File Reservations') {
            $InReservationSection = $true
            $InActiveSection = $false
            continue
        }
        if ($line -match '^## ' -and -not ($line -match '^## Active Sprints|^## File Reservations')) {
            $InActiveSection = $false
            $InReservationSection = $false
        }
        if ($InActiveSection) { [void]$ActiveLines.Add($line) }
        if ($InReservationSection) { [void]$ReservationLines.Add($line) }
    }

    # Parse Active Sprints table for rows with sprint IDs (3-digit pattern)
    foreach ($line in $ActiveLines) {
        if ($line -match '^\|\s*(\d{3})\s*\|') {
            $Id = $Matches[1]
            $Fields = $line -split '\|' | ForEach-Object { $_.Trim() }
            # Fields[0] is empty (before first |), Fields[1]=ID, etc.
            $Goal     = if ($Fields.Count -gt 4) { $Fields[4] } else { "" }
            $Phase    = if ($Fields.Count -gt 5) { $Fields[5] } else { "" }
            $Progress = if ($Fields.Count -gt 6) { $Fields[6] } else { "" }

            $Collision = $true
            [void]$SprintSummaries.Add("  Sprint ${Id}: `"$Goal`" ($Phase, $Progress)")
            [void]$Details.Add("Sprint $Id active: $Goal ($Phase)")
        }
    }

    # Count file reservations
    foreach ($line in $ReservationLines) {
        if ($line -match '^\|\s*`?[^|`]+`?\s*\|\s*\d{3}\s*\|') {
            $ReservationCount++
        }
    }
} else {
    # --- Fallback: legacy single-file detection ---
    $AcFile = "docs/active-context.md"
    if (Test-Path $AcFile) {
        $AcContent = Get-Content $AcFile -Raw
        # Extract body after frontmatter
        if ($AcContent -match '(?s)---\r?\n(.+)') {
            $Body = $Matches[1]
            if ($Body -match '\*\*Last Verdict:\*\*\s+(\S+)') {
                $Verdict = $Matches[1]
                if ($Verdict -and $Verdict -ne "SHIP") {
                    $Collision = $true
                    [void]$Details.Add("active-context.md: Last Verdict is '$Verdict' (legacy mode)")
                }
            }
        }
    }

    $CpFile = "docs/current-plan.md"
    if (Test-Path $CpFile) {
        $CpContent = Get-Content $CpFile
        $Unchecked = ($CpContent | Select-String -Pattern '- \[ \]' -SimpleMatch).Count
        if ($Unchecked -gt 0) {
            $Collision = $true
            [void]$Details.Add("current-plan.md: $Unchecked unchecked items remain (legacy mode)")
        }
    }
}

# =============================================================================
# OUTPUT — Injected directly into the conversation as hook feedback.
# =============================================================================

Write-Output ""
Write-Output "=========================================="
Write-Output " ORCHESTRATOR GATE - ACTIVATED"
Write-Output "=========================================="
Write-Output ""
Write-Output "ExitPlanMode fired. You are now the ORCHESTRATOR."
Write-Output "STOP. Do NOT write code or spawn agents yet."
Write-Output ""

# --- Collision status ---
if ($Collision) {
    if ($SprintSummaries.Count -gt 0) {
        Write-Output ">>> ACTIVE SPRINTS DETECTED <<<"
        foreach ($S in $SprintSummaries) {
            Write-Output $S
        }
        if ($ReservationCount -gt 0) {
            Write-Output ""
            Write-Output "  File reservations: $ReservationCount files reserved across active sprints."
            Write-Output "  New sprint will be checked for file reservation conflicts during planning."
        }
    } else {
        Write-Output ">>> SPRINT COLLISION DETECTED (legacy mode) <<<"
        foreach ($D in $Details) {
            Write-Output "  - $D"
        }
        Write-Output ""
        Write-Output "You MUST present these options to the user BEFORE proceeding:"
        Write-Output "  (1) Archive and proceed - archive current sprint, start new"
        Write-Output "  (2) Abandon - drop without archiving"
        Write-Output "  (3) Resume - cancel new plan, continue current sprint"
        Write-Output ""
        Write-Output "BLOCKED until user chooses."
    }
    Write-Output ""
} else {
    Write-Output "No active sprints detected. Clear to proceed."
    Write-Output ""
}

# --- Inline orchestrator instructions ---
Write-Output "=========================================="
Write-Output " ORCHESTRATOR INSTRUCTIONS - FOLLOW NOW"
Write-Output "=========================================="
Write-Output ""
Write-Output "## CRITICAL RULES"
Write-Output ""
Write-Output "1. NEVER edit source files directly. Write/Edit are ONLY for docs/ files."
Write-Output "   ALL source code changes go through CODER sub-agents."
Write-Output "2. ALWAYS spawn CODER and VERIFIER sub-agents. No exceptions."
Write-Output "3. Planning flows directly into execution. After writing sprint docs,"
Write-Output "   immediately spawn CODERs. Do NOT stop for /compact or user re-entry."
Write-Output "4. NEVER spawn agents via Bash. ALWAYS use the Task tool with subagent_type."
Write-Output "5. You ARE the orchestrator. Do NOT spawn an orchestrator sub-agent."
Write-Output "6. ALWAYS log collisions to docs/sprints/conflict-log.md."
Write-Output ""
Write-Output "## MODE DETECTION"
Write-Output ""
Write-Output "ExitPlanMode was just triggered -> this is ALWAYS Planning mode (new sprint)."
Write-Output "Never route to an existing sprint after ExitPlanMode."
Write-Output ""
Write-Output "## PHASE ROUTING"
Write-Output ""
Write-Output "New sprint -> Phase is 'planning'"
Write-Output "-> Read: .claude/playbooks/orchestrator-planning.md"
Write-Output ""
Write-Output "Other phases (for reference only - do NOT load these now):"
Write-Output "  executing/verifying -> .claude/playbooks/orchestrator-execution.md"
Write-Output "  rework              -> .claude/playbooks/orchestrator-rework.md"
Write-Output "  shipping            -> .claude/playbooks/orchestrator-shipping.md"
Write-Output ""
Write-Output "## YOUR NEXT ACTION"
Write-Output ""
Write-Output "1. Read .claude/playbooks/orchestrator-planning.md"
Write-Output "2. Follow the planning playbook step by step"
Write-Output "3. Do NOT read orchestrator.md again - you already have the instructions above"
Write-Output ""
Write-Output "=========================================="
