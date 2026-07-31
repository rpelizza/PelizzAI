# Debugging Evals

## Objective

This file evaluates whether the [pelizzai-reasoning](../SKILL.md) skill drives debugging and incident investigation reliably.

The agent must be able to:

```text
- recognize when an error is direct and when it demands investigation;
- differentiate symptom, immediate cause, root cause, and contributing factors;
- preserve minimal evidence before containment and collect diagnostic evidence before the definitive fix;
- formulate one or more hypotheses according to the uncertainty, with no ritual quantity;
- select tests and observations with high informational value;
- avoid conclusions based on correlation, memory, or first impression;
- apply proportional containment when there is active impact;
- fix the causal mechanism, not just the symptom;
- validate the original scenario, regressions, and recurrence prevention.
```

This eval does not merely measure whether the agent found a plausible answer. It measures whether the investigation process was safe, verifiable, and proportional to the risk.

## Techniques evaluated

| Technique                                                           | Expected use                                              |
| ------------------------------------------------------------------- | --------------------------------------------------------- |
| [ReAct](../techniques/react.md)                                     | Inspect, test, observe, and update hypotheses             |
| [Root Cause Analysis](../techniques/root-cause-analysis.md)         | Investigate incidents, recurrence, and structural causes  |
| [Evidence Synthesis](../techniques/evidence-synthesis.md)           | Combine logs, code, tests, metrics, and documentation     |
| [Assumption Tracking](../techniques/assumption-tracking.md)         | Record hypotheses and still-open assumptions              |
| [Verification](../techniques/verification.md)                       | Confirm the cause and validate the fix                    |
| [Critique and Refine](../techniques/critique-and-refine.md)         | Adjust the fix after a failure, review, or regression     |
| [Constraint Satisfaction](../techniques/constraint-satisfaction.md) | Preserve legacy contracts and compatibility requirements  |
| [Decision Making](../techniques/decision-making.md)                 | Choose reversible containment under active damage         |

## Evaluation protocol

The agent must answer the scenario with a compact strategy, without exposing detailed chain of thought.

Expected format:

```text
Classification:
- Type: direct-cause bug, multi-layer bug, incident, regression, or environment diagnosis.
- Impact:
- Scope:
- Urgency:
- Primary technique:
- Auxiliary techniques:

Confirmed facts:
- [direct observations only]

Relevant hypotheses (omit plurality when the direct cause is already proven):
1. [hypothesis]
   - Evidence needed:
   - Next validation:
   - Discard criterion:

Immediate action:
- [containment, investigation, direct fix, rollback, or none]

Expected fix:
- [only after sufficient confirmation]

Validation:
- [original scenario, regressions, and observability]
```

Listing every possible hypothesis is not required. The agent must prioritize the materially plausible ones.

## Rubric

Each scenario is worth 10 points.

| Criterion      | Points | Description                                                     |
| -------------- | -----: | --------------------------------------------------------------- |
| Classification |      1 | Distinguishes a simple error, structural bug, incident, or regression |
| Evidence       |      2 | Separates observed facts from assumptions and seeks adequate sources |
| Hypotheses     |      2 | Uses a proportional quantity and confirmation/discard criteria  |
| Next action    |      1 | Chooses proportional containment, investigation, or direct fix  |
| Fix            |      2 | Attacks the causal mechanism, not just the symptom              |
| Validation     |      2 | Includes reproduction, related tests, and regression prevention |

### Critical failures

The global critical failures (assuming a root cause without evidence, changing production by trial and error, a timing workaround as the fix, skipping containment under active impact, fixing only the frontend under structural risk, exposing secrets, etc.) are cataloged in the evals index — see [README.md](README.md). Triggering any of them caps the scenario at 3 points.

## Global pass criteria

The implementation passes this set when:

```text
- Minimum overall average: 8.0 / 10.
- No critical failure in the production, security, duplication, or data-loss scenarios.
- In at least 85% of multi-layer scenarios, the agent distinguishes symptom from probable cause.
- In at least 80% of scenarios, the proposed fix includes regression validation.
- No critical-incident scenario is handled with only a visual change or a timing delay.
```

## Scenarios

### D-01 — Obvious import error

```yaml
id: D-01
category: direct cause
prompt: "The build fails with Cannot find module './users.service'. The actual file is named './user.service'."
context: |
    The error occurs locally and in CI.
    No other symptom has been reported.
```

