#!/usr/bin/env pwsh
# PelizzAI - SessionStart hook (matcher startup|resume|clear|compact), PowerShell variant. OPT-IN.
#
# Equivalent to pelizzai-session-start.mjs, for fleets without Node. Requires PowerShell 7+.
#
# Emits a SHORT reminder at session start: load pelizzai-core before answering
# anything (the 1% rule), go through core/router on project tasks, classify the
# effect before acting and, if pelizzai/data/state.md has an active task
# (slug != <none> and phase != done), warn that there is a resumption via pelizzai-router.
#
# Value note: in Claude Code, CLAUDE.md is already re-injected on startup and after
# compact - the real gain of this hook is on `clear` (which wipes everything) and on
# platforms that do NOT re-inject the always-loaded entry point.
#
# Guarantees: ALWAYS exits 0; swallows any error; never blocks the session.
#
# Installation (opt-in), in the consumer project's .claude/settings.json:
#   { "hooks": { "SessionStart": [ { "matcher": "startup|resume|clear|compact", "hooks": [
#       { "type": "command",
#         "command": "pwsh -NoProfile -File \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-session-start.ps1\"" } ] } ] } }

$ErrorActionPreference = 'SilentlyContinue'
try {
  $raw = [Console]::In.ReadToEnd()
  $cwd = (Get-Location).Path
  if ($raw) { try { $j = $raw | ConvertFrom-Json; if ($j.cwd) { $cwd = $j.cwd } } catch {} }

  $lines = @(
    'PelizzAI: before answering ANYTHING, load the pelizzai-core skill and honor the 1% rule - if a skill applies (even to a trivial tweak), invoke it.',
    'Every task that touches the project goes through pelizzai-core -> pelizzai-router: classify effect, risk, uncertainty and surfaces before acting.',
    'Pick a head skill and proportional overlays; read-only initializes no state, and any write goes through the isolation gate first.'
  )

  $statePath = Join-Path $cwd 'pelizzai/data/state.md'
  if (Test-Path -LiteralPath $statePath) {
    try {
      $state = Get-Content -LiteralPath $statePath -Raw
      $mSlug = [regex]::Match($state, '(?m)^\s*-\s*slug:\s*(.+?)\s*$')
      $mPhase = [regex]::Match($state, '(?m)^\s*-\s*phase:\s*(\S+)')
      $slug = if ($mSlug.Success) { $mSlug.Groups[1].Value } else { $null }
      $phase = if ($mPhase.Success) { $mPhase.Groups[1].Value } else { $null }
      # state.md is a VERSIONED file: whatever it carries lands in the agent's context on every
      # session start. Values are matched against the shape the template documents and the whole
      # line is DISCARDED on mismatch - untrusted text, not "a different policy" (second-order
      # prompt injection via a merged commit). Parity with the .mjs fix.
      $phases = @('brainstorm', 'plan', 'exec', 'review', 'delivered', 'done', 'abandoned', 'blocked')
      if ($slug -and $slug -cmatch '^[a-z0-9][a-z0-9._-]{0,63}$' -and $phase -and ($phases -ccontains $phase) -and $phase -ne 'done') {
        $lines += "There is an ACTIVE task in pelizzai/data/state.md (slug: $slug, phase: $phase) - resume via pelizzai-router, validating the cursor against git before proceeding."
      }
    } catch {}
  }

  # Anchored-entrypoint self-orientation: in a consumer where the harness is installed (core
  # skill present) but CLAUDE.md is missing or lost its pelizzai:contract block, say how to
  # restore it - the sync recreates/repairs it without touching project content outside the markers.
  try {
    $srcModeAnchor = Test-Path -LiteralPath (Join-Path $cwd 'scripts/pelizzai-source-repo.txt')
    $coreInstalled = Test-Path -LiteralPath (Join-Path $cwd '.claude/skills/pelizzai-core')
    if ((-not $srcModeAnchor) -and $coreInstalled) {
      $anchored = $false
      try {
        $claudePath = Join-Path $cwd 'CLAUDE.md'
        if (Test-Path -LiteralPath $claudePath) {
          # -ErrorAction Stop: with SilentlyContinue at file scope a read failure would NOT
          # reach the catch, and this leg would nag where the .mjs stays silent (parity).
          $anchored = (Get-Content -LiteralPath $claudePath -Raw -ErrorAction Stop).Contains('<!-- pelizzai:contract -->')
        }
      } catch { $anchored = $true } # unreadable file: do not nag on a doubt
      if (-not $anchored) {
        $lines += 'PelizzAI entry files are missing or not anchored (no pelizzai:contract block in CLAUDE.md). Run `node scripts/sync-harness.mjs` (or the bootstrap) to create/restore the harness contract block - project content outside the block is preserved.'
      }
    }
  } catch {}

  # Consumer without a domain-skill catalog: suggests ONCE the read-only bootstrap path
  # (propose->confirm; nothing is created without consent). In source mode (source repo)
  # it is a no-op. Creating pelizzai/domain-skills.md (even `_none for now_`) silences the nudge.
  try {
    # Dedicated sentinel: only the source repo has it (consumers have manifest/sync and are NOT the source).
    $srcMode = Test-Path -LiteralPath (Join-Path $cwd 'scripts/pelizzai-source-repo.txt')
    if ((-not $srcMode) -and (-not (Test-Path -LiteralPath (Join-Path $cwd 'pelizzai/domain-skills.md')))) {
      $lines += 'Project has no domain-skill catalog (pelizzai/domain-skills.md missing). If you are going to work on the code, consider pelizzai-audit in scan-only -> propose bootstrap-write. Nothing is created without your confirmation.'
    }
  } catch {}

  # Recap of the already-ratified execution policy (anti-fatigue): the router reapplies it as a
  # 1-line recap instead of re-asking. destination is NEVER a default: push/PR/publication per task.
  try {
    $profilePath = Join-Path $cwd 'pelizzai/profile.md'
    if (Test-Path -LiteralPath $profilePath) {
      $profile = Get-Content -LiteralPath $profilePath -Raw
      $ratified = @()
      $mIso = [regex]::Match($profile, 'isolation-default:\s*(\S+)')
      $mMode = [regex]::Match($profile, 'execution-mode-default:\s*(\S+)')
      $mCommit = [regex]::Match($profile, 'commit-strategy-default:\s*(\S+)')
      # Not ratified = raw `unset` OR any placeholder between <> (the bootstrap writes
      # `<unset>`, and the template ships the `<branch|worktree|unset>` menu) - same convention
      # as state.md above. Without this, the recap would fire on every freshly bootstrapped
      # consumer. The allowlist closes the same injection vector as the slug: profile.md is
      # versioned, so only the enum values the template documents are echoed.
      # -ccontains (case-sensitive): the .mjs allowlist uses includes(), which is case-sensitive
      # — `isolation-default: Branch` must behave identically on both legs.
      $isRatified = { param($m, $allowed) $m.Success -and $m.Groups[1].Value -ne 'unset' -and -not $m.Groups[1].Value.StartsWith('<') -and ($allowed -ccontains $m.Groups[1].Value) }
      if (& $isRatified $mIso @('branch', 'worktree')) { $ratified += "isolation $($mIso.Groups[1].Value)" }
      if (& $isRatified $mMode @('inline', 'subagents', 'team')) { $ratified += "mode $($mMode.Groups[1].Value)" }
      if (& $isRatified $mCommit @('granular', 'squash-final')) { $ratified += "commit $($mCommit.Groups[1].Value)" }
      if ($ratified.Count -gt 0) {
        $lines += "Ratified execution policy for this project (pelizzai/profile.md): $($ratified -join ', ') - reapply it as a 1-line recap; do not re-ask what has already been ratified (destination remains per task)."
      }
    }
  } catch {}

  $out = [pscustomobject]@{
    hookSpecificOutput = [pscustomobject]@{
      hookEventName     = 'SessionStart'
      additionalContext = ($lines -join "`n")
    }
  }
  $out | ConvertTo-Json -Compress -Depth 5 | Write-Output
} catch {
  # never fail session start
}
exit 0
