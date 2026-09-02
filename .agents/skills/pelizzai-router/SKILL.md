---
name: pelizzai-router
description: "Use for any request that inspects or changes a project. Looks up the head skill from the request, presents the route at the kickoff gate, and invokes the head skill only after the user ratifies."
---

# PelizzAI Router

<SUBAGENT-STOP>
If you received a closed subtask, do not route again. Follow the briefing and escalate if context is missing.
</SUBAGENT-STOP>

## Purpose

Produce the smallest route that solves the task safely, as a **lookup**, not a deliberation: read the
request, find its row, recommend the route, wait for the user, invoke one head skill. The router
decides the **lifecycle**; the head skill decides the heuristics within it.

**Announce**, in the conversation's language: that you are using the PelizzAI Router skill to classify the task and propose the route.

## 1. Effect

| Effect | The request… | Rule |
| --- | --- | --- |
| `read-only` | explains, analyzes, maps, reviews, or diagnoses without changing state | May inspect; never creates or edits state, catalog, profile, branches, or files. |
| `write-local` | changes code, files, configuration, or a versionable artifact | `pelizzai-isolate` before the first persistent write — state, spec, plan, or code. |
| `external` | pushes, opens a PR, deploys, messages, spends, grants, deletes, touches production | Authority, target, reversibility, and confirmation at the action's own gate. |

A task may start read-only and turn write-local when the user asks for the fix: reclassify **before**
the first mutation. Effect, not size, decides whether the kickoff gate stops.

## 2. Head skill (one row per request)

| The request says… | Track | Head skill | What follows the head skill |
| --- | --- | --- | --- |
| broken, error, failure, "it doesn't work", "stop guessing" | `bug` | `pelizzai-diagnose` | compact confirm → oracle → fix → `pelizzai-verify` → `pelizzai-finish` |
| a local change with no new rule, contract, or surface (text, label, color, a field on an existing screen, an obvious config, a behavior-preserving local refactor) | `tweak` | `pelizzai-quick-fix` | compact confirm → change + proof → `pelizzai-verify` → `pelizzai-finish` |
| "can we…", "is it viable…", answered cheaper by a throwaway probe than by debate | `spike` | `pelizzai-experiment` | probe → verdict → the real work re-enters here |
| review of a diff, working tree, branch, or PR | `review` | `pelizzai-review` | verdict; no state |
| codebase-wide review of architecture, debt, or seams | `review` | `pelizzai-architecture` | findings; no state |
| a Git conflict in progress | — | `pelizzai-merge-recovery` | resolution → the interrupted flow resumes |
| the record and Git disagree | — | `pelizzai-resume` | reconciliation → the interrupted flow resumes |
| a new product, system, service, or MVP — **even with the stack chosen** | `exploratory` | `pelizzai-discovery` | interview → spec → stress → approval → plan → stress → approval → setup → `pelizzai-execute` |
| a feature/refactor/infra whose design is approved and whose plan exists | plan's lane | `pelizzai-execute` | post-plan setup gate → tasks → final validation → `pelizzai-finish` |
| a feature/refactor/infra whose design is approved but has no plan | see lanes | `pelizzai-plan` | plan → stress when the lane asks → setup → `pelizzai-execute` |
| stress an existing design or plan; "interview me"; a flagged material gap | — | `pelizzai-interview` | one decision per turn → back to the phase that raised it |
| "bootstrap", "reinitialize", or an accepted bootstrap proposal | — | `pelizzai-onboard` | catalog + profile + domain skills → the original request |

When two rows fit, ask **one** question in plain language. Lines and files are signals of growth, never
the criterion: a public surface, a new rule, or an open design decision is what promotes a tweak.

### Lanes for feature, refactor, and infra

| Lane | Predicate | Depth |
| --- | --- | --- |
| `bounded` | one cohesive behavior, clear acceptance, low risk, no architectural decision | `pelizzai-plan` in compact mode; no discovery forced |
| `standard` | medium risk or a few parts/contracts, solution and acceptance clear | `pelizzai-plan`; a compact discovery only if a real trade-off remains |
| `exploratory` | high uncertainty, or high risk that demands design mitigation; architecture or coupled decisions | full `pelizzai-discovery` + proportional stress → plan |

