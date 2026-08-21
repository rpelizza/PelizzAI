# Execution profile — <project>

> Detected by `pelizzai-audit` at bootstrap, reading the project's REAL scripts
> (package.json `scripts`, Makefile/Justfile, pyproject, …) — never guessed. The exception is
> the *Ratified execution defaults* section, which is NOT detected: it is born `<unset>` and only
> the user fills it in when ratifying the policy at the post-plan gate.
> Lives at `pelizzai/profile.md`. Consumed by: `pelizzai-tdd` (test command),
> `pelizzai-execute` (post-plan gate + final validation), `pelizzai-finish`
> (verification and destination), `pelizzai-router` (execution-defaults recommendation),
> `pelizzai-debug` (feedback loop), and `pelizzai-create-skill` (Stack baseline
> → version/adoption-driven axes). Update it when scripts/manifests change; in a
> workspace, repeat the sections per project.

## Harness and skill roots

- Source mode: `<true | false>`
- Canonical skill root: `<.claude/skills | .agents/skills | other native root>`
- Installed mirrors: `<none | list of roots that must stay byte-for-byte>`

_Detect from the files actually installed. Domain skills are written to the canonical root and,
when there are mirrors, synced and verified; never assume `.claude/skills` in every IDE._

## Ratified execution defaults

> PROJECT policy explicitly ratified by the user — NOT inheritance from the previous task.
> The post-plan gate uses these values as recommendations in its sequential questions. They do
> not auto-confirm a new task, unless the user explicitly delegates applying the policy.
> At bootstrap they are all born `<unset>`: write the value **literally between `<>`**. Any value
> between `<>` (the menu below, `<unset>`) reads as NOT ratified; the SessionStart hook recap
> fires on ANY raw value outside `<...>` and `unset` — including `branch`, `inline`, or
> `squash-final`. The hook reads exactly these three fields. There is no review policy: the
> review's form (one reviewer with both verdicts per task; two dispatches on the final range) is
> invariable, so there is nothing for a project to pre-select.

- isolation-default: <branch|worktree|unset>
- execution-mode-default: <inline|subagents|team|unset>
- commit-strategy-default: <granular|squash-final|unset>
- Ratified on: <YYYY-MM-DD> | Overrides since then: <n>
<!-- destination is not persistable: push/PR/publish require per-task confirmation -->

## Commands

| Action | Exact command        | Directory           |
| ------ | -------------------- | ------------------- |
| test   | `<e.g.: pnpm test>`  | `<root \| apps/x>`  |
| build  | `<…>`                | `<…>`               |
| lint   | `<…>`                | `<…>`               |
| format | `<…>`                | `<…>`               |
| dev    | `<…>`                | `<…>`               |

_List only what the project actually has; an action without a real script = row removed (do not invent)._

## Package manager

- Manager: `<npm | pnpm | yarn | bun | pip | poetry | uv | cargo | …>` — determined by the LOCKFILE (`<package-lock.json | pnpm-lock.yaml | …>`).
- Install: `<exact command, e.g.: pnpm install>`. Never use another manager — installing with npm in a pnpm project corrupts the lock.

## Stack baseline

_Snapshot date: YYYY-MM-DD (bootstrap or last refresh)._

| Technology        | Version (manifest) |
| ----------------- | ------------------ |
| `<e.g.: Node>`    | `<20.x>`           |
| `<framework>`     | `<x.y.z>`          |
| `<key-lib>`       | `<x.y.z>`          |

_Anchor of the version-driven and adoption-driven axes of `pelizzai-create-skill`:
version-driven = the version of an item in this baseline changed in the manifests (version drift);
adoption-driven = there is a new top-level entry in the manifests, absent from this baseline AND
from the `pelizzai/domain-skills.md` catalog → proposal to CREATE a skill for the new stack._

## Available MCPs (optional)

- `<e.g.: context7 — current documentation for libs/frameworks>`
