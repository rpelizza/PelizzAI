---
name: pelizzai-router
description: Orchestrator for any request that needs to inspect or change a project. Classifies effect, intent, risk, uncertainty, and surfaces; recommends one head skill and overlays; guarantees ratification and isolation before writing. On the first interaction with a consumer project, with the harness not initialized (no `pelizzai/domain-skills.md`), or when the user says "bootstrap", proposes the bootstrap via `pelizzai-audit` before routing. Every greenfield product/project goes through approved discovery, spec, and plan even with the stack specified. Use after `pelizzai-core`; do not use in a purely conceptual conversation without a project.
---

# PelizzAI Router

<SUBAGENT-STOP>
If you received a closed subtask, do not route again. Follow the briefing and escalate if context is missing.
</SUBAGENT-STOP>

## Purpose

Produce the smallest route that solves the task safely. The router decides the **lifecycle**; `pelizzai-reasoning` decides the **heuristics** within each phase.

**Announce**, in the conversation's language: that you are using the PelizzAI Router skill to classify the task's effect, risk, and flow.

## Decision envelope

Before triggering another skill, derive:

```text
effect:      read-only | write-local | external
intent:      bootstrap | feature | bug | tweak | refactor | infra | review | conflict
risk:        low | medium | high
uncertainty: low | medium | high
surfaces:    ui | security | data | public-contract | docs | none
```

### Effect

| Effect | Criterion | Rule |
| --- | --- | --- |
| `read-only` | explain, analyze, map, review, or diagnose without changing state | May inspect; never creates/edits state, catalog, profile, branches, or files. |
| `write-local` | change code, files, configuration, or a versionable artifact | Isolation before the first persistent write. |
| `external` | push/PR/deploy/message/cost/permission/production/deletion | Validate authority, target, reversibility, and confirmation at the action's gate. Git isolation only precedes the action when it also writes to the repository. |

A task may start read-only (investigation) and switch to write-local when the user asks for the fix. Reclassify **before** the first mutation.

### Risk

```text
low    — local, reversible, no contract/data/security.
medium — persistent behavior, limited integration, or an additive/reversible public contract
         with clear acceptance.
high   — data, auth, security, production, a breaking or large-blast-radius public contract,
         irreversibility, or multiple systems.
```

### Uncertainty

```text
low    — goal, acceptance, and approach were stated or ratified by the user.
medium — there are real choices, but the space is limited.
high   — requirements/cause/architecture still need to be discovered.
```

Do not turn these classifications into a form. Derive them from the request and the evidence, but do
not confuse harness inference with human decision. Present the assembled ROUTE (lane, head skill,
overlays, and artifacts) as a recommendation at the **kickoff gate** and wait for ratification on
every mutating task. Classifying is the harness's job; accepting or adjusting the route is the
user's decision.

## Proposal analysis (whenever there is a non-trivial mutating effect)

After deriving the envelope and BEFORE choosing the head skill, run a compact stress pass over the request — trigger the **Proposal Stress (Assumption Tracking applied)** routine from `pelizzai-reasoning` ([proposal-stress.md](../pelizzai-reasoning/techniques/proposal-stress.md)). Present in ≤6 bullets:

- material assumptions that would need ratification to proceed;
- gaps that change scope/UX/architecture/security/data;
- concrete risks;
- materially different alternatives, when they exist.

The Proposal analysis is diagnosis, not authorization. It feeds the **Discovery** line of the
kickoff gate; each gap that belongs to the user will be resolved later by
`pelizzai-interview`, one question at a time, with a recommendation.

Proportionality does not remove authority. In pure `read-only` and a trivial tweak/bug whose
contract was stated, the analysis may collapse to zero. In `bounded`, it collapses to one line: "No
material gaps; stated contract: <short list>". A greenfield project/product never collapses: a
specified stack does not define users, flows, states, policies, UX, data, or acceptance.

Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP), do not produce the Proposal analysis or open Discovery: apply the briefing and escalate to the coordinator whatever requires a decision.

## Source mode and bootstrap

Detect the PelizzAI source repo EXCLUSIVELY by the sentinel:

```text
scripts/pelizzai-source-repo.txt
```

The manifest (`scripts/pelizzai-core-skills.txt`) and the `sync-harness.*` scripts also exist in
consumers installed via `-ExportConsumer` — their presence does NOT indicate source mode.