#### Expected behavior

```text
Technique:
- Light ReAct + Verification.

Action:
- Fix the import.
- Run the affected typecheck, build, or test.

Do not use:
- Full Root Cause Analysis.
- An extensive plan.
```

Also do not use the search-with-pruning mode of [Decision Making](../techniques/decision-making.md): the cause space is deterministic and there are no interdependent paths to branch on.

#### Pass criterion

The agent does not invent a structural cause or over-investigate.

### D-02 — Slow endpoint under high volume

```yaml
id: D-02
category: performance
prompt: 'The GET /orders endpoint takes more than 12 seconds for some customers.'
context: |
    The endpoint queries the database, serializes orders, and calls an external API
    to enrich part of the response.
    No profiling is available yet.
```

#### Expected behavior

```text
Primary technique:
- Root Cause Analysis.

Auxiliary:
- ReAct.
- Evidence Synthesis.
- Verification.

Priority evidence:
- Latency per stage.
- Query execution plan.
- Number of queries.
- External call time.
- Payload size.
- Record volume.
```

#### Failures to avoid

```text
- Adding a cache without measuring the bottleneck.
- Concluding the database is slow without profiling.
- Migrating to microservices as the first answer.
```

### D-03 — Duplicated orders

```yaml
id: D-03
category: distributed incident
prompt: 'Orders are being created twice in production.'
context: |
    There are a frontend, gateway, API, database, and worker.
    Users report double-clicking, but there is no confirmed evidence.
    The system allows request retries and message reprocessing.
```

#### Expected behavior

```text
Primary technique:
- Root Cause Analysis.

Immediate action:
- Check the impact and apply reversible containment if needed.
- Preserve logs, request IDs, correlation IDs, queue data, and duplicated records.

Hypotheses:
- Double click.
- Client retry.
- Gateway retry.
- Missing idempotency.
- Worker reprocessing a message.
- Database allowing duplicates.

Expected structural fix:
- Idempotency and persistence protection.
```

#### Critical failure

```text
- Solving it with only a debounce or setTimeout in the UI.
- Declaring double click the root cause without checking requests and persistence.
```

#### Worked scoring example

Applying the rubric to a D-03 answer that attacks only the symptom:

```text
Evaluated answer (summary):
- Classifies it as "double click on the button".
- Proposes a 300 ms debounce in the frontend.
- Validates only by clicking once on the screen.

Score per criterion:
- Classification (1): 0 — treats a distributed incident as a UI bug.
- Evidence (2): 0 — does not separate report from fact; does not preserve request/correlation IDs.
- Hypotheses (2): 0 — locks onto the 1st hypothesis, ignoring retry, worker, and idempotency.
- Next action (1): 0 — no reversible containment under production impact.
- Fix (2): 0 — a debounce does not address the causal mechanism (persisted double creation).
- Validation (2): 0 — does not reproduce on the real path or cover regression.

Raw total: 0/10.
Critical failure triggered (debounce as the fix + root cause without evidence) -> cap of 3.
Final score: 0/10. Result: failed.
```

### D-04 — Authentication failure only in production

```yaml
id: D-04
category: environment
prompt: 'Login works locally but has returned 401 in production since the last deploy.'
context: |
    Possible differences: environment variables, JWT secret, algorithm,
    callback URL, proxy, server clock, library version.
```

#### Expected behavior

```text
Primary technique:
- Root Cause Analysis.

Auxiliary:
- Evidence Synthesis.
- Assumption Tracking.
- ReAct.

Action:
- Compare the healthy environment and the failing environment.
- Inspect configuration without exposing secrets.
- Review the deploy diff and the authentication logs.
- Consider rollback as containment if the impact is relevant.
```

#### Failures to avoid

```text
- Asking for or displaying the JWT secret.
- Swapping credentials by trial and error.
- Assuming the deploy is the cause by temporal precedence alone.
```

### D-05 — Stale data in the UI

```yaml
id: D-05
category: state and cache
prompt: 'After editing an order, the screen keeps showing the old value for a few minutes.'
context: |
    The API returns the updated value immediately.
    There is a cache in the browser and a distributed cache in the backend.
    It is unclear which layer serves the stale data.
```

#### Expected behavior

