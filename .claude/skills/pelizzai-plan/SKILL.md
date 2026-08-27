---
name: pelizzai-plan
description: "Use when a ratified spec, PRD, or design needs an implementation plan. Produces a durable, stress-tested plan executable with zero repo context, approved before any code."
---

# PelizzAI Plan

## Goal

Produce the plan that an executor with **zero context** on this repository executes without asking
a single question: each task's files, the contracts to honor, the proof of the result, and the
exact commands. Assume a good engineer who knows little of this toolset, this domain, and the
house conventions — whatever the plan lacks becomes a material gap that STOPS execution and goes
back to the user via `pelizzai-interview`. Every question execution has to ask is a failure of
the plan, never a license to guess.

Zero context is about **complete context**, not about transcribing the future code: the plan
records ratified decisions, contracts, and criteria (see *Plan depth*), not the whole implementation.

**Announce**, in the conversation's language: that you are using the PelizzAI Plan skill to turn the requirements into an executable plan.

In a consumer, the plan is **always materialized** at `pelizzai/plans/YYYY-MM-DD-<topic>.md`
(unless a different location is explicitly requested); it is the durable artifact execution reads.
In source mode, record the plan in the native execution record in a **discoverable and verifiable**
way (tasks and the requirement→task map stay traceable) and **offer to
materialize** it as a file at the repo's native path when the user wants durability; never create
consumer `pelizzai/` runtime in the source repo. The task/planning branch must already exist;
state is mandatory only in the consumer.

## Preconditions

```text
- Goal and acceptance criteria were made explicit or ratified by the user.
- The branch was opened by pelizzai-isolate before the spec/plan.
- Source mode follows the source repo's rules without `pelizzai/` runtime; a consumer uses catalog/profile.
- Library/API facts that may have changed were verified in Context7 for the observed version;
  current official documentation is the fallback when the tool is unavailable.
- Greenfield has an APPROVED spec — the waiver does not exist there; standard/exploratory has an
  approved spec or the user's explicit waiver on record (spec: explicitly waived <date>).
```

If the technical question still cannot be stated precisely, go back to `pelizzai-discovery`. If the
question is precise but the answer depends on evidence, create a short investigation or prototype
task with an output and a stop criterion.

## Plan depth

Use the lane recorded by the router:

| Lane | Shape of the plan |
| --- | --- |
| `bounded` | 1–a few compact tasks; paths, contract, acceptance, proof, and command. Do not force an interview when the user already specified the change. |
| `standard` | vertical tasks, explicit interfaces and dependencies; detail wherever an executor could choose wrong. |
| `exploratory` | risks, decisions, migration/rollback, and bounded discovery tasks; do not invent certainty or premature implementation. |

Include complete code/config only when it is itself the fragile contract (schema, format,
template, non-obvious call). For ordinary implementation, names, interfaces, invariants, and short
examples are more durable than copying the future code into the plan.

In greenfield, include a usage/development documentation slice (for example a README with setup,
run, tests, and MVP limits) as the standard recommendation. The user may adjust or waive it when
approving the plan; the LLM does not remove documentation to speed up implementation.

## Decompose into vertical slices

Each task delivers an observable end-to-end result. Do not split "all the tests" from "all the
implementation". A task is a unit that can be approved or rejected without forcing the same
decision on its neighbor; a one-task plan is valid.

```text
- Follow the existing structure; do not use the plan to restructure the repo without a requirement.
- Name paths and interfaces that are already known; mark a glob/folder only when discovering the
  right file is an explicit part of the task.
- Declare dependencies between tasks and avoid false parallelism in a shared working tree.
- A durable/asynchronous task favors contract and acceptance; do not freeze a perishable line number.
```

## Technical decisions in this plan

Every plan carries the mandatory section `## Technical decisions in this plan`: the **numbered**
list of the material technical decisions that surface when turning the spec/design into a plan —
chosen library or pattern, data format, interface contract, migration strategy, local architecture
trade-off. Each item states, in one line: **what** was decided, **where it was ratified**, the
**rejected alternative**, and the **why**.

**A material technical decision the harness settled on its own does not enter the list as a fait accompli
— it becomes a question.** While assembling the plan, separate:

- **Already ratified** (fixed in the spec, the design, or a previous interview): record it with its
  origin (`ratified in the spec` / `in the design` / `in the interview of <date>`) — and the origin
  must be locatable in the cited artifact, not a label of convenience. At the gate it is only a
  recap — what the user already decided is not re-asked.
