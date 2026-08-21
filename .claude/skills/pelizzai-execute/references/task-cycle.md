# Per-task cycle — detailed protocol

The protocol each task follows during the execution of a plan, valid in all three modes (team,
subagents, inline). The proof and the shape of the review vary by artifact and risk; the scope,
quality, and evidence gates remain observable.

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

- **By FILE (preferred, when the script exists **and** a compatible persistent Markdown plan exists):** run `task-brief <plan> <N>` — it extracts Task N + the Global Constraints into the safe handoff dir (gitignored in the consumer; temp in source mode), and the briefing points to THAT file. The report goes to the same directory and the chat reply stays at **≤15 lines**. For review, `review-package --working-tree` includes staged, unstaged, and untracked. The same package serves both lenses. The `<base-sha> <HEAD>` range is final-only. The principle "context is built, never inherited" holds.
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
- The **Active rules** of `pelizzai/data/learnings.md`, pasted (the short section; never the
  Incident log). They are what this project already paid to learn, and the member has no other way
  to reach them — a rule the coordinator read but did not paste never reaches the code. Empty
  section, or source mode: say so explicitly, so nobody assumes coverage that is not there.
- Cross-cutting skills in `overlays:` in the state (frontend, security, documentation, etc.), with
  the gates each one requires. Propagate them to the implementer **and reviewers**; naming them is
  not enough.
- The necessary conventions and contracts (paths, interfaces, decisions already made).
- Global layer: apply `pelizzai-preferences` (language, secrets, .env, production quality) and
  reason via `pelizzai-reasoning`; on conflict, the DOMAIN SKILLS pasted into this briefing and
  the project rules PREVAIL over preferences/reasoning.
- Test/validation strategy chosen by the matrix in §2. For external APIs, ground it in Context7
  for the observed version; current official documentation is the fallback, never memory.
