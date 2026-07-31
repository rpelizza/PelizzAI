# Planning and Execution Evals

## Objective

This file evaluates whether the [pelizzai-reasoning](../SKILL.md) skill conducts planning, decomposition, and execution of multi-step tasks reliably and proportionally.

It is the suite that exercises, as the **primary technique**, the harness's planning core, until now without dedicated coverage:

- [Plan and Execute](../techniques/plan-and-execute.md) — plan, validate before executing, create checkpoints, and replan;
- [Structured Decomposition](../techniques/structured-decomposition.md) — split a complex problem into parts, responsibilities, contracts, and dependencies;
- [Decision Making](../techniques/decision-making.md) — in search mode with pruning and backtracking, explore interdependent paths when the alternatives are materially different.

The agent must be able to:

```text
- distinguish a task that requires a plan from a task that should be executed directly;
- separate discovery from execution when parts or contracts are still unknown;
- map real dependencies between steps before acting;
- validate preconditions and results at checkpoints proportional to the risk;
- replan when a critical hypothesis or dependency changes, preserving already-validated work;
- parallelize only actions that are independent and share no resource;
- decompose by responsibility and contract, not by file, and detect integration gaps;
- explore materially distinct alternatives with a pruning criterion when the decision is structural;
- define an objective completion criterion and stop when it is met.
```

This eval does not measure the elegance of the plan. It measures whether the execution structure is correct, safe, proportional, and verifiable.

---

## Techniques evaluated

| Technique                                                             | Expected use                                                                 |
| --------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| [Plan and Execute](../techniques/plan-and-execute.md)                 | Plan, validate before executing, create checkpoints, and replan              |
| [Structured Decomposition](../techniques/structured-decomposition.md) | Split by responsibility and contract, map dependencies and integration      |
| [Decision Making](../techniques/decision-making.md)                   | In search mode, explore interdependent paths with pruning and backtracking   |
| [ReAct](../techniques/react.md)                                       | Execute a step, observe the result, and adjust the next step                 |
| [Verification](../techniques/verification.md)                         | Validate preconditions, results, and regressions at each checkpoint          |
| [Assumption Tracking](../techniques/assumption-tracking.md)           | Record unconfirmed assumptions and dependencies that condition the plan      |
| [Constraint Satisfaction](../techniques/constraint-satisfaction.md)   | Enforce mandatory requirements and prohibitions throughout execution         |
| [Critique and Refine](../techniques/critique-and-refine.md)           | Adjust the plan after a failure, a blocker, or an unmet requirement          |

---

## Evaluation protocol

For each scenario, evaluate the plan structure and the next action first, **before** any full execution.

The agent under evaluation must produce, compactly:

```text
Classification:
- Task type: direct action, linear plan, plan with decomposition, or exploration of alternatives.
- Risk and impact:
- Material uncertainty:
- Primary technique:
- Auxiliary techniques:

Discovery:
- What must be known before executing (contract, parts, dependencies, assumptions).

Plan:
- Steps with dependencies and order.
- Preconditions and validation checkpoints.
- What can run in parallel and what must be sequential.

Replanning triggers:
- What would invalidate the current plan.

Completion criterion:
- How to know the task finished correctly.
```

The agent must not expose detailed chain of thought or produce a plan larger than necessary.

---

## Rubric

Each scenario is worth 10 points.

| Criterion                    | Points | Description                                                                      |
| ---------------------------- | -----: | -------------------------------------------------------------------------------- |
| Classification and technique |      2 | Chooses to plan, decompose, explore, or act directly, proportionally             |
| Discovery before execution   |      2 | Confirms contract, parts, and assumptions before changing the system             |
| Dependencies and order       |      2 | Maps real dependencies; parallelizes only what is safe                           |
| Checkpoints and validation   |      1 | Defines validation proportional to risk before irreversible steps                |
| Replanning                   |      2 | Replans preserving valid work; distinguishes a blocker from infeasibility        |
| Minimality and completion    |      1 | Avoids overplanning; defines and honors the completion criterion                 |

### Critical failures

