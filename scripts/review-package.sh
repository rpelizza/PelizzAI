#!/bin/sh
# PelizzAI — review-package: packages the review material into a file (POSIX variant).
#
# Usage: sh scripts/review-package.sh <BASE> <HEAD>
#        sh scripts/review-package.sh --working-tree
#
# Writes to the safe handoff dir (gitignored in the consumer; temp in source mode):
#  - range mode: the range's commit list, the `git diff --stat` and the `git diff -U10`;
#  - --working-tree mode: status + staged and unstaged diffs + the CONTENT of untracked files.
# Prints the written path. The reviewer reads the FILE — the diff is never pasted into
# the coordinator's context.
#
# Blocks use a 4-backtick fence: diffs of .md files contain ``` and would break
# a 3-backtick fence.
#
# IMPORTANT — range is exclusive to the final review. BASE is the `base-sha` persisted in
# the state when the branch was created. Per-task review uses --working-tree. NEVER use
# HEAD~1: that would silently discard part of the delivery.
#
# PowerShell equivalent: scripts/review-package.ps1.

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
    printf '%s\n' "${TMPDIR:-/tmp}/pelizzai-continuitys-$key"
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

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "not a git repository (run from the project root)"

BASE=${1:-}
HEAD=${2:-}
MODE=range
if [ "$BASE" = "--working-tree" ]; then
  MODE=wt
else
  { [ -n "$BASE" ] && [ -n "$HEAD" ]; } || fail "usage: review-package.sh <BASE> <HEAD> | review-package.sh --working-tree"
  git rev-parse --verify --quiet "$BASE^{commit}" >/dev/null || fail "invalid BASE: $BASE"
  git rev-parse --verify --quiet "$HEAD^{commit}" >/dev/null || fail "invalid HEAD: $HEAD"
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
    echo "# Review package — working tree"
    echo
    echo "> Generated at $NOW. Working-tree changes not yet committed."
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
    echo "## New files (untracked) — content"
    echo
    UNTRACKED=$(git ls-files --others --exclude-standard | grep -v '^pelizzai/data/handoffs/' || true)
    if [ -n "$UNTRACKED" ]; then
      printf '%s\n' "$UNTRACKED" | while IFS= read -r f; do
        echo "### $f"
        echo
        if [ -L "$f" ]; then
          echo "_symbolic link — content omitted to avoid reading outside the repository._"
        elif is_sensitive_untracked "$f"; then
          echo "_potentially sensitive file — content omitted; review the path locally._"
        elif [ "$(wc -c < "$f" | tr -d ' ')" -gt 262144 ]; then
          echo "_file larger than 256 KiB — content omitted._"
        elif grep -Iq '' "$f" 2>/dev/null; then
          echo '````text'
          cat "$f"
          echo '````'
        else
          echo "_binary — content omitted._"
        fi
        echo
      done
    else
      echo "_None._"
    fi
  else
    echo "# Review package — $BASE..$HEAD"
    echo
    echo "> Generated at $NOW. Final range: BASE = base-sha persisted in the state — never HEAD~1."
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
