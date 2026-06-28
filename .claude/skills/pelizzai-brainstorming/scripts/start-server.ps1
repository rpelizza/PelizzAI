#!/usr/bin/env pwsh
#Requires -Version 7.0
# Start the brainstorm server and output connection info (PowerShell counterpart of start-server.sh)
# Usage: start-server.ps1 [-ProjectDir <path>] [-BindHost <bind-host>] [-UrlHost <display-host>] [-Foreground] [-Background]
#
# Starts server on a random high port, outputs JSON with URL.
# Each session gets its own directory to avoid conflicts.
#
# Options:
#   -ProjectDir <path>  Store session files under <path>/.dumont/brainstorm/
#                       instead of the temp dir. Files persist after server stops.
#   -BindHost <host>    Host/interface to bind (default: 127.0.0.1).
#                       Use 0.0.0.0 in remote/containerized environments.
#   -UrlHost <host>     Hostname shown in returned URL JSON.
#   -Foreground         Run server in the current terminal (no backgrounding).
#   -Background         Force background mode.
param(
    [string]$ProjectDir = '',
    [string]$BindHost = '127.0.0.1',
    [string]$UrlHost = '',
    [switch]$Foreground,
    [switch]$Background
)

$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot

if (-not $UrlHost) {
    $UrlHost = if ($BindHost -in '127.0.0.1', 'localhost') { 'localhost' } else { $BindHost }
}

# Unique session directory
$sessionId = "$PID-$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
$sessionDir = if ($ProjectDir) {
    Join-Path $ProjectDir ".dumont/brainstorm/$sessionId"
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

# Resolve the harness PID (parent of this pwsh). Same role as the grandparent
# lookup in start-server.sh: the server auto-exits when this owner dies.
$ownerPid = $PID
try {
    $parent = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID" -ErrorAction Stop).ParentProcessId
    if ($parent -and (Get-Process -Id $parent -ErrorAction SilentlyContinue)) { $ownerPid = $parent }
} catch {}

$env:BRAINSTORM_DIR       = $sessionDir
$env:BRAINSTORM_HOST      = $BindHost
$env:BRAINSTORM_URL_HOST  = $UrlHost
$env:BRAINSTORM_OWNER_PID = "$ownerPid"

# Foreground mode for environments that reap detached processes.
if ($Foreground -and -not $Background) {
    Set-Content -Path $pidFile -Value $PID
    node server.cjs
    exit $LASTEXITCODE
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
            $retry = "$scriptDir\start-server.ps1$(if ($ProjectDir) { " -ProjectDir $ProjectDir" }) -BindHost $BindHost -UrlHost $UrlHost -Foreground"
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
