#!/usr/bin/env pwsh
#Requires -Version 7.0
# Stop the brainstorm server and clean up (PowerShell counterpart of stop-server.sh)
# Usage: stop-server.ps1 <session_dir>
#
# Kills the server process. Only deletes the session directory if it's
# under the temp dir (ephemeral). Persistent directories (.dumont/) are
# kept so mockups can be reviewed later.
param([string]$SessionDir = '')

if (-not $SessionDir) {
    Write-Output '{"error": "Usage: stop-server.ps1 <session_dir>"}'
    exit 1
}

$stateDir = Join-Path $SessionDir 'state'
$pidFile  = Join-Path $stateDir 'server.pid'

if (-not (Test-Path $pidFile)) {
    Write-Output '{"status": "not_running"}'
    exit 0
}

$serverPid = Get-Content $pidFile

# Try to stop gracefully, escalate to -Force if still alive
try { Stop-Process -Id $serverPid -ErrorAction Stop } catch {}

for ($i = 0; $i -lt 20; $i++) {
    if (-not (Get-Process -Id $serverPid -ErrorAction SilentlyContinue)) { break }
    Start-Sleep -Milliseconds 100
}

if (Get-Process -Id $serverPid -ErrorAction SilentlyContinue) {
    try { Stop-Process -Id $serverPid -Force -ErrorAction Stop } catch {}
    Start-Sleep -Milliseconds 100
}

if (Get-Process -Id $serverPid -ErrorAction SilentlyContinue) {
    Write-Output '{"status": "failed", "error": "process still running"}'
    exit 1
}

Remove-Item $pidFile, (Join-Path $stateDir 'server.log'), (Join-Path $stateDir 'server.err.log') -Force -ErrorAction SilentlyContinue

# Only delete ephemeral temp-dir sessions. Trailing separator prevents a
# sibling like C:\Tempest matching the C:\Temp prefix.
$tempRoot = [System.IO.Path]::GetTempPath().TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
if (([System.IO.Path]::GetFullPath($SessionDir)).StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    Remove-Item $SessionDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output '{"status": "stopped"}'
