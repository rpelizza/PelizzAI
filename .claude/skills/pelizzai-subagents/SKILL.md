---
name: pelizzai-subagents
description: Use to delegate a focused, independent task to ONE isolated subagent (or a few independent subagents that only report back) — research, code sweep/mapping, analysis, or a contained implementation. Subagents do not talk to each other; for a TEAM of roles that need to dialogue/coordinate, use `pelizzai-team`. Trigger when the user says "delegate this", "send a subagent", or when execution runs in subagents mode.
---

# PelizzAI Subagents

## Goal

Delegate work to an **isolated subagent**: its own context, without polluting yours, that executes and **reports back**. It is the light path — when you need the **result** of a workstream, not a dialogue between roles.

**Announce at start**, in the conversation's language: that you are using the PelizzAI Subagents skill to delegate to a subagent.

> **Boundary with `pelizzai-team`:** use **subagents** for an independent workstream that only
> reports. Use **team** when multiple roles need to dialogue/coordinate. The task's branch or
> worktree is still a shared working tree — it does not isolate agents from each other.
> Investigation is always parallelizable; writing follows the ratified isolation: on `branch`, the
> coordinator applies serially; on `worktree`, workstreams with **disjoint paths** write in
> parallel inside the task's single worktree.

<TEAM-MEMBER-STOP>
If you are the dispatched subagent, execute only your task: trigger `pelizzai-reasoning`, apply the domain skills pasted into your briefing (they prevail over generic patterns) and the global layer `pelizzai-preferences`, and return the result in the agreed format. Do not delegate sub-subagents or orchestrate the flow. On an implementation task, **do not commit** — consolidation belongs to the coordinator, after review and verification.

Under a closed briefing (TEAM-MEMBER-STOP/SUBAGENT-STOP), do not produce route analyses or open gates: apply the briefing, **flag in your return** (`DONE_WITH_CONCERNS`/`NEEDS_CONTEXT`) if a domain skill covering your task's stack was missing, and escalate to the coordinator whatever requires a decision.

You **do not decide product gaps**. If a requirement, scope, UX, architecture, data, security,
cost, or acceptance criterion is not written in the briefing, the plan, or the spec, **name the
gap** — what is missing, what it changes in the delivery, and 2–3 options you see, with the one
you recommend — and return `NEEDS_CONTEXT`. Do not fill it by convention, default, Context7, or
"reasonable inference", even if the choice seems obvious and reversible; the coordinator is who
takes the gap to the human.
</TEAM-MEMBER-STOP>

---

## Mechanics

```text
- Agent/Task tool: the subagent has its own context window, ONLY returns its final text to the
  coordinator, does NOT talk to other subagents, and TERMINATES on return (no memory between calls).
- agentTypes: Explore (read-only search), Plan (read-only architect), general-purpose, or custom.
  Read-only ones (Explore/Plan) do NOT edit files — writing roles require general-purpose or custom.
- Parallelism: for independent subagents, issue several Agent calls in a single message.
  Parallel reading is safe; writing requires disjoint files and depends on the ratified isolation
  (consumer state or source execution record): on `branch`, one writer at a time and the coordinator
  integrates the writes SERIALLY; on `worktree`, parallel writing is allowed on DISJOINT PATHS
  inside the task's single worktree (never one worktree per agent). The worktree isolates the task
  from the mainline, not the agents from each other — the rule serializes, not Git; review, stage,
  commit, and cursor always belong to the coordinator.
```

## Self-sufficient briefing

The subagent **does not inherit your context** — build the prompt. In plan execution, use
`task-brief.*` only with a compatible persistent Markdown plan; a native plan uses pasted content.
The handoff dir is gitignored in the consumer and temp in source mode (see task-cycle §1):

