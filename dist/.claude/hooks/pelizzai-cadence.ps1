#!/usr/bin/env pwsh
# PelizzAI - cadence hook (UserPromptSubmit), PowerShell variant.
#
# Equivalent to pelizzai-cadence.mjs, for fleets without Node. Requires PowerShell 7+ (pwsh)
# - 5.1 corrupts accented UTF-8 output.
#
# Cadence (calibrated for active teams - see pelizzai-skill-lab ->
# references/domain-skill-maintenance.md):
#  - Sampling: checks every 10 interactions (not on every message).
#  - Review due: >= 10 commits OR > 10 days since last-review (the DAYS axis is the sprint
#    anchor; commits only PULL IT FORWARD in a real burst of work).
#  - Full repo-scan: > 15 days since last-full-scan.
#  - Snooze: after nudging, stays silent for 7 days (avoids repeating every window).
#
# Same guarantees as the .mjs: silent no-op without the ledger; the expensive check (git)
# only every N interactions; ALWAYS exits 0 (never blocks the prompt); swallows any error.
#
# Installation (opt-in, at bootstrap), in .claude/settings.json:
#   { "hooks": { "UserPromptSubmit": [ { "hooks": [
#       { "type": "command",
#         "command": "pwsh -NoProfile -File \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-cadence.ps1\"" } ] } ] } }

$ErrorActionPreference = 'SilentlyContinue'
try {
  $EVERY = 10                  # check every N interactions (sampling, not the nudge frequency)
  $COMMIT_THRESHOLD = 10       # >= N commits since the last review (pulls forward in a real burst)
  $DAY_THRESHOLD_REVIEW = 10   # > N days since the last review (sprint anchor)
  $DAY_THRESHOLD_SCAN = 15     # > N days since the last full-scan
  $SNOOZE_DAYS = 7             # after nudging, stay silent for N days

  $raw = [Console]::In.ReadToEnd()
  $cwd = (Get-Location).Path
  if ($raw) { try { $j = $raw | ConvertFrom-Json; if ($j.cwd) { $cwd = $j.cwd } } catch {} }

  $ledger = Join-Path $cwd 'pelizzai/data/review-domain-skills.md'
  if (-not (Test-Path -LiteralPath $ledger)) { exit 0 } # harness not initialized in this project

  # state: interaction counter + snooze window (backward-compatible with { count })
  $statePath = Join-Path $cwd 'pelizzai/data/.cadence-state.json'
  $count = 0
  $snoozeUntil = 0
  if (Test-Path -LiteralPath $statePath) {
    try {
      $st = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
      if ($null -ne $st.count) { $count = [int]$st.count }
      if ($null -ne $st.snoozeUntil) { $snoozeUntil = [long]$st.snoozeUntil }
    } catch {}
  }
  $count = $count + 1
  $persist = {
    try { ([pscustomobject]@{ count = $count; snoozeUntil = $snoozeUntil } | ConvertTo-Json -Compress) | Set-Content -LiteralPath $statePath -Encoding utf8 } catch {}
  }
  & $persist

  if ($count % $EVERY -ne 0) { exit 0 } # only check (and nudge) every N interactions

  $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  if ($snoozeUntil -gt 0 -and $nowMs -lt $snoozeUntil) { exit 0 } # snoozed after a recent nudge

  $text = Get-Content -LiteralPath $ledger -Raw
  $mReview = [regex]::Match($text, 'last-review:\D*(\d{4}-\d{2}-\d{2})')
  if (-not $mReview.Success) { exit 0 }
  $lastReview = $mReview.Groups[1].Value
  $mScan = [regex]::Match($text, 'last-full-scan:\D*(\d{4}-\d{2}-\d{2})')
  $lastScan = if ($mScan.Success) { $mScan.Groups[1].Value } else { $null }

  Push-Location $cwd
  $commits = 0
  try { $commits = [int](git rev-list --count "--since=$lastReview 00:00" HEAD 2>$null) } catch {}
  Pop-Location

  $now = Get-Date
  $daysReview = [int][math]::Floor(($now - [datetime]$lastReview).TotalDays)
  $daysScan = if ($lastScan) { [int][math]::Floor(($now - [datetime]$lastScan).TotalDays) } else { 0 }

  $reviewDue = ($commits -ge $COMMIT_THRESHOLD) -or ($daysReview -gt $DAY_THRESHOLD_REVIEW)
  $scanDue = $lastScan -and ($daysScan -gt $DAY_THRESHOLD_SCAN)
  if (-not $reviewDue -and -not $scanDue) { exit 0 }

  $parts = @()
  if ($reviewDue) { $parts += "$commits commit(s) and $daysReview day(s) since the last domain-skill review" }
  if ($scanDue) { $parts += "$daysScan day(s) since the last full repo-scan" }

  $ctx = 'PelizzAI (cadence): ' + ($parts -join '; ') + '. Consider invoking the pelizzai-skill-lab skill (maintenance mode) to review/update the domain skills. Suggest it to the user once; do not block the work.'
  $out = [pscustomobject]@{
    hookSpecificOutput = [pscustomobject]@{
      hookEventName     = 'UserPromptSubmit'
      additionalContext = $ctx
    }
  }
  $out | ConvertTo-Json -Compress -Depth 5 | Write-Output

  # snooze for the next SNOOZE_DAYS days so it does not repeat every window
  $snoozeUntil = $nowMs + ($SNOOZE_DAYS * 86400000L)
  & $persist
} catch {
  # never fail the user's prompt
}
exit 0
