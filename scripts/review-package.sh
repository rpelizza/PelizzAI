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
# Blocks use a DYNAMIC fence: one backtick more than the longest backtick run found in the
# content, never below 4. A fixed fence breaks the moment the content itself carries a run of
# the same length (markdown files in this very repo use 4-backtick fences).
#
# IMPORTANT — range is exclusive to the final review. BASE is the `base-sha` persisted in
# the state when the branch was created. Per-task review uses --working-tree. NEVER use
# HEAD~1: that would silently discard part of the delivery.
#
# PowerShell equivalent: scripts/review-package.ps1.

set -u
# The handoff package can carry the content of untracked files; under a permissive umask the
# directory and the file would be readable by other local users. 077 keeps both private.
umask 077

fail() { echo "review-package: $1" >&2; exit 1; }

# One backtick more than the longest run in the content, never below 4.
fence_for() {
  n=$(printf '%s' "$1" | grep -o '`\{1,\}' 2>/dev/null | awk '{ if (length > m) m = length } END { print m + 0 }')
  [ -z "$n" ] && n=0
  [ "$n" -lt 3 ] && n=3
  awk -v n="$((n + 1))" 'BEGIN { while (n-- > 0) printf "`"; print "" }'
}

emit_block() { # $1 title, $2 fence language, $3 content
  _fence=$(fence_for "$3")
  echo "## $1"
  echo
  printf '%s%s\n' "$_fence" "$2"
  [ -n "$3" ] && printf '%s\n' "$3"
  printf '%s\n' "$_fence"
  echo
}

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
# Shared-temp hygiene: never follow a symlink planted at the handoff path, keep the directory
# private (0700), and require ownership when it pre-existed.
[ -L "$OUT_DIR" ] && fail "handoff dir is a symlink: $OUT_DIR"
mkdir -p "$OUT_DIR"
chmod 700 "$OUT_DIR" 2>/dev/null || true
[ -n "$(find "$OUT_DIR" -maxdepth 0 -user "$(id -un)" 2>/dev/null)" ] || fail "handoff dir is not owned by the current user: $OUT_DIR"
STEM="$OUT_DIR/review-$(date '+%Y%m%d-%H%M%S')-$$"
OUT="$STEM.md"
COLLISION=0
while [ -e "$OUT" ]; do
  COLLISION=$((COLLISION + 1))
  OUT="$STEM-$COLLISION.md"
done
NOW=$(date '+%Y-%m-%d %H:%M')

# Written to a private temporary (0600 under umask 077) and moved into place atomically.
TMP_OUT="$OUT.tmp.$$"
{
  if [ "$MODE" = "wt" ]; then
    echo "# Review package — working tree"
    echo
    echo "> Generated at $NOW. Working-tree changes not yet committed."
    echo
    emit_block "git status --short" "text" "$(git status --short)"
    emit_block "Staged — git diff --cached -U10" "diff" "$(git diff --cached -U10)"
    emit_block "Unstaged — git diff -U10" "diff" "$(git diff -U10)"
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
          FILE_CONTENT=$(cat "$f")
          FILE_FENCE=$(fence_for "$FILE_CONTENT")
          printf '%stext\n' "$FILE_FENCE"
          printf '%s\n' "$FILE_CONTENT"
          printf '%s\n' "$FILE_FENCE"
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
    emit_block "Commits ($BASE..$HEAD)" "text" "$(git log --oneline "$BASE..$HEAD")"
    emit_block "git diff --stat" "text" "$(git diff --stat "$BASE" "$HEAD")"
    emit_block "git diff -U10" "diff" "$(git diff -U10 "$BASE" "$HEAD")"
  fi
} > "$TMP_OUT"
mv -f "$TMP_OUT" "$OUT"

echo "$OUT"