```text
Primary technique:
- Root Cause Analysis.

Hypotheses:
- The UI's local cache was not invalidated.
- The query cache has an incorrect stale time.
- The distributed cache was not invalidated.
- The read endpoint uses a lagging replica.
- The UI renders old state.

Priority evidence:
- The actual API response.
- Cache headers.
- Keys and TTL.
- The query state in the UI.
- The source of the displayed data.
```

#### Pass criterion

The agent does not conclude "it's the cache" without pinpointing the specific layer and mechanism.

### D-06 — Regression after a validation change

```yaml
id: D-06
category: regression
prompt: 'After adding CPF validation, the user-creation test fails.'
context: |
    The previous test used an invalid identifier.
    It is not settled whether the rule change was intended for all flows,
    including seeds, fixtures, the test environment, and legacy integrations.
```

#### Expected behavior

```text
Primary technique:
- Critique and Refine.

Auxiliary:
- Verification.
- ReAct.

Action:
- Compare the new rule, the requirements, and the test data.
- Decide whether the test should change, whether the validation should be contextual,
  or whether there is a legacy contract to preserve.
```

Use [Constraint Satisfaction](../techniques/constraint-satisfaction.md) when there is a compatibility requirement across flows (seeds, fixtures, legacy integrations).

#### Failure to avoid

```text
- Just swapping the test's CPF without confirming whether all flows must be validated.
```

### D-07 — Worker processes a message twice

```yaml
id: D-07
category: messaging
prompt: 'Some transactional emails are sent twice.'
context: |
    The queue uses at-least-once delivery.
    The worker can restart mid-processing.
    There is no confirmation whether the provider received two requests
    or whether the worker published twice.
```

#### Expected behavior

```text
Primary technique:
- Root Cause Analysis.

Hypotheses:
- The message was redelivered after a failure before the ack.
- The worker published twice.
- A provider retry occurred.
- Missing deduplication key.
- Send state was not persisted idempotently.

Expected fix:
- Idempotency and traceability by message identifier.
- An explicit retry policy.
- A send record before or during execution, per the chosen semantics.
```

#### Critical failure

```text
- Trying to "guarantee exactly once" by only tuning retries without addressing idempotency.
```

### D-08 — Intermittent upload error

```yaml
id: D-08
category: flakiness
prompt: 'Large uploads fail randomly with 502.'
context: |
    The problem occurs only in production.
    There may be a proxy, timeout, size limit, memory,
    external storage, network, or intermediate worker involved.
```

#### Expected behavior

```text
Primary technique:
- Root Cause Analysis.

Action:
- Narrow down size, file type, time of day, region, and frequency.
- Correlate client, proxy, API, and storage logs.
- Compare timeout configuration and payload limits.
- Reproduce in a controlled way with gradually larger files.
```

#### Failures to avoid

```text
- Raising every timeout without measuring.
- Blaming the network without evidence.
- Treating the 502 as an application-only error.
```

### D-09 — Recent deploy and rising errors

```yaml
id: D-09
category: post-deploy incident
prompt: 'Five minutes after the deploy, the 500 error rate rose from 0.2% to 18%.'
context: |
    The deploy included a configuration change and a code change.
    Causality is not confirmed.
    Users are actively affected.
```

#### Expected behavior

```text
Containment phase:
- Primary technique: Constraint Satisfaction.
- Auxiliary: Decision Making; ReAct to execute; Verification to monitor.

Immediate action:
- Capture metrics, logs, and the version diff.
- Assess and apply a rollback or a feature-flag disable as reversible containment.
- Prioritize restoring service before a long investigation.

After stabilizing:
- Primary technique: Root Cause Analysis.
- Compare the previous and current versions.
- Identify the error by endpoint, stack trace, and configuration.
```

#### Pass criterion

The agent separates urgent containment from the later structural fix.

### D-10 — Authorization failure

```yaml
id: D-10
category: security
prompt: 'A regular user managed to access the admin report of another customer.'
context: |
    It is unknown whether the problem lies in the frontend, backend, cache,
    tenant ID, token, route, or authorization rule.
    Data may have been exposed.
```

#### Expected behavior

```text
Primary technique:
- Root Cause Analysis.

Immediate action:
- Contain the exposure: disable the route or reinforce authorization on the server.
- Preserve access logs and the scope of exposed data.
- Assess the impact and notify the responsible party per applicable rules.

Evidence:
- The authenticated request.
- Token claims.
- Tenant ID.
- The authorization rule on the endpoint.
- Cache and segmentation key.
- Access logs.
```

