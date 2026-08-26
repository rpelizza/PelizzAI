---
name: pelizzai-isolate
description: "Use before the first artifact of any task that may commit. Detects the workspace, discovers the real base, and creates the task branch or worktree before anything is written."
---

# PelizzAI Isolate

## Goal

Create the isolation **before spec, plan, or code**, from a proven base. The same branch starts as
the task/planning branch; if the user chooses a worktree after the plan, the worktree is created
**from that branch**, preserving the artifacts already produced.

**Announce on start**, in the conversation's language: that you are using the PelizzAI Starting Branch skill to prepare this task's isolation.

## Invariants

```text
- One task = one Git repository. A monorepo is one repository; a multi-repo workspace opens one
  state/execution record per repository. Do not hide a list in the project field.
- The workspace is detected, never assumed: markers in the cwd and one level up (§2). The set of
  affected projects is ALWAYS confirmed with the user; `pelizzai/` is root-level of the workspace.
- base-ref and base-sha are resolved before the first change and do not change during the task.
- The branch is created before spec/plan/code. During planning, isolation may stay pending.
- The post-plan worktree reuses the existing branch; it does not create an empty branch from the
  base.
- This skill never uses `git pull`. Remote update is an explicit `git fetch <remote> <ref>`.
- Never use a detached checkout followed by pull; remote-only becomes a start-point or a local
  tracking branch.
- Never reset/delete/stash automatically to "tidy up" a base or free a worktree.
- In source mode, do not create `pelizzai/` runtime; return branch/base/isolation to the native
  execution record. The state fields below apply to consumer projects.
```

## 1. Identify the single repository

```bash
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git worktree list --porcelain
git remote -v
```

If it is not Git, offer `git init` before writing. If the folder contains multiple repositories
and the request's scope does not identify one of them unambiguously, confirm **which single
repository** belongs to the current task; open separate tasks for the others.

An empty/detached HEAD, a rebase/merge in progress, or a protected branch (`main`, `master`,
`develop`, `dev`, **and the real default discovered in §3**, such as `trunk`) is never a commit
destination. If changes already exist, preserve them by creating the task branch from the current
HEAD after confirmation. If stray commits already sit on the protected branch, create the rescue
branch and stop: hand over a handoff for the human to reconcile the protected branch. Do not run
`reset --hard`, do not force branches, and do not erase history.

If already on a non-protected branch, confirm whether it is this task's branch. Reuse it only when
the answer and the available record agree (`state.md` in a consumer; native execution record in
source mode). Without a prior record, use Git evidence + explicit ownership of the changes; an
ambiguous branch or ambiguous dirt is never adopted on a hunch.

## 2. Detect a multi-project workspace

Detects a multi-project workspace and confirms the affected set with the user: in a workspace the
harness never picks the projects on its own.

A task still belongs to **one** Git repository (§1) — that does not change. What the harness needs
to know before creating anything is whether that repository lives inside a **workspace**: the
workspace decides where `pelizzai/` lives and which projects the request actually touches. Check
the markers in the cwd and one level up:

```bash
markers="package.json pnpm-workspace.yaml turbo.json lerna.json nx.json pyproject.toml Cargo.toml go.work"
ls $markers 2>/dev/null             # cwd
(cd .. && ls $markers 2>/dev/null)  # one level up
find . -maxdepth 2 -name ".git"     # siblings with their own repository (dir or worktree file)
```

When there is a workspace or multiple projects:

```text
1. Infer from the task description which projects are affected (directory/package name, mention of
   frontend/backend/worker, etc.). Inference builds the candidate list, never closes it.
2. ALWAYS confirm the affected set with the user before proceeding. The set is the user's
   decision: present the inferred list with a recommendation and wait. A guessed set is a material
   gap — it goes to `pelizzai-interview`, not to a default.
3. Workspace of multiple Git repositories: each affected project gets its own isolation. Run §1
   and §3–§8 independently per repository, and open one execution record (consumer state or
   native execution record) per repository. Do not hide a list in the `project` field.
4. Monorepo (one Git repository, multiple packages): the isolation is single — one branch covers
   the touched packages. Confirming the affected set still applies; it bounds the scope of the
   diff, not the number of branches.
```

