# statusline.ps1 — PostToolUse hook for all tools (matcher: .*)
# Displays context health, burn rate, and session metrics
# Pure PowerShell — no jq, no pipes

$ErrorActionPreference = 'SilentlyContinue'

# ── Read JSON from stdin ──────────────────────────────────────────────────────
$JsonInput = ""
try {
    $JsonInput = [Console]::In.ReadToEnd()
} catch {
    $JsonInput = "{}"
}

# ── Parse JSON ────────────────────────────────────────────────────────────────
$Data = @{}
try {
    $Data = $JsonInput | ConvertFrom-Json -ErrorAction Stop
} catch {
    $Data = [PSCustomObject]@{}
}

# ── Helper: safe nested property access ───────────────────────────────────────
function Get-JsonVal {
    param([object]$Obj, [string[]]$Keys)
    $Current = $Obj
    foreach ($Key in $Keys) {
        if ($null -eq $Current) { return "" }
        try {
            $Current = $Current.$Key
        } catch {
            return ""
        }
    }
    if ($null -eq $Current) { return "" }
    return [string]$Current
}

# ── Cache directory ───────────────────────────────────────────────────────────
$CacheDir = Join-Path $env:TEMP "claude-statusline"
if (-not (Test-Path $CacheDir)) {
    New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
}

$TurnsFile   = Join-Path $CacheDir "turns"
$StartFile   = Join-Path $CacheDir "session-start"
$PrevPctFile = Join-Path $CacheDir "prevpct"
$GitCache    = Join-Path $CacheDir "git-branch"

# ── Reset stale caches (files older than 2 hours) ────────────────────────────
$Now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
foreach ($f in @($TurnsFile, $StartFile, $PrevPctFile)) {
    if (Test-Path $f) {
        $FileTime = (Get-Item $f).LastWriteTimeUtc
        $Age = ([DateTimeOffset]::UtcNow - [DateTimeOffset]$FileTime).TotalSeconds
        if ($Age -gt 7200) {
            Remove-Item $f -Force -ErrorAction SilentlyContinue
        }
    }
}

# ── Parse JSON fields ────────────────────────────────────────────────────────
$Model = Get-JsonVal $Data 'model','display_name'
if ([string]::IsNullOrEmpty($Model)) { $Model = "?" }

$PctRaw = Get-JsonVal $Data 'context_window','used_percentage'
$Pct = if ($PctRaw -match '^\d+') { [int][math]::Floor([double]$PctRaw) } else { 0 }

$CostRaw = Get-JsonVal $Data 'cost','total_cost_usd'
$Cost = if (-not [string]::IsNullOrEmpty($CostRaw) -and $CostRaw -ne "0") {
    try { '{0:F2}' -f [double]$CostRaw } catch { "0.00" }
} else { "0.00" }

$Dir = Get-JsonVal $Data 'workspace','current_dir'

$CtxMaxRaw = Get-JsonVal $Data 'context_window','max_tokens'
$CtxMax = if ($CtxMaxRaw -match '^\d+') { [int][math]::Floor([double]$CtxMaxRaw) } else { 0 }

$CtxUsedRaw = Get-JsonVal $Data 'context_window','used_tokens'
$CtxUsed = if ($CtxUsedRaw -match '^\d+') { [int][math]::Floor([double]$CtxUsedRaw) } else { 0 }

# Short directory name
$DirShort = if (-not [string]::IsNullOrEmpty($Dir)) { Split-Path $Dir -Leaf } else { "?" }

# ── Remaining context ─────────────────────────────────────────────────────────
$Remaining = 100 - $Pct

# ── Token counts (human-readable) ────────────────────────────────────────────
$TokenStr = ""
if ($CtxMax -gt 0) {
    $UsedK = [math]::Floor($CtxUsed / 1000)
    $MaxK  = [math]::Floor($CtxMax / 1000)
    $TokenStr = "${UsedK}k/${MaxK}k"
}

# ── Cost string ──────────────────────────────────────────────────────────────
$CostStr = ""
if ($Cost -ne "0.00") {
    $CostStr = "`$$Cost"
}

