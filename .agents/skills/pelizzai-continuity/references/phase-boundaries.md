# Phase boundaries — five moves, asked in order

A **phase** is a chunk of work that ends when you would say "ok, that part is done": the discovery,
the spec, the plan, the implementation of a task group, the QA. The **boundary** between two phases
is the only place where a context decision belongs. Mid-phase there is no decision: continue, or
split what remains into subagents. Compacting mid-phase loses the thread.

At every boundary, walk the five moves **top to bottom; the first honest "yes" wins**:

## 1. Can you continue in this session?

Yes when either holds: the next phase needs this one as a **primary source** (it wants the
reasoning verbatim, not a summary of it — discovery → spec and spec → plan are the standard case),
or there is comfortably enough context room left for the next phase. Continue costs nothing and
loses nothing; rule it out before anything else.

## 2. Is this context irrelevant to what comes next?

If everything here — the exploration, the dead ends, the decisions already written down — is
disposable, **clear** and start fresh. It is the cheapest move: instant, and it returns the whole
window. The cost of getting it wrong is one-way: clear a *relevant* context and the **why** behind
what was built is gone; re-reading the diff does not bring it back.

## 3. Does the work need to travel?

**Handoff** is narrow. It exists for exactly four cases: a new harness (Claude → Codex/Gemini/
Cursor), a new directory or repository, another person or teammate, or forking a side workstream
discovered mid-phase without derailing the current one. What a handoff buys is **portability** — a
file that travels. If nothing is travelling, skip it. (The handoff's content contract is this
skill's §Minimum content.)

## 4. Can the next phase run without steering?

If it is scoped tightly enough to run unattended — an automated review reading a diff, a mechanical
sweep — send it to a **subagent** with a closed briefing and leave this session untouched.

## 5. Otherwise, compact.

Relevant context, same repo, and you must stay in the loop: this is where the walk usually lands.
Give the compaction an instruction ("we are going to QA area X") so the summary keeps what the next
phase needs. Compaction is the **default, not the first reach**: the four questions above are all
cheaper or more precise, and starting here produces the classic failure — a fresh session
confidently wrong about a decision the summary flattened.

## Why this order

Every move except *continue* turns a **primary source** (the session as it happened: full
information, lots of noise, little room) into a **secondary source** (a summary of it: lossy, less
noise, lots of room). Pay the lossiness only when staying costs more than it saves — which is why
question 1 comes first. The questions carry judgment; the same boundary can go either way on two
different days. The value is in asking them **in order, at the boundary** — not mid-work.

## The plan boundary (the one that recurs)

The edge after a plan is ratified is the boundary this harness hits most. The plan is written to be
executable with zero repo context — so execution rarely needs the planning session as a primary
source. The default recommendation at that edge: **offer the user a fresh session (or handoff) for
execution**, with the plan's path as the seed; continue in-session only when the user prefers it or
the remaining room clearly fits the execution. `pelizzai-plan` makes this offer at its closing gate.
