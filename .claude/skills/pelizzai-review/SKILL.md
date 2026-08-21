---
name: pelizzai-review
description: Code review skill of the PelizzAI harness. Use after EVERY task during plan execution, when a relevant feature is complete, before integrating a delivery, or when the user asks for a review of a working tree, branch, or PR. Applies the spec and quality/evidence rubrics — ONE independent reviewer per task returning both verdicts, and two dispatches (blind spec + quality) on the final range — and teaches how to receive feedback with technical rigor. For security/OWASP, compose `pelizzai-oswap`.
---

# PelizzAI Review

## Goal

Catch problems before they propagate. The reviewer receives **fabricated context** — description, requirements/plan, and the diff — **never your session history**. That keeps the reviewer focused on the product, not on your reasoning, and preserves your context to continue.

**Announce on start**, in the conversation's language: that you are using the PelizzAI Review skill to review the code.

---

## Core principle

> Review early and often. A review is an independent verification of the product: actually read the
> code, do not trust the implementer's report, and give a clear verdict with evidence — never a
> "seems fine". The **depth** of each lens is proportional to risk; the **existence** of the review
> is not.

---

## When to review

```text
Mandatory:
- After EVERY task during plan execution (pelizzai-execute) — no exception for "it's simple".
  Risk changes the DEPTH of each rubric, never whether the review happens nor its form: every
  task gets ONE independent reviewer returning both verdicts, in every lane; the final range
  gets the two lenses in two dispatches.
- When a relevant feature is complete.
- On the final candidate of a planned delivery, before `validated-head` — and before integrating into the base.
- When the user asks for a review.

Optional, but valuable:
- When stuck (fresh perspective).
- Before a refactor (baseline).
- After fixing a complex bug.
```

---

## The two rubrics — one reviewer per task, two dispatches on the final range

During plan execution, each task passes through the **spec** rubric and the **quality/evidence**
rubric, in that order. The implementer has **not committed** — the code is in the working tree.

- **Spec rubric:** measures the real implementation against the task's contract, line by line —
  missing, extra, misunderstood — from the diff, the task's spec/plan, and the area's domain skills.
- **Quality/evidence rubric:** receives the author's report and **verifies the claims** — did the tests
  actually run? Is the proof fresh (command + output + exit code)? Were deviations from the plan
  declared? It actually runs the applicable checks to confirm or refute what the report asserts,
  besides assessing code quality.

**Per task, both rubrics go to ONE independent reviewer, in one dispatch, returning BOTH
verdicts** — in every lane, including a bounded task. There is nothing here for a plan to pick or
a user to ratify. The reviewer's independence comes from **fabricated context**: it receives the
task contract, the diff, the domain skills, and the author's report — never the session history,
never the coordinator's reasoning. The briefing places the spec rubric BEFORE the report and
instructs the reviewer to form the spec verdict by reading code against contract first — an
anchoring mitigation, stated as what it is, not sold as blindness.

**The truly BLIND spec lens lives at the final range, in its own dispatch.** That is where
blindness pays what it costs: a requirement that fell between two tasks passes every per-task
review and is only visible against the whole plan, judged without the delivery narrative. Per
task, a second sequential dispatch bought latency, not rigor — the per-task defect classes
(missing, extra, misunderstood) are caught by the same rubric with the contract in hand, and the
report the reviewer sees is precisely the thing its evidence rubric exists to verify.

