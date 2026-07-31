---
name: pelizzai-prototype
description: Overlay for building a throwaway experiment that answers a design question more cheaply than implementing or debating. Use for concrete uncertainty about state, integration, feasibility, or UI. Do not use as a mandatory step, a polished demo, or a shortcut to production; requires a branch before writing and removal/absorption before the seal.
---

# PelizzAI Prototype

## Goal

A prototype is **throwaway code that answers a question** — and the question decides the format.
Buy information with the smallest possible experiment: **one** question per prototype; when the
answer appears, it ends.

**Announce**, in the conversation's language: that you are using PelizzAI Prototype to answer `<question>` with a throwaway experiment.

## Gate

Use only when:

```text
[ ] there is a material, falsifiable uncertainty;
[ ] analysis, prior art, or a smaller test cannot answer at lower cost;
[ ] the answer can change the design;
[ ] there is a stop criterion and a destination for the code.
```

The items above are the suitability test (deciding that a spike is the right move remains your
job); on their own they do **not** authorize writing the experiment. A throwaway prototype is a
structural decision and requires the **user's explicit approval**, ratified at the right gate — not
at the skill's internal gate:

- with discovery/plan → propose the spike at the discovery gate (`pelizzai-brainstorming`) or at the post-plan setup gate;
- writing track without a plan → include the spike in the head skill's kickoff confirm.

Recommend and wait: "may I spend `<timebox>` on a throwaway spike to answer `<question>`?
destination: `<delete|absorb|turn into a task>`". Without a "yes", do not write the experiment.

Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP), do not produce route analyses or open gates: apply the briefing and escalate to the coordinator whatever requires a decision.

A prototype writes: go through `pelizzai-starting-branch` first. Use an ignored temporary path or a
prototype path the project has already adopted. Source mode never creates `pelizzai/` runtime;
prefer system temp or native structure. Do not include unnecessary secrets/real data.

## Choose the form by the question

| Question | Likely experiment |
| --- | --- |
| State/rule/algorithm | minimal script/CLI with cases that discriminate between the models |
| Integration/feasibility | thin spike at the real boundary, sandbox/fixture, and an explicit timeout |
| UI/flow | one or more variants only when there are real alternatives; `pelizzai-frontend` overlay and plausible content |

Do not force several “radically different” variants when one hypothesis is enough. Do not use UI to
answer a domain question, or a mock to remove precisely the boundary being tested.

## Experiment contract

Before coding, record in the plan/execution record:

```text
question
hypothesis/material alternatives
observation that confirms or refutes
timebox/maximum cost
what will deliberately lack production quality
destination: delete | absorb | turn into a task
```

Implement the minimum that runs. “Throwaway” cuts polish and abstraction; it does not remove basic
security or the proof that answers the question. Run the scenario, preserve output/limitations, and
stop at the criterion.

## Close out

1. Summarize evidence, answer, and confidence; inconclusive is a valid result.
2. Update the native design/plan with the decision. An ADR only if authorized, with the correct
   path, and passing the `pelizzai-domain-modeling` criterion; never record automatically in `pelizzai/`.
3. Delete the throwaway code, or absorb only the parts that go through the normal
   implementation/test/review cycle.
4. Confirm that no prototype, sensitive fixture, dependency, or temporary flag remains before the
   final review/seal.

## Red flags

```text
- A prototype without a falsifiable question.
- Becoming a mini-product with polish, abstractions, and scope creep.
- Keeping experimental code without an explicit decision.
- Declaring feasibility using a mock that removes the real risk.
- An automatic ADR, or consumer runtime in source mode.
- Skipping frontend on a visual prototype, or treating it as final production QA.
```
