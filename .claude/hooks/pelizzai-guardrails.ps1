#!/usr/bin/env pwsh
# PelizzAI - hook de guarda git (PreToolUse, tool Bash), variante PowerShell. OPT-IN.
#
# Equivalente ao pelizzai-guardrails.mjs, para frota sem Node. Requer PowerShell 7+ (pwsh).
#
# Bloqueia, ANTES de rodarem, comandos git destrutivos que os gates do harness ja
# proibem em prosa - aqui a proibicao vira enforcement executavel:
#  - git push --force / -f          (exceto --force-with-lease)
#  - git reset --hard
#  - git clean -f / -fd / --force
#  - git branch -D
#  - git checkout . / checkout -- .
#  - git restore .                  (sem --staged - perda da working tree)
#
# Bloqueio: exit 2 + motivo e caminho seguro no stderr. Qualquer outro comando:
# exit 0 silencioso. Erros do PROPRIO hook: exit 0 (fail-open - o hook e rede de
# seguranca, nao gate primario; um bug aqui nunca trava o usuario).
#
# Instalacao (opt-in, recomendada pela pelizzai-audit), em .claude/settings.json:
#   { "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [
#       { "type": "command",
#         "command": "pwsh -NoProfile -File \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-guardrails.ps1\"" } ] } ] } }
#
# Teste manual (num shell PowerShell):
#   '{"tool_input":{"command":"git reset --hard"}}' | pwsh -NoProfile -File pelizzai-guardrails.ps1; echo $LASTEXITCODE
#   -> motivo no stderr e exit code 2. Comando inofensivo (ex.: "git status") -> 0.

$ErrorActionPreference = 'SilentlyContinue'
try {
  $raw = [Console]::In.ReadToEnd()
  if (-not $raw) { exit 0 }
  $data = $null
  try { $data = $raw | ConvertFrom-Json } catch { exit 0 }
  $command = $data.tool_input.command
  if (-not ($command -is [string]) -or $command -notmatch '\bgit\b') { exit 0 }

  # -cmatch (case-sensitive) e obrigatorio: -D (destrutivo) != -d (seguro).
  $rules = @(
    @{ Name = 'git push --force / -f'
       # --force-with-lease NAO casa com "--force(\s|$)" - a excecao e automatica.
       Test = { param($s) ($s -cmatch '\bgit\b.*\bpush\b') -and (($s -cmatch '(^|\s)--force(\s|$)') -or ($s -cmatch '(^|\s)-f(\s|$)')) }
       Why  = 'push forcado reescreve o historico remoto e pode apagar commits de outras pessoas.'
       Safe = 'use --force-with-lease (so sobrescreve se o remoto estiver onde voce espera) - e somente com pedido explicito do usuario.' },
    @{ Name = 'git reset --hard'
       Test = { param($s) ($s -cmatch '\bgit\b.*\breset\b') -and ($s -cmatch '(^|\s)--hard\b') }
       Why  = 'descarta commits e mudancas da working tree sem volta.'
       Safe = 'crie um ponto de retorno primeiro (stash nomeado ou commit WIP) e siga o procedimento da skill pelizzai-recovery.' },
    @{ Name = 'git clean -f'
       Test = { param($s) ($s -cmatch '\bgit\b.*\bclean\b') -and (($s -cmatch '(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)') -or ($s -cmatch '(^|\s)--force\b')) }
       Why  = 'apaga arquivos nao rastreados de forma irreversivel (nao ha stash nem reflog para eles).'
       Safe = 'liste antes com git clean -n e confirme com o usuario o que sera apagado.' },
    @{ Name = 'git branch -D'
       Test = { param($s) ($s -cmatch '\bgit\b.*\bbranch\b') -and ($s -cmatch '(^|\s)-D(\s|$)') }
       Why  = 'forca a remocao de uma branch NAO mesclada - os commits dela podem se perder.'
       Safe = 'use -d (so remove branch ja mesclada) ou confirme o descarte com o usuario (a pelizzai-finish-task exige o texto "descartar").' },
    @{ Name = 'git checkout . / checkout -- .'
       Test = { param($s) $s -cmatch '\bgit\b.*\bcheckout\b(\s+--)?\s+\.(\s|$)' }
       Why  = 'sobrescreve TODAS as mudancas nao commitadas da working tree.'
       Safe = 'crie um ponto de retorno primeiro (git stash push -u -m "<motivo>") ou restaure so arquivos especificos.' },
    @{ Name = 'git restore . (working tree)'
       Test = { param($s) ($s -cmatch '\bgit\b.*\brestore\b') -and ($s -cmatch '(^|\s)\.(\s|$)') -and (($s -cnotmatch '--staged\b') -or ($s -cmatch '--worktree\b') -or ($s -cmatch '(^|\s)-W(\s|$)')) }
       Why  = 'sem --staged, restore descarta as mudancas da working tree sem volta.'
       Safe = 'git restore --staged . apenas tira do stage (seguro); para descartar de verdade, crie um ponto de retorno (stash) e confirme com o usuario.' }
  )

  # Analisa por segmento de shell (&&, ||, ;, |, quebras de linha) para nao atribuir
  # flags de um comando (ex.: rm -f) ao git de outro segmento.
  $segments = $command -split '&&|\|\||;|\||\r?\n'
  foreach ($seg in $segments) {
    foreach ($rule in $rules) {
      if (& $rule.Test $seg) {
        [Console]::Error.WriteLine("PelizzAI guardrails: comando bloqueado - $($rule.Name).")
        [Console]::Error.WriteLine("Por que: $($rule.Why)")
        [Console]::Error.WriteLine("Caminho seguro: $($rule.Safe)")
        [Console]::Error.WriteLine('(Hook opt-in de guarda git. Se o usuario pediu EXPLICITAMENTE esta operacao, peca a ele que a rode manualmente ou que desabilite o hook em .claude/settings.json.)')
        exit 2
      }
    }
  }
} catch {
  # fail-open: erro do hook nunca trava o usuario
}
exit 0
