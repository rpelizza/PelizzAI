---
name: pelizzai-finish
description: Use after overlays, consolidation, and final validation have sealed the content at validated-head. Before the destination, checks as a safety net whether security, UI, or documentation went uncovered and offers — without blocking — to return the delivery to the cycle. In a consumer, closes the task in phase delivered with a metadata-only commit of the data/history/ file from the migration — state.md is the local per-dev cursor, ignored by git (issue #43), updated but never committed (done is observed later, not here); in the source repo, validates the seal without creating runtime/closure. Keeps local by default or publishes/opens a PR with authorization. Never alters content or history after the seal.
---

# PelizzAI Finish

## Goal

Integrate **the content that was validated**, with no hidden final round of mutations. Squash,
security, frontend, documentation, fixes, and tests belong to the preceding flow and this skill
runs none of them. What it does before any destination is a **safety-net check** (§1.5): if a
touched surface got through without the matching overlay, it offers once to return the delivery to
the cycle — without blocking and without patching after the seal. This skill closes in
`phase: delivered` (content sealed + destination executed) and records `confirm:`; `done` is
observed, not declared — the observation happens at the next opening/resumption, never here. This
skill:

```text
consumer: validated-head → closure `delivered` (history/ file from the migration; the local state.md is updated, never committed) → delivery-head
source:   validated-head ──────────────────────────────────→ delivery-head
                                     (done observed later, outside this skill)
```

**Announce on start**, in the conversation's language: that you are using the PelizzAI Finish skill to integrate the already-validated content.

## Source mode — no consumer runtime

If the source repo sentinel is present, do not look for or create `pelizzai/data/state.md`. Take
`branch`, `base-ref`, `base-sha`, and `validated-head` from the execution record; require a safe
branch, `git rev-parse HEAD == validated-head`, and a clean working tree. Set
`delivery-head=validated-head`, skip the closure commit, and go straight to
**Resolve the destination**. Without an external request, recommend keeping local and wait for the
choice. When finished, mark the execution record
`phase: delivered` with `validated-head`, `delivery-head`, `confirm:`, and the destination status;
`done` is observed later (same reconciliation, in the native execution record, without creating
`pelizzai/`). Any divergence goes back to the lifecycle.

The state/closure sections below apply only to consumer projects.

## Invariants

```text
- One task/state represents a single Git repository.
- On entry, HEAD == validated-head and the working tree is clean: pelizzai/data/state.md is the
  local per-dev cursor, ignored by git (issue #43), so its pending seal update never shows in
  porcelain.
- After the seal, no squash/rebase/reset, overlay, formatter, codegen, snapshot-writing test,
  doc generator, or fix runs.
- A coverage gap (security, UI, documentation) becomes an explicit offer in §1.5, never silence;
  accepting it returns the task to the validation cycle — it never becomes a post-seal patch.
- In consumer mode, the single new commit touches only harness metadata: the
  pelizzai/data/history/ file the seal's migration just resolved as `<history-file>` — §2b step 1
  (source mode creates NO closure commit — §Source mode and §2b).
- Keeping local is the default recommendation, but it still requires an answer at the gate.
  Push/PR, worktree removal, and discard require an explicit per-task decision: they are never
  applied from a profile default nor inherited from another task.
- Never use reset --hard, branch -D, worktree remove --force, or automatic stash.
```

## 1. Fail-closed gate on the sealed content

Read `project`, `branch`, `base-ref`, `base-sha`, `validated-head`, `isolation`, and
`worktree-path` from the state. Confirm that `project` is the current repository root and run:

```bash
git branch --show-current
git rev-parse HEAD
git rev-parse "<base-sha>^{commit}"
git rev-parse "<validated-head>^{commit}"
git status --porcelain --untracked-files=all
git diff --name-only
git diff --cached --name-only
```

Stop and go back to the validating flow when any item fails:

- branch empty/protected (`main`, `master`, `develop`, `dev`, or the `base-ref` name) or different from the state;
- `validated-head` missing, abbreviated, invalid, or different from `git rev-parse HEAD`;
- staged change;
- any modified/untracked file (the local per-dev cursor is ignored by git and never appears here);
- `git ls-files -- pelizzai/data/state.md` lists the cursor — a consumer that predates the #43
  migration: stop and run it first (untrack the cursor with `git rm --cached`, update
  `pelizzai/.gitignore`, add `pelizzai/.gitattributes` — contract in `pelizzai-audit`). The
  migration commit is content: after it, return to the validating flow and seal a fresh
  `validated-head` — never resume this seal on top of it;
- evidence of review/checklist/verification predating the last fix;
- an overlay recorded in `overlays:` that never ran — the plan promised and did not deliver; go
  back and run it there. A touched surface nobody ever recorded does **not** stop here: it falls
  into the §1.5 net, which offers instead of blocking.

If `commit-strategy: squash-final`, confirm the consolidation happened **before** the seal (in
general, one content commit in the `base-sha..validated-head` range). Do not try to fix history
here; go back to `pelizzai-execute` and revalidate the new candidate.

If there are stray commits on a protected branch, preserve them by creating a rescue branch and
stop. Hand over manual instructions to reconcile the protected branch; do not auto-reset.

## 1.5. Coverage safety net (an offer — it does not block)

Overlays are the router's and the plan's responsibility and run **during execution**, before the
final review and `validated-head`; this section does not pull them here. It is the **last net**: it
catches the surface that escaped classification back then. Run it once, with the §1 gate green and
before offering the destination.

Cross the closed diff against the recorded coverage — `overlays:` in the state (in source mode, in
the execution record) plus the final-validation evidence:

```bash
git diff --name-only <base-sha>..<validated-head>
```

Classify each surface as COVERED or UNCOVERED:

```text
- Security       → pelizzai-oswap: auth/authorization, untrusted input, SQL/query, secret,
                   sensitive data, upload, deserialization, CORS/SSRF, header, new dependency.
- UI             → pelizzai-frontend: component, page, screen route, style, visual state.
- Documentation  → pelizzai-documentation: new stable human-facing surface — route,
                   command, public API, screen.
```

**Covered: do not ask.** An overlay recorded and evidenced in the final validation is settled;
repeating the question at closeout is noise and undermines the work already done.

**Uncovered: offer ONCE**, one question per surface, in the order security → UI → documentation,
with the cost on the table:

```text
The diff touches <concrete surface> and no <area> overlay covered this delivery.

Running `<skill>` now is late: the seal falls and the content returns to the cycle (overlay →
consolidation → final review → new validated-head), which delays the delivery. Even so, late
beats delivering uncovered.

Run it now, or proceed to the destination accepting the gap?
```

- **Accepted:** do not run the overlay here nor create a corrective commit after the seal. Record
  `validated-head: <none>` (source mode: in the execution record, without creating `pelizzai/`),
  note the surface under `## Progress` → `pending`, and return the task to
  `pelizzai-execute` → **Final delivery validation**, step 1 (run overlays). The corrected
  content is reconsolidated, re-reviewed, and sealed again, and only then comes back to this
  skill. "The delivered content is exactly the validated content" is not traded away for speed.
- **Declined:** proceed to §2a without insisting. Record the accepted gap in one line (`pending`)
  and repeat it in the destination report — an informed refusal is the user's decision; silence
  would be a harness failure.

Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP), do not open the offer: report the uncovered surface to
the coordinator and follow the briefing.