In **source mode**, do not require `pelizzai/domain-skills.md` and do not create consumer runtime.
Work by the source repo's rules. For mutating tasks, still use a task branch and proof, but keep
plan/progress in the platform's native mechanism and the seal as the execution record's SHA; do not
create `pelizzai/data/state.md`, consumer specs/plans, or a state closure commit.

The **native execution record** is the task's logical state in the platform's plan/task mechanism,
never a substitute file in the repo. Keep in it, when applicable: `phase`, branch/base, isolation,
execution decisions, progress, overlays, `validated-head`, `delivery-head`, and destination status
(`local | pushed | pr-open | partial`). End at `phase: done` or `phase: blocked`;
`phase: delivered` is a resting state that still requires `done` to be observed (see State and resumption).

In a consumer project, **before classifying the request**, check: is the harness initialized?
If `pelizzai/domain-skills.md` does NOT exist — or it is the first interaction with this project, or
the user typed `bootstrap` — **propose** the bootstrap via `pelizzai-audit` (maps the project,
creates the domain skills and docs) as the first thing in the turn and wait for the answer.
The router does not wait for the user to remember to ask: a missing catalog is signal enough to
raise the proposal, in one line, with the reason.

Proposing is not executing. The bootstrap only writes after an explicit "yes" — once accepted, the
effect becomes `write-local` and the first-write gate applies. If the user declines or defers, the
original request proceeds as it was: read-only stays read-only, no file is created, and you record
the limitation in one line ("proceeding without a domain catalog; the mapping stays for later"). A
purely conceptual question, which requires neither touching nor understanding THIS project, does not
trigger the proposal — answer directly. In source mode there is no trigger: there is no consumer
catalog to create.

| Situation | Route |
| --- | --- |
| Catalog missing, first interaction with the project | Invoke `pelizzai-audit` (at minimum `scan-only`) and propose the bootstrap before the kickoff gate; declining does not block the request. |
| Catalog missing, `effect: read-only` | Map in `scan-only`, propose, and wait. Yes → `pelizzai-audit` in `bootstrap-write`; no/later → continue in `scan-only`, no file is created. |
| User said `bootstrap`/`reinitialize` | `pelizzai-audit` in `bootstrap-write`. |
| Mutating task, catalog missing | Do scan-only, present the proposed minimum set of artifacts, and get consent for `bootstrap-write`. |
| Catalog exists, ledger missing | In an authorized mutating task, repair only the ledger; read-only just reports. |

With an **existing** catalog, re-running the bootstrap (remap) still requires an explicit request or
observed drift: the proactivity applies to an uninitialized harness, not to rewriting what was
already ratified.

## State and resumption

Read `pelizzai/data/state.md` when it exists, without writing it in read-only tasks.

```text
slug: <none> or phase: done
→ there is no active task.

phase: blocked
→ present the blocker before starting another mutation.

phase: delivered
→ sealed delivery awaiting observation. Apply §Reconciliation of the previous delivery
  (`pelizzai-execute`; resumption: `pelizzai-recovery`) BEFORE treating it as an active
  task or a conflict: verify `confirm:` against git and observe `done` — or propose resuming the
  branch or `abandoned`. Only then classify the new request.

active task matching the request
→ validate state against Git and resume without repeating confirmed decisions.

active task different from the new request
→ do not overwrite; report the conflict and decide with the user between finishing/pausing or
  opening another isolated front.
```

Validation:

- branch: compare the recorded branch with `git branch --show-current`;
- worktree: validate path + branch via `git worktree list` or run inside the worktree;
- base: confirm `base-ref`/`base-sha` when recorded;
- plan: the recorded path must exist in the execution environment.

On a divergence that risks work, use `pelizzai-recovery`; never reconcile destructively on a hunch.

## First-write gate

For `write-local`/`external`, invoke `pelizzai-starting-branch` **before** creating or changing:

- `pelizzai/data/state.md`;
- specs, plans, or ADRs;
- code, config, tests, scaffolds, or prototypes;
- the bootstrap's catalog/profile/domain skills.

In tracks with design/plan, open a normal **task/planning branch** first. The post-plan gate may:

- continue on that branch; or
- after a checkpoint of the planning artifacts, release the branch from the main working tree and mount a worktree from the **same existing branch**.

Never create a worktree from the clean base after writing spec/plan in another working tree.

## Classify intent and choose the lane

