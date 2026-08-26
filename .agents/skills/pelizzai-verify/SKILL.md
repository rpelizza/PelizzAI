---
name: pelizzai-verify
description: "Use before claiming anything is done, fixed, or passing — before committing, integrating, pushing, or opening a PR. Run the proof, read the output, then claim; evidence before assertion."
---

# PelizzAI Verify

## Goal

Claiming work is complete without verifying is dishonesty, not efficiency. This skill is the gate
that requires **fresh evidence** before any claim of success and makes the strength of the
assertion match the evidence. Verification is a causality gate: the proof must observe the claimed
effect **after the last mutation that could alter it**.

**Announce** only when it is an explicit phase — in the conversation's language, that you are
using the PelizzAI Verification Before Completion skill to confirm with evidence before declaring
done; as an embedded gate of another skill, run without a new preamble.

## Core principle

> Evidence before assertion, always. Violating the letter of this rule is violating its spirit.

## The Iron Law

```text
NO CLAIM OF COMPLETION WITHOUT FRESH VERIFICATION EVIDENCE.
```

If you do not have the output of a proof **from this round of changes**, you **cannot** claim it
passes.

**In a consumer, judge against `pelizzai/data/verification-standard.md`** — what "correct" means in
this project, its procedure, and the baseline per surface. It is **read-only during any correction**:
if an output fails, fix the output. Editing a criterion, the procedure, or a baseline row so a
failing output passes is the guardrail violation under a friendlier name, and it is the failure this
file exists to make visible. The standard changes only in a deliberate change of its own, ratified
through `pelizzai-interview` via `pelizzai-evolve`. Missing file, or source mode: say so, and judge
by the plan's acceptance criteria.

## The gate

```text
BEFORE asserting any status or expressing satisfaction:

1. IDENTIFY: what is the exact claim, and what is the smallest oracle that actually observes it?
   (in a consumer, use the target project's commands — pelizzai/data/state.md, the project: field,
   and pelizzai/profile.md; in source mode, the real manifest/script.)
2. RUN: execute the COMPLETE, fresh proof, after the last mutation that could alter the result.
3. READ: the entire output — check the exit code, count the failures, look at the delta and the limitations.
4. VERIFY: does the output confirm the claim?
   - If NO: state the REAL status with the evidence, or reduce the claim to what was proven.
   - If YES: make the claim TOGETHER with the evidence.
5. ONLY THEN: make the claim. In a Git delivery, seal the same HEAD that will be integrated.

Skipping any step = lying, not verifying.
```

“Fresh” does not mean “in the same message”: do not re-run the whole suite for every sentence. It
means the evidence:

- was produced in this round of changes or is an identified verifiable artifact;
- postdates the last code/config/doc/overlay/fix that affects the result;
- matches the same relevant environment, inputs, and HEAD;
- was not invalidated by a commit, amend, merge, rebase, codegen, formatter, or a test that writes.

A conversation-only change does not invalidate proof. A product change does.

## Proof by effect

| Claim/effect | Adequate evidence | Not enough |
| --- | --- | --- |
| bug fixed | the symptom's oracle now green + relevant regression | diff “looks right” |
| new/changed behavior | contract test; RED observed when TDD was the strategy | tautological test or snapshot only |
| preserving refactor | characterization/equivalent suite before and after | new test invented on green |
| build/type/lint | the matching canonical command + exit code | extrapolating one check to another |
| config/schema/migration/IaC | parser/validate/plan/dry-run, delta, and applicable rollback | unit test without observing the artifact |
| integration | real fixture/sandbox/contract at the boundary | mock that removes the boundary |
| UI | `pelizzai-interface`: app running, states, viewports, accessibility/visual | green build or a single screenshot without the flow |
| docs/prompt/policy | lint/render/links/schema/grep or a consumption scenario | fabricating a unit test |
| plan requirements | traceability requirement → task/diff/proof | “the tests pass” |

Combine rows for mixed tasks. Do not run unrelated checks just to inflate output volume.

**Scope during a task, whole suite at the end.** A task proves the files it touched; the full
suite runs once, before the final review, and it is not optional — it is the only run positioned to
catch an interaction no single task could see. Two exceptions, both narrow: a task whose subject is
itself cross-cutting (a shared type, a global config, a migration) has no meaningful touched-files
scope and runs the suite; and a red inherited from an already-failing module is named in the
briefing, or it gets reported as this task's failure. See `pelizzai-execute` →
`references/task-cycle.md` §2, which owns this rule.

