# post-edit-diff.ps1
# PostToolUse hook for Edit|Write|MultiEdit.
# Surfaces the git diff of the edited file with heuristic flags.
# Always exits 0 — diff surfacing is advisory, not blocking.

$ErrorActionPreference = 'SilentlyContinue'

$RawInput = [Console]::In.ReadToEnd()
$Input_Data = $null
try {
    $Input_Data = $RawInput | ConvertFrom-Json -ErrorAction Stop
} catch {
    exit 0
}

$tool_name = if ($Input_Data.tool_name) { $Input_Data.tool_name } else { "" }

switch ($tool_name) {
    { $_ -in 'Edit','Write','MultiEdit' } { }
    default { exit 0 }
}

$file_path = ""
try { $file_path = $Input_Data.tool_input.file_path } catch {}
if ([string]::IsNullOrEmpty($file_path)) { exit 0 }

# Must be inside a git repo
$repo_root = ""
try {
    $repo_root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($repo_root)) { exit 0 }
} catch {
    exit 0
}

# File must exist
if (-not (Test-Path $file_path)) { exit 0 }

# Normalize path relative to repo root
$rel_path = ""
try {
    $absFile = (Resolve-Path $file_path -ErrorAction Stop).Path -replace '\\', '/'
    $absRepo = (Resolve-Path $repo_root -ErrorAction Stop).Path -replace '\\', '/'
    $absRepo = $absRepo.TrimEnd('/')

    if ($absFile.StartsWith($absRepo, [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel_path = $absFile.Substring($absRepo.Length).TrimStart('/')
    } else {
        $rel_path = $file_path -replace '\\', '/'
    }
} catch {
    $rel_path = ($file_path -replace '\\', '/')
}

# === Handle untracked (new) files ===
$tracked = git -C $repo_root ls-files --error-unmatch $rel_path 2>$null
if ($LASTEXITCODE -ne 0) {
    $lines = (Get-Content $file_path).Count
    $chars = (Get-Item $file_path).Length
    Write-Output "=== New file created: $rel_path ==="
    Write-Output "Size: $lines lines, $chars bytes"
    Write-Output ""
    Write-Output "--- Preview (first 30 lines) ---"
    Get-Content $file_path -TotalCount 30
    exit 0
}

# === Tracked file — show diff ===
Push-Location $repo_root
$diff_stat = git diff --stat -- $rel_path 2>$null
$diff_body_full = git diff --unified=3 -- $rel_path 2>$null
Pop-Location

$diff_body_lines = if ($diff_body_full) { $diff_body_full -split "`n" } else { @() }
$diff_body = ($diff_body_lines | Select-Object -First 150) -join "`n"

# If no diff, the edit may have been a no-op or already committed
if ([string]::IsNullOrEmpty($diff_body)) {
    Write-Output "=== $rel_path`: no unstaged diff (already committed, or no-op edit) ==="
    exit 0
}

# Count added/removed lines
$added   = ($diff_body_lines | Where-Object { $_ -match '^\+[^+]' }).Count
$removed = ($diff_body_lines | Where-Object { $_ -match '^-[^-]' }).Count

Write-Output "=== Edit applied to $rel_path ==="
Write-Output "Stat: $diff_stat"
Write-Output "Lines: +${added} / -${removed}"

# === Heuristic flags ===
$total_changed = $added + $removed
if ($total_changed -gt 200) {
    Write-Output "WARNING: LARGE CHANGE: $total_changed lines modified. Verify this matches sprint scope."
}

# Check for new imports/usings
$new_imports = $diff_body_lines | Where-Object { $_ -match '^\+(using |import |use )' } | Select-Object -First 5
if ($new_imports) {
    Write-Output "INFO: NEW IMPORTS ADDED:"
    foreach ($imp in $new_imports) {
        Write-Output "    $imp"
    }
    Write-Output "  Verify these are necessary for the change."
}

# Check for deletion-heavy edits
if ($removed -gt 50 -and $added -lt [math]::Floor($removed / 2)) {
    Write-Output "WARNING: DELETION-HEAVY: removed $removed lines, added only $added."
    Write-Output "  Confirm this deletion is intentional."
}

# === Show truncated diff ===
Write-Output ""
Write-Output "--- Diff (truncated to 150 lines) ---"
Write-Output $diff_body

# If diff was truncated, note it
$full_diff_line_count = $diff_body_lines.Count
if ($full_diff_line_count -gt 150) {
    Write-Output ""
    Write-Output "... diff truncated ($full_diff_line_count total lines; showing first 150) ..."
    Write-Output "Run 'git diff -- $rel_path' to see full diff."
}

exit 0
