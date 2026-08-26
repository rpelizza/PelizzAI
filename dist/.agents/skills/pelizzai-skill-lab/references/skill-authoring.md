# Skill authoring — detailed rules

An adaptation, for the PelizzAI harness, of Anthropic's skill-creation rules (skill-creator) and of field-tested lessons from mature reference harnesses. Read before writing a skill.

The goal is to change behavior observably with the least context necessary. A skill does not get better by being longer, more forceful, or more ritualized; it gets better when it triggers in the right context and blocks a real, observed failure.

## Contents

| Section | What it covers |
| --- | --- |
| Authoring flow | The steps, from intent to packaging |
| Skill TDD (RED-GREEN-REFACTOR) | The Iron Law: an observed failing baseline before writing |
| Evidence and behavioral validation | The ladder: which form of evidence each type of change requires |
| Versioned pressure tests | Behavioral regression scenarios kept alongside the skill |
| Meta-testing the failure | The agent that violated diagnoses its own skill |
| Frontmatter | The `description` as trigger — and never as a workflow summary |
| Leading words and the no-op test | Pretraining anchors; sentence-level pruning |
| Progressive disclosure / Anatomy | The skill's physical structure |
| Skill source and roots | Where to edit; generated mirrors; sync as part of the edit |
| Writing patterns | Imperative, why, examples |
| Degree of freedom | Principles, pseudocode, or script — per task fragility |
| Match the Form to the Failure | The form of the guidance matches the type of failure |
| Calibrated persuasion | Authority/Commitment/Scarcity/Social Proof yes; Liking/Reciprocity forbidden |
| Premature conclusion and post-completion steps | Completion criterion; real context boundaries |
| Scripts | When the operation becomes deterministic code |
| Wording micro-test / Evals | Cheap validation before the expensive one |
| Absence of Surprises / Completion criterion / Packaging | Safety, closeout, and distribution |

## Authoring flow

```text
1. Capture the intent    — what the skill should enable; when it should trigger; output format;
                           does it need evals?
2. Research              — Context7 (preferred) or current official documentation, for the
                           version actually used.
3. Failing baseline (RED) — run the scenario WITHOUT the skill and capture the rationalizations
                           verbatim (see "Skill TDD" below).
4. Choose the form       — principles, pseudocode/checklist, or deterministic script
                           (see "Degree of freedom" and "Match the Form to the Failure").
5. Write the SKILL.md    — the MINIMAL skill against the observed failures (GREEN), following
                           the patterns below.
6. Close loopholes       — re-run under pressure, close each gap (REFACTOR), and version the
                           scenarios as `test-pressure-<n>.md` in the skill's directory.
7. Evals (if applicable) — test cases for verifiable outputs (wording micro-test BEFORE the
                           expensive eval).
8. Iterate               — draft → fresh eyes → improve; generalize from feedback.
9. Optimize the description — to improve triggering (trigger conditions; never a process summary).
10. Close                — remove duplication, sync the applicable mirrors, record real
                           limitations; package only if distributing outside the repo.
```

Do not re-litigate a decision the user already ratified. When intent, scope, or format are still human decisions, stop and ask with `pelizzai-interview`, one question at a time, with the best recommendation marked; do not fill them with defaults. Do not research by reflex when the needed knowledge is in the project. For external facts that may have changed, prefer Context7 or official documentation — it grounds options, it does not decide for the user.

### 1. Capture the intent

If the current conversation already contains the flow the user wants to capture ("turn this into a skill"), extract from the history first: tools used, step sequence, user corrections, and input/output formats. Ask the user to fill gaps and confirm before proceeding.

Four anchor questions:

```text
1. What should this skill enable?
2. When should it trigger? (phrases/contexts)
3. What is the expected output format?
4. Does it need test cases? Objectively verifiable outputs (transforming a file, extracting
   data, generating code, fixed flow) benefit; subjective outputs (style, art) usually do not.
   Suggest the appropriate default, but let the user decide.
```

### 2. Research

