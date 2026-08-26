---
name: pelizzai-security
description: "Security overlay for any diff touching auth, untrusted input, queries, sensitive data, uploads, CORS/SSRF, dependencies, integrity, or logging — web, API, or AI systems, whatever the stack."
---

# PelizzAI Security

## Goal

Review the diff and the affected trust boundaries, finding plausible paths of exploitation or of
safe failure before integrating.

Baseline: [OWASP Top 10:2025](https://owasp.org/Top10/2025/0x00_2025-Introduction/). When
maintaining this skill, confirm the current official edition; do not preserve old categories from
memory.

**Announce**, in the conversation's language: that you are using the PelizzAI OWASP skill to review this change's security surfaces.

## When

The router/plan records this overlay as soon as the scope or diff touches auth, authorization,
external input, queries, secrets/PII, uploads, network/URLs, dependencies/build, integrity,
logging/alerting, or failure handling. Review can promote it when it discovers an unanticipated
surface.

## Scope

- task not yet committed: the full working tree, including staged/untracked;
- final candidate: `base-sha..candidate-head`;
- read-only request: an explicitly delimited range/PR, without creating state.

List inputs, actors, trust boundaries, assets, and external effects. Do not review the whole repo
by reflex, but follow a chain called from the diff when that is necessary to prove authorization
or sanitization.

## OWASP Top 10:2025 — applicable lenses

| # | Category | Question for the diff |
| --- | --- | --- |
| A01 | Broken Access Control | Authorization per object/action? IDOR? SSRF/internal access controlled? |
| A02 | Security Misconfiguration | Defaults, debug, CORS/headers, permissions, or fail-open? |
| A03 | Software Supply Chain Failures | Dependencies/build/publish necessary, pinned, and with provenance/integrity? |
| A04 | Cryptographic Failures | Secret/data in the clear? Algorithm, keys, storage, and transport adequate? |
| A05 | Injection | Does input reach SQL, shell, template, LDAP, or an interpreter without parameterization/escaping? |
| A06 | Insecure Design | Were trust boundaries, abuse, rate/size limits, and business rules modeled? |
| A07 | Authentication Failures | Session/token, expiration, rotation, brute-force, and recovery correct? |
| A08 | Software or Data Integrity Failures | Does deserialization, an update, an artifact, or data cross a boundary without integrity? |
| A09 | Security Logging & Alerting Failures | Does the event produce a log without secrets/PII and an actionable alert? |
| A10 | Mishandling of Exceptional Conditions | Do errors, timeouts, retries, partial failures, and abnormal states fail safely? |

Load only the categories touched. OWASP is a taxonomy of lenses, not a list to tick without
evidence.

## Finding and proof

For each suspicion:

```text
category + severity
file:line
precondition → input → boundary → effect → impact
observed evidence
minimal fix
test/check that fails before and passes after, when automatable
```

Without a plausible path, downgrade or withdraw it; do not invent an exploit. A new dependency
requires an official source and an available scanner/lockfile, without claiming CVE absence when
the lookup never ran.

## Lifecycle

A security fix changes the candidate: implement before the seal, run the proof, consolidate, and
reopen the affected categories/reviews. Critical/High block `validated-head`; accepted risk
requires the owner's explicit decision and an appropriate durable record. Finish-task never runs
this overlay.

## Red flags

```text
- A late offer in finish-task.
- A ten-category checklist unrelated to the diff.
- A theoretical critical finding without boundary/path.
- Approving input/authorization without following the data to the enforcement point.
- Consulting CVEs/dependencies from memory.
- Fixing after validated-head without invalidating the seal.
```

## Integration

It is an overlay of the router/writing-plans/execution-plans/review and composes with domain
skills. Use Evidence Synthesis when logs/scanners/sources diverge; do not turn the taxonomy into
universal reasoning.