## 2. Resolve the destination and seal the closure (`delivered`)

### 2a. Offer the destination

**Offer the destination** once. **Keep local** is recommended when no external intent was
expressed, but it is never auto-confirmed. Ask a single question and wait:

```text
How should the validated content be integrated?

1. Publish this branch without opening a PR
2. Publish this branch and open a Pull Request
3. Keep local
4. Prepare manual discard/archival

Which option?
```

On a trivial local task, the question can be short: "I recommend keeping local; confirm, or would
you rather publish/open a PR?". Still, wait for the answer. When external intent was already
expressed, confirm only the materially ambiguous target. The destination never comes from a
profile default.

Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP), produce no route analyses and open no
gates: apply the briefing and escalate to the coordinator whatever requires a decision.

### 2b. Seal the closure in `delivered` (metadata-only commit — consumer only)

**Consumer only** (restating the §Source mode rule so this section cannot be read alone): in
source mode SKIP this entire section — no `pelizzai/` is created or edited, there is no closure
commit, `delivery-head == validated-head` is required before delivery, and the destination
status lives in the native execution record.

`delivered` = content sealed + destination executed; it is recorded BEFORE leaving the task branch
(the migrated history/ file rides along in the PR; the cursor itself is local per dev and never
travels). In the `pelizzai/data/state.md` already modified by the seal:

1. **Migrate the intact block and deflate the cursor** along the boundary defined in
   `pelizzai-execute` → §State and resumption: copy the task fields + the
   `T<n>`/`next`/`pending` lines faithfully into
   `pelizzai/data/history/<YYYY-MM-DD>-<slug>-<sha7>.md` (VERSIONED), where `<sha7>` is the first
   7 characters of `validated-head`. The name is **unique by construction, across branches too**:
   parallel tasks sealed on different branches carry different heads, so no local existence check
   — which cannot see another branch's unmerged closure — is ever needed. Add to the migrated
   block the line `sealed-by: <git user.name> <user.email>` (from `git config`): the file is the
   durable record in a multi-dev consumer, and it names its author. The resolved path is
   **`<history-file>`** from here on: the
   index line, the `git add`, and every later guard use it verbatim — never reconstruct a
   different name. Then return
   `## Active task` and `## Progress` to the template placeholders, and leave
   in `## History` **one** index line
   (`- <date> <slug> — delivered — <result ≤10 words> → <history-file>`). The cursor shrinks
   back to template size HERE, at closeout — it does not stay bloated through the whole
   `delivered` window. Preserve `slug`, `phase`, `branch`, `base-ref`, `base-sha`,
   `validated-head`, `commit-strategy`, `worktree-path`, `confirm:`, `delivery-status:`, and
   `kickoff: ratified`: the destination (Step 3) and the later observation still read them, and
   the writegate is fail-closed on the kickoff — emptying it here would report "never ratified"
   about a task that just shipped, and block any product write until the next task's gate. The
   reset of `kickoff` belongs to the NEXT task's opening (`pelizzai-execute` → §State and
   resumption), not to this seal.
