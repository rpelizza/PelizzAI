---
name: pelizzai-loop
description: "Use to drive macro loops to delivery — task-by-task execution, fix and re-review, or investigation in rounds — with OODA, a Definition of Done, and an explicit stop criterion."
---

# PelizzAI Loop

## Goal

Give the harness the discipline of the **loop**: repeat the work cycle until delivery **with an explicit stop criterion** — never quitting early, never iterating forever, never declaring done without the Definition of Done reached and verified.

**Announce on start (when triggered explicitly)**, in the conversation's language: that you are using the PelizzAI Loop skill to iterate until the Definition of Done.

---

## The macro loop is OODA

**Macro** loops, in which reality can change between iterations, follow **OODA** (full technique: [references/ooda.md](references/ooda.md)):

```text
OBSERVE — collect CURRENT reality: git, fresh test/lint/build output, review verdicts,
          the task record (consumer state or native execution record) validated against
          the real thing. Never the previous iteration's snapshot.
ORIENT  — interpret against the goal: what changed? is the DoD closer? did a premise fall?
DECIDE  — next task / fix / replan / stop and ask / escalate / conclude.
ACT     — execute (this is where TDD, review, and the tools live — the ReAct micro-cycles).
REPEAT  — from OBSERVE, until the Definition of Done.
```

Where this loop runs in the harness:

| Loop                                    | Driven by                       | What this skill contributes           |
| --------------------------------------- | ------------------------------- | ------------------------------------- |
| Task-by-task plan                       | `pelizzai-execute`      | OODA lens + DoD + stop on doubt       |
| fix → re-review                         | `pelizzai-review` + task-cycle  | re-observe (re-review) after each fix |
| Multi-round investigation               | `pelizzai-team` / `pelizzai-diagnose` | reorientation on new evidence   |

RED→GREEN and tool calls are TDD/ReAct micro-cycles inside **Act**; do not repeat the OODA vocabulary on every test. A direct bug with a single repro→fix→verify sequence does not trigger this skill.

## Definition of Done (DoD)

The loop only ends when the DoD is reached **and verified** (`pelizzai-verify`). Define the DoD **before** entering the loop:

```text
- For a plan: all tasks delivered + the coordinator's final validation (final review of the branch,
  full suite green with evidence, requirement-by-requirement checklist of the plan).
- For a task: effect delivered with the strategy recorded in the plan (TDD, characterization, validate/dry-run, visual, or static), spec ✅ and quality ✅ with fresh evidence.
- For a bug fix: original symptom now green through the adequate oracle; red→green regression when there is automatable behavior; no relevant regression.
- For a specification/workflow: whoever executes it can work without asking ONE question —
  while doubt remains, it is not ready.
```

"Almost everything" is not a DoD. An undelivered requirement = the loop continues.

## Stop criteria (legitimate exits from the loop)

```text
1. DoD reached and VERIFIED (fresh evidence) → conclude.
2. Material decision mid-loop → STOP and trigger `pelizzai-interview`; resolve one question
   at a time, with a recommendation, and only resume when no human decision is pending.
3. A blocker you cannot resolve (circuit breaker tripped, a decision that belongs to the human)
   → record phase: blocked in the consumer state or native execution record and escalate with
   an actionable message.
4. Evidence invalidated the path → replan (go back to the plan/design); do not insist.
5. Cost of continuing exceeds the benefit (investigation/rounds without their own circuit breaker
   that stopped yielding information) → escalate or ask before insisting; never exit
   silently out of fatigue.
```

Outside these five, do not ask permission for every already-approved mechanical step. Continuous
execution is not decision autonomy: any new product choice triggers criterion 2. These five
criteria are the canonical list; `references/ooda.md` points back to it.

---

## Optional lens: loops as delegable workflows

Outside code execution, a "loop" is also a recurring pattern in the user's life (routine, week, repeated activity). A **workflow** is the specification of such a loop; useful vocabulary when specifying one: **Trigger** (event or schedule that fires each run), **Checkpoint** (human decision point), **Push right** (defer the checkpoint until everything is ready), **Brief** (executive summary ready for decision, never the raw result). Use this lens only when the user is specifying automations/routines — do not impose it on the code flow.

---

## Integration

- `pelizzai-execute` — drives the macro loop of plans with this lens (OODA + DoD + stop on doubt).
- [references/ooda.md](references/ooda.md) — the full OODA technique; `pelizzai-verify` confirms the DoD.
- `pelizzai-tdd` — micro-cycle for behavior when that is the selected strategy; does not make OODA mandatory.
- `pelizzai-interview` — mandatory destination of the stop for material doubt.
- `pelizzai-verify` — no loop exit without fresh evidence.
- `pelizzai-router` — Sync & delta is the Observe at the start of each task.
