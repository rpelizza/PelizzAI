---
name: pelizzai-review
description: "Use after every task in plan execution, when a feature completes, before integrating, or when the user asks to review a working tree, branch, diff, or PR."
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
  The recorded profile (`split` by default, `combined` only by ratification) changes the FORM of the
  review, never whether it happens.
- When a relevant feature is complete.
- On the final candidate of a planned delivery, before `validated-head` — and before integrating into the base.
- When the user asks for a review.

Optional, but valuable:
- When stuck (fresh perspective).
- Before a refactor (baseline).
- After fixing a complex bug.
```

---

## Review profiles per task

During plan execution, each task passes through **two lenses with asymmetric blindness** — the
**spec** lens and the **quality/evidence** lens, in that order. The implementer has **not
committed** — the code is in the working tree. The asymmetry is deliberate:

- **Spec lens (blind):** receives ONLY the diff, the task's spec/plan, and the area's domain skills.
  **The spec lens reviewer does NOT receive the implementer's report — it judges the code against the contract, without the author's narrative.**
  Without the writer's story, it measures the real implementation against the request, line by line,
  without being anchored by the author's optimistic claims.
- **Quality/evidence lens:** receives the author's report and **verifies the claims** — did the tests
  actually run? Is the proof fresh (command + output + exit code)? Were deviations from the plan
  declared? It actually runs the applicable checks to confirm or refute what the report asserts,
  besides assessing code quality.

The plan picks the profile, which decides whether the lenses use one or two dispatches. **The
recommended default is `split`** — only with two dispatches does the blindness actually exist; in a
single dispatch it becomes mere reading order, and a reviewer who has already read the report cannot
unknow the author's narrative. `combined` is the **exception**, and the user ratifies it explicitly
at step 4 of the setup gate (`pelizzai-execute`).

| Profile | Predicate | Form |
| --- | --- | --- |
| `split` (**recommended by default**) | the normal case, including bounded tasks; **mandatory** for medium/high risk, sensitive surface, public contract, data, migration, multiple parts | the **blind** spec lens approves before the quality/evidence lens is dispatched; independent dispatches |
| `combined` (ratified exception) | bounded, low-risk, cohesive task, with no security/data/migration/public contract — **and** the user ratified the profile at the gate | one dispatch and one report; spec first, quality/evidence second — the blindness here is only logical (one pass, the reviewer sees everything) |

**Proportionality without loosening the blindness:** the asymmetric blindness of the two lenses lives in
`split`, which is the profile **recommended by default** — including for bounded tasks, in any lane.
What proportionality regulates is the **depth** of each lens (how much gets investigated, how many
checks get run), not whether the review happens nor whether it is blind. The profile reduces
handoffs, not criteria. If the diff reveals higher risk or `combined` takes a structural rejection,
promote to `split` without asking for a new ratification; downgrading to `combined` always requires
an explicit choice by the user.

**Consolidation and conflict belong to the coordinator:** it crosses the verdicts of the two lenses
and, when they diverge, decides with its own evidence (running the disputed check itself) or
escalates to the user. The coordinator is **never** the blind lens — it has already seen the author's
report and reasoning, so it cannot judge blind; the blind spec lens is always an independent reviewer.

### Stage 1 — Spec lens (compliance, blind)

Verify that the implementer built **exactly** what was asked — nothing more, nothing less.
In `split` (the default), this lens is **blind**: you do not receive the implementer's report — you
judge the diff against the contract, without the author's narrative. In a ratified `combined`, the
single reviewer does see the report, but applies this rubric **first**, measuring the code against
the request before reading any claim. In both: **actually read the code**, do not accept claims.

```text
- Missing: did they implement everything that was asked? Skipped or forgot any requirement?
  Claimed something works but never implemented it?
- Extra/unnecessary: built what was not asked? Over-engineering? "Nice to haves" outside the spec?
- Misunderstandings: interpreted differently from what was intended? Solved the wrong problem? Right, but the wrong way?
- Line-level traceability: does every changed line trace directly to a requirement of the request?
  A line with no trace is scope creep — a first-class finding, not a remark.
