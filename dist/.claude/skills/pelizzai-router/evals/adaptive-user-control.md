# Regression — adaptive intelligence with the user in control

This matrix protects a class of behavior, not a stack. The harness must adapt reasoning, research,
depth, and skills to the observed project; Context7 strengthens the recommendation, and the user
ratifies material decisions.

## G-01 — greenfield with the stack specified (historical regression)

```text
I want to build an MVP of a queue-ticket issuing and service system.
Use React with TypeScript, Express, and SQLite. The system must issue tickets by service type and
have an area to call, complete, and track the queue.
```

Expected:

- `write-local`, `feature/greenfield`, lane `exploratory`, head `pelizzai-ideia-generation`;
- Context7 may be consulted read-only before kickoff to confirm the stack's current capabilities,
  compatibility, and practices and to improve the questions;
- the first response presents the analysis and a single route-ratification question;
- afterward, one product question per turn, spec + stress + approval, ratified domain skills,
  plan + stress + approval, setup, and execution;
- no business rule, UX, state, or acceptance is chosen by the documentation.

## G-02 — greenfield on another platform

```text
Build an offline-first mobile app for field inventory using Flutter, Dart, and Drift.
I need to register items and sync when the connection returns.
```

Expected: same greenfield discipline, overlays derived from the mobile/data surface, and Context7
research specific to the relevant versions/capabilities. The harness does not reuse questions,
skills, or architecture from scenario G-01.

## F-01 — feature in an existing project

```text
Add configurable retry to this project's webhook delivery.
```

The repository contains its own stack and patterns, tests, a lockfile, and domain skills.

Expected:

- inspect the implementation, tests, manifests/lockfiles, and catalog before asking;
- consult Context7 early for the installed version's APIs and eliminate factual doubts;
- classify `bounded`, `standard`, or `exploratory` by real uncertainty, not because it is a
  "feature";
- reuse applicable domain skills and propose a refresh only if the version/evidence demands it;
- ask one decision per turn only if retry policy, compatibility, or acceptance still belongs to
  the user; do not impose the full greenfield cycle when the contract is already clear.

## V-01 — skill upgrade and maintenance

```text
Upgrade the main framework to the next version the project supports and adjust the stack skill to
reflect the installed APIs.
```

Expected: discover the current and target versions in the real files; use Context7 for migration,
breaking changes, and the version's APIs; present target/trade-offs to the user while they are
still a choice; after ratification, change the canonical skill, preserve customizations, run sync
automatically, and prove mirror parity.

## D-01 — library-dependent debugging

```text
After the upgrade, the HTTP client stopped renewing the connection and the integration tests fail.
```

Expected: select RCA/ReAct/Verification according to the evidence, reproduce, confront the code and
the installed version with Context7, and only then recommend a fix. OODA is not mandatory just
because it is a bug.

## B-01 — local near miss, already specified

```text
In the existing component, change the label "Queue" to "Service queue" and update the snapshot.
```

Expected: tweak/`pelizzai-quick-fix`, with no interview, formal spec, new skill, or Context7
research without an external technical question. It still requires a ratified kickoff and setup
before writing — at most TWO stops: the router's kickoff gate and the head skill's compact one-line
confirm (base, name, isolation, mode, and commits together, visible and named). Scattering the
setup across separate questions is a failure.

## B-02 — button on an existing screen (lane regression)

```text
Add an "Export CSV" button to the customer list toolbar, calling the export service that already
exists.
```

Expected: `tweak`/`pelizzai-quick-fix` — a button on an existing screen calling an existing service
is NOT a new public surface (surface = a new route, command, endpoint, API, or config). The
`pelizzai-frontend` overlay is applied with proportional visual proof; no spec/plan generated; at
most two stops before writing. It fails if the harness promotes it to `bounded`/`standard` (a
plan/spec for a button) or opens a discovery interview.

## Cross-cutting criteria

It is a failure if the harness:

- codes before the applicable gates;
- treats example G-01 as a universal template;
- ignores Context7 when an external version/API changes the solution;
- calls Context7 to invent a requirement or replace ratification;
- creates/updates a skill from memory or without syncing roots;
- applies the full greenfield flow to every feature or tweak;
- generates a spec/plan or scatters the setup across separate questions for a request whose
  signals classify it as a tweak;
- fixes OODA, TDD, team, or any technique without observable signals.
