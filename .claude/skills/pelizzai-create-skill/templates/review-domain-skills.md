# PelizzAI — Domain-skill maintenance ledger

> Keeps the rhythm of domain-skill review from depending on human memory.
> Read by `pelizzai-create-skill` (cadence) and by `pelizzai-audit` (bootstrap).
> - Seeded by: `pelizzai-create-skill` at bootstrap (orchestrated by `pelizzai-audit`), with the **bootstrap date** (the bootstrap is the 1st review; seeding with the 1st commit would fire a spurious nudge on the first task).
> - Updated by: `pelizzai-create-skill` on every domain-skill creation/refresh and after every review.
> Keep the YYYY-MM-DD date on the SAME line as each label — the cadence check (skill and
> hooks) does label-anchored parsing on `last-review:`/`last-full-scan:` and reads the first
> date after each one; never leave a label with a digit-less placeholder above another valid date.

- **last-review:** <YYYY-MM-DD>
- **last-full-scan:** <YYYY-MM-DD>

## Domain skills

| Skill | Created | Last updated | Last commit/ref reviewed | Axis of last change | Origin |
| ----- | ------- | ------------ | ------------------------ | ------------------- | ------ |
| <name> | <YYYY-MM-DD> | <YYYY-MM-DD> | <short sha> | bootstrap / version-driven / rework-driven | repo-scan / interview |

## Log

- <YYYY-MM-DD> — ledger initialized by `pelizzai-create-skill` at bootstrap (orchestration: `pelizzai-audit`; baseline = bootstrap date, since the skills are born from the repo-scan of the current HEAD)
