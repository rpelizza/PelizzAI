#!/usr/bin/env pwsh
# PelizzAI - review-package: empacota o material de review em arquivo.
#
# Uso: pwsh scripts/review-package.ps1 <BASE> <HEAD>
#      pwsh scripts/review-package.ps1 --working-tree
#
# Grava no handoff dir seguro (gitignored no consumidor; temp em source mode):
#  - modo range: a lista de commits do range, o `git diff --stat` e o `git diff -U10`;
#  - modo --working-tree: status + diffs staged e unstaged + o CONTEUDO dos untracked.
# Imprime o caminho gravado. O revisor le o ARQUIVO - o diff nunca e colado no
# contexto do coordenador.
#
# Os blocos usam fence de 4 backticks: diffs de arquivos .md contem ``` e quebrariam
# um fence de 3.
#
# IMPORTANTE - range e exclusivo do review final. BASE e o `base-sha` persistido no
# state quando a branch foi criada. Review por tarefa usa --working-tree. NUNCA use
# HEAD~1: isso descartaria silenciosamente parte da entrega.
#
# Requer PowerShell 7+. Variante POSIX: scripts/review-package.sh.

# Sem bloco param(): "--working-tree" seria interpretado pelo binder do PowerShell
# como nome de parametro. Os argumentos chegam crus em $args.
$Base = if ($args.Count -ge 1) { [string]$args[0] } else { '' }
$Head = if ($args.Count -ge 2) { [string]$args[1] } else { '' }

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

function Fail([string]$Message) {
  [Console]::Error.WriteLine("review-package: $Message")
  exit 1
}

function Get-HandoffDir {
  if ($env:PELIZZAI_HANDOFF_DIR) { return [IO.Path]::GetFullPath($env:PELIZZAI_HANDOFF_DIR) }
  $projectIgnore = Join-Path (Get-Location).Path 'pelizzai/.gitignore'
  if (Test-Path -LiteralPath $projectIgnore -PathType Leaf) {
    git check-ignore -q -- 'pelizzai/data/handoffs/.pelizzai-probe' 2>$null
    if ($LASTEXITCODE -eq 0) { return (Join-Path (Get-Location).Path 'pelizzai/data/handoffs') }
  }
  $identity = try { (git rev-parse --show-toplevel 2>$null | Select-Object -First 1) } catch { $null }
  if (-not $identity) { $identity = (Get-Location).Path }
  $bytes = [Text.Encoding]::UTF8.GetBytes([string]$identity)
  $sha = [Security.Cryptography.SHA256]::Create()
  try { $digest = $sha.ComputeHash($bytes) } finally { $sha.Dispose() }
  $hash = (-join ($digest | ForEach-Object { $_.ToString('x2') })).Substring(0, 12)
  return (Join-Path ([IO.Path]::GetTempPath()) "pelizzai-handoffs/$hash")
}

git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { Fail 'nao e um repositorio git (rode a partir da raiz do projeto)' }

$workingTree = ($Base -eq '--working-tree')
if (-not $workingTree) {
  if (-not $Base -or -not $Head) { Fail 'uso: review-package.ps1 <BASE> <HEAD> | review-package.ps1 --working-tree' }
  git rev-parse --verify --quiet "$Base^{commit}" *> $null
  if ($LASTEXITCODE -ne 0) { Fail "BASE invalido: $Base" }
  git rev-parse --verify --quiet "$Head^{commit}" *> $null
  if ($LASTEXITCODE -ne 0) { Fail "HEAD invalido: $Head" }
}

$outDir = Get-HandoffDir
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$stem = Join-Path $outDir "review-$stamp-$PID"
$outPath = "$stem.md"
$collision = 0
while (Test-Path -LiteralPath $outPath) {
  $collision++
  $outPath = "$stem-$collision.md"
}
$now = Get-Date -Format 'yyyy-MM-dd HH:mm'

