#!/usr/bin/env pwsh
# PelizzAI - hook writegate (PreToolUse), variante PowerShell. OPT-IN.
# Fail-CLOSED no invariante, fail-OPEN no erro. Requer PowerShell 7+ (pwsh).
#
# Equivalente ao pelizzai-writegate.mjs (comportamento identico), para frota sem Node.
# Rede de seguranca que move da obediencia do modelo para enforcement executavel as DUAS
# autonomias irreversiveis do redesign: escrever produto sem isolamento e escrever codigo
# antes de o gate ser ratificado. NAO decide rota - devolve o controle ao gate humano.
# Espelha o espirito e o envelope de seguranca do pelizzai-guardrails.ps1.
#
# Dispara ANTES da escrita, em dois matchers irmaos que compartilham este mesmo arquivo:
#  - Write | Edit | MultiEdit | NotebookEdit  -> le tool_input.file_path / .notebook_path;
#  - Bash                                     -> detecta redirecionamento de escrita no
#    tool_input.command (>, >>, &>, tee, sed -i, Set-Content/Add-Content/Out-File) para
#    caminhos DENTRO da raiz do projeto. Mesma regra dos dois lados.
#
# REGRA A (invariante, ambos os modos) - isolamento antes da primeira escrita:
#   escrever QUALQUER caminho dentro da raiz estando em branch protegida
#   (main/master/develop/dev, o default do origin/HEAD) ou em HEAD destacado -> BLOQUEIA.
#
# REGRA B (so consumidor: existe pelizzai/ e NAO e o repo-fonte) - nada de codigo antes do gate:
#   escrever caminho de PRODUTO (fora de pelizzai/) enquanto pelizzai/data/state.md NAO
#   contem "kickoff: ratificado" -> BLOQUEIA. Escritas em pelizzai/ sao sempre liberadas
#   (sao os artefatos que registram o proprio gate). Em SOURCE MODE (repo-fonte PelizzAI:
#   os 3 sentinels) a Regra B e PULADA - ali o marcador vive no execution record nativo.
#
# Bloqueio: exit 2 + motivo e caminho seguro no stderr. Erros do PROPRIO hook e casos em que
# NAO da para decidir com seguranca: exit 0 (fail-open - bug ou falso positivo nunca trava o
# usuario). Sem state.md em consumidor: permite e avisa no maximo 1x por janela.
#
# Instalacao (opt-in, recomendada pela pelizzai-audit no bootstrap, mesclada sem sobrescrever
# hooks/permissoes ja existentes), em .claude/settings.json - os DOIS matchers sao necessarios:
#   { "hooks": { "PreToolUse": [
#       { "matcher": "Write|Edit|MultiEdit|NotebookEdit", "hooks": [
#           { "type": "command",
#             "command": "pwsh -NoProfile -File \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-writegate.ps1\"" } ] },
#       { "matcher": "Bash", "hooks": [
#           { "type": "command",
#             "command": "pwsh -NoProfile -File \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-writegate.ps1\"" } ] } ] } }
#
# Teste manual (num shell PowerShell):
#   '{"tool_input":{"file_path":"src/app.ts"},"cwd":"/caminho/do/repo"}' | pwsh -NoProfile -File pelizzai-writegate.ps1; echo $LASTEXITCODE
#   -> em branch protegida ou sem "kickoff: ratificado": motivo no stderr e exit 2; caso
#      contrario (branch de tarefa com kickoff ratificado, ou fora do repo): exit 0.
#
# O usuario pode desabilitar o hook em .claude/settings.json - nunca e bloqueio inescapavel.

$ErrorActionPreference = 'SilentlyContinue'

# Branches protegidas por default (Regra A). origin/HEAD enriquece a lista em runtime.
$PROTECTED = @('main', 'master', 'develop', 'dev')
# Marcador maquina-legivel do gate consolidado no state.md (kickoff/pos-plano ratificado
# pelo usuario: conteudo + isolamento + modo + commit). writegate e retomada dependem dele.
$KICKOFF_RATIFIED = 'kickoff:\s*ratificado'
# Sentinels do repo-fonte PelizzAI (source mode): presentes os 3, a Regra B e pulada.
$SOURCE_SENTINELS = @('.claude/skills/pelizzai-core/SKILL.md', 'scripts/pelizzai-core-skills.txt', 'scripts/sync-harness.ps1')
# Fail-open "nao pode decidir": avisa no maximo 1x por janela (por repo) para nao spammar.
$script:WARN_SNOOZE_MS = 86400000L  # 24h
# Windows e macOS comparam caminhos sem case; Linux com case.
$script:CI = $IsWindows -or $IsMacOS

