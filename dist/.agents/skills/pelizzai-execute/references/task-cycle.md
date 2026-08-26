# Per-task cycle — detailed protocol

The protocol each task follows during the execution of a plan, valid in all three modes (team,
subagents, inline). The proof and the shape of the review vary by artifact and risk; the scope,
quality, and evidence gates remain observable.

1. [Autonomy between tasks and the material-gap stop](#0-autonomy-between-tasks-and-the-material-gap-stop)
2. [Self-sufficient briefing](#1-self-sufficient-briefing-by-file-when-the-scripts-exist-by-pasting-otherwise)
3. [Choosing the strategy by artifact](#2-choosing-the-strategy-by-artifact) — including test scope
4. [Task review: one independent reviewer, both verdicts](#3-task-review-one-independent-reviewer-both-verdicts)
5. [Member status](#4-member-status)
6. [Review-loop circuit breaker](#5-review-loop-circuit-breaker) — five rounds, then adjudication
7. [Commit as a gate](#6-commit-as-a-gate)
8. [Advancing the cursor](#7-advancing-the-cursor)
9. [Model selection per role](#8-model-selection-per-role) — tier by role, ratified
10. [Phase timing](#9-phase-timing-lightweight-instrumentation)

## 0. Autonomy between tasks and the material-gap stop

The coordinator runs the cycle below end to end **without asking leave at every step**: inside a
ratified plan, a mechanical, verifiable step gets executed — no asking "continue?" at the end of
each task, no permission requests for reversible local commands. The autonomy is one of
**execution**; the decision still belongs to the human.

Outside `BLOCKED` and the circuit breaker (§5), the only thing that interrupts a workstream
mid-flight is a **material gap**: a requirement, scope, UX, architecture, data, security, cost,
accepted risk, or acceptance criterion the spec and the plan did not decide. It has a fixed path;
it is not a vague pause:

```text
1. The member STOPS their task and NAMES the gap: what is undecided, what it changes in the
   delivery, and the 2–3 options they see, with the recommended one. They return NEEDS_CONTEXT.
   They never fill it by convention, default, Context7, or "reasonable inference", and never talk
   to the user directly.
2. The coordinator does NOT decide in their place nor on their own. They check whether the answer
   is already in the plan/spec: if it is, it was missing context — provide it and re-dispatch. If
   not, it is a material gap.
3. The coordinator CONSOLIDATES the open material gaps — consolidating means grouping and ordering by
   dependency, NEVER deciding — and takes them to the human via `pelizzai-interview` in gap
   mode: one question at a time, with real options and the recommended one (one-line why).
4. The ratified decision is recorded in the plan (`## Technical decisions in this plan`, origin:
   execution interview; the gap leaves `## Exposed material gaps` as resolved) and the workstream
   resumes where it stopped, with the briefing updated.
```

**A DOMAIN SKILL gap is a different thing and follows a different path:** the member flags it
(`DONE_WITH_CONCERNS`), execution does **not** stop, and the coordinator accumulates the gaps for a
single proposal at closeout (§4). One is a user decision and stops the workstream; the other is
catalog maintenance and never becomes a per-task gate.

## 1. Self-sufficient briefing (by file when the scripts exist; by pasting otherwise)

The member (teammate/subagent) **never reads the plan file** — this avoids context pollution and keeps the focus. The coordinator is who delivers the context, through one of these two channels:

- **By FILE (preferred, when the script exists **and** a compatible persistent Markdown plan exists):** run `task-brief <plan> <N>` — it extracts Task N + the Global Constraints into the safe handoff dir (gitignored in the consumer; temp in source mode), and the briefing points to THAT file. The report goes to the same directory and the chat reply stays at **≤15 lines**. For review, `review-package --working-tree` includes staged, unstaged, and untracked. The same package serves combined/split. The `<base-sha> <HEAD>` range is final-only. The principle "context is built, never inherited" holds.
- **By pasting (fallback, no script or no persistent plan):** the coordinator extracts the **full text** of the task from the native plan/execution record and pastes it into the member's prompt. Do not create a consumer file just to satisfy the helper.

Each task's briefing includes:

```text
- Full text of the task (from the file brief, or pasted from the plan, with exact values to use
  verbatim) — including the Global Constraints from the plan header.
- Applicable domain skills from the catalog (pasted, or their key points) — the member does not
  inherit your context. In doubt whether a catalog domain skill applies to the task, include it:
  the cost of including is lower than the cost of ignoring a project rule. If the task's surface
  touches a stack with NO domain skill covering it, the member applies what they have and FLAGS
  the gap in the return (`DONE_WITH_CONCERNS`); they never create a skill mid-task.
- Cross-cutting skills in `overlays:` in the state (frontend, security, documentation, etc.), with
  the gates each one requires. Propagate them to the implementer **and reviewers**; naming them is
  not enough.
- The necessary conventions and contracts (paths, interfaces, decisions already made).
- The **Active rules** of `pelizzai/data/learnings.md`, PASTED (the short section; never the
  Incident log). They are what this project already paid to learn, and the member has no other way
  to reach them — a rule the coordinator read but did not paste never reaches the code. Empty
  section, or source mode: say so explicitly, so nobody assumes coverage that is not there.
- Global layer: apply `pelizzai-preferences` (language, secrets, .env, production quality) and
  reason deliberately; on conflict, the DOMAIN SKILLS pasted into this briefing and
  the project rules PREVAIL over preferences/reasoning.
- Test/validation strategy chosen by the matrix in §2, WITH THE COMMAND SCOPED to the paths this
  task touches, and the explicit line that the full suite is not this task's job. For external APIs, ground it in Context7
  for the observed version; current official documentation is the fallback, never memory.
- Reasoning: when the task involves uncertainty, a decision, or a diagnosis, the suggested
  dominant technique (decomposition, RCA, comparison, verification —
  see the skill's matrix); omit it for a mechanical task with a clear contract — do not impose a
  technique without a trigger.
- The task review shape: ONE independent dispatch with both verdicts (§3); the truly blind spec
  lens runs on the final range, not per task.
- The expected return format and status (see below), including the mandatory field
  `Deviations from plan:` (or `none`).
- Operational deviation test (canonical phrase, in the briefing TEXT):
  "if the decision is not written in the plan or the spec, it is not approved — present it before implementing".
  A technical, scope, or approach decision that emerges during implementation and is not in the
  plan/spec interrupts the task: the member NAMES the gap and returns `NEEDS_CONTEXT` **with 2–3
  options and the recommended one** (one-line why); it is never filled in silently nor returned
  as an open question without options. The coordinator is who takes the gap to the human, via
  `pelizzai-interview` in gap mode (§0) — the member does not talk to the user.
- Escalation safe-conduct (canonical phrase, in the briefing TEXT): "It is always OK to stop and
  say 'this is too hard for me'. Bad work is worse than no work. You will not be penalized for
  escalating (report BLOCKED)."
```

Answer the member's questions **before** the work starts; re-dispatch if context is missing.

## 2. Choosing the strategy by artifact

Do not force TDD where no observable executable behavior exists. The briefing declares **one
primary strategy** and the expected evidence; mixed tasks may combine lines:

| Artifact / intent | Primary strategy | Minimum evidence |
| --- | --- | --- |
| New executable behavior or reproducible bug | **TDD** (`pelizzai-tdd`) | observed RED → GREEN → refactor; behavior test |
| Refactor or legacy without a safe contract | **Characterization** | current behavior captured and green before the change; regression after |
| Config, schema, migration, script, build, or integration | **Validate** | parser/dry-run/fixture/real integration and rollback when applicable |
| UI, layout, responsive states, or visual interaction | **Visual + functional** | functional test when useful + the app running, screenshots/viewport/states via `pelizzai-interface` |
| Docs, Markdown, prompts, policies, or static artifact | **Static/scenario** | lint/render/link/schema/grep or a consumption scenario; never a fictitious test just to say "TDD" |

TDD is the primary strategy when the skill's suitability gate passes; being able to write just any
test is not enough. For deletions and purely mechanical changes, use the regression suite +
proportional static checks. The member tests/validates, self-reviews, and **does not commit**.

### Scope during a task, whole suite at the end

A task proves the files it touched. Scoping is not proving less — the evidence the row above demands
is unchanged; what changes is that a member neither pays for nor gets blocked by a red in a module
it never opened. The briefing must say so, because "run the tests" resolves to the whole suite by
default in most repositories:

```text
Tests to run: <the command scoped to the touched paths>
Full suite: NOT in this task — the coordinator runs it at the end.
```

**The full suite runs once, before the final review**, and is neither optional nor delegable: it is
the only run positioned to catch an interaction the per-task scopes could not see, and nobody
holding one task's context reads a cross-task regression correctly. Two exceptions, named in the
briefing when they apply: a task whose subject is itself cross-cutting (shared type, global config,
migration) has no touched-files scope and runs the suite; and a module already red is declared as
such, or the member reports someone else's failure as its own.

A red in the final run is not the last member's fault by default — find which task introduced it
(`git bisect` over the task commits) before dispatching a fix.

## 3. Task review: one independent reviewer, both verdicts

Every task passes through the **spec** and **quality/evidence** rubrics, in this order, applied by
**ONE independent reviewer in ONE dispatch** — in any lane, including bounded. There is no profile
to pick and no downgrade to ratify. The reviewer's independence comes from **fabricated context**:
it receives the task contract, the diff, the domain skills, and the author's report — never the
session history. The briefing (`pelizzai-review` → `references/task-reviewer.md`) places the spec
rubric BEFORE the report and instructs the reviewer to form the spec verdict reading code against
contract first. The truly BLIND spec lens belongs to the FINAL range, in its own dispatch — that
is where a requirement that fell between tasks becomes visible (issue #49 holds the cost analysis
that moved it there).

Proportionality: what varies with risk is the **depth** of each rubric — how much gets
investigated and how many checks get run — never the existence of the review or who reviews
(always an independent reviewer, never the coordinator grading its own delivery).

```text
(0) Material: generate `review-package --working-tree`; the same package covers staged, unstaged,
    and untracked. Do not use a range before the task is committed.
(1) ONE dispatch, TWO verdicts, in order:
    (a) Spec rubric — formed BEFORE the report section: the reviewer compares the real
        implementation vs the requirements LINE BY LINE, hunting for omissions, extras (scope
        beyond what was asked), and misunderstandings, with the area's domain skills as part of
        the contract.
    (b) Quality / evidence rubric — receives the author's report and VERIFIES the claims — tests
        run? FRESH proof? deviations declared? — on top of readability, design, reuse, and
        security. It does not blindly trust the report: the reviewer actually ran the checks
        applicable to the artifact and pasted output + exit code. An inferred "tests pass" does
        NOT count as approved; a check that did not run = UNVERIFIED, never ✅.
```

The reviewer runs a test only when reading raises a specific doubt no existing run answers — and
then a focused test, never the whole suite (§2 owns the suite's single position in the cycle).
Warnings or other noise in the reported test output are findings — test output should be pristine.

Approval requires **both** verdicts: spec ✅ **and** quality ✅ — a report missing either verdict
is incomplete, never approved. Conflict between the verdicts (or with the coordinator's own
knowledge) → the coordinator decides with their OWN evidence or escalates; the author's narrative
never arbitrates. "⚠️ not verifiable" items require the coordinator's assessment against the plan
before marking them complete.

Pipeline anti-corruption (full rules in `pelizzai-review`): do not instruct the reviewer on what NOT to flag nor pre-classify severity; a finding caused by the plan itself goes up to the human; Minors accumulate in a ledger triaged at the final review; the final review's findings are fixed by ONE single fixer.

## 4. Member status

The member reports one of these statuses:

| Status               | Meaning                                         | Coordinator's conduct                                          |
| -------------------- | ----------------------------------------------- | -------------------------------------------------------------- |
| `DONE`               | Work complete                                   | Proceed to the review                                          |
| `DONE_WITH_CONCERNS` | Complete, but with caveats                      | Read the caveats before proceeding; a domain skill gap goes to the record and is accumulated for the adoption-driven axis at closeout (it does not become a per-task gate) |
| `NEEDS_CONTEXT`      | Missing information **or** a named material gap | Context you have (it is in the plan/spec): provide it and re-dispatch. Material gap (user decision): consolidate it and take it to the human via `pelizzai-interview` before the workstream continues — consolidating is not deciding (§0) |
| `BLOCKED`            | Cannot finish                                   | Assess: give context → change the approach/split the task → escalate to the human (the model is already the top — see §8) |

Every task report — in any status — includes the mandatory field **`Deviations from plan:`**
(or `none`): technical, scope, or approach decisions that departed from what the plan/spec wrote,
with the rationale for each one. The coordinator **checks that field before accepting `DONE`**: an
unratified material deviation does not become complete — by the operational deviation test, it goes
back to the user via `pelizzai-interview` (gap mode, §0) before the review, is never absorbed
silently, and is never ratified by the coordinator themselves.

Never ignore an escalation nor re-dispatch without changing anything.

## 5. Review-loop circuit breaker

Five rounds in three regimes. The regime matters more than the count: a loop that only counts higher
never changes what it is doing.

```text
Rounds 1-3  SAME implementer, same approach. Ordinary correction, nothing escalates.
Round 4     FRESH implementer, approach MUST change — dispatched WITHOUT the loop's history,
            which after three rejections is arguing with itself. State what was tried and
            rejected. Recommend a more capable model here and wait: per §8 the bill is the
            user's. A "no" costs nothing; round 4 runs either way.
Round 5     Last attempt, with whatever was ratified.
At the cap  The BREAKER adjudicates — the human is not the next step.
```

**The breaker** judges the disagreement instead of continuing it, because after five rounds the
likeliest reading is that both sides are right about different things. It receives the task, the
diff, and each rejection in order — **never** the loop's conversation — and returns one of:

```text
IMPLEMENTER_RIGHT  the rejection does not hold. Accept the work; record the concern as an
                   observation. A reviewer is a subagent and can be wrong.
REVIEWER_RIGHT     the defect is real. Name it in ONE sentence the implementer can act on; if
                   that sentence cannot be written, this is not the verdict.
BOTH_PARTIAL       they answer different questions. Name both, and which one the task is for.
UNDERSPECIFIED     neither can be right: the plan/spec does not decide it. Ends the loop and goes
                   to the human — and reaching it early is a win, not a failure.
```

A verdict is not an approval to ship: `IMPLEMENTER_RIGHT` returns to normal close-out, everything
else buys one bounded fix or escalates.

```text
- Limit: 5 fix→re-review rounds PER TASK — the task review is one dispatch, so the two verdicts
  share a single counter. The re-review is SCOPED to the fix's diff plus each rejection's
  subject; it is not a fresh hunt over the whole task.
- The same issue rejected 2x → do not spend rounds 2 and 3 repeating it: jump to the round-4
  regime (fresh implementer, changed approach) on the 2nd.
- Structural rejection ("the approach is fundamentally wrong") → straight to the breaker; rounds
  do not fix a wrong approach.
- Resets (do not give up too early): zero the counter on full approval (both verdicts ✅) and
  when starting a new task — a loop in Task N does not affect N+1.
- Does NOT count as a cycle (avoids false positives): BLOCKED (it is already an escalation, never
  a tally); DONE_WITH_CONCERNS whose caveats are observations and the review passes; an
  implementer who CONTESTS the rejection ("the reviewer says X is missing, but it is on line Y")
  → treat it as NEEDS_CONTEXT and reconfirm with the reviewer (reviewers are subagents and make
  mistakes).
- On reaching the cap: dispatch the BREAKER first — the human is not the next step, the
  adjudication is. `IMPLEMENTER_RIGHT` closes the task normally. `REVIEWER_RIGHT` or
  `BOTH_PARTIAL` buys ONE bounded fix against the named sentence, and that fix does not reopen
  the counter: if it fails, escalate.
- On escalating (the breaker returned `UNDERSPECIFIED`, or the bounded fix failed): stop
  dispatching; write `phase: blocked` in the consumer state or native
  execution record. In the consumer, log the blockage in `## Progress` → `pending` (task, stage,
  number of failed rounds, the distinct rejection reasons
  IN ORDER, the fixes attempted, the pattern — independent issues / same recurring issue /
  structural conflict — and the breaker's verdict); commit ONLY the cursor in the consumer (source mode creates no cursor commit); escalate to the
  human with an ACTIONABLE message (what was done + each reason + fixes + pattern + verdict + options:
  clarify the spec via pelizzai-plan / split the task / revise the plan);
  leave the working tree INTACT (never git reset --hard). If the human says to continue,
  re-dispatch reusing the WIP — do not restart from scratch.
```

## 6. Commit as a gate

```text
- The member does NOT commit. The work stays in the working tree until BOTH lenses pass.
- Only after spec ✅ and quality ✅ (with fixes applied) does the COORDINATOR consolidate.
- The coordinator stages the task's exact paths and, in the consumer, the state; inspects
  `git diff --cached` and never uses `git add -A`.
- To allow safe reuse of the review in a single-task bounded delivery, require that no
  unstaged/untracked content of the task remains, capture `reviewed-tree = git write-tree` before
  the commit, and compare it afterward with `git rev-parse HEAD^{tree}`. Divergence invalidates
  the reuse.
- Granular: one DEFINITIVE commit per task. In the consumer, the cursor touch goes into the SAME
  commit; in source mode, the native execution record advances with no file. History is kept.
- Squash-final: one WORK commit per task (`wip(<slug>): <task>`) — never accumulate the entire
  working tree without a commit until the end (a crash would lose everything). After the tasks and
  overlays, `pelizzai-execute` consolidates the WIPs into a single commit **before** the
  final review and `validated-head`. `pelizzai-finish` does not rewrite history. In the
  consumer the cursor goes into the WIP; in source mode there is no cursor commit.
```

## 7. Advancing the cursor

In the consumer, before the task's commit update `pelizzai/data/state.md` (in `## Progress`, append
**one line** `T<n> ✅ <sha|date> — <note ≤1 line>` — a long report goes to
`pelizzai/data/reports/` with only the link —, adjust `next` and `pending`, keep `phase: exec`) and
include it in the stage along with the task's exact paths. The definitive commit (granular) or wip
(squash-final) carries the cursor — including Task 1, which carries the state written at setup:
**there is no metadata-only commit to start the task**. On concluding the plan and sealing the
content, `pelizzai-finish` seals `phase: delivered` in the single metadata-only closure
commit, migrating the task's intact block to `data/history/` — the cursor returns to template size
and `done` is observed afterward.

In source mode, advance the native execution record after the commit and do not create
state/closure.

## 8. Model selection per role

Harness policy — **tier by role, ratified at the setup gate, never switched silently**:

```text
Session tier (the model the user chose):  spec, plan, ORCHESTRATION (the coordinator),
                                          every review, the breaker, final validation.
Ratified executor tier:                   implementation members run the tier the user chose at
                                          setup-gate step 4 — the session's tier, or a mid tier
                                          when the tasks are mechanical against a ratified plan.
```

The asymmetry has evidence behind it: plans and reviews concentrate the judgment, and a weaker
**orchestrator** — not just a weaker reviewer — is what ships planted defects. That is why the
coordinator never runs below the session's tier, whatever the executors run. Specify model and
effort explicitly when dispatching members and reviewers, so nobody inherits a default smaller
than intended.

The harness elevates the reasoning of **any** model: the right technique, a verifiable protocol,
and fresh evidence do not depend on the model's capability. Proportionality still applies to the
depth of the process (interview, brainstorming, TDD, overlays) — and it is **never lowered to
compensate for a smaller model**: a mid-tier executor demands an intact process, not a shallower
one, and the session-tier review is exactly the net under it.

Escalating capability is always **recommend and ratify** — the bill is the user's, never an
automatic swap. The two places it happens: round 4 of the fix loop (§5), and a BLOCKED whose
context, tooling, and decomposition were already fixed. The coordinator records concerns, does
not feign certainty.

## 9. Phase timing (lightweight instrumentation)

Stamp wall-clock timings as the cycle advances, so slowness is measurable instead of anecdotal:
per task, note the elapsed time of the implementation, of the review, and of the fix rounds,
appended to the SAME progress line the cursor already writes (`## Progress` in the consumer state;
the native execution record in source mode) — e.g.
`T3 ✅ <sha> — <note> [timing: impl 14m · review 9m · fix-rounds 1 (7m)]` — the task review is one
dispatch, so it is one duration (the final range, with its own dispatches, may log
`final-review spec 6m · quality 9m`). It is a suffix of the existing line, not a second one — the
one-line-per-task Progress hygiene still holds. No new file and no commit of its own: the timing
travels with the record that already exists, under the same rules. The final report aggregates the
totals per phase — that aggregate is what proves, or refutes, where the delivery's time went.
