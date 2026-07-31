---
name: pelizzai-resolving-merge-conflicts
description: Use when there is a git merge/rebase conflict in progress to resolve — the goal is to preserve the intent of BOTH sides. Never uses `--abort` on its own to escape the conflict; if the original intent cannot be safely preserved, it STOPS and escalates to the user. Trigger when the user says "resolve this conflict", "there's a merge conflict", "rebase conflict".
---

# PelizzAI Resolving Merge Conflicts

**Announce at start:** "Using the PelizzAI Resolving Merge Conflicts skill to resolve the conflicts."

## Process

```text
1. See the current state of the merge/rebase. Check the git history and the conflicted files
   (git status, git diff, git log of both tips).

2. Find the primary source of each conflict. Understand DEEPLY why each change was made and what the
   original intent was — read the commit messages, the PRs, the originating issues/tickets.

3. Resolve each hunk. Preserve BOTH intents when possible. Where they are incompatible, choose the one
   that matches the declared goal of the merge and note the trade-off. Do NOT invent new behavior.
   Always try to resolve. If the original intent CANNOT be safely preserved (fundamentally
   incompatible sides, insufficient context), do NOT invent and do NOT force it: STOP and escalate
   to the user with the options — including aborting (`--abort`) and starting over with more context.
   The abort is the user's decision, never your autonomous exit to escape the conflict.

4. Reapply the change's domain skills and overlays (frontend/security/docs when the resolution
   touches those surfaces). Run the proof appropriate to the artifact: focal/full test, typecheck,
   parser, dry-run, render, or visual QA. Do not run irrelevant formatters/checks as ritual.

5. Stage only the resolved paths, check `git diff --cached`, and confirm that
   `git diff --name-only --diff-filter=U` is empty. Continue the merge/rebase with the command
   indicated by `git status`; on each new conflict, go back to step 1. Never use `git add -A`.

6. When done, run Verification against the integrated state. If this conflict belongs to an active
   task, return control to the lifecycle; do not create a parallel closeout.
```

## Red flags

```text
Never: run `git merge --abort`/`git rebase --abort` on your own to escape the conflict (aborting is
       the user's decision, after you escalate with the options); invent behavior that was on
       neither side; resolve without understanding the original intent; `git add -A`; conclude
       without proportional proof or without checking for unresolved conflicts.
```

## Integration

**Combines with:** `pelizzai-starting-branch` (the base the conflict arises from), `pelizzai-finish-task` (the integration/PR where the conflict appears), `pelizzai-verification-before-completion` (running the checks after resolving), `pelizzai-reasoning` (Evidence Synthesis to reconcile conflicting intents).
