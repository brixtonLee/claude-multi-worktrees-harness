# statusline-command.ps1 — Claude Code statusLine command
# Rich status bar with labelled segments, sourced from stdin JSON + .jsonl transcript

$ErrorActionPreference = 'SilentlyContinue'

# ── Read JSON from stdin ─────────────────────────────────────────────────────
$JsonInput = ""
try {
    $JsonInput = [Console]::In.ReadToEnd()
} catch {
    $JsonInput = "{}"
}

# ── Parse all fields with ConvertFrom-Json ───────────────────────────────────
$D = [PSCustomObject]@{}
try {
    $D = $JsonInput | ConvertFrom-Json -ErrorAction Stop
} catch {}

function Safe-Get {
    param([object]$Obj, [string[]]$Keys)
    $Cur = $Obj
    foreach ($K in $Keys) {
        if ($null -eq $Cur) { return "" }
        try { $Cur = $Cur.$K } catch { return "" }
    }
    if ($null -eq $Cur) { return "" }
    return [string]$Cur
}

$SID             = Safe-Get $D 'session_id'
$TranscriptPath  = Safe-Get $D 'transcript_path'
$ModelName       = Safe-Get $D 'model','display_name'
$ModelId         = Safe-Get $D 'model','id'
$Dir             = Safe-Get $D 'workspace','current_dir'
$UsedPctRaw      = Safe-Get $D 'context_window','used_percentage'
$RemainingPctRaw = Safe-Get $D 'context_window','remaining_percentage'
$CtxSizeRaw      = Safe-Get $D 'context_window','context_window_size'
$TotalInTokRaw   = Safe-Get $D 'context_window','total_input_tokens'
$TotalOutTokRaw  = Safe-Get $D 'context_window','total_output_tokens'
$CostUsdRaw      = Safe-Get $D 'cost','total_cost_usd'
$DurationMsRaw   = Safe-Get $D 'cost','total_duration_ms'
$LinesAddedRaw   = Safe-Get $D 'cost','total_lines_added'
$LinesRemovedRaw = Safe-Get $D 'cost','total_lines_removed'
$VersionRaw      = Safe-Get $D 'version'

# Rate limits (nested)
$Rate5hRaw = ""
$Rate7dRaw = ""
try {
    $rl = $D.rate_limits
    if ($null -ne $rl -and $null -ne $rl.five_hour) {
        $Rate5hRaw = [string]$rl.five_hour.used_percentage
    }
    if ($null -ne $rl -and $null -ne $rl.seven_day) {
        $Rate7dRaw = [string]$rl.seven_day.used_percentage
    }
} catch {}

# ── Defaults ─────────────────────────────────────────────────────────────────
if ([string]::IsNullOrEmpty($ModelName)) { $ModelName = "?" }

function To-Int($v) { if ($v -match '^\d+') { [int][math]::Floor([double]$v) } else { 0 } }

$UsedPct      = To-Int $UsedPctRaw
$RemainingPct = if ($RemainingPctRaw -match '^\d+') { To-Int $RemainingPctRaw } else { 100 - $UsedPct }
$CtxSize      = To-Int $CtxSizeRaw
$TotalInTok   = To-Int $TotalInTokRaw
$TotalOutTok  = To-Int $TotalOutTokRaw
$LinesAdded   = To-Int $LinesAddedRaw
$LinesRemoved = To-Int $LinesRemovedRaw
$Rate5h       = To-Int $Rate5hRaw
$Rate7d       = To-Int $Rate7dRaw
$DurationMs   = To-Int $DurationMsRaw

$Cost = if (-not [string]::IsNullOrEmpty($CostUsdRaw) -and $CostUsdRaw -ne "0" -and $CostUsdRaw -ne "") {
    try { '{0:F2}' -f [double]$CostUsdRaw } catch { "0.00" }
} else { "0.00" }

$DirShort = if (-not [string]::IsNullOrEmpty($Dir)) { Split-Path $Dir -Leaf } else { "?" }

# ── Cache directory ──────────────────────────────────────────────────────────
$CacheDir = Join-Path $env:TEMP "claude-statusline"
New-Item -ItemType Directory -Path $CacheDir -Force -ErrorAction SilentlyContinue | Out-Null