# git com o cwd do stdin; '' em QUALQUER falha (git ausente, fora de repo, ref inexistente).
function Invoke-Git([string]$Cwd, [string[]]$GitArgs) {
  try {
    $out = & git -C $Cwd @GitArgs 2>$null
    if ($LASTEXITCODE -ne 0) { return '' }
    return ($out | Out-String).Trim()
  } catch { return '' }
}

# Barras para frente e sem barra final, para comparacao de prefixo robusta a \ e /.
function Get-Norm([string]$p) {
  return (($p -replace '\\', '/') -replace '/+$', '')
}

# child e o proprio root ou esta DENTRO dele (case conforme o SO).
function Test-Inside([string]$child, [string]$root) {
  $c = Get-Norm $child
  $r = Get-Norm $root
  if ($script:CI) { $c = $c.ToLowerInvariant(); $r = $r.ToLowerInvariant() }
  return ($c -eq $r) -or $c.StartsWith($r + '/')
}

# Fecha o token corrente: alvo de redirecionamento (ignora dup de fd >&N) ou token comum
# (descarta prefixo de fd solto, o "2" de "2>"). Mutacoes via [ref] (parametro por referencia).
function Flush-Token([ref]$Cur, $Tokens, $Redirects, [ref]$Expect) {
  if ($Cur.Value -eq '') { return }
  if ($Expect.Value) {
    if (-not $Cur.Value.StartsWith('&')) { [void]$Redirects.Add($Cur.Value) }
    $Expect.Value = $false
  } elseif (-not [regex]::IsMatch($Cur.Value, '^[0-9]+$|^&$')) {
    [void]$Tokens.Add($Cur.Value)
  }
  $Cur.Value = ''
}

# Parser de UM segmento de shell, ciente de aspas: separa tokens e ALVOS de redirecionamento.
# Ciente de aspas para nao confundir um '>' dentro de string (ex.: git commit -m "a > b")
# com redirecionamento real.
function Get-ParsedSegment([string]$seg) {
  $tokens = [System.Collections.Generic.List[string]]::new()
  $redirects = [System.Collections.Generic.List[string]]::new()
  $cur = ''
  $quote = $null
  $expectTarget = $false
  for ($i = 0; $i -lt $seg.Length; $i++) {
    $ch = $seg.Substring($i, 1)
    if ($null -ne $quote) {
      if ($ch -eq $quote) { $quote = $null } else { $cur += $ch }
      continue
    }
    if ($ch -eq '"' -or $ch -eq "'") { $quote = $ch; continue }
    if ($ch -eq '>') {
      Flush-Token ([ref]$cur) $tokens $redirects ([ref]$expectTarget)
      if (($i + 1) -lt $seg.Length -and $seg.Substring($i + 1, 1) -eq '>') { $i++ } # '>>'
      $expectTarget = $true
      continue
    }
    if ($ch -eq ' ' -or $ch -eq "`t") {
      Flush-Token ([ref]$cur) $tokens $redirects ([ref]$expectTarget)
      continue
    }
    $cur += $ch
  }
  Flush-Token ([ref]$cur) $tokens $redirects ([ref]$expectTarget)
  return @{ Tokens = $tokens; Redirects = $redirects }
}

