---
name: pelizzai-audit
description: Harness bootstrap and project mapping, in two modes. This is the skill that initializes PelizzAI in a project or workspace — invoke it on the user's FIRST contact with the harness, whenever they type "bootstrap", "remap", "rescan", or "reinitialize", and whenever the harness has not yet been initialized here (no `pelizzai/domain-skills.md`). Use `scan-only` for read-only analyses/reviews that create no files; use `bootstrap-write` when the user authorizes preparing the catalog, profile, and domain skills. A purely conceptual question does not trigger it. Never run a consumer bootstrap in the PelizzAI source repo itself.
---

# PelizzAI Audit

<FIRST-TIME-USING-PELIZZAI>
The **first time** the user interacts with the PelizzAI harness in this project, or whenever they
type **"bootstrap"**, this skill **MUST** be invoked before any work — at minimum in `scan-only`.
Without this mapping, the harness works blind.

The harness is initialized in this project when the file `pelizzai/domain-skills.md` exists. If it
does **not** exist, treat this as the first time: map the project and actively PROPOSE the
bootstrap, without waiting for the user to discover it exists. Invoking is mandatory; **writing
still depends on the user's answer** (see *Choosing the mode*).
</FIRST-TIME-USING-PELIZZAI>

## Goal

Map the working context so the harness acts with precision — what the project is (single or
workspace, new or existing), what it is built with, what infrastructure already exists — and, when
authorized, turn each finding into a useful artifact: the domain skills and documentation that make
the agent assertive. A versionable, portable bootstrap, never a report for its own sake.

**Announce**, in the conversation's language: that you are using the PelizzAI Audit skill in `<scan-only|bootstrap-write>` mode to map the project proportionally.

## Choosing the mode

| Mode | Trigger | May write? |
| --- | --- | --- |
| `scan-only` | analyze, explain, review, diagnose; a mutating task still without bootstrap authorization | No. No state, branch, profile, catalog, ledger, hook, or skill. |
| `bootstrap-write` | the user said `bootstrap`/`reinitialize`, or approved the proposal after a scan | Yes, inside the task branch created before the first write. |

A read-only request never becomes a mutating bootstrap just because `pelizzai/domain-skills.md` does not exist.

## Source mode

If the sentinel `scripts/pelizzai-source-repo.txt` exists, treat the project as the PelizzAI source repo. Do not create a consumer `pelizzai/`; do only the scan the task needs. The presence of a manifest/sync-harness does NOT indicate a source repo — consumers installed via `-ExportConsumer` have them too.

## Proportional depth

```text
small project/simple stack
→ focused inline inspection.

monorepo or multiple independent fronts
→ read-only subagents/team when they cut latency or raise coverage.

new/empty project
→ do not implement or invent patterns; route first through the greenfield cycle of discovery,
  spec, and approval.
```

Team is not the default. Use it only when the fronts are independent and the synthesis is worth the cost.

## Scan-only

Answer the relevant questions without turning the scan into a universal inventory:

```text
Structure: single repo, monorepo, or multi-repo workspace?
Stack: manifests, lockfiles, frameworks, runtime, database, and key versions?
Execution: real test/build/lint/dev commands and their directories?
Conventions: instructions, linters, tests, commits, design system, and repeated patterns?
Git: current branch, real default, remotes/provider, CI, and working tree?
Skills: installed roots, existing domain skills, and catalog?
Tooling: MCPs/connectors that actually change this task?
```

Separate observed facts from inferences. Do not write a generic report when the request only needs a localized answer.

After identifying the real stack and versions, consult Context7 for the external components that
could change the route, the skill candidates, or the recommendations. Do not consult a generic
version when the lockfile/manifest provides the installed one; do not consult irrelevant
technology just to pad the inventory.

When finishing scan-only:

- deliver the requested analysis;
- at the design→plan and plan→execution edges, proactively PULL the domain-skills proposal (do not wait for the user to type `bootstrap`) — see **Proactive domain skills gate**; ask for consent once;
- do not create placeholders to "prepare later".

## Proactive domain skills gate (design→plan and plan→execution edges)

The stack classification and the candidate list are computed, but they become a **recommendation to
ratify**, never a silent write. Pull the proposal at the high-value edges, without waiting for the
user to type `bootstrap`:

- **design→plan (new project):** after the spec/design is approved, detect the chosen stack;
  propose domain skills grounded in `context7`/official docs before the plan.
  The plan does not start until the user chooses to create, trim, defer, or record zero skills.
- **plan→execution (existing project):** before fixing the build lane, if a mutating task's stack is not covered by the catalog (absent, OR present but not covering that stack), propose all the domain skills that would close that gap and prevent agent error.

**Who invokes this gate (it is not just the audit's own self-service):** `pelizzai-idea-generation`
triggers it at the design→plan edge, as a numbered step of closing the design edge;
`pelizzai-writing-plans` triggers it as a safety net before Task 1, when the plan's stack has no
coverage in the catalog (or the catalog is absent). At those two points, the `pelizzai-router`
kickoff already announces in the Artifacts that the stack's domain skills will come as a proposal
at the design edge.

A one-question gate, with a recommendation:

```text
I detected the ratified stack <X, Y, Z>. I propose <N> domain skills: [name — decision/error it corrects],
grounded in context7/official docs for the version pinned in the manifest.
Recommendation: <create all | subset> — <one-line reason>.
Question: create the recommended ones, adjust the set, or proceed with none for now?
```

After the answer about skills, ask separately the opt-in question about arming maintenance
(Stack baseline + ledger + hook), also with a recommendation. Do not hide two decisions inside a
single checkbox.

Zero domain skills is valid only when ratified against the proposal. "First interaction" does not
trigger writing by itself; greenfield triggers discovery and, after the spec is approved, this
proposal. Nothing is written without an explicit answer. Context7 provides the skill's technical
grounding; it does not decide whether the project wants the skill.

Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP), produce no route analyses and open no gates: apply the briefing and escalate to the coordinator whatever requires a decision.

**Source mode** (PelizzAI source repo): this gate does NOT run; domain rules, if any, live in the native execution record.

## Bootstrap logical flow

```mermaid
flowchart TD
    Start([First contact OR bootstrap]) --> Mode{Does the request mutate files?}
    Mode -- No --> Scan[scan-only: context inventory\nteam/subagents only when worth it]
    Scan --> Gate[Proactive domain skills gate:\nrecommends; the user ratifies]
    Mode -- Yes, authorized --> Iso[pelizzai-starting-branch:\nisolate before the first write]
    Gate -- ratified --> Iso
    Iso --> Kick[Compact confirm: setup\n+ reviewer capability\n→ kickoff: ratified]
    Kick --> Inv[Inventory: structure, stacks,\nMCPs, git/host, skills, conventions]
    Inv --> New{New or existing project?}
    New -- New --> Bra[pelizzai-interview + pelizzai-idea-generation:\ndiscovery, spec, stress, approval]
    Bra --> Wri
    New -- Existing / Workspace --> Rep[Full repo-scan:\npatterns, stacks, frameworks, conventions]
    Rep --> Wri[pelizzai-create-skill:\ncreates the maximum of useful domain skills\nwith context7 + Anthropic rules]
    Wri --> Doc[Harness artifacts: domain-skills.md\ncatalog + ledger + profile.md]
    Doc --> Rec[Recommendations: git init, remote,\nstack MCPs, context7, opt-in hooks]
    Rec --> Rev[Standalone change review:\nquality lens + Verification\nno blind lens — no contract]
    Rev --> Seal[Commit exact paths →\npelizzai-final-verification →\nvalidated-head → pelizzai-finish]
    Seal --> End([Harness ready to act])
```

## Bootstrap-write

### 1. Isolate before writing

If Git exists, invoke `pelizzai-starting-branch` and create a task branch such as
`chore/bootstrap-harness` before any file. If there is no Git, offer `git init`; if the user
declines, explain that there will be no history/rollback and proceed only with authorization.

The bootstrap is its own transaction. Its artifacts must be committed/integrated or stay on the same task branch before a feature worktree depends on them.

**Ratify the bootstrap before the first artifact.** Base and branch name were just ratified by
`pelizzai-starting-branch`. What is still unratified is the setup, and it has no other gate: the
bootstrap has no plan, so it never reaches the post-plan setup gate of `pelizzai-execute`, and it is
neither `tweak` nor `bug`, so no light-track confirm covers it. Present ONE compact line — in the
conversation's language — and wait:

```text
Bootstrap on <branch> — isolation: branch · execution-mode: inline · commits: granular.
Closing review (stated, not offered): quality lens only, no blind lens — the bootstrap has no
contract for it to judge. Reviewer available here: <yes, independent | NO — none dispatchable>.
Ok, or name what to change?
```

The review's FORM is not one of the items to adjust — it follows from the contract, and there is no
second answer to offer (`pelizzai-execute` → "The review is deliberately NOT a gate item"). What can
genuinely be answered is the **capability**, and only when it is missing: that has three answers,
and they are the user's.

**Check the reviewer specifically.** Being able to parallelize the repo-scan does not prove a
reviewer is dispatchable. If this environment cannot dispatch one, say so HERE and open the
degradation choice (`pelizzai-review` → "When there is no independent reviewer") — not at step 7,
with every artifact already written. The bootstrap does not advance to the first write until the
user has chosen (a), (b), or (c): the recommendation is not an answer, and silence is not an answer.

**Record after the "ok"** (or after the named overrides), in the consumer `pelizzai/data/state.md`
that `pelizzai-starting-branch` just wrote: `track: bootstrap`, `kickoff: ratified <YYYY-MM-DD>`,
`isolation`, `execution-mode`, and `commit-strategy` — plus a `review-integrity: degraded` entry
(date and reason) if the user took option (b). **In the bootstrap, this skill is the sole owner of the
kickoff marker.** Without it the writegate blocks (Rule B) the very domain skills the user just
ratified, and `pelizzai-final-verification` refuses to seal at step 7 — the bootstrap would write
`state.md` and then be locked out by its own harness.

### 2. Detect skill roots

Record in `pelizzai/profile.md` the roots actually installed:

```text
source-mode: false
skill-roots:
  - .claude/skills   # if it exists/is used
  - .agents/skills   # if it exists/is used
canonical-skill-root: <active root>
```

`pelizzai-create-skill` writes domain skills to the active root; if both are installed, it keeps byte-for-byte copies and verifies parity.

### 2.5. Anchor the entrypoints

Run `node scripts/sync-harness.mjs` once. It anchors the harness contract — the
`<!-- pelizzai:contract -->` block derived from the shipped asset
(`.claude/skills/pelizzai-audit/assets/contract.md`) — into `CLAUDE.md`, `AGENTS.md`, and
`GEMINI.md`: **absent → created; present → the block is appended, the project's own content
untouched; block tampered or outdated → resynced in place**. `dist/` ships no entry files on
purpose — this step (or any later sync) is what creates them, so a copy-install works on a
virgin project AND on a project that already has its own entry files, without clobbering either.
The same command is the repair path whenever a session notices the block missing (the
session-start hook nudges exactly that).

### 3. Propose the maximum of useful domain skills

In an existing project or workspace, first do the **full repo-scan** — patterns, stacks,
frameworks, languages, conventions, and extension points. From the observed patterns comes the
proposal: the **maximum of useful domain skills** for the agent to work correctly in this project.
Broad coverage is the target; the filter is "useful", not "few". `pelizzai-create-skill` writes
each candidate grounded in the `context7` MCP (real documentation of the libs/frameworks at the
version pinned in the manifest) and in Anthropic's skill-creation rules.

Signals that raise confidence in a candidate — quality criteria to order the proposal and guide
the writing, **never a conjunctive door** that vetoes candidates:

```text
- a recurring, project-specific pattern/invariant exists;
- loading it would change a decision or prevent a real agent error;
- there is evidence in the repo, approved design, or official documentation to ground it;
- it is not yet covered by existing instructions/skills — partial coverage becomes a
  complementary cut, not a reason to discard.
```

A candidate with few signals goes lower in the order, with a one-line reason — it is not silently
discarded. What prevents noise is each skill's value, not a quantity cap: a skill per folder, file,
or generic tool is not coverage. The proposal grows with the project's real patterns, not with the
directory tree.

Zero domain skills is a possible outcome WHEN the user ratifies it against the proposal — the decision not to create is the user's, not the classifier's.

ALWAYS present the candidates (name + error they prevent) and wait for confirmation before writing them — the proposal is presented in full, including when the recommended set is small or empty, and the user may create all, trim, defer, or decline. For an external stack/lib, the skill must be grounded in `context7` or current official documentation for the pinned version; for internal rules observed in the repo, `context7` is preferred, not a blocker.

### 4. Create the artifacts

The persistent bootstrap leaves:

- `pelizzai/domain-skills.md` — the catalog, including `_none for now_` when applicable;
- `pelizzai/data/review-domain-skills.md` — the ledger seeded with the current date/HEAD;
- `pelizzai/data/verification-standard.md` and `pelizzai/data/learnings.md` — the
  self-optimization pair, seeded from `pelizzai-evolve/templates/` (their format authority):
  what "correct" means here, filled from the REAL commands/criteria confirmed with the user, and
  the execution memory, born empty — never pre-filled with guesses;
- `pelizzai/profile.md` — real commands, package manager, **Stack baseline** (the drift anchor for the version/adoption axes), and skill roots; also record the **Ratified execution defaults** section with every field at `<unset>` — the bootstrap does not guess policy; the user ratifies it at the post-plan gate;
- `pelizzai/.gitignore` — scoped protection of the ephemerals and of the per-dev cursor;
- `pelizzai/.gitattributes` — union merge for the append-shaped shared memory.

Mandatory content of `pelizzai/.gitignore`:

```gitignore
data/state.md
data/.cadence-state.json
data/handoffs/
data/mockups/
data/reports/
```

Mandatory content of `pelizzai/.gitattributes`:

```gitattributes
data/learnings.md merge=union
data/history/learnings-*.md merge=union
```

`data/review-domain-skills.md`, `data/learnings.md`, and `data/history/` are **versioned** — a
durable record; they never go into the ignore (a broad `data/*` with exceptions would silence
`history/` and break the durability of the sealed-task record). `data/state.md` is the one
deliberate exception: the cursor is **local per dev** (issue #43) — with it versioned, every
developer's closure commit edits the same singleton file and concurrent MRs conflict by
construction; the durable record of each task is the `data/history/<YYYY-MM-DD>-<slug>-<sha7>.md` file
(unique by construction, across branches too — `<sha7>` comes from the task's `validated-head`,
per the seal migration in `pelizzai-finish` — conflict-free) that the seal migration creates. `merge=union` on
`learnings.md` keeps concurrent appends from conflicting; its residual risk is an occasional
duplicated line and arbitrary ordering of concurrently appended lines — visible and benign for
append-shaped content — never a silent conflict. Verify with `git check-ignore` using
temporary proof files; remove the proofs afterward.

Create on demand, not at bootstrap: `context.md`, `adr/`, `out-of-scope/`, `specs/`, `plans/`, and the ephemeral directories.

**Arming maintenance is a first-class outcome, even with zero skills.** The minimal initialization (arm-only) writes the profile (Stack baseline + skill roots + real commands), seeds the ledger with today's date, and offers the cadence hook — without requiring any skill to be created (`_none for now_` is a valid catalog). Treat "arm maintenance" as a ratifiable item distinct from "create skills": without the anchor (Stack baseline + ledger), the version/adoption/rework axes and the cadence have nowhere to fire later — the machinery dies at the origin.

### 5. New project

With no code/patterns, use the greenfield cycle: `pelizzai-interview` one question at a time →
full `pelizzai-idea-generation` → stress → approved spec. Then apply the **Proactive domain skills
gate** before the plan, create only the ratified ones, and record them in the catalog/ledger. If
the original request includes building the product, continue to `pelizzai-writing-plans`; if it
asked only for bootstrap/design, stop at the approved scope.

### 6. Hooks and integrations

Claude hooks are opt-in and separate. On a consumer's first mutating interaction, run
`node scripts/install-hooks.mjs --check` in read-only mode. If they are absent, offer to install
the **opt-in Claude Code hooks** — **one by one, with confirmation; never impose** — explaining
the effect of each. Do not reopen the offer once the check passes:

- **Cadence hook** (`pelizzai-cadence.mjs`/`.ps1`, `UserPromptSubmit`): non-blocking reminder to
  review the domain skills (see `pelizzai-create-skill` →
  `references/domain-skill-maintenance.md`); a no-op without a ledger.
- **Git guard hook** (`pelizzai-guardrails.mjs`/`.ps1`, `PreToolUse` matcher `Bash`): blocks,
  before they run, `push --force` (except `--force-with-lease`), `reset --hard`, `clean -f`,
  `branch -D`, `checkout .`, and `restore .` — executable enforcement of the fail-closed gates
  that, without it, depend only on model obedience.
- **SessionStart hook** (`pelizzai-session-start.mjs`/`.ps1`, matcher
  `startup|resume|clear|compact`): re-injects the harness entry point (core → router), warns of an
  active task in `state.md`, and recaps the already-ratified execution policy — most valuable on
  `clear` and on platforms that do not re-inject the always-loaded entry point.
- **Writegate** (`pelizzai-writegate.mjs`/`.ps1`, `PreToolUse` on the matchers
  `Write|Edit|MultiEdit|NotebookEdit` **and** `Bash`): fail-closed safety net that blocks product
  writes on a protected/detached branch (Rule A) and, in a consumer, while `kickoff: ratified` is
  not yet recorded in `pelizzai/data/state.md` (Rule B — skipped in source mode, where the marker
  lives in the native execution record) — it moves the invariant "isolation before the first
  write" from model obedience to executable enforcement.
  It does NOT enforce the greenfield approval steps: the kickoff menu remains the harness's, not
  the hook's. Fail-open on any error of the hook itself (always exit 0 when it cannot decide).

Only edit settings after confirmation, and respect the granularity of the answer: use
`node scripts/install-hooks.mjs` when the user accepts all four. If they accept only a subset, use
`--only <ids>` (`guardrails`, `writegate`, `cadence`, `session-start`, comma-separated) and pass
the same `--only` to `--check` and `--remove` — never batch-install what was not accepted, and do
not hand-edit `.claude/settings.json` for a subset the installer already handles in its canonical
form. `--only` is additive (it does not drop a hook the user had already accepted), bare `--check`
is an inventory in which a deliberate partial install is not a failure, and `--check --only <ids>`
turns into a turnstile that requires exactly those hooks. The installer merges
`.claude/settings.json` without overwriting existing hooks/permissions and is idempotent. The
export may register them immediately only when the user explicitly chooses `--install-hooks`.

`PreToolUse` has **two** groups: the writegate also runs on `Bash`, otherwise writes via
redirection/heredoc slip past the gate. This is how `scripts/install-hooks.mjs` writes it:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "node \"$CLAUDE_PROJECT_DIR/.claude/hooks/pelizzai-guardrails.mjs\"" },
          { "type": "command", "command": "node \"$CLAUDE_PROJECT_DIR/.claude/hooks/pelizzai-writegate.mjs\"" }
        ]
      },
      {
        "matcher": "Write|Edit|MultiEdit|NotebookEdit",
        "hooks": [
          { "type": "command", "command": "node \"$CLAUDE_PROJECT_DIR/.claude/hooks/pelizzai-writegate.mjs\"" }
        ]
      }
    ]
  }
}
```

Cadence and SessionStart live on their own events (`UserPromptSubmit` and `SessionStart` with
matcher `startup|resume|clear|compact`).

The `.mjs` hooks and the Node installer are portable across Windows, macOS, and Linux; the `.ps1`
variants remain as a Windows fallback. Context7 is the preferred technical integration: verify its
availability at bootstrap and use it whenever an external stack/API/version matters. If absent,
recommend configuring it for the platform; current official documentation is the fallback, not
memory.

Close the bootstrap with the environment recommendations — recommend, do not impose; any action
that changes the environment waits for confirmation:

```text
- No Git → suggest `git init` (the harness works better with history).
- No remote → suggest integrating with GitHub or GitLab.
- MCPs → research the most relevant ones for the identified stack and suggest them.
- context7 absent → suggest installing it: it is what grounds skills and answers in real
  documentation instead of guessing.