function Add-Block([System.Collections.Generic.List[string]]$List, [string]$Title, [string]$Fence, $Body) {
  $List.Add("## $Title")
  $List.Add('')
  $List.Add('````' + $Fence)
  foreach ($l in @($Body)) { if ($null -ne $l) { $List.Add([string]$l) } }
  $List.Add('````')
  $List.Add('')
}

function Test-SensitiveUntracked([string]$Path) {
  $leaf = [IO.Path]::GetFileName($Path).ToLowerInvariant()
  if ($leaf -in @('.env.example', '.env.sample', '.env.template')) { return $false }
  if ($leaf -eq '.env' -or $leaf.StartsWith('.env.')) { return $true }
  if ($leaf -in @('.npmrc', '.pypirc', '.netrc', 'credentials.json', 'id_rsa', 'id_ed25519')) { return $true }
  if ($leaf -match '^(secret|secrets)\.(json|ya?ml|toml|ini)$') { return $true }
  return ([IO.Path]::GetExtension($leaf) -in @('.pem', '.key', '.p12', '.pfx'))
}

$content = [System.Collections.Generic.List[string]]::new()
if ($workingTree) {
  $content.Add('# Pacote de review - working tree')
  $content.Add('')
  $content.Add("> Gerado em $now. Mudancas ainda nao commitadas da working tree.")
  $content.Add('')
  Add-Block $content 'git status --short' 'text' (git status --short)
  Add-Block $content 'Staged - git diff --cached -U10' 'diff' (git diff --cached -U10)
  Add-Block $content 'Unstaged - git diff -U10' 'diff' (git diff -U10)
  $content.Add('## Arquivos novos (untracked) - conteudo')
  $content.Add('')
  # Exclui o proprio diretorio de handoffs (o pacote em escrita nao entra no pacote).
  $untracked = @(git ls-files --others --exclude-standard | Where-Object { $_ -notlike 'pelizzai/data/handoffs/*' })
  if ($untracked.Count -gt 0) {
    foreach ($f in $untracked) {
      $content.Add("### $f")
      $content.Add('')
      $item = $null
      try { $item = Get-Item -LiteralPath $f -Force -ErrorAction Stop } catch {}
      if ($item -and $item.LinkType) {
        $content.Add('_link simbólico — conteúdo omitido para não ler fora do repositório._')
        $content.Add('')
        continue
      }
      if (Test-SensitiveUntracked $f) {
        $content.Add('_arquivo potencialmente sensível — conteúdo omitido; revise o path localmente._')
        $content.Add('')
        continue
      }
      if ($item -and $item.Length -gt 262144) {
        $content.Add("_arquivo maior que 256 KiB ($($item.Length) bytes) — conteúdo omitido._")
        $content.Add('')
        continue
      }
      $text = $null
      try { $text = Get-Content -LiteralPath $f -Raw -ErrorAction Stop } catch {}
      if ($null -ne $text -and $text -notmatch "`0") {
        $content.Add('````text')
        foreach ($l in ($text -split "`r?`n")) { $content.Add($l) }
        $content.Add('````')
      } else {
        $content.Add('_binario ou ilegivel - conteudo omitido._')
      }
      $content.Add('')
    }
  } else {
    $content.Add('_Nenhum._')
  }
} else {
  $content.Add("# Pacote de review - $Base..$Head")
  $content.Add('')
  $content.Add("> Gerado em $now. Range final: BASE = base-sha persistido no state - nunca HEAD~1.")
  $content.Add('')
  Add-Block $content "Commits ($Base..$Head)" 'text' (git log --oneline "$Base..$Head")
  Add-Block $content 'git diff --stat' 'text' (git diff --stat "$Base" "$Head")
  Add-Block $content 'git diff -U10' 'diff' (git diff -U10 "$Base" "$Head")
}

Set-Content -LiteralPath $outPath -Value ($content -join "`n") -Encoding utf8
Write-Output $outPath
