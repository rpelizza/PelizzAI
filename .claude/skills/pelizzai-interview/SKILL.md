---
name: pelizzai-interview
description: "Canonical gap-closing mechanism. Use whenever a product, scope, UX, architecture, data, or acceptance decision is not covered by spec or plan. One question at a time, with a recommendation."
---

# PelizzAI Interview

## Goal

Obtain from the human the decisions that evidence cannot provide. This skill is the **canonical
gap-closing mechanism** of the harness: every decision not covered by spec, plan, or prior
ratification passes through here, in any phase — discovery, design, plan, or execution. Filling a
gap by default, convention, Context7, or "reasonable inference" is a violation, even when the
choice looks obvious and reversible.

Efficiency here means well-ordered questions, not batched decisions or presumed answers.
The interview does not replace reading the project, nor does it exist to fabricate gaps.

**Announce**, in the conversation's language: that you are using the PelizzAI Interview skill to resolve the material decisions still open. Everything this flow says to the user — questions, proposals, evidence, verdicts, confirmations, closeouts — follows the conversation's language, even when this skill is read in isolation.

## Modes

| Mode | Trigger | Output |
| --- | --- | --- |
| discovery | the goal/acceptance has materially different interpretations | goal, scope, constraints, and decision |
| focused stress | an idea/design/plan already exists, but there is a concrete premise or risk | decision, risk accepted/mitigated, and required change |
| gap | execution hit a decision the spec and plan do not cover | decision ratified, recorded in the plan, execution resumed |
| explicit interview | the user asked for questions/an interview | the depth requested, without stretching past usefulness |

`pelizzai-discovery` creates the design. This skill resolves pending human decisions; if there
is no design or concrete options yet, hand back to `pelizzai-discovery`.

## Where it is mandatory

At these points the interview is **not an offer**: run it to the end and list the gaps before
handing control back.

1. **Before design** — the request admits two or more materially different readings: interview
   to fix goal, scope, constraints, and acceptance before `pelizzai-discovery` designs
   anything.
2. **After design, before the spec closes** — stress-test the design and **expose the gaps**
   (unhandled cases, missing validation, authorization/security failures, undefined states,
   contradictions). Return control to `pelizzai-discovery` so it can conclude spec and approval.
3. **After the plan, before execution** — stress-test the `pelizzai-plan` plan: every
   material technical decision without a ratification origin becomes a question here, never a fait
   accompli.
4. **During execution, at every gap** — protocol in the "Gap mode" section.

The greenfield cycle (discovery → spec → stress → approval → plan → stress → approval) always runs
through 1–3, even with the stack already defined. A `bounded` lane the user has specified himself
(goal, acceptance, and approach given) waives 1–3, but **never waives item 4**: the trigger is the
gap, not the lane.

Closing early is allowed only after the gaps have been **actually identified and
resolved** — or explicitly accepted by the user. Never skip the step "to save time": the cost of
discovering the gap after implementation is always higher.

## What is a gap — and what is not

A gap is a decision whose answer changes **product/UX, scope, architecture, data, security, cost,
or acceptance**. If none of those change, it is not a gap, it does not become a question, and the
interview does not become ceremony.

```text
NOT a gap — resolve it yourself:
- a fact verifiable in the repository (code, tests, manifest, lockfile, spec, plan, state);
- an external fact verifiable for the version in use via Context7 or official documentation;
- a mechanical step inside a boundary already ratified in a spec, plan, or prior decision;
- an implementation detail with no observable effect (internal name, helper order, formatting,
  a local refactor that preserves the contract).

A gap — STOP and ask:
- a requirement, acceptance criterion, or priority that admits two materially different readings;
- an undefined interface contract (signature, payload, error, empty state, authorization);
- a scope, UX, architecture, or data-model choice the spec and plan did not write down;
- a cost, performance, or risk trade-off nobody explicitly accepted;
- a contradiction between spec, plan, and code.
```

A product decision does not stop being a gap because a common, safe, or reversible default exists
— the default becomes the question's **recommendation**, not its answer. Context7 and official
documentation ground options; they never ratify a decision that belongs to the user.

## Before asking

