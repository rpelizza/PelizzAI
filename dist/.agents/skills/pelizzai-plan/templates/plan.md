# Implementation plan template — PelizzAI

Copy to `pelizzai/plans/YYYY-MM-DD-<topic>.md` and replace every bracketed text with real content. Each task is a verifiable vertical slice; the strategy varies with the effect. Write for someone who opens the plan with zero context on the repository: complete context yes, transcription of the future code no.

---

## Mandatory header

```markdown
# [Name] — Implementation plan

> **For the executor:** MANDATORY SUB-SKILL — use `pelizzai-execute`.

**Goal:** [one-sentence result]

**Architecture:** [approach and boundaries in 2–3 sentences]

**Tech stack:** [technologies/libraries]

**Applicable domain skills:** [names from `pelizzai/domain-skills.md` or `none`]

**Global Constraints (copied VERBATIM from the spec):**

- [project-wide constraint; if there is none, write `none`]

**Approvals** (one line each; a marker without an explicit user answer stays `pending`):

- Discovery: [ratified on YYYY-MM-DD | waived on YYYY-MM-DD | not applicable]
- Spec: [`path` approved on YYYY-MM-DD | explicit waiver on YYYY-MM-DD | not applicable]
- Domain skills: [chosen set, or `none` — ratified on YYYY-MM-DD]
- Plan: [draft | approved on YYYY-MM-DD]

---
```

The approvals are the **historical record of the human decision** and live only here — `state.md` keeps the task cursor (`lane`, `phase`, `spec:`, `plan:`), not the stamps. `Plan: draft` until the user's explicit answer at the content-approval edge; silence does not become a date.

The coordinator includes the Global Constraints and the cross-cutting skills recorded on the task in each executor's briefing. Do not list an overlay for a remote possibility: UI requires `pelizzai-interface`; a sensitive surface requires `pelizzai-security`.

## Exposed material gaps

List the residual assumptions and material gaps **new to the plan** (unhandled cases, missing validation, undefined state/error, missing authorization, spec↔plan contradictions). Each one leaves the edge resolved, explicitly accepted by the user, or converted into an investigation task — never in silence. If there are none, write `none`.

```text
- [gap → resolution | accepted by the user | Investigation task N]
```

## Technical decisions in this plan

**Numbered** list of this plan's material technical decisions — each on one line: **what** was decided, **where it was ratified**, the **rejected alternative**, and the **why**. Every material decision must be ratified before the plan closes: one that emerged while assembling the plan goes to the user as a question with 2–3 options and a recommendation (via `pelizzai-interview`), not as a fait accompli. If the plan is purely mechanical and makes no material technical decision, write exactly `no material technical decision — purely mechanical plan`. Never leave the section empty or omit it.

```text
1. [decision] — ratified: [spec | design | plan interview | execution interview] — rejected: [alternative] — why: [one-line reason]
2. [decision] — ratified: [spec | design | plan interview | execution interview] — rejected: [alternative] — why: [one-line reason]
```

The post-plan setup gate presents this list: the already-ratified ones (spec/design/interview) as a one-line recap, and any decision with no ratification origin becomes a question with 2–3 options and a recommendation right there — never a block rubber-stamp. During execution the operational deviation test applies — if the decision is not written in the plan or the spec, it is not approved — present it before implementing. A material gap that surfaces later, mid-execution, is plugged by `pelizzai-interview` and comes back here as a new line with origin `execution interview` — the list stays alive during execution; it does not freeze at the gate.

## Structure of each task

````markdown
### Task N: [vertical outcome]

**Out of scope:** [files, behaviors, or decisions this task must NOT change; `none` only when the task truly has no boundary to state]

**Files:**

- Create: `exact/path.ext`
- Modify: `exact/path.ext:123`
- Validate: `exact/path/to/test-or-artifact.ext`

**Domain skills to apply:** [names or `none`]

**Cross-cutting harness skills to apply:** [names or `none`]

**Interfaces:**

- Consumes: `exactName(arg: Type): Return` — origin
- Produces: `otherName(arg: Type): Return` — consumer

_If self-contained, write `none`._

**Implementation and validation strategy:**

- Predominant effect: [behavior | refactoring | config/IaC/migration | visual UI | documentation]
- Implementation: [TDD red→green | characterization on green | validate/plan/dry-run | pelizzai-interface + visual QA | static check]
- Oracle: [what proves the result]
- Command(s): `[complete canonical commands]`
- Expected evidence: [exit code, delta, visual state, or exact output]
- Rollback: [when applicable; otherwise, `not applicable`]
- Review depth: [which checks the task reviewer should actually run] — [justification by risk/surface]

- [ ] **Step 1: Establish the baseline/oracle** → verify: [exact result]

[concrete command, test, or inspection]

- [ ] **Step 2: Apply the slice's smallest change** → verify: [local criterion]

```language
[complete content only when it is itself the fragile contract — schema, format, template,
non-obvious call; otherwise, name the interface, the invariant, and one short example]
```

- [ ] **Step 3: Run the strategy's proof** → verify: [exact output]

Run: `[exact command]`
Expected: `[observable result]`
Discriminating proof (TDD/regression only): `[preserved RED | controlled mutation the test
kills | reversion in the editor — how the test is shown to detect the defect, not just pass;
whichever means, name what it kills: kills: <wrong implementation rejected>]`

- [ ] **Step 4: Ready for review → consolidate** — do not commit mid-task; the commit is the coordinator's gate after the spec ✅ + quality ✅ lenses at the recorded review depth. → verify: `git status` contains only this task's scope
````

Adapt the order without losing the proof:

```text
- Behavior/regression: RED observed → minimal implementation → GREEN → refactor on green.
- Preserving refactor: green characterization → small step → same green characterization.
- Config/IaC/migration: baseline → change → validate/plan/dry-run → inspect delta and rollback.
- UI: behavior when present + implement states → pelizzai-interface on desktop/mobile → screenshot/browser.
- Docs/copy: edit → lint/links/examples/build-render → inspect the result.
```

## Plan quality gates

```text
- An executor with zero context on the repository completes each task without asking a single question.
- Paths, interfaces, content, commands, and outputs are concrete.
- Every step has `→ verify:`.
- Each task records cross-cutting skills, implementation/validation strategy, and review depth.
- UI never omits `pelizzai-interface`; Playwright/browser is a tool, not an overlay.
- No artificial RED for refactoring, CSS, docs, config, IaC, or migration.
- No TBD/TODO, "handle edge cases", "same as Task N", or undefined references.
- External APIs are anchored in current documentation, not memory.
```

## Forwarding to execution

Plan materialized, stress-tested, and approved → **forward to the sequential post-plan setup gate**
of `pelizzai-execute`. The plan carries recommendations; the user decides isolation (keep the
branch or convert to worktree), mode, commits, and the executor tier one question at a time before
Task 1 — branch base and name were already ratified by `pelizzai-isolate` before the spec/plan.
