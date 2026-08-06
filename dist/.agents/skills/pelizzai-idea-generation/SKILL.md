---
name: pelizzai-idea-generation
description: Explores and ratifies design before implementing a greenfield product/project, or a feature, refactor, or structural change with trade-offs, requirements, architecture, UX, data, or risk still open. Greenfield uses full mode even with a defined stack; a change to an existing system may use compact mode. Do not use for already-approved design, a trivial tweak, or a bug under investigation.
---

# PelizzAI Idea Generation

## Goal

Turn intent into a design decided by the user before implementation. The skill investigates,
surfaces alternatives, and recommends; it never fills in a product decision to gain speed.

**Announce**, in the conversation's language: that you are using the PelizzAI Idea Generation skill in `<compact|full>` mode to resolve the design decisions before implementing.

<HARD-GATE>
Do NOT invoke an implementation skill, write code, create scaffolding, or take any implementation
action until the design has been presented and the user has approved it. **This applies to ALL
projects, regardless of apparent simplicity** — the design can be short (a few sentences for a
truly simple scope), but it must be presented and approved.

The only exit lies before this skill: a pinpoint fix and a `bounded` lane already specified by the user
are resolved by `pelizzai-router` BEFORE brainstorming (see Preconditions). Once inside
this phase, the rule holds in full — "too simple to need design" is not a
justification; it is the anti-pattern the rule exists to block.
</HARD-GATE>

## Preconditions

- The router has already classified effect, risk, uncertainty, and overlays.
- For any spec/ADR/prototype write, the task/planning branch already exists.
- In the `bounded` lane of an existing product, with goal, acceptance, and approach already supplied
  by the user, return to the router and proceed without brainstorming. Greenfield never uses this exception.
- In the `standard`/`exploratory` lanes, no implementation starts before the design spec exists and has been presented at the design edge — barring an explicit waiver from the user. Depth scales with the lane (lean for a `standard` with clear acceptance, full for `exploratory`); the classifier never concludes on its own "no trade-off here, I'll skip the spec".

## Choosing depth

| Mode | When | Output |
| --- | --- | --- |
| `compact` | medium uncertainty, few decisions, cohesive scope | focused context → short design → one approval → lean spec. |
| `full` | high uncertainty, open architecture, or coupled sensitive decisions | exploration, real alternatives, proportional stress, detailed spec. |

A greenfield product/project always starts in `full`. Naming any combination of language,
framework, runtime, database, service, or platform reduces technical uncertainty, but does not
settle actors, journeys, states, rules, exceptions, or acceptance.

Visual complexity or file count is not enough to pick a mode; use the cost of a wrong decision and real uncertainty. In `standard`/`exploratory` the spec is the default artifact: the mode picks the spec's depth (lean vs full), not whether it exists.

## Common flow

### 1. Explore focused context

Read only what you need to answer:

```text
- Where does the change fit?
- Which existing contracts/patterns must it preserve?
- Is there testing and implementation prior art?
- Which decisions are already recorded in ADR/out-of-scope?
- Which domain skills and overlays apply?
```

Use a read-only subagent only when the search has independent fronts. Do not run a full repo scan by reflex.

When external technology affects feasibility or options, identify the version in manifests/lockfiles
and consult Context7 before formulating the corresponding question. In greenfield with no
dependencies installed, consult the current documentation of the stated stack or of the candidates
you intend to recommend. Use that evidence to discard incompatible options and explain trade-offs;
the choice stays at the user's gate.

### 2. Fix goal and boundaries

Define:

- outcome and user/consumer;
- observable acceptance criteria;
- out of scope;
- constraints and compatibility;
- reversible vs hard-to-reverse decisions.

Consult evidence before asking so you never request facts already observable. For user decisions,
ask **one question at a time**, even when they seem independent: the answer can change the priority,
vocabulary, and options of the next ones. Each discovery turn contains:

```text
Decision: <why this changes the solution>
Real options: <2–3 when they help>
Recommendation: <best option> — <one-line reason>
Question: <a single question>
```

An open question is valid when options would bias the answer. Never hide a decision inside a
"safe assumption".

### 3. Run discovery when there is a material gap

When context and goal reveal gaps in scope, UX, architecture, security, or data, do not resolve
them by assumption. Order the gaps internally by dependency and impact, but present only the next
decision. Example:

```text
I found product decisions still open. The first conditions the others:

Decision: <gap> — changes <scope|UX|architecture|security|data>.
Options: A) <...> · B) <...> · C) <...>.
Recommendation: <B> — <reason>.
Question: which option do you choose?
```

The turn stops after the question. Silence, a recommendation, and Context7 do not count as an
answer. After the choice, record the decision, recompute the gaps, and ask only the next question.
Skipping the entire discovery requires an explicit request; in that case, do not invent answers:
record the untaken decisions as limitations and confirm an implementable spec still exists.

Do not reopen what the router's kickoff gate has already ratified: group only the material gaps still open. In `bounded` with no material gap, the gate does not appear.

Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP), do not produce route analyses or open gates: apply the briefing and escalate to the coordinator whatever requires a decision.

### 4. Explore alternatives when they exist

Present 2–3 approaches only if they are genuinely valid and materially different. Compare by what
matters and recommend one. Ask for the user's choice before folding it into the design.

If a single approach is compatible with the contracts, explain it directly; do not invent alternatives to satisfy ritual.

### 5. Design the solution

Cover proportionally:

```text
responsibilities and boundaries
interfaces/contracts and data flow
states and error handling
compatibility/migration/rollback when applicable
validation strategy and real seams
observability/security when risk demands it
```

For UI, apply the `pelizzai-frontend` overlay at design time: real flow, states, content, existing system, accessibility, and visual direction. This does not authorize implementing before approval.

