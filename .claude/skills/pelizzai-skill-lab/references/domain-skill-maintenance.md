# Domain-skill maintenance — detailed mechanics

How PelizzAI keeps domain skills alive as the project evolves, with an opt-in hook only when the
project has authorized it. This document describes **proactive** maintenance: detection and
proposal. An edit explicitly requested by the user skips the cadence proposal but does **not**
skip the anti-overwrite lock — reading the current skill, changing only what is needed, and
showing the diff before writing applies in both cases.

## The three maintenance axes

Two axes **update** skills that already exist; one axis **creates** the first skill for a newly adopted stack.

| Axis                | Trigger                                                              | Action                                                            |
| ------------------- | -------------------------------------------------------------------- | ---------------------------------------------------------------- |
| **Version-driven**  | The major version of a Stack baseline item changed in the manifests   | Re-read the current version's docs (`context7`) and **update** the existing skill (refresh) |
| **Rework-driven**   | The same fix was made by hand several times in git history            | The repeated pattern becomes a **rule** inside the existing skill |
| **Adoption-driven** | The task adopted a significant dependency/service NOT YET covered by a catalog skill (new top-level in the manifests/lockfiles, absent from the Stack baseline in `pelizzai/profile.md` AND from the catalog) | **PROPOSE CREATING** the first skill for that stack, grounded in context7 or current official documentation for the pinned version — not just updating |

All three are **opt-in**: the harness detects, **proposes**, the user decides. They never run on their own.

### Version-driven (refresh)

```text
1. Detect the drift: compare the current versions (manifests, lockfiles) against the ones recorded in the ledger/skill and against the **Stack baseline** in `pelizzai/profile.md` (written at bootstrap by `pelizzai-onboard`).
2. Re-read the current version's docs via `context7` (without it, current official documentation — never memory).
3. Update the affected skill in refresh mode (see "Refresh never overwrites blindly").
4. Record in the ledger (axis = version-driven, new commit/ref, date).
```

### Adoption-driven (create from the manifest)

Version-driven and rework-driven only **update** what already exists. Adoption-driven is the only axis that **creates** outside bootstrap: it tracks the stack's real evolution between one repo-scan and the next, creating the first skill for a technology that arrived later. It only fires when a new, significant, uncovered stack enters the project.

```text
1. Detect the adoption: the manifests/lockfiles diff since `last-review` shows a new top-level,
   absent from the **Stack baseline** in `pelizzai/profile.md` AND from the catalog
   `pelizzai/domain-skills.md`.
2. Filter by leverage: only propose for significant external technology (framework, ORM/data,
   auth, payments, queue/sensitive infra). A trivial utility does not become a skill — the filter
   here is real leverage, not scarcity.
3. At the task's CLOSEOUT (read-only nudge from `pelizzai-finish`), present ONE grouped
   proposal — never a per-task gate (the quoted shape below is REFERENCE content: emit it in the conversation's language, identifiers verbatim): "The task adopted <lib@lockfile version>, with no domain
   skill covering it. Create one now, grounded in context7 or current official documentation?
   [create · defer · don't create]". Recommended: "create" for high-leverage libs; "defer" for a
   utility.
4. Only after a "yes": create ONE skill (a mini bootstrap-write of one skill) reusing the
   authoring engine, grounded in context7 or current official documentation for the pinned
   version — with no current docs available, defer (never invent from memory). Catalog it and
   record it in the ledger with axis = adoption-driven.
```

Coverage gaps flagged during consumption (inline/subagents/team execution touching a stack with no covering skill) feed this axis: they are collected and become ONE grouped proposal at closeout, never a mid-task creation. Drift/adoption detection is automatic (the intelligence stays); writing the skill requires a "yes" and never overwrites blindly — the same `propose → confirm → apply → record` as the other axes.

### Rework-driven (learning from history)

Git history is evidence of what the harness did well and of what required manual rework.

```text
1. Bound the window: from the ledger's `last-review` to HEAD (git log --since="<last-review>").
2. Look for patterns: the same kind of fix made by hand repeatedly; conventions the team applied
   consistently; errors that repeat.
3. For each recurring pattern, propose turning it into a rule inside the relevant domain skill.
4. Confirm with the user, apply (refresh), and record in the ledger.
```

## Refresh never overwrites blindly

Non-negotiable rule when updating an **existing** skill:

```text
- READ the current skill before any change.
- Change ONLY what the new version/pattern requires.
- PRESERVE the customizations the project added (do not recreate from scratch on top).
- SHOW the diff to the user BEFORE writing.
- RECONCILE the catalog entry (`pelizzai/domain-skills.md`) in the same step as any body edit:
  the router reads the catalog, not the skill, so a stale entry outlives and outreaches the
  corrected body. Consumer only — in the source repo the catalog does not exist; the native
  execution record takes its place and no `pelizzai/` file is created.
- Approval is PER skill — never in bulk, never inherited from the "yes" given to another skill.
  Without confirmation, nothing is written.
```

Recreating a skill from scratch on top of an existing one erases customizations and is forbidden.
The flow is always **propose → confirm → apply → record**. There is no "hands-free" mode (it was
tried in the previous harness and failed in the field). In an edit the user already requested, the
proposal IS the diff: show it before writing, within the requested scope, without reopening the
authorization they just gave.

## Cadence (triggers)

**Hybrid** model: portable core in the skill + reinforcement hook in Claude Code.

### Portable core (when closing the task)

