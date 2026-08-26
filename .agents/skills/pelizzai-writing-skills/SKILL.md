---
name: pelizzai-writing-skills
description: "Use this skill to create, edit, validate, or optimize a skill **at the user's request**, and as the authoring and maintenance engine for a project's **DOMAIN** skills. Trigger it (a) at bootstrap, called by `pelizzai-audit`, to generously enumerate the candidates the repo's patterns justify — one per recurring flow/responsibility — and write them after the user ratifies the list; (b) for domain-skill maintenance — a stack that changes version, rework that repeats in git, a newly adopted stack with no coverage, or an overdue cadence (10+ commits, 10+ days, repo-scan every 15 days); and (c) when the user says \"create a skill\", \"turn this into a skill\", \"optimize the description\", or \"update the domain skills\". Proactive maintenance acts ONLY on domain skills — harness skills (`pelizzai-*`) are only created or edited at the user's explicit request. And it NEVER overwrites a skill blindly: the diff goes to the user before writing, with per-skill approval."
---

# PelizzAI Writing Skills

## Purpose

This skill is the PelizzAI harness's **skill authoring and maintenance engine**. It does two jobs:

| Job            | When                                                                   | Result                                                           |
| -------------- | ---------------------------------------------------------------------- | ---------------------------------------------------------------- |
| **Authoring**  | The user wants a new skill; or `pelizzai-audit` requests domain skills at bootstrap | One or several well-written, grounded, cataloged skills          |
| **Maintenance** | The stack changes version; patterns repeat in git; the cadence comes due | Domain skills updated (with diff and confirmation) and recorded |

**Announce on start**, in the conversation's language: that you are using the PelizzAI Writing Skills skill to create/maintain skills.

<TEAM-MEMBER-STOP>
If you are a **member** of a team (subagent/teammate) tasked with writing **one** domain skill, write only yours and return the draft to the coordinator — do not orchestrate the whole bootstrap or touch the catalog/ledger. Invoke `pelizzai-reasoning` for your subtask.
</TEAM-MEMBER-STOP>

---

## Core principle

> A skill is written once and invoked thousands of times, in contexts you never saw. Write to **generalize**, not to nail one specific case. Keep it lean, explain the **why** behind every rule (theory of mind, not rigid commands), and **never** overwrite someone else's work without showing what changes.

---

## Authority

Respect the platform's native hierarchy. Within the same level, a specific user/project instruction prevails over this skill's defaults. Safety and the absence of surprises are not style preferences.

---

## Authoring rules (summary)

Full detail in **[references/skill-authoring.md](references/skill-authoring.md)** — read it before writing a skill. In short:

- **Frontmatter:** only `name` and `description`. The `description` is the trigger — include **what the skill does AND the observable signals/phrases for when to use it**. Be **incisive**: under-triggering is the dominant failure (the harness tends to trigger too little); naming the *near misses* is what prevents the skill storm, not shrinking the trigger. The `description` **never summarizes the workflow** — a process summary makes the agent follow the description and SKIP the body.
- **Progressive disclosure (3 levels):** metadata (always in context) → `SKILL.md` body (ideally <500 lines) → bundled resources on demand (`scripts/`, `references/`, `assets/`). If the body exceeds ~500 lines, move depth to `references/` with clear pointers.
- **Style:** imperative in instructions; explain the why (theory of mind); **generalize** — write for many contexts, not for the test cases; start with a draft and improve with fresh eyes.
- **Evals:** skills with **verifiable** output (transforming a file, extracting data, generating code, fixed flow) benefit from test cases in `evals/`; subjective skills (style, art) usually do not. See `references/skill-authoring.md`.

---

## Proportional behavioral validation

Treat skills as versioned behavior. Use the smallest evidence that detects the relevant regression; detail in **[references/skill-authoring.md](references/skill-authoring.md)**.

```text
- A high-risk behavioral change, or behavior still unknown, needs a baseline:
  a documented real failure, an existing eval, or a minimal scenario. Repo/feedback evidence may
  suffice; an editorial edit needs no behavioral baseline.
- Write the smallest rule that fixes the failure class; do not overfit to the example.
- Version a pressure test only when it protects against a material/recurring failure. Do not
  create a test file for every wording tweak.
- Fixed flow/script: executable test. Routing/heuristic: forward-test with clean context.
  Subjective style: contrastive examples and inspection, without faking determinism.
- Re-run the affected regression and a composite smoke suite. More samples only when the
  observed variance justifies them.
- If a rule only works with growing prohibitions, revise the activation predicate before
  adding another exception.
```

---

## Domain skills: specific rules

Domain skills capture **this project's** patterns, stacks, and conventions, making the harness assertive.

