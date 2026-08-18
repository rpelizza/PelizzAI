---
name: pelizzai-evolve
description: The harness's self-optimization cycle over two consumer artifacts — pelizzai/data/verification-standard.md (what "correct" means here) and pelizzai/data/learnings.md (what execution already learned). Use when a failure recurs and a standing rule might prevent it; when pelizzai-finish flags a recurrence at closeout; when a better path found mid-task must be proposed instead of adopted; when either artifact is missing or over budget; or when the user asks to promote a learning, update the verification standard, or make the project "learn" from a defect.
---

# PelizzAI Evolve

The self-optimization cycle: two files, two channels, one rule.

<EXTREMELY-IMPORTANT>
**Self-improvement is a side effect of fixing a real, observed failure — never a reason to go
looking for something to change.** No sweep, no refresh, no "while I'm here". Nothing enters
this cycle that cannot name the failure that produced it.
</EXTREMELY-IMPORTANT>

**Announce on start**, in the conversation's language: that you are using the PelizzAI Evolve
skill to update the project's verification standard or learnings from an observed failure.

## Source mode — no consumer runtime

In the PelizzAI source repo (sentinel `scripts/pelizzai-source-repo.txt`), never create
`pelizzai/`. A lesson about the harness itself becomes a proposal against the harness's own
skills/tests through the normal task flow; a lesson that only matters to one conversation stays
in the native execution record.

## The two artifacts

