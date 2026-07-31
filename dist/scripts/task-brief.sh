#!/bin/sh
# PelizzAI — task-brief: file-based handoff of the task briefing (POSIX variant).
#
# Usage: sh scripts/task-brief.sh <plan-path> <N>
#
# Extracts from the plan (pelizzai/plans/*.md) the text of Task N — from the
# "### Task N: ..." header to the next header of the same (or higher) level or EOF —
# PLUS the "Global Constraints" block from the plan header (every task inherits it),
# and writes it to the safe handoff dir (gitignored in the consumer; temp in source mode).
# Prints the written path. Fails with a clear message if the plan does not exist
# or the task is not found.
#
# Why a file, not pasting: everything that enters by pasting stays resident in the
# coordinator's context forever (gain measured at the source: ~2x faster,
# ~50% fewer tokens). See pelizzai-execution-plans -> references/task-cycle.md, section 1.
#
# PowerShell equivalent: scripts/task-brief.ps1.

set -u

fail() { echo "task-brief: $1" >&2; exit 1; }

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

[ $# -eq 2 ] || fail "usage: task-brief.sh <plan-path> <N>"
PLAN=$1
N=$2

case $N in
  ''|*[!0-9]*) fail "invalid N: '$N' (expected the task number, e.g. 3)" ;;
esac

[ -f "$PLAN" ] || fail "plan not found: $PLAN"

# Global Constraints block from the plan header: from the "**Global Constraints" line to the first '---' or header.
# Lines starting with ``` toggle the code-fence state; headers/separators INSIDE a
# fence (e.g. a shell/python '#' comment at column zero) do not end the block.
GC=$(awk '
  /^```/ { in_fence = !in_fence }
  in_block && !in_fence && ($0 ~ /^---[ \t]*$/ || $0 ~ /^#/) { exit }
  $0 ~ /\*\*Global Constraints/ { in_block = 1 }
  in_block { print }
' "$PLAN")

# Task N: from the "### Task N" header to the next header of level <= 3 (OUTSIDE code fences) or EOF.
TASK=$(awk -v n="$N" '
  /^```/ { in_fence = !in_fence }
  in_task && !in_fence && ($0 ~ /^# / || $0 ~ /^## / || $0 ~ /^### /) { exit }
  !in_task && !in_fence && $0 ~ ("^###[ \t]+Task[ \t]+" n "([^0-9]|$)") { in_task = 1 }
  in_task { print }
' "$PLAN")

[ -n "$TASK" ] || fail "Task $N not found in $PLAN (expected a header '### Task $N: ...')"

OUT_DIR=$(handoff_dir)
mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/task-$N-brief.md"

{
  echo "# Brief — Task $N"
  echo
  echo "> Generated from \`$PLAN\` at $(date '+%Y-%m-%d %H:%M'). The member reads THIS file — never the whole plan."
  echo
  echo "## Global Constraints (inherited from the plan header)"
  echo
  if [ -n "$GC" ]; then printf '%s\n' "$GC"; else echo "_The plan has no Global Constraints block._"; fi
  echo
  echo "## Task"
  echo
  printf '%s\n' "$TASK"
  echo
  echo "---"
  echo
  echo "Report: write the result to \`$OUT_DIR/task-$N-report.md\` (mirroring this brief) and reply in chat in at most 15 lines."
} > "$OUT"

echo "$OUT"