`pelizzai/` is **root-level of the workspace**, not one per package: `domain-skills.md`,
`profile.md`, and `data/` live in the root declared as owner of the artifacts — that root is what
`pelizzai-onboard` maps and it is how the cadence hook locates the ledger (it resolves via `cwd`
assuming `pelizzai/` at the root). In a workspace with multiple repositories, one scalar state
does not cover them all: either bootstrap per repo, or explicitly declare the owning root.

Names: use the same `<type>/<slug>` across all affected projects, unless the user asks for
project-specific names.

## 3. Discover the real base

Do not use the historical preference `develop > dev > main`. Discover the repository's default:

```bash
# Run only if `origin` exists; a network failure does not invalidate already-known local refs.
git fetch origin --prune
git symbolic-ref --quiet --short refs/remotes/origin/HEAD

# Only if origin/HEAD is absent: queries the HEAD announced by the remote, without checkout.
git remote show origin

# Local fallback: just a candidate name, valid only if the corresponding ref exists.
git config --get init.defaultBranch

# Inventory to confirm candidates and avoid guessing.
git for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin
```

Algorithm:

1. If `origin/HEAD` resolves to a commit, propose that ref.
2. If it is absent, use the `HEAD branch` announced by `git remote show origin`, provided
   `origin/<name>` resolves.
3. Without a remote default, accept `init.defaultBranch` only if `refs/heads/<name>` or
   `refs/remotes/origin/<name>` exists.
4. Without an unambiguous candidate, show the existing refs and ask for the base. Never create
   `develop` as a harness convention.
5. With an unambiguous, current candidate, present ref + SHA with a recommendation and ask one
   question: "Confirm this base?". Wait. In the light tracks (tweak/bug), do not open a separate
   question: hand the recommended base (ref + SHA) and the suggested name to the head skill's
   compact confirm, which ratifies everything in a single line; a base without an unambiguous
   candidate (step 4) still stops here. A materially different base is an explicit restart;
   `base-ref`/`base-sha` remain immutable during the task.

The name pointed to by the discovered default is treated as a protected branch by the harness from
then on, even if it is not called main/master/develop/dev.

For a remote base, update only that base and use the remote-tracking ref as the start-point:

```bash
git fetch origin <base-name>
base_ref=origin/<base-name>
base_sha=$(git rev-parse "$base_ref^{commit}")
```

For a purely local base:

```bash
base_ref=refs/heads/<base-name>
base_sha=$(git rev-parse "$base_ref^{commit}")
```

`base-ref` records the ref actually used and `base-sha` records the full SHA. If the fetch fails,
present the local ref's age/limitation and ask for confirmation; do not pretend it is current.

## 4. Name the task/planning branch

After ratifying the base, derive `<type>/<kebab-slug>` (ASCII, lowercase, up to 50 characters).
Present the recommended name with the reason and ask a single question: "Confirm this name?". In
the light tracks (tweak/bug), the recommended name travels in the head skill's compact confirm
instead of a separate question — the line's "ok" IS the ratification of base + name. Only create
the branch after an affirmative answer. Never lock in name/base silently. The type comes from the
real effect:

| Nature | Suggested type |
| --- | --- |
| feature | `feat` |
| bug | `fix` |
| refactor | `refactor` |
| docs only | `docs` |
| tests only | `test` |
| tooling/config/deps | `chore`, `build`, or `ci` |
| performance | `perf` |

## 5. Open the branch before planning

For tracks with a spec/plan, once base and name are ratified, create the branch in the current
working tree **before** writing those artifacts. The choice between keeping the branch and moving
to a worktree stays pending until the post-plan gate:

```bash
git switch -c <type>/<slug> --no-track <base-ref>
```

In a consumer, immediately record `project`, `branch`, `base-ref`, `base-sha`,
`validated-head: <none>`, `isolation: <pending>`, and `worktree-path: <none>`. In source mode,
return these values to the execution record without creating state. Persistent specs/plans and the
consumer state are now born on the branch that will later feed the worktree.

For a direct flow without planning, apply the isolation choice right away:

- Branch: use the command above and record `isolation: branch`.
- Worktree: `git worktree add -b <branch> <path-outside-the-repo> <base-ref>` and record the path.