| File | Holds | Read by, and when | Written by, and when |
| --- | --- | --- | --- |
| `pelizzai/data/verification-standard.md` | what *correct* means here | `pelizzai-final-verification` before judging a delivery · `pelizzai-review` when briefing reviewers · `pelizzai-writing-plans` when drafting validation | `pelizzai-audit` at bootstrap · here, in its own ratified change — **never during a correction** |
| `pelizzai/data/learnings.md` (**Active rules**) | what execution already learned | `pelizzai-writing-plans` before approaches · `pelizzai-execute` before Task 1 **and pasted into every task briefing** · `pelizzai-quick-fix` before the change · `pelizzai-debug` on entering the investigation and again when choosing the proof | incident entries at root-cause confirmation (usually `pelizzai-debug`, in the fix's own commit) · `pelizzai-finish` counts recurrences at closeout · here, on promotion and retirement |
| `pelizzai/data/learnings.md` (**Incident log**) | the evidence that earned each rule | on demand — **not** loaded at task start: promotion, recurrence check, and when a rule's origin is in doubt; those three read `learnings.md` **and** every existing `pelizzai/data/history/learnings-<YYYY>.md`, never the active file alone | same as above |

`verification-standard.md` missing in a consumer → propose creating it from
[templates/verification-standard.md](templates/verification-standard.md); `learnings.md`
missing → from [templates/learnings.md](templates/learnings.md) — each artifact keeps its own
schema (`pelizzai-audit` seeds both at bootstrap; both are **versioned**, like the rest of
`pelizzai/data/`'s durable record). A cycle with no standard has nothing to measure against, and
a learnings file nobody reads before designing is a log.

**Neither file has one owner doing both halves — deliberately.** The node that observes a
failure is not the node tempted to soften the standard, and the node that designs is not the one
that decides what counts as a lesson.

### `verification-standard.md` — three parts

1. **Acceptance criteria: pass/fail, never a 0–5 score.** Concrete, objective, observable.
2. **The procedure.** Reading the code is not exercising the artifact — review proves intent,
   execution proves behavior. Name the command and the output that proves each criterion.
3. **The baseline** — the latest known-good state **per surface**, one row each, with numbers
   and evidence. A new approval of a surface **replaces its row**; the superseded numbers live
   in `pelizzai/data/history/`, where "when did p95 move, and which delivery moved it?" is
   actually answered.

**Read-only during any correction.** If an output fails, fix the **output**. Editing a
criterion, the procedure, or the baseline so a failing output passes is the guardrail violation
under a friendlier name. The standard changes only in a deliberate change of its own, ratified
through `pelizzai-interview`.

**Budget: 150 lines hard — Baseline at most 25 rows.** Past 25 rows the criteria are describing
more surfaces than one standard can hold: split it per package before dropping a row.

### `learnings.md` — two parts

**Active rules** (semantic): short imperatives applied on every task in their scope. This is the
part that is READ AT TASK START, by every track — it is the prevention mechanism, and it is kept
short precisely so that reading it is never a cost worth skipping. **Incident log** (episodic):
what happened, once each, newest first; evidence consulted on demand, never loaded at task start.
Every entry carries **trigger** · **root cause** (not the symptom) · **smallest durable fix**
(`file:line`) · **rule learned**, or explicitly `n/a — one-off` · **scope** · **revert** (one
line) · **status** `candidate → promoted → retired`.

**`scope:` names paths or globs, not prose.** `back/**/repository*.py` or
`front/**/*.spec.ts` — never "anything that touches the database". Whoever reads a rule has to
decide in one second whether it applies to what they have in hand, and prose forces a judgment
call that a hurried track will resolve as "probably not mine". This is precision of
communication, not a filter: **every** Active rule is read, always, and the scope tells the
reader whether it binds — nothing matches globs mechanically to decide what to load. A filter
that guesses wrong hides exactly the rule that would have redirected the work, and looks like
coverage while doing it.

**Promotion:** a learning becomes a standing rule only after it **recurred 2–3 times**. The
first occurrence is an incident (`candidate`); the repeat is the evidence. `pelizzai-finish`
counts — writing a closeout for a task that fixed a confirmed defect, it checks whether that
root cause is already in the log, and a match routes here. **That count runs over the whole
corpus**: `learnings.md` plus every existing `pelizzai/data/history/learnings-<YYYY>.md`.
Counting the active file alone makes archiving lower the number that decides promotion — the
prevention mechanism weakened by the very act of preserving its evidence. The count is also the
reason the valve leaves a pointer behind (below): a corpus nobody can find is a corpus nobody
reads. The promotion itself happens here and is **ratified by the user** via
`pelizzai-interview`: flip the entries to `promoted`, write the one-line imperative into
**Active rules** with its scope. **The archives are append-only**: the flip reaches only the
entries still in `learnings.md` — an archived entry is evidence, not state to rewrite. What
records that a root cause was already promoted is the standing rule in **Active rules**, so a
promotion that never lands there leaves the corpus counting the same cause forever. Propose an
edit to the project's `CLAUDE.md` only when the rule must hold before any skill loads — in the
**project's own section, never inside the `pelizzai:contract` block** (the anchored block
belongs to the harness and is overwritten by the next sync).

**Two budgets, deliberately separate.** **Active rules: 40 lines hard. Incident log: 160 lines
hard.** They are NOT one pool of 200. Under a shared budget the log wins by construction — it
only grows, the rules are few, and "retire before adding" puts the pressure on whichever side has
less mass. What gets squeezed out is the prevention, and what survives is the history: the exact
inversion of what the file is for. Separate ceilings mean a full log can never cost a rule a seat.

Retire before adding, **within each section**: an entry whose failure mode can no longer happen
(code gone, dependency dropped, rule absorbed by a domain skill or a linter) goes `retired` and
out. A log at its ceiling with nothing retirable moves its OLDEST entries to
`pelizzai/data/history/learnings-<YYYY>.md` — the evidence is kept, it just stops competing for
the space that is read at task start. **Archiving is a budget measure and nothing else: the
moved entries stay in the corpus of the recurrence check.** So the move is only complete when it
leaves a **pointer in `learnings.md`**, in place of the entries that left — one line naming the
archive it wrote to and saying to consult it on a recurrence check — one pointer per archive
file, so a move into a file already pointed to needs no second line. The pointer replaces
entries, so it costs the section nothing it was not already spending. Without the pointer,
whoever counts sees a shorter log and no reason to suspect there is more, which is exactly how
archiving turns into a silent reduction of the count. Active rules at their ceiling is a
different signal: 40 lines of standing rules means the project needs a domain skill or a linter,
not a longer file.

## The two channels

| Channel | What it is | What you may do | Gate |
| --- | --- | --- | --- |
| **Defect** | an observed failure | fix it, inside the guardrails | none, once confirmed (`pelizzai-debug` proves it is real and repeatable) |
| **Opportunity** | a better path noticed mid-task | measure it, propose it | human adoption, always |

**Defect — confirm before fixing.** An anomaly that does not reproduce is **logged, not fixed**
— a fix for a phantom is a change with no oracle. Confirmed → smallest durable change, then the
*full* standard, not only the part that broke.

**Opportunity — proposal-only, never autonomous.** Finish on the path that already works. Then
treat the gain as a hypothesis: state it in one line, validate the alternative against the
**complete** standard, **measure it against the baseline** with the numbers named, and propose.
Adoption is the user's. An opportunity that cannot be measured against the baseline is an
opinion — present it as one.

## The worth-it gate

Escalate from a local fix to a structural change only when **both** hold: the defect
**recurred** (at least twice in the corpus — `learnings.md` plus every existing
`pelizzai/data/history/learnings-<YYYY>.md`), and a local fix demonstrably does not prevent
the next one. Otherwise fix locally, log, move on. Every change is **reversible**, its revert
line written before it lands; nothing structural, shared, or irreversible lands without explicit
user approval — including the standard, `CLAUDE.md`, shared config, and anything another project
consumes.

## Boundaries with the existing machinery

- **Domain skills** stay with `pelizzai-create-skill` and its ledger
  (`pelizzai/data/review-domain-skills.md`) — this cycle does not duplicate that maintenance. A
  learning whose natural home is a domain skill is proposed THERE, and its incident entries are
  retired here once the skill absorbs the rule.
- **A lasting user preference** is recorded via `pelizzai-preferences`, not as a learning.
- **The cursor and the history** (`state.md`, `history/`) stay with `pelizzai-execute`
  and `pelizzai-finish`; this cycle only reads them as evidence.

## Red flags

```text
- A change with no named, observed failure behind it; "fixing" an anomaly nobody reproduced.
- Touching the standard, a criterion, or the baseline while a correction is open.
- Adopting an opportunity because it is "obviously better", or proposing one with no measurement.
- Promoting a learning on its first occurrence — or leaving a second occurrence unpromoted
  because nobody claimed the edit.
- A Baseline row appended for a surface that already had one.
- learnings.md **at or past** either budget with nothing retired or archived — the ceilings are
  hard, so touching 40/160 already engages the valve; waiting to exceed them means the next
  promotion has nowhere to land. Each section reacts on its OWN ceiling (a full log is never a
  reason to retire a rule; a full rules section is never a reason to archive the log).
- Counting a recurrence over `learnings.md` alone while `pelizzai/data/history/` holds archived
  entries — or archiving without leaving the pointer, which produces the same blind count by
  omission. Archiving protects the budget, never the count that earns a promotion.
- Flipping an archived entry to `promoted`, or landing a promotion that never reaches Active
  rules: the archives are append-only, and the standing rule is the ONLY record that a cause was
  already promoted. Without it the corpus keeps counting the same cause forever.
- Declaring a reader of the Active rules that does not actually read them. A false declaration is
  worse than an absent one: whoever audits the harness assumes a coverage that is not there.
- Writing a `scope:` in prose instead of paths/globs — or building a mechanism that loads only
  "the matching rules": the section is short so that it is read WHOLE.
- Promoting a rule into the pelizzai:contract block of CLAUDE.md (the next sync erases it).
- Creating pelizzai/ artifacts in the source repo.
```

## Integration

**Called by:** `pelizzai-finish` (recurrence or budget flagged at closeout), the user
directly, and `pelizzai-debug` when a confirmed root cause deserves more than an incident
entry.

**Combines with:** `pelizzai-interview` — one ratification per promotion, standard change, or
opportunity adoption; `pelizzai-final-verification` and `pelizzai-review` — the
standard's readers; `pelizzai-writing-plans`, `pelizzai-execute`, `pelizzai-quick-fix`, and
`pelizzai-debug` — the readers of the Active rules, one per track, so no route reaches a decision
without them; `pelizzai-audit` — seeds both artifacts at bootstrap; `pelizzai-create-skill` — the
home of a lesson that belongs in a domain skill.