Greenfield is always `exploratory`: the stack removes technical uncertainty and decides nothing about
users, flows, states, policies, UX, data, or acceptance. Each artifact of that chain is skipped only by
the user's explicit waiver, recorded in the plan header.

### Before the row: bootstrap, state, source mode

- **Consumer without `pelizzai/domain-skills.md`** (first interaction, or the user typed `bootstrap`):
  propose the bootstrap through `pelizzai-onboard` as the first thing in the turn, even in `read-only`,
  and wait. "No" or "later" returns the request to its row without creating anything; "yes" makes the
  effect `write-local`. A purely conceptual question never triggers it. The modes and the
  situation table live in `pelizzai-onboard` §Choosing the mode.
- **`pelizzai/data/state.md` exists**: read it without writing. `slug: <none>` or `phase: done` → no
  active task. `phase: blocked` → present the blocker first. `phase: delivered` → reconcile the previous
  delivery (`pelizzai-execute` §State and resumption) before classifying. An active task that matches the
  request → validate against Git and resume without re-asking ratified decisions; one that does not →
  report the conflict and decide with the user. A divergence that risks work → `pelizzai-resume`.
- **Source repo** (sentinel `scripts/pelizzai-source-repo.txt`, the sole criterion): no consumer runtime,
  no `pelizzai/` files, no bootstrap; the cursor is the platform's native execution record.

## 3. Overlays by signal

| Signal in the request or the diff | Overlay |
| --- | --- |
| screen, component, CSS, layout, UX, accessibility | `pelizzai-interface`, from design through visual QA |
| auth, external input, SQL, upload, secret, CORS, SSRF, dependency | `pelizzai-security` before final validation |
| project-specific patterns | domain skills from `pelizzai/domain-skills.md` (source repo: its own rules) |
| human documentation in scope | `pelizzai-docs` before final validation |

`pelizzai-preferences` is the behavior floor of every non-trivial task, not an overlay to choose.
Overlays propagate to the plan, the task brief, the review, and Verification.

## 4. Proposal analysis (mutating, non-trivial)

Before the kickoff gate, when a mutating request still has an open scope, UX, architecture, security,
or data reading, run [references/proposal-stress.md](references/proposal-stress.md): ≤6 bullets of
material assumptions, gaps, risks, and alternatives. It feeds the **Discovery** line of the gate; each
gap that belongs to the user is later closed by `pelizzai-interview`, one question at a time. In
`read-only` and in a tweak or bug with a stated contract it collapses to nothing; in `bounded` to one
line ("no material gaps; stated contract: …"); in greenfield it never collapses. Under a closed briefing
(SUBAGENT-STOP / TEAM-MEMBER-STOP), skip it and escalate open decisions to the coordinator.

## 5. Kickoff gate

Every mutating route that will produce a plan, a spec, or a probe stops here — `bounded` included.
Two routes do not: a **tweak** or a **bug** whose goal and acceptance the user already stated hands
off directly, and the head skill's one-line compact confirm (branch, base, isolation, mode, commits,
all named, one "ok") **is** the kickoff of that track — one stop before the first write, never two. A
tweak or bug whose contract is still open, or that the proposal analysis promotes, stops here like
the others. `read-only` review, analysis, or explanation informs the route and proceeds. The router
is the sole issuer of this block; the head skill is the sole issuer of the compact confirm.

```text
**Kickoff gate — proposed route:**
- Understanding: <X> as a <feature|tweak|bug|refactor|spike>
- Lane: <bounded|standard|exploratory|—> — <one-line justification>
- Head + overlays: <head skill> + <overlays or "none">
- Discovery: <"no material gaps" | numbered gaps → compact | full pelizzai-discovery | focused pelizzai-interview>
- Artifacts: <spec/plan/ADR expected | "none beyond the native plan">; greenfield with a missing catalog or a new stack also lists "stack domain skills (proposed at the design edge)"

Recommendation: accept this route because <reason>.
Single question: May I proceed with this route? (yes or adjust)
```