```

### 7. Validate and close

Before declaring the bootstrap done:

```text
[ ] entrypoints anchored: CLAUDE.md, AGENTS.md, and GEMINI.md carry the pelizzai:contract block
    (node scripts/sync-harness.mjs --check passes);
[ ] the catalog exists and matches the real skills;
[ ] ledger/profile have no placeholders (`<unset>` fields in *Ratified execution defaults* are valid state — policy not yet ratified —, not a placeholder to fill);
[ ] commands came from real manifests/scripts;
[ ] skill roots and parity were verified;
[ ] ephemerals pass git check-ignore;
[ ] the diff contains only approved artifacts;
```

Review the whole diff with `pelizzai-review` → **Standalone change review**: the bootstrap produces
its own artifacts with no plan, no task spec, and no approved requirement, so there is **no contract
for the blind spec lens to judge against** — the checklist above IS the conformance check, and it
belongs to the coordinator, not to a reviewer. The quality/evidence lens still goes out, to an
independent reviewer, in its own dispatch, with its `Verification` block. If this environment has
none, the choice was already made at step 1; do not discover it here.

**Loop bound:** 3 fix→re-review cycles over the whole diff. The bootstrap is ONE transaction, not a
sequence of tasks, and there is no second counter because there is no second lens — a loop over
artifacts the audit itself regenerates would otherwise have no limit at all. On blowing it, stop
dispatching, record `phase: blocked`, leave the working tree INTACT, and escalate with an actionable
message, in the shape of `pelizzai-execute` → `references/task-cycle.md` §5.

Then commit the approved artifacts with exact paths, and only then run
`pelizzai-final-verification` against that HEAD. After recording `validated-head`,
close the transaction via `pelizzai-finish`. Do not leave the bootstrap uncommitted or expect
pelizzai-finish to consolidate it.

## Partial state

- catalog exists, ledger missing → propose/repair only the ledger in write mode;
- `git ls-files -- pelizzai/data/state.md` lists the cursor (consumer bootstrapped before
  issue #43) → propose the one-time migration in write mode: `git rm --cached
  pelizzai/data/state.md`, update `pelizzai/.gitignore`, add `pelizzai/.gitattributes` per the
  mandatory contents above; read-only just reports it;
- `verification-standard.md`/`learnings.md` missing (consumer bootstrapped before the evolve
  cycle) → propose creating only them from `pelizzai-evolve/templates/` in write mode;
- an entry file (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md`) missing or without the
  `pelizzai:contract` block → run `node scripts/sync-harness.mjs` (creates/repairs only the
  block; project content outside the markers is preserved);
