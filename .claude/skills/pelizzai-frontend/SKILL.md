---
name: pelizzai-frontend
description: Use when building or changing frontend interfaces — pages, components, dashboards, app shells, forms, empty states; when the user asks for UI design, redesign, polish, or critique; or when a task's diff touches templates, styles, or client-side components.
---

# PelizzAI Frontend

The design overlay for UI work. It exists to kill two failure modes: **generic AI convergence** (the same faces, the same gradient hero, the same card grid — measured: a model asked 16 times produced 30/35 identical concepts) and **vibe-only direction** ("modern and clean" is not a decision). The operating principle: **commitment beats refinement** — a decided direction executed firmly beats timid iteration every time.

## The direction contract — before any screen

Five blocks, each a **concrete choice**, written before building:

| Block | A decision looks like | Not a decision |
|---|---|---|
| 1. Concept | the one idea the interface embodies, named | "clean and professional" |
| 2. Typography | the actual faces, scale, weights | "a nice modern font" |
| 3. Color & material | the palette with roles — mood lives in the brand colors, not in tinted surfaces | "a fresh palette" |
| 4. Layout system | grid, density, spacing rhythm | "well spaced" |
| 5. Motion | what moves, when, how long — or deliberately static | "subtle animations" |

**The test: if a block reads as vibe, the direction was not decided — rewrite it as a choice.** Synthesis ≤150 words, ratified by the user (direction is a product decision; a contested block goes to `pelizzai-interview-me`). Once ratified, execute with commitment: mid-build aesthetic drift is a gap, not iteration.

An existing brand or design system **is** the direction — no sortition; record it in the contract and follow it.

**Visual questions get visual answers.** During direction and build, a genuinely visual question is answered with disposable mockups: quick HTML rendered in the browser or preview — the `pelizzai-brainstorming` visual companion serves exactly this — showing 2–3 **structurally different** variants; slightly adjusted grids are wallpaper, not variants. Mockups are scratch (temp dir or the visual companion's workspace), never committed as product code.

## Anti-convergence sortition

When the direction is open (no brand imposed):

1. **Generate 6–10 candidate directions, genuinely different** — different concept + typography + color + layout, not one grid with ten accents.
2. **Derive a deterministic index from project facts** — sum the character codes of the task slug; `index = 3 + (sum mod (N − 2))`. The index **never lands on candidates 1 or 2**: the model's first instincts are the convergent ones, and the external seed is what the model cannot fake.
3. Present the selected candidate with the full list. The user **ratifies or re-rolls** — a re-roll generates new candidates; it never quietly picks the discarded firsts.

## Build rules

- Follow the [Craft Floor](references/craft-floor.md) — numeric, Verify/Refuse format. Floors are **category defaults, not bans**: deviating is legitimate only as a declared exception in the direction contract, never silently.
- Real content over lorem whenever it exists — lorem hides layout failures that real strings expose.
- **Every state is designed**: loading, empty, error, disabled. Empty states are design, not leftovers.
- Accessibility floors are the exception to "defaults, not bans": those are Refuse lines, non-negotiable.

## Verification — the design oracle

UI claims are verified rendered, never from source reading alone:

- **Machine-checkable floors** (contrast ratios, tap targets, page overflow at 375px, focus visibility, reduced-motion) are measured in a real browser — playwright/browser MCP when installed (the harness recommends it at bootstrap). These are machine oracles: iterate freely until they pass.
- **Aesthetic judgment** is an attestation oracle: screenshots or a live preview presented against the direction contract; the user judges. Presenting evidence is not claiming success (`pelizzai-verification-before-completion`).

## Fresh-eyes design review

For substantial UI deliveries, dispatch a fresh-context, read-only reviewer carrying: the direction contract, the screenshots/preview, and the craft floor. It returns a **fidelity matrix** — per contract block: followed / drifted, with evidence, typography and color/material lines mandatory — plus floor violations with **measured values**. The coordinator cannot soften the verdict — the same anti-pre-judging rule as `pelizzai-review`.

## Red flags

- Building before the contract is ratified, or a contract block that reads as vibe.
- Shipping candidate 1 or 2 of a sortition.
- "Improving" the direction mid-build — drift dressed as iteration.
- Lorem-only screens presented as done; states missing.
- Claiming visual quality without a rendered check.
- Softening the design reviewer's fidelity matrix.

## Harness integration

This skill is a **mandatory overlay** for any task whose diff touches pages, components, styles, layout, visual states, or UX — whatever the head skill. The router records the overlay; `pelizzai-writing-plans` lists it among the plan's cross-cutting harness skills; the executor loads it before implementing and before reviewing. Under a closed briefing (SUBAGENT-STOP / TEAM-MEMBER-STOP), do not open gates or produce route analyses: apply the briefing and escalate to the coordinator anything that requires a decision. Direction ratification and durable visual decisions (dark mode, density, charts/metrics) are recommendations the user ratifies — never silent defaults.

- `pelizzai-brainstorming` — UI-bearing specs produce the direction contract in their design phase; its visual companion renders the disposable mockups.
- `pelizzai-writing-plans` — UI tasks carry floor checks in their proof lines.
- `pelizzai-execution-plans` — frontend tasks load this overlay inside the task cycle.
- `pelizzai-review` — reviews of frontend diffs delegate fidelity and floor checks here.
- `pelizzai-verification-before-completion` — rendered evidence before any visual claim.
- `pelizzai-interview-me` — direction is a product decision; contested blocks land there.
- `pelizzai-audit` and the project's domain skills — discovery of an existing design system, tokens, and components.

---

**This skill is working if:** interfaces stop resembling the model's first instinct (candidates 1–2 never ship); every UI delivery has a ratified direction contract its screens are checked against; floor violations are caught by measurement, not taste debate; and empty and error states arrive designed, not discovered.
