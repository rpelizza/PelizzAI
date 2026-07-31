---
name: pelizzai-codebase-design
description: Shared vocabulary for designing deep modules. Use when the user wants to design or improve a module's interface, find deepening opportunities, decide where a seam goes, make code more testable or navigable, or when another skill (`pelizzai-tdd`, `pelizzai-brainstorming`, `pelizzai-writing-plans`) needs the deep-modules vocabulary. Trigger when designing interfaces, defining unit boundaries, or assessing testability.
---

# PelizzAI Codebase Design

Design **deep modules**: lots of behavior behind a small interface, at a clean seam, testable through the interface itself. Use this language and these principles whenever code is being designed or restructured. The goal is leverage for callers, locality for maintainers, and testability for everyone.

**Announce on start (when triggered explicitly)**, in the conversation's language: that you are using the PelizzAI Codebase Design skill to design deep modules.

## Glossary

Use these terms **exactly** — do not swap in "component", "service", "API", or "boundary". Consistent language is the point.

```text
- Module: anything with an interface and an implementation. Scale-agnostic: function, class, package, slice.
- Interface: everything a caller must know to use it correctly — the type signature, but also
  invariants, ordering, error modes, required config, performance characteristics. (Broader than "signature".)
- Implementation: what is inside the module. Distinct from Adapter.
- Depth: leverage at the interface — how much behavior you exercise per unit of interface
  you must learn. DEEP = lots of behavior behind a small interface; SHALLOW = an interface almost
  as complex as the implementation (avoid).
- Seam (Michael Feathers): a place where you can change behavior without editing there; the LOCATION of the interface.
  Where to put the seam is a design decision distinct from what goes behind it. (Say "seam", not "boundary".)
- Adapter: a concrete thing that satisfies an interface at a seam (a role, not a substance).
- Leverage: what callers gain from depth — one implementation pays off across N call sites and M tests.
- Locality: what maintainers gain — change, bugs, knowledge, and verification concentrate in one place.
```

## Deep vs shallow

```text
DEEP module    = small interface + lots of implementation (few methods, simple params, hidden complexity).
SHALLOW module = large interface + little implementation (it only passes through) — AVOID.

When designing the interface, ask:
- Can the number of methods be reduced?
- Can the parameters be simplified?
- Can more complexity be hidden inside?
```

## Principles

```text
- Depth is a property of the INTERFACE, not the implementation. A deep module may have small,
  mockable internal parts — they just are not part of the interface (internal seams vs the external seam).
- The deletion test: imagine deleting the module. If the complexity disappears, it was a pass-through; if it
  reappears across the N callers, it was paying its own cost.
- The interface is the test surface. Callers and tests cross the same seam. If you want to test BEYOND the
  interface, the module probably has the wrong shape.
- One adapter = a hypothetical seam. Two adapters = a real seam. Do not create a seam without something that actually varies at it.
```

## Designing for testability

```typescript
// Testable: receives the dependency          // Hard: creates the dependency
function processOrder(order, gateway) {}    function processOrder(order) { const g = new StripeGateway() }

// Testable: returns a result                // Hard: side effect
function computeDiscount(cart): Discount {}  function applyDiscount(cart): void { cart.total -= d }
```

Small surface: fewer methods = fewer tests; fewer params = simpler test setup.

## Design the interface twice

When the interface's shape is uncertain and the impact is high, **design it in several radically different ways** and compare them by depth, locality, and seam position. Use `pelizzai-team`/`pelizzai-subagents` to generate the alternatives — in parallel only when the exploration is read/analysis or when each alternative writes to disjoint paths under the ratified isolation; prototypes that share paths are generated serially — and `pelizzai-reasoning` (*Decision Making*, in search-with-pruning mode for the interdependent paths) to compare and **recommend** — choosing among the alternatives is architecture, and architecture is the user's decision: present the recommended one for ratification and take any material gap to `pelizzai-interview-me`.

## Integration

**Used by:** `pelizzai-tdd` (planning — deep modules and testability), `pelizzai-brainstorming` (isolation and clarity), `pelizzai-writing-plans` (file structure), `pelizzai-improving-architecture` (the deletion test and this vocabulary guide the proactive review; a missing seam caught by `pelizzai-debugging` in the regression test is an architectural finding that lands there as a candidate).

**Combines with:** `pelizzai-reasoning` (Structured Decomposition, Decision Making), `pelizzai-domain-modeling` (the domain vocabulary that names these modules).
