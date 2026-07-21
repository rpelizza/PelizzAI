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
#  - git switch -C / --force-create
#  - git restore .                  (sem --staged - perda da working tree)
#  - git worktree remove --force
#
# ESTAS REGRAS SAO DELIBERADAMENTE ESTREITAS. O hook mira o punhado de comandos que
# apagam trabalho de forma irrecuperavel; ele NAO tenta cobrir todo git perigoso. Por
# isso passam sem bloqueio, de proposito: git restore <arquivo>, git checkout -- <arquivo>,
# git branch -M <nome> (passo canonico do git init), git push --delete/+refspec e
# qualquer mencao a "restore"/"reset" dentro de um path, de uma mensagem de commit ou de
# um filtro (git add src/restore.ts, git log --grep=restore). Regra larga aqui custa caro:
# ela trava trabalho legitimo, o agente aprende a contornar o hook e a rede de seguranca
# perde valor. Ao mexer, prefira falso negativo a falso positivo - e teste os dois lados.
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
#
# Falso positivo conhecido (fail-closed, aceitavel para rede de seguranca): texto CITADO
# que contenha um padrao perigoso - ex.: git commit -m "docs: explica git reset --hard" -
# e bloqueado. Saida: reformule a mensagem ou rode o commit manualmente.
#
# Paridade com o .mjs e contrato: as duas variantes devem bloquear e liberar exatamente
# os mesmos comandos - verificado pelo scripts/test-harness-contracts.ps1.

$ErrorActionPreference = 'SilentlyContinue'
try {
  $raw = [Console]::In.ReadToEnd()
  if (-not $raw) { exit 0 }
  $data = $null
  try { $data = $raw | ConvertFrom-Json } catch { exit 0 }
  $command = $data.tool_input.command
  if (-not ($command -is [string]) -or $command -notmatch '\bgit\b') { exit 0 }

  # -match (case-insensitive) reconhece o comando: "Git reset --hard" tambem e bloqueado.
  # -cmatch (case-sensitive) e obrigatorio nas FLAGS: -D/-C/-S/-W destroem, -d/-c/-s/-w nao.
  $rules = @(
    @{ Name = 'git push --force / -f'
       # --force-with-lease NAO casa com "--force(\s|$)" - a excecao e automatica.
       # Flags curtas podem vir agrupadas (git push -uf origin main) - casar o f dentro do bundle.
       Test = { param($s) ($s -match '\bgit\b.*\bpush\b') -and (($s -cmatch '(^|\s)--force(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)')) }
       Why  = 'push forcado reescreve o historico remoto e pode apagar commits de outras pessoas.'
       Safe = 'use --force-with-lease (so sobrescreve se o remoto estiver onde voce espera) - e somente com pedido explicito do usuario.' },
    @{ Name = 'git reset --hard'
       Test = { param($s) ($s -match '\bgit\b.*\breset\b') -and ($s -cmatch '(^|\s)--hard\b') }
       Why  = 'descarta commits e mudancas da working tree sem volta.'
       Safe = 'crie um ponto de retorno primeiro (stash nomeado ou commit WIP) e siga o procedimento da skill pelizzai-recovery.' },
    @{ Name = 'git clean -f'
       Test = { param($s) ($s -match '\bgit\b.*\bclean\b') -and (($s -cmatch '(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)') -or ($s -cmatch '(^|\s)--force\b')) }
       Why  = 'apaga arquivos nao rastreados de forma irreversivel (nao ha stash nem reflog para eles).'
       Safe = 'liste antes com git clean -n e confirme com o usuario o que sera apagado.' },
    @{ Name = 'git branch -D'
       # -D case-sensitive (-d e seguro); pode vir agrupada (git branch -qD nome).
       # -M NAO entra: renomear branch e o passo canonico de git init (git branch -M main).
       Test = { param($s) ($s -match '\bgit\b.*\bbranch\b') -and ($s -cmatch '(^|\s)-[a-zA-Z]*D[a-zA-Z]*(\s|$)') }
       Why  = 'forca a remocao de uma branch NAO mesclada - os commits dela podem se perder.'
       Safe = 'use -d (so remove branch ja mesclada) ou confirme o descarte com o usuario (a pelizzai-finish-task exige o texto "descartar").' },
    @{ Name = 'git checkout . / checkout [<ref>] -- .'
       # Cobre "checkout .", "checkout -- .", "checkout <ref> -- ." e a forma "./" (todas descartam a working tree).
       # checkout -- <arquivo> NAO entra: descartar um arquivo nomeado e operacao rotineira.
       Test = { param($s) ($s -match '\bgit\b.*\bcheckout\b(\s+--)?\s+\.\/?(\s|$)') -or ($s -match '\bgit\b.*\bcheckout\b\s+\S+\s+--\s+\.\/?(\s|$)') }
       Why  = 'sobrescreve TODAS as mudancas nao commitadas da working tree.'
       Safe = 'crie um ponto de retorno primeiro (git stash push -u -m "<motivo>") ou restaure so arquivos especificos.' },
    @{ Name = 'git switch -C / --force-create'
       # -C case-sensitive (-c/--create e seguro: falha se a branch ja existir).
       Test = { param($s) ($s -match '\bgit\b.*\bswitch\b') -and (($s -cmatch '(^|\s)--force-create(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*C[a-zA-Z]*(\s|$)')) }
       Why  = 'sobrescreve uma branch existente com o ponto de partida atual - os commits que so existiam nela se perdem.'
       Safe = 'use -c/--create (falha se a branch ja existir); sobrescrever exige decisao explicita do usuario.' },
    @{ Name = 'git restore . (working tree)'
       # Sem --staged/-S (ou com --worktree/-W explicito), restore descarta a working tree. "./" == ".".
       # O alvo "." e obrigatorio: git restore <arquivo> e rotina, e exigir o "." mantem o hook
       # cego para "restore" que aparece em paths, mensagens e filtros (git add src/restore.ts).
       Test = { param($s) ($s -match '\bgit\b.*\brestore\b') -and ($s -cmatch '(^|\s)\.\/?(\s|$)') -and ((-not (($s -cmatch '--staged\b') -or ($s -cmatch '(^|\s)-S(\s|$)'))) -or ($s -cmatch '--worktree\b') -or ($s -cmatch '(^|\s)-W(\s|$)')) }
       Why  = 'sem --staged, restore descarta as mudancas da working tree sem volta.'
       Safe = 'git restore --staged . apenas tira do stage (seguro); para descartar de verdade, crie um ponto de retorno (stash) e confirme com o usuario.' },
    @{ Name = 'git worktree remove --force'
       Test = { param($s) ($s -match '\bgit\b.*\bworktree\b.*\bremove\b') -and (($s -cmatch '(^|\s)--force(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)')) }
       Why  = 'remove um worktree sujo e apaga com ele as mudancas nao commitadas que estavam la.'
       Safe = 'inspecione o worktree, preserve o conteudo e use git worktree remove sem --force.' }
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