- a skill exists outside the catalog → catalog it after confirming origin/content;
- outdated profile → update only the affected fields;
- read-only → just report the inconsistency.

## Canonical layout

```text
pelizzai/
├── .gitignore
├── .gitattributes
├── domain-skills.md
├── profile.md
├── context.md | context/           on demand
├── adr/ | out-of-scope/            on demand
├── specs/ | plans/                 on demand
└── data/
    ├── state.md                    ignored (local per-dev cursor — issue #43)
    ├── review-domain-skills.md     versioned
    ├── verification-standard.md    versioned (what "correct" means — pelizzai-evolve)
    ├── learnings.md                versioned (execution memory — pelizzai-evolve)
    ├── history/                    versioned (each task's intact block, migrated at the seal)
    ├── .cadence-state.json         ignored
    ├── handoffs/                   ignored
    ├── mockups/                    ignored
    └── reports/                    ignored
```

In a workspace with multiple repositories, do not pretend one scalar state covers them all: bootstrap per repo or explicitly declare which root owns the artifacts.

## Anti-patterns

```text
- Changing files in scan-only.
- Starting new-project scaffolding before discovery, spec, and an approved plan.
- Using Context7 as a substitute for product decisions or for the domain skills gate.
- Re-running the bootstrap in every new session.
- Skipping the bootstrap on first contact and starting to work blind.
- Cutting the domain-skills proposal by a quantity cap instead of by usefulness.
- Using a team on a repo that a focused inspection solves.
- Creating a profile with guessed commands.
- Writing a skill only to .claude when the active platform uses .agents (or vice versa).
- Declaring a directory gitignored without proving it in the consumer project.
- Leaving the bootstrap loose on main or invisible to the next worktree.
- Writing the first artifact without the compact confirm of step 1 — leaving `kickoff: ratified`
  unwritten locks the bootstrap out of its own domain-skill writes (writegate, Rule B).
- Demanding the blind spec lens over the bootstrap diff, or writing a spec after the fact so it has
  something to read: the bootstrap discovers the project, it does not implement a requirement.
```

## Integration

Uses `pelizzai-starting-branch` and `pelizzai-finish` only in `bootstrap-write`; `pelizzai-review` closes the bootstrap diff through the **Standalone change review** (quality lens only — the bootstrap has no contract for the blind lens, and that skill owns the rule) and `pelizzai-final-verification` seals `validated-head` before the handoff; `pelizzai-create-skill` writes the ratified domain skills — the target is the maximum of useful skills, grounded in `context7`; `pelizzai-team`/`pelizzai-subagents` parallelize the repo-scan when the fronts are independent; `pelizzai-idea-generation` enters only on the new/uncertain-project branch.
