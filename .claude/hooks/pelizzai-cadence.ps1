#!/usr/bin/env pwsh
# PelizzAI - hook de cadencia (UserPromptSubmit), variante PowerShell.
#
# Equivalente ao pelizzai-cadence.mjs, para frota sem Node. Requer PowerShell 7+ (pwsh)
# - o 5.1 corrompe a saida UTF-8 com acentos.
#
# Mesmas garantias do .mjs: no-op silencioso sem ledger; checagem cara (git) so a cada N
# interacoes; SEMPRE sai 0 (nunca bloqueia o prompt); engole qualquer erro.
#
# Instalacao (opt-in, no bootstrap), em .claude/settings.json:
#   { "hooks": { "UserPromptSubmit": [ { "hooks": [
#       { "type": "command",
#         "command": "pwsh -NoProfile -File \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-cadence.ps1\"" } ] } ] } }

$ErrorActionPreference = 'SilentlyContinue'
try {
  $EVERY = 10            # checa a cada N interacoes
  $COMMIT_THRESHOLD = 10 # >= N commits desde a ultima revisao
  $DAY_THRESHOLD = 10    # > N dias desde a ultima revisao / ultimo full-scan

  $raw = [Console]::In.ReadToEnd()
  $cwd = (Get-Location).Path
  if ($raw) { try { $j = $raw | ConvertFrom-Json; if ($j.cwd) { $cwd = $j.cwd } } catch {} }

  $ledger = Join-Path $cwd 'pelizzai/data/review-domain-skills.md'
  if (-not (Test-Path -LiteralPath $ledger)) { exit 0 } # harness nao inicializado neste projeto

  # contador de interacoes
  $statePath = Join-Path $cwd 'pelizzai/data/.cadence-state.json'
  $count = 0
  if (Test-Path -LiteralPath $statePath) {
    try { $count = [int]((Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json).count) } catch {}
  }
  $count = $count + 1
  try { ([pscustomobject]@{ count = $count } | ConvertTo-Json -Compress) | Set-Content -LiteralPath $statePath -Encoding utf8 } catch {}

  if ($count % $EVERY -ne 0) { exit 0 } # so checa (e nudga) a cada N interacoes

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

  $reviewDue = ($commits -ge $COMMIT_THRESHOLD) -or ($daysReview -gt $DAY_THRESHOLD)
  $scanDue = $lastScan -and ($daysScan -gt $DAY_THRESHOLD)
  if (-not $reviewDue -and -not $scanDue) { exit 0 }

  $parts = @()
  if ($reviewDue) { $parts += "$commits commit(s) e $daysReview dia(s) desde a ultima revisao de skills de dominio" }
  if ($scanDue) { $parts += "$daysScan dia(s) desde o ultimo repo-scan completo" }

  $ctx = 'PelizzAI (cadencia): ' + ($parts -join '; ') + '. Considere acionar a skill pelizzai-writing-skills (modo manutencao) para revisar/atualizar as skills de dominio. Sugira ao usuario uma vez; nao bloqueie o trabalho.'
  $out = [pscustomobject]@{
    hookSpecificOutput = [pscustomobject]@{
      hookEventName     = 'UserPromptSubmit'
      additionalContext = $ctx
    }
  }
  $out | ConvertTo-Json -Compress -Depth 5 | Write-Output
} catch {
  # nunca falhe o prompt do usuario
}
exit 0
