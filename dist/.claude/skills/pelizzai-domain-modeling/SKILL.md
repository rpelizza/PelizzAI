---
name: pelizzai-domain-modeling
description: Overlay that makes the domain model explicit and consistent during design or authorized documentation. Use when the task actually changes terminology, relationships, invariants, bounded contexts, ADRs, or a durable rejection. Merely reading the glossary does not trigger this skill. Respects source mode and never creates consumer documentation by reflex.
---

# PelizzAI Domain Modeling

## Goal

Make code, spec, and product language express the same model, using concrete scenarios
to expose ambiguity — without turning every noun into DDD ceremony.

**Announce when material**, in the conversation's language: that you are using PelizzAI Domain Modeling to resolve the model change.

## Effect and persistence gate

Reading existing terms/ADRs is normal investigation. This skill enters when the model will be **changed**;
the task branch must already exist before documentation is edited.

| Mode | Where to read/write |
| --- | --- |
| Consumer | glossary in `pelizzai/context.md` or `pelizzai/context/`; ADRs in `pelizzai/adr/`; rejections in `pelizzai/out-of-scope/`, created only when needed |
| Source mode | native documentation already adopted by the repo, or the plan/execution record; never create `pelizzai/`. If there is no native path and no file was requested, keep the decision in the native design artifact |

ADR/rejection recording follows the gate, never reflex:

- **Decision already ratified at a design/plan gate**, inside an authorized write flow (task
  branch open): RECORD the ADR automatically when the three criteria of §3 hold, and
  announce it in one line, in the conversation's language: that ADR-000N `<title>` was recorded and
  the user may ask to adjust or remove it (the `ADR-000N` identifier stays verbatim). The harness is
  only recording a decision the user already made; it decides nothing new.
- **Emergent architectural decision** — arising during execution, in a lane without a design gate, or
  in a debugging root cause: do not record it silently. Present it to the user at the
  validation/completion edge (which is already a gate) before writing the ADR.
- Creating the ADR is the **coordinator's** action; a team member only flags the decision in
  the report, without writing.
- **Never** write an ADR after `candidate-head`/`validated-head`: a doc written after the seal
  invalidates the candidate. Pin the write to the cycle of the task where the decision is made
  (pre-seal).
- In read-only analysis, only **propose** the record; the write returns to the first-write gate.

Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP), produce no route analyses and open no gates: apply the
briefing and escalate to the coordinator whatever requires a decision.

## Process

### 1. Locate the real vocabulary

Read the existing glossary/ADRs/specs and look for the terms in code, schemas, APIs, and UI. Separate:

- official name;
- legitimate per-context synonym;
- collision/overload;
- divergence between documentation and behavior.

### 2. Force precision with scenarios

Use a few examples that change the answer:

```text
- identity: can two entities exist separately?
- lifecycle: which transition is valid, forbidden, or reversible?
- ownership: who may create, change, cancel, or observe?
- time: what happens before/after, expires, or is historized?
- boundary: does this term mean the same thing in every context?
```

Ask only when evidence cannot settle a decision that belongs to the user. Do not invent
new terms if the current vocabulary is already precise.

### 3. Update the smallest durable artifact

- Glossary: definition, context, and the necessary distinction; no implementation details.
- ADR: when the decision is hard to reverse, surprising without context, **and** the product of a
  real trade-off (all three together). Use `templates/adr.md` — a numbered file (ADR-000N) with
  context, decision, rejected alternatives, and consequences, no frontmatter. In a consumer, write
  it in `pelizzai/adr/`; in source mode, record it in the execution record/native design artifact
  and **offer** to materialize it as a file at the repo's native ADR path when the user wants
  durability (default: keep it in the record), without creating `pelizzai/`.
- Out-of-scope: durable rejection only; deferral/momentary capacity is not rejection.

One concept updates the existing record; do not create a file per conversation. Something already
implemented does not become out-of-scope. A vocabulary change must propagate to the in-scope
artifacts or leave an explicit migration — do not silently rename half the system.

### 4. Verify

Look for contradictions in the relevant consumers and validate render/lint/links when applicable.
Record in the plan/briefing the terms and invariants the implementation/review must preserve.

## Integration

`pelizzai-idea-generation` uses this overlay only when the model changes; `pelizzai-writing-plans`
propagates the invariants; `pelizzai-codebase-architecture` translates the boundaries into modules; useful
reasoning is Constraint Satisfaction + Assumption Tracking.

ADR recording points (all filtered by the triple criterion, all the coordinator's action):
`pelizzai-idea-generation` when saving the spec of a ratified design (auto + one-line announcement);
`pelizzai-execute` when consolidating a durable architectural decision — already ratified at
the design gate (auto, pre-seal) or emergent (presents it to the user before writing);
`pelizzai-debug` on a durable root cause (emergent → presents); `pelizzai-architecture-refinement`
only **offers**, being read-only.

## Red flags

```text
- Creating `pelizzai/context.md` or an ADR in the source repo.
- An ADR for an easy/reversible decision or one without a trade-off.
- Recording a rejection/ADR during read-only without authorization.
- Using DDD as cosmetic renaming.
- Duplicating the entire spec in the glossary.
- Different terms for the same concept without explicit context.
```

## Definition of Done

```text
[ ] terms and invariants are unambiguous in the affected contexts;
[ ] durable artifacts are minimal and at the mode's correct path;
[ ] the ADR/rejection meets the criterion and belongs to the authorized scope;
[ ] plan/implementation/review received the updated vocabulary.
```
