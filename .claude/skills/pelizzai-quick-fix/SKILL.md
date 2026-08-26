---
name: pelizzai-quick-fix
description: "Head skill for a local, cohesive, clear, low-risk tweak — text, label, color, button, or field on an existing screen, a constant, a mechanical rename/refactor, an obvious configuration. Typical signals: ~1 file and under ~50 lines (scale signals, not hard limits). Public surface = a NEW route, command, endpoint, API, or config — a tweak creates none of them and changes no business rule. Something broken uses `pelizzai-debugging`; a new surface/contract or a design decision reclassifies through the router's lane."
---

# PelizzAI Quick Fix

## Goal

A lean path for trivial changes. It avoids the cost of design + plan when there is no architecture
decision to make — **without** giving up an isolated branch, verification, and closeout.

**Announce at start**, in the conversation's language: that you are using the PelizzAI Quick Fix skill for this one-off tweak.

> **Principle:** trivial ≠ sloppy. Skip the design, not the discipline.

## Criteria without hard counts

It is a `quick-fix` when the change:

```text
- goal and acceptance are unambiguous;
- the change is local, cohesive, reversible, and low-risk;
- it does NOT create a public surface — a new route, command, endpoint, API, or config — nor
  changes a business rule or decides architecture (a button, field, or label on an existing
  screen is NOT a public surface: it is a tweak);
- proof and rollback are direct;
- the expected diff is small enough that a formal review would add no material signal
  (~1 file and <~50 lines are the typical scale signals, not hard limits).
```

Lines and files help detect growth, but they never decide alone. Clear acceptance is an ENTRY
criterion of the quick-fix, never a reason for promotion. Promote only when something new appears:
a NEW public surface/contract with clear acceptance → `bounded` lane and a compact plan; a real
design decision or uncertainty → `standard`/`exploratory` and proportional brainstorming. In doubt
between tweak and bounded, recommend `tweak` at kickoff — promoting later is cheap; a plan to swap
a button is not. Something **broken** uses debugging.

## Process

`pelizzai-router` computes the recommendations for this tweak; this head skill is the sole emitter
of the setup. A tweak uses the **compact one-line confirm** — not the post-plan gate's question
menu. `pelizzai-starting-branch` discovers the base and proposes the name WITHOUT a stop of its
own (a base with no unambiguous candidate still stops there); the head skill presents everything
in one line, with the decisions visible and named, and waits:

`Kickoff: quick-fix on branch <type>/<slug> @ <base-ref> (<short-sha>) — isolation: branch · mode: inline · commits: granular. Ok? (overrides: worktree · subagents/team · squash-final · different name/base)`

One "ok" ratifies base, name, and the three decisions at once — all are named in the line, nothing
was silent; a named override adjusts only that item and keeps the rest. Only then is the branch
created. Do not scatter this line across separate questions: the one-decision-per-turn menu
belongs to the post-plan gate of the tracks with a plan. Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP),
open no gates: apply the briefing and escalate to the coordinator whatever requires a decision.

```text
1. Branch — pelizzai-starting-branch discovers the base and proposes `<type>/<slug>`; ratification
   happens in the compact confirm above and only after it is the branch created (never on a
   protected branch).
1.5. Local rules — in a consumer, check `pelizzai/domain-skills.md`; in source mode, use the repo's
   own rules/skills. Follow only those applicable to the area.
1.6. Record the ratification (after the compact confirm's "ok") — write the marker `kickoff: ratified <YYYY-MM-DD>`
   (with `isolation`/`execution-mode`/`commit-strategy` ratified) in the consumer state
   `pelizzai/data/state.md` or, in source mode, in the native execution record with the same keyword,
   BEFORE the first product write. The head skill is the sole owner of this marker in the `tweak`
   track; without it the writegate (Rule B) blocks the first product write and resumption does not
   recognize the gate.
2. Change + minimal verification — every changed line must trace directly to the request
   (a line without a trace is scope creep: remove it or escalate). Choose the bucket honestly:
   - Testable behavior (constant, condition, return value): pelizzai-tdd — smallest failing test first, then the change.
   - Behavior-preserving refactor (rename/extract/inline): do NOT fabricate a RED — ensure characterization/a green suite first, refactor in a small step, and run the same proof after.
   - Config/IaC/migration: use validate/plan/dry-run and check compatibility/rollback; unit tests only for separable logic.
   - UI/CSS/visual state: mandatorily apply pelizzai-frontend and use the proportional visual
     proof defined there; TDD enters only if there is behavior.
   - Documentation, label, or copy: lint/links/build-render or proportional static inspection; nothing to unit-test.
   Do not self-classify a behavior change as "cosmetic"/"config" to skip the test.
3. Prove the working tree — run the proof selected above and, when there is executable code, the
   project's relevant suite. Fix before consolidating.
3.5. Commit the **content** with exact paths and a definitive message
   `<type>(<scope>): <description>`. A quick-fix already produces a single commit; do not create
   WIP nor leave a squash for finish-task.
4. Seal and close — run `pelizzai-verification-before-completion` against that HEAD, record
   `validated-head` only after success, and invoke `pelizzai-finish-task`: a consumer adds
   only the metadata closure (state + the task's history file);
   source mode closes the execution record without a closure file/commit.
```

> The tweak track skips formal review only while it stays low-risk, cohesive, and without a new
> surface/rule. The adequate proof + Verification cover the closeout. If the diff reveals risk,
> promote the lane and apply `pelizzai-review` before consolidating.

---

## Red flags

```text
Never: treat as quick-fix something that creates a new surface or changes a business rule; promote
       to bounded/plan just because the acceptance is clear (clear acceptance is an entry
       criterion, not a promotion trigger); scatter the compact confirm across separate questions;
       skip the isolated branch ("it's just a tiny bit of text" — the protected-branch gate applies
       all the same); skip the verification; insist on the light path after the change has grown
       (escalate to feature).
```

---

## Integration

**Routed by:** `pelizzai-router` (track `tweak`).

**Uses:** `pelizzai-starting-branch`, local rules/skills, `pelizzai-reasoning` (strategy
selection), `pelizzai-tdd` only for behavior, `pelizzai-frontend` as the mandatory overlay
for UI, `pelizzai-verification-before-completion`, and `pelizzai-finish-task`.

**Escalates to:** `pelizzai-writing-plans` for bounded, `pelizzai-brainstorming` when there is a
design decision or uncertainty, or `pelizzai-debugging` when it is a bug.
