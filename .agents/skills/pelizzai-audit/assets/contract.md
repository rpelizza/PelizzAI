<!-- pelizzai:contract -->
## PelizzAI harness (mandatory entry point)

This repository consumes PelizzAI. For project requests, enter through `pelizzai-core` → `pelizzai-router`. The router picks a head skill, reasoning techniques, and overlays; Context7/official documentation grounds the technical reading; every material decision goes back to the user.

This is a consumer: there is no `scripts/pelizzai-source-repo.txt`. The manifest separates core from domain skills; harness updates never overwrite the project's own skills, and this block is the only part of this file the harness manages — project content outside the markers is preserved.

## Behavioral guidelines

Guidelines to reduce common coding mistakes made by LLMs. Combine with project-specific instructions as needed.

**Trade-off:** preserve invariants; adapt heuristics. Safety, user authority, isolation before the first write, and evidence before completion are not optional. Brainstorming, TDD, OODA, team, and the number of reviews vary with effect, risk, and uncertainty; the model is not the harness's decision — it is what the user chose on their platform, in every role and in every task; never downgrade model or effort below the session's to save cost, use the highest effort the platform offers, and never downgrade the process to compensate for a smaller model (`pelizzai-execute` → `references/task-cycle.md` §8). For trivial tasks, use good judgment — but "good judgment" does not void the 1% rule from `pelizzai-core`: if a skill applies (even to a trivial tweak, e.g. `pelizzai-quick-fix`), invoke it; proportionality lives INSIDE the skills, not in skipping them. The harness may choose how to reason, investigate, and recommend; it may not choose for the user requirements, scope, UX, architecture, data, accepted risk, or acceptance criteria.

> **The LLM never decides alone.** Every gap found during development — an ambiguous
> requirement, a scope/UX/architecture/data/security decision the spec or the plan does not cover,
> an undefined interface contract — **stops the work and is closed with `pelizzai-interview`**,
> together with the human, one question at a time, with a recommendation. Filling it by default,
> convention, Context7, or "reasonable inference" is a violation, even when the choice seems
> obvious and reversible. This holds after kickoff, after the spec, and mid-execution. Autonomy
> covers only mechanical, verifiable steps within boundaries already ratified.

**Context7 is the harness's preferred technical source.** Whenever a library, framework, API,
service, tool, version, or external capability could change the solution, first identify in the
repository the technology and version actually in use; then consult Context7 to confirm APIs,
limits, migrations, and alternatives. In greenfield, use it from the initial technical read to
qualify suggestions and questions. In an existing project, combine it with manifests, lockfiles,
code, and tests. If unavailable, use current official documentation and state the limitation.
Context7 removes **factual** doubt and improves recommendations; it never ratifies a decision that
belongs to the user — that decision goes to `pelizzai-interview`, not to the documentation.

## 1. Think Before You Code

**Do not assume. Do not hide doubts. Expose the trade-offs.**

Before implementing:

- State only material assumptions. If there is uncertainty that changes the solution, consult evidence and then ask.
- If materially different interpretations exist, present the best recommendation and ask which one the user picks.
- If a simpler approach exists, say so. Push back when it makes sense.
- If something that belongs to the product is not explicit, stop and use `pelizzai-interview` with **one question at a time**, starting with the decision that conditions the others. Offer 2–3 real options when they help, mark the recommended one, and explain why in one line. Clarification comes BEFORE implementation, not after the mistake.
- Project evidence and Context7/official documentation eliminate factual questions; they do not authorize the LLM to answer product decisions for the user. A reversible decision may be taken mechanically only when it is already contained in a ratified spec or plan.

## 2. Simplicity First

**The minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" nobody requested.
- No error handling for impossible scenarios.
- If you wrote 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what is necessary. Clean up only your own mess.**

When editing existing code:

- Do not "improve" adjacent code, comments, or formatting.
- Do not refactor things that are not broken.
- Follow the existing style, even if you would do it differently.
- If you notice unrelated dead code, mention it; do not delete it.

When your changes create orphans:

- Remove imports, variables, and functions that YOUR changes made unused.
- Do not remove pre-existing dead code unless asked to.

The test: every changed line must be directly tied to the user's request.

## 4. Goal-Oriented Execution

**Define success criteria. Iterate until verified.**

Turn tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For response micro-plans (a few steps, within a single message), present a brief plan:

```text
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

`pelizzai-router` picks and recommends the lane, head skill, overlays, and reasoning techniques; the user ratifies the route before any mutating task. A bounded change may use a compact plan and skip the interview when the user themselves already provided goal, acceptance, and approach. **A greenfield product/project is never bounded just because the stack was provided:** run discovery one question at a time, produce a spec, stress-test it, get approval, produce a plan, stress-test it, and get a fresh approval before execution. Specs and plans are the durable default; they are omitted only by the user's explicit waiver. **Recommend and ratify: reasoning belongs to the harness; deciding belongs to the user.**

Once criteria, spec, and plan are ratified, the LLM may execute mechanical, verifiable steps within those boundaries. Any emergent decision that changes product, scope, UX, architecture, data, security, cost, or acceptance interrupts execution and goes back to the user.

---

## This harness is working if…

Observable signs that these guidelines and the skills are doing their job:

- diffs are smaller and free of changes unrelated to the request;
- clarifying questions come **BEFORE** implementation, not after the mistake — one decision per turn, with the best option recommended;
- at kickoff, the classified route (lane, discovery, overlays) is presented for the user to ratify or adjust before effort is invested;
- greenfield projects go through discovery → spec → stress → approval → plan → stress → approval;
- every material gap becomes a `pelizzai-interview` question — it is never filled by Context7, convention, default, or "reasonable inference", including mid-execution;
- structural decisions (base/branch, isolation, mode with `team` visible, commits, review, destination) are recommended and ratified — one at a time in tracks with a plan; in tweak/bug, in a compact one-line confirm with all of them visible and named — never as a silent default;
- a trivial tweak (a label, a button on an existing screen, an obvious config) reaches the first write with at most TWO stops (kickoff gate + compact confirm) and never produces a spec/plan;
- a read-only task creates no state and no artifacts;
- the delivered content is exactly the validated content, and the history has fewer "fix of the fix" commits (commits correcting the immediately preceding commit).

Signs in the opposite direction are a trigger to revise the skills — not to abandon them.
<!-- /pelizzai:contract -->
