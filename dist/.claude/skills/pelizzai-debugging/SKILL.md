---
name: pelizzai-debugging
description: Head skill of the bug track. Use when encountering a bug, test failure, incident, or unexpected behavior — including when the user says "it doesn't work", "it's buggy", "it broke", "strange behavior", or "stop guessing", and when a test breaks in the middle of another task. Triages between direct cause, uncertain deterministic bug, flaky/distributed failure, and incident with active damage; picks proportional reasoning and validation, contains damage reversibly before investigating, and never mandates RCA, OODA, or a fixed number of hypotheses.
---

# PelizzAI Debugging

## Goal

Fix the proven cause with the least process that preserves evidence, safety, and regression coverage.

**Announce on start:** "Using the PelizzAI Debugging skill to classify the failure, contain impact if needed, and fix it with evidence."

## Invariants

```text
NO DEFINITIVE FIX WITHOUT SUFFICIENT EVIDENCE OF THE CAUSE.
REVERSIBLE CONTAINMENT IS NOT A FIX AND MAY PRECEDE THE INVESTIGATION.
```

- Do not conflate symptom, hypothesis, confirmed cause, containment, and prevention.
- Do not impose RCA on a direct cause or OODA on a short sequence.
- Do not invent a hypothesis count. Keep only the materially plausible ones.
- The fix runs inline. Delegate only read-only investigation of genuinely independent hypotheses; the main session decides and implements.

---

## Step 0 — is there active damage?

Before reproduction, check whether users, data, security, availability, or cost are still being affected.

If **yes**:

```text
1. Confirm target, scope, and authorization.
2. Preserve the minimum evidence containment would erase (metrics, IDs, logs, version/diff).
3. Apply the smallest reversible containment available: known rollback, feature flag, pausing a consumer,
   blocking the vulnerable route, or reducing exposure — as the system and permissions allow.
4. Monitor the impact signal and confirm it has stabilized.
5. Only then investigate the structural fix.
```

If no safe containment exists or you lack the authority, escalate immediately with target, impact, proposed option, and risk. **Never block containment waiting for a perfect reproduction.**

---

## Step 1 — classify before choosing the reasoning

| Class | Signals | Reasoning | Hypotheses | Path |
| --- | --- | --- | --- | --- |
| **Direct cause** | compiler, stack trace, or contract points to an unambiguous local cause | ReAct + Verification | zero or one | reproduce the error → fix → run the same oracle |
| **Uncertain deterministic** | fails every time, but the origin is not yet proven | light RCA + ReAct | one is enough if it discriminates; add others only if they compete | minimal loop → evidence → falsifiable hypothesis → fix |
| **Flaky, recurring, or distributed** | variable rate, concurrency, network, multiple layers/retries | RCA + Evidence Synthesis; Assumption Tracking when useful | several, only while materially plausible | measure the rate → correlate boundaries → test the most informative hypothesis |
| **Incident with active damage** | degraded production, exposure, ongoing loss/cost | Constraint Satisfaction + Decision Making for the containment; RCA afterward | after stabilizing | contain → monitor → reclassify and investigate |

Use `pelizzai-loop`/OODA only when there are **multiple rounds** and each round changes evidence, hypothesis, or external reality. OODA is the control macro-loop; it is not a diagnostic technique.

---

## Step 2 — build the cheapest oracle that proves the symptom

Prefer an executable, already-run command that fails on the exact symptom. In a consumer, use
`pelizzai/profile.md` when it exists; in source mode or without a profile, discover the command in
the real manifests, scripts, and workflows. Do not guess and do not create a profile just to
investigate. The tactics menu lives in [references/feedback-loops.md](references/feedback-loops.md);
**this SKILL.md is canonical for triage and order**.

The oracle can be a test, typecheck/build, minimal script, controlled query, trace, metric, or reproduction rate. For a flaky failure, record conditions and frequency; for an incident that cannot be reproduced outside production, correlated metrics/logs can be the initial oracle.

Collect only the evidence that discriminates between paths:

```text
- full message, stack trace, input, and environment;
- recent changes and the diff of the area;
- an equivalent example that works;
- the value's flow up to the first point where it becomes incorrect;
- across multiple layers, input/output and correlation/request ID at each boundary.
```

