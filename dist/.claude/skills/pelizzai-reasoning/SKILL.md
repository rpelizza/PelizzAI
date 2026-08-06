---
name: pelizzai-reasoning
description: Selects reasoning techniques when there is material uncertainty, an investigation, a decision between alternatives, evidence synthesis, non-trivial planning, or high-impact validation. Use it inside the head skill to attack the dominant question; it is not mandatory for direct mechanical action whose contract and proof are already clear.
---

# PelizzAI Reasoning

## Purpose

Use this skill to select, combine, and apply reasoning techniques in proportion to the task: when to investigate, when to act directly, when to plan, when to gather evidence, when to compare alternatives, when to ask for clarification, when to validate, when to conclude, and when to block or escalate a decision.

This skill does not replace domain skills, project rules, technical documentation, tools, or explicit user instructions. It orchestrates the reasoning; the catalog and the matrix below define each decision operationally.

---

## Core principle

> Use the least structured reasoning needed to diagnose, recommend, and verify. Reasoning chooses
> **how to think**; it grants no authority to choose **the product**.

Do not load every technique by default. Do not turn simple tasks into long processes. Do not use a technique just because it exists.

---

## Priorities

Follow this order of priority:

1. Explicit user instructions.
2. Mandatory system and environment rules.
3. Rules specific to the project, workspace, or repository.
4. Security, privacy, permission, and compatibility requirements.
5. This skill and its techniques.
6. Technical, aesthetic, or implementation preferences.

---

## Activation

Use this skill when the task involves at least one of these conditions:

- multiple steps;
- code, tools, or integrations with uncertainty, dependencies, or material risk;
- verifiable or potentially current facts;
- material uncertainty;
- a decision between alternatives;
- requirements, constraints, or prohibitions;
- risk of regression, data loss, cost, or external impact;
- a bug, incident, diagnosis, or unexpected behavior;
- a relevant technical recommendation;
- the need to validate an answer before concluding.

Do not apply the full flow to simple, creative, direct, or purely editorial tasks.

Examples that normally require no extra techniques:

```text
- Translate a sentence.
- Rewrite a paragraph.
- Fix a typo.
- Explain a stable, basic concept.
- Rename a local variable.
```

---

## Initial triage

Before choosing a technique, determine:

```text
Goal:
- What does the user want to receive or achieve?

Scope:
- What is included and excluded?

Risk:
- What happens if the answer or action is wrong?

Uncertainty:
- What is not yet confirmed?

Dependencies:
- Are files, code, tools, APIs, sources, or permissions required?

Impact:
- Does the task change data, code, configuration, cost, security, or users?

Completion criterion:
- How will you know the task was completed correctly?
```

Do not ask factual questions by reflex. First use context, files, documentation, code, and tools.
When a decision of requirement, scope, UX, architecture, data, security, cost, accepted risk, or
acceptance remains, ask the user one decision at a time and recommend the best option.

For a new feature/refactor request with mutating effect and material uncertainty, produce the **Proposal Analysis** with [Proposal Stress (Assumption Tracking applied)](techniques/proposal-stress.md) before routing — assumptions, material gaps, risks, and alternatives — as a result presented by `pelizzai-router`, not as a question. Read-only work and trivial tweaks do not trigger it; high risk alone raises proof and gates, not uncertainty.

Use `pelizzai-interview` in every greenfield and whenever there is a material human decision.
Evidence resolves facts; it does not resolve the user's preference, policy, or intent.

---

## Operational selector: method and proof by effect

Classify separately **the task's effect**, **the uncertainty**, and **the environment's dynamism**. The head skill defines the lifecycle; this skill picks the heuristics. No head skill may impose OODA, RCA, or TDD without the corresponding trigger.

| Predominant effect | Implementation and validation strategy |
| --- | --- |
| New or changed behavior | `pelizzai-tdd`: red→green behavioral test against the public contract |
| Behavioral bug | Red→green regression when there is an automatable seam; another reproducible oracle when there is not |
| Refactoring with no behavior change | Green characterization suite/coverage before; refactor in small steps; same suite green after |
| Configuration, IaC, or migration | `validate`/`plan`/`dry-run`, compatibility, and rollback strategy; unit tests only for separable logic |
| UI/UX/visual | Mandatory overlay `pelizzai-frontend`, behavioral tests where applicable, and real visual verification |
| Documentation/copy | Proportional static checks: lint, links, examples, build/render, or diff inspection |

