---
name: pelizzai-frontend
description: Use for any frontend/UI work in PelizzAI: creating or changing pages, components, flows, visual states, dashboards, forms, landing pages, design systems, CSS, responsiveness, accessibility, microinteractions, and visual QA. Trigger it especially when the task mentions "frontend", "UI", "screen", "component", "layout", "style it", "improve the look", "responsive", "Figma", "design", "avoid AI slop", or whenever an execution task touches the user experience.
---

# PelizzAI Frontend

## Purpose

Deliver interfaces that look like they were designed by someone who understood the product, the user, and the codebase. Avoid "AI slop": UI that looks good from a distance but is generic, with no clear function, full of placeholders, automatic gradients, decorative cards, fake data, incomplete states, vague text, and broken responsiveness.

This skill is not only about aesthetics. It is a product, implementation, and visual-verification gate.

**Announce on start**, in the conversation's language: that you are using the PelizzAI Frontend skill to design, implement, and verify the UI experience.

---

## Core principle

> A good interface comes from evidence. First understand the existing product, then choose a specific visual direction, implement it with the project's real patterns, and only declare it done after seeing the screen working.

Acceptable frontend must pass four proofs:

```text
1. Product: it solves the user's real flow, with realistic content and complete states.
2. System: it respects the existing stack, components, tokens, routes, data, and conventions.
3. Design: it has its own visual direction, coherent with the domain, free of automatic AI clichés.
4. Verification: it was seen in the smallest browser/viewport matrix able to reveal the likely failure.
```

### Precedence: approved intent beats heuristic

An explicit user instruction, an approved spec/Figma, a brand guide, and the product's design system prevail over this skill's **default** preferences and prohibitions. Anti-slop does not mean erasing an intentional direction: a gradient, glassmorphism, a large radius, a hero, or any other normally suspect choice remains valid when it is part of the approved system and serves the flow.

When there is no approved direction, the rules below prevent generic AI defaults. When there is one, execute it faithfully, use the real tokens/components, and flag only functional, accessibility, or technical conflicts — do not redesign out of personal taste.

---

## Mandatory flow

### 1. Read the context before designing

Before writing UI:

```text
[ ] Identify the stack, routes, framework, component library, CSS, icons, and tests.
[ ] Read neighboring screens/components that solve similar problems.
[ ] Find existing tokens: colors, spacing, radius, fonts, shadows, breakpoints.
[ ] Understand where the real data comes from: API, store, props, loader, form state, test mocks.
[ ] Look for already standardized states: loading, empty, error, disabled, selected, success.
```

If there is a design system or local components, use them. Only create a new visual component when the existing ones do not solve the case or when the task calls for a new language.

In an existing app, the first obligation is continuity. Visual differentiation does not authorize breaking navigation, density, vocabulary, or patterns the user has already learned.

### 2. Define the visual direction in one sentence

Before coding, formulate a specific thesis:

```text
"This screen should feel <visual quality> because the user needs <real goal> in a context of <domain/pressure/pace>."
```

Good examples:

```text
- "A compact, calm operational panel, because managers return to it many times a day to decide fast."
- "An editorial editor, airy and typographic, because the user needs to compare long versions without fatigue."
- "An austere financial flow, with strong contrast and explicit feedback, because input errors are costly."
```

Bad examples:

```text
- "Modern and clean."
- "Premium with a gradient."
- "A beautiful dashboard."
```

When the task comes from `pelizzai-ideia-generation` or from an approved spec/screen/Figma, the already
approved visual direction prevails: execute it faithfully. A local change inherits that direction
with no gate; do not invent a new aesthetic thesis or a new personality mid-execution.

**Visual-direction gate (redesign or new screen, before implementing):** with no approved direction,
a new screen or a redesign does not start from a silent assumption — the thesis is presented and
ratified before writing UI. Reading the product and the system and proposing the direction is still
your job (the intelligence is preserved); the direction, the dark mode, the charts/metrics, and the
layout become a recommendation to be ratified, not a decision applied silently.

```text
Proposed visual direction (reply "ok" or adjust):
- Recommended: <thesis in 1 sentence> — <why it serves the flow/domain>
- Alternatives: <2-3 materially different directions> — ONLY when there is real aesthetic ambiguity
- Durable decisions: <dark mode | charts/metrics displayed | density/layout> — a recommendation per item
```

- Real aesthetic ambiguity → 2-3 materially different directions, one recommended.
- A design system/brand guide already decides the language → one recommendation is enough; do not fabricate alternatives.
- When seeing it first reduces rework, offer mockups/wireframes navigable in the browser before implementing.