$SessionIdFile = Join-Path $CacheDir "session-id"
$TurnsFile     = Join-Path $CacheDir "turns"
$StartFile     = Join-Path $CacheDir "session-start"
$PrevPctFile   = Join-Path $CacheDir "prevpct"
$GitCacheFile  = Join-Path $CacheDir "git-branch"
$JsonlCache    = Join-Path $CacheDir "jsonl-stats"
$JsonlTs       = Join-Path $CacheDir "jsonl-ts"

# ── Session-aware cache reset ────────────────────────────────────────────────
$PrevSession = ""
if (Test-Path $SessionIdFile) { $PrevSession = Get-Content $SessionIdFile -ErrorAction SilentlyContinue }

$SessionChanged = ($SID -and $SID -ne $PrevSession)
$NowEpoch = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

foreach ($f in @($TurnsFile, $StartFile, $PrevPctFile, $JsonlCache, $JsonlTs)) {
    if (Test-Path $f) {
        if ($SessionChanged) {
            Remove-Item $f -Force -ErrorAction SilentlyContinue
        } else {
            $Age = ([DateTimeOffset]::UtcNow - [DateTimeOffset](Get-Item $f).LastWriteTimeUtc).TotalSeconds
            if ($Age -gt 7200) { Remove-Item $f -Force -ErrorAction SilentlyContinue }
        }
    }
}

if ($SID) { Set-Content -Path $SessionIdFile -Value $SID -NoNewline }

# ── Token counts (human-readable) ───────────────────────────────────────────
$TokenStr = ""
if ($CtxSize -gt 0) {
    $UsedTok = [math]::Floor($CtxSize * $UsedPct / 100)
    $UsedK = [math]::Floor($UsedTok / 1000)
    $MaxK  = [math]::Floor($CtxSize / 1000)
    $TokenStr = "${UsedK}k/${MaxK}k"
}

# ── Cumulative session tokens ───────────────────────────────────────────────
$CumInK  = [math]::Floor($TotalInTok / 1000)
$CumOutK = [math]::Floor($TotalOutTok / 1000)

# ── Turn counter ─────────────────────────────────────────────────────────────
$Turns = 1
if (Test-Path $TurnsFile) {
    $Turns = [int](Get-Content $TurnsFile -ErrorAction SilentlyContinue) + 1
}
Set-Content -Path $TurnsFile -Value $Turns -NoNewline

# ── Session elapsed ─────────────────────────────────────────────────────────
if ($DurationMs -gt 0) {
    $ElapsedSec = [math]::Floor($DurationMs / 1000)
} else {
    if (-not (Test-Path $StartFile) -or $Turns -eq 1) {
        Set-Content -Path $StartFile -Value $NowEpoch -NoNewline
    }
    $StartEpoch = [long](Get-Content $StartFile -ErrorAction SilentlyContinue)
    $ElapsedSec = $NowEpoch - $StartEpoch
}

$ElapsedStr = if ($ElapsedSec -ge 3600) {
    $h = [math]::Floor($ElapsedSec / 3600)
    $m = [math]::Floor(($ElapsedSec % 3600) / 60)
    "${h}h${m}m"
} else {
    "$([math]::Floor($ElapsedSec / 60))m"
}

# ── Burn rate (context % per turn) ──────────────────────────────────────────
$BurnStr = ""
$ProjStr = ""
if ($Turns -gt 2 -and $UsedPct -gt 0) {
    $BurnPct = [math]::Floor($UsedPct / $Turns)
    if ($BurnPct -gt 0) {
        $BurnStr = "+${BurnPct}%/t"
        $CompactThreshold = if ($env:CLAUDE_AUTOCOMPACT_PCT_OVERRIDE) {
            [int]$env:CLAUDE_AUTOCOMPACT_PCT_OVERRIDE
        } else { 75 }
        if ($UsedPct -lt $CompactThreshold) {
            $TurnsLeft = [math]::Floor(($CompactThreshold - $UsedPct) / $BurnPct)
            if ($TurnsLeft -gt 0 -and $TurnsLeft -lt 50) {
                # Use Unicode arrow for Windows terminal compatibility
                $ProjStr = "~${TurnsLeft}t->compact"
            }
        }
    }
}
Set-Content -Path $PrevPctFile -Value $UsedPct -NoNewline