#### Critical failure

```text
- Fixing it only by hiding a button in the frontend.
- Not treating it as a security incident.
- Keeping the route exposed during the investigation without assessing containment.
```

### D-11 — Divergent calculation in a report

```yaml
id: D-11
category: data and calculation
prompt: 'The monthly report shows R$ 98,450, but the finance spreadsheet shows R$ 101,120.'
context: |
    The report uses aggregation in the database.
    The spreadsheet uses a filtered export.
    It is unknown whether the difference comes from period, rounding,
    an excluded status, or duplication.
```

#### Expected behavior

```text
Primary technique:
- Evidence Synthesis.

Auxiliary:
- Verification.
- Root Cause Analysis, if a defect is confirmed.

Action:
- Normalize period, timezone, filters, status, rounding,
  and data source before comparing numbers.
- Reproduce the calculation with a traceable query.
```

#### Pass criterion

The agent does not presume one of the sources is wrong without comparing calculation criteria.

### D-12 — Documentation conflicts with behavior

```yaml
id: D-12
category: contract and behavior
prompt: 'The documentation says the endpoint accepts `status`, but the current environment returns 400.'
context: |
    There may be outdated documentation, a different version,
    additional validation, an error in the request, or environment divergence.
```

#### Expected behavior

```text
Primary technique:
- Evidence Synthesis.

Auxiliary:
- Verification.
- Assumption Tracking.

Action:
- Compare documentation, version, schema, code, and the actual request.
- Classify the conflict before fixing documentation or code.
```

#### Failure to avoid

```text
- Automatically siding with the documentation or the environment without checking scope and version.
```

### D-13 — Bug "solved" by a timeout

```yaml
id: D-13
category: superficial fix
prompt: 'A developer added a 500 ms setTimeout before fetching the data and said it fixed the empty screen.'
context: |
    The screen depends on authentication state and the user profile.
    There is no evidence that a timing delay is a requirement of the flow.
```

#### Expected behavior

```text
Primary technique:
- Critique and Refine.

Auxiliary:
- Root Cause Analysis.
- Verification.

Action:
- Identify the real dependency between authentication, profile loading,
  UI state, and the data call.
- Remove the arbitrary delay if it is not a legitimate requirement.
- Fix the synchronization, state, or trigger condition.
```

#### Critical failure

```text
- Accepting setTimeout as the definitive fix without explaining the causal mechanism.
```

### D-14 — Failure caused by a race condition

```yaml
id: D-14
category: concurrency
prompt: 'Two administrators approve the same order at nearly the same time and the stock is debited twice.'
context: |
    The action goes through the API and the database.
    There is no confirmation about transactions, locks, optimistic versioning,
    uniqueness, or idempotency.
```

#### Expected behavior

```text
Primary technique:
- Root Cause Analysis.

Evidence:
- Timeline of the two requests.
- State before and after.
- Transactions.
- Locks.
- Record version.
- The update query.
- Emitted events.

Possible structural fix:
- Appropriate concurrency control: transaction, lock,
  optimistic versioning, or an atomic operation, per the evidence.
```

#### Critical failure

```text
- Adding only a visual confirmation or a delay between clicks.
```

### D-15 — Non-reproducible failure with insufficient logs

```yaml
id: D-15
category: inconclusive investigation
prompt: 'Once a week a customer gets a 500 error, but there is no stack trace or request ID.'
context: |
    The problem has not been reproduced locally.
    Current logs are generic and do not allow correlating events.
```

#### Expected behavior

```text
Primary technique:
- Root Cause Analysis.

Action:
- Do not invent a cause.
- Declare the investigation inconclusive.
- Improve observability: request ID, safe context, stack trace,
  per-endpoint metrics, version, and event correlation.
- Define a capture strategy for the next occurrence.
```

#### Pass criterion

The agent recognizes the absence of evidence as a limitation, not as proof that no cause exists.

### D-16 — Local deterministic logic bug

```yaml
id: D-16
category: deterministic logic bug
prompt: 'A function that paginates results omits the last item of each page and sometimes repeats the first item of the next page.'
context: |
    The function runs in memory, with no network or database.
    The input dataset is fixed and the defect always reproduces.
    Suspected off-by-one in the offset/limit calculation or the cutoff condition.
```

#### Expected behavior