Applies in the active skill roots (`.claude`/`.agents`); Cursor is just an adapter. This block is
the cadence's **primary trigger**: `pelizzai-finish` consumes it in the closeout's read-only
nudge (§5), a natural milestone that neither interrupts the flow nor blocks delivery. The hook
(Claude Code) is only a safety net, every 10 interactions. When completing a task that touched
code:

```bash
# ledger dates — parsing ANCHORED on the label (robust to line order; reads BOTH dates)
last_review=$(grep -oE 'last-review:[^0-9]*[0-9]{4}-[0-9]{2}-[0-9]{2}' pelizzai/data/review-domain-skills.md | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
last_full_scan=$(grep -oE 'last-full-scan:[^0-9]*[0-9]{4}-[0-9]{2}-[0-9]{2}' pelizzai/data/review-domain-skills.md | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
# commits since the last review
count=$(git rev-list --count --since="$last_review 00:00" HEAD 2>/dev/null || echo 0)
```

> Commands in sh/Bash; in a fleet without POSIX (e.g. PowerShell only), use the equivalent — the `.ps1` hook already implements the same label-anchored read.

```text
- Review threshold: count >= 10 commits OR > 10 days have passed since last_review.
  The DAYS axis is the anchor (a short, predictable cadence); commits only BRING FORWARD
  the nudge when there is a real burst of work. The cadence is deliberately short: field
  feedback showed that long thresholds let domain skills age without warning — better to
  remind early (advisory, once, with snooze) than too late.
- Threshold crossed → propose ONCE (reference shape; emitted in the conversation's language):
  "We have accumulated <count> commits / <days> days since the last domain-skill review.
   May I run maintenance (pelizzai-skill-lab) now? Proceed now or leave it for later?"
- Below the threshold → say nothing and finish.
- "Warn once, never block." If the user defers, do not repeat it in the same session nor
  for the next ~7 days (the hook persists that suppression window; see below).
```

Full repo-scan: if > 15 days have passed since `last-full-scan`, propose a broad re-scan (reusing `pelizzai-onboard`) and update the impacted skills.

### Reinforcement hook (every 10 interactions — Claude Code only)

The hook `.claude/hooks/pelizzai-cadence.mjs` is a `UserPromptSubmit` that counts interactions and, every 10, checks the git delta; if the threshold is crossed, it injects a short reminder. The thresholds are the same as the portable core's (10 commits / 10 review days / 15 full-scan days). Safety characteristics:

```text
- Silent no-op if there is no ledger (harness not yet initialized in this project).
- Only does the expensive check (git) on every 10th interaction; on the others, it only
  increments the counter.
- ALWAYS ends with exit 0 (never blocks the user's prompt).
- Swallows any error (missing git, etc.) without noise.
- Suppression: after emitting a reminder, it goes silent for 7 days (writes `snoozeUntil` to
  .cadence-state.json) — it does not repeat every window while the threshold stays crossed.
- The state is backward-compatible: an old `.cadence-state.json` (just `{count}`) remains valid.
```

> **Sampling ≠ nudge frequency.** `EVERY=10` decides how often the hook LOOKS; whether the nudge APPEARS is decided by the thresholds (10 commits / 10 days) + the 7-day suppression. Do not raise `EVERY` to high values (e.g. 100): that blinds the hook in short sessions without reducing the real warning frequency (already governed by the thresholds and the snooze).

Entry in `settings.json` (installed at bootstrap, with confirmation — opt-in):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "node \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-cadence.mjs\"" }
        ]
      }
    ]
  }
}
```

**Who installs it (opt-in):** at bootstrap, `pelizzai-skill-lab` **proposes** the installation; if the user accepts, it **merges** the entry into `.claude/settings.json`, preserving existing hooks and permissions (merge, **never** overwrite the file). In Claude Code, the `update-config` skill can perform this edit. Also add `pelizzai/data/.cadence-state.json` to `.gitignore` — it is mutable state (changes on every interaction) and must not be versioned.

**No-Node variant:** in a fleet without Node, use the PowerShell hook `.claude/hooks/pelizzai-cadence.ps1` (requires pwsh 7+), with the command `pwsh -NoProfile -File "${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-cadence.ps1"`.

**Assumption:** the hook locates the ledger from the `cwd` and assumes `pelizzai/` at the project root (harness convention; in a monorepo/workspace, `pelizzai/` is root-level).

> Why opt-in rather than on by default: a noisy `UserPromptSubmit` hook already "broke the flow" in a previous harness. The **portable core** (in the skill) is the source of truth; the hook is only reinforcement in Claude Code.

## Seeding and ledger updates

```text
- Seed `last-review` and `last-full-scan` with the BOOTSTRAP DATE (today) — NOT with the 1st
  commit's. The bootstrap just created the domain skills from the repo-scan of the current HEAD:
  they are the "first review", so the last review is now. Seeding with a mature repo's 1st commit
  makes `daysReview`/`commits` born already past the threshold → a spurious nudge on the first
  task, about freshly created skills. `count=0` on bootstrap day is correct (it climbs as new
  commits arrive). (In a new repo with no commits, today's date was already the value used — now
  it applies to both cases.)
- On every domain-skill creation/refresh, update the skill's row in the ledger
  (date, last commit/ref, axis) and the `## Log`.
- After a maintenance review, update `last-review` to the review date.
```

Ledger and catalog format: see `templates/review-domain-skills.md` and `templates/domain-skills.md`.