- Reasoning: when the task involves uncertainty, a decision, or a diagnosis, the suggested
  dominant technique from `pelizzai-reasoning` (decomposition, RCA, comparison, verification —
  see the skill's matrix); omit it for a mechanical task with a clear contract — do not impose a
  technique without a trigger.
- The risk rationale that sets the DEPTH of each review lens (the two lenses and their two
  dispatches are invariable — there is nothing to record about them).
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
| UI, layout, responsive states, or visual interaction | **Visual + functional** | functional test when useful + the app running, screenshots/viewport/states via `pelizzai-frontend` |
| Docs, Markdown, prompts, policies, or static artifact | **Static/scenario** | lint/render/link/schema/grep or a consumption scenario; never a fictitious test just to say "TDD" |

TDD is the primary strategy when the skill's suitability gate passes; being able to write just any
test is not enough. For deletions and purely mechanical changes, use the regression suite +
proportional static checks. The member tests/validates, self-reviews, and **does not commit**.

## 3. Two-lens review, always in two dispatches

Every task passes through the **spec** and **quality** lenses, in this order, with **asymmetric
blindness**: the spec lens judges the code blind against the contract; the quality lens is the
**evidence** lens and receives the author's report in order to verify it. They always use **two
independent dispatches**, in any lane, including bounded — the spec stage approves before quality
is dispatched. There is no profile to pick and no downgrade to ratify: a single pass would collapse
the blindness into mere reading order, since a reviewer who has already read the report cannot
unknow the author's narrative.

Proportionality: what varies with risk is the **depth** of each lens — how much gets investigated
and how many checks get run — never the existence of the review, the number of dispatches, or the
blindness. Cutting a dispatch is not proportionality, it is removing the only mechanism that makes
the spec lens independent.

```text
(0) Material: generate `review-package --working-tree`; the same package covers staged, unstaged,
    and untracked. Do not use a range before the task is committed.
(a) Spec lens (BLIND): receives ONLY the diff + the task's spec/plan + the area's domain skills.
    The spec-lens reviewer does NOT receive the implementer's report — they judge the code against the contract, without the author's narrative.
    It is ADVERSARIAL by instruction: it compares the real implementation vs the requirements LINE BY LINE,
    hunting for omissions, extras (scope beyond what was asked), and misunderstandings.
(b) Quality / evidence lens: receives the author's report and VERIFIES the claims — tests run?
    FRESH proof? deviations declared? — on top of readability, design, reuse, and security.
    It does not blindly trust the report: the reviewer actually ran the checks applicable to the
    artifact and pasted output + exit code. An inferred "tests pass" does NOT count as approved; a
    check that did not run = UNVERIFIED, never ✅.
```

Approval requires **both** verdicts: spec ✅ **and** quality ✅, in this order and in separate
stages — quality is not dispatched while spec is open. Conflict between the lenses → the coordinator decides with their OWN evidence or
escalates; the author's narrative never arbitrates. "⚠️ not verifiable" items require the
coordinator's assessment against the plan before marking them complete.

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

```text
- Limit: 3 fix→re-review cycles PER TASK — one budget shared by both lenses, whichever one
  rejects. Separate per-lens counters doubled the worst case to 6 rounds per task without buying
  anything the shared budget lacks: a task that burned 3 rounds is escalation material regardless
  of which lens spent them.
- A fix round is one fix dispatch plus one SCOPED re-review: the re-review verdicts the previous
  findings (ADDRESSED / NOT_ADDRESSED) and flags only NEW breakage inside the fix's diff window —
  it does not re-run the full rubric over the whole task.
- Fixes go back to the implementer. When the platform can RESUME the original implementer
  (teammate still alive, resumable subagent), prefer resuming it with the findings verbatim — its
  context is intact and cheaper than a cold re-dispatch; a fresh implementer is for when the
  original is gone or the rejection is structural.
- Escalation by failure, not by default: after a rejection, raise the reasoning effort of the NEXT
  fix and re-review dispatches, up to the platform's highest (§8) — a rejected round is what buys
  more capability; a first pass is not. A LARGER MODEL remains a ratifiable recommendation, never
  an automatic swap (§8).
- The same issue rejected 2x → escalate on the 2nd.
- Structural rejection ("the approach is fundamentally wrong") → escalate immediately.
- Reset (do not give up too early): zero the budget when starting a new task — a loop in Task N
  does not affect N+1. Passing one lens does not refund rounds already spent.
- Does NOT count as a cycle (avoids false positives): BLOCKED (it is already an escalation, never
  a tally); DONE_WITH_CONCERNS whose caveats are observations and the review passes; an
  implementer who CONTESTS the rejection ("the reviewer says X is missing, but it is on line Y")
  → treat it as NEEDS_CONTEXT and reconfirm with the reviewer (reviewers are subagents and make
  mistakes).
- On blowing the limit: stop dispatching; write `phase: blocked` in the consumer state or native
  execution record. In the consumer, log the blockage in `## Progress` → `pending` (task, stage,
  number of failed cycles, the distinct rejection reasons
  IN ORDER, the fixes attempted, and the pattern: independent issues / same recurring issue /
  structural conflict); the cursor write is local — no commit in either mode (the per-dev cursor
  is ignored by git, issue #43); escalate to the
  human with an ACTIONABLE message (what was done + each reason + fixes + pattern + options:
  clarify the spec via pelizzai-writing-plans / split the task / revise the plan);
  leave the working tree INTACT (never git reset --hard). If the human says to continue,
  re-dispatch reusing the WIP — do not restart from scratch.
```

This breaker governs PLAN TASKS. A flow outside the task cycle declares its own bound at its closing
step (`pelizzai-audit` step 7, over the bootstrap diff; `pelizzai-debug` step 4, over the bug's
working tree) — same shape: count the cycles, escalate on the limit, record `phase: blocked`, leave the
working tree INTACT. Dropping the per-task machinery never drops the limit.

## 6. Commit as a gate

```text
- The member does NOT commit. The work stays in the working tree until BOTH lenses pass.
- Only after spec ✅ and quality ✅ (with fixes applied) does the COORDINATOR consolidate.
- The coordinator stages the task's exact paths; inspects `git diff --cached` and never uses
  `git add -A`. In the consumer the cursor is updated alongside, never staged (local per-dev
  file, ignored by git — issue #43).
- Granular: one DEFINITIVE commit per task. In the consumer, the cursor advances with the task
  but stays out of the commit; in source mode, the native execution record advances with no
  file. History is kept.
- Squash-final: one WORK commit per task (`wip(<slug>): <task>`) — never accumulate the entire
  working tree without a commit until the end (a crash would lose everything). After the tasks and
  overlays, `pelizzai-execute` consolidates the WIPs into a single commit **before** the
  final review and `validated-head`. `pelizzai-finish` does not rewrite history. The cursor stays
  out of the WIPs too — it is local per dev in the consumer, and source mode has no cursor file.
```

## 7. Advancing the cursor

In the consumer, alongside the task's commit update `pelizzai/data/state.md` (in `## Progress`,
append **one line** `T<n> ✅ <sha|date> — <note ≤1 line>` — a long report goes to
`pelizzai/data/reports/` with only the link —, adjust `next` and `pending`, keep `phase: exec`).
The cursor is the local per-dev file `pelizzai/.gitignore` covers (issue #43): it is NEVER staged
— not in the definitive commit (granular), not in a wip (squash-final), not at setup:
**there is no metadata-only commit to start the task**, and there is no cursor in any commit
after it either. On concluding the plan and sealing the content, `pelizzai-finish` seals
`phase: delivered` in the single metadata-only closure commit — which carries only the
`data/history/` file the intact-block migration generates — and the cursor returns to template
size; `done` is observed afterward.

In source mode, advance the native execution record after the commit and do not create
state/closure.

## 8. Model selection per role

Harness policy: **the model is whatever the user chose on their platform** — by plan, cost, or
preference — and it holds for every role: members, reviewers, and the coordinator use the
session's model, with no upgrade required. What the harness never does is **downgrade on its
own**: no role runs on a smaller model than the session's to save money, and no dispatch runs
below the session's effort. **The session's effort is the floor, not the ceiling everywhere:** the
platform's HIGHEST effort is reserved for the last filter — the final branch review and the
delivery's final validation — and enters earlier only as escalation after a review rejection (§5).
Per-task dispatches run at the session's effort; forcing the maximum on every routine dispatch
buys latency, not rigor. Specify the model and the effort explicitly when dispatching members and
reviewers, so they do not inherit a default smaller than the session's.

The harness elevates the reasoning of **any** model via `pelizzai-reasoning`: the right technique,
a verifiable protocol, and fresh evidence do not depend on the model's capability. Proportionality
still applies to the depth of the process (interview, brainstorming, TDD, the depth of each review
lens, overlays) — and it is **never lowered to compensate for a smaller model**. In architecture, in the
two review lenses, in the final review, and in the delivery's final validation, a smaller model
demands an intact process, not a shallower one.

If the platform allows more capability in a critical role, **recommend and ratify**: the model
bill is the user's, never an automatic swap. The BLOCKED steps are still give more context →
change the approach/split the task → escalate to the human; "switching models" only enters as a
ratifiable recommendation on that last step. Fix context, tooling, or decomposition first. The
coordinator records concerns, does not feign certainty.

## 9. Phase timing (lightweight instrumentation)

Stamp wall-clock timings as the cycle advances, so slowness is measurable instead of anecdotal:
per task, note the elapsed time of the implementation, of each review lens, and of the fix rounds,
appended to the SAME progress line the cursor already writes (`## Progress` in the consumer state;
the native execution record in source mode) — e.g.
`T3 ✅ <sha> — <note> [timing: impl 14m · spec 6m · quality 9m · fix-rounds 1 (7m)]`. It is a
suffix of the existing line, not a second one — the one-line-per-task Progress hygiene still
holds. No new file and no commit of its
own: the timing travels with the record that already exists, under the same rules (the consumer
cursor is local per dev and never staged). The final report aggregates the totals per phase — that
aggregate is what proves, or refutes, where the delivery's time went.
