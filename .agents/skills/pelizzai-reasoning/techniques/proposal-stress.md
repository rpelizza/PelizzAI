# Proposal Stress (Assumption Tracking applied)

## Purpose

Use Proposal Stress to **stress-test a new request before routing**: expose the assumptions, the
material gaps, the risks, and the alternatives the solution would depend on, producing the
**Proposal Analysis** that `pelizzai-router` presents to the user. It is
[Assumption Tracking](assumption-tracking.md) applied with a scope-premortem lens — not a new
technique, but the standardized routine on top of the same assumption machine.

> The Proposal Analysis is a presented result, not a question; it feeds the discovery gate
> when there is a material gap.

The recovered gain is behavioral: before acting, the harness once again exposes assumptions/gaps/
risks/alternatives instead of silently choosing one reading of scope/UX/architecture/security and
moving on.

## When to use

Produce the Proposal Analysis when the request has a **non-trivial mutating effect** with material
uncertainty:

```text
- a new or changed feature;
- a refactor with a contract/boundary at stake;
- a structural, data, or security change;
- any request in which a scope/UX/architecture decision is still open.
- every greenfield product/project, even with the stack stated.
```

## When to avoid

Do not produce the analysis (it collapses to zero) for:

```text
- read-only tasks (explaining, analyzing, reviewing without writing);
- trivial low-uncertainty tweaks (text, a label, a mechanical rename, obvious config).
```

In those cases the route is announced without a stop — do not turn skill activation into a preamble
bigger than the task. **High risk is not a trigger for an expanded analysis**: a high-risk refactor
with clear scope collapses the analysis into one line; risk raises proof, gates, and overlays, it
does not create artificial uncertainty. The trigger for the expanded analysis and the discovery
gate is the **material gap**, not risk alone.

## Routine

Given a request:

1. **List the assumptions** the plan would depend on to proceed (functional, architectural, data,
   security, integration, compatibility). Use the hidden-assumption signals from
   [Assumption Tracking](assumption-tracking.md).
2. **Classify each assumption** by impact × uncertainty (the same criticality matrix).
3. **Mark as MATERIAL** the assumptions whose wrong reading would change a requirement, scope, UX,
   architecture, security, data, or acceptance. A reversible product decision still belongs to the
   user; only a mechanical detail covered by a ratified contract may become an operational assumption.
4. **Emit the compact analysis** and point out **which material gaps justify PROPOSING discovery**
   (compact brainstorming or a focused `pelizzai-interview-me`).

## Analysis format (≤ 6 bullets, proportional)

```text
Facts and decisions already ratified:
- <item> — <evidence or user decision>

Decisions still open:
- <decision> — changes <requirement/scope/UX/architecture/security/data/acceptance>

Material gaps (change scope/UX/architecture/security/data):
- <gap> — what changes if the reading is different

Concrete risks:
- <risk> — when it appears

Materially different alternatives (when they exist):
- <alternative> — central trade-off
```

For an already-specified bounded/tweak change, the pass collapses into **one line**: `No material
gaps; stated contract: <short list>`. Greenfield never collapses.

## Link to routing

- **No material gap** → recommend the route and await ratification if there is a mutation.
- **≥ 1 material gap** → the router recommends discovery; the interview then resolves one decision
  per turn. Skipping is an explicit user decision; a recommendation is not an authorization.

## Subagent carve-out

Under a closed briefing (SUBAGENT-STOP), do NOT produce the always-on analysis and do NOT open the
discovery gate: apply the briefing and escalate to the coordinator the scope decision it left open.

## Relation to other techniques

| Technique                                      | Role relative to Proposal Stress                                          |
| ---------------------------------------------- | ------------------------------------------------------------------------- |
| [Assumption Tracking](assumption-tracking.md)  | The assumption machine (identify, classify, validate) this routine applies |
| [Constraint Satisfaction](constraint-satisfaction.md) | Separates the mandatory from the desirable among the gaps found      |
| [Decision Making](decision-making.md)          | Compares the materially different alternatives when the gate opens        |
| [pelizzai-interview-me](../../pelizzai-interview-me/SKILL.md) | Sister skill that resolves the material gaps once discovery is accepted |

## Anti-patterns

```text
- Running the analysis on a read-only task or a trivial tweak (ceremony with no effect).
- Silently choosing one reading of scope/UX/architecture and proceeding without declaring it.
- Treating reversibility as authorization for the LLM to decide a product preference.
- Treating high risk as uncertainty and inflating the analysis of a clearly scoped request.
- Turning the analysis into a question instead of a presented result.
- Opening the discovery gate under a closed briefing (SUBAGENT-STOP).
```

Back to the [technique catalog](../SKILL.md).