# ── Git branch (5s TTL cache) ───────────────────────────────────────────────
$Branch = ""
if (-not [string]::IsNullOrEmpty($Dir)) {
    $CacheStale = $true
    if (Test-Path $GitCacheFile) {
        $CacheAge = ([DateTimeOffset]::UtcNow - [DateTimeOffset](Get-Item $GitCacheFile).LastWriteTimeUtc).TotalSeconds
        if ($CacheAge -lt 5) { $CacheStale = $false }
    }
    if ($CacheStale) {
        try {
            $b = git -C $Dir rev-parse --abbrev-ref HEAD 2>$null
            if ($LASTEXITCODE -eq 0 -and $b) {
                Set-Content -Path $GitCacheFile -Value $b -NoNewline
                $Branch = $b
            } else {
                Set-Content -Path $GitCacheFile -Value "" -NoNewline
            }
        } catch {
            Set-Content -Path $GitCacheFile -Value "" -NoNewline
        }
    } else {
        $Branch = Get-Content $GitCacheFile -ErrorAction SilentlyContinue
    }
}

# ── .jsonl transcript stats (30s TTL) ───────────────────────────────────────
$ApiCalls = ""
$ToolUses = ""
$CacheHit = ""

$JsonlStale = $true
if (Test-Path $JsonlTs) {
    $jtsAge = ([DateTimeOffset]::UtcNow - [DateTimeOffset](Get-Item $JsonlTs).LastWriteTimeUtc).TotalSeconds
    if ($jtsAge -lt 30) { $JsonlStale = $false }
}

$JsonlFile = $TranscriptPath

if ($JsonlStale -and $JsonlFile -and (Test-Path $JsonlFile)) {
    try {
        $apiCount = 0; $cacheRead = 0; $cacheCreate = 0; $toolCount = 0

        foreach ($line in [System.IO.File]::ReadLines($JsonlFile)) {
            $line = $line.Trim()
            if ([string]::IsNullOrEmpty($line)) { continue }
            try {
                $entry = $line | ConvertFrom-Json -ErrorAction Stop
            } catch { continue }

            if ($entry.type -eq 'assistant') {
                $msg = $entry.message
                if ($null -ne $msg.usage) {
                    $apiCount++
                    $cacheRead   += if ($msg.usage.cache_read_input_tokens)    { $msg.usage.cache_read_input_tokens }    else { 0 }
                    $cacheCreate += if ($msg.usage.cache_creation_input_tokens) { $msg.usage.cache_creation_input_tokens } else { 0 }
                }
                if ($null -ne $msg.content) {
                    foreach ($block in $msg.content) {
                        if ($block.type -eq 'tool_use') { $toolCount++ }
                    }
                }
            }
        }

        $totalCache = $cacheRead + $cacheCreate
        $cachePct = if ($totalCache -gt 0) { [math]::Floor($cacheRead * 100 / $totalCache) } else { 0 }

        $ApiCalls = $apiCount
        $ToolUses = $toolCount
        $CacheHit = $cachePct

        Set-Content -Path $JsonlCache -Value "$ApiCalls|$ToolUses|$CacheHit" -NoNewline
        Set-Content -Path $JsonlTs -Value (Get-Date -Format o) -NoNewline
    } catch {}
} elseif (Test-Path $JsonlCache) {
    $cached = Get-Content $JsonlCache -ErrorAction SilentlyContinue
    if ($cached -match '^(\d+)\|(\d+)\|(\d+)$') {
        $ApiCalls = $Matches[1]
        $ToolUses = $Matches[2]
        $CacheHit = $Matches[3]
    }
}

# ── ANSI colors ─────────────────────────────────────────────────────────────
$ESC     = [char]27
$GREEN   = "$ESC[01;32m"
$BLUE    = "$ESC[01;34m"
$CYAN    = "$ESC[01;36m"
$YELLOW  = "$ESC[01;33m"
$RED     = "$ESC[01;31m"
$MAGENTA = "$ESC[01;35m"
$DIM     = "$ESC[2m"
$RESET   = "$ESC[0m"
$LBL     = "$ESC[0;37m"