# Alvos de escrita de um comando shell (matcher irmao de Bash). Best-effort e honesto:
# cobre os casos comuns; o que nao conseguir parsear com seguranca, nao bloqueia.
function Get-ShellTargets([string]$command) {
  $targets = [System.Collections.Generic.List[string]]::new()
  foreach ($seg in ($command -split '&&|\|\||;|\||\r?\n')) {
    $parsed = Get-ParsedSegment $seg
    $tokens = $parsed.Tokens
    foreach ($r in $parsed.Redirects) { [void]$targets.Add($r) }
    for ($i = 0; $i -lt $tokens.Count; $i++) {
      $t = $tokens[$i].ToLowerInvariant()
      # tee [-flags] arquivo...  /  Tee-Object -FilePath arquivo
      if ($t -eq 'tee' -or $t -eq 'tee-object') {
        for ($j = $i + 1; $j -lt $tokens.Count; $j++) {
          $a = $tokens[$j]
          if ([regex]::IsMatch($a, '^-(?:literal)?(?:file)?path$', 'IgnoreCase') -and ($j + 1) -lt $tokens.Count) {
            [void]$targets.Add($tokens[$j + 1]); $j++; continue
          }
          if (-not $a.StartsWith('-')) { [void]$targets.Add($a) }
        }
      }
      # Set-Content / Add-Content / Out-File: -Path/-LiteralPath ou primeiro posicional.
      if ($t -eq 'set-content' -or $t -eq 'add-content' -or $t -eq 'out-file') {
        $took = $false
        for ($j = $i + 1; ($j -lt $tokens.Count) -and (-not $took); $j++) {
          $a = $tokens[$j]
          if ([regex]::IsMatch($a, '^-(?:literal)?(?:file)?path$', 'IgnoreCase') -and ($j + 1) -lt $tokens.Count) {
            [void]$targets.Add($tokens[$j + 1]); $took = $true
          } elseif (-not $a.StartsWith('-')) {
            [void]$targets.Add($a); $took = $true
          }
        }
      }
      # sed -i / --in-place <arquivo> (ultimo operando nao-flag do segmento).
      if ($t -eq 'sed') {
        $inPlace = $false
        for ($k = $i + 1; $k -lt $tokens.Count; $k++) {
          $x = $tokens[$k]
          if ([regex]::IsMatch($x, '^-i(?:\..*)?$') -or ($x -eq '--in-place') -or [regex]::IsMatch($x, '^-[a-z]*i[a-z]*$', 'IgnoreCase')) { $inPlace = $true; break }
        }
        if ($inPlace) {
          for ($j = $tokens.Count - 1; $j -gt $i; $j--) {
            if (-not $tokens[$j].StartsWith('-')) { [void]$targets.Add($tokens[$j]); break }
          }
        }
      }
    }
  }
  return @($targets | Where-Object { $_ -and (-not $_.StartsWith('-')) })
}

# Bloqueia: motivo + caminho seguro no stderr e exit 2.
function Invoke-Block([string]$reason) {
  [Console]::Error.WriteLine("PelizzAI writegate: escrita bloqueada - $reason")
  [Console]::Error.WriteLine('(Hook opt-in fail-closed de isolamento/kickoff. Se a escrita for legitima fora do fluxo, isole via pelizzai-starting-branch, ratifique o gate, ou desabilite o hook em .claude/settings.json.)')
  exit 2
}

# Aviso best-effort, no maximo 1x por janela e por repo - nunca afeta o exit code.
function Invoke-WarnOnce([string]$gitRoot, [string]$message) {
  try {
    $key = ((Get-Norm $gitRoot).ToLowerInvariant() -replace '[^a-z0-9]', '_')
    if ($key.Length -gt 60) { $key = $key.Substring($key.Length - 60) }
    $statePath = Join-Path ([System.IO.Path]::GetTempPath()) "pelizzai-writegate-$key.json"
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $warnUntil = 0L
    if (Test-Path -LiteralPath $statePath) {
      try { $warnUntil = [long]((Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json).warnUntil) } catch {}
    }
    if ($now -lt $warnUntil) { return }
    [Console]::Error.WriteLine("PelizzAI writegate (aviso): $message")
    try { (@{ warnUntil = ($now + $script:WARN_SNOOZE_MS) } | ConvertTo-Json -Compress) | Set-Content -LiteralPath $statePath -Encoding utf8 } catch {}
  } catch {}
}

