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
  The per-task form is fixed: ONE independent dispatch, both verdicts (below); risk changes the
  DEPTH of each rubric, never whether the review happens.
- When a relevant feature is complete.
- On the final candidate of a planned delivery, before `validated-head` — and before integrating into the base.
- When the user asks for a review.

Optional, but valuable:
- When stuck (fresh perspective).
- Before a refactor (baseline).
- After fixing a complex bug.
```

---

## Task review: one independent reviewer, both verdicts

During plan execution, each task is reviewed by **ONE independent reviewer in ONE dispatch**,
applying the **spec** rubric and then the **quality/evidence** rubric, in that order — in any
lane, including bounded. The implementer has **not committed** — the code is in the working tree.
There is no profile to pick: the sequential split-per-task was the harness's largest latency
multiplier, and the per-task blindness it bought was reading order, not blindness. The
**truly blind spec lens runs on the FINAL range**, in its own dispatch (§Final branch review) —
that is also where a requirement that fell between tasks becomes visible.

The reviewer's independence comes from **fabricated context**: it receives the task contract, the
diff, the area's domain skills, and the author's report — never the session history, and never the
coordinator's opinion. The briefing template is
**[references/task-reviewer.md](references/task-reviewer.md)**; it places the spec rubric BEFORE
the report section and instructs the reviewer to form the spec verdict reading code against
contract first.

**Proportionality regulates depth, never existence:** how much each rubric investigates and how
many checks it runs scale with risk; who reviews does not — always an independent reviewer, never
the coordinator grading its own delivery.

**Consolidation and conflict belong to the coordinator:** it reads the two verdicts and, when they
diverge — or clash with its own knowledge — decides with its OWN evidence (running the disputed
check itself) or escalates to the user. The author's narrative never arbitrates.

### Rubric 1 — Spec compliance (formed before reading the report)

Verify that the implementer built **exactly** what was asked — nothing more, nothing less. Form
this verdict measuring the code against the request BEFORE reading any claim in the report.
**Actually read the code**, do not accept claims.

```text
- Missing: did they implement everything that was asked? Skipped or forgot any requirement?
  Claimed something works but never implemented it?
- Extra/unnecessary: built what was not asked? Over-engineering? "Nice to haves" outside the spec?
- Misunderstandings: interpreted differently from what was intended? Solved the wrong problem? Right, but the wrong way?
- Line-level traceability: does every changed line trace directly to a requirement of the request?
  A line with no trace is scope creep — a first-class finding, not a remark.
```

Per task, this rubric lives inside **[references/task-reviewer.md](references/task-reviewer.md)**;
on the final range, the standalone blind dispatch uses
**[references/spec-reviewer.md](references/spec-reviewer.md)** (without running tests —
Verification belongs to the quality rubric). Outcome: **✅ Matches the spec** (everything checks
out after code inspection), **❌ Issues** (list what is missing/extra, with `file:line`), or
**⚠️ Not verifiable** → requires the coordinator's assessment against the plan before concluding
(see `pelizzai-execute` → `references/task-cycle.md` §3-§4).

### Rubric 2 — Quality/evidence

Applied after the spec verdict is formed. **This is the rubric that receives the implementer's report** and
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

Use an **independent reviewer** — always: the coordinator never grades its own delivery. Per task,
one dispatch with **[references/task-reviewer.md](references/task-reviewer.md)** (both rubrics, in
order). On the final range, two dispatches: the blind spec lens with
**[references/spec-reviewer.md](references/spec-reviewer.md)** and quality/evidence with
**[references/code-reviewer.md](references/code-reviewer.md)**. When no independent reviewer can
be dispatched in the environment, the degradation is DECLARED, never silent — and it is a last
resort for environments that CANNOT dispatch (headless, no subagent tooling), not for a dispatch
that failed once: retry or repair the dispatch before degrading, because the inline fallback is
self-review by nature. Only then does the coordinator apply the rubrics inline, in order, with the
report's first line stating `review degraded: single-context (<reason>)` — inconvenient does not
count as unavailable, and a declared degradation never blocks the delivery seal from naming it.
Fill in with:

```text
- Description: what was built.
- Requirements/Plan: what it should do (task text or plan path in pelizzai/plans/).
- Implementer's report: the author's claims (tests run, proof, plan deviations). It goes to the
  task reviewer (whose template forms the spec verdict BEFORE reading it) and to the final range's
  quality/evidence lens. NEVER to the final range's blind spec lens — that one judges the code
  against the contract, without the narrative.
- Diff to review:
  - Per task → generate `review-package --working-tree`. The package contains,
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
with `read-only` or `write-local` effect, low risk, with no
findings and no later content mutation may treat the task's review as the final review when
the post-commit tree SHA is exactly the reviewed candidate tree SHA. Keep the checks, checklist, and
Verification. If even **one** of these items is missing — `write-shared`/production effect,
medium/high risk, sensitive surface (security, data, migration, public contract),
multiple tasks, a later overlay/fix, compaction without evidence, or any doubt — the
normal final review becomes mandatory again. The exception exists to avoid duplicating a provably
identical review, not to waive the final validation.

Any fix — from a finding, overlay, test, checklist, or visual verification — changes the candidate:
invalidate `validated-head`, consolidate the fix, re-run the affected overlays, and **reopen the
final review** over the new HEAD. "It was reviewed before the fix" does not count as approval.

**Who triggers the final review:** `pelizzai-execute` (plan closeout). A bug fix
(`pelizzai-diagnose`) uses the **standalone change review** below while still in the working tree;
then debugging consolidates the content, runs Verification against the HEAD, and only then calls
`pelizzai-finish`. The tweak track (`pelizzai-quick-fix`) waives formal review as long as it stays trivial.

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

This feeds the `pelizzai-execute` circuit breaker (5 rounds per task in three regimes, then the
breaker adjudicates; detail and resets in `pelizzai-execute` → `references/task-cycle.md` §5).
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
- Skipping the per-task dispatch, or degrading to inline rubrics without the DECLARED
  `review degraded: single-context` first line.
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
- Inverting the rubric order (quality before spec), per task or on the final range.
- Handing the implementer's report to the final range's blind spec lens — it judges the code
  against the contract, without the author's narrative.
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

- `pelizzai-execute` — per-task review (one dispatch, both verdicts) and final review; see `task-cycle.md`.
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
Per task: ONE independent dispatch, spec verdict formed before the report is read, then quality/evidence. Final range: the blind spec lens in its own dispatch, then quality/evidence. Critical/Important before moving on; Minor for the end.
The final range's spec lens is blind (no report) and receives diff + spec/plan + the area's domain skills; the quality/evidence lens receives and verifies the report. The coordinator crosses the verdicts and is never the blind lens.
Never pass the session history to the reviewer. For security, use pelizzai-security.
```