Check the available MCPs. If useful (consulting docs, finding similar skills, checking best practices), research in parallel with `pelizzai-team`, delegate to a single subagent with `pelizzai-subagents`, or do it inline. **Prefer the `context7` MCP** to ground in the real documentation of the version pinned in the lockfile; without it, use current official documentation and state the limitation. Bring ready context to reduce the user's load.

## Skill TDD (RED-GREEN-REFACTOR)

> Writing skills **IS** Test-Driven Development applied to process documentation.

The Iron Law of authoring: **no new skill — and no behavioral edit to an existing skill — without an observed failing baseline.** The cycle:

```text
RED      — run the target scenario WITHOUT the skill, in fresh context, and observe the real
           failure. Capture the rationalizations VERBATIM ("the tests here are too trivial to
           be worth TDD", "I'll write the test afterward so I don't lose the flow") — THEY are
           what the skill must block, not the failures you imagine ahead of time. Without an
           observed failing baseline, you don't know whether the skill changes anything.
GREEN    — write the MINIMAL skill that blocks exactly the captured failures. Nothing against
           hypothetical failure: each rule exists because a real rationalization demands it.
REFACTOR — re-run WITH the skill, under pressure. Each new loophole the agent finds becomes a
           targeted fix (a new row in the rationalization table, a more foundational principle,
           reorganization) followed by a re-test. Version the scenarios used
           (see "Versioned pressure tests").
```

Scope of the law:

```text
- Applies to DOMAIN skills and to the harness skills (`pelizzai-*`).
- Applies to a NEW skill and to a BEHAVIORAL EDIT of an existing skill — any change that
  alters what the agent DOES.
- A purely editorial edit (typo, formatting, broken link) is NOT behavioral and needs no
  baseline.
- At bootstrap, the real pattern observed in the repo-scan/history plays the baseline's role —
  the failure has already been observed in the field. It is the same rule said another way: do
  not invent a skill without evidence of a failure or a real pattern behind it.
```

Why the law is hard: in a field-tested reference harness, the TDD skill needed **6 iterations** and **more than 10 unique rationalizations** captured and blocked one by one before reaching **100% compliance** under pressure. Without the RED baseline, each of those rationalizations would have survived invisible — the skill "looked good" on paper and failed in the field.

## Evidence and behavioral validation

The Iron Law demands evidence of real failure. This section says **which form** that evidence takes — a ladder, not a single ritual:

| Change | Typical minimum evidence |
| --- | --- |
| typo, link, or formatting | parser/link/static check |
| deterministic script or format | fixture + expected result + error case |
| safety or lifecycle rule | matrix of allowed and blocked commands/scenarios |
| routing/description | positives, *near misses*, and ambiguous cases |
| discipline under pressure | versioned pressure test, re-run before and after the edit |
| subjective guidance | criteria-based critique and contrasting examples |

The failing baseline is mandatory when the behavior is still unknown, the change is high-impact, or the agent tends to rationalize exceptions. Evidence already observed in the repository, in a regression, or in user feedback fulfills that role — it is real failure, just captured elsewhere. What does not qualify is imagined failure: do not fabricate a scenario to fill the table, nor demand a pressure-test file for every wording tweak.

For complex changes, do *forward testing*: give a fresh session only the request and the new skill, without revealing the desired diagnosis. Observe the chosen route and fix the instruction, not the test's answer.

## Versioned pressure tests (`test-pressure-<n>.md`)

Every scenario used to validate a discipline skill is **versioned alongside it**: files `test-pressure-1.md`, `test-pressure-2.md`, … in the skill's directory, next to the `SKILL.md`. They are reference documents **without frontmatter** (the `name`/`description` frontmatter is exclusive to `SKILL.md`). They are the **regression criterion**: any behavioral change to the skill re-runs the scenarios before and after the edit.

Anatomy of a good pressure scenario:

```text
- 3+ COMBINED pressures: time ("the deploy is in 20 minutes"), sunk cost ("you already wrote
  400 lines"), authority ("the tech lead said to skip it"), exhaustion ("it's the sixth
  attempt, it's 11 pm"), social ("everyone on the team does it this way"). One isolated
  pressure does not break the agent; the combination does.
- FORCED A/B/C options — one correct, the others tempting and defensible.
- The question is "what do you DO?", never "what should you do" — the conditional invites a
  theoretical answer; the present tense forces the decision.
- No easy way out: "I would ask the user" without choosing an option is an invalid answer in
  the scenario (in real life, asking may be right; in the test, it masks the decision).
```

Live scenarios in the harness, which serve as models of form and as real regressions:

- `.claude/skills/pelizzai-resume/test-pressure-1.md` — "just do a `reset --hard` and it's fixed" (urgency + authority + sunk cost + exhaustion).
- `.claude/skills/pelizzai-architecture/test-pressure-1.md` — "go ahead and refactor all five while you're at it".

A behavioral change to those skills re-runs the corresponding scenario before and after. The files are mirrored to the roots generated by `sync-harness`; edit only the canonical root (see "Skill source and roots").

## Meta-testing: when the agent violates with the skill loaded

Failed WITH the skill in context? Don't guess the fix: **ask the agent itself** how the skill should have been written so it would not have violated. Three diagnoses:

| The agent answers | Diagnosis | Fix |
| --- | --- | --- |
| "I knew the rule, but thought it didn't apply here" | ignored knowingly | a **foundational principle** is missing — the why that closes the negotiation |
| "the skill should say X" | literal gap | add **X verbatim** |
| "I didn't see section Y" | organization problem | **reorganize** — promote the section, shorten what comes before it |

A discipline skill is **bulletproof** when the agent: (1) chooses the correct option under maximum pressure; (2) **cites the skill's sections** when justifying the choice; (3) **admits the temptation** ("option B was attractive because…") — a sign it processed the conflict instead of not seeing it.

## Frontmatter

Only two fields, both required:

```yaml
---
name: kebab-case-name
description: What the skill does and the observable contexts in which it should be used.
---
```

- **name** — the skill's identifier (kebab-case), same as the directory name.
- **description** — **the trigger**. It is the primary triggering mechanism. Include **what the skill does AND the specific contexts of use**. All "when to use" information goes here, not in the body.

> Note: the harness tends to **under-trigger**. Make descriptions "incisive". Instead of "Creates an internal data dashboard", write "Creates an internal data dashboard. Use whenever the user mentions dashboards, data visualization, or metrics, or wants to display any company data — even without explicitly asking for a 'dashboard'."

Incisive is not vague. Both failures are real and are fixed together:

```text
- Under-triggering (dominant failure): the description cites only the task's canonical name and
  the skill never fires. Fix: enrich the TRIGGERS — terms the user would actually say, casual
  and formal variants, domain synonyms.
- Skill storm: the description is broad enough to contend for any request against better skills.
  Fix: name the NEAR MISSES — shared words are not enough when the intent is something else.
```

A short, non-negotiable constraint may live in the description when it is essential for routing.

**Optimizing triggering (verifiable method):** build ~20 realistic queries — half that **should** trigger the skill (varied phrasings, casual/formal, without naming the skill) and half *near-miss* that should **not** (shares keywords, but needs something else). Measure the trigger rate and prefer the description that best **generalizes**, avoiding overfitting to the training queries. Expand to a larger suite only if the boundary is ambiguous or has already regressed.

(`compatibility` is optional and rarely necessary.)

### The `description` never summarizes the workflow

A counter-intuitive, field-tested finding from a reference harness: when the `description` summarizes the process, the agent **follows the description and skips the body**. Real case: a skill with "code review between tasks" in the description led the agent to do **one** review instead of the **two** the body's flow required — the summary became a substitute for the flow.

