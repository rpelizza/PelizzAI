# Trigger test — proving the skill actually fires

A skill that never triggers is dead weight in the catalog: the work of writing it is spent, and the failure it was meant to prevent keeps happening. **Under-triggering is the harness's dominant failure**, so triggering is verified by measurement, not by rereading the description and finding it convincing.

This is the routing counterpart of the RED baseline in [skill-authoring.md](skill-authoring.md): the baseline proves the skill's rules change behavior once loaded; the trigger test proves the skill gets loaded at all.

## When it is mandatory

```text
MANDATORY:
- a new domain skill, before it enters the catalog;
- any edit that touches the `description` (the description IS the router — an edit can
  silently break triggering);
- splitting a skill in two, or narrowing/broadening a trigger.

NOT required (the evidence ladder in skill-authoring.md applies instead):
- an editorial edit — typo, formatting, broken link;
- a body-only change that does not touch the description and does not alter which
  tasks should invoke the skill.
```

Maintenance is included: a `refresh` that rewrites the description re-enters this gate. A version bump that only corrects a technical fact inside the body does not.

## Protocol

1. **Write the probe task.** A realistic, small task in the skill's domain — a bug to diagnose, a small feature to plan, a question — phrased the way this project's users actually phrase requests. The probe **never names the skill** and should naturally contain some of the tokens the description relies on: that is what makes it realistic, and what makes the test honest.
2. **Dispatch a fresh subagent** via `pelizzai-subagents`, with clean context: the probe task and the repository, and nothing from the conversation where the skill was written. The subagent has to discover the skill through normal routing — never because it was told the skill exists.
   **The probe is READ-ONLY.** A subagent shares the task's working tree (`pelizzai-subagents`: a worktree does not isolate agents from each other), so a probe allowed to write would mutate the very delivery under review, and the gate would dirty what it is verifying. Brief the subagent to diagnose, plan, and report — never to edit, commit, or clean. Both verdicts below are readable in its report; neither needs a byte written. If a scenario genuinely cannot be answered without executing, run it in a disposable copy outside the task's tree and discard it before judging.
3. **Judge against both criteria:**
   - **Triggered** — the subagent invoked/read the skill before substantive work on the task.
   - **Followed** — at least one of the skill's rules visibly shaped the output: a convention applied, a trap avoided, the verification run.

Both criteria met → the gate passes. Only one → it fails; a skill that is read and ignored is as dead as one never read.

## Failure diagnosis

| Symptom | Likely cause | Fix |
|---|---|---|
| Skill never invoked | The description lacks the concrete tokens real tasks contain | Add the paths, domain terms, and symptoms from the probe to the description |
| Invoked, rules ignored | The description summarizes the workflow (the agent thinks it already knows), or the key rule is buried deep in the body | Cut the summary from the description; raise the rule to the top of its section |
| A different skill fired | Trigger overlap between siblings | Sharpen both descriptions until the probe has one obvious owner |
| The subagent invented conventions | The body is abstract — no real example to anchor on | Replace the abstraction with the worked example from the evidence step |

## Round budget

Each failed test consumes one round: diagnose, adjust, and dispatch a **new** fresh subagent — never reuse one that has already seen the skill discussed, since its context is contaminated and the next pass proves nothing.

**After 3 failed rounds, stop.** Escalate through `pelizzai-interview-me` with the probe task, the three diagnoses, and what changed in each round. Three failures usually mean the skill is mis-scoped — wrong granularity or wrong domain boundary — and scope is a decision that belongs to the user, not a fourth attempt by the harness.

## Batch bootstrap

At bootstrap, N candidate skills are written in parallel. The trigger test stays per skill — one probe per skill, judged on its own — but two rules keep it honest:

```text
- Probes run AFTER the whole batch is written, never against a half-populated catalog:
  overlap between two new siblings only shows up when both exist.
- A failure of the "a different skill fired" type in a batch is a symptom of the SET, not of
  one skill: fix the pair of descriptions, not just the one that lost the probe.
```

## Anti-patterns

- Letting the probe write: a gate that mutates the delivery it is verifying has destroyed its own evidence.
- Declaring the skill done because the description "reads well" — the description is a routing artifact, and reading well is not evidence that it routes.
- Running the probe in the same session that wrote the skill: the context already contains the skill, so the test measures nothing.
- Naming the skill in the probe ("use the X skill to…") — that tests obedience, not triggering.
- Passing the gate with only the first criterion and calling the second "a body improvement for later".
- Burning a fourth round instead of escalating a scope decision.