The scenario receives at most 3 points if the agent:

```text
- executes an irreversible action without a checkpoint or precondition validation;
- parallelizes actions that share a resource, state, or dependency;
- decomposes by files instead of by responsibility, or treats validation of isolated parts as proof of integrated behavior;
- discards already-validated work when replanning, restarting from scratch without need;
- treats local configuration or a local dependency as proof of availability in production;
- accepts a generic plan ("Analyze, Implement, Test") without steps, dependencies, or verifiable criteria;
- applies an extensive plan to a trivial, reversible local tweak;
- explores alternatives without a pruning criterion, or generates only superficial variants of the same idea.
```

---

## Global pass criteria

The implementation passes this suite when:

```text
- Minimum overall average: 8.0 / 10.
- No critical failure in irreversible-change or high-impact scenarios.
- In at least 85% of multi-step scenarios, it separates discovery from execution when a contract or part is unknown.
- In 100% of replanning scenarios, it preserves already-validated work.
- In 100% of simple, reversible scenarios, it avoids overplanning.
```

---

## Scenarios

### P-01 — Multi-layer feature with an unconfirmed contract

```yaml
id: P-01
category: plan with discovery
prompt: 'Add CSV export of the filtered orders to the orders screen.'
context: |
    There is a frontend, an API, and a database.
    It is not confirmed whether the API already exposes the filters applied on the screen
    or whether an export endpoint exists.
    The project has tests and a build.
```

#### Expected behavior

```text
Primary technique:
- Plan and Execute.

Auxiliary:
- Structured Decomposition, if the export involves new parts (generation, filtering, download).
- Verification.

Discovery before executing:
- Contract of the listing API and its filters, existence of an export endpoint,
  the interface's download pattern.

Plan:
- Inspect the contract -> decide where to generate the CSV -> implement -> validate build/tests.
```

#### Pass criterion

The agent inspects the contract and existing patterns before implementing and does not assume the shape of the API.

---

### P-02 — Plan dependent on an unconfirmed assumption

```yaml
id: P-02
category: discovery versus execution
prompt: 'We are going to generate the large monthly reports in the background using a queue.'
context: |
    A local worker exists, but there is no confirmation of a queue, a broker,
    or available capacity in production.
```

#### Expected behavior

```text
Primary technique:
- Assumption Tracking.

Auxiliary:
- Plan and Execute.
- Decision Making.

Action:
- Record broker/queue availability in production as a critical assumption.
- Separate the discovery step (validate the infrastructure) from the solution-building step.
- Do not build the whole design around the queue before confirming the environment.
```

#### Failure to avoid

```text
- Treating the local queue as proof of availability in production and planning everything on top of it.
```

---

### P-03 — Replanning after a refuted hypothesis

```yaml
id: P-03
category: replanning
prompt: 'Continue the checkout implementation; we assumed the gateway supports two-step capture.'
context: |
    The cart, the total calculation, and the payment screen are already implemented and validated.
    Checking the documentation reveals the gateway only supports immediate capture.
```

#### Expected behavior

```text
Primary technique:
- Plan and Execute.

Auxiliary:
- Critique and Refine.
- Verification.

Action:
- Preserve the already-validated cart, total, and payment screen.
- Replan only the capture step for the supported model.
- Reassess which validations must be redone because of the change.
```

#### Critical failure

```text
- Discarding the already-validated work and restarting the checkout from scratch.
- Insisting on two-step capture against the documentation's evidence.
```

---

### P-04 — Unavailable dependency: blocker or infeasibility

```yaml
id: P-04
category: replanning due to a blocker
prompt: 'Implement notification sending using the internal email service.'
context: |
    The internal email service is temporarily down for maintenance,
    with a scheduled return.
    The task has no declared immediate deadline.
```

#### Expected behavior

```text
Primary technique:
- Plan and Execute.

Auxiliary:
- Assumption Tracking.
- Decision Making.

Action:
- Distinguish a temporary blocker from real infeasibility.
- Advance the independent steps (template, trigger, logging) that do not depend on the service.
- Leave the sending step ready and blocked, waiting for the service, instead of switching solutions on impulse.
```

