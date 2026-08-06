---
name: pelizzai-documentation
description: Overlay for HUMAN documentation of a feature's stable contract, such as routes, commands, APIs, and screens. Use when docs are part of the scope, the diff creates a stable surface that needs explaining, or the user asks for usage documentation. Runs before the final review and validated-head; pelizzai-finish does not execute it (it only flags the gap as a safety net), and it does not apply to the harness's specs/plans/ADRs.
---

# PelizzAI Documentation

## Goal

Explain to humans the delivery's observable, durable contract, without narrating internal details
that go stale in the next refactor.

**Announce**, in the conversation's language: that you are using the PelizzAI Documentation skill to document the feature's contract.

## Where

Follow the existing docs structure, its index, and its generator. Absent a convention, use
`docs/<area>/<feature>.md`. Human docs do not live in `pelizzai/`; specs, plans, and ADRs are
process artifacts.

## Proportional content

Include only what applies:

```markdown
# <Feature>

## Purpose
Problem and audience.

## Usage
Routes, commands, APIs, or screen flow with a real example.

## Contract
Inputs, outputs, states, permissions, and compatibility.

## Limits and diagnostics
Preconditions, relevant errors, and how to observe/fix.
```

- Document public behavior, not internal functions/files.
- Use real names, examples, and outputs; do not invent placeholders/product data.
- Update the index/README only when the convention requires it.
- Do not create a separate document if a comment, schema, or existing page is the canonical home.

## Validation and lifecycle

Validate applicable links, examples, snippets, and build/render. The doc is delivery content:
consolidate it via the head skill's commit-strategy **before** the final review and
`validated-head`. Any fix reopens the affected proofs.

The doc goes in **its own commit** — `docs(<feature>): <description>` —, never mixed into the code
commit: separating doc from code is history hygiene, not preference. In `commit-strategy:
granular` it is the definitive commit of the doc; in `squash-final` it is the WIP `docs(...)` the
head skill consolidates with the others **before** the final review. The protected-branch gate of
`pelizzai-starting-branch` applies: never commit to `main`/`master`/`develop`/`dev` or to the
actual discovered default.

`pelizzai-finish` never generates or fixes documentation: after the seal it is too late to write there.
What it does is the safety-net check — if a documentable surface got through without this skill, it
offers **once** to return the delivery to the cycle (the seal falls and the doc becomes validated
content again, with the final review redone). Informed refusal ships without docs; the net does not
block, and it does not replace the normal path either, which is running here before the final review.

## Red flags

```text
- Documenting volatile implementation instead of the contract.
- Creating human docs inside pelizzai/.
- An example that was not validated.
- Duplicating already-existing canonical documentation.
- Leaving the doc without its own commit: dangling in the working tree, or diluted into the code commit.
- Creating it after the seal.
```

## Integration

Router/plan register this overlay; pelizzai-execute runs it before the final review. Combine with
domain skills and `pelizzai-writing-clearly` when that changes the wording.