**The rule behind the form.** The spec rubric exists wherever a **ratified contract** exists — a
plan, a task spec, an approved requirement, written BEFORE the diff. Per task it rides in the
single reviewer's first verdict; on the final range it becomes a blind, independent dispatch. A
flow that PRODUCES its own artifact with no prior requirement — a reported symptom, the harness
bootstrap itself — has nothing for the spec rubric to judge against: it dispatches the
quality/evidence lens with its `Verification` block, in its own dispatch, under
**[Standalone change review](#standalone-change-review)** below. Fabricating a contract so the
spec rubric has something to read — writing the spec after the fact, or handing the reviewer the
coordinator's own checklist — is the anti-pattern, not the compliance.

Two tombstones, kept honest. The `combined` **profile** (issue #24) died because a ratifiable
choice with one real answer was ritual; it stays dead — the per-task form is invariable, not a
menu. The per-task **two-dispatch split** (PR #25) died to issue #49: it serialized every task
behind two reviewer round-trips while every reference harness caps review at two dispatches in a
single pass, and the blindness it protected per task was mere briefing order — the real one was
always the final range's. Neither comes back by request.

**Proportionality without loosening the form:** what proportionality regulates is the **depth** of
each rubric — how much gets investigated, how many checks get run — never whether the review
happens, who reviews (always an independent reviewer), or the final range's two dispatches.

**Consolidation and conflict belong to the coordinator:** it reads the two verdicts and, when they
diverge from each other or from its own knowledge, decides with its own evidence (running the
disputed check itself) or escalates to the user. The coordinator **never reviews its own
delivery** — it has already seen the author's report and reasoning; per task the reviewer is an
independent agent, and on the final range the blind spec lens is always an independent reviewer.

### The task review — one dispatch, two verdicts

Use the **[references/task-reviewer.md](references/task-reviewer.md)** template. The reviewer
verifies, in this order, and returns BOTH verdicts — a report missing either one is incomplete:

```text
Spec verdict (form it BEFORE reading the report section):
- Missing: did they implement everything that was asked? Skipped or forgot any requirement?
  Claimed something works but never implemented it?
- Extra/unnecessary: built what was not asked? Over-engineering? "Nice to haves" outside the spec?
- Misunderstandings: interpreted differently from what was intended? Solved the wrong problem? Right, but the wrong way?
- Line-level traceability: does every changed line trace directly to a requirement of the request?
  A line with no trace is scope creep — a first-class finding, not a remark.

Quality/evidence verdict:
- The full quality rubric plus the Verification block: run the applicable checks, verify every
  claim in the implementer's report, and flag undeclared plan deviations.
```

Spec outcome: **✅ Matches the spec**, **❌ Issues** (with `file:line`), or **⚠️ Not verifiable** →
requires the coordinator's assessment against the plan before concluding (see `pelizzai-execute` →
`references/task-cycle.md` §3-§4). A claim the reviewer could not confirm by running the check is
**UNVERIFIED**, never ✅. Assess: separation of concerns, error handling, type safety, DRY without premature abstraction, edge cases, architecture, security, tests (they verify real behavior, not mocks), production readiness. Additionally:

```text
- Does each file have ONE clear responsibility and a well-defined interface?
- Are units decomposed so they can be understood and tested independently?
- Does the implementation follow the plan's file structure?
- Did this change create already-large files, or bloat existing files too much?
  (Do not flag pre-existing size — focus on what THIS change contributed.)
- Judge the change also against the project's DOMAIN SKILLS (`pelizzai/domain-skills.md` in a
  consumer; in source mode, the source repo's own rules/skills). In conflict with generic
  patterns, the domain skills and the project's rules PREVAIL.
```

If the reviewer flags a **sensitive surface** (auth, user input, query/SQL, secrets, upload, new dependencies), trigger `pelizzai-oswap` (OWASP) before concluding — do not leave security as a mere checklist item.

---

## Fresh evidence (Verification block, mandatory)

The quality reviewer selects and **actually runs** the checks that can prove the artifact
(test, lint, build, parser, render, dry-run, or scenario), pasting command, output, and exit code
into a `### Verification` block. Do not impose test/lint/build when there is no executable diff or
causal relation; codebase-wide architectural review uses `pelizzai-architecture-refinement`. **Do not
infer** pass/fail by reading the diff. A relevant check that could not run is **UNVERIFIED — never ✅**.

---

## How to dispatch the reviewer

Use an **independent reviewer** — always: the coordinator never applies the rubrics inline; there
is no inline mode. Per task, ONE reviewer runs both rubrics via
**[references/task-reviewer.md](references/task-reviewer.md)**. On the final range, TWO
dispatches: the blind spec lens uses
**[references/spec-reviewer.md](references/spec-reviewer.md)** and the quality/evidence lens uses
**[references/code-reviewer.md](references/code-reviewer.md)** — never merged into one briefing
there. Where no contract exists, only the quality/evidence lens goes out — still to another agent,
still in its own dispatch (see **[Standalone change review](#standalone-change-review)**).
Fill in with:

```text
- Description: what was built.
- Requirements/Plan: what it should do (task text or plan path in pelizzai/plans/).
- Implementer's report: the author's claims (tests run, proof, plan deviations). In the task
  review it fills the report section AFTER the spec rubric — the reviewer verifies it under the
  evidence rubric. On the final range it goes ONLY to the quality/evidence lens:
  NEVER to the blind spec lens — that lens judges the range against the plan, without the narrative.
- Diff to review:
  - Per task (one dispatch, both rubrics) → generate `review-package --working-tree`. The package contains,
    separately, `git diff --cached`, `git diff`, and the content of the untracked files. Do not use a range:
    the task has not been committed yet, and an empty range would hide all the work.
  - Final review → generate `review-package <base-sha> <HEAD_SHA>` and use the committed range.
    `base-sha` comes from the consumer `state.md` or the native execution record; do not rediscover the base.
- DOMAIN SKILLS for the area (pasted) — from the `pelizzai/domain-skills.md` catalog in a consumer, or
  from the source repo's rules/skills in source mode. They fill the `{DOMAIN_SKILLS}` slot of
  **every** template: the task reviewer and, on the final range, the blind spec lens (diff +
  spec/plan + domain skills) and the quality/evidence lens (the same skills plus the report). In a
  consumer, also paste the acceptance criteria of
  `pelizzai/data/verification-standard.md` when it exists — the reviewer judges against what
  "correct" means HERE, not against taste (see `pelizzai-evolve`).
  A domain skill promised but not pasted is a reviewer
  without the project's contract — paste the operational points, not just the names. With no coverage for the
  area, write "none" and ask the reviewer to flag the gap.
- Cross-cutting skills/overlays recorded in the state/execution record (pasted) — frontend, security,
  documentation, or any other applicable constraint is also part of the review contract.
```

Use `pwsh scripts/review-package.ps1 --working-tree` or
`sh scripts/review-package.sh --working-tree`. The helper writes a unique name into the consumer's
gitignored handoff dir, or into the system temp in source mode; pass that file to the reviewer. The
`<BASE> <HEAD>` mode is used in the delivery's final review; outside the lifecycle, only when the
user explicitly asked for a standalone range.

The reviewer **never** receives the session history.

---

## When there is no independent reviewer

Some environments cannot dispatch one: the platform has no subagent tool, a session instruction
forbids it, a cost/quota ceiling blocks it, or the run is headless with nobody to ask. The harness
does not pretend this never happens, and it does not leave the choice to improvisation.

**Detect and declare at the EDGE, not mid-task.** The place is step 2 of the setup gate
(`pelizzai-execute`), when the mode is being ratified — the capability is already knowable there,
and the code has not been written yet. Discovering it at review time means discovering it after the
work, when the cheapest options are already gone. In the `tweak`/`bug` tracks, the place is the head
skill's compact confirm (`pelizzai-quick-fix`/`pelizzai-debug`). **In the bootstrap, the place is
the reviewer-capability line of `pelizzai-audit` step 1**, before the first artifact. Every flow
that dispatches a review carries an edge of its own — a flow without one is a flow that discovers
the collision too late (see **[Who dispatches which lenses](#who-dispatches-which-lenses)**).

```text
Name the collision in one line, IN THE CONVERSATION'S LANGUAGE — what the harness requires (an
independent reviewer per task; on the final range, two dispatches with the blind one by an
independent agent), what this environment allows, and
why they conflict. Then offer:

(a) authorize the independent reviewer for the reviews of this task/delivery — the way out that
    costs nothing in rigor. Ask for it explicitly; the user may simply not know the harness
    needs it (see the mode note at the gate);
(b) accept a DECLARED non-independent review — the coordinator applies the rubrics itself, with
    real Verification (fresh runs), KNOWING it is not independent — and, on the final range, that
    its spec pass is not blind. Record it (below) and state it in the final report;
(c) defer the integration until there is a reviewer — the work is consolidated and stays
    unsealed; `validated-head` is not written.
```

**One lens is not inline.** A flow with no ratified contract dispatches ONE lens — the
quality/evidence one — and that lens still goes to an INDEPENDENT reviewer, in its own dispatch. So
the absent blind lens does not, by itself, resolve an environment that has no reviewer: the same
three options apply, unchanged, to the single lens. Read (b) there as "the quality/evidence lens is
applied by the coordinator, KNOWING it is not independent, with the fresh run required below", and
(c) as "the diff stays on its task branch, uncommitted and unsealed, until a reviewer exists". Under
(b), record `review-integrity: degraded <YYYY-MM-DD> — <reason>` exactly as in a two-lens flow: what
`degraded` marks is a lens the flow REQUIRED that did not run independently, and a single-lens flow
requires that one.

**(b) is the ONLY exception in the whole harness to the independent reviewer — and to the final
range's blindness — and it is not yours to take.** It requires the user's EXPLICIT choice, in this turn, under the same rule
as every other decision at the edges: the recommendation is not an answer, silence is not an
answer, and "the environment forced it" is not an answer. Without an explicit choice the route is
**(c)** — the work waits. An agent that reads this section and applies (b) on its own has not
followed the degradation path; it has taken the exception the path exists to keep ratifiable.

**With nobody to ask, (b) does not exist.** In a headless, cron, or CI run there is no one to
ratify, so the exception cannot be granted: the run takes (c), consolidates without sealing, and
reports what it needs. A process never grants itself the exception on the grounds that no one was
around to deny it.

**What never degrades**, in any of the three:

```text
- The coordinator does NOT dispatch itself as "the blind spec lens". Option (b) is not blindness
  under another name: it is an explicitly non-blind review, and it is announced as such.
- The review does not disappear, and the evidence bar does not move. The quality/evidence lens and
  its Verification block do not require a second agent, but the proof still requires a FRESH RUN —
  command, output, and exit code produced now, by whoever is reviewing. Output pasted by whoever
  implemented is NEVER evidence, and that rule does not relax here (`pelizzai-team` → evidence
  gate). When the coordinator both implemented and reviews, it RE-RUNS the checks itself: that is
  weaker than an independent run, and being weaker is part of what `degraded` records.
- Silence is not an option. A coordinator's self-review presented as a completed independent
  review is exactly the defect this whole section exists to prevent — and it is worse than the
  missing capability, because it is invisible.
```

**Record.** With option (b), write `review-integrity: degraded <YYYY-MM-DD>` in the consumer
`pelizzai/data/state.md` (or the native execution record) and name the reason. The marker travels:
it appears in the final report, it survives resumption in another session, and it blocks the final
review from treating that task's verdict as blind. A delivery that carries any `degraded` task
says so at the seal — the user decides whether to accept it, and decides knowing.

---

## Review-pipeline anti-corruption

These rules protect the review's independence (the other skills reference this section):

```text
- NEVER instruct the reviewer about what NOT to flag, nor pre-classify severity in the prompt —
  if the prompt you are writing contains "do not flag…", you are pre-judging the review.
- A finding caused by the plan ITSELF (the implementation followed what the plan mandated) goes up
  to the human — whoever wrote the plan does not grade their own work.
- Minors accumulate in a LEDGER and are triaged at the final review — a roll-up nobody reads is a
  silent discard.
- The final review's findings are fixed by ONE single fixer (one dispatch with all the
  findings) — never one fixer per finding.
```

---

## Severity and output format

The reviewer returns, in this structure (detail in `references/code-reviewer.md`):

```text
### Strengths        — what is well done (specific; accurate praise builds trust in the rest)
### Issues
  #### Critical      — bugs, security, data loss, broken functionality (fix now)
  #### Important     — architecture, missing feature, mishandled error, test gap (fix before moving on)
  #### Minor         — style, optimization, doc polish (note for later)
  (each issue: file:line, what is wrong, why it matters, how to fix)
### Recommendations
### Verification     — applicable checks actually RUN + output + exit code; relevant check not run = UNVERIFIED
### Assessment       — Ready to merge? [Yes | No | With fixes] + 1-2 sentences of rationale
```

Categorize by REAL severity — not everything is Critical; a nitpick is not Critical.

---

## Final branch review

When all tasks are complete, review the **entire branch** over the committed range
`<base-sha>..<HEAD>` — after the `squash-final` consolidation, when chosen — and not only per
task. Use independent reviewers, with the **session's model** — the one the user chose, never
a lesser one — and the **highest effort the platform allows**: the final review is the last filter
before the seal, not a place to economize on your own initiative nor to tune the process to
compensate for a lesser model. It is step 1 of the coordinator's
**final delivery validation** (`pelizzai-execute` → "Final delivery
validation") and happens **after** the overlays that may write (security, frontend, and documentation)
and before the full suite, checklist, and `pelizzai-final-verification`. Open
Critical/Important findings block completion.

**The final review uses the SAME two lenses, in the same two dispatches** — it is not a
quality-only pass:

```text
(a) Blind spec lens over the RANGE: receives the range diff + the full spec/plan (every requirement,
    not one task's text) + the area's domain skills. It does NOT receive the delivery narrative,
    the task reports, or the coordinator's summary. Its question is the one no per-task review can
    answer: does the delivery, taken whole, do what the plan promised — nothing missing between the
    tasks, nothing built that no requirement asked for?
(b) Quality/evidence lens over the same range: receives the delivery report and verifies it, runs
    the applicable checks from scratch, and fills the Verification block.
```

The blind lens matters more here than anywhere else. A per-task review sees one task's contract; a
requirement that fell **between** two tasks passes every per-task review and is only visible against
the whole plan. That is exactly the finding a reviewer holding the delivery narrative is least
likely to reach, because the narrative explains the delivery as complete.

**Tasks marked `review-integrity: degraded`** (see "When there is no independent reviewer") do not
become blind retroactively because the final review was blind: the final range is a different
object, and it does not re-review each task's contract line by line. List them at the seal, by name,
so the user accepts the delivery knowing which parts never had an independent spec lens. If the
capability came back, the honest move is to re-review those tasks before sealing — say so and let
the user decide.

**There is no reuse exception and no low-risk waiver.** A task's review is never promoted to the
final review, not even for a single bounded task with an identical tree SHA: the range is a
different object from the task — it carries the consolidation, the overlays that wrote, and the
plan as a whole — and the last filter before the seal is not where the harness economizes.

Any fix — from a finding, overlay, test, checklist, or visual verification — changes the candidate:
invalidate `validated-head`, consolidate the fix, re-run the affected overlays, and **reopen the
final review** over the new HEAD. "It was reviewed before the fix" does not count as approval.

### Who dispatches which lenses

The FORM of a review comes from the flow's contract, never from its risk. Every head skill that
dispatches one, and what it dispatches:

```text
- pelizzai-execute   — per task: ONE independent reviewer, both rubrics, both verdicts. On the
                       final range: TWO lenses, TWO dispatches — it executes a ratified plan/spec,
                       so the blind lens has the whole plan to judge the range against.
- pelizzai-debug     — standalone change review on the working tree (quality/evidence lens only);
                       then it consolidates the content, runs Verification against the HEAD, and
                       only then calls pelizzai-finish.
- pelizzai-audit     — the bootstrap diff: standalone change review (quality/evidence lens only),
                       because the bootstrap produces its own artifacts with no plan, no task spec,
                       and no approved requirement (pelizzai-audit → step 7).
- pelizzai-quick-fix — the tweak track waives formal review, for as long as it stays trivial.
```

A new head skill that dispatches a review belongs on this list, with its form derived from the rule
above. A flow missing from here is a flow nobody measured against the contract criterion — which is
exactly how the blind lens came to be demanded of a bootstrap that had nothing to show it.

### Standalone change review

A bug outside a plan, a tweak reclassified before the commit, or the harness bootstrap's own diff —
any change that produces its own artifact with no ratified contract. Use
`review-package --working-tree` (staged + unstaged + untracked) and apply the **quality/evidence
rubric** (`references/code-reviewer.md`) with the `Verification` block, **without** the per-task / final-review machinery. This is
**not** the task review minus paperwork: the spec rubric
is missing because there is no contract for it to judge against — no plan, no task spec, no
approved requirement, only a reported symptom or a set of artifacts the coordinator itself
produced. Where a contract exists, both rubrics apply. If the
change acquires one (a new surface, a ratified acceptance), it stops being standalone: reclassify
through the router and the full review form applies.

The fix→re-review loop is still **bounded** — dropping the per-task machinery does not drop the
limit. The dispatching skill declares its own at its closing step (`pelizzai-debug` step 4, over the
bug's working tree; `pelizzai-audit` step 7, over the bootstrap diff), in the same shape as
`pelizzai-execute` → `references/task-cycle.md` §5: count the cycles, escalate on the limit, record
`phase: blocked`, and leave the working tree INTACT.

A valid quick-fix does not enter this procedure. If the diff raises the risk, reclassify through the
router and apply the new route's review before the commit.

**Standalone review track:** recommend the scope derived from the request and from Git, and
**confirm when it is ambiguous** — working tree, `<BASE>..<HEAD>` range, and PR are materially
different interpretations; do not review the wrong target on an assumption. With a single plausible
reading, proceed without asking. Apply the quality lens + Verification. This track is read-only and
creates no state. A Critical finding is not fixed inside the review: it becomes a new bug/tweak
track via the router; the remaining findings are handed to the user for decision.

When the user authorizes **applying** the findings, apply **all of them** — Critical, Important, and
Minor (must/should/nice) in one consolidated dispatch, not only the Criticals; a roll-up nobody
fixes is a silent discard. Each finding that becomes a write follows the router's route
(quick-fix/tdd/debugging) and, after the fixes, **reopen the review** over the new content — "I
already reviewed before the fix" does not count.

Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP), produce no route analyses and open no gates: apply the briefing and escalate to the coordinator whatever requires a decision.

---

## Acting on the feedback

```text
- Critical → fix immediately.
- Important → fix before moving on.
- Minor → note for the final review.
- Reviewer wrong → push back with technical reasoning (show code/tests that prove it).
```

This feeds the `pelizzai-execute` circuit breaker (3 cycles per task, one budget shared by both
lenses; scoped re-review, effort escalation after a rejection, and resets in
`pelizzai-execute` → `references/task-cycle.md` §5).
**Protected-branch handback:** if acting on the feedback means writing code and there is no
isolation in the consumer state or native execution record, go through `pelizzai-starting-branch`
first — so the fixes do not land on a protected branch.

---

## Receiving review feedback (technical rigor, not performance)

```text
Response pattern: READ → UNDERSTAND (restate the requirement or ask) → VERIFY against the code →
ASSESS (is it technically correct for THIS project?) → RESPOND (technical acknowledgement or
grounded push back) → IMPLEMENT one item at a time, testing each one.

NEVER: "you're absolutely right", "great point", "great feedback", nor thanking — actions speak.
       Do not implement before verifying. Do not implement partially while items remain not understood
       (ask for clarification of ALL of them first — items may be related).
WHEN you fix it: "Fixed. [what changed]" — and the code shows you listened.
YAGNI: if the reviewer suggests "implementing it properly", grep the real usage; if it is unused, propose removing it.
Push back when: it breaks something existing, the reviewer lacks full context, it violates YAGNI, it is incorrect for the stack,
       or it conflicts with a user architecture decision — with technical reasoning, not defensiveness.
Cannot verify? Say: "I cannot verify this without [X] — investigate / ask / proceed?"
       (never implement blind).
On a GitHub PR, reply in the inline comment THREAD (not as a top-level PR comment).
```

---

## Anti-patterns / red flags

```text
- Skipping the review because "it's simple" — depth is proportional; the existence of the review is not.
- Skipping a review required by the lane, or shrinking it because the risk looks low.
- Collapsing the FINAL range review into a single dispatch, or skipping its blind spec lens —
  the final range is the one place the blindness uniquely pays, and it is not negotiable there.
- A task reviewer returning only one verdict — spec and quality/evidence are BOTH required, and a
  report missing either one is incomplete, not approved.
- Splitting the task review back into two sequential dispatches "for extra rigor" — that is the
  latency the form removed (issue #49), and the added rigor was briefing order, not blindness.
- Writing a spec/plan for a flow that has none just so the spec rubric can be applied "by the
  book" — a contract fabricated after the diff measures the diff against itself.
- Demanding the spec rubric of a flow that produces its own artifact (the bootstrap, a reported
  symptom), or dropping it where a ratified plan/spec exists.
- Running the final review with the quality lens only, or reusing a task's review as the final one.
- Discovering only at review time that this environment cannot dispatch a reviewer — the capability
  is checked when the mode is ratified, not after the code is written.
- Treating a missing reviewer as license to skip the review, or to self-dispatch as "the blind lens"
  and report a completed two-lens review. Degradation is legitimate; UNDECLARED degradation is the
  defect — and `review-integrity: degraded` is what makes it visible past this session.
- Promising domain skills to the reviewer and dispatching the briefing with the `{DOMAIN_SKILLS}` slot
  empty — the reviewer is left without the project contract it should judge against.
- Downgrading model or effort below the session's in a review (per-task or final) to save cost —
  capacity is the user's choice, and the harness never reduces it silently.
- Ignoring a Critical, or moving on with an Important open.
- Giving feedback on code you did not actually read.
- Marking a nitpick as Critical, or being vague ("improve error handling").
- Reporting as ✅ a check that did not run (evidence inferred from the diff).
- Passing the session history to the reviewer (it receives only fabricated context).
- Performative agreement when receiving feedback ("you're absolutely right", thanking).
- In the final review, dispatching quality/evidence before the blind spec lens passes, or both at once.
- Handing the delivery narrative, the task reports, or the coordinator's summary to the final
  blind spec lens — it judges the range against the plan, without the narrative; the lens that
  receives and verifies the report is quality/evidence.
- The coordinator dispatching itself as the blind spec lens: it has already seen the author's report
  and reasoning, so it cannot judge blind — the blind lens is always an independent reviewer.
- Instructing the reviewer about what NOT to flag, or pre-classifying severity in the prompt.
- Fixing the final review's findings with one fixer per finding (it is ONE fixer for all).
- Using `<BASE>..<HEAD>` in the per-task review; before the commit, the scope is always `--working-tree`.
- Accepting as final a review older than the last fix or overlay that wrote files.
```

---

## Integration

**Combines with:**

- `pelizzai-execute` — per-task review (one reviewer, both verdicts) and final review (two dispatches); see `task-cycle.md`.
- `pelizzai-tdd` — the tests the review checks are born from the TDD cycle.
- `pelizzai-starting-branch` — handback when acting on feedback turns into writing code.
- `pelizzai-reasoning` — *Critique and Refine* (acting on the feedback) and *Verification* (fresh evidence).
- `pelizzai-oswap` — the review's security (OWASP) dimension.
- `pelizzai-final-verification` / `pelizzai-finish` — completion after the final review.

---

## Final instruction for the agent

```text
Review the product, not the reasoning. Read the code; do not trust the report.

Prefer:
- fresh evidence (commands actually run) over "seems to pass";
- a clear verdict (Yes/No/With fixes) over "looks good";
- real severity over marking everything Critical;
- technical rigor over performative agreement when receiving feedback.

Review early and often: depth is proportional to risk, the existence of the review is not.
Per task: ONE independent reviewer, spec verdict first, quality/evidence verdict second — both
required. On the final range: two dispatches — the BLIND spec lens (range + full plan, no
narrative) approves before quality/evidence. Critical/Important before moving on; Minor for the end.
The spec rubric exists where a ratified contract exists. Where none does — a reported symptom, the harness bootstrap — the quality lens goes alone, to an independent reviewer, and inventing a contract to feed the spec rubric is the defect.
The coordinator crosses the verdicts and never reviews its own delivery; the final blind lens is always an independent reviewer.
Never pass the session history to the reviewer. For security, use pelizzai-oswap.
```