A task can combine strategies: a new form uses TDD for behavior **and** `pelizzai-frontend` for states, accessibility, responsiveness, and visual QA. Record the combination in the plan; do not force an artificial red test to prove CSS, Markdown, or a `terraform plan`.

---

## Progressive technique loading

1. Choose the technique that answers the phase's **dominant question**.
2. Read only that technique's file plus the auxiliaries that close a distinct gap.
3. Add or swap techniques when new evidence changes the question; do not keep a pipeline out of inertia.
4. Consider the context cost: every technique must justify a decision or an observable proof.

There is no fixed quota. Usually one main technique is enough; high impact may require several
lenses, while a direct task may require none. A pipeline (see **Recommended compositions**) chains
phases over time — it does not load the whole catalog at once.

---

## Technique catalog

Read the corresponding technique before applying it.

| Technique                | When to use                                                                      | File                                                                  |
| ------------------------ | -------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| ReAct                    | Execute actions, use tools, observe results, and adjust the next step            | [react.md](techniques/react.md)                                       |
| OODA                     | Macro loop Observe→Orient→Decide→Act: dynamic situations, long executions, re-observing reality on every iteration | [ooda.md](techniques/ooda.md)                                         |
| Plan and Execute         | Multi-step tasks, dependencies, checkpoints, and replanning                      | [plan-and-execute.md](techniques/plan-and-execute.md)                 |
| Structured Decomposition | Split a complex problem into parts, responsibilities, contracts, and dependencies | [structured-decomposition.md](techniques/structured-decomposition.md) |
| Constraint Satisfaction  | Guarantee requirements, prohibitions, compatibility, and limits                  | [constraint-satisfaction.md](techniques/constraint-satisfaction.md)   |
| Assumption Tracking      | Track assumptions, hypotheses, and conditions not yet confirmed                  | [assumption-tracking.md](techniques/assumption-tracking.md)           |
| Evidence Synthesis       | Compare documents, sources, logs, tests, data, and conflicting evidence          | [evidence-synthesis.md](techniques/evidence-synthesis.md)             |
| Verification             | Confirm code, facts, calculations, contracts, results, and limitations; includes cross-check via independent runs (multi-agent) | [verification.md](techniques/verification.md)                         |
| Decision Making          | Choose between valid alternatives, with trade-offs and reversibility; includes search with pruning/backtracking for interdependent paths | [decision-making.md](techniques/decision-making.md)                   |
| Root Cause Analysis      | Investigate uncertain causes, recurrence, flakiness, incidents, and cross-system failures | [root-cause-analysis.md](techniques/root-cause-analysis.md)        |
| Critique and Refine      | Improve an artifact after feedback, a failure, an inconsistency, or an unmet requirement | [critique-and-refine.md](techniques/critique-and-refine.md)           |

> The `pelizzai-interview` skill is a **sister skill**, not one of the catalog's techniques: invoke it to resolve material ambiguity by interview, per the Initial triage and the matrix.

> **Proposal Stress** is the [Assumption Tracking](techniques/assumption-tracking.md) routine applied to a new request, documented in [proposal-stress.md](techniques/proposal-stress.md): it produces the **Proposal Analysis** that `pelizzai-router` presents before routing. It is not an extra catalog technique — it is the same assumption machine with a scope-premortem lens.

---

## Selection matrix

