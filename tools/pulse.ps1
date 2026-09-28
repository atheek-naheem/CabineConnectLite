# pulse.ps1 - report process progress ("pulses") to ai-hub.
#
# Usage:
#   tools/pulse.ps1 <stage> started [--dry-run]
#   tools/pulse.ps1 <stage> completed --gate <passed|failed> [--count name=number ...] [--dry-run]
#   tools/pulse.ps1 status
#
# If script execution is blocked on Windows, run:
#   powershell -ExecutionPolicy Bypass -File tools\pulse.ps1 <arguments>
#
# Stages: requirements-elaboration design development review quality handoff
#
# Configuration:
#   tools/pulse.config  committed, no secrets (host, agent actor, node and activity IDs)
#   .env                never committed (AIHUB_TEAM_KEY, AIHUB_ACTOR)
#   Environment variables override values from both files.
#
# Exit codes: 0 on success AND on any network/ai-hub/setup failure (never blocks
# the team); 2 on usage errors (bad stage, missing gate, invalid count).
#
# Uses only built-in cmdlets. Works on Windows PowerShell 5.1 and PowerShell 7.

$ErrorActionPreference = 'Continue'
Set-StrictMode -Version 2.0

$Stages = @('requirements-elaboration', 'design', 'development', 'review', 'quality', 'handoff')
$CountSuffixes = @('_count', '_passed', '_failed', '_fixed', '_completed', '_traced')
$TimeoutSeconds = 5

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = (Resolve-Path (Join-Path $ScriptDir '..')).Path
$ConfigFile = Join-Path $ScriptDir 'pulse.config'
$EnvFile = Join-Path $Root '.env'
$StateDir = Join-Path $Root '.pulse'
$LogFile = Join-Path $Root 'pulses.log'
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

# ---------------------------------------------------------------- helpers ---

function Write-Warn([string]$Message) { [Console]::Error.WriteLine("pulse: warning: $Message") }
function Write-Info([string]$Message) { [Console]::Error.WriteLine("pulse: $Message") }

