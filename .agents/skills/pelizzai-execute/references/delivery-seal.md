# Delivery seal and reconciliation

What happens to the cursor at the EDGES of a delivery: when it is sealed, and when the next task
is opened on top of one already delivered.

**Do not read this during the tasks.** Nothing here fires between Task N and Task N+1 of the same
plan — it fires at closeout, and again the first time a new task opens after a `delivered` seal.

**Migration at the `delivered` seal (the cursor slims down at closeout, not at the next opening).**
The executor is `pelizzai-finish`; the boundary is defined here. When writing
`phase: delivered`, the task's **intact block** migrates to
`pelizzai/data/history/<YYYY-MM-DD>-<slug>.md` (VERSIONED) and the state returns to template
size, with ONE index line under `## History`. Intact block (**migration boundary**, identical
for `done` and `abandoned`) = all fields of this task's `## Active task` + its
`T<n>`/`next`/`pending` lines from `## Progress`, with the `data/reports/` links copied verbatim.
Order of operations (lossless → verifiable):

```text
1. Copy the intact block to data/history/<YYYY-MM-DD>-<slug>.md — a faithful copy, nothing rewritten.
2. Return `## Active task` to the template placeholders, PRESERVING the fields that the
   destination and the later observation still read: slug, phase: delivered, branch, base-ref,
   base-sha, validated-head, commit-strategy, worktree-path, and confirm.
3. Remove the migrated T<n>/next/pending lines from `## Progress` (they return to placeholders).
4. Insert under `## History`: `- <date> <slug> — delivered — <result ≤10 words> →
   data/history/<file>`.
```

The migration is only complete after (1)–(4) and is lossless → automatic; CONDENSING the block's
content (instead of copying it faithfully) is destructive, falls outside the automatic rule →
propose-confirm only.

**Reconciliation of the previous delivery (`delivered` → `done`).** When opening the next task
(here) or resuming (`pelizzai-resume`/session-start), if the state carries `phase: delivered`,
observe the delivery BEFORE overwriting the cursor. The block is already in `history/`; the
reconciliation only stamps the outcome:

```text
- Read `confirm:` and verify it against git (read-only): does `base-ref` already contain
  `validated-head`? Was the PR merged/closed? Was the branch integrated? (Local delivery: does
  the user accept it?)
- Observed → stamp the `## History` index line (`— done <YYYY-MM-DD> — <one-line evidence>`),
  write `phase: done`, and append the same observation to the corresponding `data/history/`
  file. Only then free slug/branch/base-*/validated-head/confirm for the new task.
- Failed (PR closed without merge, branch discarded) → do NOT stamp `done`. Report it and propose
  resuming the delivery branch or archiving it as `abandoned` — the decision is the user's.
  Archiving as `abandoned` uses the SAME lossless migration: the block already migrated at the
  seal, and the index line gets `— abandoned <YYYY-MM-DD> — <reason ≤10 words>`.
```

Metadata writes in `pelizzai/` are allowed on any branch; the commit still requires a task
branch. That is why the reconciliation **reads** on the current branch (even a protected one) and
**writes** the reconciled metadata, but it is only **committed in the first commit of the NEW
task branch** — never a commit on a protected branch. Source mode: the same observation applies
in the native execution record, without creating `pelizzai/` or `history/` runtime.

In both modes, validate the branch with `git branch --show-current` and the worktree via
`git worktree list`/a command run inside the recorded path. A material divergence calls
`pelizzai-resume` in the corresponding mode; it preserves WIP before reconciling.

---
