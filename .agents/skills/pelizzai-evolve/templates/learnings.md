# Learnings — PelizzAI

> What execution already learned in this project. The file has TWO parts with opposite natures
> and **separate budgets** — they are not one pool.
>
> **Active rules** — read at task start by EVERY track: `pelizzai-plan` before
> approaches · `pelizzai-execute` before Task 1 and pasted into every task briefing (the member
> does not inherit the coordinator's context) · `pelizzai-quick-fix` before the change ·
> `pelizzai-diagnose` on entering the investigation and again when choosing the proof.
> **Budget: 40 lines hard.**
>
> **Incident log** — evidence, consulted ON DEMAND (promotion, recurrence check, doubt about a
> rule's origin); never loaded at task start. Those three read this file **and** every existing
> `pelizzai/data/history/learnings-<YYYY>.md`: archiving protects the budget, never the count
> that earns a promotion. **Budget: 160 lines hard**; at the ceiling with nothing retirable, the
> OLDEST entries move to `pelizzai/data/history/learnings-<YYYY>.md`, leaving in this file, in
> their place, the pointer
> `<!-- archived to pelizzai/data/history/learnings-<YYYY>.md — consult on a recurrence check -->`.
>
> Incidents are written when a defect's root cause is CONFIRMED — by `pelizzai-diagnose` inside
> the fix's own commit when the task is a bug, or offered as candidates by `pelizzai-finish` at
> closeout for defects confirmed during any delivery, review rounds included; `pelizzai-finish`
> also counts recurrences at closeout; `pelizzai-evolve` promotes and retires, ratified by the
> user.

## Active rules

<!-- Short imperatives applied on every task in their scope — the reason this file is read at
     task start, and the only part loaded there. A rule arrives here by PROMOTION only: the same
     root cause recurred 2–3 times. Each rule keeps a scope (a rule without one fires everywhere)
     and a pointer to the incidents that earned it.
     BUDGET: 40 lines hard, independent of the log below — a full log never costs a rule its
     seat. Hitting 40 lines of standing rules is a signal that the project needs a domain skill
     or a linter, not a longer file.
     scope: PATHS OR GLOBS, never prose. `back/**/repository*.py`, not "anything touching the
     database" — the reader has to decide in one second whether the rule binds. Every rule here
     is read, always: the scope tells the reader if it applies, it does not filter what loads. -->

- <imperative rule> — scope: `<path or glob, e.g. back/**/repository*.py>` — from: <incident dates/slugs>

## Incident log

<!-- Episodic: what happened, once each, newest first. Every entry carries all the fields —
     an entry that cannot name its trigger and root cause is an anecdote, not a learning.
     status: candidate → promoted (recurred 2–3×, rule extracted above) → retired (failure
     mode can no longer happen: code gone, dependency dropped, rule absorbed by a domain
     skill or a linter — retired entries leave the file).
     BUDGET: 160 lines hard. At the ceiling with nothing retirable, move the OLDEST entries to
     pelizzai/data/history/learnings-<YYYY>.md: the evidence is kept, it just stops competing
     for the space that is read at task start. The move is only complete when it leaves a
     pointer in this file, below, in place of the entries that left — one line per archive file,
     in the exact form the header above gives. A second move into a file already pointed to
     reuses that line. Whoever counts a recurrence reads this file AND every existing archive:
     a shorter log must never mean a smaller count. -->

- <YYYY-MM-DD> <slug> — status: candidate
  - trigger: <the observable event>
  - root cause: <the cause, not the symptom>
  - smallest durable fix: <file:line>
  - rule learned: <imperative | n/a — one-off>
  - scope: `<path or glob>`
  - revert: <one line to undo the fix>

_Last updated: <YYYY-MM-DD>_