function Show-Usage {
    [Console]::Error.WriteLine(@'
Usage:
  tools/pulse.ps1 <stage> started [--dry-run]
  tools/pulse.ps1 <stage> completed --gate <passed|failed> [--count name=number ...] [--dry-run]
  tools/pulse.ps1 status

Stages: requirements-elaboration design development review quality handoff
'@)
}

function Stop-Usage([string]$Message) {
    [Console]::Error.WriteLine("pulse: error: $Message")
    Show-Usage
    exit 2
}

function ConvertTo-CompactJson($Value) {
    return (ConvertTo-Json -InputObject $Value -Compress -Depth 10)
}

function Get-Timestamp { return (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss'Z'") }

function New-Uuid { return [guid]::NewGuid().ToString() }

# Load KEY=VALUE lines from a file into a hashtable (no code execution).
function Read-KeyValueFile([string]$Path, [hashtable]$Target) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    foreach ($raw in [System.IO.File]::ReadAllLines($Path)) {
        $line = $raw.TrimEnd("`r")
        if ($line -eq '' -or $line.StartsWith('#') -or -not $line.Contains('=')) { continue }
        $idx = $line.IndexOf('=')
        $key = $line.Substring(0, $idx)
        $value = $line.Substring($idx + 1)
        if ($key.StartsWith('export ')) { $key = $key.Substring(7) }
        $key = $key -replace '[ \t]', ''
        if ($key -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { continue }
        $value = $value.Trim()
        if ($value.Length -ge 2) {
            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
        }
        $Target[$key] = $value
    }
}

# Value lookup: environment variable first, then .env / pulse.config.
function Get-Setting([string]$Key) {
    $envValue = [Environment]::GetEnvironmentVariable($Key)
    if (-not [string]::IsNullOrEmpty($envValue)) { return $envValue }
    if ($script:Config.ContainsKey($Key)) { return [string]$script:Config[$Key] }
    return ''
}

function Test-Placeholder([string]$Value) {
    if ([string]::IsNullOrEmpty($Value)) { return $true }
    if ($Value -clike '*FILL_ME*' -or $Value -like '*your_*') { return $true }
    if ($Value.StartsWith('<') -and $Value.EndsWith('>')) { return $true }
    return $false
}

# Read pulses.log as objects, skipping unreadable lines.
function Read-PulseLog {
    $entries = @()
    if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) { return ,$entries }
    foreach ($line in [System.IO.File]::ReadAllLines($LogFile)) {
        if ($line.Trim() -eq '') { continue }
        try { $entries += ,(ConvertFrom-Json -InputObject $line) } catch { }
    }
    return ,$entries
}

function Get-Prop($Object, [string]$Name) {
    if ($null -eq $Object) { return $null }
    $p = $Object.PSObject.Properties[$Name]
    if ($null -eq $p) { return $null }
    return $p.Value
}

function Get-Dim($Entry, [string]$Name) { return (Get-Prop (Get-Prop (Get-Prop $Entry 'payload') 'dimensions') $Name) }

# Count logged "started" pulses for a stage (sent and failed; dry-runs excluded).
function Get-StartedCount([object[]]$Entries, [string]$Stage) {
    $n = 0
    foreach ($e in $Entries) {
        if ((Get-Dim $e 'stage') -eq $Stage -and (Get-Dim $e 'event') -eq 'started' -and (Get-Prop $e 'result') -ne 'dry-run') { $n++ }
    }
    return $n
}

function Add-LogEntry([string]$Result, $HttpStatus, [string]$Url, $Payload, [string]$Message) {
    $entry = [ordered]@{
        timestamp   = Get-Timestamp
        result      = $Result
        http_status = $HttpStatus
        url         = $Url
        message     = $Message
        payload     = $Payload
    }
    try {
        [System.IO.File]::AppendAllText($LogFile, (ConvertTo-CompactJson $entry) + "`n", $Utf8NoBom)
    } catch {
        Write-Warn 'could not write to pulses.log'
    }
}

# ----------------------------------------------------------------- status ---

function Show-Status {
    if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
        Write-Info 'no pulses.log yet - no pulses have been sent.'
        return
    }
    $entries = Read-PulseLog
    $fmt = '{0,-12} {1,-10} {2,-8} {3,-10} {4,-7} {5}'
    Write-Output ($fmt -f 'STAGE', 'ITERATIONS', 'STARTED', 'COMPLETED', 'GATE', 'SENT')
    foreach ($stage in $Stages) {
        $real = @($entries | Where-Object { (Get-Dim $_ 'stage') -eq $stage -and (Get-Prop $_ 'result') -ne 'dry-run' })
        $latest = 0
        foreach ($e in $real) {
            $it = Get-Dim $e 'iteration'
            if ($null -ne $it -and [int]$it -gt $latest) { $latest = [int]$it }
        }
        if ($latest -eq 0) {
            Write-Output ($fmt -f $stage, 0, '-', '-', '-', '-')
            continue
        }
        $started = 'no'; $completed = 'no'; $gate = '-'; $sent = 'yes'
        foreach ($e in $real) {
            if ([int](Get-Dim $e 'iteration') -ne $latest) { continue }
            $ev = Get-Dim $e 'event'
            if ($ev -eq 'started') { $started = 'yes' }
            if ($ev -eq 'completed') {
                $completed = 'yes'
                $g = Get-Dim $e 'gate_passed'
                if ($g -eq $true) { $gate = 'passed' } elseif ($g -eq $false) { $gate = 'failed' }
            }
            if ((Get-Prop $e 'result') -ne 'sent') { $sent = 'no' }
        }
        Write-Output ($fmt -f $stage, (Get-StartedCount $entries $stage), $started, $completed, $gate, $sent)
    }
    Write-Output ''
    Write-Output '(ITERATIONS counts started pulses; STARTED/COMPLETED/GATE/SENT describe the latest iteration. Dry-runs are ignored.)'
}

# ------------------------------------------------------------------- main ---

$argv = @($args)
if ($argv.Count -lt 1) { Stop-Usage 'missing arguments' }

switch -CaseSensitive ([string]$argv[0]) {
    'status' {
        if ($argv.Count -ne 1) { Stop-Usage 'status takes no arguments' }
        Show-Status
        exit 0
    }
    { $_ -in @('-h', '--help', 'help') } { Show-Usage; exit 0 }
}

$stage = [string]$argv[0]
if ($Stages -cnotcontains $stage) { Stop-Usage "unknown stage '$stage' (allowed: $($Stages -join ' '))" }
if ($argv.Count -lt 2) { Stop-Usage 'missing event (started or completed)' }
$pulseEvent = [string]$argv[1]
if (@('started', 'completed') -cnotcontains $pulseEvent) { Stop-Usage "unknown event '$pulseEvent' (allowed: started, completed)" }

$dryRun = $false
$gate = ''
$counts = [ordered]@{}
$i = 2
while ($i -lt $argv.Count) {
    $arg = [string]$argv[$i]
    if ($arg -ceq '--dry-run') {
        $dryRun = $true
    } elseif ($arg -ceq '--gate' -or $arg.StartsWith('--gate=')) {
        if ($arg -ceq '--gate') {
            if ($i + 1 -ge $argv.Count) { Stop-Usage '--gate needs a value (passed or failed)' }
            $i++; $gate = [string]$argv[$i]
        } else {
            $gate = $arg.Substring(7)
        }
        if (@('passed', 'failed') -cnotcontains $gate) { Stop-Usage "--gate must be 'passed' or 'failed' (got '$gate')" }
    } elseif ($arg -ceq '--count' -or $arg.StartsWith('--count=')) {
        if ($arg -ceq '--count') {
            if ($i + 1 -ge $argv.Count) { Stop-Usage '--count needs name=number' }
            $i++; $value = [string]$argv[$i]
        } else {
            $value = $arg.Substring(8)
        }
        if (-not $value.Contains('=')) { Stop-Usage "--count must be name=number (got '$value')" }
        $name = $value.Substring(0, $value.IndexOf('='))
        $number = $value.Substring($value.IndexOf('=') + 1)
        if ($name -cnotmatch '^[a-z][a-z0-9]*(_[a-z0-9]+)*$') { Stop-Usage "count name '$name' must be lowercase snake_case (e.g. open_questions)" }
        if ($number -notmatch '^[0-9]+$') { Stop-Usage "count '$name' must be a non-negative integer (got '$number')" }
        if ($number.Length -gt 15) { Stop-Usage "count '$name' is too large" }
        $full = "${name}_count"
        foreach ($suffix in $CountSuffixes) { if ($name.EndsWith($suffix)) { $full = $name } }
        if ($counts.Contains($full)) { Stop-Usage "count '$full' given more than once" }
        $counts[$full] = [int64]$number
    } else {
        Stop-Usage "unknown option '$arg'"
    }
    $i++
}

if ($pulseEvent -eq 'started') {
    if ($gate -ne '') { Stop-Usage "--gate is only valid with 'completed'" }
    if ($counts.Count -gt 0) { Stop-Usage "--count is only valid with 'completed'" }
} elseif ($gate -eq '') {
    Stop-Usage "'completed' requires --gate passed|failed"
}

# --- configuration ---
$script:Config = @{}
Read-KeyValueFile $ConfigFile $script:Config
Read-KeyValueFile $EnvFile $script:Config

$stageUp = $stage.ToUpperInvariant().Replace('-', '_')
$eventUp = $pulseEvent.ToUpperInvariant()
$aihubHost = (Get-Setting 'AIHUB_HOST').TrimEnd('/')
$agent = Get-Setting 'AGENT_ACTOR'
$actor = Get-Setting 'AIHUB_ACTOR'
$key = Get-Setting 'AIHUB_TEAM_KEY'
$node = Get-Setting "${stageUp}_NODE"
$activity = Get-Setting "${stageUp}_${eventUp}"
$expectedActivity = "stage-$pulseEvent"

$problems = @()
if (-not (Test-Path -LiteralPath $EnvFile -PathType Leaf) -and [string]::IsNullOrEmpty($env:AIHUB_TEAM_KEY)) {
    $problems += '.env not found: copy .env.example to .env and fill it in'
}
if (Test-Placeholder $key) { $problems += 'AIHUB_TEAM_KEY is missing or a placeholder (set it in .env)' }
if (Test-Placeholder $actor) { $problems += 'AIHUB_ACTOR is missing or a placeholder (set your registered email in .env)' }
if (Test-Placeholder $aihubHost) { $problems += 'AIHUB_HOST is missing in tools/pulse.config' }
if (Test-Placeholder $agent) { $problems += 'AGENT_ACTOR is missing in tools/pulse.config' }
if (Test-Placeholder $node) { $problems += "${stageUp}_NODE is missing or a placeholder in tools/pulse.config (ask the organizer)" }
if (Test-Placeholder $activity) { $problems += "${stageUp}_${eventUp} is missing or a placeholder in tools/pulse.config (ask the organizer)" }
$problemText = ($problems | ForEach-Object { "`n  - $_" }) -join ''

# --- correlation ID and iteration ---
# .pulse/<stage>.cid holds two lines, written at 'started' and reused at
# 'completed': the correlation ID and the iteration number.
$cidFile = Join-Path $StateDir "$stage.cid"
$cid = ''
$iteration = 0
if ($pulseEvent -eq 'started') {
    if ((Test-Path -LiteralPath $cidFile) -and -not $dryRun) {
        Write-Warn "'$stage' was already started and not completed; starting a new iteration."
    }
    $cid = New-Uuid
    $iteration = (Get-StartedCount (Read-PulseLog) $stage) + 1
} else {
    if (Test-Path -LiteralPath $cidFile) {
        $state = @([System.IO.File]::ReadAllLines($cidFile))
        if ($state.Count -ge 1) { $cid = $state[0].Trim() }
        if ($state.Count -ge 2 -and $state[1].Trim() -match '^[0-9]+$') { $iteration = [int]$state[1].Trim() }
    }
    if ($cid -eq '') {
        Write-Warn "no matching 'started' pulse found for '$stage'; using a new correlation ID."
        $cid = New-Uuid
    }
    if ($iteration -lt 1) {
        $iteration = Get-StartedCount (Read-PulseLog) $stage
        if ($iteration -lt 1) { $iteration = 1 }
    }
}

# --- commit ---
$commit = 'unknown'
$git = Get-Command git -ErrorAction SilentlyContinue
$inRepo = $false
if ($null -ne $git) {
    $null = & git -C $Root rev-parse --git-dir 2>$null
    $inRepo = ($LASTEXITCODE -eq 0)
}
if ($inRepo) {
    $head = & git -C $Root rev-parse --short HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $head) { $commit = ([string]$head).Trim() }
    if ($pulseEvent -eq 'completed') {
        $dirty = & git -C $Root status --porcelain -- . ':(exclude)pulses.log' 2>$null
        if ($dirty) { Write-Warn 'working tree has uncommitted changes; commit the stage artifact before ''completed''.' }
    }
} else {
    Write-Warn "not a git repository (or git not installed); commit reported as 'unknown'."
}