## Common failures

The matrix above picks the proof. This table lists the claims where the lying happens most
often:

| Claim                     | Requires                                | Not enough                           |
| ------------------------- | --------------------------------------- | ------------------------------------ |
| Tests pass                | Test command output: 0 failures         | A previous run, "it should pass"     |
| Linter clean              | Linter output: 0 errors                 | Partial check, extrapolation         |
| Build works               | Build command: exit 0                   | Linter passed, "the logs look ok"    |
| Bug fixed                 | Testing the original symptom: passes    | Code changed, presumed fixed         |
| Valid regression test     | Verified red-green cycle                | The test passes once                 |
| Subagent finished         | Git diff shows the changes              | The agent reported "success"         |
| Requirements met          | Line-by-line checklist against the plan | The tests pass                       |

## Key patterns

```text
Tests:
✅ [run the command] [see: 34/34 pass] "All tests pass"
❌ "It should pass now" / "Looks correct"

Regression test (TDD red-green):
✅ Write → Run (passes) → Revert the fix → Run (MUST FAIL) → Restore → Run (passes)
❌ "I wrote a regression test" (without the red-green cycle)

Build:
✅ [run the build] [see: exit 0] "Build passes"
❌ "The linter passed" (a linter does not verify compilation)

Requirements:
✅ Re-read the plan → build a checklist → verify each item → report gaps or completion
❌ "The tests pass, phase complete"

Subagent delegation:
✅ Subagent reports success → check the git diff → verify the changes → report the REAL state
❌ Trusting the subagent's report
```

## TDD and regression

If the RED→GREEN cycle was already observed and recorded in this round, before the fix, it already
is the proof: do not revert the final content to stage another RED — re-run GREEN and the affected
regression checks. When there is no evidence that the test detects the defect, the cycle above is
mandatory and must be obtained by safe means (reverting the fix in the editor, controlled mutation,
a temporary branch/patch, or a preserved earlier reproduction), always restoring and re-verifying
the state. Do not use destructive reversion or leave the working tree ambiguous.

## Warning signs — STOP

```text
- Using "should", "probably", "it seems".
- Expressing satisfaction before verifying ("Great!", "Perfect!", "Done!").
- About to commit/push/PR without verification.
- Trusting a subagent's success report.
- Leaning on partial verification.
- Thinking "just this once".
- Fatigue and the urge to finish.
- ANY phrase that implies success without having run the verification.
```

```text
- Using a partial proof for a broad claim.
- Forcing TDD/mutation testing on an artifact with no automatable behavior.
- Declaring UI done without the frontend overlay and an explicit visual limit.
- Recording validated-head before squash/overlays/fixes/final review.
- Delivering a HEAD different from the validated content.
- Re-running checks just because the message changed, without a relevant mutation.
```

## Rationalization prevention

| Excuse                                    | Reality                  |
| ----------------------------------------- | ------------------------ |
| "It should work now"                      | RUN the verification     |
| "I am confident"                          | Confidence ≠ evidence    |
| "Just this once"                          | No exceptions            |
| "The linter passed"                       | Linter ≠ compiler        |
| "The subagent said it worked"             | Verify it yourself       |
| "I am tired"                              | Exhaustion ≠ excuse      |
| "A partial check is enough"               | Partial proves nothing   |
| "Different words, the rule does not apply" | Spirit above the letter  |

## Delegation and review

An agent's report is not proof by itself. Check the artifact/diff and run the evidence that is the
coordinator's responsibility. In the per-task review, the Verification block covers the quality
lens; on the final candidate, the coordinator revalidates the consolidated range/HEAD according to risk.

`UNVERIFIED` is a valid, honest state. Say what could not run and limit the conclusion; do not
convert a missing tool into approval.

## Frontend

Any change to a page, component, CSS, layout, visual state, or UX applies
`pelizzai-interface` as an overlay: green tests and an ok build do **not** prove the page renders
correctly. Approved spec/Figma/design system prevail over heuristics; anti-AI-slop, states,
responsiveness, accessibility, and visual QA remain part of the proof.

Playwright, the browser, and screenshots are tools, not substitutes for the frontend contract. If
the UI cannot run, do the planned static review and declare that visual validation remains pending.