```text
- description = WHAT the skill does + WHEN to trigger it (trigger conditions, trigger phrases).
- The PROCESS (phases, order, counts, commands) lives in the body — never in the description.
- If the description contains a sequence of steps ("does A, then B, and closes with C"),
  rewrite it: keep the rich triggers, cut the process summary.
- A short non-negotiable constraint ("NEVER start on main without consent") may stay —
  what is forbidden is the SEQUENCE of steps, which the agent executes in a shallow version.
```

## Leading words and the no-op test

**Leading word**: a compact word that already lives in the model's pretraining and works as a behavioral anchor — *seam*, *tracer bullet*, *red*, *tight*, *fog of war*. The right leading word is worth a paragraph of instruction: it pulls in the entire behavior associated with it. **Front-load the leading word in the `description`** — it is the first (sometimes the only) text of the skill the agent sees.

**No-op test**, per sentence: "does this sentence change the agent's behavior relative to the default without it?" Decide **by running** (fresh context, with and without the sentence), **not by debating**. Pruning is by **whole sentence**, not word by word — a half-pruned sentence leaves the negotiation open.

Named failure modes:

| Mode | Symptom |
| --- | --- |
| **Sediment** | adding feels safe, removing feels risky — the skill only grows, layer upon layer |
| **Sprawl** | length itself is the cost: it dilutes the prominence of what matters |
| **Duplication** | repeating a rule artificially inflates its prominence at the expense of the others |
| **No-op** | "be careful" changes no behavior at all; the fix for "be thorough" (no-op) was "relentless" (leading word) |

## Progressive disclosure (3 levels)

```text
1. Metadata (name + description) — always in context (~100 words).
2. SKILL.md body                 — in context when the skill triggers (ideally < 500 lines).
3. Bundled resources             — on demand (unlimited; scripts can run without loading into context).
```

Patterns:

- Keep the `SKILL.md` < 500 lines. Approaching the limit, add a hierarchy level (move depth to `references/`) with clear pointers on **when** to read each file.
- Reference the files explicitly from the `SKILL.md`. Do not create a deep chain of references.
- For long reference files (>300 lines), include a table of contents at the top.
- Keep the body focused on the workflow and the decision criteria; move large tables, vendor details, and bulky examples to `references/`.

The numbers (~100 words of metadata, <500 body lines, 300 lines for a table of contents) are **approximate** — exceed them when there is a reason. The goal is to keep lean what is always in context, not to meet a quota.

## Anatomy

```text
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description) — exclusive to SKILL.md
│   └── Markdown instructions
├── test-pressure-<n>.md (discipline skills) — regression scenarios, NO frontmatter
└── Bundled resources (optional)
    ├── scripts/    — executable code for deterministic/repetitive tasks
    ├── references/ — documents loaded on demand
    └── assets/     — files used in the output (templates, icons, fonts)
```

Not every skill needs those directories. Do not create a README, changelog, or auxiliary files without an operational function.

**Organization by variant** (when the skill covers multiple domains/frameworks):

