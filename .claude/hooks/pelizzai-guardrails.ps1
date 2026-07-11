#!/usr/bin/env pwsh
# PelizzAI - hook de guarda git (PreToolUse, tool Bash), variante PowerShell. OPT-IN.
#
# Equivalente ao pelizzai-guardrails.mjs, para frota sem Node. Requer PowerShell 7+ (pwsh).
#
# Bloqueia, ANTES de rodarem, comandos git destrutivos que os gates do harness ja
# proibem em prosa - aqui a proibicao vira enforcement executavel:
#  - git push forcado ou destrutivo (--force/-f/+refspec/--delete/--mirror/:ref)
#  - git reset --hard
#  - git clean -f / -fd / --force
#  - git branch -D/-M/-f/--force
#  - git checkout de paths ou checkout -f/-B; switch -C/--force-create
#  - git restore de working tree (restore apenas --staged continua permitido)
#  - git worktree remove --force
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
    @{ Name = 'git push forcado/destrutivo'
       # --force-with-lease NAO casa com "--force(\s|$)" - a excecao e automatica.
       # Flags curtas podem vir agrupadas (git push -uf origin main) - casar o f dentro do bundle.
       Test = { param($s) ($s -match '\bgit\b.*\bpush\b') -and (($s -cmatch '(^|\s)--force(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)') -or ($s -cmatch '(^|\s)\+\S+(\s|$)') -or ($s -cmatch '(^|\s)(--delete|--mirror|--prune)(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*d[a-zA-Z]*(\s|$)') -or ($s -cmatch '(^|\s):\S+(\s|$)')) }
       Why  = 'pode reescrever ou apagar refs remotas e commits de outras pessoas.'
       Safe = 'use push normal; se reescrita for indispensavel, use --force-with-lease com autorizacao explicita. Exclusao remota deve ser executada conscientemente pelo usuario.' },
    @{ Name = 'git reset --hard'
       Test = { param($s) ($s -match '\bgit\b.*\breset\b') -and ($s -cmatch '(^|\s)--hard\b') }
       Why  = 'descarta commits e mudancas da working tree sem volta.'
       Safe = 'crie um ponto de retorno primeiro (stash nomeado ou commit WIP) e siga o procedimento da skill pelizzai-recovery.' },
    @{ Name = 'git clean -f'
       Test = { param($s) ($s -match '\bgit\b.*\bclean\b') -and (($s -cmatch '(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)') -or ($s -cmatch '(^|\s)--force\b')) }
       Why  = 'apaga arquivos nao rastreados de forma irreversivel (nao ha stash nem reflog para eles).'
       Safe = 'liste antes com git clean -n e confirme com o usuario o que sera apagado.' },
    @{ Name = 'git branch force-delete/force-rename'
       Test = { param($s) ($s -match '\bgit\b.*\bbranch\b') -and (($s -cmatch '(^|\s)-[a-zA-Z]*[DM][a-zA-Z]*(\s|$)') -or ($s -cmatch '(^|\s)--force(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)')) }
       Why  = 'pode remover branch nao mesclada ou sobrescrever um nome existente.'
       Safe = 'use -d/-m sem forca; descarte ou sobrescrita exige decisao explicita e operacao manual.' },
    @{ Name = 'git checkout de paths'
       Test = { param($s) ($s -match '\bgit\b.*\bcheckout\b(\s+--)?\s+\.\/?(\s|$)') -or ($s -match '\bgit\b.*\bcheckout\b.*\s--\s+\S+') }
       Why  = 'sobrescreve mudancas nao commitadas nos paths selecionados.'
       Safe = 'crie um ponto de retorno primeiro e confirme os paths; para stage, use git restore --staged.' },
    @{ Name = 'git checkout/switch force-create'
       Test = { param($s) ((($s -match '\bgit\b.*\bcheckout\b') -and (($s -cmatch '(^|\s)--force(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*B[a-zA-Z]*(\s|$)'))) -or (($s -match '\bgit\b.*\bswitch\b') -and (($s -cmatch '(^|\s)--force-create(\s|$)') -or ($s -cmatch '(^|\s)--discard-changes(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*C[a-zA-Z]*(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)')))) }
       Why  = 'pode sobrescrever a branch alvo ou descartar mudancas locais ao trocar de branch.'
       Safe = 'preserve a working tree primeiro e use switch/checkout sem flags de forca; para recuperacao, siga pelizzai-recovery.' },
    @{ Name = 'git restore de working tree'
       Test = { param($s) if (-not ($s -match '\bgit\b.*\brestore\b')) { return $false }; $staged = ($s -cmatch '--staged\b') -or ($s -cmatch '(^|\s)-[a-zA-Z]*S[a-zA-Z]*(\s|$)'); $worktree = ($s -cmatch '--worktree\b') -or ($s -cmatch '(^|\s)-[a-zA-Z]*W[a-zA-Z]*(\s|$)'); return (-not $staged) -or $worktree }
       Why  = 'restore sem modo exclusivamente staged descarta mudancas da working tree.'
       Safe = 'git restore --staged <paths> apenas tira do stage; para descartar conteudo, crie um ponto de retorno e obtenha confirmacao.' },
    @{ Name = 'git worktree remove --force'
       Test = { param($s) ($s -match '\bgit\b.*\bworktree\b.*\bremove\b') -and (($s -cmatch '(^|\s)--force(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)')) }
       Why  = 'pode remover um worktree sujo e apagar mudancas nao commitadas.'
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
