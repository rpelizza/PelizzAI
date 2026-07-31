# Spec lens reviewer prompt template — blind (Stage 1)

Use when dispatching the SPEC reviewer (first stage, per task). It is a **pure** compliance verdict — **do NOT run tests or fill Verification** (that belongs to Stage 2). The reviewer receives fabricated context, never the session history.

This lens is **blind** by design. In the `split` profile — the **recommended default**, where it runs in its own dispatch — the anchor holds: **The spec lens reviewer does NOT receive the implementer's report — it judges the code against the contract, without the author's narrative.** Do not paste the report into this briefing. (In `combined`, an exception the user ratifies at the gate, a single reviewer merges this rubric and the quality/evidence one into a single briefing, and the report enters through the quality/evidence rubric — never through here.)

Blindness is **not** lack of project context: this lens receives the diff, the task's spec/plan, **and the area's domain skills**. What it does not receive is the author's narrative.

````text
You are reviewing whether an implementation matches its specification.

## What was asked

{FULL_TASK_TEXT}

## Domain skills to apply

{DOMAIN_SKILLS}   # paste the relevant ones from the pelizzai/domain-skills.md catalog (consumer) or
                  # from the source repo's rules/skills (source mode), or "none"

These are this project's rules — part of the contract you are measuring against. Code that fulfills
the task text but violates a domain skill pasted here is a finding, not a style detail.
In conflict with generic patterns, the domain skills PREVAIL. If the slot arrives empty or
"none" and the change clearly belongs to an area with conventions of its own, say so in the verdict.

## CRITICAL: you do NOT receive the implementer's report

This is the blind lens. You do not have the author's narrative about what they claim to have done —
and that is intentional: judge the code against the CONTRACT (what was asked above), without being
anchored by optimistic claims. VERIFY everything independently by actually reading the code.

The implementer has NOT committed — the code is in the working tree (`git diff`, `git diff --staged`,
and new files via `git status`). Read that code and check:

- Missing: did they implement everything that was asked? Skipped/forgot any requirement?
- Extra/unnecessary: built what was not asked? Over-engineering? "Nice to haves" outside the spec?
- Scope creep (a first-class finding category): is there behavior in the diff that was not asked for?
- Line-level traceability (mechanical criterion): does every changed line trace directly to a
  requirement of the request? A line with no trace is a finding, not a detail.
- Misunderstandings: interpreted differently from what was intended? Solved the wrong problem? Right, but the wrong way?
- Domain skills: does the change respect the rules pasted in the section above?

Verify by READING THE CODE against the contract.

## Verdict (compliance only — no running tests, no Verification)

- ✅ Matches the spec (everything checks out after code inspection), or
- ❌ Issues: [list specifically what is missing or extra, with file:line], or
- ⚠️ Not verifiable: [what could not be confirmed and why] — the coordinator assesses against the plan.
````

**Placeholders:** `{FULL_TASK_TEXT}` (pasted from the plan) · `{DOMAIN_SKILLS}` (operational points of the area's skills, or `none` — same slot as in `code-reviewer.md`). The implementer's report is **not** a placeholder of this lens — it goes only to the quality/evidence lens (see `code-reviewer.md`).
