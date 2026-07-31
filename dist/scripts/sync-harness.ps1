#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Windows/PowerShell wrapper for the portable PelizzAI sync.

.DESCRIPTION
  The canonical implementation lives in scripts/sync-harness.mjs and requires Node.js 18+.
  This wrapper preserves the historical PowerShell interface without duplicating the logic.

.EXAMPLE
  pwsh scripts/sync-harness.ps1
  pwsh scripts/sync-harness.ps1 -Check -SourceMode
  pwsh scripts/sync-harness.ps1 -UpdateManifest
  pwsh scripts/sync-harness.ps1 -ExportConsumer C:\projetos\my-app
  pwsh scripts/sync-harness.ps1 -ExportConsumer C:\projetos\my-app -InstallHooks
  pwsh scripts/sync-harness.ps1 -BuildDist
#>
param(
    [switch]$Check,
    [switch]$UpdateManifest,
    [switch]$SourceMode,
    [string]$ExportConsumer,
    [switch]$InstallHooks,
    [switch]$BuildDist
)

$ErrorActionPreference = 'Stop'
$arguments = @()
if ($Check) { $arguments += '--check' }
if ($UpdateManifest) { $arguments += '--update-manifest' }
if ($SourceMode) { $arguments += '--source-mode' }
if ($ExportConsumer) { $arguments += @('--export-consumer', $ExportConsumer) }
if ($InstallHooks) { $arguments += '--install-hooks' }
if ($BuildDist) { $arguments += '--build-dist' }

& node (Join-Path $PSScriptRoot 'sync-harness.mjs') @arguments
exit $LASTEXITCODE