```text
skill-name/
├── SKILL.md           (workflow + variant selection)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

## Skill source and roots

In the PelizzAI source repo:

- edit `.claude/skills/<name>/`;
- treat `.agents/skills/` as a generated mirror; `.cursor/rules/pelizzai.mdc` is a **manual** adapter — the sync does not generate it, update it by hand when the entrypoints change;
- after an authorized edit, automatically run `node scripts/sync-harness.mjs` and validate
  with `node scripts/sync-harness.mjs --check --source-mode`; `.ps1` and `.sh` are wrappers.

In a consumer project, detect the active root before writing. Use `.claude/skills/` **or** `.agents/skills/`, per the platform and the existing conventions; do not duplicate the edit in both roots on your own. If the project declares a generation process, edit the source and run that process automatically as part of the already-authorized edit.

## Writing patterns

- Use the **imperative** in instructions and observable criteria.
- Explain **why** something matters (theory of mind) instead of imposing rigid, excessive rules — but only when the why closes a likely rationalization. Broad skills generalize better than skills tied to examples.
- **Define output formats** with an exact template when the output must be consistent.
- **Include examples** (input → output) when they reduce ambiguity.
- Prefer one central rule to scattered repetitions.
- Name limits and fallback paths; say when **not** to use the skill.
- Start with a draft; then revisit with fresh eyes and improve.

## Degree of freedom

| Situation | Appropriate form |
| --- | --- |
| Multiple valid solutions; contextual judgment | principles and decision criteria |
| Preferred pattern with acceptable variation | pseudocode, a short checklist, or a parameterized example |
| Fragile, repetitive, or exact-order operation | deterministic script with few parameters |

Do not turn a heuristic into an invariant. Safety, authority, and integrity may require rigid rules; style, decomposition, reasoning techniques, and test quantity normally require contextual selection.

## Match the Form to the Failure

The degree of freedom answers to the **task's fragility**; this section answers to the **type of failure**. Getting the form wrong makes the skill inert or counterproductive:

| Failure type | Correct form of guidance |
| --- | --- |
| Violates discipline under pressure | **Explicit prohibition** + rationalization table (each excuse captured, with its answer) |
| Output with the wrong shape | **POSITIVE RECIPE** of what the output IS (template, example, skeleton) |
| Omitted element | **REQUIRED** slot in the template — the absence becomes syntactically visible |
| Wrong conditional behavior | Conditional on an **observable predicate** ("if the file exists", not "if it makes sense") |

Why a positive recipe for output shape — A/B evidence from a mature harness: the arm with prohibitions ("don't X") produced **MORE** unwanted content than the control **with no guidance at all**. The prohibition draws attention to exactly the pattern it wants to suppress. For output shaping, describe what the output **is**; never list what it is not.

Corollaries:

```text
- NO nuance clauses: "don't do X unless it really matters" reopens the negotiation the rule
  existed to close — under pressure, everything "really matters".
- Exemption clauses don't scope: "this doesn't apply to Y" becomes the hole everything passes
  through. If the rule needs an exception, RESTRUCTURE the rule until the exception disappears.
```

## Calibrated persuasion

Empirical basis: Meincke et al. 2025 — classic persuasion principles raised LLM compliance from **33% to 72%**. Discipline skills can (and should) use the right principles; the wrong ones are forbidden:

| Principle | Use in skills |
| --- | --- |
| **Authority** | "YOU MUST", with no exceptions or softeners — the core of discipline skills |
| **Commitment** | make the agent ANNOUNCE what it will do; checklists with todos; forced choice between options |
| **Scarcity** | real sequence urgency: "IMMEDIATELY after X" |
| **Social Proof** | universal consequence: "checklist without a todo = skipped step. Always." |
| **Liking** | **FORBIDDEN** — praising/pleasing produces sycophancy, not discipline |
| **Reciprocity** | **FORBIDDEN** — "I did this for you, so…" produces sycophancy, not discipline |

Ethics test before using any technique: **"would this technique serve the user's genuine interest if they understood it completely?"** If the answer is no, don't use it.

## Premature conclusion and post-completion steps

Visible future steps **pull** the agent toward concluding early: it sees the end of the flow and starts wrapping up before meeting the criterion. Defense, **in order**:

```text
1. Sharpen the completion criterion FIRST. Two axes:
   - clarity — does the criterion resist premature conclusion? "Every modified skill accounted
     for" resists; "review the skills" does not.
   - demand  — does the criterion FORCE the work? "Every modified skill accounted for" requires
     checking each one; "produce a list" accepts any list.
2. Only if sharpening is not enough, hide the future steps — and hiding only works across a
   REAL context boundary (subagent, handoff). "Hiding" inline (pushing to the end of the text,
   saying "ignore for now") cleans nothing: the agent has already read it.
