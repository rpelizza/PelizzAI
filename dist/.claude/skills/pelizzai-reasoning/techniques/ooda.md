# OODA — Observe, Orient, Decide, Act

## Purpose

Run long or dynamic executions as a **macro loop** in which every iteration restarts from **current reality** — not from the previous iteration's snapshot. It is the formal lens of the harness's execution loop (`pelizzai-loop`, `pelizzai-execution-plans`) and of the `pelizzai-router`'s Sync & delta.

## Core principle

> Re-observe before deciding. Acting on an outdated mental model costs more than the `git status`/suite that would refresh it — and a loop without a Definition of Done is not discipline, it is drift.

## When to use

- Long looped execution until the Definition of Done (executing a plan task by task).
- Dynamic situations: the base moves forward (teammates pushed), tests/reviews return new information, dependencies change version.
- **Multi-round** investigations in which each round changes the hypotheses, the evidence, or what is worth doing next.
- Resuming a task after a pause/compaction (the world may have changed since the record).

## When to avoid

- Short single-action task — plain [ReAct](react.md) is enough there.
- Deterministic bug with direct repro→fix→verify — OODA is not a diagnostic technique and does not replace ReAct/RCA.
- Purely analytical work over static inputs (nothing changes between "iterations") — there is nothing to re-observe.
- When a specific circuit breaker already governs the loop (the task cycle's fix→re-review) — OODA is the lens, not a second counter.

## The cycle

```text
1. OBSERVE — collect external reality BEFORE deciding:
   git state (branch, delta from the base, new commits), fresh test/lint/build output,
   review verdicts, the task record (consumer state `pelizzai/data/state.md` or
   the native execution record in source mode) validated against reality.
   Observation is evidence collected now — not memory of the last iteration.

2. ORIENT — interpret what was observed against the goal:
   what does this change in the plan? Is the Definition of Done closer, or has a blocker appeared?
   Did an assumption fall (Assumption Tracking)? Does the observed delta affect THIS task?
   Re-read only what changed and matters — orienting is updating the model, not a full re-briefing.

3. DECIDE — choose the next highest-value action:
   next task in the plan / fix what failed / replan (evidence invalidated the path)
   / stop and ask (material doubt → pelizzai-interview-me) / escalate (circuit breaker)
   / conclude (DoD reached — confirm with Verification before declaring it).

4. ACT — execute the decision:
   inside Act live the ReAct micro-cycles (think → tool → observe the immediate result)
   and the executor skills (pelizzai-tdd, pelizzai-review, …).

5. REPEAT from OBSERVE — never from the previous iteration's mental model.
```

## Rules

- **An iteration never inherits the previous one's snapshot.** Re-observe before deciding; a `git status`/suite costs less than acting on stale reality.
- **Honest orientation:** if the evidence contradicts the plan, the plan loses — replan or escalate; do not continue with an outdated plan.
- **Recorded decisions:** during plan execution, every Decide advances the cursor — `pelizzai/data/state.md` in a consumer, the native execution record in source mode — and the loop survives compaction.
- **Stop criteria:** the canonical list of the loop's legitimate exits lives in `pelizzai-loop` (the five stop criteria: DoD verified; material doubt → `pelizzai-interview-me`; blocked → `phase: blocked` and escalate; evidence invalidated the path → replan; cost exceeds benefit → escalate/ask before insisting). Define the DoD **before** entering the loop.
- **Do not let it become ritual:** on a trivial task, the loop collapses to a single cycle — observe quickly, act, verify.

## Anti-patterns

```text
- Acting on the previous iteration's snapshot without re-observing (the base moved, you did not see it).
- "Orienting" while ignoring evidence that invalidates the plan (continuation bias).
- A loop with no stop criterion (infinite investigation) — define the DoD before entering the loop.
- Using OODA for a single-action task (overhead with no gain — use ReAct).
- Deciding without recording (the next cycle — or the next session — does not know where the loop was).
```

## Harness integration

- `pelizzai-loop` — the DoD and the stop-on-doubt rule are this loop's boundaries.
- `pelizzai-execution-plans` — the per-task macro loop IS an OODA loop (observe evidence → orient against the plan → decide the next task/fix → act via the recorded strategy + review).
- `pelizzai-router` (Sync & delta) — the task-start Observe: the git delta since the last task.
- `pelizzai-debugging` — uses OODA only as a macro lens when the investigation genuinely requires rounds; a direct cause or a short deterministic bug does not need it.
- [ReAct](react.md) — the micro-cycle inside Act. [Verification](verification.md) — confirms the DoD before leaving the loop.
