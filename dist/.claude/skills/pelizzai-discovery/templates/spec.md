# Design spec template

Two scales in the same file. Choose by the ratified lane:

- **Lean spec** — `bounded` (when accepted) and `standard` with clear acceptance.
- **Full spec** — greenfield, `exploratory`, and coupled sensitive decisions.

Fill in only the sections that add value; do not force empty fields. The spec points to the ADR
when one exists (via `pelizzai-domain-modeling`) and does not duplicate the decision's whole
explanation. Consumer: save to `pelizzai/specs/YYYY-MM-DD-<topic>-design.md`. Source mode: record
the content in the native execution record, without creating `pelizzai/`; materialize it as a file
only when the user asks for durability.

Every spec is born with `Status: draft`. Switch to `approved on YYYY-MM-DD` only after the user's
explicit answer at the design edge.

---

## Lean spec

```markdown
# <Title> — design

**Status:** <draft | approved on YYYY-MM-DD>

## Goal
- Outcome and user/consumer.

## Acceptance criteria
- Observable and verifiable.

## Short design
- How the change fits; contracts/patterns it preserves.

## Out of scope
- What this change does not do.

## Decisions
- Choice — reason — reversible or hard to reverse (point to the ADR if any).
```

---

## Full spec

```markdown
# <Title> — design

**Status:** <draft | approved on YYYY-MM-DD>

## Goal
- Outcome and user/consumer.

## Acceptance criteria
- Observable and verifiable.

## Context and constraints
- Relevant prior art, constraints, compatibility, and recorded rejections (`out-of-scope`).

## Design and contracts
- Responsibilities and boundaries; interfaces/contracts and data flow; real test seams.

## States, failures, and security
- States and error handling; authorization/security/data when risk demands it.

## Compatibility, migration, and rollback
- Strategy when applicable.

## Testing & Validation Decisions
- Chosen seams and why; how the codebase already tests similar things; proof by effect.

## Out of scope
- What this change does not do.

## Hard-to-reverse decisions
- Every decision that passes the triple criterion (hard to reverse + surprising without context +
  real trade-off) points to its ADR.

## Ratified decisions and limitations
- Decisions chosen by the user, explicit waivers, and gaps converted into investigation.
```