```text
- NEVER use the `pelizzai-` prefix (reserved for harness skills).
- Name with the project prefix + a descriptive verb: e.g. `<project>-generate-report`,
  `<project>-migrate-schema`.
- A skill for an external stack/lib must be **grounded in context7 or current official documentation**
  for the version pinned in the lockfile; without that grounding available, do not write the stack
  skill — ground it or defer (never invent from memory). A skill for an internal convention is
  grounded in the project's own code, tests, ADRs, and history, where `context7` is preferred,
  not a blocker.
- In a CONSUMER, every domain skill created/updated enters the catalog `pelizzai/domain-skills.md`
  and the ledger `pelizzai/data/review-domain-skills.md` (see Templates). In the PelizzAI source
  repo (sentinel `scripts/pelizzai-source-repo.txt`) that runtime does not exist: record the same
  facts in the native execution record and create no `pelizzai/` file.
```

### Skill roots in the consumer project

Detect the actually installed roots and record them in `pelizzai/profile.md`.

```text
PelizzAI source repo:
  edit .claude/skills and run sync-harness to generate .agents.

Consumer with one root:
  write the domain skill to the active root (.claude/skills OR .agents/skills).

Consumer with both:
  use the profile's canonical-skill-root, mirror the domain skill to the other root, and verify hash.
```

Never create a domain skill in a directory the current platform does not load. Catalog and ledger record the real path.

### Mandatory sync as part of the edit

Once the user has authorized creating, changing, or removing a skill, syncing the generated roots is
a mechanical part of that same change — do not ask for a second authorization:

```text
1. Edit only the canonical-skill-root.
2. If scripts/sync-harness.mjs exists, run automatically:
   node scripts/sync-harness.mjs
   node scripts/sync-harness.mjs --check [--source-mode in the source repo]
3. The sync-harness.ps1 and sync-harness.sh wrappers are equivalent entry points, not different
   implementations. Use whichever is available when `node` is not directly exposed to the agent.
4. When creating/removing a core skill in the source repo, include --update-manifest before --check.
5. Without a generation script, mirror per the profile and compare hashes.
```

Do not sync a maintenance proposal not yet ratified. After ratification, do not leave the canonical
skill and mirrors divergent, and do not hand this step off to the user.

---

## Bootstrap mode (called by `pelizzai-audit`)

Triggered in `bootstrap-write`, after `pelizzai-audit` has mapped the context and created the task branch. Scan-only does not call this mode. **Consumer only:** in the PelizzAI source repo there is no consumer bootstrap and no `pelizzai/` runtime — steps 4–5 below write nothing under `pelizzai/`; the equivalent record lives in the native execution record.

```text
1. Receive the evidenced inventory from pelizzai-audit (stacks, frameworks, modules, conventions,
   MCPs) and the active skill roots. If `context7` is missing, PROPOSE installing it before
   generating — without it, grounding falls back to the current official documentation exactly
   where the key MCP would make the difference, and a stack skill with neither source available is
   deferred, never written from memory.
2. List the CANDIDATE domain skills — the maximum number of useful skills the patterns justify
   (one per recurring flow/responsibility: build/deploy, code generation, tests, migrations,
   integrations, UI conventions, etc.). The filter is TRUTH, not scarcity: do not invent skills
   with no real pattern behind them, and do not cut a true candidate just to keep the list short.
   Each candidate names the observed pattern and the agent decision/error it changes.
2.5. GATE: present the candidate list to the user (name + what each would cover) and WAIT for
   confirmation before writing — creating skills writes files into their repository. They can cut,
   add, or adjust candidates; zero domain skills is a possible outcome WHEN they ratify it in the
   face of the proposal — the decision not to create belongs to the user, not to the classifier.
   If the bootstrap consent already included the candidates' names/scope, do not repeat the
   question; reopen the decision only if the scan materially changed the proposed set.
3. Write the confirmed candidates in PARALLEL with `pelizzai-team` — one candidate skill per
   member, each grounding theirs via context7 or, when it is unavailable, the current official
   documentation; defer the skill only when neither source is. **Scale with the number of candidates:** 5
   confirmed candidates are 5 fronts, not a queue. With a single candidate (or when a team would
   be unnecessary), delegate via `pelizzai-subagents`. Members who WRITE skills need WRITE
   capability (general-purpose or a subagent with write tools) and access to context7/official
   docs — read-only agents serve only for grounding research/reading, not for writing the skill.
   DISJOINT PATHS: each member writes ONLY its own candidate's file, one writer per file. No
   member touches the catalog, the ledger, the generated mirrors, or the manifest — those are the
   coordinator's, serially, in 5.5.
4. For each skill: follow the authoring rules and validate the frontmatter. CONSUMER ONLY: record
   it in the catalog and the ledger (including the origin: repo-scan or interview). In source mode
   the same facts go to the native execution record — no file under `pelizzai/`.
5. CONSUMER ONLY: seed the ledger (`last-review`/`last-full-scan`) with the **bootstrap date
   (today)** — the skills are born from the repo-scan of the current HEAD, so the bootstrap IS the
   first review; seeding with a mature repo's 1st commit fires a spurious nudge on the very first
   task. Write the catalog `pelizzai/domain-skills.md` — its existence marks the bootstrap as
   complete. See Templates. In source mode this step does not run: there is no catalog, no ledger,
   and nothing marks a consumer bootstrap.
5.5. SERIAL, COORDINATOR ONLY, after every member has returned: run the sync ONCE for the whole
   batch (§Mandatory sync as part of the edit), plus `--update-manifest` before `--check` when a
   core skill was created in the source repo. Never let members sync in parallel — concurrent runs
   regenerate the same mirrors and leave divergent hashes.
6. Offer to install the cadence hook (opt-in; see `references/domain-skill-maintenance.md`).
7. Present the user the catalog of created skills, with diff and validation — nothing is final
   without their sign-off. Ask for a new decision only for scope/content not covered by the
   existing authorization or for external effect.
```

