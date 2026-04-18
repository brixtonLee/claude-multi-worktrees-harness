# pre-read-guard.ps1
# Blocks Read calls that would waste context:
#   - Reads of >1000-line files without offset/limit
#   - Reads of build artifacts (bin/, obj/, target/, node_modules/, etc.)
#
# Exit codes:
#   0 = allow (tool proceeds)
#   2 = block (message surfaces to model as tool error)

$ErrorActionPreference = 'SilentlyContinue'

$RawInput = [Console]::In.ReadToEnd()
$Input_Data = $null
try {
    $Input_Data = $RawInput | ConvertFrom-Json -ErrorAction Stop
} catch {
    exit 0
}

$file_path = ""
try { $file_path = $Input_Data.tool_input.file_path } catch {}
$offset = $null
try { $offset = $Input_Data.tool_input.offset } catch {}

# No path? Let Read's own validation handle it.
if ([string]::IsNullOrEmpty($file_path)) { exit 0 }

# Normalize to forward slashes for consistent matching
$normalizedPath = $file_path -replace '\\', '/'

# === Block 1: Build artifacts and dependencies ===
$blockedPatterns = @(
    '*/bin/*', '*/obj/*', '*/target/*', '*/node_modules/*',
    '*/.next/*', '*/dist/*', '*/build/*', '*/.venv/*', '*/__pycache__/*'
)

foreach ($pattern in $blockedPatterns) {
    # Convert glob to regex: * -> .*, escape other special chars
    $regex = '^' + ($pattern -replace '\.', '\.' -replace '\*', '.*') + '$'
    if ($normalizedPath -match $regex) {
        [Console]::Error.WriteLine(@"
BLOCKED: Read of build artifact or dependency directory.

Path: $file_path

These paths contain generated or vendored code and should not be read directly.
Alternatives:
  - For dependency source: check the package's own repository
  - For build output: check build logs via 'dotnet build' or 'cargo build'
  - Override: if truly needed, use Bash 'cat' with explicit justification
"@)
        exit 2
    }
}

# === Block 2: File must exist to size-check ===
if (-not (Test-Path $file_path)) { exit 0 }

# === Block 3: Large file without offset ===
$lines = (Get-Content $file_path -ErrorAction SilentlyContinue).Count
if ($lines -gt 1000 -and $null -eq $offset) {
    [Console]::Error.WriteLine(@"
BLOCKED: Read of large file without offset.

File: $file_path
Size: $lines lines

Reading this in full would cost significant context budget.
Use one of these approaches instead:
  1. Grep with -n to find the target symbol, then Read with offset/limit
  2. Bash 'head -50' or 'wc -l' to scan structure first
  3. Call scripts/read-symbol.sh or scripts/read-section.sh if available
  4. If the full file is genuinely needed, pass offset=1 and limit=$lines
     explicitly — this acknowledges the context cost
"@)
    exit 2
}

exit 0