- **Still open** (emerged now, while decomposing): **do not write the choice as decided.** Before
  closing the plan, take it to the user via `pelizzai-interview`, one question at a time, with
  **2–3 real options + the recommended one marked and a one-line why** (the intelligence lies in
  building the good options and grounding them in repo/Context7 evidence; the decision is the
  user's). Only once ratified does it enter the list, with origin `ratified in the plan interview`.

The plan only closes when **every** material decision is ratified — no weighty technical choice
travels hidden in the middle of an N-task plan to be rubber-stamped along with it. **This close is
the single ratification boundary.** The post-plan gate's item 0 is a SAFETY NET against a
ratification that failed to get recorded, never a second boundary: an unratified decision surfacing
there means this close failed its own contract — ratify it right there and amend the plan before
Task 1, so the artifact and the record agree.

**A ratified decision with architectural weight also becomes an ADR** — chosen pattern or library
with a rejected alternative, a boundary/contract that future work must honor, a durable rejection.
Trigger `pelizzai-domain-modeling` (its §recording gate and `templates/adr.md`) right after the
ratification, while the why is fresh; a decision that only lives in a plan file stops being
findable the day the plan is archived.

When the plan is purely mechanical and introduces no material technical decision, write explicitly
`no material technical decision — purely mechanical plan`. Never leave the section empty or omit
it: the absence of decisions is itself a claim to ratify.

This list is what the post-plan setup gate presents — the ratified ones as a recap, and any
decision with no ratification origin as a question with options right there, before the "ok". A
decision that does not fit in one clear line signals a missing human decision (go back to the
design or to `pelizzai-interview`), not that the line should grow.

During execution the **operational deviation test** applies:
if the decision is not written in the plan or the spec, it is not approved — present it before implementing.
An emergent technical decision interrupts the task and returns to the user **as a question with
2–3 options and the recommended one** (with a one-line why); it is never filled in silently or
handed back as an open question without options. Agreeing with the recommendation costs one word.

## Applicable skills

**In a consumer, read the Active rules of `pelizzai/data/learnings.md` BEFORE choosing approaches**
(the short section only; the Incident log is consulted on demand) and, with them,
`pelizzai/data/verification-standard.md` — what *correct* means here grounds each task's
validation strategy (see `pelizzai-evolve`). A rule read after the approach is picked can only be
an audit; read before, it removes an approach from the table. If either file is absent, note it,
propose creating it from the corresponding template, and continue without blocking. Source mode:
use the repo's own rules; never create `pelizzai/` for this.

- In the header: the catalog's domain skills that apply to the whole plan, or `none`.
- In each task: that slice's domain skills and the **Cross-cutting harness skills** it requires,
  or `none`. This per-task block is what reaches the executor in the briefing — the overlay does
  not live only in the header.

Mandatory overlays by surface:

| Surface | Overlay |
| --- | --- |
| page, component, CSS, layout, visual state, UX | `pelizzai-interface` |
| auth, authorization, untrusted input, SQL, upload, secrets, sensitive data | `pelizzai-security` |
| human documentation that is part of the delivery | `pelizzai-docs` |

Do not list a skill for a remote possibility. UI never swaps `pelizzai-interface` for Playwright,
browser, or screenshots; those are just tools of the overlay.

## Strategy per task

Fill in **Implementation and validation strategy**:

| Effect | Primary strategy | Evidence |
| --- | --- | --- |
| automatable behavior/regression | TDD red→green on the public contract | RED observed, GREEN, focal test |
| preserving/legacy refactor | characterization | same green proof before/after |
| config, IaC, schema, migration, script | validate | parser, fixture, plan/dry-run, and applicable rollback |
| visual/interaction UI | visual + functional | app running, states/viewports, accessibility |
| docs, prompt, policy, static artifact | static/scenario | lint, render, link/schema/grep, or real consumption |

Mixed tasks combine strategies. Do not fabricate RED for CSS, Markdown, or configuration just to
make the plan uniform.

The review shape is fixed, not planned: per task, ONE independent dispatch with both verdicts
(spec, then quality/evidence); the truly blind spec lens runs on the final range. What the plan
records per task is the review DEPTH the risk demands — which checks the reviewer should actually
run — never a profile choice.

## Document

Use [templates/plan.md](templates/plan.md) and keep only the applicable fields. The header carries
the **Approvals** block — discovery, spec, domain skills, and the plan itself, one line each with
the ratification date: it is the historical record of the human decision, and `state.md` keeps
only the task cursor. No marker is filled by inference. Each task contains:

```text
result + out of scope
files/interfaces
domain skills + overlays
dependencies/constraints
implementation and validation strategy
review profile
sufficient steps and commands
observable completion criterion and rollback when applicable
```

Defects: `TBD`, "handle edge cases" without naming them, nonexistent commands, an API recalled
without a current source, placeholders, a horizontal task, proof that does not observe the effect,
or a requirement created by the LLM without ratification.

## Verify the plan

Before the handoff:

1. Map every requirement to a task and every task to a requirement.
2. Confirm interfaces/naming between tasks and dependencies.
3. Confirm overlays and the proof strategy per artifact.
4. Hunt for placeholders and guessed commands.
5. Re-read the plan as someone who has never seen this repository: is there any question left the
   artifact does not answer?
6. Confirm the lane did not receive more ceremony than its risk.
7. **Stress-test and expose the material gaps** of the plan: actively hunt for unhandled cases,
   missing validation, undefined state/error, missing authorization, and spec↔plan↔task
   contradictions.

List residual assumptions **new to the plan**, without re-litigating the approved design. Every
material gap leaves the edge resolved, accepted by the user, or converted into an investigation.
When it requires a human decision, use `pelizzai-interview` and ask one question at a time,
with a recommendation. `bounded` uses a compact stress pass; `standard` uses a focal stress pass;
`exploratory`/greenfield requires a full stress pass. Context7 can confirm API and version, but
cannot close a requirement, UX, business rule, or acceptance. Do not reopen an approved design
without new evidence.

Present the plan and the stress result at the edge — `bounded`: a summary of the tasks;
`standard`/`exploratory`: the requirement→task map. Ask **one approval question about the plan's
content** and wait. Only then move on to setup; approval of the WHAT and decisions about the HOW
are not compressed into a single answer.

Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP), do not produce route analyses or open gates: apply the
briefing and escalate to the coordinator whatever requires a decision.