```

Use the **[references/spec-reviewer.md](references/spec-reviewer.md)** template (without running tests — Verification belongs to Stage 2). Outcome: **✅ Matches the spec** (everything checks out after code inspection), **❌ Issues** (list what is missing/extra, with `file:line`), or **⚠️ Not verifiable** → requires the coordinator's assessment against the plan before concluding (see `pelizzai-execute` → `references/task-cycle.md` §3-§4).

### Stage 2 — Quality/evidence lens

In the `split` profile, only dispatch this lens after spec passes. In `combined`, apply it in the
second part of the same report. **This is the lens that receives the implementer's report** and
verifies the claims — did the tests actually run? Is the proof fresh (command + output + exit
code)? Were deviations from the plan declared in the `Plan deviations:` field? A claim you could not
confirm by running the check is **UNVERIFIED**, never ✅. Use the full rubric in
**[references/code-reviewer.md](references/code-reviewer.md)**. Assess: separation of concerns, error handling, type safety, DRY without premature abstraction, edge cases, architecture, security, tests (they verify real behavior, not mocks), production readiness. Additionally:

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

If the reviewer flags a **sensitive surface** (auth, user input, query/SQL, secrets, upload, new dependencies), trigger `pelizzai-security` (OWASP) before concluding — do not leave security as a mere checklist item.

---

## Fresh evidence (Verification block, mandatory)

The quality reviewer selects and **actually runs** the checks that can prove the artifact
(test, lint, build, parser, render, dry-run, or scenario), pasting command, output, and exit code
into a `### Verification` block. Do not impose test/lint/build when there is no executable diff or
causal relation; codebase-wide architectural review uses `pelizzai-architecture`. **Do not
infer** pass/fail by reading the diff. A relevant check that could not run is **UNVERIFIED — never ✅**.

---

## How to dispatch the reviewer

Use an **independent reviewer** — it is the default: in `split` the blind spec lens must be another
agent, and the coordinator never embodies it. Only with a ratified `combined` may the coordinator
apply the two rubrics inline, and even then in the order spec → quality. The spec lens uses
**[references/spec-reviewer.md](references/spec-reviewer.md)**; quality/evidence and the final review use
**[references/code-reviewer.md](references/code-reviewer.md)**. In `combined`, merge the two
rubrics into a single briefing, keeping the order. Fill in with:

```text
- Description: what was built.
- Requirements/Plan: what it should do (task text or plan path in pelizzai/plans/).
- Implementer's report: the author's claims (tests run, proof, plan deviations). It goes
  ONLY to the quality/evidence lens (which verifies it) and to the single reviewer of `combined`.
  NEVER to the blind spec lens of `split` — it judges the code against the contract, without the narrative.
- Diff to review:
  - Per task (spec AND quality/evidence, combined or split) → generate `review-package --working-tree`. The package contains,
    separately, `git diff --cached`, `git diff`, and the content of the untracked files. Do not use a range:
    the task has not been committed yet, and an empty range would hide all the work.
  - Final review → generate `review-package <base-sha> <HEAD_SHA>` and use the committed range.
    `base-sha` comes from the consumer `state.md` or the native execution record; do not rediscover the base.
- DOMAIN SKILLS for the area (pasted) — from the `pelizzai/domain-skills.md` catalog in a consumer, or
  from the source repo's rules/skills in source mode. They fill the `{DOMAIN_SKILLS}` slot **of both
  templates**: the blind spec lens receives diff + spec/plan + domain skills; the quality/evidence lens
  receives the same skills plus the report. A domain skill promised but not pasted is a blind lens
  without a contract — paste the operational points, not just the names. With no coverage for the
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
task. Use an independent reviewer, with the **session's model** — the one the user chose, never
a lesser one — and the **highest effort the platform allows**: the final review is the last filter
before the seal, not a place to economize on your own initiative nor to tune the process to
compensate for a lesser model. It is step 1 of the coordinator's
**final delivery validation** (`pelizzai-execute` → "Final delivery
validation") and happens **after** the overlays that may write (security, frontend, and documentation)
and before the full suite, checklist, and `pelizzai-verify`. Open
Critical/Important findings block completion.

Reuse exception (narrow, and never the default path): a plan of **a single bounded task**,
with `read-only` or `write-local` effect, low risk, `combined` profile ratified by the user, with no
findings and no later content mutation may treat the task's review as the final review when
the post-commit tree SHA is exactly the reviewed candidate tree SHA. Keep the checks, checklist, and
Verification. If even **one** of these items is missing — `write-shared`/production effect,
medium/high risk, sensitive surface (security, data, migration, public contract), `split` profile
(the default), multiple tasks, a later overlay/fix, compaction without evidence, or any doubt — the
normal final review becomes mandatory again. The exception exists to avoid duplicating a provably
identical review, not to waive the final validation.

Any fix — from a finding, overlay, test, checklist, or visual verification — changes the candidate:
invalidate `validated-head`, consolidate the fix, re-run the affected overlays, and **reopen the
final review** over the new HEAD. "It was reviewed before the fix" does not count as approval.

**Who triggers the final review:** `pelizzai-execute` (plan closeout). A bug fix
(`pelizzai-diagnose`) uses the **standalone change review** below while still in the working tree;
then debugging consolidates the content, runs Verification against the HEAD, and only then calls
finish-task. The tweak track (`pelizzai-quick-fix`) waives formal review as long as it stays trivial.

**Standalone change review** (a bug outside a plan, or a tweak reclassified before the commit): use
`review-package --working-tree` (staged + unstaged + untracked) and apply **Stage 2**
(quality) with the `Verification` block, **without** the per-task / final-review /
circuit-breaker machinery.

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

This feeds the `pelizzai-execute` circuit breaker (3 cycles per lens, per task;
detail and resets in `pelizzai-execute` → `references/task-cycle.md` §5).
**Protected-branch handback:** if acting on the feedback means writing code and there is no
isolation in the consumer state or native execution record, go through `pelizzai-isolate`
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
- Skipping a review required by the lane/profile, or downgrading the profile despite new risk.
- Using `combined` on your own: the default is `split`, and the downgrade requires the user's
  explicit ratification at the gate.
- Promising domain skills to the reviewer and dispatching the briefing with the `{DOMAIN_SKILLS}` slot
  empty — the blind lens is left without the project contract it should judge against.
- Downgrading model or effort below the session's in a review (per-task or final) to save cost —
  capacity is the user's choice, and the harness never reduces it silently.
- Ignoring a Critical, or moving on with an Important open.
- Giving feedback on code you did not actually read.
- Marking a nitpick as Critical, or being vague ("improve error handling").
- Reporting as ✅ a check that did not run (evidence inferred from the diff).
- Passing the session history to the reviewer (it receives only fabricated context).
- Performative agreement when receiving feedback ("you're absolutely right", thanking).
- In the split profile, dispatching quality/evidence before spec passes; in combined, inverting the lenses.
- Handing the implementer's report to the blind spec lens of split — it judges the code against the
  contract, without the author's narrative; the lens that receives and verifies the report is quality/evidence.
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

- `pelizzai-execute` — per-task review (combined/split) and final review; see `task-cycle.md`.
- `pelizzai-tdd` — the tests the review checks are born from the TDD cycle.
- `pelizzai-isolate` — handback when acting on feedback turns into writing code.
- `pelizzai-security` — the review's security (OWASP) dimension.
- `pelizzai-verify` / `pelizzai-finish` — completion after the final review.

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
Spec first, quality/evidence second — in TWO dispatches by default (`split`); a single dispatch (`combined`) only with the user's explicit ratification. Critical/Important before moving on; Minor for the end.
In split, the spec lens is blind (no report) and receives diff + spec/plan + the area's domain skills; the quality/evidence lens receives and verifies the report. The coordinator crosses the lenses and is never the blind lens.
Never pass the session history to the reviewer. For security, use pelizzai-security.
```
