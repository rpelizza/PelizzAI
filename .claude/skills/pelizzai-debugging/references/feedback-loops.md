# Feedback loops — tactics menu

How to build the oracle — the reproduction command that Step 2 of `pelizzai-debugging` requires. Triage, order, and active-damage containment live in the SKILL.md, which is canonical; this menu only catalogs tactics. The menu is **ordered**: try the tactics at the top first — they produce tighter loops (fast, deterministic, executable by the agent); move down only when the one above does not apply to the bug at hand.

## The four attributes of the loop

| Attribute          | What it means                                                                    | Quick test                                      |
| ------------------ | ------------------------------------------------------------------------------- | ----------------------------------------------- |
| **red-capable**    | the command ASSERTS the exact reported symptom — fails while the bug exists, passes when it is gone | "would it be red right now, with the bug alive?" |
| **deterministic**  | same result on every run                                                         | run it 3× in a row before trusting it           |
| **fast**           | seconds, not minutes                                                             | a 2s loop allows dozens of iterations per hypothesis |
| **agent-runnable** | you run it yourself, without depending on a human clicking                       | "can I execute this now, from this terminal?"   |

## The menu (in order of preference)

1. **Failing test** — an automated test in the project's framework that asserts the symptom. The best possible loop: it is born in the format Step 4 will promote to a regression test. Use when the bug is reachable through the existing suite.

2. **Curl script** — for API/HTTP bugs: one call with a fixed payload + an assert on status/body (`curl -sf … | grep …`). No need to boot the frontend or click anything.

3. **CLI with fixture** — invoke the project's binary/entrypoint with a minimal, versionable input file (fixture) that triggers the bug. Good for parsers, generators, data pipelines.

4. **Headless browser** — when the symptom only exists in the browser: a Playwright/Puppeteer script that navigates, acts, and asserts the symptom (error text, missing element, console). Slower — keep the scenario minimal.

5. **Captured-trace replay** — record ONE real occurrence (HAR, request dump, structured log, session recording) and build a replayer that reinjects it. Turns "it happened in production" into a local command.

6. **Throwaway harness** — a disposable script that imports only the suspect module and calls it with the case's data. Cuts the rest of the system out of the path; deleted in the post-mortem, never committed.

7. **Property/fuzz with ~1000 inputs** — when the exact breaking input is unknown: generate ~1000 inputs (random with a logged seed, or property-based) and assert the violated invariant. The first input that fails becomes tactic 3's fixture.

8. **Bisection harness (`git bisect run`)** — when the bug is a REGRESSION and you have a red-capable command from any tactic above: `git bisect run <command>` finds the guilty commit on its own. The `<command>` must be **idempotent and free of persistent side effects** — bisect runs it dozens of times across different commits; a command that mutates state (writes to the database, alters versioned files, publishes something) corrupts the search and produces false culprits. The commit found feeds Step 3's hypotheses (the guilty commit's diff is the suspect list).

9. **Differential loop** — run the version that worked and the one that breaks (old vs new version, lib A vs B, prod vs local) with the SAME input and diff the output. The point where the outputs diverge locates the break without understanding the whole system.

10. **HITL (human-in-the-loop) script** — last resort, when only a human can operate (physical mobile app, corporate SSO, hardware). Do NOT converse in prose: generate a structured script that **drives** the human with `step` (instruction of what to do) and `capture` (what to observe) helpers, returning parseable `KEY=VALUE` back to you. The human becomes a structured actuator, not a prose interlocutor:

    ```bash
    step    "1. Open /checkout on the phone and tap 'Pay'"
    capture "BANNER_STATUS"  "code shown in the error banner"
    capture "SPINNER_STUCK"  "yes/no — did the spinner exceed 10s?"
    # expected return: BANNER_STATUS=502  SPINNER_STUCK=yes
    ```

    Each run of the script is one iteration of the loop; the `KEY=VALUE` pairs are the output you assert.

## Non-deterministic bugs: reproduction rate

With a flaky bug, the goal is to **raise the reproduction RATE**, not to chase the perfect repro. A bug that reproduces 50% of the time is debuggable; 1% is not.

```text
- Run the loop 100× and count the failures — the rate is your measurable baseline
  (e.g.: for i in $(seq 100); do <loop>; done | grep -c FAIL). The N× command IS the loop:
  red-capable = rate above the threshold you fixed.
- Parallelize: N concurrent processes running the loop — race conditions reproduce
  more under contention.
- Apply stress: loaded CPU/IO, shortened timeouts, delays injected at the suspect
  boundaries (with the session prefix), random test order with a LOGGED seed.
- Every change that RAISES the rate is information about the cause: rose with parallelism →
  suspect shared state; rose with a short timeout → suspect a race with I/O.
- After the fix, the green criterion is statistical too: the same 100 runs, zero failures.
```