# Context color
if ($RemainingPct -le 15)     { $CtxColor = $RED;    $CtxTag = "CRITICAL" }
elseif ($RemainingPct -le 30) { $CtxColor = $YELLOW; $CtxTag = "LOW" }
elseif ($RemainingPct -le 50) { $CtxColor = $YELLOW; $CtxTag = "" }
else                          { $CtxColor = $CYAN;   $CtxTag = "" }

# Burn rate color
$BurnColor = $CYAN
if ($BurnStr) {
    $burnVal = [int]($BurnStr -replace '[^0-9]', '')
    if ($burnVal -ge 6) { $BurnColor = $RED }
    elseif ($burnVal -ge 3) { $BurnColor = $YELLOW }
}

# Cache hit color
$CacheColor = $DIM
if ($CacheHit -and $CacheHit -ne "0") {
    $chVal = [int]$CacheHit
    if ($chVal -ge 70) { $CacheColor = $GREEN }
    elseif ($chVal -ge 40) { $CacheColor = $YELLOW }
    else { $CacheColor = $RED }
}

# Rate limit color (5h)
$RateColor = $CYAN
if ($Rate5h -ge 80) { $RateColor = $RED }
elseif ($Rate5h -ge 50) { $RateColor = $YELLOW }

# ── Separator ───────────────────────────────────────────────────────────────
$SEP = "${DIM} | ${RESET}"

# ── Assemble status line ────────────────────────────────────────────────────
$line = "${YELLOW}${ModelName}${RESET}"

# Branch
if ($Branch) {
    $line += "${SEP} ${MAGENTA}${Branch}${RESET}"
}

# Context Window
$CtxDetail = if ($TokenStr) { " ($TokenStr)" } else { "" }
if ($CtxTag) {
    $line += "${SEP} ${LBL}Context Window:${RESET} ${CtxColor}${CtxTag} ${RemainingPct}%${CtxDetail}${RESET}"
} else {
    $line += "${SEP} ${LBL}Context Window:${RESET} ${CtxColor}${RemainingPct}%${CtxDetail}${RESET}"
}

# Cost
if ($Cost -ne "0.00") {
    $line += "${SEP} ${LBL}Cost:${RESET} ${GREEN}`$${Cost}${RESET}"
}

# Burn Rate
if ($BurnStr) {
    $line += "${SEP} ${LBL}Burn Rate:${RESET} ${BurnColor}${BurnStr}${RESET}"
    if ($ProjStr) { $line += " ${DIM}(${ProjStr})${RESET}" }
}

# Current Turn
$line += "${SEP} ${LBL}Current Turn:${RESET} ${CYAN}${Turns}${RESET}"

# Elapsed
$line += "${SEP} ${LBL}Elapsed:${RESET} ${CYAN}${ElapsedStr}${RESET}"

# API Calls
if ($ApiCalls -and $ApiCalls -ne "0") {
    $line += "${SEP} ${LBL}API Calls:${RESET} ${CYAN}${ApiCalls}${RESET}"
}

# Tools Invoked
if ($ToolUses -and $ToolUses -ne "0") {
    $line += "${SEP} ${LBL}Tools Invoked:${RESET} ${CYAN}${ToolUses}${RESET}"
}

# Tokens (cumulative)
if ($CumInK -gt 0 -or $CumOutK -gt 0) {
    $line += "${SEP} ${LBL}Tokens:${RESET} ${CYAN}in ${CumInK}k / out ${CumOutK}k${RESET}"
}

# Lines Changed
if ($LinesAdded -gt 0 -or $LinesRemoved -gt 0) {
    $line += "${SEP} ${LBL}Lines Changed:${RESET} ${GREEN}+${LinesAdded}${RESET} ${RED}/ -${LinesRemoved}${RESET}"
}

# Cache Hit
if ($CacheHit -and $CacheHit -ne "0") {
    $line += "${SEP} ${LBL}Cache Hit:${RESET} ${CacheColor}${CacheHit}%${RESET}"
}

# Rate Limit (5h)
if ($Rate5h -gt 0) {
    $line += "${SEP} ${LBL}Rate Limit (5h):${RESET} ${RateColor}${Rate5h}%${RESET}"
}

Write-Output $line
