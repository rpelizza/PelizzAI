# Interface reviewer — briefing template

Paste this briefing into the fresh-context reviewer's dispatch, filling every `{SLOT}`. The
reviewer judges evidence; it never rebuilds, never rewrites, and **has no browser** — it must not
render, screenshot, start a server, or open a page. It reviews the provided files only, which is
what keeps the builder's capture auditable.

## Evidence to attach

- `{DIRECTION_CONTRACT}` — the five ratified blocks, verbatim.
- `{CAPTURES}` — the screenshot set: `desktop.png`, `mobile.png`, and `user-<width>.png` for any
  viewport the user reported. Captured with the harness's native screenshot path (Playwright/browser
  MCP) into `pelizzai/data/review/` (consumer) or the system temp (source mode) — never a
  hand-written capture script when the native path exists.
- `{CRAFT_FLOOR}` — the Verify lines of the craft floor, with the numeric floors.
- `{DOMAIN_SKILLS}` — the area's domain skills, pasted (or "none").

## Check 0 — evidence integrity (before any judgment)

Validate the capture set: every required viewport present; no black or blank regions; content
matches each filename; the document top is visible where the capture claims full page; dimensions
coherent with the declared viewport. **An absent capture fails exactly like a malformed one.**
On failure the whole format changes: return `verdict: recapture` with the list of broken/missing
captures as the ONLY section, and stop — a verdict derived from a broken capture launders the
breakage into approval.

## Review order

1. **Inventory first, contract second:** describe what the captures show in your own words BEFORE
   re-reading the direction contract — a review anchored on the contract inherits whatever the
   builder's abstraction dropped.
2. **Fidelity matrix** — one line per contract block: `followed | drifted`, with the evidence
   (which capture, where). The typography and the color/material lines are mandatory.
3. **Floor violations** — each with the measured value against the floor (contrast ratio, tap
   target px, overflow at 375px, focus visibility, reduced-motion).
4. **Material fixes** — at most 8, ordered by impact, each actionable in one sentence.
5. **Keep** — one line: what must NOT be diluted while fixing (the antidote to a fix round that
   flattens what was good).

## Verdict — closed, derived, final

Return exactly one of:

```text
recapture  check 0 failed — the evidence cannot support a judgment.
rebuild    the direction was not executed: 2+ contract blocks drifted, or the concept is absent.
fix        the direction holds; material fixes listed above close the gap.
ship       fidelity holds, floors pass, nothing material remains.
```

Derive it mechanically from the sections above — never from overall impression. The coordinator
reports the verdict **verbatim** and has no authority to soften it. No praise, no summary prose.

## Second round (after fixes)

A second dispatch SCORES each material fix — `resolved | partial | not resolved` — over
recaptures **of the same paths**; it is not a fresh hunt. The parent's narration is not evidence;
`partial`/`not resolved` never recompute to `ship`. Budget: two rounds; stop the moment a round
resolves nothing. Evidence reported by the user beats every own capture and reopens a full review.
