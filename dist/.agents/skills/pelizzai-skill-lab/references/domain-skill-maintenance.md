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

Detection is automatic within an authorized task; adoption follows the project's recorded
maintenance authorization. Without that authorization, the harness proposes and the user decides.

## Select by evidence before opening skills

At closeout, compare changed paths with `pelizzai/atlas.md` and each skill's explicit territory.
Use the per-skill reviewed SHA in `review-domain-skills.md`, not a date alone:
`git diff --name-only <reviewed-sha>..HEAD -- <territory-paths>`. Include affected lockfiles.
Also inspect uncommitted changes in that territory; HEAD alone cannot clear ongoing work.
No change and no incident → skip the skill without advancing its reviewed SHA.
Missing territory, invalid SHA or missing ledger row → `unknown`, never `clear`.

For a due skill, record three verdicts (`clear`, `drifted`, `unknown`) with evidence:
code (paths/contracts still exist), use (the skill actually reached work in its territory),
and source (claims still hold for pinned versions). Absence of a skill name in history is not
proof of non-use when the execution trace is missing. Read only relevant history returned by
`scripts/project-memory.mjs --query`; archived failures remain eligible evidence.

The cadence offers a pass; these signals determine its contents. A calendar threshold alone
never warrants opening or rewriting every skill. A clean pass records what was checked, not
an invented improvement. Change only the canonical source, validate it, then sync mirrors.

## Bounded automatic adoption

Default: `propose`. A user may authorize `apply-approved` in the project profile, naming skills,
allowed mechanical edits, checks and expiry/review boundary. This standing authorization may
cover re-grounding moved references or correcting an already demonstrated instruction; it
never expands product behavior, security policy, acceptance standards or external effects.
No matching authorization → show the concrete diff for approval. A new standing rule or a
change to the verification standard still needs its own human decision.

For either mode: capture source hashes, prepare the smallest diff, run the regression that
motivated it plus existing checks, and compare hashes again before applying. If the source
changed, rebuild the proposal instead of overwriting. Record evidence, authorization origin,
changed skills, reviewed SHA and rollback. Never silently edit core `pelizzai-*` in a consumer.

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
1. Bound the window by the affected skill's last reviewed SHA and territory
   (`git log <reviewed-sha>..HEAD -- <territory-paths>`), including archived incidents. A global
   `last-review` date cannot exclude work in a skill skipped by another area's review.
2. Look for patterns: the same kind of fix made by hand repeatedly; conventions the team applied
   consistently; errors that repeat.
3. For each recurring pattern, propose turning it into a rule inside the relevant domain skill.
4. Check explicit approval or bounded standing authorization, apply (refresh), and record in the ledger.
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
- Each skill must be covered by explicit approval or the bounded standing authorization above.
  Approval of a different skill or a generic delivery does not authorize maintenance.
```

Recreating a skill from scratch on top of an existing one erases customizations and is forbidden.
The flow is **detect → concrete diff → validate → check authorization → apply → record**.
Unbounded hands-free rewriting is unsupported. In an edit the user already requested, the
proposal IS the diff: show it before writing, within the requested scope, without reopening the
authorization they just gave.

## Cadence (triggers)

**Hybrid** model: portable core in the skill + optional reinforcement hooks in Claude Code/Codex.

### Portable core (when closing the task)

Applies in the active skill roots (`.claude`/`.agents`); Cursor is just an adapter. This block is
the cadence's **primary trigger**: `pelizzai-finish` consumes it in the closeout's read-only
nudge (§5), a natural milestone that neither interrupts the flow nor blocks delivery. The hook
is only a safety net, every 10 interactions. When completing a task that touched
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

### Reinforcement hook (every 10 interactions — Claude Code and Codex)

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

Claude Code entry in `settings.json` (installed at bootstrap, with confirmation — opt-in):

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

**Who installs it (opt-in):** at bootstrap, `pelizzai-skill-lab` proposes installation. If accepted,
use `node scripts/install-hooks.mjs --platform <claude|codex> --only cadence`, preserving existing
hooks and permissions. Codex registration lives in `.codex/hooks.json` and still requires host
trust and observed dispatch; never copy Claude's environment-variable command into it. Also add
`pelizzai/data/.cadence-state.json` to `.gitignore` — it changes on interactions and is not versioned.

**No-Node variant:** in a fleet without Node, use the PowerShell hook `.claude/hooks/pelizzai-cadence.ps1` (requires pwsh 7+), with the command `pwsh -NoProfile -File "${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-cadence.ps1"`.

**Assumption:** the hook locates the ledger from the `cwd` and assumes `pelizzai/` at the project root (harness convention; in a monorepo/workspace, `pelizzai/` is root-level).

> Why opt-in rather than on by default: a noisy `UserPromptSubmit` hook already "broke the flow" in a previous harness. The **portable core** (in the skill) is the source of truth; the hook is only reinforcement when the host supports and dispatches it.

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