| Request | Track/head |
| --- | --- |
| Authorized bootstrap/remap, or accepted bootstrap proposal | `pelizzai-audit` (`bootstrap-write`) |
| Something broken/error/failure/unexpected behavior; "it doesn't work", "it broke", "there's a bug", "stop guessing" | `bug` → `pelizzai-debug` |
| Local change without a new rule/contract/surface (text, label, color, button/field on an existing screen; ~1 file/<~50 lines as a signal) | `tweak` → `pelizzai-quick-fix` |
| Local refactor preserving behavior | `tweak` → `pelizzai-quick-fix` |
| Review of a diff, working tree, branch, or PR | `review` → `pelizzai-review` |
| Codebase-wide review of architecture, debt, or seams | `review` → `pelizzai-architecture-refinement` |
| Git conflict in progress | `pelizzai-merge-conflict-resolution` |
| Greenfield product/project, even with the stack specified | `exploratory` → `pelizzai-ideia-generation` + `pelizzai-interview` → spec → plan |
| Feature/refactor/infra with design already approved and a plan ready | `pelizzai-execute` |
| Approved design/spec/Figma, clear acceptance, but no plan | `pelizzai-writing-plans`; brainstorming/pelizzai-interview **proposed** when the Proposal analysis flags a material gap |
| Stress-test an existing design/plan, resolve a flagged material gap, or an interview request | proposed by the Proposal analysis or by the user → `pelizzai-interview` |
| Existing feature/refactor/infra with ratified requirements but no plan | use the lanes below |

### Feature/refactor/infra lanes

| Lane | Predicate | Route |
| --- | --- | --- |
| `bounded` | low uncertainty/risk; one cohesive behavior; clear acceptance; no architectural decision | `pelizzai-writing-plans` in compact mode; do not force brainstorming. |
| `standard` | medium risk and/or a few parts/contracts, with a clear solution and acceptance | `pelizzai-writing-plans`; prepend a compact brainstorming only if a real trade-off remains. |
| `exploratory` | high uncertainty, or high risk that demands discovery/design mitigation; architecture or sensitive coupled decisions | full `pelizzai-ideia-generation` + proportional stress → plan. |

### Greenfield rule

A greenfield product/project is always `exploratory` at entry: that includes creating a system,
application, service, or MVP from scratch, even when framework, language, and database have already
been chosen. The stack reduces technical uncertainty; it does not resolve product decisions. The
mandatory route, barring the user's explicit waiver of each artifact, is:

```text
ratified understanding
→ discovery with `pelizzai-interview`: one question at a time, with a recommendation
→ design/spec (`pelizzai-ideia-generation`)
→ spec stress-test with `pelizzai-interview` + approval
→ domain skills proposal and ratification
→ implementation plan
→ plan stress-test with `pelizzai-interview` + approval
→ ratified setup
→ execution
```

Context7/official documentation is read-only technical reconnaissance, not a late step. After
identifying the stack and the real version in manifests/lockfiles — or the candidate stack in
greenfield — consult it before kickoff whenever that improves classification, reveals constraints,
avoids a factual question, or sharpens the recommendation. Keep using it through design, planning,
implementation, debugging, upgrades, and skill authoring/maintenance. Never use it to invent a
persona, business rule, permission, state, priority, retention, or acceptance criterion.

A small, additive endpoint with a clear contract can be `standard` with stronger review/overlays;
risk raises proof and gates, it does not create artificial uncertainty. A large, mechanical change
can have low uncertainty. Lines/files are signals, not the main criterion.

## Mandatory overlays

Derive overlays by surface and propagate them to the plan, task brief, review, and Verification;
record them in the consumer state or the native execution record.

| Signal | Overlay/conduct |
| --- | --- |
| screen, component, CSS, layout, UX, accessibility | `pelizzai-frontend` from design/implementation through visual QA. |
| auth, external input, SQL, upload, secret, CORS, SSRF, dependency | `pelizzai-oswap` before final validation. |
| project-specific patterns | consumer: skills from `pelizzai/domain-skills.md`; source mode: the source repo's rules/skills. |
| human documentation in scope | `pelizzai-documentation` before final validation. |

`Playwright`, the browser, and screenshots are tools of the frontend overlay, not substitutes for it.

## Proportional execution defaults

Compute the setup defaults as a **recommendation**, not a decision applied silently. Read `pelizzai/profile.md` first (section `## Ratified execution defaults`, when it exists): a filled value is the recommendation to display; `<unset>` falls back to the proportional default below.

