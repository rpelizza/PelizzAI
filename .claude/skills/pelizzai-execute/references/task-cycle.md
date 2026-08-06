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
- Global layer: apply `pelizzai-preferences` (language, secrets, .env, production quality) and
  reason via `pelizzai-reasoning`; on conflict, the DOMAIN SKILLS pasted into this briefing and
  the project rules PREVAIL over preferences/reasoning.
- Test/validation strategy chosen by the matrix in §2. For external APIs, ground it in Context7
  for the observed version; current official documentation is the fallback, never memory.
- Reasoning: when the task involves uncertainty, a decision, or a diagnosis, the suggested
  dominant technique from `pelizzai-reasoning` (decomposition, RCA, comparison, verification —
  see the skill's matrix); omit it for a mechanical task with a clear contract — do not impose a
  technique without a trigger.
- The review profile recorded in the plan: `split` (default) or ratified `combined`, with the
  risk rationale.
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

## 3. Proportional review with two lenses

Every task passes through the **spec** and **quality** lenses, in this order, with **asymmetric
blindness**: the spec lens judges the code blind against the contract; the quality lens is the
**evidence** lens and receives the author's report in order to verify it. The profile decides
whether they use one or two dispatches:

| Profile | When | Execution |
| --- | --- | --- |
| `split` (default) | the normal case, including the bounded lane; **mandatory** for medium/high risk, public contract, security, data, migration, multiple parts, or structural rejection | the spec stage approves before quality is dispatched; independent dispatches |
| `combined` (ratified exception) | bounded lane, low risk, cohesive scope, no security/data/migration/public contract — **and** the user ratified the profile in step 4 of the setup gate | one reviewer and one report, spec first and quality second |

Proportionality: what varies with risk is the **depth** of each lens, not the existence of the
review nor the blindness. The **separate lenses with blindness** profile is the default in any
lane — only with two dispatches does the spec lens not know the author's narrative. If the diff
reveals a surface that changes the risk, promote `combined` to `split` without a new ratification;
downgrading to `combined` is always the user's explicit choice, never the saving of one round.

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

Approval requires **both** verdicts: spec ✅ **and** quality ✅, whether in the same report or in
separate stages. In the `combined` profile the asymmetry is logical: first the blind judgment
against the contract, only then the reading of the report to verify the evidence — never the
reverse. Conflict between the lenses → the coordinator decides with their OWN evidence or
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
- Limit: 3 fix→re-review cycles PER LENS, PER TASK. In the `combined` profile, use a shared
  counter; promote to `split` if it becomes unclear which lens is failing.
- The same issue rejected 2x → escalate on the 2nd.
- Structural rejection ("the approach is fundamentally wrong") → escalate immediately.
- Resets (do not give up too early): zero the spec counter on spec ✅, the quality counter on
  quality ✅, and BOTH when starting a new task — a loop in Task N does not affect N+1.
- Does NOT count as a cycle (avoids false positives): BLOCKED (it is already an escalation, never
  a tally); DONE_WITH_CONCERNS whose caveats are observations and the review passes; an
  implementer who CONTESTS the rejection ("the reviewer says X is missing, but it is on line Y")
  → treat it as NEEDS_CONTEXT and reconfirm with the reviewer (reviewers are subagents and make
  mistakes).
- On blowing the limit: stop dispatching; write `phase: blocked` in the consumer state or native
  execution record. In the consumer, log the blockage in `## Progress` → `pending` (task, stage,
  number of failed cycles, the distinct rejection reasons
  IN ORDER, the fixes attempted, and the pattern: independent issues / same recurring issue /
  structural conflict); commit ONLY the cursor in the consumer (source mode creates no cursor commit); escalate to the
  human with an ACTIONABLE message (what was done + each reason + fixes + pattern + options:
  clarify the spec via pelizzai-writing-plans / split the task / revise the plan);
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

Harness policy: **the model is whatever the user chose on their platform** — by plan, cost, or
preference — and it holds for every role: members, reviewers, and the coordinator use the
session's model, with no upgrade required. What the harness never does is **downgrade on its
own**: no role runs on a smaller model than the session's to save money, and the effort/reasoning
stays at the highest level the user's platform offers. Specify the model and the effort explicitly
when dispatching members and reviewers, so they do not inherit a default smaller than the
session's.

The harness elevates the reasoning of **any** model via `pelizzai-reasoning`: the right technique,
a verifiable protocol, and fresh evidence do not depend on the model's capability. Proportionality
still applies to the depth of the process (interview, brainstorming, TDD, review profile,
overlays) — and it is **never lowered to compensate for a smaller model**. In architecture, in the
two review lenses, in the final review, and in the delivery's final validation, a smaller model
demands an intact process, not a shallower one.

If the platform allows more capability in a critical role, **recommend and ratify**: the model
bill is the user's, never an automatic swap. The BLOCKED steps are still give more context →
change the approach/split the task → escalate to the human; "switching models" only enters as a
ratifiable recommendation on that last step. Fix context, tooling, or decomposition first. The
coordinator records concerns, does not feign certainty.
