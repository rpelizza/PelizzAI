# Craft Floor

The numeric quality floor for UI work. Every rule is a **category default, not a ban**: deviating is legitimate only as a declared exception in the direction contract. The exceptions to this rule are the **Accessibility** lines — those are hard Refuse lines — and the one true ban, marked as such.

Format: **Verify** (how to check, preferably measured in a rendered browser) / **Refuse** (what gets rejected).

## Typography

- **At most 2 typefaces** — one display, one text (plus mono for code).
  Verify: count `font-family` values in computed styles. Refuse: a third decorative face.
- **Text measure 65–75ch** for running prose.
  Verify: paragraph width in `ch` at desktop. Refuse: full-viewport-width prose.
- **Display size ≤6rem**; tracking on large display **never tighter than −0.04em**.
  Verify: computed `font-size` / `letter-spacing` on the largest heading. Refuse: hero text beyond 6rem or crushed tracking.
- **Line-height** ≈1.5 for body, ≈1.1–1.2 for display.
  Verify: computed values. Refuse: single-spaced body text.
- **BAN — kicker/eyebrow labels above headings** (the small all-caps label over a title). This one is a real ban, not a default: it is the single strongest marker of converged AI layouts.

## Color

- **Mood lives in the brand colors, not the surfaces.** Surfaces stay near-neutral; target distribution ≈ **50% pure white / 25% pure black / 25% tinted** (mirrored for dark themes).
  Verify: eyeball the rendered page area by that split. Refuse: every surface tinted "for warmth".
- **Chroma cap ≈0.23 (OKLCH)** for brand colors; surfaces far below it.
  Verify: token values. Refuse: neon-saturated large areas.
- **Text contrast ≥4.5:1** (≥3:1 for large text); **UI component boundaries ≥3:1**.
  Verify: measured contrast in DevTools/Playwright — never by eye. Refuse: any text below floor.
- **The two brand colors are distinguishable in role** — primary vs accent separated on at least one OKLCH axis: `max(L)/min(L) ≥1.7` **or** `max(C)/min(C) ≥1.7`, computed on the two brand tokens converted to OKLCH. When the smaller value on an axis is exactly 0, the ratio is undefined and the axis resolves by rule: it **passes** if the larger value is above 0 (pure black against any lighter tone, or an achromatic grey against a chromatic brand color, are maximally separated on that axis) and **fails** if both are 0. Hue difference alone never satisfies this.
  Verify: convert both brand tokens to OKLCH and evaluate both axes; at least one must clear 1.7 or resolve as a pass by the zero rule. Refuse: two near-identical brand colors doing the same job.
- **White text on saturated backgrounds: measure, don't trust the eye** — saturated hues read lighter than they measure (Helmholtz–Kohlrausch); the contrast number decides.
- **One accent doing accent work.** If everything is accented, nothing is.

## Layout & spacing

- **Spacing on a consistent scale** (4/8px base or the project's token scale).
  Verify: computed margins/paddings snap to the scale. Refuse: one-off arbitrary values.
- **Everything aligns to something nameable.**
  Verify: overlay a grid; each edge answers "aligned to what?". Refuse: near-alignment (2–3px off).
- **No horizontal scroll of the page body at any breakpoint.**
  Verify: render at 375px width. Refuse: body overflow; wide content scrolls inside its own container.
- **Density is chosen in the contract, then consistent** — no airy hero over a cramped table without a declared reason.

## Interaction

- **Tap targets ≥44×44px** on touch.
  Verify: measure the smallest interactive element at mobile width. Refuse: icon buttons below floor.
- **Visible focus state on every interactive element.**
  Verify: tab through the page. Refuse: `outline: none` without a replacement.
- **Hover is enhancement, never the only signal** — everything hover reveals must be reachable without it.
- **All states exist**: loading, empty, error, disabled.
  Verify: force each state. Refuse: an error state that was never designed.

## Motion

- **UI transitions 150–300ms**, eased (never linear), and **motivated** — enter, exit, or feedback.
  Verify: computed transition values. Refuse: permanently looping decorative animation.
- **`prefers-reduced-motion` honored** — motion collapses to opacity or nothing.
  Verify: toggle the preference and re-render.

## Accessibility — hard Refuse lines

Non-negotiable; no direction contract can except them:

- Contrast floors above.
- Focus visibility above.
- Informative images carry `alt`; decorative ones carry empty `alt`.
- Every input has a programmatic label.
- Everything interactive is keyboard-reachable in a sensible order.