```text
bounded/tweak/common bug:
  isolation: branch
  execution-mode: inline
  commit-strategy: granular

plan with truly independent fronts:
  isolation: worktree recommended — ONE worktree per task, never one per agent; the fronts share it
  and only write on DISJOINT paths. execution-mode: subagents/team when there is real independence.

squash-final:
  only when the intermediate history has no value; consolidate BEFORE final validation.
```

The router does not apply these defaults — it computes the recommendation and forwards it for ratification:

- **Tracks with a plan** (bounded/standard/exploratory): defer isolation, mode, and commit to the consolidated **post-plan setup gate** of `pelizzai-execute` — that is where the three mode options (inline · subagents · **team**) are always visible and the commit strategy is always shown.
- **Write-local without a plan** (tweak/bug): hand the recommendation to the head skill; the head
  skill itself (`pelizzai-quick-fix`/`pelizzai-debug`) issues the compact ONE-line confirm —
  base, name, isolation, mode, and commits visible and named; one "ok" ratifies everything, a named
  override adjusts only that item — before the first write. The router does not duplicate the
  question; the one-decision-per-turn menu belongs to the post-plan gate.

`worktree` and `squash-final` are never applied without the user's choice. Use subagents/team for real independence, hypothesis diversity, or measurable gain; do not treat them as hierarchically better than inline.

## Material gap during execution

Ratifying the route does not end the user's authority. After kickoff — in spec, plan,
implementation, debugging, review, or closeout — **every material gap stops the work and goes back
to the user through `pelizzai-interview`**, one question at a time, with a recommendation. A
material gap includes: an ambiguous requirement; a scope, UX, architecture, data, or security
decision that the spec/plan does not cover; an undefined interface contract.

Filling the gap with a default, ecosystem convention, Context7, or "reasonable inference" is a
violation — including when the choice looks obvious and reversible. Context7 and official
documentation eliminate **factual** doubt; they never ratify a decision that belongs to the user.

Autonomy between gates still holds for the **mechanical, verifiable** step within already-ratified
boundaries (approved spec and plan, ratified setup). If the answer changes product, scope, UX,
architecture, data, security, cost, or acceptance, it is not mechanical: stop and ask.

## Sync & delta

For a mutating task in Git, observe reality before deciding:

```text
git status --short --branch
git fetch origin                 # only if there is a remote and the network is available
git log --oneline <base>..HEAD
git log --oneline HEAD..origin/<base>  # when the ref exists
```

Re-read only the relevant delta. Do not fetch in a read-only analysis without need, and do not hide a network failure.

## Execution record

Only mutating tasks update the record: the state template in a consumer; the native execution
record in source mode, without creating a file. Logical fields:

```text
slug, track, lane, phase, effect, risk, overlays,
base-ref, base-sha, branch, isolation, worktree-path,
execution-mode, commit-strategy, audience, kickoff,
spec, plan, project, confirm,
validated-head (only after final validation).
```

The record is the task's **cursor**, not a stamp card of approvals. In greenfield, the eight
steps (discovery → spec → stress → approval → plan → stress → approval → setup) remain mandatory
and their ratifications live in the **plan header**, dated; the setup gate only writes
`kickoff: ratified` after checking them there or after recording the user's explicit waiver.

When ratifying the kickoff gate, record the route's `lane`/`audience`/overlays, but leave
`kickoff: pending`: the `kickoff: ratified <YYYY-MM-DD>` marker belongs to the post-plan setup gate
or to the tweak/bug head skill's confirm, before the first product write. Resumption honors
decisions already ratified; a new task never inherits `lane`/`kickoff`/`audience`.

A new task never inherits decisions from the previous one. Closeout belongs to `pelizzai-finish`.

## Red flags

```text
- A mutating bootstrap to answer a read-only request without proposing and getting the user's "yes".
- Finding a missing catalog and proceeding in silence, without proposing the bootstrap.
- Writing state/spec/plan before isolation.
- Forcing full brainstorming on a bounded feature.
- Classifying a greenfield product/project as bounded because the stack was specified.
- Using lines/files as the only measure of complexity.
- Treating frontend/security as a late offer.
- Applying isolation, execution mode, or commit strategy without user ratification.
- Scattering the route or the setup across several micro-questions instead of one grouped block.
- Scattering the tweak/bug compact confirm across separate questions, or promoting a tweak to
  bounded/plan just because the acceptance is clear (a spec/plan to change a button is the
  historical failure).
- Silently assuming a decision that changes scope/UX/architecture without presenting it in the Proposal analysis or at the kickoff gate.
- Using Context7, convention, or a "safe default" as the user's vote.
- Filling with a default/convention/inference a material gap that appeared AFTER kickoff, instead
  of stopping the work and taking it to `pelizzai-interview`.
- Asking several discovery questions in the same turn when the previous answer changes the next.
- Parallelizing writes in a shared working tree as if a worktree isolated the agents.
- Inheriting `lane`/base/branch/strategy from a PREVIOUS task's state as accidental carryover — the
  project policy explicitly ratified in `profile.md` is the only exception.
- Triggering several head skills at the same time.
```

