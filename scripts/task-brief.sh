#!/bin/sh
# PelizzAI — task-brief: handoff por arquivo do briefing de tarefa (variante POSIX).
#
# Uso: sh scripts/task-brief.sh <caminho-do-plano> <N>
#
# Extrai do plano (pelizzai/plans/*.md) o texto da Tarefa N — do header
# "### Tarefa N: ..." até o próximo header de mesmo nível (ou superior) ou EOF —
# MAIS o bloco "Global Constraints" do cabeçalho do plano (toda tarefa o herda),
# e grava em pelizzai/data/handoffs/task-<N>-brief.md (gitignored).
# Imprime o caminho gravado. Falha com mensagem clara se o plano não existir
# ou a tarefa não for encontrada.
#
# Por que arquivo, e não colagem: tudo que entra por colagem fica residente no
# contexto do coordenador para sempre (ganho medido na fonte: ~2x mais rápido,
# ~50% menos tokens). Ver pelizzai-execution-plans -> references/task-cycle.md, seção 1.
#
# Equivalente PowerShell: scripts/task-brief.ps1.

set -u

fail() { echo "task-brief: $1" >&2; exit 1; }

[ $# -eq 2 ] || fail "uso: task-brief.sh <caminho-do-plano> <N>"
PLAN=$1
N=$2

case $N in
  ''|*[!0-9]*) fail "N inválido: '$N' (esperado o número da tarefa, ex.: 3)" ;;
esac

[ -f "$PLAN" ] || fail "plano não encontrado: $PLAN"

# Bloco Global Constraints do cabeçalho: da linha "**Global Constraints" até o primeiro '---' ou header.
# Linhas que começam com ``` alternam o estado de code fence; headers/separadores DENTRO de
# fence (ex.: comentário '#' de shell/python na coluna zero) não encerram o bloco.
GC=$(awk '
  /^```/ { in_fence = !in_fence }
  in_block && !in_fence && ($0 ~ /^---[ \t]*$/ || $0 ~ /^#/) { exit }
  $0 ~ /\*\*Global Constraints/ { in_block = 1 }
  in_block { print }
' "$PLAN")

# Tarefa N: do header "### Tarefa N" até o próximo header de nível <= 3 (FORA de code fence) ou EOF.
TASK=$(awk -v n="$N" '
  /^```/ { in_fence = !in_fence }
  in_task && !in_fence && ($0 ~ /^# / || $0 ~ /^## / || $0 ~ /^### /) { exit }
  !in_task && !in_fence && $0 ~ ("^###[ \t]+Tarefa[ \t]+" n "([^0-9]|$)") { in_task = 1 }
  in_task { print }
' "$PLAN")

[ -n "$TASK" ] || fail "Tarefa $N não encontrada em $PLAN (esperado um header '### Tarefa $N: ...')"

OUT_DIR="pelizzai/data/handoffs"
mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/task-$N-brief.md"

{
  echo "# Brief — Tarefa $N"
  echo
  echo "> Gerado de \`$PLAN\` em $(date '+%Y-%m-%d %H:%M'). O membro lê ESTE arquivo — nunca o plano inteiro."
  echo
  echo "## Global Constraints (herdadas do cabeçalho do plano)"
  echo
  if [ -n "$GC" ]; then printf '%s\n' "$GC"; else echo "_O plano não tem bloco Global Constraints._"; fi
  echo
  echo "## Tarefa"
  echo
  printf '%s\n' "$TASK"
  echo
  echo "---"
  echo
  echo "Relatório: grave o resultado em \`pelizzai/data/handoffs/task-$N-report.md\` (espelhando este brief) e responda no chat em, no máximo, 15 linhas."
} > "$OUT"

echo "$OUT"
