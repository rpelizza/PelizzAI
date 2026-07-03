#!/usr/bin/env pwsh
# PelizzAI - hook de cadencia (UserPromptSubmit), variante PowerShell.
#
# Equivalente ao pelizzai-cadence.mjs, para frota sem Node. Requer PowerShell 7+ (pwsh)
# - o 5.1 corrompe a saida UTF-8 com acentos.
#
# Cadencia (calibrada para times ativos - ver pelizzai-writing-skills ->
# references/domain-skill-maintenance.md):
#  - Amostragem: checa a cada 20 interacoes (nao a cada mensagem).
#  - Revisao devida: >= 30 commits OU > 14 dias desde last-review (o eixo de DIAS e a ancora
#    de sprint; os commits so ANTECIPAM num burst real de trabalho).
#  - Repo-scan completo: > 21 dias desde last-full-scan.
#  - Supressao: depois de avisar, silencia por 7 dias (evita repetir a cada janela).
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
  $EVERY = 20                  # checa a cada N interacoes (amostragem, nao frequencia do nudge)
  $COMMIT_THRESHOLD = 30       # >= N commits desde a ultima revisao (antecipa em burst real)
  $DAY_THRESHOLD_REVIEW = 14   # > N dias desde a ultima revisao (ancora de sprint)
  $DAY_THRESHOLD_SCAN = 21     # > N dias desde o ultimo full-scan
  $SNOOZE_DAYS = 7             # apos avisar, silencia por N dias

  $raw = [Console]::In.ReadToEnd()
  $cwd = (Get-Location).Path
  if ($raw) { try { $j = $raw | ConvertFrom-Json; if ($j.cwd) { $cwd = $j.cwd } } catch {} }

  $ledger = Join-Path $cwd 'pelizzai/data/review-domain-skills.md'
  if (-not (Test-Path -LiteralPath $ledger)) { exit 0 } # harness nao inicializado neste projeto

  # estado: contador de interacoes + janela de supressao (retrocompativel com { count })
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

  if ($count % $EVERY -ne 0) { exit 0 } # so checa (e nudga) a cada N interacoes

  $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  if ($snoozeUntil -gt 0 -and $nowMs -lt $snoozeUntil) { exit 0 } # silenciado apos aviso recente

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

  # silencia os proximos SNOOZE_DAYS dias para nao repetir a cada janela
  $snoozeUntil = $nowMs + ($SNOOZE_DAYS * 86400000L)
  & $persist
} catch {
  # nunca falhe o prompt do usuario
}
exit 0