## Kickoff gate (route as a recommendation)

After assembling envelope → Proposal analysis → lane → head skill → overlays, present the **proposed route** as a **recommendation to ratify** before investing — never a form, a single block with the default already pre-selected. The classification remains yours; following or adjusting it is the user's. The router is the **sole** issuer of the kickoff; the core only flags intent/audience/ambiguity and hands off.

**When it informs and proceeds:** only `read-only` review/analysis/explanation, because there is no
mutation to authorize. Every mutating route stops at kickoff, including `bounded`, tweak, and bug;
the block's depth can be a single line, but the affirmative answer is mandatory.

**Before the kickoff:** in a consumer project without a catalog, the bootstrap proposal (§Source
mode and bootstrap) comes first and applies even in `read-only`. It is not the kickoff — it is a
one-line question about initializing the harness; a "no" returns the request to its original route
without creating anything.

**For every mutating task:** stop and wait for ratification. Ask a single question about the route;
show details as context, not as several simultaneous questions:

```text
**Kickoff gate — proposed route:**
- Understanding: <X> as a <feature|tweak|bug|refactor>
- Lane: <bounded|standard|exploratory> — <one-line justification>
- Head + overlays: <head skill> + <overlays or "none">
- Discovery: <"no material gaps" | numbered list of gaps → I recommend <compact|full pelizzai-ideia-generation|focused pelizzai-interview>>
- Artifacts: <spec/plan/ADR expected in this lane | "none beyond the native plan">; in greenfield/exploratory with a missing catalog or a new stack, also list "stack domain skills (proposed at the design edge)"

Recommendation: accept this route because <reason>.
Single question: May I proceed with this route? (yes or adjust)
```

An affirmative answer accepts the route; the user may adjust lane, discovery, artifacts, or overlay.
Without an affirmative answer, hold the turn. After kickoff, discovery asks **one decision per
turn**, always with a recommendation; do not turn the route block into a requirements questionnaire.

In a greenfield/exploratory lane with a missing catalog or a new stack, the Artifacts line
anticipates the "stack domain skills (proposed at the design edge)": they will be proposed by the
**proactive domain skills gate** of `pelizzai-audit` at the design→plan edge — the user already sees
at kickoff that they are coming and decides there.

**Audience:** when the user seems non-technical or the intent admits ≥2 material readings, the block's first line re-presents the understanding (handshake) before routing; record `audience: technical | layperson` (see Execution record). Do not dump jargon; follow `pelizzai-writing-clearly`.

**Discovery:** when there is a material gap, recommend `pelizzai-ideia-generation`/`pelizzai-interview`.
Accepting starts the sequential interview. Skipping discovery requires an explicit request and
records which decisions were left unvalidated; the LLM does not fill those decisions on its own.

**Setup stays out of this block:** isolation, mode (with `team` always visible), and commit are ratified at the post-plan setup gate of `pelizzai-execute` (tracks with a plan) or in the head skill's one-line confirm (tweak/bug). The router recommends silently and does not repeat the question.

Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP), do not produce route analyses or open the kickoff gate: apply the briefing and escalate to the coordinator whatever requires a decision.

## Regression evaluation

When changing routing, Context7, discovery, spec, plan, or authority rules, validate the matrix
[adaptive-user-control.md](evals/adaptive-user-control.md). It combines the historical failure with
greenfield on another platform, an existing feature, a skill upgrade/refresh, debugging, and a
local tweak to prevent both autonomy and overfitting to one prompt or stack.

## Final instruction

Classify effect, intent, risk, uncertainty, and surfaces. Present the Proposal analysis and the
recommended route; on a mutating task, only invoke the head skill after explicit ratification.
Greenfield always discovers, specifies, stress-tests, and plans before implementing, with
`pelizzai-interview` in discovery and in both stress passes. A material gap that appears later —
including mid-execution — stops the work and goes back to the user through the same skill. Select
reasoning/test/review proportionally, without turning process intelligence into authority over the
product.
