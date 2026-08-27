# Dead-name sweep — remap of renamed skills in consumer artifacts

Read on demand from the **Partial state** branch of `pelizzai-onboard`, when a remap runs over an
existing `pelizzai/` and the artifacts may predate a harness rename. Never resident.

## Why

Harness updates never overwrite project content — correctly. The cost is that data artifacts
materialized at bootstrap (`pelizzai/profile.md`, `pelizzai/data/*.md`) keep the skill names that
were current on that date. After a rename, their headers send the reader to skills that no longer
exist: the file says who reads and writes it, and the pointer is dead. Execution does not break —
the router triggers real skills, not headers — but navigability and trust do (issue #67).

## The sweep

1. **Ground truth is the catalog on disk.** List the directories under `.claude/skills/`. A
   `pelizzai-*` identifier is dead when no directory of that name contains a `SKILL.md` — the
   installed-skill criterion the validator uses; an auxiliary folder without `SKILL.md` does not
   make a name live. Never validate against a hardcoded table: tables drift exactly like the
   artifacts being fixed.
2. **Scan every `.md` under `pelizzai/` (`pelizzai/**/*.md`), excluding `pelizzai/data/history/`.**
   History files are the record of what held at the time — `overlays:` lines naming that era's
   skills; rewriting them falsifies the record. Everything else — `profile.md`,
   `data/learnings.md`, `data/verification-standard.md`, `state.md`, specs and plans still
   active — is in scope.
3. **Propose, never rewrite silently.** The artifacts belong to the user. For each dead name, find
   the current skill that owns the same role (read the descriptions in the catalog; the rename
   usually preserves the role) and present the substitution list in one block — old name, proposed
   name, files touched — with a recommendation, and wait for ratification. When no current skill
   clearly owns the role, that is a material gap: close it through `pelizzai-interview`, one
   question at a time, before proposing or writing anything.
4. **Read-only entry reports and stops.** In `scan-only`, list the dead names and where they
   point; the rewrite waits for a write-authorized pass, like every Partial state repair.
5. **Verify by re-scanning.** After the ratified rewrite, the sweep over `pelizzai/**/*.md` minus
   `pelizzai/data/history/` returns zero dead names. Record the remap inside the rewritten
   artifact itself — where it already keeps provenance remarks, as `profile.md` does with its
   remap notes; `pelizzai/data/history/` is never the destination and never changes.

## Red flags

```text
- Rewriting data/history/ — the historical record is legitimate as written.
- Substituting by a memorized rename table instead of the catalog on disk.
- Fixing the names without ratification because "it is just a header".
- Treating a dead name in an ACTIVE artifact as historical record to skip the fix.
```
