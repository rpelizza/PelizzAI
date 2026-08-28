---
name: pelizzai-finish
description: "Use after final validation seals validated-head: 'finish the task', 'close this out', 'seal the delivery'. Integrates exactly the validated content and resolves the destination."
---

# PelizzAI Finish

## Goal

Integrate **the content that was validated**, with no hidden final round of mutations. Squash,
security, frontend, documentation, fixes, and tests belong to the preceding flow and this skill
runs none of them. What it does before any destination is a **safety-net check** (§1.5): if a
touched surface got through without the matching overlay, it offers once to return the delivery to
the cycle — without blocking and without patching after the seal. It then runs the **closure
write-back** (§1.6): the knowledge this delivery produced — approved baseline numbers, confirmed
defects, lessons marked for promotion — returns to `pelizzai/data/` before the seal,
recommend-and-ratify, so the happy path feeds the memory instead of burying it in the cursor. This skill closes in
`phase: delivered` (content sealed + destination executed) and records `confirm:`; `done` is
observed, not declared — the observation happens at the next opening/resumption, never here. This
skill:

```text
consumer: validated-head → closure `delivered` (state.md + history/ from the migration) → delivery-head
source:   validated-head ──────────────────────────────────→ delivery-head
                                     (done observed later, outside this skill)
```

**Announce on start**, in the conversation's language: that you are using the PelizzAI Finish skill to integrate the already-validated content. Everything this flow says to the user — questions, proposals, evidence, verdicts, confirmations, closeouts — follows the conversation's language, even when this skill is read in isolation.

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
- On entry, HEAD == validated-head.
- The only dirt allowed is pelizzai/data/state.md with the seal not yet committed.
- After the seal, no squash/rebase/reset, overlay, formatter, codegen, snapshot-writing test,
  doc generator, or fix runs.
- A coverage gap (security, UI, documentation) becomes an explicit offer in §1.5, never silence;
  accepting it returns the task to the validation cycle — it never becomes a post-seal patch.
- The single new commit touches only harness metadata: pelizzai/data/state.md, the
  pelizzai/data/history/<YYYY-MM-DD>-<slug>.md the seal's migration just generated, and — only
  when §1.6 ratified them — pelizzai/data/verification-standard.md and pelizzai/data/learnings.md.
- Every §1.6 write is recommend-and-ratify: nothing lands in verification-standard.md or
  learnings.md without the user's explicit yes, and a decline is recorded, never silent.
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
- modified/untracked file other than `pelizzai/data/state.md`;
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
- Security       → pelizzai-security: auth/authorization, untrusted input, SQL/query, secret,
                   sensitive data, upload, deserialization, CORS/SSRF, header, new dependency.
- UI             → pelizzai-interface: component, page, screen route, style, visual state.
- Documentation  → pelizzai-docs: new stable human-facing surface — route,
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

## 1.6. Closure write-back — the delivery feeds pelizzai/data (recommend-and-ratify)

Consumer only; source mode skips this section (no `pelizzai/` runtime — a lesson about the
harness itself becomes a proposal through the normal task flow, per `pelizzai-evolve`). Run it
once, after the §1.5 net and BEFORE the destination offer (§2a): every ratified write below lands
in the working tree first and travels **inside the §2b closure commit** — never a second commit,
never after the seal. A delivery produces knowledge in three shapes, each with a versioned home
the happy path must feed — the migration at the seal erases whatever stays behind in the cursor.

**a) Baseline rows → `pelizzai/data/verification-standard.md`.** Cross the surfaces the final
validation approved (the same evidence §1.5 reads) against the Baseline table. A surface approved
with numbers different from its recorded row → propose the row's REPLACEMENT (replace, never
append; the superseded numbers survive in this task's `pelizzai/data/history/` file). The
closeout is the moment the new number is proven, and this is the deliberate ratified change the
standard demands — never during a correction: at this point the delivery is already approved and
sealed content, so the "fix the output, not the criterion" guard does not apply to it. Declined →
the stale row stays; record the gap in the destination report, because a baseline nobody replaces
judges the next regression against the wrong number.

**b) Incidents and recurrence → `pelizzai/data/learnings.md`.** Enumerate the defects CONFIRMED
during this delivery — including those found and fixed in review rounds inside a feature task,
not only work that entered as a bug: `pelizzai-diagnose` is one confirmation path, not the only
one. **Recurrence identity is deterministic:** an existing entry MATCHES a confirmed defect only
when its `root cause` names the same causal mechanism AND its `scope:` covers the defect's path —
symptom similarity is not identity, and a doubtful match is presented to the user, never resolved
silently. Entries with `status: candidate` or `promoted` count, in the active file and in every
archive; a `retired` entry never counts as recurrence — its failure mode was declared impossible,
so a new occurrence means the retirement was wrong: flag exactly that. For each confirmed defect:

- **No entry in the Incident log** → offer it ONCE as an incident candidate, with every
  `pelizzai-evolve` field (trigger, root cause, smallest durable fix, rule learned, scope,
  revert, `status: candidate`). An entry that was expected from the fix's own commit and is
  missing gets flagged as such — the offer repairs the omission, it does not normalize it.
- **Entry already present** → it is a **recurrence**. Count it over the WHOLE corpus
  (`learnings.md` plus every existing `pelizzai/data/history/learnings-<YYYY>.md`) and at 2–3
  occurrences offer the promotion via `pelizzai-evolve` (ratified, never automatic).
- **Recurrence with the rule ALREADY in Active rules** → not silence either: the standing rule
  did not prevent the defect, which is the worth-it gate's second condition — flag THAT to
  `pelizzai-evolve` in place of the promotion.

While touching the file, check its budgets **per section, never summed** — Active rules at or
past 40 lines, Incident log at or past 160, `verification-standard.md` at or past 150 — and
route the valve (retire / archive with pointer / split) to `pelizzai-evolve`: the ceilings are
hard, so reaching one already engages it.

**c) Marked lessons — swept from the cursor before the migration buries them.** Scan the block
the seal is about to migrate — the `## Progress` lines and the `data/reports/` files they link
(reports are git-ignored: this sweep is their only exit) — for the explicit `lesson(evolve):`
marker from the state template. The marker is the ONLY form the sweep recognizes; equivalence is
never inferred. A line that reads like a lesson but carries no marker is pointed out to the user
as exactly that — an unmarked candidate — and only the user's answer turns it into one: record
the absence, do not promote inferred text. Present each marked lesson for promotion or
registration via `pelizzai-evolve`. The migration keeps the block intact in `history/`, but
nobody re-reads history looking for rules: a lesson not swept here dies as archaeology.

The ratifications of (a)+(b)+(c) produce an explicit **allowlist** — the knowledge files
(`verification-standard.md`, `learnings.md`) actually ratified this closeout, possibly empty.
The §2b guards judge the closure against it.

Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP), open no ratification gate: report the
candidates — baseline deltas, incident candidates, marked lessons — to the coordinator and follow
the briefing.

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

### 2b. Seal the closure in `delivered` (metadata-only commit)

`delivered` = content sealed + destination executed; it is recorded BEFORE leaving the task branch
(it rides along in the PR). In the `pelizzai/data/state.md` already modified by the seal:

1. **Migrate the intact block and deflate the cursor** along the boundary defined in
   `pelizzai-execute` → §State and resumption: copy the task fields + the
   `T<n>`/`next`/`pending` lines faithfully into `pelizzai/data/history/<YYYY-MM-DD>-<slug>.md`
   (VERSIONED), return `## Active task` and `## Progress` to the template placeholders, and leave
   in `## History` **one** index line
   (`- <date> <slug> — delivered — <result ≤10 words> → data/history/<file>`). The cursor shrinks
   back to template size HERE, at closeout — it does not stay bloated through the whole
   `delivered` window. Preserve `slug`, `phase`, `branch`, `base-ref`, `base-sha`,
   `validated-head`, `commit-strategy`, `worktree-path`, and `confirm:`: the destination (Step 3)
   and the later observation still read them.
2. Set `phase: delivered` and record `confirm:` with the observable condition that becomes `done`,
   derived from the destination chosen in 2a: publish/PR → `base-ref contains validated-head
   (PR/branch integrated)`; keep local → `local delivery accepted by the user`; discard/archival
   (option 4) → `archived locally, no merge expected` (it is not a delivery onto a base: §3d
   decides archive or discard; the observation becomes `done` when the archive is accepted, or
   `abandoned` if discarded).
3. Check that the `## History` index line (step 1) is dated as `delivered`, without promising
   merge/`done` yet — that stamp comes from the later observation.
4. Update the date.

Stage **only** the harness metadata — the cursor, the history file the migration just generated,
and the `pelizzai/data/` files §1.6 ratified, when any (all of it travels in this same closure,
never in an extra commit):

```bash
git add -- pelizzai/data/state.md pelizzai/data/history/<YYYY-MM-DD>-<slug>.md
# only when §1.6 ratified writes to them:
git add -- pelizzai/data/verification-standard.md pelizzai/data/learnings.md
git diff --cached --name-only
git commit -m "chore: seal task as delivered"
```

Before executing the destination, prove the three guards:

```bash
# must equal EXACTLY state.md + the history file + the §1.6 allowlist, nothing more.
# A knowledge file listed here but NOT on the allowlist is an unratified write:
# the closeout is invalid — stop, unstage, do not commit.
git diff --name-only <validated-head>..HEAD

# no product difference outside the harness metadata (the two knowledge files are excluded
# here because the allowlist check above already judges them — excluded is not exempt)
git diff --quiet <validated-head>..HEAD -- . ':(exclude)pelizzai/data/state.md' ':(exclude)pelizzai/data/history/*' ':(exclude)pelizzai/data/verification-standard.md' ':(exclude)pelizzai/data/learnings.md'

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
only the closure metadata files: `pelizzai/data/state.md`, the
`pelizzai/data/history/<YYYY-MM-DD>-<slug>.md` generated by the seal's migration, and the
knowledge files on the §1.6 allowlist — nothing more. A knowledge file in the diff that the
allowlist does not name is an unratified write: stop, do not publish.
In source mode, require `delivery-head == validated-head`.
Diverged? Stop; do not publish.

### 3a. Publish without a PR

This publishes **the task branch**; it does not merge/push directly onto the base. Require a known
`origin` remote and push the closed SHA via an explicit refspec:

```bash
git push origin <delivery-head>:refs/heads/<branch>
git branch --set-upstream-to=origin/<branch> <branch>
```

Then confirm that `refs/heads/<branch>` on the remote points to `delivery-head` and record
`delivery-status: pushed`. Non-fast-forward, auth, network, or a divergent remote SHA fails
closed; do not force-push.

### 3b. Publish and open a PR

Do the exact same push and derive the base name from `base-ref` (for example,
`origin/trunk` → `trunk`). Then:

```bash
gh pr create --head <branch> --base <base-name> --title "..." --body "..."
```

The body carries the summary and the evidence/how to test. Without authentication, report the
blocker; do not switch the destination on your own.

On success, capture the returned URL, check the PR's head/base, and record
`delivery-status: pr-open` + the URL. This same transition closes a resumption that was `partial`.

Push and PR creation are separate checkpoints. If the push was confirmed and `gh pr create`
fails, record/report `delivery-status: partial`, the remote branch + SHA, and the PR error: the
content is already published, but the PR was not created. On resumption, reconcile the remote
branch and any existing PR; skip the already-confirmed push and repeat only the PR creation. Do
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
  elapsed; (b) full repo-scan since `last-full-scan`. Thresholds live in `pelizzai-skill-lab`
  → `references/domain-skill-maintenance.md`. Either one due → suggest **once** invoking
  `pelizzai-skill-lab` in maintenance mode, saying which trigger is due. Below the
  thresholds, say nothing; if the user defers, do not repeat it in the same session.
- **New stack adoption (adoption-driven):** check in this task's closed range
  (`git diff <base-sha>..<validated-head>` over manifests/lockfiles) whether a significant
  dependency or service was adopted without a covering domain skill. If so, propose ONCE creating
  the skill, grounded in context7/the official docs for the version pinned in the lockfile: "The
  task adopted `<lib@version>` with no covering domain skill. Create one now? [create · defer ·
  don't create]". Recommend `create` for high-leverage libs (auth, payments, ORM/data, framework,
  queue/sensitive infra) and `defer` for a trivial utility; the writing only happens after the
  "yes", via `pelizzai-skill-lab`.
- **Maintenance not armed:** if the cadence hook is installed but the ledger is missing, say so
  ONCE ("cadence inactive: no ledger; run the minimal initialization of `pelizzai-onboard` to arm
  it") to distinguish "off" from "broken".
- **Bulky state:** if `pelizzai/data/state.md` grew past ~60 lines, suggest compacting once
  (advisory) — the whole template is ~50. The intact-block migration to `data/history/` at the
  `delivered` seal already slims the state; condensing what remains is propose-and-confirm.

Source mode, or no hook and no ledger: silent no-op.

## Red flags

```text
- Delivering a sensitive, UI, or documentable surface without an overlay and without the §1.5 offer.
- A surface approved with new numbers, closed without the §1.6a Baseline replacement offer.
- A defect confirmed in review during a feature task, closed without the §1.6b incident offer.
- A lesson marked for pelizzai-evolve left to die in the cursor migration (§1.6c sweep skipped).
- Writing verification-standard.md or learnings.md at closeout without ratification — or in a
  second commit after the seal instead of inside the closure commit.
- Running the accepted overlay here, or patching with a fix/doc after the seal, instead of
  returning to the cycle.
- Repeating at closeout the offer of an overlay that already ran during execution.
- Declaring `phase: done` here (`pelizzai-finish` closes in `delivered`; `done` is observed later).
- Squash/reset/rebase/amend after validated-head.
- `git add -A` in the closure commit.
- A second cursor commit to record the destination.
- Pushing HEAD without comparing it to delivery-head, or pushing directly onto the base.
- Force-push, branch -D, worktree --force, automatic stash/reset.
- Treating multiple repositories as a single task.
```

## Integration

**Called by:** `pelizzai-execute`, `pelizzai-diagnose`, and `pelizzai-quick-fix`, only
after their overlays and validation have recorded `validated-head`.

**Combines with:** `pelizzai-isolate`, `pelizzai-verify`,
`pelizzai-review`, `pelizzai-resume`, and `pelizzai-merge-recovery`. The §1.5 net
points to `pelizzai-security`, `pelizzai-interface`, and `pelizzai-docs` — always via
the return to `pelizzai-execute`, never by running the overlay inside this skill. The §1.6
write-back is `pelizzai-evolve`'s ratified channel invoked at the delivery edge: the proposals
are made here, the doctrine of what enters each file stays there.