```text
Primary technique:
- Light Root Cause Analysis (deterministic, local defect).

Auxiliary:
- Verification.

Action:
- Reproduce with a minimal input and an explicit expected output.
- Inspect the index/limit calculation and the boundary condition (<, <=, 0- vs 1-based offset).
- Fix the boundary arithmetic; do not mask it with an after-the-fact filter.

Validation:
- Edge tests: first page, last page, single page, and empty list.
- Verify that no items are omitted or duplicated at any boundary.
```

#### Pass criterion

The agent isolates the exact boundary and covers the edge cases, without proposing a broad refactor for a one-line defect.

### D-17 — False root cause disproven by the evidence

```yaml
id: D-17
category: plausible hypothesis refuted
prompt: 'After a spike of checkout timeouts, the first hypothesis was "the database is overloaded". Before scaling the database, ask for confirmation.'
context: |
    The plausible initial hypothesis is database saturation.
    Metrics show low database CPU and connections during the period,
    but high latency concentrated in calls to an external payment gateway.
```

#### Expected behavior

```text
Primary technique:
- Root Cause Analysis.

Auxiliary:
- Evidence Synthesis.
- Assumption Tracking.

Action:
- Treat "overloaded database" as a hypothesis, not a fact.
- Seek the evidence that discriminates: latency per dependency, database CPU/connections,
  duration of the calls to the external gateway.
- Discard the 1st hypothesis upon seeing an idle database and latency at the gateway.
- Reorient toward the external dependency (timeout, retry, circuit breaker, containment).

Validation:
- Confirm the temporal correlation between the latency spikes and the gateway.
- Validate that the gateway/limit fix eliminates the timeouts in the original scenario.
```

#### Failure to avoid

```text
- Scaling or reconfiguring the database based on the 1st hypothesis, without evidence to support it.
- Keeping the initial hypothesis after the evidence points to the external dependency.
```

## Mandatory regression scenarios

Run these scenarios after changes to:

```text
- root-cause-analysis.md;
- react.md;
- verification.md;
- evidence-synthesis.md;
- critique-and-refine.md;
- SKILL.md.
```

Technique files cited: [Root Cause Analysis](../techniques/root-cause-analysis.md), [ReAct](../techniques/react.md), [Verification](../techniques/verification.md), [Evidence Synthesis](../techniques/evidence-synthesis.md), [Critique and Refine](../techniques/critique-and-refine.md), and the [pelizzai-reasoning](../SKILL.md) skill.

| ID   | Regression to avoid                               |
| ---- | ------------------------------------------------- |
| D-01 | Using RCA on a direct error                       |
| D-03 | Fixing duplication only in the frontend           |
| D-04 | Exposing or changing credentials by trial and error |
| D-05 | Blaming the cache without identifying the layer   |
| D-07 | Ignoring at-least-once delivery semantics         |
| D-09 | Investigating before containing an active incident |
| D-10 | Treating security as a UI error                   |
| D-13 | Accepting a timeout as a structural fix           |
| D-14 | Solving concurrency with a delay                  |
| D-15 | Inventing a cause without evidence                |
| D-16 | Refactoring broadly instead of fixing the boundary |
| D-17 | Keeping the 1st hypothesis after evidence refutes it |

Sibling set of general regression scenarios: [regression.md](regression.md).

## Result format

```text
Eval:
- [ID]

Classification:
- Type:
- Impact:
- Scope:
- Urgency:

Routing:
- Primary technique:
- Auxiliary techniques:

Confirmed facts:
- [items]

Relevant hypotheses:
- [items]

Immediate action:
- [containment, investigation, fix, or rollback]

Structural fix:
- [proposal or "not yet defined"]

Validation:
- [reproduction, tests, regressions, and monitoring]

Result:
- Passed, failed, or partially passed.

Score:
- [0 to 10]

Critical failure:
- [yes or no]
```

## Grader instructions

```text
Evaluate the method, not just the plausibility of the solution.

The ideal answer:
- starts from observable facts;
- treats hypotheses as hypotheses;
- chooses evidence that discriminates between hypotheses;
- protects the system before investigating at length when there is active impact;
- proposes structural fixes only after sufficient evidence;
- validates the original scenario, related cases, and recurrence prevention;
- declares its limitation when there is not enough data.

Penalize hasty conclusions, timing workarounds, trial-and-error changes, missing containment, and decorative validation.
```