| Situation                                                    | Main technique           | Possible auxiliary techniques                                 |
| ------------------------------------------------------------ | ------------------------ | ------------------------------------------------------------- |
| Simple task with a clear action                              | None, or light ReAct     | Verification                                                  |
| Long/dynamic looped execution until delivery (plan, changing environment) | OODA        | Plan and Execute, Verification                                |
| Feature with multiple parts                                  | Plan and Execute         | Structured Decomposition, Verification                        |
| Existing code with unknown parts/contracts                   | Structured Decomposition | Plan and Execute, Verification                                |
| Refactoring while preserving behavior                        | Structured Decomposition | Regression Verification, Constraint Satisfaction              |
| Explicit error with a direct cause                           | ReAct                    | Verification                                                  |
| Deterministic bug with an uncertain cause                    | Light Root Cause Analysis | ReAct, Verification                                          |
| Flaky, recurring, or distributed bug                         | Root Cause Analysis      | Evidence Synthesis, Assumption Tracking, Verification         |
| Incident with active damage                                  | Constraint Satisfaction  | Decision Making, ReAct, Verification; RCA after containment   |
| Choosing between libraries or architectures                  | Decision Making          | Constraint Satisfaction, Evidence Synthesis                   |
| Research across several sources                              | Evidence Synthesis       | Verification, Assumption Tracking                             |
| New feature/refactor request with material uncertainty, before routing | Assumption Tracking + Proposal Stress | Constraint Satisfaction, pelizzai-interview |
| Ambiguous or incomplete requirements                         | Assumption Tracking      | Constraint Satisfaction, pelizzai-interview                |
| Plan depending on an unconfirmed assumption                  | Assumption Tracking      | Plan and Execute, Verification                                |
| Multiple interdependent alternatives with material impact    | Decision Making (search with pruning/backtracking) | Constraint Satisfaction, Evidence Synthesis    |
| Critical calculation, diagnosis, or extraction               | Verification             | Evidence Synthesis; multi-agent cross-check when there are independent reviewers |
| Result failed a test, review, or checklist                   | Critique and Refine      | Verification, ReAct                                           |
| High-impact change                                           | Constraint Satisfaction  | Assumption Tracking, Decision Making, Verification            |

---

## Boundaries between neighboring techniques

Use these distinctions when two techniques look like candidates for the main one:

- **OODA vs ReAct:** [ReAct](techniques/react.md) is the **micro-cycle** of a single action (think → act with a tool → observe the immediate result). [OODA](techniques/ooda.md) is the **macro loop** of an entire execution: re-**Observe** external reality (git, tests, reviews, what changed in the world), re-**Orient** against the goal/plan/DoD, **Decide** the next iteration, and **Act** — repeating until the Definition of Done. One OODA loop contains many ReAct cycles inside the Act phase.
- **RCA vs direct cause:** use [Root Cause Analysis](techniques/root-cause-analysis.md) when a material causal question still remains. An explicit error whose contract, stack trace, or compiler already identifies the cause uses ReAct + Verification; do not invent competing hypotheses. In an incident with active damage, reversible containment and minimal evidence preservation precede the RCA.
- **Linear comparison vs interdependent paths:** [Decision Making](techniques/decision-making.md) is the technique for choosing between alternatives. The standard case compares closed options by trade-offs in a single pass; when the paths are **interdependent** and the viable one only emerges by building a partial solution, evaluating, pruning, and backtracking, use Decision Making's own **search mode with pruning and backtracking** — and reserve it for external, auditable backtracking (partial architectures in files/prototypes), since native thinking already branches internally.
- **Structured Decomposition vs Plan and Execute:** decompose with [Structured Decomposition](techniques/structured-decomposition.md) when **parts, responsibilities, or contracts are still unknown**; move to [Plan and Execute](techniques/plan-and-execute.md) when the parts are already known and what remains is ordering and executing them.
- **Multi-agent cross-check belongs to Verification:** crossing independent runs to measure convergence is expensive and redundant in a single agent (native thinking already does internal consistency). Reserve it for multiple agents/lenses (`pelizzai-team`, independent reviewers, blind lenses) and treat it as the **cross-check via independent runs** mode of [Verification](techniques/verification.md); convergence never replaces the calculation, the source, or the real test.
- **Verification + Critique and Refine:** combine [Verification](techniques/verification.md) with [Critique and Refine](techniques/critique-and-refine.md) only when the **cause of the failure is not yet confirmed**. A failure with a direct cause uses Critique and Refine with inline verification, without ritual double reading.

---

## Recommended compositions

Each arrow is a **phase transition**: the next technique takes over when the previous one has done its job. Load one phase at a time — a technique enters when its question dominates and leaves when it answers it. There is no numeric cap; there is the requirement that every technique justify a decision or an observable proof.

### Feature implementation

```text
Assumption Tracking + Constraint Satisfaction during discovery
→ Decision Making to recommend alternatives to the user
→ Structured Decomposition after ratified decisions
→ Plan and Execute
→ ReAct during execution
→ [OODA only when there is a macro loop with re-observed reality]
→ Verification
```

Use Constraint Satisfaction when there are hard requirements, compatibility, security, or
prohibitions. OODA only governs `pelizzai-loop`/`pelizzai-execute` when there are multiple
iterations and reality (git, tests, review, environment) can change the next decision. A linear
task or a single-slice plan does not earn OODA just for using tools.

### Research or technical recommendation