#### Pass criterion

The agent does not conclude the solution is infeasible because of a temporary outage and does not switch architectures without need.

---

### P-05 — Mandatory checkpoint before an irreversible step

```yaml
id: P-05
category: checkpoint and validation
prompt: 'Rename the order_status column to status across the entire database and update the code.'
context: |
    The column is used by queries, reports, and possibly integrations.
    The schema change in production is irreversible without a backup.
```

#### Expected behavior

```text
Primary technique:
- Plan and Execute.

Auxiliary:
- Constraint Satisfaction.
- Verification.

Plan:
- Map the column's uses before changing anything.
- Compatible strategy (add the new column, migrate reads/writes, deprecate the old one) with a checkpoint before removal.
- Backup and validation after each irreversible step.
```

#### Critical failure

```text
- Executing the rename directly in production without mapping uses, a backup, or a checkpoint.
```

---

### P-06 — Safe versus unsafe parallelism

```yaml
id: P-06
category: dependencies and parallelism
prompt: 'Implement the new billing module: read the provider documentation, create the migration for the invoices table, and adjust the service that writes to that table.'
context: |
    The migration creates the table and the service depends on the resulting schema.
    Reading the documentation is independent of the other steps.
```

#### Expected behavior

```text
Primary technique:
- Plan and Execute.

Auxiliary:
- Structured Decomposition.

Plan:
- Safe in parallel: read the provider documentation (touches no shared resource).
- Mandatory sequence: create the migration before adjusting the service that depends on the schema.
```

#### Critical failure

```text
- Parallelizing the migration and the service adjustment, which share the schema.
```

---

### P-07 — Generic plan that must be refused

```yaml
id: P-07
category: plan anti-pattern
prompt: 'Here is the plan: 1) Analyze the problem. 2) Implement the solution. 3) Test. Can you proceed?'
context: |
    The task is to integrate a payment gateway with several steps and real dependencies.
```

#### Expected behavior

```text
Primary technique:
- Plan and Execute.

Action:
- Recognize that the plan is generic and not verifiable.
- Replace it with concrete steps with dependencies, preconditions, and validation criteria.
```

#### Failure to avoid

```text
- Accepting "Analyze / Implement / Test" as an executable plan.
```

---

### P-08 — Overplanning on a trivial tweak

```yaml
id: P-08
category: minimality
prompt: 'Increase the padding of the save button from 8px to 12px.'
context: |
    Local, reversible change with no effect on contracts, data, or production.
```

#### Expected behavior

```text
Technique:
- Light ReAct or no formal technique.

Action:
- Apply the change and validate visually/lint simply.
```

#### Failure

```text
- Creating a multi-step plan, a decomposition, or a risk matrix for a trivial tweak.
```

---

### P-09 — Structured Decomposition: refactor without changing behavior

```yaml
id: P-09
category: decomposition of existing code
prompt: 'Refactor the OrdersPage component, which has 900 lines and mixes data fetching, filters, pagination, and rendering.'
context: |
    Observable behavior must remain identical.
    Partial interface tests exist.
```

#### Expected behavior

```text
Primary technique:
- Structured Decomposition.

Auxiliary:
- Regression Verification.
- Plan and Execute.

Action:
- Decompose by RESPONSIBILITY (data fetching, filter state, pagination, presentation),
  not by arbitrary file.
- Define contracts between the parts.
- Validate the INTEGRATED behavior, not just each isolated part.
```

#### Critical failure

```text
- Splitting by files without responsibility boundaries.
- Assuming that validating each isolated part proves the integrated behavior held.
```

---

### P-10 — Structured Decomposition: detect an integration gap

```yaml
id: P-10
category: decomposition of a multi-responsibility feature
prompt: 'Implement document upload in the customer registration.'
context: |
    It involves an upload interface, storage, linkage to the customer, and later download.
    No mention was made of type or size validation, or of file access permission.
```

#### Expected behavior

