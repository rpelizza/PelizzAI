---
name: pelizzai-resume
description: Safely reconciles divergences between the task record and Git after an interruption, crash, orphaned worktree, or resumption in the wrong directory. Uses state in the consumer and execution record in source mode. Starts read-only, distinguishes false alarms from real risk, and preserves WIP before any operation that could move or discard it. Never stashes/resets/deletes/aborts automatically.
---

# PelizzAI Resume

## Purpose

Rebuild reality without losing work and without turning every divergence into a Git menu.

**Announce**, in the conversation's language: that you are using the PelizzAI Recovery skill to reconcile the record with Git without losing WIP.

## 1. Read-only diagnosis

Do not write or move WIP until the divergence is classified:

```bash
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git worktree list --porcelain
git log --oneline -10
git stash list
```

Read `project`, `branch`, `base-ref`, `base-sha`, `validated-head`, `confirm`, `isolation`,
`worktree-path`, `phase`, the progress, and `next` from the consumer `state.md` or the native
execution record. Missing state in source mode is normal. Separate:

| Class | Example | Conduct |
| --- | --- | --- |
| wrong directory | record points to a valid worktree, but the command ran in the main repo | switch to the correct path; zero writes |
| lagging cursor | Git/commits are coherent and the record lost progress | reconcile only the record, with evidence |
| recoverable WIP | dirty working tree on the correct branch | preserve and resume; no reflexive stash |
| divergent identity | branch/path/base do not match and the WIP's origin is uncertain | human decision after inventory |
| risk of loss / rewritten history | commits vanished, refs changed, dirty orphaned worktree | preserve refs/WIP and escalate |

If it is a directory false alarm, fix the context and return to the router without touching the record.

**Delivery in `delivered` on resumption.** If state shows `phase: delivered`, the task was sealed and
its destination executed, leaving only the observation of `done` — this is **not** WIP divergence.
Apply the same reconciliation as `pelizzai-execute` (§Reconciling the previous delivery):
check `confirm:` against git (read-only) — does `base-ref` contain `validated-head`? PR merged?
branch integrated? (local delivery: does the user accept?). Observed → stamp the `## History` index
line with `done <YYYY-MM-DD>` + 1-line evidence and record `phase: done` — the full block
already migrated to `pelizzai/data/history/<YYYY-MM-DD>-<slug>.md` at the `delivered` seal, so
there is no block to move here; writing metadata in `pelizzai/` is valid on any branch, but the commit waits for
the new task branch (never on a protected one). Failed (PR closed without merge) → do not record
`done`; report and propose resuming the branch or archiving as `abandoned`. No working file is moved
in this observation. Source mode: the same observation applies to the native execution record,
without creating `pelizzai/` or `history/`.

## 2. Inventory the WIP

Before proposing any mutation, show:

```text
tracked staged/unstaged
untracked (names, without reading secrets)
commits exclusive to the branch
relevant stashes
worktrees/refs that still point to the content
```

Do not treat unknown files as belonging to the task. Discover their origin/scope before including
them in a commit or stash.

## 3. Choose the smallest recovery

Use a safe default when unambiguous:

- cursor provably lagging and no identity conflict → update only the evidenced fields;
- active record points to a valid worktree → run from there;
- coherent WIP **outside** a mid-plan resumption (standalone tweak/bug on the right branch) →
  resume in place.

**Mid-plan resumption with WIP always opens the recovery gate.** Reopening a plan midway with a
dirty working tree is a structural decision: do not silently resume in place just because the WIP
looks coherent. Present the return point and the options, with the recommended one pre-selected:

```text
Recovery gate — plan "<name>" resumed midway (answer "ok" or pick another option):
Return point: <proposed rescue ref/branch | "waivable: resuming in place does not move the WIP">
1. [recommended] Resume in place — continues from where it stopped; does not move the WIP.
2. Return to the last sealed state (validated-head <sha>) — discards/reviews the WIP with confirmation.
3. Review the diff before deciding — full WIP inventory (§2), then choose again.
4. Discard the WIP — destructive; requires explicit confirmation and a return point first (§4).
```

Outside a mid-plan resumption, ask only when there are materially different paths; do not show
inapplicable options. Discard, stash, abort, reset, deletion, or worktree removal are never chosen
autonomously.

Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP), do not produce route analyses or open gates: apply the briefing and escalate to the coordinator whatever requires a decision.

## 4. Return point before risk

If the selected route will move, hide, rewrite, or discard WIP:

1. obtain explicit confirmation of the operation and its scope;
2. prefer a rescue branch/ref when the commits already exist;
3. for an arbitrary working tree, use a **named** stash only after listing staged/unstaged/untracked
   and confirming it will not capture unrelated/sensitive files;
4. record the name/SHA and the restore command before continuing.

Never use `reset --hard`, branch `-D`, worktree `--force`, or `git clean -f`. If the user truly
wants an operation blocked by the guardrails, deliver a diagnosis and manual instructions; do not
bypass the hook.

## 5. Reconcile the record

Update only proven fields. Before the commit:

- be on a safe, non-protected branch; if needed, use `pelizzai-isolate` without losing the
  rescue ref;
- consumer: stage only `pelizzai/data/state.md` when the recovery is cursor-only;
- source mode: update only the native execution record; do not create state or a cursor commit;
- if legitimate WIP will also be consolidated, return it to the normal lifecycle for
  review/proof/commit; do not mix unreviewed content into a “recovery commit”.

In the consumer, add the divergence, evidence, and recovery to the History. In source mode, record
the same summary in the native mechanism. Validate against Git again. If you cannot persist safely,
preserve the return point and escalate; do not invent a commit on a protected branch.

## 6. Resume

Return to the router with:

```text
confirmed reality
return point (if any)
reconciled record or the reason for not changing it
exact next step
limitations/pending decision
```

If the task was sealed and any content changed, invalidate `validated-head` and go back to review +
Verification. Recovery never calls finish-task with a stale seal.

## Red flags

```text
- Automatic stash just because the working tree is dirty.
- A full menu for a simple wrong-directory run.
- Mixing an unrelated file into the checkpoint/commit.
- Reconciling state/execution record from memory, without Git.
- Destructive operation without confirmation and a return point.
- Preserving validated-head after the content changed.
```

## Integration

Called by router/starting-branch/execution-plans when the record and Git diverge. Uses
`pelizzai-isolate` for safe rescue and returns the work to the lifecycle; finish-task only
enters after new content is consolidated and sealed.