# --- payload ---
$dimensions = [ordered]@{
    stage     = $stage
    event     = $pulseEvent
    iteration = [int]$iteration
    commit    = $commit
}
if ($pulseEvent -eq 'completed') { $dimensions['gate_passed'] = ($gate -eq 'passed') }
foreach ($k in $counts.Keys) { $dimensions[$k] = $counts[$k] }
$payload = [ordered]@{
    eventId       = New-Uuid
    correlationId = $cid
    actors        = @($actor, $agent)
    dimensions    = $dimensions
}
$payloadJson = ConvertTo-CompactJson $payload
$url = "$aihubHost/metrics/nodes/$node/node-activities/$activity/events"

# --- dry run ---
if ($dryRun) {
    Write-Output 'DRY RUN - nothing sent.'
    Write-Output "POST $url"
    Write-Output $payloadJson
    Write-Output ''
    if ($problems.Count -gt 0) {
        Write-Output "Setup is NOT complete:$problemText"
    } else {
        Write-Output 'Setup looks complete (key and actor present; key not shown).'
    }
    Add-LogEntry 'dry-run' $null $url $payload 'dry run'
    exit 0
}

# Update correlation state now so a failed send does not break the pairing.
try {
    if ($pulseEvent -eq 'started') {
        if (-not (Test-Path -LiteralPath $StateDir)) { $null = New-Item -ItemType Directory -Path $StateDir }
        [System.IO.File]::WriteAllText($cidFile, "$cid`n$iteration`n", $Utf8NoBom)
    } elseif (Test-Path -LiteralPath $cidFile) {
        Remove-Item -LiteralPath $cidFile -Force
    }
} catch {
    Write-Warn "could not update $cidFile"
}