With a native option-selection tool, deliver the single question through it: the block as context,
**accept** first and marked as recommended, **adjust** as the alternative. Both forms speak the
conversation's language. **Silence is not a yes**: without the affirmative answer, hold the turn — no
branch, no file, no head skill. The user may adjust lane, discovery, artifacts, or overlays; a
claimed prior approval that the transcript cannot show re-opens this gate rather than skipping it.
When the user seems non-technical or the intent admits two material readings, the first line
re-presents the understanding in plain words and `audience: layperson` is recorded.

Setup stays out of this block. Compute the recommendation silently — `isolation: branch`,
`execution-mode: inline`, `commit-strategy: granular` for tweak, bug, and `bounded`; a worktree and
subagents/team only for truly independent fronts, `squash-final` only when the intermediate history has
no value; a value ratified in `pelizzai/profile.md` §Ratified execution defaults replaces the default —
and hand it over: the tweak/bug head skill emits the **one-line compact confirm**; tracks with a plan
ratify at the **post-plan setup gate** of `pelizzai-execute`, where `team` is always visible. The router
never applies `worktree` or `squash-final` on its own and never repeats the question.

## 6. Hand off

After the "yes" — immediately, for a tweak or bug with a stated contract — **Call the Skill tool with
the head skill's name** — exactly one — and pass what you understood: the row, lane, effect, overlays,
audience, the state read, and the recommended setup. Announcing the head skill in prose and working on
is the measured failure; the hop is an invocation. In a
consumer, record `slug`, `track`, `lane`, `effect`, `overlays`, `audience` in `pelizzai/data/state.md`
and leave `kickoff: pending`: the `kickoff: ratified <YYYY-MM-DD>` marker belongs to the head skill's
compact confirm or to the post-plan gate, before the first product write (the writegate's Rule B reads
it). A new task never inherits `lane`, `kickoff`, `audience`, base, branch, or strategy from the
previous one; the profile's ratified policy is a pre-selected recommendation, not inheritance.

For a mutating task in Git, observe reality before proposing: `git status --short --branch`,
`git log --oneline <base>..HEAD`, and `git fetch` + `HEAD..origin/<base>` when a remote exists. Re-read
only the relevant delta; do not fetch in a read-only analysis without need.

A material gap that appears **after** kickoff — in spec, plan, implementation, debugging, review, or
closeout — stops the work and returns to the user through `pelizzai-interview` (`CLAUDE.md` §The LLM
never decides alone). The router does not re-run; the head skill raises it.

## Red flags

```text
- Narrating the route and jumping to the head skill: the hop is a Skill invocation, not a sentence.
- Writing state, spec, plan, or code before pelizzai-isolate.
- A mutating bootstrap, or a missing catalog met with silence, instead of a proposal and a "yes".
- Forcing discovery on a bounded feature — or calling a greenfield bounded because the stack was named.
- Promoting a tweak to a plan because the acceptance is clear (a spec to rename a button is the historical failure).
- Applying worktree, squash-final, or a mode without ratification; scattering the setup across micro-questions.
- Filling a scope/UX/architecture/data gap with Context7, convention, or a "safe default" as the user's vote.
- Several head skills at once; a second route inside a closed briefing.
```

## Regression evaluation

When changing routing, discovery, or authority rules, run [evals/adaptive-user-control.md](evals/adaptive-user-control.md)
and the trigger battery (`tests/trigger`, `--runs 5`, compared A/B against the previous checkout).

## Final instruction

Classify the effect, find the row, derive lane and overlays, run the proposal analysis when a material
reading is open, and **Call the Skill tool with the head skill's name**: right away for a tweak or bug
with a stated contract (its compact confirm is the stop), only after an explicit "yes" at the kickoff
gate for every other mutating route. Greenfield always discovers, specifies, stress-tests, and plans
before implementing. The route is the harness's recommendation; the decision is the user's.