Existing telemetry can be read immediately. Any instrumentation that changes code/config goes
through `pelizzai-starting-branch` **before** the edit; any eventual deploy also goes through the
`external` gate. If you add temporary instrumentation, create a unique `[DEBUG-<id>]` prefix, use it
in every new log line, and remove it before the definitive implementation.

**Minimize the loop — only in the "uncertain deterministic" and "flaky" classes.** With the red
oracle in hand, cut ONE element at a time (fixture, flag, step, layer, input field) and re-run the
oracle after each cut. It is minimized when every remaining element is load-bearing: removing any
one makes the bug vanish or breaks the oracle. For a direct cause this is waste — the stack trace
has already isolated the element; in an incident with active damage,
the Step 0 containment comes before any cut.

---

## Step 3 — test hypotheses proportionally

A provable direct cause needs no causal brainstorming. When there is uncertainty:

```text
1. Record confirmed facts separately from hypotheses.
2. For each material hypothesis, write a falsifiable prediction.
3. Choose the observation that best discriminates the hypotheses at the lowest cost/risk.
4. Change one variable at a time; do not stack fixes.
5. Evidence refuted the hypothesis → discard it and reorient.
```

Present the hypothesis ranking to the user whenever more than one materially plausible hypothesis remains — their operational knowledge often reorders the priorities; do not interrupt a local bug with a single or obvious cause with ceremony. Use `pelizzai-team` for read-only investigation only when independent hypotheses can be tested in parallel or after real thrashing.

**Three failed definitive fixes stop the track — they do not become a fourth fix.** Stop, count
the attempts and summarize the accumulated evidence. Three fixes that do not solve it **are** a material gap:
the model of the problem is wrong and the next choice is not yours. Trigger `pelizzai-interview-me`
to stress-test hypothesis and architecture with the user, one question at a time, with a
recommendation. If the conversation reveals a structural or design problem, escalate to
`pelizzai-brainstorming` (feature track). Without that discussion there is no fix #4.

---

## Step 4 — implement and prove

Before any mutation in the repository — test, instrumentation, or fix — use
`pelizzai-starting-branch`. In a consumer, load the applicable skills from
`pelizzai/domain-skills.md`; in source mode, use the source repo's own rules/skills. Revert
throwaway experiments that do not belong to the fix. Authorized operational containment that does
not write to the repo does not wait for a branch.

Track `bug` uses the **compact one-line confirm** — not the post-plan gate's question menu.
`pelizzai-starting-branch` discovers the base and proposes the name WITHOUT a stop of its own (a
base with no unambiguous candidate still stops there); the head skill is the sole emitter, the
router does not duplicate it, and reversible containment/read-only investigation do not wait for
it:

`Kickoff: fix on branch fix/<slug> @ <base-ref> (<short-sha>) — isolation: branch · mode: inline · commits: granular. Ok? (overrides: worktree · subagents/team · squash-final · different name/base)`

A single "ok" ratifies base, name, and the three decisions at once — all named on the line, nothing
was silent; a named override adjusts only that item and keeps the rest. Only then is the branch
created. Do not scatter this line into separate questions. After the "ok" (or the overrides), record
the marker
`kickoff: ratified <YYYY-MM-DD>` (with isolation/mode/commit) — in a consumer in
`pelizzai/data/state.md`, in source mode in the native execution record with the same keyword —
BEFORE the first product write to the repository. The head skill is the sole owner of this marker in
track `bug`; without it the writegate (Rule B) blocks product writes and resumption does not
recognize the gate. Reversible containment (Step 0) and read-only investigation do not wait for it;
temporary instrumentation, the regression test, and the fix do — if the Step 2 instrumentation is
the first product mutation, run the confirm and record the marker before it. Under a closed
briefing (SUBAGENT-STOP), produce no route analyses and open no gates: apply the briefing and
escalate to the coordinator whatever requires a decision.

Choose the strategy by the nature of the change, per `pelizzai-reasoning`:

```text
- Behavioral bug with an automatable seam: red→green regression test via pelizzai-tdd.
- Direct static error (import, type, build): the reproducing typecheck/build can be sufficient proof;
  add a test only if it protects useful behavior.
- Refactoring required by the fix: green characterization first, small steps, same suite green after.
- Config/IaC/migration: validate/plan/dry-run and rollback; unit tests only for separable logic.
- UI: pelizzai-frontend is a mandatory overlay; behavior when applicable + visual verification.
- Documentation: lint/links/examples/build/render or proportional static inspection.
```

Implement **one** fix at the origin, with no "while I'm here".

If the confirmed root cause establishes a durable architectural decision (hard to reverse,
surprising without context, **and** the product of a real trade-off — all three together), trigger
`pelizzai-domain-modeling` to record the ADR **before the seal**. Since it is an emergent decision —
with no prior design gate — domain-modeling presents it to the user at the completion edge before
writing; creating the ADR is the coordinator's action. Never record an ADR after `validated-head`.

Then:

```text
1. Re-run the original oracle — now green.
2. Run the relevant validation and confirm no regressions.
3. Review the working tree with `pelizzai-review`; apply findings and re-run the affected proofs.
4. Consolidate the content into a definitive commit. If an explicitly authorized squash-final
   strategy produced WIPs, consolidate it now, before the seal; finish-task does not rewrite history.
5. Run `pelizzai-verification-before-completion` against the consolidated HEAD, record
   `validated-head`, and only then call `pelizzai-finish-task`: metadata-only closure in a consumer;
   closing of the execution record, with no runtime/closure, in source mode.
```

If no adequate seam exists for an important regression, record the architectural finding and route it to `pelizzai-improving-architecture`; do not write a tautological test at the wrong seam.

---

## Proportional closeout

Always:

```text
[ ] Original oracle re-run and green.
[ ] `rg "\[DEBUG-"` finds no instrumentation from this session.
[ ] Prototypes and experimental changes removed.
[ ] Diff contains only the fix and its proof.
[ ] Confirmed cause — the winning hypothesis — recorded in the COMMIT MESSAGE of the fix.
```

For a recurring, distributed, or security failure, or an incident, also record: confirmed cause, contributing factors, containment, prevention/detection, and "what would have prevented this?". For an obviously wrong import, do not invent a post-mortem.

## Signals from the human partner

User phrases that carry a diagnosis — decode and act, do not argue:

| Signal | Diagnosis | Action |
| --- | --- | --- |
| "Isn't this happening?" | you assumed something without checking | check now, against the oracle |
| "Stop guessing" | your hypotheses have no falsifiable prediction | go back to the oracle (Step 2) and re-derive the hypotheses with predictions |
| "Are we stuck?" | thrashing — stacked fixes without progress | stop; summarize what you know, what is missing, and the next step |
| "We already tried that" | you lost the thread of what was tested | re-read hypotheses and results before repeating |

## Red flags

```text
- Investigating at length while the damage continues and reversible containment is available.
- Declaring root cause from temporal correlation.
- Demanding 3–5 hypotheses for a direct error, or accepting a single one in a distributed system without evidence.
- Using OODA as a name for every command/test.
- Fixing duplication with nothing but frontend debounce/delay.
- Raising a timeout, disabling security, or hiding the symptom as the definitive solution.
- Stacking changes and then asking which one worked.
- Attempting fix #4 after three failures without returning the decision to the user.
- Writing an artificial test just to claim TDD was used.
```

## Integration

**Routed by:** `pelizzai-router` (track `bug`).

**Uses conditionally:** `pelizzai-reasoning` (selection above), `pelizzai-loop` (macro-loop across rounds only), [feedback-loops.md](references/feedback-loops.md), domain skills, `pelizzai-starting-branch`, `pelizzai-tdd` (automatable behavioral bug), `pelizzai-frontend` (UI), `pelizzai-team` (read-only investigation of independent hypotheses), `pelizzai-interview-me` (the three-fix circuit breaker and any other material gap), `pelizzai-brainstorming` (when the interview reveals a structural problem), `pelizzai-verification-before-completion`, `pelizzai-review`, and `pelizzai-finish-task`.

For external APIs/libs, derive the version from manifests/lockfiles and consult Context7 before
committing to a hypothesis; current official documentation is the fallback. For a missing seam, use
`pelizzai-improving-architecture` with the vocabulary of `pelizzai-codebase-design`.
