#!/usr/bin/env pwsh
# PelizzAI - task-brief: handoff por arquivo do briefing de tarefa.
#
# Uso: pwsh scripts/task-brief.ps1 <caminho-do-plano> <N>
#
# Extrai do plano (pelizzai/plans/*.md) o texto da Tarefa N - do header
# "### Tarefa N: ..." ate o proximo header de mesmo nivel (ou superior) ou EOF -
# MAIS o bloco "Global Constraints" do cabecalho do plano (toda tarefa o herda),
# e grava em pelizzai/data/handoffs/task-<N>-brief.md (gitignored).
# Imprime o caminho gravado. Falha com mensagem clara se o plano nao existir
# ou a tarefa nao for encontrada.
#
# Por que arquivo, e nao colagem: tudo que entra por colagem fica residente no
# contexto do coordenador para sempre (ganho medido na fonte: ~2x mais rapido,
# ~50% menos tokens). Ver pelizzai-execution-plans -> references/task-cycle.md, secao 1.
#
# Requer PowerShell 7+. Variante POSIX: scripts/task-brief.sh.

[CmdletBinding()]
param(
  [Parameter(Position = 0)][string]$PlanPath,
  [Parameter(Position = 1)][string]$TaskNumber
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
  [Console]::Error.WriteLine("task-brief: $Message")
  exit 1
}

if (-not $PlanPath -or -not $TaskNumber) { Fail 'uso: task-brief.ps1 <caminho-do-plano> <N>' }
if ($TaskNumber -notmatch '^[0-9]+$') { Fail "N invalido: '$TaskNumber' (esperado o numero da tarefa, ex.: 3)" }
if (-not (Test-Path -LiteralPath $PlanPath -PathType Leaf)) { Fail "plano nao encontrado: $PlanPath" }

$lines = Get-Content -LiteralPath $PlanPath

# Bloco Global Constraints do cabecalho: da linha "**Global Constraints" ate o primeiro '---' ou header.
# Linhas que comecam com ``` alternam o estado de code fence; headers/separadores DENTRO de
# fence (ex.: comentario '#' de shell/python na coluna zero) nao encerram o bloco.
$gc = [System.Collections.Generic.List[string]]::new()
$inGc = $false
$inFence = $false
foreach ($line in $lines) {
  if ($line -match '^```') { $inFence = -not $inFence }
  if ($inGc -and -not $inFence -and ($line -match '^---\s*$' -or $line -match '^#')) { break }
  if (-not $inGc -and $line -match '\*\*Global Constraints') { $inGc = $true }
  if ($inGc) { $gc.Add($line) }
}

# Tarefa N: do header "### Tarefa N" ate o proximo header de nivel <= 3 (FORA de code fence) ou EOF.
$task = [System.Collections.Generic.List[string]]::new()
$inTask = $false
$inFence = $false
foreach ($line in $lines) {
  if ($line -match '^```') { $inFence = -not $inFence }
  if (-not $inTask) {
    if (-not $inFence -and $line -match "^###\s+Tarefa\s+$TaskNumber\b") { $inTask = $true; $task.Add($line) }
    continue
  }
  if (-not $inFence -and $line -match '^#{1,3}\s') { break }
  $task.Add($line)
}

if (-not $inTask) { Fail "Tarefa $TaskNumber nao encontrada em $PlanPath (esperado um header '### Tarefa ${TaskNumber}: ...')" }

$outDir = Join-Path 'pelizzai' (Join-Path 'data' 'handoffs')
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outPath = Join-Path $outDir "task-$TaskNumber-brief.md"

$now = Get-Date -Format 'yyyy-MM-dd HH:mm'
$content = [System.Collections.Generic.List[string]]::new()
$content.Add("# Brief - Tarefa $TaskNumber")
$content.Add('')
$content.Add("> Gerado de ``$PlanPath`` em $now. O membro le ESTE arquivo - nunca o plano inteiro.")
$content.Add('')
$content.Add('## Global Constraints (herdadas do cabecalho do plano)')
$content.Add('')
if ($gc.Count -gt 0) { foreach ($l in $gc) { $content.Add($l) } }
else { $content.Add('_O plano nao tem bloco Global Constraints._') }
$content.Add('')
$content.Add('## Tarefa')
$content.Add('')
foreach ($l in $task) { $content.Add($l) }
$content.Add('')
$content.Add('---')
$content.Add('')
$content.Add("Relatorio: grave o resultado em ``pelizzai/data/handoffs/task-$TaskNumber-report.md`` (espelhando este brief) e responda no chat em, no maximo, 15 linhas.")

Set-Content -LiteralPath $outPath -Value ($content -join "`n") -Encoding utf8
Write-Output $outPath