2. Set `phase: delivered` and record `confirm:` with the observable condition that becomes `done`,
   derived from the destination chosen in 2a: publish/PR → `base-ref contains validated-head
   (PR/branch integrated)`; keep local → `local delivery accepted by the user`; discard/archival
   (option 4) → `archived locally, no merge expected` (it is not a delivery onto a base: §3d
   decides archive or discard; the observation becomes `done` when the archive is accepted, or
   `abandoned` if discarded). Also set `delivery-status:` to the destination INTENT from 2a —
   `pending push`, `pending pr`, `local`, or `archive`. In a consumer it is written once in the
   local cursor at the seal and never edited again by this skill (the cursor is local per dev and
   never committed — issue #43); source mode records the destination status in the native
   execution record as §3 describes: what actually
   happened at §3 is reported in the conversation and OBSERVED on resumption against the remote,
   with the sealed intent narrowing the reconciliation — remote branch missing = failed before
   the push; branch at `delivery-head` without a PR = pushed, PR pending.
3. Check that the `## History` index line (step 1) is dated as `delivered`, without promising
   merge/`done` yet — that stamp comes from the later observation.
4. Update the date. Order note: the history file is the only durable snapshot of the task
   (issue #43) — perform the step 1 copy with the sealed fields of steps 2–3 already written, or
   re-copy them into the history file before staging; a history file without
   `phase/confirm/delivery-status` recorded is an incomplete seal.

Stage **only** the harness metadata — the history file the step 1 migration just generated (a
versioned file; it travels in this same closure, never in an extra commit). The cursor is
**written, never staged**: it is the local per-dev file the ignore protects (issue #43):

```bash
git add -- <history-file>
git diff --cached --name-only
git commit -m "chore: seal task as delivered"
```

Before executing the destination, prove the three guards:

```bash
# must list exactly this one metadata file, nothing more
git diff --name-only <validated-head>..HEAD

# no product difference outside the harness metadata
git diff --quiet <validated-head>..HEAD -- . ':(exclude)pelizzai/data/history/*'

# must be empty
git status --porcelain --untracked-files=all
```

Record `closure-head=$(git rev-parse HEAD)` and `delivery-head=$closure-head` for this run's
operations only. A hook that included another file or left dirt invalidates the closeout; stop, do
not make another corrective commit.

## 3. Execute the destination

The destination was decided in 2a and the `delivered` closure is already committed (2b). Now
execute the chosen effect. Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP), apply the
briefing and escalate to the coordinator whatever requires a decision; do not reopen the gate.

Immediately before any external effect, repeat:

```bash
test "$(git rev-parse HEAD)" = "<delivery-head>"
git status --porcelain --untracked-files=all
```

In a consumer, also repeat `git diff --name-only <validated-head>..<delivery-head>` and require
only the one closure metadata file: the `<history-file>` resolved by the seal's migration
(§2b step 1) — nothing more.
In source mode, require `delivery-head == validated-head`.
Diverged? Stop; do not publish.

### 3a. Publish without a PR

This publishes **the task branch**; it does not merge/push directly onto the base. Require a known
`origin` remote and push the closed SHA via an explicit refspec:

```bash
git push origin <delivery-head>:refs/heads/<branch>
git branch --set-upstream-to=origin/<branch> <branch>
```

Then confirm that `refs/heads/<branch>` on the remote points to `delivery-head` and report
`delivery-status: pushed` (in the conversation and the destination report — the cursor keeps the
sealed intent; a resumption distinguishes "failed before the push" from "pushed" by observing the
remote branch). Non-fast-forward, auth, network, or a divergent remote SHA fails closed; do not
force-push.

### 3b. Publish and open a PR

Do the exact same push and derive the base name from `base-ref` (for example,
`origin/trunk` → `trunk`). Then:

```bash
gh pr create --head <branch> --base <base-name> --title "..." --body "..."
```

The body carries the summary and the evidence/how to test. Without authentication, report the
blocker; do not switch the destination on your own.

On success, capture the returned URL, check the PR's head/base, and report
`delivery-status: pr-open` + the URL. This same transition closes a resumption that was `partial`.

Push and PR creation are separate checkpoints. If the push was confirmed and `gh pr create`
fails, report `delivery-status: partial`, the remote branch + SHA, and the PR error: the
content is already published, but the PR was not created. On resumption, reconcile the remote
branch and any existing PR — the OBSERVATION (remote branch at `delivery-head`; PR present or
not) is what distinguishes `partial` from `pushed`/`pr-open`, since the cursor holds only the
sealed intent; skip the already-confirmed push and repeat only the PR creation. Do
not revalidate content, do not create another state commit, and do not change the destination on
your own.

### 3c. Keep local

Make no external effect. Report the branch, `validated-head`, and `delivery-head`; in source mode
record `delivery-status: local`.

### 3d. Prepare discard/archival

Ask for the literal confirmation `discard`. Even confirmed, the harness never forces deletion:

- offer to keep/rename the branch as a local archive;
- if it is already integrated, `git branch -d` is the only acceptable automatic deletion;
- if it is not integrated, hand the user the manual `branch -D` command and its SHAs,
  but do not run it;
- a dirty worktree is never removed; a clean worktree follows the §4 gate, without `--force`.

## 4. Worktree

After publishing or keeping the branch safe, offer to remove the worktree. Confirm again, exit to
the main repository, verify it is clean, and use only:

```bash
git worktree remove <path>
```

Failure means stop and report. Do not use `--force`. Do not create another commit to clear
`worktree-path`; the state sealed in `delivered` is already lean (the intact block went to
`history/`) and the next opening stamps `done` on the index before overwriting.

## 5. Maintenance nudge (read-only)

In a consumer, after the destination, without blocking or altering the delivery — everything here
is propose-and-confirm and coordinator action; a team member only flags the gap in the report:

- **Cadence due:** this is the **primary trigger** of the domain-skill cadence — the Claude Code
  hook is only a safety net. Check the **two** triggers in the
  `pelizzai/data/review-domain-skills.md` ledger: (a) review — commits since `last-review` or days
  elapsed; (b) full repo-scan since `last-full-scan`. Thresholds live in `pelizzai-create-skill`
  → `references/domain-skill-maintenance.md`. Either one due → suggest **once** invoking
  `pelizzai-create-skill` in maintenance mode, saying which trigger is due. Below the
  thresholds, say nothing; if the user defers, do not repeat it in the same session.
- **New stack adoption (adoption-driven):** check in this task's closed range
  (`git diff <base-sha>..<validated-head>` over manifests/lockfiles) whether a significant
  dependency or service was adopted without a covering domain skill. If so, propose ONCE creating
  the skill, grounded in context7/the official docs for the version pinned in the lockfile: "The
  task adopted `<lib@version>` with no covering domain skill. Create one now? [create · defer ·
  don't create]". Recommend `create` for high-leverage libs (auth, payments, ORM/data, framework,
  queue/sensitive infra) and `defer` for a trivial utility; the writing only happens after the
  "yes", via `pelizzai-create-skill`.
- **Maintenance not armed:** if the cadence hook is installed but the ledger is missing, say so
  ONCE ("cadence inactive: no ledger; run the minimal initialization of `pelizzai-audit` to arm
  it") to distinguish "off" from "broken".
- **Bulky state:** if `pelizzai/data/state.md` grew past ~60 lines, suggest compacting once
  (advisory) — the whole template is ~50. The intact-block migration to `data/history/` at the
  `delivered` seal already slims the state; condensing what remains is propose-and-confirm.
- **Learnings recurrence and budgets (`pelizzai-evolve`):** when this task fixed a confirmed
  defect, check `pelizzai/data/learnings.md`: the incident entry should already be there
  (written at root-cause confirmation, inside the fix's commit) — missing, flag it; and when the
  same root cause appears 2–3 times, offer ONCE the promotion via `pelizzai-evolve` (ratified by
  the user, never automatic) — unless **Active rules** already carries a rule for that root
  cause: the archives are append-only, so the standing rule is what records that the promotion
  already happened. That is not silence either: a recurrence with the rule ALREADY in force is
  the worth-it gate's second condition — the local fix did not prevent the next one — so flag
  THAT to `pelizzai-evolve` in place of the promotion. **Count over the whole corpus** —
  `learnings.md` plus every existing `pelizzai/data/history/learnings-<YYYY>.md`; the valve
  leaves a pointer naming each one, and a missing pointer is no excuse — enumerate every
  `history/learnings-<YYYY>.md`. Counting the active file alone means archiving lowers the
  number that decides the promotion, which turns a budget measure into a silent veto on
  prevention. Check the budgets on `learnings.md` itself, **per section, never summed**, and
  **at or past** the ceiling — they are hard, so reaching 40/160 already needs the valve: Active
  rules at or past 40 lines (flag it), Incident log at or past 160 (flag it: the valve in
  `pelizzai-evolve` routes the oldest entries to `pelizzai/data/history/learnings-<YYYY>.md`,
  leaving the pointer that keeps them findable) — plus `verification-standard.md` at or past
  150. A full log is NOT a reason to retire a rule: the ceilings are separate precisely so the
  history cannot evict the prevention, and the log's valve is moving the oldest entries to
  `pelizzai/data/history/learnings-<YYYY>.md`, leaving its pointer. A start-of-task read over
  budget is a file nobody reads, and the valve (retire / archive / replace baseline rows)
  belongs to `pelizzai-evolve`.

Source mode, or no hook and no ledger: silent no-op.

## Red flags

```text
- Delivering a sensitive, UI, or documentable surface without an overlay and without the §1.5 offer.
- Running the accepted overlay here, or patching with a fix/doc after the seal, instead of
  returning to the cycle.
- Repeating at closeout the offer of an overlay that already ran during execution.
- Declaring `phase: done` here (pelizzai-finish closes in `delivered`; `done` is observed later).
- Squash/reset/rebase/amend after validated-head.
- `git add -A` in the closure commit.
- Staging or committing the local per-dev cursor — at the closure or anywhere else (issue #43).
- Pushing HEAD without comparing it to delivery-head, or pushing directly onto the base.
- Force-push, branch -D, worktree --force, automatic stash/reset.
- Treating multiple repositories as a single task.
```

## Integration

**Called by:** `pelizzai-execute`, `pelizzai-debug`, and `pelizzai-quick-fix`, only
after their overlays and validation have recorded `validated-head`.

**Combines with:** `pelizzai-starting-branch`, `pelizzai-final-verification`,
`pelizzai-review`, `pelizzai-recovery`, and `pelizzai-merge-conflict-resolution`. The §1.5 net
points to `pelizzai-oswap`, `pelizzai-frontend`, and `pelizzai-documentation` — always via
the return to `pelizzai-execute`, never by running the overlay inside this skill.