Under a closed briefing (SUBAGENT-STOP), produce no route analyses and open no gates: apply the briefing and escalate to the coordinator whatever requires a decision.

### 3. Make a compact visual plan

For small changes, keep the plan in your head. For medium/large changes, record it briefly before implementing:

```text
- Structure: the screen's hierarchy, primary/secondary areas, navigation.
- Components: which to reuse, which to create, which states to cover.
- Content: titles, labels, CTAs, error/empty messages.
- Tokens: colors, typography, spacing, radius, shadows, icons.
- Responsiveness: how the screen changes on mobile, tablet, and desktop.
- Verification: which viewports and flows will be inspected in the browser.
```

Do not present long aesthetic defenses to the user during execution. Use the plan to guide decisions and surface it only when there is a material trade-off.

---

## Anti-slop rules

### Hard prohibitions

Without explicit grounding in the spec/design system/product, do not ship:

```text
- A marketing hero when the request is a tool/app/operational screen.
- Cards inside cards, decorative floating sections, or an excess of containers with no function.
- A palette dominated by neon purple/blue, cream/terracotta, black + acid green, or a generic gradient with no domain justification.
- Orbs, blobs, bokeh, glassmorphism, or diffuse glow as default decoration.
- Big numbers with small captions when the numbers are not the real primary content.
- Placeholders like "Lorem ipsum", "Feature 1", "User Name", "Data here", or invented data on a final screen.
- Marketing copy for functional controls.
- A layout that only works in the viewport it was written in.
- Animations scattered around to mask a lack of hierarchy.
- Buttons that change size because of loading, an icon, hover, or translated text.
- Hand-drawn icons when the project already has an icon library.
```

Use fictional data only when the task is a prototype or an isolated story/test. Even then, make the data plausible for the domain and make it clear in the code/test that these are fixtures.

### Signs you are sliding into AI slop

Stop and revise if you notice:

```text
- The screen could serve any SaaS by swapping the logo.
- The colors have no relation to the domain, the urgency, or the task's hierarchy.
- The text describes the interface instead of helping the user act.
- Almost everything has the same visual importance.
- There are many effects, but none improves comprehension, speed, or confidence.
- The empty state does not say what to do.
- The error apologizes but does not explain how to fix it.
- Mobile is just the desktop version squeezed.
- The component ignores keyboard, focus, contrast, or reduced motion.
```

---

## Product design

### Hierarchy and composition

Start from the user's real work:

```text
1. What decision or action does the person need to take?
2. What information do they need to see first?
3. What is secondary, rare, or destructive?
4. What can be hidden, collapsed, or kept off the initial screen?
```

Then compose the UI:

```text
- One clear primary area per screen or per panel.
- Density matched to usage: operational = compact and scannable; editorial = more breathing room.
- Consistent alignment; asymmetry only when it communicates something.
- Spacing on a scale, not random values.
- Dividers, labels, badges, and numbering only when they carry meaning.
```

### Content and microcopy

Write like product, not like an ad.

```text
- Buttons use specific verbs: "Save changes", "Invite user", "Generate report".
- The same concept gets the same name across the whole screen.
- Titles say what the area contains, not slogans.
- Errors say what failed and how to fix it.
- Empty states offer the next possible action.
- Loading preserves the layout and avoids visual jumps.
```

Do not use visible text to explain the UI itself ("click here to…", "this card shows…") when the component can be self-explanatory.

### Controls

Choose controls by the type of decision:

```text
- Button: explicit command.
- Toggle/checkbox: binary state.
- Segmented control/tabs: mutually exclusive modes or views.
- Select/menu: a closed set of options.
- Slider/stepper/number input: adjustable value.
- Swatch: color.
- Icon with tooltip: common, compact action.
```

Use icon + text for important or ambiguous actions. Use icon-only for recognizable actions, with an `aria-label` and a tooltip when the library offers one.

### Required states

For every interactive screen/component, cover:

```text
[ ] Default
[ ] Hover/focus/active
[ ] Loading
[ ] Empty
[ ] Error
[ ] Disabled
[ ] Success/confirmation when applicable
[ ] Mobile
[ ] Long or translated content
[ ] Permissions/no access when applicable
```

If a state does not apply, know why. Do not leave a hole out of forgetfulness.

---

## Implementation

### Follow the project

Prefer local patterns:

```text
- Existing components, hooks, stores, loaders/actions, and helpers.
- CSS/Tailwind/theme tokens already defined.
- The icon library already installed, especially lucide when it is the standard.
- The existing form and validation strategy.
- The existing test and story patterns.
```