> In a **new** project (no code), there are no patterns to extract: first complete sequential
> discovery, design, stress-testing, and an approved spec. Then propose domain skills grounded in
> the ratified stack and design; write only the ones the user chooses, and only then move on to
> the plan.

---

## Maintenance mode

Keeps the **domain** skills alive as the project evolves. Full detail in **[references/domain-skill-maintenance.md](references/domain-skill-maintenance.md)**. Three axes — two **update** what already exists, one **creates** the first skill for a new stack:

> **Scope (non-negotiable):** proactive detection across the three axes and the cadence acts only
> on domain skills and only proposes changes. Harness skills (`pelizzai-*`) are never changed
> without the user's explicit request.

- **Version-driven (refresh — UPDATES):** the stack changed major version or gained a significant dependency → re-read the current version's docs (context7) and **update** the affected existing skill. Drift is detected by comparing the current manifests against the **Stack baseline** in `pelizzai/profile.md` (written by `pelizzai-audit` at bootstrap).
- **Rework-driven (history — UPDATES):** the same fix was made by hand several times in git → the pattern becomes a rule in the existing skill.
- **Adoption-driven (new stack — CREATES):** the task adopted a significant dependency/service **not yet covered** by a catalog skill (new top-level in the manifests, absent from the **Stack baseline** and the catalog) → **propose CREATING** the first skill for that stack, **grounded in context7 or current official documentation** for the pinned version — not just updating. The proposal is ALWAYS presented at closeout, grouped; create/defer/don't-create is the user's decision. It is the only axis that CREATES outside bootstrap: it tracks the stack's evolution between bootstraps instead of letting coverage age until the next repo-scan.

<HARD-GATE>
**Refresh never overwrites blindly.** When updating an existing skill: read the current skill,
change **only** what the new version/pattern requires, **preserve the customizations** the project
added, and **show the diff to the user BEFORE writing**. Approval is **per skill** — never in bulk,
never implicit in the "yes" given to another. Recreating a skill from scratch on top of another is
forbidden.
</HARD-GATE>

An update is always **propose → confirm → apply → record**. There is no "hands-free" mode. In an
edit the user already requested, the proposal is the diff itself: show it before writing, within
the requested scope, without reopening the authorization they just gave.

---

## Cadence and triggers (hybrid)

Self-maintenance combines **portable logic in the skill** (core) with a **reinforcement hook** in Claude Code. Detailed mechanics in **[references/domain-skill-maintenance.md](references/domain-skill-maintenance.md)**.

```text
- When CLOSING a task (core, portable — valid in .claude/.agents/.cursor; PRIMARY TRIGGER):
  read the ledger, count commits since `last-review` (git rev-list --since) and the elapsed days.
  If >= 10 commits OR > 10 days → propose the review ONCE ("warn once, never block").
  The DAYS axis is the anchor (short cadence); commits only bring it forward in a real burst.
- Full repo-scan: if > 15 days since `last-full-scan` → propose a re-scan and a broad update.
- Every 10 interactions (reinforcement hook, Claude Code only): a safety net that checks the git
  delta and injects a reminder when the threshold is crossed, with 7-day suppression after
  warning. See `references/domain-skill-maintenance.md` and the script
  `.claude/hooks/pelizzai-cadence.mjs`. Opt-in: installed at bootstrap with confirmation.
```

The thresholds (10 commits / 10 review days / 15 full-scan days / 10 interactions / 7 suppression days) are deliberately short to keep maintenance close to the real work; tune them to the project's rhythm. Nothing in the cadence **blocks** the user's work — it only suggests.

---

## Ledger and catalog

Two artifacts per **consumer** project, created/updated by this skill (in the source repo neither
exists: the native execution record takes their place and no `pelizzai/` runtime is created):

