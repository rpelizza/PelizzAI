# Learnings — PelizzAI

> What execution already learned in this project. Read by `pelizzai-writing-plans` and
> `pelizzai-execution-plans` BEFORE approaches are proposed — the only moment a rule can still
> change a design. Incidents are written when a defect's root cause is CONFIRMED (usually by
> `pelizzai-debugging`, inside the fix's own commit); `pelizzai-finish-task` counts recurrences
> at closeout; `pelizzai-evolve` promotes and retires, ratified by the user.
> Budget: **~200 lines hard** — retire before adding; a file too long to read at task start is
> a file nobody reads.

## Active rules

<!-- Short imperatives applied on every task in their scope — the reason this file is read at
     task start. A rule arrives here by PROMOTION only: the same root cause recurred 2–3
     times. Each rule keeps a scope (a rule without one fires everywhere) and a pointer to the
     incidents that earned it. -->

- <imperative rule> — scope: <where it applies> — from: <incident dates/slugs>

## Incident log

<!-- Episodic: what happened, once each, newest first. Every entry carries all the fields —
     an entry that cannot name its trigger and root cause is an anecdote, not a learning.
     status: candidate → promoted (recurred 2–3×, rule extracted above) → retired (failure
     mode can no longer happen: code gone, dependency dropped, rule absorbed by a domain
     skill or a linter — retired entries leave the file). -->

- <YYYY-MM-DD> <slug> — status: candidate
  - trigger: <the observable event>
  - root cause: <the cause, not the symptom>
  - smallest durable fix: <file:line>
  - rule learned: <imperative | n/a — one-off>
  - scope: <where the rule applies>
  - revert: <one line to undo the fix>

_Last updated: <YYYY-MM-DD>_