For modules, use `pelizzai-codebase-architecture` only when boundaries/seams are still a decision. For the domain, use `pelizzai-domain-modeling` when the vocabulary/ADR actually changes — not merely to read the glossary.

### 6. Proportional stress

When stress-testing the design, hunt gaps ACTIVELY and present them as a numbered list — do not let one slip by just because the user did not mention it. Look only for the failures plausible for the real surface:

```text
unhandled cases and undefined states
missing validation
authorization/security failure or data exposure
compatibility/migration/rollback
unconfirmed scale or integration assumption
contradiction between spec, plan, and code
```

Full mode/greenfield: the stress with `pelizzai-interview` is **MANDATORY**, not an offer.
Announce it in the conversation's language — that you are going to interview the user to
stress-test this design and expose the weak points before moving on — and run the interview. Every new decision that belongs to
the user comes back one question at a time, with a recommendation. Each gap is resolved, explicitly
accepted, or converted into an investigation task before leaving the design edge.

Compact mode: do a short counterexample pass. Escalate to an interview only if you find material ambiguity.

Do not require stress twice on the same decisions. Writing Plans tests the plan's executability
without reopening the approved design absent new evidence.

### 7. Approve at the right edge

Present the whole design at proportional size and ask **one approval question** at the edge.
In greenfield/`standard`/`exploratory`, the spec is the artifact presented before any plan or
implementation. The user approves, requests an adjustment, or explicitly waives; the waiver is recorded.

The user does not need to approve every paragraph, every seam, and then the same content again in the spec.

### 8. Persist the spec

The spec is the default artifact of `standard`/`exploratory`; produce it by default and use `templates/spec.md` at the lane's scale (lean for `standard`, full for `exploratory`). Skipping the spec is the user's decision, recorded in the state/execution record — never the classifier's. After approval:

- consumer: save to `pelizzai/specs/YYYY-MM-DD-<topic>-design.md` on the task branch;
- source mode: record the design in the native plan/execution record, without creating `pelizzai/`, verifiably in the record; offer to materialize it as a file at the repo's native path when the user wants durability;
- a versioned file in the source repo only when it is an explicitly requested artifact, at the
  project's native path, and after the first-write gate.

Include only durable content (see `templates/spec.md`):

```text
Goal and acceptance criteria
Relevant context/constraints
Design and contracts
Applicable states/failures/security
Testing & Validation Decisions
Out of scope
Hard-to-reverse decisions
```

Record an ADR only for an approved decision that is hard to reverse, surprising without context, and carries a real trade-off. The spec may point to the ADR; do not duplicate the whole explanation.

Self-review inline: placeholders, contradictions, ambiguity, scope creep, and unverifiable requirements. Fix the document; do not create a separate ritual.

### 9. Transition

- Normal flow: hand the approved spec to `pelizzai-writing-plans`.
- New project — design-edge closeout checklist, each step mandatory before leaving design:
  1. Design approved → invoke `pelizzai-audit` (proactive domain skills gate): propose the set for the decided stack, with context7; the decision is the user's.
  2. Create only the ratified ones and record them in the catalog/ledger.
  3. Proceed to `pelizzai-writing-plans` when the original request includes building the product; stop after design/bootstrap only when that was the requested scope.

## Prototypes

Use `pelizzai-prototype` only when a state/logic/visual-form question cannot be answered economically by analysis. The prototype:

- is born on the task branch or in an ignored ephemeral directory;
- answers one explicit question;
- gets no production polish/abstraction;
- is absorbed or removed before final validation.

## Visual Companion

Offer it only when the user will understand better by seeing than by reading. Examples: wireframes, layouts, diagrams, or visual comparisons. Do not use it for textual choices or requirements.

Short offer:

> "This decision is clearer visually. Want me to open a companion with the options?"

If accepted, read [visual-companion.md](visual-companion.md), use only documented/tested flags, and stop the session when the phase closes.

## Anti-patterns

```text
- Full brainstorming for a bounded feature.
- Treating a greenfield project as bounded because the stack was stated.
- Full repo scan without a concrete question.
- A question whose answer is already in the code/spec.
- Always inventing three alternatives.
- Asking several discovery questions in the same turn.
- Offering a recommendation and treating it as the user's choice.
- Mandatory interview on a low-uncertainty design.
- Treating the stress with `pelizzai-interview` as an optional offer in greenfield/full mode.
- Implementing, scaffolding, or "just getting a head start" on code before design approval, claiming simplicity.
- Writing a spec/prototype before the task branch.
- Using frontend only as late QA instead of as a design overlay.
- Reopening an approved decision without new evidence.
- Silently assuming a scope/UX/architecture decision with a material gap instead of proposing discovery.
- Using Context7 to invent a requirement, persona, business rule, or acceptance criterion.
- Suppressing the spec of a standard/exploratory lane without the user's explicit waiver.
- Closing the design edge on a new project without presenting the domain skills proposal.
```

## Definition of Done

```text
[ ] material gaps were exposed and each is resolved or explicitly accepted;
[ ] full mode/greenfield: the stress with `pelizzai-interview` happened and the design was
    approved by the user before any implementation action;
[ ] acceptance criteria and out of scope are verifiable;
[ ] overlays and validation strategy are identified;
[ ] standard/exploratory: the proportional spec was produced by default and presented at the edge,
    or the user explicitly waived it (waiver recorded); the consumer saves it on the task branch,
    source mode records it in the native execution record without consumer runtime;
[ ] new project: the stack's domain skills proposal was presented at the edge (the proactive gate
    of `pelizzai-audit`) before proceeding to the plan, and the user's decision is recorded;
[ ] the next skill receives enough context without repeating the interview.
```
