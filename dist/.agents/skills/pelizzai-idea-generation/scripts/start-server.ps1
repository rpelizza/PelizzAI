#!/usr/bin/env pwsh
#Requires -Version 7.0
# Start the brainstorm server and output connection info (PowerShell counterpart of start-server.sh)
# Usage: start-server.ps1 [-ProjectDir <path>] [-BindHost <bind-host>] [-UrlHost <display-host>] [-Open] [-AllowInsecureNetwork] [-IdleTimeoutMinutes <n>] [-Foreground|-Background]
#
# Starts server on a random high port, outputs JSON with URL.
# Each session gets its own directory to avoid conflicts.
#
# Options:
#   -ProjectDir <path>  Store session files under <path>/pelizzai/data/mockups/
#                       instead of the temp dir. Files persist after server stops.
#   -BindHost <host>    Host/interface to bind (default: 127.0.0.1).
#                       Non-loopback binds also require -AllowInsecureNetwork.
#   -AllowInsecureNetwork  Accept that the session key and events cross the network
#                       unencrypted (http/ws) on a non-loopback bind. Prefer a TLS proxy.
#   -UrlHost <host>     Hostname shown in returned URL JSON.
#   -Open               Open the authenticated URL in the default browser.
#   -IdleTimeoutMinutes Stop after N idle minutes (default: 240).
#   -Foreground         Run server in the current terminal (no backgrounding).
#   -Background         Force background mode.
#   -Help               Show usage and exit.
param(
    [string]$ProjectDir = '',
    [string]$BindHost = '127.0.0.1',
    [string]$UrlHost = '',
    [switch]$Open,
    [switch]$AllowInsecureNetwork,
    [ValidateRange(1, 10080)][int]$IdleTimeoutMinutes = 240,
    [switch]$Foreground,
    [switch]$Background,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot

if ($Help) {
    Get-Content -LiteralPath $PSCommandPath | Select-Object -First 21
    exit 0
}

if (-not $UrlHost) {
    $UrlHost = if ($BindHost -in '127.0.0.1', 'localhost') { 'localhost' } else { $BindHost }
}

# Unique session directory
$sessionId = "$PID-$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
$sessionDir = if ($ProjectDir) {
    Join-Path $ProjectDir "pelizzai/data/mockups/$sessionId"
} else {
    Join-Path ([System.IO.Path]::GetTempPath()) "brainstorm-$sessionId"
}
$stateDir = Join-Path $sessionDir 'state'
$pidFile  = Join-Path $stateDir 'server.pid'
$logFile  = Join-Path $stateDir 'server.log'
$errFile  = Join-Path $stateDir 'server.err.log'

New-Item -ItemType Directory -Force (Join-Path $sessionDir 'content'), $stateDir | Out-Null

# Kill any existing server for this session dir
if (Test-Path $pidFile) {
    $oldPid = Get-Content $pidFile
    try { Stop-Process -Id $oldPid -Force -ErrorAction Stop } catch {}
    Remove-Item $pidFile -Force
}

Set-Location $scriptDir

# Resolve the harness PID (GRANDPARENT of this pwsh — parity with start-server.sh, where the
# owner is the parent of the shell running the script). The direct parent is often an ephemeral
# shell the agent spawned just to run this launcher: it dies when the script exits, and the
# server would shut down on the next lifecycle check, killing the session early. Fallback
# chain: grandparent alive → grandparent; else parent alive → parent; else this PID.
$ownerPid = $PID
try {
    $parent = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID" -ErrorAction Stop).ParentProcessId
    if ($parent -and (Get-Process -Id $parent -ErrorAction SilentlyContinue)) {
        $ownerPid = $parent
        $grand = (Get-CimInstance Win32_Process -Filter "ProcessId=$parent" -ErrorAction Stop).ParentProcessId
        if ($grand -and $grand -gt 4 -and (Get-Process -Id $grand -ErrorAction SilentlyContinue)) { $ownerPid = $grand }
    }
} catch {}

$env:BRAINSTORM_DIR       = $sessionDir
$env:BRAINSTORM_HOST      = $BindHost
$env:BRAINSTORM_URL_HOST  = $UrlHost
$env:BRAINSTORM_OWNER_PID = "$ownerPid"
$env:BRAINSTORM_OPEN      = if ($Open) { 'true' } else { 'false' }
$env:BRAINSTORM_ALLOW_INSECURE_NETWORK = if ($AllowInsecureNetwork) { 'true' } else { 'false' }
$env:BRAINSTORM_IDLE_TIMEOUT_MINUTES = "$IdleTimeoutMinutes"

# Foreground mode for environments that reap detached processes.
if ($Foreground -and -not $Background) {
    $proc = Start-Process node -ArgumentList 'server.cjs' -NoNewWindow -PassThru
    Set-Content -Path $pidFile -Value $proc.Id
    $proc.WaitForExit()
    exit $proc.ExitCode
}

# Background: detached node process; child inherits the BRAINSTORM_* environment.
$proc = Start-Process node -ArgumentList 'server.cjs' -WindowStyle Hidden -PassThru `
    -RedirectStandardOutput $logFile -RedirectStandardError $errFile
Set-Content -Path $pidFile -Value $proc.Id

# Wait for the server-started message (up to ~5s)
for ($i = 0; $i -lt 50; $i++) {
    if ((Test-Path $logFile) -and (Select-String -Path $logFile -Pattern 'server-started' -Quiet)) {
        # Verify the server survives a short window (catches process reapers)
        $alive = $true
        for ($j = 0; $j -lt 20; $j++) {
            if (-not (Get-Process -Id $proc.Id -ErrorAction SilentlyContinue)) { $alive = $false; break }
            Start-Sleep -Milliseconds 100
        }
        if (-not $alive) {
            $retry = "$scriptDir\start-server.ps1$(if ($ProjectDir) { " -ProjectDir $ProjectDir" }) -BindHost $BindHost -UrlHost $UrlHost -IdleTimeoutMinutes $IdleTimeoutMinutes -Foreground"
            Write-Output "{`"error`": `"Server started but was killed. Retry in a persistent terminal with: $retry`"}"
            exit 1
        }
        (Select-String -Path $logFile -Pattern 'server-started' | Select-Object -First 1).Line
        exit 0
    }
    Start-Sleep -Milliseconds 100
}

Write-Output '{"error": "Server failed to start within 5 seconds"}'
exit 1