- **`pelizzai/domain-skills.md`** — catalog: what each domain skill does and when to use it. Template: [templates/domain-skills.md](templates/domain-skills.md).
- **`pelizzai/data/review-domain-skills.md`** — ledger: per skill, creation date, last update, last commit/ref reviewed, the axis of the change, and the origin (repo-scan/interview); + global `last-review` and `last-full-scan`. Template: [templates/review-domain-skills.md](templates/review-domain-skills.md).

In a consumer, seed the ledger with the **bootstrap date (today)**, in new and existing repos alike — the bootstrap just created the skills from the current HEAD, so "last review = now". In source mode there is no ledger to seed. Seeding with a mature repo's 1st commit makes `daysReview`/`commits` born already past the threshold and fires a spurious nudge on the first task. `count=0` on bootstrap day is correct (it climbs as new commits arrive). See `references/domain-skill-maintenance.md` → "Seeding".

---

## Description optimization

Once a skill is ready, you can **optimize the `description`** to improve triggering (fight under-triggering). See `references/skill-authoring.md` (sections "Frontmatter" and "Leading words"). Golden rule: the `description` says what the skill does **and** lists the contexts/phrases that should trigger it — and **never summarizes the workflow steps** (the agent follows the summary and skips the body). **Front-load the skill's leading word** — the anchor word that already carries the behavior in pretraining (*seam*, *red*, *tracer bullet*).

---

## Anti-patterns

```text
- Overwriting an existing skill without reading/preserving customizations or without showing the diff.
- Auto-applying skill updates in "hands-free" mode (failed in the field in the previous harness).
- Creating a domain skill with the `pelizzai-` prefix, without adequate evidence, or in an
  inactive root.
- Overfitting the skill to the test cases instead of generalizing.
- Bloating SKILL.md past ~500 lines instead of using `references/`.
- Inventing domain skills with no real project pattern behind them.
- Letting the cadence block the work, or repeating the nudge more than once.
- Forgetting to update the catalog and the ledger after creating/changing a skill.
- Making a behavioral edit without a baseline/eval/forward-test proportional to the risk.
- Summarizing the workflow in the description (the agent follows the summary and skips the body).
- A vague trigger that contends for every request without naming the near misses (skill storm) —
  or one so narrow the skill never fires (under-triggering, the dominant failure).
- Cutting a true candidate to "keep the set small", or writing N candidates in a queue when the
  team would write them in parallel.
- Duplicating the same domain skill across roots without verifying parity.
```

---

## Condensed operating flow

```text
1. Identify the mode: Authoring (new skill) or Maintenance (update existing ones).
2. AUTHORING: capture the intent → gather evidence → proportional baseline → write the minimal
   skill → validate/forward-test → record in catalog and ledger when it is a domain skill.
3. BOOTSTRAP: generously enumerate the true candidates → CONFIRM the list with the user
   (gate 2.5) → write in parallel (team; a subagent when there is just one) → sync roots →
   catalog → seed the ledger → final user acceptance.
4. MAINTENANCE: detect the axis (version/history/adoption) → version/rework read the existing
   skill and change only what is needed; adoption PROPOSES creating the new stack's skill
   (context7/current official docs) → confirm when the proposal is proactive → validate
   proportionally → show the diff → record in the ledger with the axis.
5. CADENCE: when closing the task, check the ledger and propose a review if the threshold was
   crossed.
```

---

## Integration

**Combines with:**

- `pelizzai-audit` — calls this skill at bootstrap; the domain-skill creation engine lives here.
- `pelizzai-team` — write many candidate skills in parallel; `pelizzai-subagents` for delegation to a single subagent.
- `pelizzai-reasoning` — reasoning for authoring (Structured Decomposition) and maintenance (Critique and Refine, Evidence Synthesis).
- `pelizzai-interview-me` / `pelizzai-brainstorming` — the new-project branch, before creating the first skills.
- `pelizzai-writing-clearly-and-concisely` — write skill bodies with clarity.

---

## Final instruction to the agent

```text
Create skills that generalize and keep them alive without ever destroying the work of those who
came before.

Prefer:
- grounding in context7 over trusting memory, without treating documentation as the user's decision;
- enumerating the candidates the patterns justify over shrinking the list for scarcity;
- writing in parallel (one candidate per member) over queueing confirmed candidates;
- showing the diff over overwriting;
- propose-and-confirm over "hands-free";
- references/ over a giant SKILL.md;
- cataloging and recording over letting maintenance depend on human memory.

Every domain skill enters the catalog and the ledger.
No skill update is applied without the diff and the user's confirmation; approval is per skill
and comes with the evidence.
Incremental creation (the adoption axis) follows the same propose→confirm and never writes a
stack skill without grounding in context7 or current official documentation.
The cadence suggests; it never blocks.
```