# --- setup problems: log as failed, never block ---
if ($problems.Count -gt 0) {
    Write-Warn "pulse NOT sent - setup is incomplete:$problemText"
    Add-LogEntry 'failed' $null $url $payload 'setup incomplete'
    exit 0
}

# --- send ---
try {
    # Windows PowerShell 5.1 may not enable TLS 1.2 by default.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch { }

$status = $null
$body = ''
$networkError = ''
try {
    $response = Invoke-WebRequest -Uri $url -Method Post -UseBasicParsing `
        -Headers @{ Authorization = "Bearer $key" } `
        -ContentType 'application/json' `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) `
        -TimeoutSec $TimeoutSeconds -ErrorAction Stop
    $status = [int]$response.StatusCode
    $content = $response.Content
    if ($content -is [byte[]]) { $content = [System.Text.Encoding]::UTF8.GetString($content) }
    $body = [string]$content
} catch {
    $resp = $null
    try { $resp = $_.Exception.Response } catch { }
    if ($null -ne $resp) {
        try { $status = [int]$resp.StatusCode } catch { }
    }
    if ($null -eq $status) { $networkError = $_.Exception.Message }
}

if ($null -eq $status) {
    Write-Warn "could not reach ai-hub ($networkError); pulse NOT sent. Carry on - it is logged in pulses.log."
    Add-LogEntry 'failed' $null $url $payload "network error: $networkError"
    exit 0
}

if ($status -ne 202) {
    Write-Warn "ai-hub answered HTTP $status (expected 202); pulse NOT accepted. Carry on - it is logged in pulses.log."
    Add-LogEntry 'failed' $status $url $payload 'unexpected HTTP status'
    exit 0
}

$message = 'accepted'
$gotActivity = ''
$accepted = $null
try {
    $parsed = ConvertFrom-Json -InputObject $body
    $gotActivity = [string](Get-Prop $parsed 'activity')
    $accepted = Get-Prop $parsed 'accepted'
} catch { }
if ($gotActivity -ne $expectedActivity) {
    Write-Warn "ai-hub recorded activity '$gotActivity' but '$expectedActivity' was expected; check ${stageUp}_${eventUp} in tools/pulse.config."
    $message = "activity mismatch: got '$gotActivity'"
}
if ($null -ne $accepted -and [int]$accepted -eq 0) {
    Write-Warn 'ai-hub accepted 0 events (filtered); tell the organizer.'
    $message = "$message; accepted 0"
}
Add-LogEntry 'sent' 202 $url $payload $message
Write-Info "$stage $pulseEvent pulse sent (iteration $iteration)."
exit 0
