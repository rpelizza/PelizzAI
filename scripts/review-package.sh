#!/bin/sh
# PelizzAI — review-package: empacota o material de review em arquivo (variante POSIX).
#
# Uso: sh scripts/review-package.sh <BASE> <HEAD>
#      sh scripts/review-package.sh --working-tree
#
# Grava em pelizzai/data/handoffs/review-<timestamp>.md (gitignored):
#  - modo range: a lista de commits do range, o `git diff --stat` e o `git diff -U10`;
#  - modo --working-tree: `git status --short` + `git diff -U10` + o CONTEÚDO dos
#    arquivos novos (untracked) — o escopo B da pelizzai-review cobre "diff + arquivos novos".
# Imprime o caminho gravado. O revisor lê o ARQUIVO — o diff nunca é colado no
# contexto do coordenador.
#
# Os blocos usam fence de 4 backticks: diffs de arquivos .md contêm ``` e quebrariam
# um fence de 3.
#
# IMPORTANTE — captura do BASE: o BASE é capturado ANTES do despacho do implementador
# (`git rev-parse HEAD` no momento do dispatch). NUNCA use `HEAD~1` como base: isso
# descarta silenciosamente tudo menos o último commit (uma tarefa com N commits, ou o
# range de várias tarefas, ficaria fora do review).
#
# Equivalente PowerShell: scripts/review-package.ps1.

set -u

fail() { echo "review-package: $1" >&2; exit 1; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "não é um repositório git (rode a partir da raiz do projeto)"

BASE=${1:-}
HEAD=${2:-}
MODE=range
if [ "$BASE" = "--working-tree" ]; then
  MODE=wt
else
  { [ -n "$BASE" ] && [ -n "$HEAD" ]; } || fail "uso: review-package.sh <BASE> <HEAD> | review-package.sh --working-tree"
  git rev-parse --verify --quiet "$BASE^{commit}" >/dev/null || fail "BASE inválido: $BASE"
  git rev-parse --verify --quiet "$HEAD^{commit}" >/dev/null || fail "HEAD inválido: $HEAD"
fi

OUT_DIR="pelizzai/data/handoffs"
mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/review-$(date '+%Y%m%d-%H%M%S').md"
NOW=$(date '+%Y-%m-%d %H:%M')

{
  if [ "$MODE" = "wt" ]; then
    echo "# Pacote de review — working tree"
    echo
    echo "> Gerado em $NOW. Mudanças ainda não commitadas da working tree."
    echo
    echo "## git status --short"
    echo
    echo '````text'
    git status --short
    echo '````'
    echo
    echo "## git diff -U10"
    echo
    echo '````diff'
    git diff -U10
    echo '````'
    echo
    echo "## Arquivos novos (untracked) — conteúdo"
    echo
    UNTRACKED=$(git ls-files --others --exclude-standard | grep -v '^pelizzai/data/handoffs/' || true)
    if [ -n "$UNTRACKED" ]; then
      printf '%s\n' "$UNTRACKED" | while IFS= read -r f; do
        echo "### $f"
        echo
        if grep -Iq '' "$f" 2>/dev/null; then
          echo '````text'
          cat "$f"
          echo '````'
        else
          echo "_binário — conteúdo omitido._"
        fi
        echo
      done
    else
      echo "_Nenhum._"
    fi
  else
    echo "# Pacote de review — $BASE..$HEAD"
    echo
    echo "> Gerado em $NOW. BASE capturado ANTES do despacho (git rev-parse HEAD) — nunca HEAD~1."
    echo
    echo "## Commits ($BASE..$HEAD)"
    echo
    echo '````text'
    git log --oneline "$BASE..$HEAD"
    echo '````'
    echo
    echo "## git diff --stat"
    echo
    echo '````text'
    git diff --stat "$BASE" "$HEAD"
    echo '````'
    echo
    echo "## git diff -U10"
    echo
    echo '````diff'
    git diff -U10 "$BASE" "$HEAD"
    echo '````'
  fi
} > "$OUT"

echo "$OUT"
