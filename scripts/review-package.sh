#!/bin/sh
# PelizzAI — review-package: empacota o material de review em arquivo (variante POSIX).
#
# Uso: sh scripts/review-package.sh <BASE> <HEAD>
#      sh scripts/review-package.sh --working-tree
#
# Grava no handoff dir seguro (gitignored no consumidor; temp em source mode):
#  - modo range: a lista de commits do range, o `git diff --stat` e o `git diff -U10`;
#  - modo --working-tree: status + diffs staged e unstaged + o CONTEÚDO dos untracked.
# Imprime o caminho gravado. O revisor lê o ARQUIVO — o diff nunca é colado no
# contexto do coordenador.
#
# Os blocos usam fence de 4 backticks: diffs de arquivos .md contêm ``` e quebrariam
# um fence de 3.
#
# IMPORTANTE — range é exclusivo do review final. BASE é o `base-sha` persistido no
# state quando a branch foi criada. Review por tarefa usa --working-tree. NUNCA use
# HEAD~1: isso descartaria silenciosamente parte da entrega.
#
# Equivalente PowerShell: scripts/review-package.ps1.

set -u

fail() { echo "review-package: $1" >&2; exit 1; }

handoff_dir() {
  if [ -n "${PELIZZAI_HANDOFF_DIR:-}" ]; then
    printf '%s\n' "$PELIZZAI_HANDOFF_DIR"
  elif [ -f 'pelizzai/.gitignore' ] && git check-ignore -q -- 'pelizzai/data/handoffs/.pelizzai-probe' 2>/dev/null; then
    printf '%s\n' "$(pwd -P)/pelizzai/data/handoffs"
  else
    identity=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
    key=$(printf '%s' "$identity" | cksum | awk '{print $1}')
    printf '%s\n' "${TMPDIR:-/tmp}/pelizzai-handoffs-$key"
  fi
}

is_sensitive_untracked() {
  leaf=${1##*/}
  case "$leaf" in
    .env.example|.env.sample|.env.template) return 1 ;;
    .env|.env.*|.npmrc|.pypirc|.netrc|credentials.json|id_rsa|id_ed25519|secret.json|secret.yaml|secret.yml|secret.toml|secret.ini|secrets.json|secrets.yaml|secrets.yml|secrets.toml|secrets.ini|*.pem|*.key|*.p12|*.pfx) return 0 ;;
    *) return 1 ;;
  esac
}

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

OUT_DIR=$(handoff_dir)
mkdir -p "$OUT_DIR"
STEM="$OUT_DIR/review-$(date '+%Y%m%d-%H%M%S')-$$"
OUT="$STEM.md"
COLLISION=0
while [ -e "$OUT" ]; do
  COLLISION=$((COLLISION + 1))
  OUT="$STEM-$COLLISION.md"
done
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
    echo "## Staged — git diff --cached -U10"
    echo
    echo '````diff'
    git diff --cached -U10
    echo '````'
    echo
    echo "## Unstaged — git diff -U10"
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
        if [ -L "$f" ]; then
          echo "_link simbólico — conteúdo omitido para não ler fora do repositório._"
        elif is_sensitive_untracked "$f"; then
          echo "_arquivo potencialmente sensível — conteúdo omitido; revise o path localmente._"
        elif [ "$(wc -c < "$f" | tr -d ' ')" -gt 262144 ]; then
          echo "_arquivo maior que 256 KiB — conteúdo omitido._"
        elif grep -Iq '' "$f" 2>/dev/null; then
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
    echo "> Gerado em $NOW. Range final: BASE = base-sha persistido no state — nunca HEAD~1."
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