In a consumer, **write** the `state.md` with your file tools and move on — writing is enough. **Do
not create a metadata-only commit** (`chore: start task <slug>`): the cursor travels in the task's
first content commit, alongside the exact paths it describes. It is harness metadata, not delivery
content — if it shows up in Task 1's review package, it is known noise, never a reason for an
extra commit. In source mode, there is no state and no setup commit; branch/worktree + execution
record suffice.

## 6. Apply the chosen isolation after the plan

The name and the base were already ratified before the planning branch. If the user asks to rename
later, use `git branch -m <new-name>` after confirmation; never `-M`. The base is not rewritten
here.

### Keep as a branch

Confirm that `git branch --show-current` is the recorded branch and, in a consumer, record
`isolation: branch` plus the gate decisions. Before Task 1, checkpoint the intentional
planning/state artifacts with exact paths and require a clean working tree. In source mode,
checkpoint only a persistent plan the user explicitly asked for; a native plan generates no file.
Do not recreate the branch or recompute the base.

### Move the existing branch to a worktree

1. On the task branch, checkpoint **only when there are** intentional persistent planning
   artifacts (`plan`, spec/ADR and, in a consumer, `state.md`). Use exact paths; never
   `git add -A`. A native plan in source mode creates no empty commit.
2. If there are artifacts, inspect `git diff --cached` and create the commit. If the user does not
   authorize that checkpoint, keep `isolation: branch`; uncommitted changes do not cross
   worktrees. With or without a new commit, capture `checkpoint-sha = git rev-parse HEAD`.
3. Require an empty `git status --porcelain`. A strange or third-party change triggers a
   handoff/human decision; do not auto-stash.
4. Free the branch in the main working tree:
   - existing local base: `git switch <local-base-name>`;
   - remote-only base: create the local tracking branch without a detached HEAD,
     `git switch -c <base-name> --track <base-ref>`;
   - base that is a tag/SHA or a colliding local name: stop and agree on a parking branch.
5. Create the worktree **with the existing branch**, without `-b`:

```bash
git worktree add <path-outside-the-repo> <type>/<slug>
```

6. Inside it, confirm the branch, `HEAD == checkpoint-sha`, and the presence of the persistent
   artifacts, when they exist.
7. In a consumer, record `isolation: worktree` and `worktree-path` in the `state.md` inside the
   worktree — no metadata commit; that touch goes into the first content commit. Before Task 1,
   require that nothing besides it is dirty. In source mode, update only the native execution
   record; do not create state.

The path stays outside the repository tree. If the environment blocks the creation, report it and
ask for confirmation to stay on branch; do not degrade silently.

## 7. Proportional baseline

Before implementation, run the baseline evidence appropriate to the artifact and the project's
profile: focal suite/test for behavior, characterization for legacy, parser/dry-run for config,
render/lint for docs, and a running application for UI. A failing baseline is reported before the
change; the user decides whether to investigate or proceed with the failure on record.

## 8. State and report

In a consumer, the final setup `state.md` contains:

```text
project: <root of this single repo>
branch: <type>/<slug>
base-ref: <exact ref>
base-sha: <full SHA>
validated-head: <none>
isolation: <branch | worktree>
worktree-path: <none | path>
```

Report branch, base-ref + base-sha, isolation, path, and baseline. In source mode, this report is
the execution record. On resumption, compare the persisted/native data with Git; a material
divergence calls `pelizzai-resume`, not heuristics.

## Red flags

```text
- Imposing/creating develop because "it's the convention".
- `git pull` without an explicit remote/ref, or pull on a detached HEAD.
- Writing the spec/plan on the base and only then creating an empty branch/worktree from the base.
- Creating the post-plan worktree with `-b` from the base, losing the planning branch.
- Recomputing base-sha at closeout; it is a snapshot of the start.
- Skipping workspace detection, or closing the affected project set alone without confirming.
- Scattering a `pelizzai/` per package instead of keeping it at the workspace root.
- Mixing multiple repositories into a single state.
- `git add -A`, stash, reset, force-delete, or automatic cleanup to free the worktree.
- Creating the branch before the user ratifies the recommended base and name.
```

## Integration

**Called by:** the router before brainstorming/spec/plan; `pelizzai-execute` at the
post-plan gate; debugging/quick-fix before writing code.

**Combines with:** `pelizzai-execute`, `pelizzai-resume`, `pelizzai-finish`, and
`pelizzai-onboard`.
