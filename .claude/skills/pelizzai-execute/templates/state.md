# Task state — PelizzAI

> Cursor of the active task. Lives in `pelizzai/data/state.md` (repository or workspace root),
> LOCAL per dev — `pelizzai/.gitignore` covers it (issue #43); it is never committed. The durable
> record is `data/history/` (VERSIONED). Doctrine — who writes each field, the Delivery lifecycle
> (`delivered` → `done`), reconciliation, and history hygiene — lives in `pelizzai-execute` →
> SKILL.md §State and resumption.
> Reference, don't duplicate: the fields live here, the process lives there.
> No active task = `slug: <none>`. `phase: blocked` = stuck, awaiting a human decision.

## Active task

- slug: <none>
- track: <feature | bug | tweak | refactor | infra | review | bootstrap>
- lane: <bounded | standard | exploratory>   # depth classified by the router, ratified at kickoff (high risk lands in `exploratory`; severity lives in `risk:`)
- phase: <brainstorm | plan | exec | review | delivered | done | abandoned | blocked>   # pelizzai-finish does NOT declare `done`: it seals `delivered` (content + destination executed); `done` is observed later against git; `abandoned` = archived without merge
- branch: <branch-name>
- base-ref: <exact ref used to create the branch, e.g. origin/main or refs/heads/trunk>
- base-sha: <full SHA resolved from base-ref before the first change>
- validated-head: <none | full SHA of the last content commit approved in the final validation>
- confirm: <none | observable condition to establish `done` — e.g. "base-ref contains validated-head (PR/branch integrated)" | "local delivery accepted by the user">
- delivery-status: <none | pending push | pending pr | local | archive>   # destination INTENT sealed in the pelizzai-finish closure; what actually happened is OBSERVED against the remote on resumption (the cursor is local — never committed)
- kickoff: <pending | ratified YYYY-MM-DD>   # consolidated gate (plan content + isolation/mode/commits) ratified by the user
- isolation: <pending | branch | worktree>   # <pending> until ratification; never written as a silent default
- worktree-path: <none | path of the worktree, when isolation: worktree>
- execution-mode: <pending | team | subagents | inline>   # <pending> until ratification; the three options always visible (team never omitted)
- commit-strategy: <pending | granular | squash-final>   # <pending> until ratification; squash-final only on the user's explicit request
- review-integrity: <blind | degraded YYYY-MM-DD — reason>   # `blind` = every lens the flow REQUIRES ran independently (two where a ratified contract exists; the quality lens alone where none does — bootstrap, standalone). `degraded` ONLY when the environment had no independent reviewer and the user accepted a declared non-blind review; it travels to the final report and to the next session (pelizzai-review → "When there is no independent reviewer")
- effect: <read-only | write-local | external>
- risk: <low | medium | high>
- overlays: <none | comma-separated names>   # required cross-cutting skills, e.g. pelizzai-frontend, pelizzai-oswap
- audience: <technical | layperson>
- spec: <pending | path of the spec | explicitly waived YYYY-MM-DD | not-applicable>
- plan: <pending | path of the plan in execution, e.g. pelizzai/plans/YYYY-MM-DD-<topic>.md>
- project: <none | path of this task's single Git repository>

## Progress

<!-- One line per task of the plan. A long report (QA, review, investigation, round decision)
     does NOT live here: write it to pelizzai/data/reports/<YYYY-MM-DD>-<slug>-<topic>.md (ignored)
     and leave only the link. Over ~60 lines? The harness proposes compacting once (advisory, never blocks). -->

- T1 ✅ <sha|YYYY-MM-DD> — <note ≤1 line | → data/reports/<file>>
- next: <next concrete step>
- pending: <open items / doubts>

## History

<!-- Durable index of deliveries. On the `delivered` seal, the task's intact block migrates to
     pelizzai/data/history/<YYYY-MM-DD>-<slug>.md (VERSIONED), the cursor returns to the size of
     this template, and ONE line stays here — stamped with `done`/`abandoned` when observed. -->

- <YYYY-MM-DD> — state initialized (pelizzai-router / pelizzai-starting-branch / pelizzai-execute)
- <YYYY-MM-DD> <slug> — delivered [→ done | abandoned <YYYY-MM-DD>] — <outcome in ≤10 words> → data/history/<YYYY-MM-DD>-<slug>.md

_Last updated: <YYYY-MM-DD>_