```text
Constraint Satisfaction
→ Evidence Synthesis
→ Decision Making
→ Verification
```

Use Assumption Tracking when the recommendation depends on information not yet confirmed.

### Debugging or incident

```text
Direct cause: ReAct → Verification
Uncertain deterministic cause: light RCA → ReAct → Verification
Flaky/recurring/distributed: RCA + Evidence Synthesis → [OODA only if there are rounds] → Verification
Active damage: Constraint Satisfaction + Decision Making → reversible containment → RCA after stabilizing → Verification
```

The number of hypotheses tracks the uncertainty: one direct, falsifiable hypothesis may be enough; keep several only when materially plausible causes compete. Do not treat the first symptom as the root cause, and do not turn an explicit error into a ceremonial investigation.

### Architectural decision

```text
Constraint Satisfaction
→ Decision Making
→ Verification
```

When the alternatives are interdependent and require pruning and backtracking, use Decision Making's own search mode; otherwise, compare the closed options directly.

### High-impact change

```text
Constraint Satisfaction
→ Assumption Tracking
→ Decision Making
→ Plan and Execute
→ Verification
```

Applies to the actions listed in the **High-impact actions** section.

---

## Effort budget

Investigation depth must be proportional to risk.

| Level    | Characteristic                                                                          | Conduct                                                             |
| -------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| Low      | Local, reversible change with no external effect                                        | Execute and validate simply                                         |
| Medium   | Functional code, limited integration, or a relevant decision                            | Plan briefly, validate the main flow and relevant errors            |
| High     | Data, security, production, contracts, or multiple systems                              | Use evidence, checkpoints, tests, and contingency                   |
| Critical | Irreversible, financial, legal, medical, sensitive-security, or critical-production action | Do not proceed without strong validation, authorization, and a recovery plan |

Do not investigate indefinitely.

Stop when:

```text
- the goal has been met;
- the completion criteria have been validated;
- no material uncertainty remains;
- the next action neither reduces risk nor produces useful information;
- an indispensable authorization, tool, or piece of context is missing;
- the cost of continuing exceeds the benefit.
```

---

## Tool use

Before using a tool, define:

```text
- What question should this tool answer?
- What result would be sufficient?
- Is the tool the most reliable source?
- Does the action have side effects?
- Is there a less invasive alternative?
```

After using a tool:

```text
- Interpret the actual result.
- Update facts, hypotheses, and assumptions.
- Do not invent a tool result.
- Do not claim something was tested without a real test.
- Do not continue with an outdated plan after contrary evidence.
```

Use sources and tools according to the nature of the question:

```text
Code and behavior:
- Source code, tests, logs, contracts, and controlled execution.

Technology:
- Official documentation via the `context7` MCP when available (`resolve-library-id` → `query-docs`);
  without it, changelog, official repository, and the web. Proof of concept when the docs are not enough.
  First derive technology and version from manifests, lockfiles, config, and code. In greenfield with
  no installed version, look up the current version of the stated stack or of each real candidate.
  Use Context7 from the initial reconnaissance on, and again whenever design, planning, implementation,
  debugging, upgrades, or skill maintenance raises a new technical question.
  Never answer from memory about an external lib's API/version when Context7 can confirm it.
  Context7 can confirm technical capability and constraints; it never chooses a requirement, persona, flow,
  policy, preferred architecture, or acceptance criterion on the user's behalf.

Current facts:
- Current primary or official source.

Data:
- Original source, reproducible calculation, and consistency checks.

Uploaded files:
- Direct reading, relevant excerpts, and validation against the content.
```

---

## Clarifying questions

Ask when the answer materially changes a requirement, plan, UX, architecture, data, security, cost,
accepted risk, or outcome. In greenfield, assume these decisions still need to be obtained until
the spec shows otherwise.

Before asking, check:

```text
- Does the context already answer it?
- Does the code or a file answer it?
- Does the documentation answer it?
- Has the user already explicitly delegated this category of decision?
```

Ask when:

```text
- requirements conflict;
- authorization for a relevant action is missing;
- the choice changes scope or cost;
- a critical assumption cannot be verified;
- the decision belongs to the user or an external owner;
- no valid solution exists under the current constraints.
```

Ask one question at a time. When there are real options, show 2–3, highlight the recommended one,
and explain why in one line. Do not batch decisions to save turns; use the answer to recompute the
next question.

---

## High-impact actions

Before executing an action with a relevant external effect:

```text
[ ] The user's goal is clear.
[ ] The target has been confirmed.
[ ] Constraints and prohibitions have been identified.
[ ] Impacts have been assessed.
[ ] Rollback, backup, or contingency exists where applicable.
[ ] Permissions have been verified.
[ ] The action is necessary and proportional.
[ ] There is validation after execution.
```

High-impact actions include, among others:

```text
- Changing a database.
- Changing a public contract.
- Publishing to production.
- Changing permissions.
- Sending messages or e-mails.
- Deleting data.
- Creating recurring cost.
- Processing sensitive data.
```

Do not execute a destructive, irreversible, financial, or production action, or one that exposes sensitive data, without proper confirmation.

---

## Communication rules

In the answer to the user:

- deliver the result, not a detailed chain of thought;
- distinguish confirmed facts, inferences, and hypotheses;
- report the validations actually executed;
- state limitations and open assumptions when they are material;
- explain trade-offs only when they are relevant;
- do not claim more certainty than the evidence allows;
- be proportional to the request and to the user's technical level.

Recommended format for relevant tasks:

```text
Result:
- [main deliverable]

Validation:
- [tests, sources, build, logs, or checks performed]

Decisions and trade-offs:
- [only when relevant]

Limitations:
- [what was not confirmed or depends on external context]
```

---

## Routing anti-patterns

Do not do this:

```text
- Use the search mode with pruning/backtracking (Decision Making) for a linear choice between closed options.
- Cross independent runs (Verification's cross-check) in a single agent, for a simple answer.
- Create an extensive plan for a local tweak.
- Run Root Cause Analysis on an obvious syntax error.
- Impose OODA on a short sequence with no useful macro re-observation.
- Impose TDD on refactoring, CSS, documentation, configuration, IaC, or migrations with no automatable behavior.
- Research multiple sources when there is a direct contract.
- Use Critique and Refine without feedback or a concrete problem.
- Use Verification as a merely decorative checklist.
- Ask before consulting available evidence.
- Ask several discovery questions in the same turn.
- Use a technique, Context7, or a "safe default" to ratify a decision that belongs to the user.
- Keep investigating after the completion criteria are met.
- Load every technique without need.
```

---

## Evaluation (Evals)

The eval suites measure whether this skill **decides, protects, and is proportional and reliable** — not eloquence. Run them when creating, reviewing, or changing `SKILL.md` or any technique.

| Suite                                                     | What it validates                                                       |
| --------------------------------------------------------- | ----------------------------------------------------------------------- |
| [README](evals/README.md)                                 | Index, execution order, global critical failures, and quality targets   |
| [routing](evals/routing.md)                               | Selecting the right technique and the absence of redundant techniques   |
| [planning-and-execution](evals/planning-and-execution.md) | Planning, decomposition, dependencies, checkpoints, and replanning      |
| [debugging](evals/debugging.md)                           | Bug investigation, incidents, root cause, and containment               |
| [research](evals/research.md)                             | Current research, primary sources, conflicts, versions, and limitations |
| [high-impact-actions](evals/high-impact-actions.md)       | Destructive, financial, production, security, and privacy actions       |
| [regression](evals/regression.md)                         | Compact suite with critical scenarios from every area                   |

After changing a technique, run the matching specialized suite plus `regression` before approving the change.

---

## Condensed operational flow

```text
1. Understand goal, scope, risk, and completion criterion.
2. Check context, project rules, and available evidence.
3. Classify the effect and choose the matching implementation/validation strategy.
4. Choose the dominant technique and only auxiliaries with a distinct function.
5. Read the corresponding Markdown files.
6. Execute with ReAct when there are tools, observation, or uncertainty.
7. Validate in proportion to risk and effect.
8. Replan only if new evidence invalidates the current path.
9. Conclude when the completion criteria are met.
```

---

## Final instruction to the agent

```text
Use PelizzAI Reasoning to orchestrate reasoning techniques, not to make every task complex.

Choose the smallest combination of techniques that reduces uncertainty, respects constraints, produces sufficient evidence, and allows a safe conclusion.

Prefer:
- evidence over assumption;
- a reversible recommendation over premature commitment, without deciding for the user;
- real validation over subjective confidence;
- specific techniques over generic reasoning;
- proportional conclusion over infinite investigation.

Do not expose a detailed chain of thought.
Do not invent observations, tests, sources, changes, or results.
Do not use a technique without a real trigger.
```
