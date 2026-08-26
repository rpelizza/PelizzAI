#!/usr/bin/env pwsh
# PelizzAI - review-package: packages the review material into a file.
#
# Usage: pwsh scripts/review-package.ps1 <BASE> <HEAD>
#        pwsh scripts/review-package.ps1 --working-tree
#
# Writes to the safe handoff dir (gitignored in the consumer; temp in source mode):
#  - range mode: the range's commit list, the `git diff --stat` and the `git diff -U10`;
#  - --working-tree mode: status + staged and unstaged diffs + the CONTENT of untracked files.
# Prints the written path. The reviewer reads the FILE - the diff is never pasted into
# the coordinator's context.
#
# Blocks use a 4-backtick fence: diffs of .md files contain ``` and would break
# a 3-backtick fence.
#
# IMPORTANT - range is exclusive to the final review. BASE is the `base-sha` persisted in
# the state when the branch was created. Per-task review uses --working-tree. NEVER use
# HEAD~1: that would silently discard part of the delivery.
#
# Requires PowerShell 7+. POSIX variant: scripts/review-package.sh.

# No param() block: "--working-tree" would be interpreted by the PowerShell binder
# as a parameter name. The arguments arrive raw in $args.
$Base = if ($args.Count -ge 1) { [string]$args[0] } else { '' }
$Head = if ($args.Count -ge 2) { [string]$args[1] } else { '' }

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

function Fail([string]$Message) {
  [Console]::Error.WriteLine("review-package: $Message")
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
  return (Join-Path ([IO.Path]::GetTempPath()) "pelizzai-continuitys/$hash")
}

git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { Fail 'not a git repository (run from the project root)' }

$workingTree = ($Base -eq '--working-tree')
if (-not $workingTree) {
  if (-not $Base -or -not $Head) { Fail 'usage: review-package.ps1 <BASE> <HEAD> | review-package.ps1 --working-tree' }
  git rev-parse --verify --quiet "$Base^{commit}" *> $null
  if ($LASTEXITCODE -ne 0) { Fail "invalid BASE: $Base" }
  git rev-parse --verify --quiet "$Head^{commit}" *> $null
  if ($LASTEXITCODE -ne 0) { Fail "invalid HEAD: $Head" }
}

$outDir = Get-HandoffDir
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$stem = Join-Path $outDir "review-$stamp-$PID"
$outPath = "$stem.md"
$collision = 0
while (Test-Path -LiteralPath $outPath) {
  $collision++
  $outPath = "$stem-$collision.md"
}
$now = Get-Date -Format 'yyyy-MM-dd HH:mm'

function Add-Block([System.Collections.Generic.List[string]]$List, [string]$Title, [string]$Fence, $Body) {
  $List.Add("## $Title")
  $List.Add('')
  $List.Add('````' + $Fence)
  foreach ($l in @($Body)) { if ($null -ne $l) { $List.Add([string]$l) } }
  $List.Add('````')
  $List.Add('')
}

function Test-SensitiveUntracked([string]$Path) {
  $leaf = [IO.Path]::GetFileName($Path).ToLowerInvariant()
  if ($leaf -in @('.env.example', '.env.sample', '.env.template')) { return $false }
  if ($leaf -eq '.env' -or $leaf.StartsWith('.env.')) { return $true }
  if ($leaf -in @('.npmrc', '.pypirc', '.netrc', 'credentials.json', 'id_rsa', 'id_ed25519')) { return $true }
  if ($leaf -match '^(secret|secrets)\.(json|ya?ml|toml|ini)$') { return $true }
  return ([IO.Path]::GetExtension($leaf) -in @('.pem', '.key', '.p12', '.pfx'))
}

$content = [System.Collections.Generic.List[string]]::new()
if ($workingTree) {
  $content.Add('# Review package - working tree')
  $content.Add('')
  $content.Add("> Generated at $now. Working-tree changes not yet committed.")
  $content.Add('')
  Add-Block $content 'git status --short' 'text' (git status --short)
  Add-Block $content 'Staged - git diff --cached -U10' 'diff' (git diff --cached -U10)
  Add-Block $content 'Unstaged - git diff -U10' 'diff' (git diff -U10)
  $content.Add('## New files (untracked) - content')
  $content.Add('')
  # Excludes the handoff directory itself (the package being written does not go into the package).
  $untracked = @(git ls-files --others --exclude-standard | Where-Object { $_ -notlike 'pelizzai/data/handoffs/*' })
  if ($untracked.Count -gt 0) {
    foreach ($f in $untracked) {
      $content.Add("### $f")
      $content.Add('')
      $item = $null
      try { $item = Get-Item -LiteralPath $f -Force -ErrorAction Stop } catch {}
      if ($item -and $item.LinkType) {
        $content.Add('_symbolic link — content omitted to avoid reading outside the repository._')
        $content.Add('')
        continue
      }
      if (Test-SensitiveUntracked $f) {
        $content.Add('_potentially sensitive file — content omitted; review the path locally._')
        $content.Add('')
        continue
      }
      if ($item -and $item.Length -gt 262144) {
        $content.Add("_file larger than 256 KiB ($($item.Length) bytes) — content omitted._")
        $content.Add('')
        continue
      }
      $text = $null
      try { $text = Get-Content -LiteralPath $f -Raw -ErrorAction Stop } catch {}
      if ($null -ne $text -and $text -notmatch "`0") {
        $content.Add('````text')
        foreach ($l in ($text -split "`r?`n")) { $content.Add($l) }
        $content.Add('````')
      } else {
        $content.Add('_binary or unreadable - content omitted._')
      }
      $content.Add('')
    }
  } else {
    $content.Add('_None._')
  }
} else {
  $content.Add("# Review package - $Base..$Head")
  $content.Add('')
  $content.Add("> Generated at $now. Final range: BASE = base-sha persisted in the state - never HEAD~1.")
  $content.Add('')
  Add-Block $content "Commits ($Base..$Head)" 'text' (git log --oneline "$Base..$Head")
  Add-Block $content 'git diff --stat' 'text' (git diff --stat "$Base" "$Head")
  Add-Block $content 'git diff -U10' 'diff' (git diff -U10 "$Base" "$Head")
}

Set-Content -LiteralPath $outPath -Value ($content -join "`n") -Encoding utf8
Write-Output $outPath