1. Read the request, the spec/plan, the task record (consumer state or native execution record), and only the relevant code/documentation.
2. Separate observed facts, inferences, and decisions that belong to the user.
3. Remove factual questions whose answer is already in the project. Do not remove a product
   decision because a common, safe, or reversible default exists; turn it into the question's
   recommendation.
4. Order the rest by dependency and impact.

Do not state effort as fact without measuring. When two interpretations materially change scope or
cost, show the available evidence and the consequence of each.

**Finding facts is the harness's job, never the user's.** When a pending question needs a fact from
the environment (filesystem, repo, docs), look it up — or dispatch a subagent for it — instead of
asking; and do not block on it: only the questions downstream of that fact wait, the current
question proceeds. Asking the user something the repo can answer wastes their turn and erodes the
interview's authority.

**Record each answer where it lives, immediately — once writing is authorized.** A ratified answer
is written into the spec/plan section it affects (or the plan's `## Technical decisions`) right
after the turn — replacing the ambiguous statement it invalidates, never accumulating beside it —
so an interrupted interview loses nothing and the artifact never carries two contradictory
sentences. The first-write gate still rules: with isolation and the task/planning branch not yet
confirmed (an explicit interview, a read-only entry), the ratified answers ride the handoff and
land in the artifact at the first AUTHORIZED write, never on the current branch by convenience.

## How to ask

- Ask **exactly one question per turn**. Order it by the highest-impact decision that conditions
  the following ones; after the answer, recompute the interview script.
- **When the platform offers a native option-selection tool, use it** — never deliver a closed
  question as prose the user has to answer by typing when they could select. The contract holds
  inside the tool: one question per turn, 2–3 real options, explicit recommendation.
- The recommendation goes **where the user reads the choice**. In a native format with a short
  label and a longer description per option, the recommended option comes **first** and carries
  the mark **in its label** (e.g. `<option> (Recommended)`); the reason goes in the description.
  A recommendation buried in a description the user does not read is a recommendation not made.
  In prose — no native tool, or an open question — highlight
  `Recommended: <option> — <reason>` before the question.
- Use 2–3 options only when they are real and sufficiently complete.
- Use an open question for discovery, product language, or when listing options would bias the
  answer.
- Do not invent options to fill a format — no facade "Other", no fourth option for symmetry, no
  closed question where the decision is genuinely open. This bullet forbids fabricating choices;
  it never forbids using the platform's selector for real ones.
- Explain why the answer changes the delivery. Cut cosmetic questions that do not alter the result;
  reversible product choices still belong to the user, but he can explicitly delegate
  them.

If the platform's tool imposes a specific question format, follow it without changing this
contract's semantics; where no native tool exists, the prose format is the fallback, not a
preference. Both delivery forms — labels, descriptions, and prose — speak the conversation's
language.

## Gap mode: closing the hole mid-execution

Trigger: implementing a task — inline, as a subagent, or as a team member — you hit a decision the
spec and plan do not cover. The operational deviation test applies: **if the decision is not
written in the spec, the plan, or the task record (consumer state or native execution record),
it is not approved — present it before implementing.**

1. **STOP the task.** Do not implement "the most likely reading" to show later, do not leave a
   TODO, flag, or configurable parameter to postpone the decision, and do not continue in another
   file while holding the doubt. Code written over a self-filled gap is rework, not progress.
2. **Name the gap in one sentence**: what is undefined and which of the material effects it changes
   (product/UX, scope, architecture, data, security, cost, or acceptance).
3. **Bring 2–3 real options** when they are complete and do not bias the answer — each with its
   consequence in one line, the recommended one marked as `## How to ask` prescribes: native
   selector when the platform has one, mark in the option's label; in prose,
   `Recommended: <option> — <reason>`. When real options would be fabricated or would bias the
   answer, ask an open question instead.
   Facade options (one good and two absurd) are not options;
   the intelligence lies in building good alternatives and grounding them in repo/Context7 evidence.
4. **One question at a time**, starting with the decision that conditions the rest; recompute the
   following options after each answer. Never dump the whole block of gaps as a questionnaire.
5. **Record the answer in the plan**, under `## Technical decisions in this plan`, in the canonical
   line (`decision — ratified: execution interview — rejected: <alternative> — why: <reason>`); if
   residual risk remains, add it to `## Exposed material gaps`. Source mode or a task without a
   plan file: record it in the native execution record, verifiably, without creating
   `pelizzai/`.
6. **Resume the task** exactly where it stopped, now inside a ratified boundary.

**Under a closed briefing** (`SUBAGENT-STOP` / `TEAM-MEMBER-STOP`) the executor opens no gate and
does not interview the user: stop at step 1, build steps 2 and 3, and return `NEEDS_CONTEXT` with
the named gap, the options, and the recommended one, also declaring it under
`Deviations from plan:`.
The coordinator conducts the interview; he re-dispatches the task after ratification.

If the gap is large enough to undo the plan, do not close it with a spot question: hand back to
`pelizzai-plan` (replan) or `pelizzai-discovery` (redesign).

## Proportional stress

Hunt only failures plausible for the real surface:

```text
missing contract or acceptance
relevant error or empty state
authorization/security/data
compatibility/migration/rollback
unconfirmed scale or integration premise
contradiction between spec, plan, and code
```

Do not invent a list of risks to prove depth. The `bounded` lane usually waives the design and
plan stress, but `bounded` with a material gap still calls this skill — the trigger is the gap,
not the lane. Standard uses focused stress; exploratory/greenfield walks the decisions
sequentially and stops when spec/plan can be approved without the LLM inventing requirements.

When the gap arrives flagged by the **Proposal analysis** — output of the **Proposal Stress
(Assumption Tracking applied)** routine of `pelizzai-router`
([proposal-stress.md](../pelizzai-router/references/proposal-stress.md)) — go straight into
focused stress on the material premises it pointed out: that analysis is the inventory; this
interview is the resolution.

## Stop criterion

Stop when:

- no open human decision changes requirement, scope, UX, architecture, data, security, risk,
  authority, acceptance, or solution;
- critical premises have proof, an owner, or explicit acceptance;
- the next step and its success criterion are clear.

Do not chase "complete understanding" of the whole system. If an answer creates a new dependent
decision, continue; if it creates investigable technical work, return it to the flow as a task,
not as a question.

## Output and handback

The interview **ends with the numbered list of gaps and how each one changes the solution** — active
hunting, not prose: point out every material gap even if the user did not mention it, and say how
it was resolved, explicitly accepted, or converted into an investigation task.
A summary without the gaps section is incomplete.

Return compactly:

```text
Decisions:
- choice — reason/evidence

Gaps (numbered — each with what it changes in the solution):
1. gap — changes scope/UX/architecture/security/data — resolved, accepted, or becomes a task
2. ...

Open premises:
- only those still constraining execution

Next step:
- the skill/artifact that takes back control
```

If no new risk was found, say so; do not fabricate one, nor declare that every project has a
gap. Return to the caller (`pelizzai-discovery`, `pelizzai-plan`,
`pelizzai-execute`, or the router). In gap mode, the handback is the interrupted task:
resume it with the decision already written in the plan. This skill does not choose team,
subagents, branch, or commit strategy.

## Red flags

```text
- Filling the gap yourself by default, convention, Context7, or "reasonable inference".
- Implementing the most likely reading and presenting the decision as a fait accompli.
- Hoarding the gaps to ask in a batch at the end of the task.
- Asking what the code/spec already answers, or fabricating a gap where there is no material effect.
- More than one question per turn.
- A batch of questions that prevents recomputing options after each answer.
- Four artificial options and a recommendation without evidence.
- Skipping the mandatory design or plan stress "to save time".
- Skipping the interview in a greenfield product/project because the stack is defined.
- Handing control back without having explicitly exposed the gaps — revealing them is the goal.
- Treating external documentation as the answer to a user decision.
- Continuing after the next step no longer depends on the user.
- Declaring that every project necessarily has a gap.
```

## Integration

- `pelizzai-discovery` — interview before the design and mandatory stress after it.
- `pelizzai-plan` — mandatory stress of the plan; an emergent decision becomes a question here.
- `pelizzai-execute` / `pelizzai-loop` — destination of the stop for material doubt
  mid-execution (gap mode); `pelizzai-subagents` and `pelizzai-team` escalate to the coordinator.
- `pelizzai-router` — the Proposal analysis
  ([proposal-stress.md](../pelizzai-router/references/proposal-stress.md)) inventories the
  material premises this interview resolves.