```

## Scripts

Prefer a script when copying commands would be fragile or the result can be verified automatically. A script must:

- accept explicit inputs and validate parameters;
- fail with an actionable message;
- avoid destructive effects by default;
- work from documented paths;
- have at least one happy fixture and one representative error when it is critical.

Test the script by running it. Merely reading it does not validate quoting, encoding, platform differences, or exit codes.

## Wording micro-test

Before any expensive eval, validate the wording cheaply:

```text
1. 5+ fresh-context samples PER wording VARIANT.
2. Always against a CONTROL with no guidance — without a control, you don't know whether the
   skill changed the behavior or the model would already do it on its own.
3. Read each match MANUALLY: template echo (the agent repeats the skill's words without
   changing behavior) masks a false hit.
4. VARIANCE is a first-class metric: five different interpretations across five reps
   = the wording is NOT binding, however good "the average" looks.
5. Batching is FORBIDDEN: close one skill's wording before moving to the next — in a batch,
   you don't know which change caused which effect.
```

## Evals (when the output is verifiable)

The wording micro-test (section above) comes first; the eval is the expensive step. Evals are indicated when there is objectively verifiable output or an important routing boundary. Each case must contain minimal context and input, expected behavior, the relevant forbidden behavior, an objective pass criterion, and the reason the case protects against a plausible regression.

Structure of the file **you create** inside the skill, at evals/evals.json (no skill in this repository uses this format today — the harness's evals are the Markdown scenarios described below):

```json
{
  "skill_name": "skill-name",
  "evals": [
    {
      "id": 1,
      "prompt": "User task",
      "expected_output": "Expected result",
      "expectations": ["The output includes X", "The skill used script Y"],
      "files": []
    }
  ]
}
```

The `expectations` field (objectively verifiable assertions) is what the **grader** checks — it is what makes the eval "verifiable". Add it when writing the assertions. The full `evals.json`/`grading.json` schema **does not live in this repository**: it comes from Anthropic's `skill-creator`, in the references/schemas.md file **of that skill's package**. Confirm the exact field name in the version you have installed instead of assuming what is written here.

When the criterion is about **routing** rather than literal output, the harness uses Markdown scenarios inside `evals/` (e.g. `.claude/skills/pelizzai-router/evals/adaptive-user-control.md`). Same requirement: each case names the expected route, the forbidden route, and the regression it protects against.

Procedure (when subagents are available):

```text
- Run in parallel: one execution WITH the skill and one WITHOUT (baseline).
- While they run, write quantitative assertions; capture tokens and duration from the
  notifications.
- Grade each execution with a "grader" subagent against the assertions.
- Aggregate into benchmark.json and show the user (e.g. eval-viewer).
- Iterate from the feedback, GENERALIZING (do not overfit to the test cases).
```

In environments without subagents (e.g. claude.ai), run the cases sequentially, without baseline/benchmark, and present the results in the conversation.

Avoid turning the answer's exact wording into a contract, except when the format is an API. Test decisions and observable effects.

## Absence of Surprises principle

Skills must not contain malware, exploits, or content that compromises security. Do not fulfill requests to create deceptive skills or ones aimed at unauthorized access, exfiltration, or malicious activity. A skill must not surprise the user relative to its declared purpose. (Legitimate resources like "act as an XYZ" are acceptable.)

A skill also must not silently introduce network access, credentials, global installation, out-of-scope writes, publication, or data destruction. Declare dependencies and effects. Use consent when new authority is needed. Never include secrets in examples, logs, or fixtures.

## Completion criterion

A skill is ready when:

- its trigger distinguishes valid uses from *near misses*;
- the body contains only instructions that change behavior (no-op test applied);
- the degree of freedom and the form of the guidance match the task's fragility and the failure type;
- links, frontmatter, and relevant scripts have been validated;
- the critical behavior passed the baseline and the versioned pressure scenarios, when they exist;
- source, mirrors, and documentation do not contradict the new contract.

## Packaging

To distribute a skill as an artifact, package the skill folder (e.g. `python -m scripts.package_skill <folder>` in the upstream skill-creator). In PelizzAI, skills live in `.claude/skills/` and are versioned with the project; packaging is only necessary when the user actually needs to distribute the skill outside the repository. Within PelizzAI, versioning and sync are enough.
