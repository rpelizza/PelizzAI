#!/usr/bin/env pwsh
# PelizzAI - hook SessionStart (matcher startup|clear|compact), variante PowerShell. OPT-IN.
#
# Equivalente ao pelizzai-session-start.mjs, para frota sem Node. Requer PowerShell 7+.
#
# Emite um lembrete CURTO no inicio da sessao: carregar a pelizzai-core antes de
# responder qualquer coisa (regra do 1%), passar por core/router nas tarefas de projeto,
# classificar o efeito antes de agir e, se pelizzai/data/state.md tiver tarefa
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
    'PelizzAI: antes de responder QUALQUER coisa, carregue a skill pelizzai-core e honre a regra do 1% - se uma skill se aplica (mesmo a um ajuste trivial), acione-a.',
    'Toda tarefa que toca o projeto passa por pelizzai-core -> pelizzai-router: classifique effect, risco, incerteza e superficies antes de agir.',
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

  # Consumidor sem catalogo de skills de dominio: sugere UMA vez o caminho de bootstrap
  # read-only (propor->confirmar; nada e criado sem consentimento). Em source mode (repo-fonte)
  # e no-op. Criar pelizzai/domain-skills.md (mesmo `_nenhuma por enquanto_`) silencia o nudge.
  try {
    # Sentinela dedicada: so o repo-fonte a tem (consumidores tem manifesto/sync e NAO sao fonte).
    $srcMode = Test-Path -LiteralPath (Join-Path $cwd 'scripts/pelizzai-source-repo.txt')
    if ((-not $srcMode) -and (-not (Test-Path -LiteralPath (Join-Path $cwd 'pelizzai/domain-skills.md')))) {
      $lines += 'Projeto sem catalogo de skills de dominio (pelizzai/domain-skills.md ausente). Se for trabalhar no codigo, considere pelizzai-audit em scan-only -> propor bootstrap-write. Nada e criado sem sua confirmacao.'
    }
  } catch {}

  # Recap da politica de execucao ja ratificada (anti-fadiga): o router reaplica como recap de
  # 1 linha em vez de re-perguntar. destination NUNCA e default: push/PR/publicacao por tarefa.
  try {
    $profilePath = Join-Path $cwd 'pelizzai/profile.md'
    if (Test-Path -LiteralPath $profilePath) {
      $profile = Get-Content -LiteralPath $profilePath -Raw
      $ratified = @()
      $mIso = [regex]::Match($profile, 'isolation-default:\s*(\S+)')
      $mMode = [regex]::Match($profile, 'execution-mode-default:\s*(\S+)')
      $mCommit = [regex]::Match($profile, 'commit-strategy-default:\s*(\S+)')
      # Nao ratificado = `unset` cru OU qualquer placeholder entre <> (o bootstrap grava
      # `<unset>`, e o template traz o menu `<branch|worktree|unset>`) - mesma convencao do
      # state.md acima. Sem isto, o recap dispararia em todo consumidor recem-bootstrapado.
      $isRatified = { param($m) $m.Success -and $m.Groups[1].Value -ne 'unset' -and -not $m.Groups[1].Value.StartsWith('<') }
      if (& $isRatified $mIso) { $ratified += "isolamento $($mIso.Groups[1].Value)" }
      if (& $isRatified $mMode) { $ratified += "modo $($mMode.Groups[1].Value)" }
      if (& $isRatified $mCommit) { $ratified += "commit $($mCommit.Groups[1].Value)" }
      if ($ratified.Count -gt 0) {
        $lines += "Politica de execucao ratificada do projeto (pelizzai/profile.md): $($ratified -join ', ') - reaplique como recap de 1 linha; nao re-pergunte o que ja foi ratificado (destino continua por tarefa)."
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
  # nunca falhe o inicio da sessao
}
exit 0
