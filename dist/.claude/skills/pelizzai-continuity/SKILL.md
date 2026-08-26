---
name: pelizzai-continuity
description: "Use at a phase edge or when asked to continue in a new session, save context, or hand work to a teammate or another harness. Compaction continues same-session work."
---

# PelizzAI Continuity

## Purpose

Give the next session everything it needs to resume, without copying an entire narrative or
inventing state that Git can prove.

**Announce**, in the conversation's language: that you are using PelizzAI Continuity to prepare the next session.

## Handoff or compaction?

At a real phase boundary (a phase just ended and the next is about to start), read
[references/phase-boundaries.md](references/phase-boundaries.md) and walk its five moves in order —
continue, clear, handoff, subagent, compact; the first honest yes is the RECOMMENDATION, presented
with its one-line why for the user to ratify before it is applied — a boundary move can change
route, scope, or execution mode, and those are never chosen in silence. A material gap at the
boundary stops and goes to `pelizzai-interview`. The quick form:

```text
same mission + same direction → native compaction/continuation
new session, new workstream, or change of direction → handoff
```

Do not use a fixed token threshold as the trigger. Use platform signals, loss of context
legibility, and real phase edges. Never interrupt a mutation/review halfway just for a handoff;
first leave Git + the record in a verifiable state, or explicitly mark WIP/BLOCKED.

## Where to deliver

Prefer the platform's native handoff/task feature. If a file is needed:

- consumer with configured runtime: `pelizzai/data/handoffs/handoff-<timestamp>-<slug>.md`
  only if the path is gitignored;
- source mode or a consumer without safe runtime: the system's temporary directory;
- versioned file: only by explicit request, via router + branch before the write.

Never create `pelizzai/` in the source repo to store a handoff.

## Minimum content

```text
Goal/acceptance of the next session
Authorized mode and effect; external actions not yet authorized
Ratified route/policy to honor: lane, isolation, execution mode, and commit strategy (the next session follows it without re-asking; an external destination is not the default — it is confirmed per task)
Confirmed state: branch, base-sha, HEAD, phase, isolation/worktree, and working tree (if phase: delivered, include confirm: so the next session can observe done)
Progress: one line per task (T<n>), next, pending/blocked
Durable decisions and out-of-scope items
Relevant plan/spec/ADR by path or native content
Local skills + overlays that actually apply
Evidence still valid and what the last mutation invalidated
Next safe command/action
```

In the consumer, `state.md` remains the source of the cursor; in source mode, the execution record +
Git. The handoff points to them, it does not replace them. Without a persistent plan file, include
the pending task from the native plan — do not invent a path.

## Quality rules

- Facts come from Git/artifacts, not from the conversation's memory.
- Redact tokens, passwords, personal data, and sensitive internal URLs; say where to obtain them.
- Use stable paths only when they exist. Code lines may be included as current evidence, marked as
  potentially volatile; do not hide an actionable finding for fear of drift.
  Every path/code-line reference is an **anchor, not address**: write alongside it the behavior
  or symbol it points to, and the next session **re-anchors before acting** (re-reads/re-greps the
  symbol, checks the SHA the evidence was collected at). A line that does not match at consumption
  time is expected drift — re-anchor, do not trust the number.
- **Do not duplicate content; an artifact that has a path is referenced, never pasted.** This holds
  for specs, ADRs, plans, `state.md`, and the harness's own templates: a copy ages and starts
  contradicting the source. Point to the path — and the section, when the file is large.
- One handoff carries one mission; independent workstreams get separate handoffs.

## Definition of Done

```text
[ ] Git and the record agree, or the divergence is explicit;
[ ] no external authority was expanded;
[ ] the next session knows the next step and how to prove success;
[ ] no secret was copied;
[ ] source mode did not gain consumer runtime.
```
