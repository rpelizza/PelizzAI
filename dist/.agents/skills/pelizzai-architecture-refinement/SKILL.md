---
name: pelizzai-architecture-refinement
description: Read-only head skill for PROACTIVE codebase-wide review of architecture, technical debt, and missing seams. Use periodically (every few days of intense work on the project), when the user asks for a broad architectural analysis or what is worth refactoring, and when debugging records a structural gap. Delivers candidates prioritized by evidence; does not edit code, report, ADR, or out-of-scope. Diff/branch/PR review uses pelizzai-review.
---

# PelizzAI Architecture Refinement

## Goal

Find where the architecture is charging an **observable** cost and return a few actionable
opportunities, without turning aesthetic preference into a refactor or a read-only analysis into
writes.

**Announce**, in the conversation's language: that you are using the PelizzAI Architecture Refinement skill to review the architecture by evidence.

## Effect contract

The default mode is `read-only`:

```text
- does not create branch, state, HTML, ADR, spec, out-of-scope, or any file whatsoever;
- delivers the report in chat/the platform's native resource;
- does not fix the candidates it finds;
- runs focused checks only when they discriminate an architectural hypothesis.
```

If the user asks for a persistent artifact or chooses to implement a candidate, return to the router,
reclassify to `write-local`, and go through `pelizzai-starting-branch` **before** the first write.
A consumer uses the harness paths; source mode uses the repo's native paths and never creates `pelizzai/`.

## Scope

Architecture degrades silently: each task looks at its own diff and nobody looks at the whole. That
is why the trigger is not just the user's request — it is also **cadence**: every few days of
intense work on the project, the harness offers this review. Offering is proactive; running and implementing
remain the user's choice.

Use for:

- broad periodic review of architecture/debt/seams;
- recurring friction backed by real bugs, changes, or navigation;
- a missing seam that blocked a useful regression test.

Do not use for:

- an active bug (`pelizzai-debug`);
- review of a diff, working tree, branch, or PR (`pelizzai-review`);
- implementing an already-decided refactor (router lane/plan);
- interrupting a task in progress: the periodic offer waits for the task to close.

## Adaptive process

### 1. Pin the question

Derive the scope from the request and the existing evidence. Ask only when two plausible
boundaries would materially change the result. Do not turn "the whole repo" into a questionnaire.

### 2. Collect friction, not checklist smells

Inspect the minimum able to test real signals:

```text
- similar changes scattered across many places;
- recurring bugs/fixes at the same boundary;
- a missing seam, or a test that must know too much implementation;
- a pass-through module whose cost reappears in the callers;
- a wide contract for narrow use;
- a concept that demands excessive jumps between modules;
- a dependency/cycle that grows the blast radius.
```

Use history, tests, imports/callers, and ADRs when they help. Read-only subagents only when there
are independent fronts. The absence of a perfect metric does not authorize inventing frequency or
impact.

### 3. Test each hypothesis

For each material candidate:

1. describe the observed friction;
2. apply the deletion test: without this layer, does the complexity disappear or merely migrate?;
3. find a counterexample/prior art that could refute the hypothesis;
4. check for an ADR/constraint that explains the current design;
5. estimate reach, reversibility, and migration risk.

Use `pelizzai-codebase-architecture` as vocabulary/lens, not as a second head skill. Useful reasoning:
Evidence Synthesis for scattered signals, Assumption Tracking for gaps, and Decision Making for
prioritization. Do not force OODA without real rounds, nor TDD onto an analysis.

### 4. Prioritize honestly

Classify each candidate:

| Class | Evidence |
| --- | --- |
| Strong | recurring friction + causal mechanism + plausible direction |
| Worth exploring | real signal, but the benefit or design still needs discovery |
| Speculative | useful hypothesis without sufficient evidence; do not recommend implementation |

Prefer 1–5 candidates. If nothing justifies change, say so; "no refactoring recommended"
is a valid conclusion.

### 5. Deliver the report

For each candidate, state:

```text
evidence: files/lines, history, or the relevant test
friction: concrete cost today
mechanism: why the structure produces that cost
direction: boundary change, without inventing the final interface
expected gain and trade-offs
confidence: Strong | Worth exploring | Speculative
next cheapest proof
```

Also include "keep as is" when it is a rational alternative. Visualize only when relations between
modules become materially clearer; use inline/native resources in read-only mode.

## After the choice

At the end of the analysis, without leaving read-only mode, offer to record what is durable —
propose-and-confirm, never writing by reflex:

- Chosen candidate: the router decides `bounded | standard | exploratory`; open architecture
  usually goes through brainstorming, but a clear refactor can go straight to the plan.
- A durable architectural decision worth remembering (adopting a new boundary, or keeping the
  current one for a real trade-off): **offer** to record an ADR via `pelizzai-domain-modeling`. The
  write only happens after reclassifying to `write-local` and passing the first-write gate; the
  report itself does not write.
- A rejection with a durable reason: **offer** to record it in an ADR/out-of-scope; do not write it
  automatically.
- A missing seam: hand the evidence to the design flow, without fabricating a tautological test.

## Red flags

```text
- Creating a report/ADR/out-of-scope during read-only analysis.
- Confusing a broad architectural review with code review of a diff.
- Recommending a refactor for size, style, or "clean code" alone.
- Inventing the definitive interface before design.
- Ignoring an ADR/constraint that explains the current trade-off.
- Rewriting the world instead of prioritizing a few candidates.
- Forcing subagents, visuals, or checks with no signal gain.
```

## Definition of Done

```text
[ ] every recommendation points to verifiable evidence;
[ ] hypothesis, fact, and inference are kept separate;
[ ] trade-offs and the do-nothing alternative were considered;
[ ] no state was changed in read-only mode;
[ ] the next route is clear without implicitly starting implementation.
```
