#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Wrapper Windows/PowerShell do sync portátil do PelizzAI.

.DESCRIPTION
  A implementação canônica vive em scripts/sync-harness.mjs e requer Node.js 18+.
  Este wrapper preserva a interface PowerShell histórica sem duplicar a lógica.

.EXAMPLE
  pwsh scripts/sync-harness.ps1
  pwsh scripts/sync-harness.ps1 -Check -SourceMode
  pwsh scripts/sync-harness.ps1 -UpdateManifest
  pwsh scripts/sync-harness.ps1 -ExportConsumer C:\projetos\meu-app
  pwsh scripts/sync-harness.ps1 -ExportConsumer C:\projetos\meu-app -InstallHooks
#>
param(
    [switch]$Check,
    [switch]$UpdateManifest,
    [switch]$SourceMode,
    [string]$ExportConsumer,
    [switch]$InstallHooks
)

$ErrorActionPreference = 'Stop'
$arguments = @()
if ($Check) { $arguments += '--check' }
if ($UpdateManifest) { $arguments += '--update-manifest' }
if ($SourceMode) { $arguments += '--source-mode' }
if ($ExportConsumer) { $arguments += @('--export-consumer', $ExportConsumer) }
if ($InstallHooks) { $arguments += '--install-hooks' }

& node (Join-Path $PSScriptRoot 'sync-harness.mjs') @arguments
exit $LASTEXITCODE
