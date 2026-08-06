# Craft Floor

The quality floor for UI work. **Every line under "Floors" is pass/fail with a procedure that
produces the value** — a criterion that can be argued down is not a criterion (the same doctrine
as `pelizzai-evolve`'s verification standard). Lines that cannot be measured live in
[Declared guidance](#declared-guidance--not-floors) at the bottom, are marked as such, and never
fail a review.

Each floor is a **category default, not a ban**: deviating is legitimate only as a declared
exception in the direction contract (the `### Direction contract` block of the plan). The
exceptions to *that* are the **Accessibility** lines — hard Refuse, no contract excepts them —
and the one true ban, marked as such. When a floor and the project's design system disagree, the
ladder in `pelizzai-frontend` decides: **accessibility > approved direction/design system >
floor defaults and bans > the model's taste.**

Format: **Verify** (the procedure and where it runs) / **Refuse** (what the value has to be to
fail). Colors are compared in **OKLCH**; convert tokens before measuring. Unless a line says
otherwise, measure in a rendered page at 1280px width.

## Typography

- **At most 2 typefaces** — one display, one text (plus mono for code).
  Verify: collect distinct `font-family` values from computed styles across the rendered page.
  Refuse: a third family that is neither text, display, nor mono.
- **Prose measure ≤80ch**, target 65–75ch for running text.
  Verify: paragraph `getBoundingClientRect().width` ÷ the element's `1ch` advance. Refuse: >80ch.
- **Display size ≤6rem; letter-spacing ≥ −0.04em** on any face ≥3rem.
  Verify: computed `font-size` and `letter-spacing` on the largest heading. Refuse: >6rem, or
  tracking below −0.04em.
- **Line-height: body 1.4–1.7, display 1.0–1.25** (unitless, computed ÷ font-size).
  Verify: computed values on one body paragraph and the largest heading. Refuse: outside the band.
- **BAN — kicker/eyebrow labels above headings** (the small all-caps label over a title). A real
  ban, not a default: it is the single strongest marker of converged AI layouts. It binds
  **invention, not inheritance** — a design system that already uses the pattern wins under the
  ladder, recorded as an inherited exception with its citation.
  Verify: read the markup above each heading. Refuse: a newly introduced label element above a
  heading with no system citation.

## Color

- **Text contrast ≥4.5:1**; ≥3:1 for text ≥24px, or ≥18.66px at weight ≥700. **Non-text UI
  boundaries, icons carrying meaning, and focus rings ≥3:1.**
  Verify: WCAG relative-luminance computation over the two rendered colors, or a measured value
  from DevTools/Playwright — the number decides and the eye never does, because saturated hues
  read lighter than they measure (Helmholtz–Kohlrausch). Refuse: any value below the floor,
  including one that looks fine.
- **Chroma ceilings: brand tokens C ≤0.23; any surface token C ≤0.08.**
  Verify: convert each token to OKLCH and read C. Refuse: a value above its ceiling.
- **The two brand colors are distinguishable in role.** Primary and accent are separated on at
  least one axis: **ΔL ≥0.15**, or **C_max ÷ C_min ≥1.7**, or **Δhue ≥30°**.
  Verify: convert both tokens and compute all three margins. Refuse: none of the three met — two
  near-identical colors doing the same job.
- **Tinted surface share ≤35% of the viewport.** Target shape ≈50% light-neutral / 25%
  dark-neutral / 25% tinted, mirrored in dark themes; the pass line is the single number.
  Verify — preferred procedure: screenshot the rendered viewport and sample its **pixels** on a
  fixed grid (one probe every ~16px). The composited pixel already encodes paint order,
  pseudo-elements, `pointer-events: none` layers, opacity, and occlusion **by construction** —
  no DOM stacking rules to re-derive. To keep foreground out of the numerator (the floor is
  about SURFACES), mark probes **ineligible** when the point falls inside the client rects of
  text nodes, replaced content (`img`, `video`, `canvas`, data `svg`), or chart data inks;
  ineligible probes leave the numerator AND the denominator. Classify each eligible pixel as
  tinted when OKLCH C >0.02, neutral otherwise, and divide tinted probes by **eligible**
  probes; with zero eligible probes, report the floor as *not measurable for this page*
  (attestation to the user), never as a pass.
  Fallback (no screenshot surface available): resolve each probe's surface from the DOM —
  `elementsFromPoint` plus the layers hit testing misses (`pointer-events: none` elements and
  `::before`/`::after` that paint a background), the combined set ordered by CSS painting order
  (stacking context, then `z-index`, then DOM order) with each pseudo-element bounded by its
  **own border box**, never the owner's full rect; the topmost painted background wins. Where
  that order is ambiguous, say the value was **computed with that caveat** — the fallback
  approximates what the screenshot measures directly. Grid sampling counts each visible point
  once — summing element rects would double-count overlapping surfaces and ignore occlusion.
  Refuse: >35% — every surface tinted "for warmth".
- **One token carries call-to-action emphasis per screen.**
  Verify: list the background and border tokens of the buttons and emphasis marks in the rendered
  page, excluding the semantic status set (success / warning / error / info). Refuse: two
  different non-semantic tokens both styled as the primary call to action.

## Layout & spacing

- **Every margin and padding is on the scale** — a multiple of the 4/8px base, or a project token.
  Verify: collect computed margin and padding values across the rendered page and test each
  against the scale. Refuse: any one-off value off it.
- **Edges that align, align exactly.**
  Verify: compare `getBoundingClientRect()` x and y of sibling region edges. Refuse: two edges
  within 8px of each other and unequal — near-alignment reads as a rendering error.
- **No horizontal scroll of the page body at any breakpoint.**
  Verify: at 375px, 768px and 1280px, assert
  `document.scrollingElement.scrollWidth <= clientWidth`. Refuse: body overflow; wide content
  scrolls inside its own container instead.
- **Repeated elements of one kind share one padding token** — every card, every table row, every
  form field.
  Verify: compare computed padding across instances of the same component. Refuse: differing
  values within a kind, which is how declared density drifts.

## Interaction

- **Tap targets ≥44×44px** on touch.
  Verify: measure the smallest interactive element's rect at 375px width. Refuse: any below floor.
- **Visible focus on every interactive element**, at ≥3:1 against its adjacent colors.
  Verify: tab through the rendered page and read the `:focus-visible` computed styles and their
  contrast. Refuse: `outline: none` with no replacement, or an indicator below 3:1.
- **Hover reveals nothing that hover alone can reach.**
  Verify: focus the same element by keyboard and confirm the identical content appears, and that
  it is present in the DOM without a pointer. Refuse: content reachable only by hovering.
- **All four states exist**: loading, empty, error, disabled.
  Verify: force each one in the real component and capture it. Refuse: any of the four undesigned.

## Motion

- **UI transitions 150–300ms**, non-linear easing, and **motivated** — enter, exit, or feedback.
  Verify: computed `transition-duration` and `transition-timing-function`. Refuse: a duration
  outside the band, `linear`, or a permanently looping decorative animation.
- **`prefers-reduced-motion` honored** — motion collapses to opacity ≤100ms or to nothing.
  Verify: emulate the preference, re-render, and re-read the computed values. Refuse: unchanged
  durations under the preference.

## Data display & charts

- **Series are separable without color.** Every series carries a second channel — direct label,
  dash pattern, marker shape, or position.
  Verify: re-render under `filter: grayscale(1)` and identify each series. Refuse: color as the
  only encoding.
- **Categorical series ≤7 per chart.**
  Verify: count rendered series. Refuse: more — group the tail or split into small multiples.
- **Series colors adjacent in the legend are separated** by ΔL ≥0.15 in OKLCH, or by a non-color
  channel from the line above.
  Verify: convert the palette in series order and compute ΔL on each neighbouring pair. Refuse: a
  pair inside the margin with no second channel.
- **Chart text meets the text contrast floor; data marks ≥3:1 against the plot background.** Axis
  labels, tick labels, legends and data labels are text. Gridlines are decorative and exempt.
  Verify: measured contrast on each. Refuse: any value below its floor.
- **Length encodings include zero.** Bar, column and area value axes start at zero; line and
  scatter may truncate, and the truncation is stated on the axis.
  Verify: read the rendered axis domain. Refuse: a truncated bar or area baseline.
- **Every axis states its unit; every number its format and precision.**
  Verify: read the rendered axis and data labels. Refuse: bare magnitudes with no unit or scale.
- **A non-visual equivalent exists** — a data table, an `aria-label` carrying the takeaway, or a
  data download.
  Verify: read the accessibility tree for the chart node. Refuse: a bare `<canvas>` or an
  unlabeled `<svg>` as the only representation.
- **Chart states are designed**: loading, no data, error, and a single data point.
  Verify: force each with the real component and real data shapes. Refuse: an empty dataset that
  renders a blank frame with no message.

## Accessibility — hard Refuse lines

Non-negotiable; no direction contract and no design system excepts them:

- Contrast floors above, text and non-text, charts included.
- Focus visibility above.
- Informative images carry `alt`; decorative ones carry empty `alt`.
- Every input has a programmatic label.
- Everything interactive is keyboard-reachable in a sensible order.
- Every chart has the non-visual equivalent above.

## Declared guidance — not floors

Not measured, and a review never fails on them. They inform the direction contract and the
critique; a line that arrives here has left the numeric floor on purpose, because inventing a
number for it would produce a criterion arguable down to whatever the output already did.

- **Mood lives in the brand colors, not the surfaces.** The tinted-share floor caps the failure;
  the taste question of *which* surfaces earn a tint stays here.
- **Density is chosen in the contract, then held.** An airy hero over a cramped table needs a
  declared reason. The repeated-element floor catches the mechanical half of this.
- **One accent doing accent work.** If everything is accented, nothing is. The call-to-action
  floor catches the countable half.
- **Direct labels beat a detached legend** at four series or fewer — the reader stops matching
  swatches.
- **Real content over lorem** wherever real strings exist: lorem hides the layout failures that a
  47-character product name exposes.

---

**This floor is working if:** every Refuse a reviewer reports comes with the value that failed
and the procedure that produced it; no floor line is settled by "it looks fine"; and a line
nobody can measure is found in Declared guidance rather than in the floor.