## Handoff

**Domain skill coverage check (safety net).** Before forwarding to the setup gate, verify: does
the plan's stack have coverage in the `pelizzai/domain-skills.md` catalog? If not — or if the
catalog is absent — invoke the **proactive domain skills gate** of `pelizzai-onboard` to propose
the set for the decided stack (grounded in Context7); the decision is the user's and happens
**BEFORE Task 1**. This catches flows that reached the plan without passing through
`pelizzai-discovery`. In source mode there is no consumer catalog: the check falls to the
source repo's domain skills and never creates `pelizzai/` runtime. Under a closed briefing
(SUBAGENT-STOP / TEAM-MEMBER-STOP), do not open this gate: flag the coverage gap to the coordinator.

In the consumer, update the `plan:` field in state and confirm the materialized path
(`pelizzai/plans/YYYY-MM-DD-<topic>.md`); content approval is recorded in the header of the plan
itself (`Plan: approved on YYYY-MM-DD`), not in state. In source mode, hand the native
plan/execution record to `pelizzai-execute` in a discoverable way. Branch/base are already
set; **forward to the post-plan setup gate** of `pelizzai-execute` only after content
approval. The gate ratifies the **how** in sequential decisions — isolation (keep the branch or
convert to worktree), mode (the three options always visible), commits, and the executor tier;
branch base and name were already ratified by `pelizzai-isolate` BEFORE the spec/plan, and the
task review is never a question. `pelizzai-plan` carries recommendations, not decisions:

```text
isolation: branch recommended; worktree only if requested/justified — taken to the gate
execution-mode: inline recommended; subagents/team for real independence or coordination — taken to the gate
commit-strategy: granular recommended; squash-final only with a trade-off/request — taken to the gate
```

Do not apply isolation, mode, or commits as a decision without the user's ratification at the
sequential gate; the plan informs and the gate ratifies before Task 1. If the user asked for **the
plan only**, do not execute code: validate the artifact, consolidate/seal the planning delivery,
and keep it local unless an external destination is requested.

**Session boundary.** The approved plan is a phase boundary — it runs on zero repo context, so
execution rarely needs this session's reasoning. At the closing
gate, alongside the setup recommendations, offer the choice: **continue executing here, or start a
fresh session (or handoff) seeded with the plan's path** — recommend the fresh session when the
planning conversation is long, and continuing when the remaining room clearly fits the execution.
The decision tree is `pelizzai-continuity` → `references/phase-boundaries.md`.

## Red flags

```text
- Writing the plan before the task branch.
- Forcing discovery/interview on a clear bounded lane.
- Planning greenfield without an approved spec or an explicit waiver.
- Skipping stress and plan approval to start implementing.
- Duplicating in the plan all the code execution should write.
- Omitting a detectable frontend/security overlay.
- Universal TDD — or planning a review "profile": the per-task review shape is fixed (one dispatch, both verdicts).
- Team/worktree out of harness preference, without concrete gain.
- Using Context7 to decide requirements or acceptance criteria.
- A giant plan covering subsystems that should be separate tasks/projects.
- Omitting the `## Technical decisions in this plan` section or leaving it empty instead of
  declaring `no material technical decision — purely mechanical plan`.
- Forwarding to the setup gate with a stack uncovered by the catalog, without invoking the
  proactive domain skills gate of `pelizzai-onboard`.
```

## Integration

Combines with `pelizzai-discovery` when there was design, `pelizzai-interview` for focal stress of a material residual assumption,
`pelizzai-interface`/`pelizzai-security` as overlays, and `pelizzai-execute` for execution.

## Final instruction

Plan the contract, the proof, and the boundaries at the lane's depth. Leave the implementation to
execution and do not turn clarity into ceremony.