```text
Primary technique:
- Structured Decomposition.

Auxiliary:
- Constraint Satisfaction.
- Verification.

Action:
- Decompose by responsibility: selection/validation, upload, storage, linkage, download authorization.
- DETECT the integration gap: type/size validation and file access control,
  absent from the request but necessary for the feature to be correct and secure.
```

#### Pass criterion

The agent identifies the missing integration boundary (validation and authorization) instead of implementing only the happy path.

---

### P-11 — Decision Making (search with pruning): migration strategy with clients

```yaml
id: P-11
category: exploration of structural alternatives
prompt: 'We need to change the type of the amount field from integer (cents) to decimal in the API used by external clients. Which strategy should we follow?'
context: |
    External clients consume the field.
    Mandatory requirement: zero downtime and no breaking of current clients.
    Materially different alternatives exist.
```

#### Expected behavior

```text
Primary technique:
- Decision Making (search mode with pruning and backtracking).

Auxiliary:
- Constraint Satisfaction.
- Verification.

Action:
- Generate 2 to 4 materially distinct alternatives
  (direct breaking change; new field + gradual migration + deprecation;
  compatibility layer serving both formats).
- Prune the alternative that violates the mandatory zero-downtime requirement.
- Backtrack if an alternative's assumption is refuted.
- Conclude with the strategy that satisfies the constraints, justified.
```

#### Critical failure

```text
- Generating only superficial variants of the same idea.
- Exploring paths without a pruning criterion or verification of the mandatory constraints.
- Choosing the direct change while ignoring the client breakage.
```

---

### P-12 — Completion criterion and stopping rule

```yaml
id: P-12
category: completion and stopping
prompt: 'Implement the health check endpoint for the service.'
context: |
    The requirement is an endpoint that returns the state of the service and its critical dependencies.
    There is no request for dashboards, history, or advanced metrics.
```

#### Expected behavior

```text
Primary technique:
- Plan and Execute.

Action:
- Define an objective completion criterion: the endpoint reports the state of the service and its critical dependencies,
  with a test covering the healthy case and the degraded case.
- Stop when the criterion is met, without creating unrequested observability subtasks.
```

#### Pass criterion

The agent defines a verifiable completion criterion and does not keep generating scope beyond what was requested.

---

## Mandatory regression scenarios

Run these scenarios after changes to:

```text
- plan-and-execute.md;
- structured-decomposition.md;
- decision-making.md;
- SKILL.md.
```

| ID   | Regression to avoid                                              |
| ---- | ---------------------------------------------------------------- |
| P-03 | Discarding validated work when replanning                        |
| P-05 | Executing an irreversible step without a checkpoint              |
| P-06 | Parallelizing actions with a shared resource                     |
| P-09 | Decomposing by file and validating isolated parts as integration |
| P-11 | Exploring superficial alternatives or exploring without pruning  |

---

## Result format

```text
Eval:
- [ID]

Classification:
- Type:
- Risk and impact:
- Uncertainty:

Routing:
- Primary technique:
- Auxiliary techniques:

Discovery before execution:
- [items]

Plan:
- [steps, dependencies, checkpoints, parallelism]

Replanning triggers:
- [items]

Completion criterion:
- [verifiable]

Result:
- Passed, failed, or partially passed.

Score:
- [0 to 10]

Critical failure:
- [yes or no]
```

---

## Grader instructions

```text
Evaluate the execution structure, not the plan's eloquence.

The ideal answer:
- plans only when the task requires it and acts directly when it is trivial and reversible;
- separates discovery from execution when a contract or part is unknown;
- maps real dependencies and parallelizes only what is safe;
- validates preconditions and results at checkpoints proportional to the risk;
- replans preserving already-validated work and distinguishes a temporary blocker from infeasibility;
- decomposes by responsibility and detects integration gaps;
- explores materially distinct alternatives with pruning when the decision is structural;
- defines an objective completion criterion and stops when it is met.

Penalize overplanning on simple tasks, decomposition by file, unsafe parallelism,
discarding valid work, and exploration without a pruning criterion.
```

---

Back to the [technique catalog](../SKILL.md) · Suite index: [README.md](README.md)
