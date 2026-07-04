#!/usr/bin/env pwsh
# PelizzAI - review-package: empacota o material de review em arquivo.
#
# Uso: pwsh scripts/review-package.ps1 <BASE> <HEAD>
#      pwsh scripts/review-package.ps1 --working-tree
#
# Grava em pelizzai/data/handoffs/review-<timestamp>.md (gitignored):
#  - modo range: a lista de commits do range, o `git diff --stat` e o `git diff -U10`;
#  - modo --working-tree: `git status --short` + `git diff -U10` + o CONTEUDO dos
#    arquivos novos (untracked) - o escopo B da pelizzai-review cobre "diff + arquivos novos".
# Imprime o caminho gravado. O revisor le o ARQUIVO - o diff nunca e colado no
# contexto do coordenador.
#
# Os blocos usam fence de 4 backticks: diffs de arquivos .md contem ``` e quebrariam
# um fence de 3.
#
# IMPORTANTE - captura do BASE: o BASE e capturado ANTES do despacho do implementador
# (`git rev-parse HEAD` no momento do dispatch). NUNCA use `HEAD~1` como base: isso
# descarta silenciosamente tudo menos o ultimo commit (uma tarefa com N commits, ou o
# range de varias tarefas, ficaria fora do review).
#
# Requer PowerShell 7+. Variante POSIX: scripts/review-package.sh.

# Sem bloco param(): "--working-tree" seria interpretado pelo binder do PowerShell
# como nome de parametro. Os argumentos chegam crus em $args.
$Base = if ($args.Count -ge 1) { [string]$args[0] } else { '' }
$Head = if ($args.Count -ge 2) { [string]$args[1] } else { '' }

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
  [Console]::Error.WriteLine("review-package: $Message")
  exit 1
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

$outDir = Join-Path 'pelizzai' (Join-Path 'data' 'handoffs')
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$outPath = Join-Path $outDir "review-$stamp.md"
$now = Get-Date -Format 'yyyy-MM-dd HH:mm'

function Add-Block([System.Collections.Generic.List[string]]$List, [string]$Title, [string]$Fence, $Body) {
  $List.Add("## $Title")
  $List.Add('')
  $List.Add('````' + $Fence)
  foreach ($l in @($Body)) { if ($null -ne $l) { $List.Add([string]$l) } }
  $List.Add('````')
  $List.Add('')
}

$content = [System.Collections.Generic.List[string]]::new()
if ($workingTree) {
  $content.Add('# Pacote de review - working tree')
  $content.Add('')
  $content.Add("> Gerado em $now. Mudancas ainda nao commitadas da working tree.")
  $content.Add('')
  Add-Block $content 'git status --short' 'text' (git status --short)
  Add-Block $content 'git diff -U10' 'diff' (git diff -U10)
  $content.Add('## Arquivos novos (untracked) - conteudo')
  $content.Add('')
  # Exclui o proprio diretorio de handoffs (o pacote em escrita nao entra no pacote).
  $untracked = @(git ls-files --others --exclude-standard | Where-Object { $_ -notlike 'pelizzai/data/handoffs/*' })
  if ($untracked.Count -gt 0) {
    foreach ($f in $untracked) {
      $content.Add("### $f")
      $content.Add('')
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
  $content.Add("> Gerado em $now. BASE capturado ANTES do despacho (git rev-parse HEAD) - nunca HEAD~1.")
  $content.Add('')
  Add-Block $content "Commits ($Base..$Head)" 'text' (git log --oneline "$Base..$Head")
  Add-Block $content 'git diff --stat' 'text' (git diff --stat "$Base" "$Head")
  Add-Block $content 'git diff -U10' 'diff' (git diff -U10 "$Base" "$Head")
}

Set-Content -LiteralPath $outPath -Value ($content -join "`n") -Encoding utf8
Write-Output $outPath