# ── Turn counter ──────────────────────────────────────────────────────────────
$Turns = 1
if (Test-Path $TurnsFile) {
    $Turns = [int](Get-Content $TurnsFile -ErrorAction SilentlyContinue) + 1
}
Set-Content -Path $TurnsFile -Value $Turns -NoNewline

# ── Session start time & elapsed ──────────────────────────────────────────────
if (-not (Test-Path $StartFile) -or $Turns -eq 1) {
    Set-Content -Path $StartFile -Value $Now -NoNewline
}
$StartEpoch = [long](Get-Content $StartFile -ErrorAction SilentlyContinue)
$ElapsedMin = [math]::Floor(($Now - $StartEpoch) / 60)

# ── Burn rate ─────────────────────────────────────────────────────────────────
$BurnStr = ""
$ProjStr = ""
if ($Turns -gt 2) {
    if (Test-Path $PrevPctFile) {
        if ($Turns -gt 0) {
            $BurnPct = [math]::Floor($Pct / $Turns)
            if ($BurnPct -gt 0) {
                if ($BurnPct -ge 3) {
                    $BurnStr = "+${BurnPct}%/t"
                }
                $CompactThreshold = if ($env:CLAUDE_AUTOCOMPACT_PCT_OVERRIDE) {
                    [int]$env:CLAUDE_AUTOCOMPACT_PCT_OVERRIDE
                } else { 75 }

                if ($Pct -lt $CompactThreshold) {
                    $Divisor = if ($BurnPct -eq 0) { 1 } else { $BurnPct }
                    $TurnsLeft = [math]::Floor(($CompactThreshold - $Pct) / $Divisor)
                    if ($TurnsLeft -gt 0 -and $TurnsLeft -lt 20) {
                        $ProjStr = "~${TurnsLeft}t->compact"
                    }
                }
            }
        }
    }
}
Set-Content -Path $PrevPctFile -Value $Pct -NoNewline

# ── Context warning ──────────────────────────────────────────────────────────
$CtxIcon = ""
if ($Remaining -le 15) {
    $CtxIcon = "CRIT "
} elseif ($Remaining -le 40) {
    $CtxIcon = "WARN "
}

# ── Git branch (5s TTL cache) ────────────────────────────────────────────────
$Branch = ""
if (-not [string]::IsNullOrEmpty($Dir)) {
    $CacheStale = $true
    if (Test-Path $GitCache) {
        $CacheAge = ([DateTimeOffset]::UtcNow - [DateTimeOffset](Get-Item $GitCache).LastWriteTimeUtc).TotalSeconds
        if ($CacheAge -lt 5) { $CacheStale = $false }
    }
    if ($CacheStale) {
        try {
            $b = git -C $Dir rev-parse --abbrev-ref HEAD 2>$null
            if ($LASTEXITCODE -eq 0 -and $b) {
                Set-Content -Path $GitCache -Value $b -NoNewline
                $Branch = $b
            } else {
                Set-Content -Path $GitCache -Value "" -NoNewline
            }
        } catch {
            Set-Content -Path $GitCache -Value "" -NoNewline
        }
    } else {
        $Branch = (Get-Content $GitCache -ErrorAction SilentlyContinue)
    }
}

# ── AWS region (Bedrock) ─────────────────────────────────────────────────────
$Region = if ($env:AWS_REGION) { $env:AWS_REGION } elseif ($env:AWS_DEFAULT_REGION) { $env:AWS_DEFAULT_REGION } else { "" }

# ── Assemble output ──────────────────────────────────────────────────────────
$Parts = [System.Collections.ArrayList]::new()
[void]$Parts.Add("[$Model]")
[void]$Parts.Add($DirShort)
if ($Branch)   { [void]$Parts.Add("($Branch)") }
[void]$Parts.Add("${CtxIcon}CTX: ${Remaining}% left")
if ($TokenStr) { [void]$Parts.Add($TokenStr) }
if ($CostStr)  { [void]$Parts.Add($CostStr) }
if ($BurnStr)  { [void]$Parts.Add($BurnStr) }
if ($ProjStr)  { [void]$Parts.Add($ProjStr) }
[void]$Parts.Add("T#${Turns}")
[void]$Parts.Add("${ElapsedMin}m")
if ($Region)   { [void]$Parts.Add($Region) }

Write-Output ($Parts -join " | ")
