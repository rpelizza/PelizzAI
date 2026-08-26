---
name: pelizzai-prose
description: "Use when writing or editing text for humans — docs, READMEs, UI copy, reports, commit messages. Clear, vigorous prose; names and removes AI-writing patterns."
---

# PelizzAI Prose

The writing overlay. Two failure modes it exists to kill: prose that buries the point under
ceremony, and prose that reads as generated — the recognizable AI register of hedged symmetry,
importance puffery, and fake-profound endings. The operating principle: **every sentence earns its
place, and the writer's real voice survives the edit.**

## Two modes

**Edit (default).** The text is yours to improve: make the minimum effective edit using the
principles below and the pattern catalog, and say what changed in one short block. A rough draft
with a real voice still sounds like the same person afterward. The change summary speaks the conversation's language (the edited text keeps its own).

**Detect.** Asked whether a text reads as AI, or to audit without rewriting: name each pattern
from [references/patterns.md](references/patterns.md) that appears, quote the offending line, and
give the fix in a few words. Do not rewrite, do not score, and never claim to know whether an AI
wrote it — detectors guess; a named pattern with a quoted line is evidence the reader can check.
The report itself speaks the conversation's language; pattern names and quotes stay verbatim.

## Editing principles

- **Preserve the voice.** Note the draft's vocabulary, cadence, bluntness, humor, and level of
  polish before touching anything; keep what is personal. Equal tidiness in every paragraph is a
  loss, not a win.
- **Lead with the point.** Cut throat-clearing; keep an aside or admission that builds character
  or context. Front-load conclusions when it helps the reader — not as a universal shape.
- **Concrete beats abstract.** Names, numbers, dates, mechanisms. "Cut deploy time from 40 minutes
  to 4" beats "improved efficiency". Protect the specific fact: never smooth a useful detail into
  generic importance.
- **The portability test.** A sentence that could move unchanged to another company, product, or
  person is filler — replace it with a fact, consequence, or judgment specific to THIS subject.
- **Show, don't label.** Cut commentary that tells the reader something is important, surprising,
  or subtle instead of demonstrating why. If the prose already shows it, trust the reader.
- **Verbs do the work.** Active voice; "decided" not "made a decision"; "is" and "has" over
  fake-strong verbs ("serves as a centralized hub for").
- **Keep the meaning.** Never invent claims, examples, or sources; a missing source is a question
  to the user, not a "studies show".
- **The bar:** for each paragraph, point to the sentence that makes it specifically YOURS — about
  this subject, this project, this decision. A paragraph with no such sentence is generic filler
  by default, whoever typed it.

## Two levels of rigor

The full catalog does not apply to everything the harness writes:

| Level | Applies to | Rules |
| --- | --- | --- |
| **1 — human copy** | READMEs, docs, reports, commit/PR messages, UI copy, specs and plans | the whole of [references/patterns.md](references/patterns.md): word lists, named patterns, judgment patterns, em-dash discipline |
| **2 — LLM instruction** | the harness's own SKILL.md files, subagent briefings, prompt templates | word lists and named patterns only, with the technical vocabulary released (`robust`, `seamless`, `elevate`, `underscore`, `pivotal`, `leverage` have legitimate technical readings — `leverage` is canonical vocabulary in pelizzai-module-design) — and the hardening repetition and triadic checklists those files use exist ON PURPOSE; do not strip the mechanisms that make an instruction survive |

Applying level 1 to a skill file attacks exactly what makes skills work; applying level 2 to a
README ships slop. Say which level you are applying when it is not obvious.

## Governance

A rule that produces a false positive is not silently bypassed — propose the amendment to this
skill (via the harness's normal flow) so the rule improves for everyone. Rewording to sneak past a
pattern the catalog names is the failure, not the fix.

## Integration

**Combines with:** `pelizzai-interface` (interface vocabulary and control naming live there; this
skill supplies the register), `pelizzai-docs` (documentation content), `pelizzai-skill-lab`
(level 2 applies to skill authoring), `pelizzai-finish` (commit/PR messages). Deep dives on
composition — active voice, positive form, omitting needless words — live in
[elements-of-style/03-elementary-principles-of-composition.md](elements-of-style/03-elementary-principles-of-composition.md),
consulted when a passage resists the quick rules.

## Final instruction

Read the whole text first. Identify the core point and the voice signals to preserve. Then either
name the patterns (Detect) or make the minimum effective edit (Edit) — and end on the clearest
concrete sentence, never on a kicker.