try {
  $raw = [Console]::In.ReadToEnd()
  if (-not $raw) { exit 0 }
  $data = $null
  try { $data = $raw | ConvertFrom-Json } catch { exit 0 } # payload ilegivel -> nao trava

  $cwd = (Get-Location).Path
  if (($data.cwd -is [string]) -and $data.cwd) { $cwd = $data.cwd }
  $ti = $data.tool_input

  # Alvos: file_path (Write/Edit/MultiEdit), notebook_path (NotebookEdit), shell (Bash).
  $targets = [System.Collections.Generic.List[string]]::new()
  if (($ti.file_path -is [string]) -and $ti.file_path) { [void]$targets.Add($ti.file_path) }
  if (($ti.notebook_path -is [string]) -and $ti.notebook_path) { [void]$targets.Add($ti.notebook_path) }
  if (($ti.command -is [string]) -and $ti.command) { foreach ($x in (Get-ShellTargets $ti.command)) { [void]$targets.Add($x) } }
  if ($targets.Count -eq 0) { exit 0 } # nada a guardar (ex.: Bash somente leitura)

  $gitRoot = Invoke-Git $cwd @('rev-parse', '--show-toplevel')
  if (-not $gitRoot) { exit 0 } # fora de repo git (scratchpad/externos) ou git ausente -> permite

  # So interessam alvos DENTRO da raiz; scratchpad/temp fora da raiz nunca bloqueia.
  $inRoot = [System.Collections.Generic.List[string]]::new()
  foreach ($t in $targets) {
    $abs = if ([System.IO.Path]::IsPathRooted($t)) { $t } else { Join-Path $cwd $t }
    try { $abs = [System.IO.Path]::GetFullPath($abs) } catch { continue }
    if (Test-Inside $abs $gitRoot) { [void]$inRoot.Add($abs) }
  }
  if ($inRoot.Count -eq 0) { exit 0 }

  # -- Regra A (ambos os modos): branch protegida/destacada bloqueia QUALQUER escrita in-root.
  $branch = Invoke-Git $cwd @('branch', '--show-current') # '' = HEAD destacado (ou sem branch)
  $isProtected = ($branch -eq '') -or ($PROTECTED -contains $branch)
  if (-not $isProtected) {
    # Enriquecimento pelo default do remoto; se falhar, degrada para a lista estatica
    # (NAO para fail-open - a Regra A precisa continuar armada sem origin/HEAD).
    $originHead = Invoke-Git $cwd @('symbolic-ref', '--short', 'refs/remotes/origin/HEAD')
    if ($originHead) {
      $tail = ($originHead -split '/')[-1]
      if ($tail -and ($tail -eq $branch)) { $isProtected = $true }
    }
  }
  if ($isProtected) {
    $b = if ($branch) { $branch } else { 'HEAD destacado' }
    Invoke-Block "branch protegida/destacada ($b). Isole via pelizzai-starting-branch antes de escrever - isolamento antes da primeira escrita e invariante."
  }

  # Source mode (repo-fonte PelizzAI): o marcador vive no execution record -> Regra B pulada.
  $sourceMode = $true
  foreach ($rel in $SOURCE_SENTINELS) {
    if (-not (Test-Path -LiteralPath (Join-Path $gitRoot $rel))) { $sourceMode = $false; break }
  }
  if ($sourceMode) { exit 0 }

  # -- Regra B (so consumidor): escrita de PRODUTO exige kickoff ratificado no state.md.
  $pelizzaiDir = Join-Path $gitRoot 'pelizzai'
  $products = @($inRoot | Where-Object { -not (Test-Inside $_ $pelizzaiDir) })
  if ($products.Count -eq 0) { exit 0 } # so artefatos de setup em pelizzai/ -> liberado

  $statePath = Join-Path $gitRoot 'pelizzai/data/state.md'
  if (-not (Test-Path -LiteralPath $statePath)) {
    # Consumidor sem state.md: nao da para ler o kickoff com seguranca -> fail-open + aviso 1x.
    Invoke-WarnOnce $gitRoot 'sem pelizzai/data/state.md para verificar o kickoff; permitindo a escrita. Se este projeto usa o harness, conduza o gate de kickoff e registre "kickoff: ratificado" antes de escrever produto.'
    exit 0
  }
  $state = ''
  try { $state = Get-Content -LiteralPath $statePath -Raw } catch { exit 0 } # nao leu o marcador -> fail-open
  if ([regex]::IsMatch($state, $KICKOFF_RATIFIED, 'IgnoreCase')) { exit 0 } # kickoff ratificado -> liberado

  Invoke-Block 'o kickoff ainda nao foi ratificado (falta "kickoff: ratificado" em pelizzai/data/state.md). Conduza o gate de kickoff/pos-plano COM o usuario - isolamento, modo de execucao e estrategia de commit -, grave "kickoff: ratificado" em pelizzai/data/state.md e entao escreva o codigo.'
} catch {
  # fail-open: erro do proprio hook nunca trava o usuario
}
exit 0