## Sealing the Git content

After all product mutations and the final commit strategy:

```text
1. Confirm a clean working tree and validated-head: <none>.
2. Capture candidate-head = git rev-parse HEAD.
3. Confirm the evidence of the overlays already completed and run the final review,
   checks/checklist, and this Verification against candidate-head; any fix or reopened overlay
   restarts the candidate.
4. Confirm HEAD is still candidate-head.
5. Consumer: record the full candidate-head in state as validated-head, without committing.
   Source mode: record it in the execution record and keep the working tree clean.
6. Hand over to pelizzai-finish.
```

Finish-task closes out in `phase: delivered` (sealed content + destination executed), never in `done`;
`done` is a later observation against `confirm:`, on the next open/resumption. Verification seals
the content; it does not declare `done`.

When recording `validated-head`, confirm that the state/execution record carries `kickoff: ratified`:
the sealed content was born from a ratified structural route, not from silent defaults. If the
marker is `pending` on a planned delivery, the route was not ratified — resolve it at the right
gate before sealing. It is a one-line anchor, not a new checklist; read-only/trivial does not seal
and does not require it.

At finish-task entry in a consumer:

- `git rev-parse HEAD == validated-head`;
- the only dirt is `pelizzai/data/state.md` with the pending seal;
- no evidence predates the last fix/overlay.

Finish-task creates exactly one metadata-only closure commit. Before push/PR, it proves that
`validated-head..closure-head` contains only harness metadata: `pelizzai/data/state.md` and the
`pelizzai/data/history/<YYYY-MM-DD>-<slug>.md` file generated by the seal migration. That commit
does not change the validated content.

In source mode, finish-task receives `validated-head` from the execution record, requires an equal
HEAD and a clean working tree, and does **not** create a state/closure commit.

Any product mutation after the seal invalidates `validated-head`: go back to the
overlays/review/proofs, commit the new candidate, and seal again. Never “fix just one more thing”
in finish-task.

## When to apply

```text
ALWAYS before:
- Any variation of a claim of success/completion or that something is working.
- Any expression of satisfaction.
- Any positive statement about the state of the work.
- Committing, sealing a Git delivery, pushing, opening a PR, integrating, or completing the task.
- Any external effect whose safety depends on the result.
- Incorporating as done the work returned by a subagent/member.
- Moving to the next task, and at the task/phase gate when the head skill requires it.

The rule covers: exact phrases, paraphrases and synonyms, implications of success —
any communication that suggests completion or a fix.
```

Do not trigger a final validation for every tool call, intermediate question, or delegation
dispatch. Local evidence may guide the next action without a claim of completion.

## Why this matters

Claiming completion without evidence breaks trust and creates rework: an undefined function that
will break in production, a missing requirement delivered as done, time lost on false completion →
redirection → rework. The real cost shows up when the human partner stops believing your word
("I don't believe you") — broken trust is not recovered with one more claim, but with evidence.
Honesty is a core value of the harness: state what you **proved**, not what you hope.

## Integration

- `pelizzai-execute` — gate before declaring the task/plan complete (final review →
  verification → `pelizzai-finish`).
- `pelizzai-finish` — verifies before consolidating and before any push/PR; receives the
  content already sealed.
- `pelizzai-review` — the reviewer's `Verification` block is this same discipline (fresh evidence;
  UNVERIFIED never ✅), per task and in the final review; this skill is the gate for the whole delivery.
- `pelizzai-tdd` — red-green produces the test; the regression PROOF (revert the fix → MUST FAIL →
  restore) is required here.
- `pelizzai-interface` — performs the visual verification of the running UI (browser/screenshot,
  mobile and desktop) that this skill requires for interface changes.

The head skill decides when the gate enters; this skill decides whether the evidence supports the
conclusion.

## Final instruction

```text
No shortcuts to verification.

Run the proof. Read the output. ONLY THEN state the result.

Prefer:
- fresh evidence over "it should work";
- exit code and failure counts over "looks ok";
- the real state over a subagent's report;
- a checklist against the plan over "the tests pass";
- proof of the effect over ritual, and the sealed content over content delivered by mistake.

This is non-negotiable.
```

Prove the effect, not the ritual: reuse evidence that is still valid, invalidate it when the
product changes, and seal exactly the content that will be delivered.