```text
- Goal: the single, clear expected result.
- Necessary context: paths, contracts, decisions already made, conventions (the subagent has not seen the conversation).
- Relevant local rules/skills: assemble a SPECIALIST — when the subagent embodies an area role
  (e.g., backend-implementer), name it by the area and paste the **COMPLETE** domain-skill package
  for that area (consumer: catalog `pelizzai/domain-skills.md`; source mode: the source repo's
  rules/skills), not just the ones that seem to apply to the specific task. When in doubt whether a
  domain skill from the catalog belongs to the area,
  include it: the cost of including is lower than the cost of ignoring a project rule. Paste the
  operational points — the subagent must apply them instead of generic patterns. If the area has no
  covering skill, say so and ask the subagent to flag the gap in its return.
- Global layer: instruct the subagent to apply `pelizzai-preferences` and to reason via
  `pelizzai-reasoning`; on conflict, the pasted DOMAIN SKILLS and the project rules PREVAIL.
- Reasoning: main suggested technique from `pelizzai-reasoning` per the task. For external library
  APIs, ground in the current official documentation available — not in memory.
- Delivery contract: the EXACT return format (list of findings file:line; diff; X/Y/Z report).
- Safe harbor (in the briefing text): it is always OK to stop and say "this is too hard for me" —
  bad work is worse than no work; the subagent will not be penalized for escalating.
- Material gap (in the briefing text): if a requirement, scope, UX, architecture, data, security,
  or acceptance criterion is not written in the briefing, the plan, or the spec, STOP, NAME the gap
  (what is missing + what it changes + 2–3 options with the recommended one), return
  `NEEDS_CONTEXT`, and also declare it under `Deviations from plan:`. Do not fill it by default or
  by "reasonable inference" — the coordinator is who takes the decision to the human, via
  `pelizzai-interview` (gap mode).
- Constraints: what not to touch; read-only, when applicable.
```

## Verification and integration

A subagent's result is **not** truth until checked. For implementation, run it through the two
`pelizzai-review` lenses under the recorded profile (`split` by default; `combined` only when the
user ratified the downgrade at the setup gate). In `split`, the blindness is asymmetric: the
**blind spec lens** receives only diff + spec/plan + the area's domain skills and does
**NOT receive the report** of the subagent (it judges the code against the contract, without the
narrative); the **quality/evidence lens** receives the report and verifies the claims with fresh
proof. The coordinator (the main session) cross-checks the lenses and is **never** the blind lens.
Then apply `pelizzai-verification-before-completion` before consolidating. For research,
cross-check conflicting findings and distrust an unverified report.

If the subagent flagged a domain-skill gap for the task's stack, the coordinator accumulates
those gaps and consolidates them into a single proposal at closeout (the adoption-driven axis of
`pelizzai-finish`) — never creating a skill mid-task. This path does **not** halt execution.

**A material gap is the other path, and that one halts the workstream.** If the subagent NAMED a
requirement, scope, UX, architecture, data, security, cost, or acceptance decision that was not in
the briefing, the plan, or the spec, it does not get resolved in the next dispatch: the coordinator
does **not decide** for itself or for the subagent. It consolidates the open gaps — grouping and
ordering by dependency, never choosing — and takes them to the human via `pelizzai-interview`
in gap mode (one question at a time, 2–3 options with the recommended one) before re-dispatching.
The ratified decision goes back into the plan and the briefing; only then does the workstream
continue.

---

## Anti-patterns

```text
- Expecting subagents to coordinate on their own (they do not talk to each other) — that is the coordinator's job.
- Sending a writing role to a read-only agentType (Explore/Plan do not edit).
- A vague briefing, or assuming the subagent has the conversation history.
- Treating the subagent's report as truth without checking (git diff / fresh evidence).
- Handing the subagent's report to the blind spec lens, or the coordinator dispatching itself as that lens.
- Assembling the specialist subagent without the complete domain-skill package for its area.
- The subagent filling by default or "reasonable inference" a decision that is not in the briefing/plan/spec, instead of naming the gap and returning NEEDS_CONTEXT.
- The coordinator resolving the material gap alone (or re-dispatching over it) instead of taking it to the human via `pelizzai-interview` — consolidating is not deciding.
- Using subagents for a TEAM of roles that need to dialogue — that is `pelizzai-team`.
```

---

## Integration

**Composes with:**

- `pelizzai-team` — the full team (multiple roles, task list, dialogue); subagents is delegation to ONE agent.
- `pelizzai-reasoning` / `pelizzai-preferences` — reasoning layer and global floor instructed in the briefing (domain skills prevail).
- `pelizzai-execute` — `subagents` mode: one subagent per task, dispatched by the coordinator.
- `pelizzai-interview` — destination of the material gap the subagent names: the coordinator takes it to the human before re-dispatching.
- `pelizzai-review` / `pelizzai-verification-before-completion` — check the result before consolidating.
- `pelizzai-audit` — catalog of domain skills pasted into the briefing.
