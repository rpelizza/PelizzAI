---
name: pelizzai-interface
description: "Use when building or changing UI — pages, components, dashboards, forms, empty states — or when the user asks for design, redesign, polish, or critique. Direction is decided before pixels."
---

# PelizzAI Interface

The design overlay for UI work. It exists to kill two failure modes: **generic AI convergence** (the same faces, the same gradient hero, the same card grid — measured: a model asked 16 times produced 30/35 identical concepts) and **vibe-only direction** ("modern and clean" is not a decision). The operating principle: **commitment beats refinement** — a decided direction executed firmly beats timid iteration every time. 

Everything this flow says to the user — questions, proposals, evidence, verdicts, confirmations, closeouts — follows the conversation's language, even when this skill is read in isolation.

## The direction contract — before any screen

Five blocks, each a **concrete choice**, written before building:

| Block | A decision looks like | Not a decision |
|---|---|---|
| 1. Concept | the one idea the interface embodies, named | "clean and professional" |
| 2. Typography | the actual faces, scale, weights | "a nice modern font" |
| 3. Color & material | the palette with roles — mood lives in the brand colors, not in tinted surfaces | "a fresh palette" |
| 4. Layout system | grid, density, spacing rhythm | "well spaced" |
| 5. Motion | what moves, when, how long — or deliberately static | "subtle animations" |

**The test: if a block reads as vibe, the direction was not decided — rewrite it as a choice.** Synthesis ≤150 words, ratified by the user (direction is a product decision; a contested block goes to `pelizzai-interview`). Once ratified, execute with commitment: mid-build aesthetic drift is a gap, not iteration.

An existing brand or design system **is** the direction — no sortition; record it in the contract and follow it.

**Visual questions get visual answers.** During direction and build, a genuinely visual question is answered with disposable mockups: quick HTML rendered in the browser or preview — the `pelizzai-discovery` visual companion serves exactly this — showing 2–3 **structurally different** variants; slightly adjusted grids are wallpaper, not variants. Mockups are scratch (temp dir or the visual companion's workspace), never committed as product code.

**Know your own accent.** AI-generated design today clusters around three looks, measured
independently by two teams: warm cream (≈`#F4F1EA`) with a high-contrast serif and a terracotta
accent; near-black with a single acid-green or vermilion pop; and hairline-rule broadsheet with
dense columns and zero border-radius. All three are legitimate for some briefs — **the brief's own
words always win, including when it asks for one of these looks** — but they are defaults, not
choices, and they appear regardless of subject. Where the brief leaves an axis free, do not spend
that freedom on one of them; treat your first palette instinct as already spent.

## Anti-convergence sortition

When the direction is open (no brand imposed):

1. **Generate 6–10 candidate directions, genuinely different** — different concept + typography + color + layout, not one grid with ten accents.
2. **Derive a deterministic index from project facts** — sum the character codes of the task slug; `index = 3 + (sum mod (N − 2))`. The index **never lands on candidates 1 or 2**: the model's first instincts are the convergent ones, and the external seed is what the model cannot fake.
3. Present the selected candidate with the full list. The user **ratifies or re-rolls** — a re-roll generates new candidates; it never quietly picks the discarded firsts.

## Build rules

- **Temporal gate:** load [references/craft-floor.md](references/craft-floor.md) immediately
  before editing UI — never during analysis or direction work. The context cost is paid when it
  changes behavior, and a ban-list read at design time biases the direction toward timid output.
  Build to the floor without announcing the checklist.
- The Craft Floor is numeric, Verify/Refuse format. Floors are **category defaults, not bans**: deviating is legitimate only as a declared exception in the direction contract, never silently.
- **Copy is design material, not decoration.** Name things by what the person controls, never by
  the system's construction (a person manages *notifications*, not *webhook config*); active
  voice; a control says exactly what happens and keeps its name through the flow (button
  "Publish" → toast "Published"); errors name the problem and the recovery, never apologize, and
  are never vague; an empty state is an invitation to act. Register (vigor, no filler) comes from
  `pelizzai-prose`; interface vocabulary lives here.
- Real content over lorem whenever it exists — lorem hides layout failures that real strings expose.
- **Every state is designed**: loading, empty, error, disabled. Empty states are design, not leftovers.
- Accessibility floors are the exception to "defaults, not bans": those are Refuse lines, non-negotiable.

## Verification — the design oracle

UI claims are verified rendered, never from source reading alone:

- **Machine-checkable floors** (contrast ratios, tap targets, page overflow at 375px, focus visibility, reduced-motion) are measured in a real browser — playwright/browser MCP when installed (the harness recommends it at bootstrap). These are machine oracles: iterate freely until they pass.
- **Aesthetic judgment** is an attestation oracle: screenshots or a live preview presented against the direction contract; the user judges. Presenting evidence is not claiming success (`pelizzai-verify`).
- **Verify in bounded passes, not a loop:** build complete, inspect once in a batched round
  (desktop + mobile together — a screenshot is worth a thousand tokens), fix everything in one
  batch, confirm with at most one more round, stop. Open-ended self-QA burns the user's money.

## Fresh-eyes design review

For substantial UI deliveries, dispatch a fresh-context, read-only reviewer with the briefing
template [references/interface-reviewer.md](references/interface-reviewer.md): check 0 validates
the evidence before any judgment (a verdict derived from a broken capture launders the breakage
into approval), the reviewer has **no browser** (it judges exactly the evidence the builder
captured, which keeps the capture auditable), and it returns a closed verdict —
`recapture | rebuild | fix | ship` — that the coordinator reports **verbatim** and has no
authority to soften, plus the fidelity matrix (typography and color/material lines mandatory) and
floor violations with **measured values**.

## Red flags

- Building before the contract is ratified, or a contract block that reads as vibe.
- Shipping candidate 1 or 2 of a sortition.
- "Improving" the direction mid-build — drift dressed as iteration.
- Lorem-only screens presented as done; states missing.
- Claiming visual quality without a rendered check.
- Softening the design reviewer's fidelity matrix.

## Harness integration

This skill is a **mandatory overlay** for any task whose diff touches pages, components, styles, layout, visual states, or UX — whatever the head skill. The router records the overlay; `pelizzai-plan` lists it among the plan's cross-cutting harness skills; the executor loads it before implementing and before reviewing. Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP), do not open gates or produce route analyses: apply the briefing and escalate to the coordinator anything that requires a decision. Direction ratification and durable visual decisions (dark mode, density, charts/metrics) are recommendations the user ratifies — never silent defaults.

- `pelizzai-discovery` — UI-bearing specs produce the direction contract in their design phase; its visual companion renders the disposable mockups.
- `pelizzai-plan` — UI tasks carry floor checks in their proof lines.
- `pelizzai-execute` — frontend tasks load this overlay inside the task cycle.
- `pelizzai-review` — reviews of frontend diffs delegate fidelity and floor checks here.
- `pelizzai-verify` — rendered evidence before any visual claim.
- `pelizzai-interview` — direction is a product decision; contested blocks land there.
- `pelizzai-onboard` and the project's domain skills — discovery of an existing design system, tokens, and components.

---

**This skill is working if:** interfaces stop resembling the model's first instinct (candidates 1–2 never ship); every UI delivery has a ratified direction contract its screens are checked against; floor violations are caught by measurement, not taste debate; and empty and error states arrive designed, not discovered.
