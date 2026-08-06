# Contributing to PelizzAI

Thanks for your interest. This document explains what is peculiar about this repository — because
contributing here does not look like contributing to an ordinary software project.

## What you are editing

The "product" of this repository is **instructional prose in markdown**: the skills. They are read
by a coding agent at runtime and change its behavior. There is no running application, and there is
no build.

The practical consequence: **a regression here is an ambiguous, contradictory, or lost
instruction** — not a stack trace. The most common and most expensive defect is a section that
contradicts another section of the same file. The reviewer reads looking for exactly that.

## The golden rule

**Do not edit the generated files.** These paths are produced by `scripts/sync-harness.mjs`, and
any change made to them is lost on the next sync:

- `.agents/skills/`
- `AGENTS.md`
- `GEMINI.md`
- `scripts/pelizzai-core-skills.txt` (manifest)
- `dist/` (all of it — the ready-to-copy consumer payload)

The source of behavior is `.claude/` (skills and hooks). Also authored — and editable — are
`CLAUDE.md`, `README.md`, `scripts/`, and `.github/`. `.cursor/rules/pelizzai.mdc` is a
**manual** adapter: the sync distributes it but does not generate it, and it must be updated by
hand when the entrypoints change.

## The flow

```bash
# 1. edit .claude/skills/... or .claude/hooks/...

# 2. regenerate the mirrors (always, before committing)
node scripts/sync-harness.mjs

# 3. validate sync and contracts
node scripts/sync-harness.mjs --check
pwsh scripts/test-harness-contracts.ps1     # must finish with 0 FAIL

# 4. commit and PR
```

Step 2 is not optional. A commit that changes the source without regenerating the mirror breaks
the CI `sync-check` job.

**Requirements:** Node.js 18+ for the core; PowerShell 7+ for the contract suite and the `.ps1`
wrappers.

## Contracts: new behavior requires a new assertion

`scripts/test-harness-contracts.ps1` is what keeps the harness from regressing silently. Every
relevant behavior has an assertion that locks it in.

If your PR changes behavior, it needs to touch the contracts:

- **new behavior** → a new assertion that would fail without your change;
- **behavior removed on purpose** → remove the assertion and explain in the commit body why it no
  longer holds;
- **behavior that moved to another file** → repoint the assertion.

One specific anti-pattern will be rejected in review: **weakening an assertion until it passes**.
A regex that matches almost anything, or a `Check-NotMatch` turned into a no-op, is worse than no
assertion at all — because it simulates coverage that does not exist. If an assertion is in your
way, either its behavior still holds (and your change is wrong), or it no longer holds (and the
assertion should be removed with justification). There is no third way.

## Writing a skill

Each skill lives in `.claude/skills/<name>/SKILL.md` and follows these rules:

- **Frontmatter only in `SKILL.md`.** It needs `name` and `description`, and `name` has to equal
  the directory name. Files under `references/`, `templates/`, `evals/`, and `techniques/` take
  **no** frontmatter.
- **The `description` is the discovery mechanism.** It is how the agent finds the skill. Write the
  real usage triggers, including the colloquial phrases a person would use ("it doesn't work",
  "it broke"). An elegant, generic summary makes the skill never fire.
- **Every pointer must exist.** `references/...`, `templates/...`, and every `pelizzai-*` name
  cited in prose are verified; a dead pointer breaks the sync.
- **Cross-references are qualified.** When citing a file that lives in another skill, write
  `pelizzai-execute` → `references/task-cycle.md`, never a bare `references/task-cycle.md`
  — otherwise the reader searches the wrong directory.

There is a skill dedicated to this: `pelizzai-create-skill`, with
`references/skill-authoring.md`. Worth reading before writing your first one.

## Touching the hooks

The hooks in `.claude/hooks/` are the most sensitive part of the repository, because **they run on
the machine of whoever installed the harness**.

- **Parity is mandatory.** Each hook exists as `.mjs` (Node) and `.ps1` (PowerShell). Divergence
  between the two legs is a bug, even when each one is correct in isolation.
- **A false positive is the worst possible defect.** An undue block halts a stranger's work,
  teaches the agent to route around the safety net, and makes the whole protection lose its
  value. The `guardrails` rules are **deliberately narrow**: they target the handful of commands
  that erase work irrecoverably, and they do not try to cover everything dangerous in Git. When
  touching them, prefer a false negative over a false positive.
- **Test both legs, by executing.** The suite has fixtures of commands that must block and of
  commands that must pass. Add to both lists — a hook you have not executed is not verified.
- **Fail open on internal error.** If the hook itself breaks, it exits with 0. A bug in the safety
  net must never hijack the user's tool.

## Language and style

The repository is written entirely in **English**. This holds for skills, code comments, commit
messages, and PR descriptions.

The brand is spelled exactly **PelizzAI** in prose — never "Pelizzai", "pelizzAI", or "PELIZZAI".

Write instruction, not an essay: short sentences, active voice, the criterion before the example.
The skill `pelizzai-writing-clearly` is the project's style guide.

## Opening a PR

- Describe **what changes in the agent's behavior**, not just which files you touched.
- Say how you verified it. "I ran the suite" is the minimum; if you touched a hook, paste the
  output of the cases you tested.
- Small, thematic PRs get reviewed faster. A doctrine change that cuts across 15 skills should
  probably be a discussion before it is a PR.
- For large changes or ones that alter an invariant (user authority, isolation before the first
  write, evidence before completion), **open an issue first**. These points are deliberate, and
  changing them requires conversation, not just code.

## One principle that cuts across everything

The harness classifies, reasons, investigates, and recommends; **the user decides the product**.
When proposing a change, check that it does not authorize the agent to decide scope, UX,
architecture, data, accepted risk, or acceptance criteria on its own. A material gap found during
the work must lead to `pelizzai-interview` — never to a silent default.

A contribution that breaks this principle will be rejected even if the code is impeccable.