Do not add a visual library, a remote font, a heavy animation, or a design dependency without a clear need. If you need one, justify it by the gain for the product.

### CSS and layout

Build stable layouts:

```text
- Define predictable dimensions for toolbars, buttons, grids, cards, tiles, and panels.
- Use `minmax`, `clamp`, `aspect-ratio`, `min-height`, `max-width`, and responsive containers when it makes sense.
- Avoid text overflowing its container; handle wrapping, truncation, or reflow.
- Do not scale fonts by viewport width.
- Avoid negative letter-spacing.
- Cards, when they exist, must follow the system's radius; with no token/direction, prefer a discreet radius (8px or less).
- Do not put a card inside a card.
```

Control specificity. Prefer clear classes/components over cascades that fight each other.

### Accessibility and interaction

Treat accessibility as part of the delivery:

```text
[ ] Visible focus and a logical tab order.
[ ] Interactive elements with an accessible name.
[ ] Sufficient contrast for text, icons, and states.
[ ] Comfortable tap targets on touch.
[ ] `prefers-reduced-motion` respected.
[ ] Form errors associated with their fields.
[ ] No exclusive reliance on color to communicate state.
```

Animation must help the perception of cause, a state change, or spatial orientation. If it is only ornament, remove it.

---

## Visual verification

Do not finish a relevant visual/interactive change by reading code alone. The depth of the proof
follows what can break:

| Change | Minimum proof |
| --- | --- |
| Copy, label, token, or local style with no change to geometry/interaction | render the affected surface in the highest-risk viewport; a screenshot is optional. Add another viewport when there is risk of wrapping, translation, or a breakpoint. |
| Layout, component, flow, interaction, or responsiveness | desktop + mobile, the main states, and a screenshot when available. |

For the matrix's second row, whenever the project can run in a browser:

```text
1. Start or use the existing dev server.
2. Open the changed screen.
3. Check at least one desktop viewport and one mobile viewport.
4. Interact with the main states.
5. Fix overlap, text breakage, layout shift, console errors, and illegible states.
```

Use screenshots when available. Look at the image as a visual reviewer, not as a proud author:

```text
- Does the first glance make it clear what to do?
- Is there clear hierarchy?
- Is any text cut off, cramped, or competing?
- Does any element look like a generic template?
- Does mobile keep priority and legibility?
- Is there anything decorative that should be removed?
```

If running the UI is not possible, state that in the final result and compensate with a static review: inspect the CSS, structure, states, and tests. Do not fake visual verification.

---

## Harness integration

This skill is a **mandatory overlay** for any task that changes a page, component, CSS, layout, visual states, or UI experience — regardless of whether the head skill is feature, bug, or tweak. The router registers the overlay; `pelizzai-writing-plans` includes it under **Cross-cutting harness skills** and on the task; the executor must load it before implementing and before reviewing.

Playwright, the browser MCP, and screenshots are **tools** for carrying out this skill's verification, not alternatives to its contract on product, anti-slop, accessibility, states, and responsiveness.

**Combines with:**

```text
- `pelizzai-ideia-generation`: to define the spec and the visual direction before creative implementation.
- `pelizzai-execute`: to execute UI tasks inside approved plans.
- `pelizzai-tdd`: for component, form, route, and regression behavior.
- `pelizzai-review`: to review adherence to the spec and quality.
- `pelizzai-verification-before-completion`: for fresh evidence before declaring it done.
- The project's domain skills: for the real product, design system, and stack patterns.
```

In a plan task, apply this skill inside the task cycle. UI is not done just because it compiles; it must be tested, navigable, and visually verified.

---

## Definition of Done

Before saying you are finished, confirm:

```text
[ ] The UI solves the user's real goal described in the task/spec.
[ ] It uses existing patterns/components/tokens, or justifies the deviations.
[ ] It contains no placeholders, no undue fake data, and no generic text.
[ ] It covers the relevant states: loading, empty, error, disabled, success.
[ ] Responsiveness was checked in the viewports applicable to the change's risk.
[ ] It has visible focus, accessible names, and adequate contrast.
[ ] It has no decoration without function and no automatic visual clichés.
[ ] It was verified in the browser/by screenshot when possible.
[ ] The relevant tests/lint/build were run, or the limitation was stated.
```

---

## Final instruction to the agent

```text
Design the interface from the real product.
Follow the existing system before inventing.
Choose a specific visual direction, not a generic AI aesthetic.
Implement complete, responsive, accessible states.
See the screen working before declaring it done.
Remove any element that is only there to look pretty.
```
