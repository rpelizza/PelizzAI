#!/usr/bin/env pwsh
# PelizzAI - task-brief: file-based handoff of the task briefing.
#
# Usage: pwsh scripts/task-brief.ps1 <plan-path> <N>
#
# Extracts from the plan (pelizzai/plans/*.md) the text of Task N - from the
# "### Task N: ..." header to the next header of the same (or higher) level or EOF -
# PLUS the "Global Constraints" block from the plan header (every task inherits it),
# and writes it to the safe handoff dir: pelizzai/data/handoffs when the bootstrap proved the ignore,
# or the system temp (source mode/project without bootstrap).
# Prints the written path. Fails with a clear message if the plan does not exist
# or the task is not found.
#
# Why a file, not pasting: everything that enters by pasting stays resident in the
# coordinator's context forever (gain measured at the source: ~2x faster,
# ~50% fewer tokens). See pelizzai-execution-plans -> references/task-cycle.md, section 1.
#
# Requires PowerShell 7+. POSIX variant: scripts/task-brief.sh.

[CmdletBinding()]
param(
  [Parameter(Position = 0)][string]$PlanPath,
  [Parameter(Position = 1)][string]$TaskNumber
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

function Fail([string]$Message) {
  [Console]::Error.WriteLine("task-brief: $Message")
  exit 1
}

function Get-HandoffDir {
  if ($env:PELIZZAI_HANDOFF_DIR) { return [IO.Path]::GetFullPath($env:PELIZZAI_HANDOFF_DIR) }
  $projectIgnore = Join-Path (Get-Location).Path 'pelizzai/.gitignore'
  if (Test-Path -LiteralPath $projectIgnore -PathType Leaf) {
    git check-ignore -q -- 'pelizzai/data/handoffs/.pelizzai-probe' 2>$null
    if ($LASTEXITCODE -eq 0) { return (Join-Path (Get-Location).Path 'pelizzai/data/handoffs') }
  }
  $identity = try { (git rev-parse --show-toplevel 2>$null | Select-Object -First 1) } catch { $null }
  if (-not $identity) { $identity = (Get-Location).Path }
  $bytes = [Text.Encoding]::UTF8.GetBytes([string]$identity)
  $sha = [Security.Cryptography.SHA256]::Create()
  try { $digest = $sha.ComputeHash($bytes) } finally { $sha.Dispose() }
  $hash = (-join ($digest | ForEach-Object { $_.ToString('x2') })).Substring(0, 12)
  return (Join-Path ([IO.Path]::GetTempPath()) "pelizzai-handoffs/$hash")
}

if (-not $PlanPath -or -not $TaskNumber) { Fail 'usage: task-brief.ps1 <plan-path> <N>' }
if ($TaskNumber -notmatch '^[0-9]+$') { Fail "invalid N: '$TaskNumber' (expected the task number, e.g. 3)" }
if (-not (Test-Path -LiteralPath $PlanPath -PathType Leaf)) { Fail "plan not found: $PlanPath" }

$lines = Get-Content -LiteralPath $PlanPath

# Global Constraints block from the plan header: from the "**Global Constraints" line to the first '---' or header.
# Lines starting with ``` toggle the code-fence state; headers/separators INSIDE a
# fence (e.g. a shell/python '#' comment at column zero) do not end the block.
$gc = [System.Collections.Generic.List[string]]::new()
$inGc = $false
$inFence = $false
foreach ($line in $lines) {
  if ($line -match '^```') { $inFence = -not $inFence }
  if ($inGc -and -not $inFence -and ($line -match '^---\s*$' -or $line -match '^#')) { break }
  # The marker only opens the block OUTSIDE a code fence and anchored at column zero: a code
  # example quoting `**Global Constraints` before the real block must not start the capture.
  if (-not $inGc -and -not $inFence -and $line -match '^\*\*Global Constraints\b') { $inGc = $true }
  if ($inGc) { $gc.Add($line) }
}

# Task N: from the "### Task N" header to the next header of level <= 3 (OUTSIDE code fences) or EOF.
$task = [System.Collections.Generic.List[string]]::new()
$inTask = $false
$inFence = $false
foreach ($line in $lines) {
  if ($line -match '^```') { $inFence = -not $inFence }
  if (-not $inTask) {
    if (-not $inFence -and $line -match "^###\s+Task\s+$TaskNumber\b") { $inTask = $true; $task.Add($line) }
    continue
  }
  if (-not $inFence -and $line -match '^#{1,3}\s') { break }
  $task.Add($line)
}

if (-not $inTask) { Fail "Task $TaskNumber not found in $PlanPath (expected a header '### Task ${TaskNumber}: ...')" }

$outDir = Get-HandoffDir
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outPath = Join-Path $outDir "task-$TaskNumber-brief.md"

$now = Get-Date -Format 'yyyy-MM-dd HH:mm'
$content = [System.Collections.Generic.List[string]]::new()
$content.Add("# Brief - Task $TaskNumber")
$content.Add('')
$content.Add("> Generated from ``$PlanPath`` at $now. The member reads THIS file - never the whole plan.")
$content.Add('')
$content.Add('## Global Constraints (inherited from the plan header)')
$content.Add('')
if ($gc.Count -gt 0) { foreach ($l in $gc) { $content.Add($l) } }
else { $content.Add('_The plan has no Global Constraints block._') }
$content.Add('')
$content.Add('## Task')
$content.Add('')
foreach ($l in $task) { $content.Add($l) }
$content.Add('')
$content.Add('---')
$content.Add('')
$reportPath = Join-Path $outDir "task-$TaskNumber-report.md"
$content.Add("Report: write the result to ``$reportPath`` (mirroring this brief) and reply in chat in at most 15 lines.")

Set-Content -LiteralPath $outPath -Value ($content -join "`n") -Encoding utf8
Write-Output $outPath
