#!/usr/bin/env pwsh
# PelizzAI - hook SessionStart (matcher startup|clear|compact), variante PowerShell. OPT-IN.
#
# Equivalente ao pelizzai-session-start.mjs, para frota sem Node. Requer PowerShell 7+.
#
# Emite um lembrete CURTO no inicio da sessao: carregar core/router para tarefas de
# projeto, classificar o efeito antes de agir e, se pelizzai/data/state.md tiver tarefa
# ativa (slug != <none> e phase != done), avisar que ha retomada via pelizzai-router.
#
# Nota de valor: no Claude Code o CLAUDE.md ja e re-injetado no startup e apos o
# compact - o ganho real deste hook esta no `clear` (que zera tudo) e em plataformas
# que NAO re-injetam a entrada sempre-carregada.
#
# Garantias: SEMPRE sai 0; engole qualquer erro; nunca bloqueia a sessao.
#
# Instalacao (opt-in), em .claude/settings.json do projeto consumidor:
#   { "hooks": { "SessionStart": [ { "matcher": "startup|clear|compact", "hooks": [
#       { "type": "command",
#         "command": "pwsh -NoProfile -File \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-session-start.ps1\"" } ] } ] } }

$ErrorActionPreference = 'SilentlyContinue'
try {
  $raw = [Console]::In.ReadToEnd()
  $cwd = (Get-Location).Path
  if ($raw) { try { $j = $raw | ConvertFrom-Json; if ($j.cwd) { $cwd = $j.cwd } } catch {} }

  $lines = @(
    'PelizzAI: em tarefas de projeto, carregue pelizzai-core -> pelizzai-router e classifique effect, risco, incerteza e superficies antes de agir.',
    'Escolha uma head skill e overlays proporcionais; read-only nao inicializa estado, e qualquer escrita passa primeiro pelo gate de isolamento.'
  )

  $statePath = Join-Path $cwd 'pelizzai/data/state.md'
  if (Test-Path -LiteralPath $statePath) {
    try {
      $state = Get-Content -LiteralPath $statePath -Raw
      $mSlug = [regex]::Match($state, '(?m)^\s*-\s*slug:\s*(.+?)\s*$')
      $mPhase = [regex]::Match($state, '(?m)^\s*-\s*phase:\s*(\S+)')
      $slug = if ($mSlug.Success) { $mSlug.Groups[1].Value } else { $null }
      $phase = if ($mPhase.Success) { $mPhase.Groups[1].Value } else { $null }
      if ($slug -and $slug -ne '<none>' -and -not $slug.StartsWith('<') -and $phase -and $phase -ne 'done' -and -not $phase.StartsWith('<')) {
        $lines += "Ha tarefa ATIVA em pelizzai/data/state.md (slug: $slug, phase: $phase) - retome via pelizzai-router, validando o cursor contra o git antes de prosseguir."
      }
    } catch {}
  }

  $out = [pscustomobject]@{
    hookSpecificOutput = [pscustomobject]@{
      hookEventName     = 'SessionStart'
      additionalContext = ($lines -join "`n")
    }
  }
  $out | ConvertTo-Json -Compress -Depth 5 | Write-Output
} catch {
  # nunca falhe o inicio da sessao
}
exit 0
