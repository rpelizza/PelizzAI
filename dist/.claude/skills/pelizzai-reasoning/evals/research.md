# Research Evals

## Objective

This file evaluates whether [`pelizzai-reasoning`](../SKILL.md) conducts research and evidence-based recommendations reliably.

The agent must be able to:

- recognize when current information, a specific version, or an external source requires research, and answer directly when research is not needed;
- define exactly what needs to be confirmed;
- prioritize primary, official sources appropriate to the domain;
- distinguish documentation, code, tests, changelog, announcement, news, opinion, and forum;
- compare conflicting sources without choosing arbitrarily, considering date, version, environment, scope, and applicability;
- separate confirmed fact, inference, hypothesis, recommendation, and unknown;
- avoid decorative citations or citations that do not support the conclusion;
- declare the limitation when there is not enough evidence.

This eval does not merely measure whether the answer contains links or sources: it measures whether the agent uses the right evidence for the right question.

## Techniques evaluated

| Technique                                                           | Expected use                                                             |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| [Evidence Synthesis](../techniques/evidence-synthesis.md)           | Combine sources, compare conflicts, and produce a proportional conclusion |
| [Verification](../techniques/verification.md)                       | Confirm critical or version-dependent claims                             |
| [Assumption Tracking](../techniques/assumption-tracking.md)         | Record open assumptions, gaps, or unverified dependencies                |
| [Decision Making](../techniques/decision-making.md)                 | Choose an alternative in recommendations with trade-offs                 |
| [Constraint Satisfaction](../techniques/constraint-satisfaction.md) | Filter options by requirements, prohibitions, and compatibility          |

## Evaluation protocol

Before answering in full, the agent must produce a compact strategy:

```text
Classification:
- Type: stable explanation, current fact, technical research, comparison, recommendation, or source conflict.
- Recency required:
- Relevant version, date, or scope:
- Risk of error:
- Primary technique:
- Auxiliary techniques:

Research question:
- [what needs to be confirmed]

Priority sources:
- [source types or expected official source]

Sufficiency criteria:
- [what evidence would allow a conclusion]

Foreseeable limitations:
- [what may remain unconfirmed]
```

After the research, the answer must contain only what is necessary:

```text
Conclusion:
- [main result]

Evidence:
- [relevant sources and facts]

Limitations:
- [gaps, conflicts, differences in version, environment, or scope]

Confidence level:
- [high, medium, or low]
```

The agent must not expose detailed chain of thought.

## Rubric

Each scenario is worth 10 points.

| Criterion                   | Points | Description                                            |
| --------------------------- | -----: | ------------------------------------------------------ |
| Need for research           |      1 | Researches when necessary and avoids useless research  |
| Question and scope          |      1 | Defines the fact, version, date, or condition to confirm |
| Source quality              |      2 | Prioritizes the appropriate source closest to the fact |
| Synthesis and conflicts     |      2 | Compares sources, versions, scope, and divergences     |
| Facts and inferences        |      1 | Does not present hypothesis or opinion as fact         |
| Recommendation              |      1 | Uses criteria and trade-offs when there is a choice    |
| Limitations and confidence  |      1 | Declares gaps and proportional confidence              |
| Citations and traceability  |      1 | Uses evidence that supports the central claims         |

Score bands per scenario: **Passed** = 8-10; **Partial** = 4-7; **Failed** = 0-3 (or any critical failure, which caps the score at 3).

### Critical failures

The scenario receives at most 3 points if the agent:

```text
- answers from memory when the question depends on a current fact, version, price, rule, officeholder, policy, or availability;
- uses a secondary or informal source in place of an available primary source;
- cites a source that does not support the stated claim;
- ignores a material conflict between sources;
- uses documentation for a different version without declaring the limitation;
- recommends a product, library, or service without considering explicit requirements;
- treats absence of evidence as proof of absence;
- declares high certainty without proportional evidence;
- fabricates a search, test, source, or result.
```

## Confidence calibration

The declared confidence level must be proportional to the evidence. Expected confidence by scenario type:

| Scenario type                                                                | Expected confidence when well resolved  |
| ---------------------------------------------------------------------------- | --------------------------------------- |
| Stable concept or provided primary source (S-01, S-15, S-20)                 | High                                    |
| Current fact confirmed in an official source (S-02, S-03, S-04, S-16, S-17)  | High, with date or version              |
| Conflict, comparison, or benchmark (S-05, S-06, S-07, S-11, S-12, S-13, S-19) | Medium until scope or criteria are separated |
| Recommendation under open requirements (S-08, S-09, S-14)                    | Low until material criteria are defined |
| Negative or inconclusive evidence (S-10, S-18)                               | Low, declared inconclusive              |

Declaring high confidence without proportional evidence, or low confidence when the primary source already settles the question, is a calibration deviation.

## Global pass criteria

The implementation passes this suite when:

```text
- Minimum overall average: 8.0 / 10.
- No critical failure in scenarios involving current information, security, price, compatibility, or recommendation.
- In at least 85% of version-dependent scenarios, the agent declares and verifies the correct version.
- In at least 80% of conflict scenarios, the agent identifies scope, time, or environment before concluding.
- In 100% of stable, purely conceptual scenarios, it avoids unnecessary research.
```

## Scenarios

## S-01 — Stable concept, no research

```yaml
id: S-01
category: stable explanation
prompt: 'Explain the difference between HTTP GET and POST.'
context: |
    The user wants a general explanation.
    They are not asking about current rules, a specific framework, or the behavior of an API.
```

### Expected behavior

```text
Research:
- Not needed.

Techniques:
- No formal technique, or light ReAct if needed.

Action:
- Explain directly with simple examples.
```

### Failure to avoid

```text
- Researching external documentation without need.
- Building a multi-source synthesis for a basic concept.
```

---

## S-02 — API with a specific version

```yaml
id: S-02
category: technical research
prompt: 'Does library X support OAuth with Google on FastAPI 0.115?'
context: |
    Library X and FastAPI evolve frequently.
    The user provided no documentation.
```

### Expected behavior

```text
Primary technique:
- Evidence Synthesis.

Auxiliary:
- Verification.
- Assumption Tracking, if the library version or configuration is undefined.

Priority sources:
- The library's official documentation.
- Official repository and changelog.
- FastAPI documentation for the relevant version.
- Official example or minimal test, when needed.

Conclusion:
- Must limit claims to the confirmed flow and versions.
```

### Critical failure

```text
- Answering from internal knowledge alone.
- Using an old article without confirming current compatibility.
```

---

## S-03 — Current product rule

```yaml
id: S-03
category: current information
prompt: 'What is the current price of the Pro plan for tool X?'
context: |
    The price may vary by country, currency, annual or monthly plan, and date.
```

### Expected behavior

```text
Primary technique:
- Evidence Synthesis.

Auxiliary:
- Verification.

Priority sources:
- Official pricing page.
- Applicable official terms or documentation.

Action:
- Confirm currency, country, billing cycle, and date of the check.
```

### Critical failure

```text
- Citing a blog or a third-party price comparison as the main source.
- Reporting a price without distinguishing monthly, annual, or region.
```

---

## S-04 — Current officeholder

```yaml
id: S-04
category: time-sensitive fact
prompt: 'Who is the current CEO of company X?'
context: |
    The position may have changed recently.
```

### Expected behavior

```text
Primary technique:
- Evidence Synthesis or light Verification.

Priority sources:
- Official leadership page.
- Recent official announcement.
- Regulatory filing or investor relations page, when applicable.

Action:
- Check a current source before answering.
```

### Critical failure

```text
- Assuming the current officeholder from memory.
```

---

## S-05 — Documentation versus changelog

```yaml
id: S-05
category: temporal conflict
prompt: 'The documentation says feature Y exists, but the recent changelog says it was removed. Is it still supported?'
context: |
    The documentation does not state a version.
    The changelog has a date and a release version.
```

### Expected behavior

```text
Primary technique:
- Evidence Synthesis.

Auxiliary:
- Verification.
- Assumption Tracking, if the version the user runs is unconfirmed.

Action:
- Identify the documentation's version, the changelog's version, and the installed version.
- Do not conclude until the temporal scope is separated.
```

### Pass criterion

The agent does not automatically pick the documentation or the changelog without checking which version is relevant.

---

## S-06 — Code versus documentation

```yaml
id: S-06
category: technical behavior
prompt: 'The documentation says the endpoint accepts `status`, but the current code rejects the field. Which should prevail?'
context: |
    The code is the version deployed in the current environment.
    It is not confirmed whether the documentation should reflect a future version,
    the current public contract, or legacy behavior.
```

### Expected behavior

```text
Primary technique:
- Evidence Synthesis.

Auxiliary:
- Verification.
- Assumption Tracking.

Action:
- Compare schema, implementation, integration tests, version, and the published contract.
- Distinguish current behavior from documented intent.
```

### Failure to avoid

```text
- Claiming the code always wins without considering the public contract and version.
```

---

## S-07 — Library comparison with requirements

```yaml
id: S-07
category: technical recommendation
prompt: 'Compare libraries A, B, and C for authentication in FastAPI.'
context: |
    Requirements:
    - Email login.
    - OAuth with Google.
    - PostgreSQL.
    - Refresh token.
    - No paid external service.
    - Active maintenance.
```

### Expected behavior

```text
Primary technique:
- Decision Making.

Auxiliary:
- Constraint Satisfaction.
- Evidence Synthesis.

Priority sources:
- Official documentation.
- Repository and releases.
- Official code or examples.
- Official licensing and pricing policy, if applicable.

Action:
- Eliminate incompatible options before comparing preferences.
- Declare points not yet confirmed, such as precise refresh-token compatibility.
```

### Critical failure

```text
- Choosing based on popularity alone.
- Recommending a paid service in spite of the explicit prohibition.
```

---

## S-08 — Recommendation with cost and security

```yaml
id: S-08
category: high-impact recommendation
prompt: 'Which authentication provider should we contract for the product?'
context: |
    The product processes personal data.
    Budget is limited but undefined.
    It is unclear which regions, SLA, regulatory requirements,
    or audit capabilities are needed.
```

### Expected behavior

```text
Primary technique:
- Constraint Satisfaction.

Auxiliary:
- Assumption Tracking.
- Decision Making.
- Evidence Synthesis, once minimum requirements are defined.

Action:
- Do not recommend a definitive vendor without clarifying critical requirements.
- Identify data, region, cost, SSO, audit, SLA, support, and integration.
```

### Critical failure

```text
- Choosing a vendor by reputation without security, region, or budget requirements.
```

---

## S-09 — Insufficient information

```yaml
id: S-09
category: insufficient evidence
prompt: 'What is the best observability tool?'
context: |
    No stack, budget, scale, retention, compliance,
    team, environment, or goal is defined.
```

### Expected behavior

```text
Primary technique:
- Assumption Tracking or light Decision Making.

Action:
- Explain that no universal best option exists.
- Request or infer only material criteria.
- Offer categories or conditional recommendations, without false certainty.
```

### Pass criterion

The agent does not turn an absence of requirements into a definitive ranking.

---

## S-10 — Absence of mention does not prove absence

```yaml
id: S-10
category: negative evidence
prompt: 'I found no mention of rate limiting in the documentation. So the API has no rate limit?'
context: |
    The documentation may be incomplete, or the limit may live in the terms,
    headers, account dashboard, or plan configuration.
```

### Expected behavior

```text
Primary technique:
- Verification.

Auxiliary:
- Evidence Synthesis.

Action:
- Explain that absence of mention does not prove absence.
- Check operational documentation, headers, terms, FAQ, or official support.
- Declare it inconclusive if there is not enough evidence.
```

### Critical failure

```text
- Confirming the absence of a rate limit merely because a page was not found.
```

---

## S-11 — Old article versus current source

```yaml
id: S-11
category: outdated information
prompt: 'A 2022 article says framework Z does not support feature Q. Is that still true?'
context: |
    Frameworks evolve.
    The current version was not provided.
```

### Expected behavior

```text
Primary technique:
- Evidence Synthesis.

Auxiliary:
- Verification.
- Assumption Tracking.

Action:
- Identify the current or target version.
- Check the current documentation and changelog.
- Treat the article as historical evidence, not current.
```

---

## S-12 — News versus official announcement

```yaml
id: S-12
category: recent corporate fact
prompt: 'Was company X acquired by company Y?'
context: |
    There are diverging news reports and rumors.
    The information may affect a vendor decision.
```

### Expected behavior

```text
Primary technique:
- Evidence Synthesis.

Priority sources:
- The companies' official announcements.
- Regulatory filing, when applicable.
- Investor relations page.
- Reliable outlets only as secondary support.

Action:
- Differentiate announcement, intent, signed agreement, regulatory approval, and closing of the acquisition.
```

### Failure to avoid

```text
- Treating a rumor or a preliminary news report as a completed acquisition.
```

---

## S-13 — Benchmark comparison

```yaml
id: S-13
category: benchmark
prompt: 'Is model A faster than model B?'
context: |
    Benchmarks may vary by hardware, batch size, precision,
    context length, version, and workload type.
```

### Expected behavior

```text
Primary technique:
- Evidence Synthesis.

Action:
- Request or define the context of hardware, workload, batch, latency versus throughput, and version.
- Compare equivalent benchmarks.
- Avoid a universal conclusion.
```

### Pass criterion

The agent differentiates inference speed, throughput, latency, cost, and quality.

---

## S-14 — Tool recommendation with a privacy requirement

```yaml
id: S-14
category: recommendation under constraint
prompt: 'Recommend a tool to transcribe meetings.'
context: |
    The meetings may contain confidential information.
    The user requires that the audio not be used to train public models.
    Budget, language, volume, and environment are undefined.
```

### Expected behavior

```text
Primary technique:
- Constraint Satisfaction.

Auxiliary:
- Evidence Synthesis.
- Decision Making.

Action:
- Filter options by data-use policy and contract.
- Check official terms, retention, location, and privacy controls.
- Declare the requirements still open.
```

### Critical failure

```text
- Recommending a tool without checking its data policy.
```

---

## S-15 — Factual information with a provided source

```yaml
id: S-15
category: file-based answer
prompt: 'Based on the attached document, what is the termination notice period?'
context: |
    The attached document is the primary and sufficient source.
    The user is not asking for a general rule or an external update.
```

### Expected behavior

```text
External research:
- Not needed.

Primary technique:
- Light Evidence Synthesis or no formal technique.

Action:
- Read the document, point to the relevant passage, and answer based on it.
```

### Failure to avoid

```text
- Fetching external information and replacing the document's content with a generic rule.
```

---

## S-16 — Price in a different country or currency

```yaml
id: S-16
category: price and scope
prompt: 'How much does the Team plan for tool X cost in Brazil?'
context: |
    The global page shows the price in dollars.
    There may be taxes, local billing, regional pricing,
    exchange-rate variation, or unavailability in the country.
```

### Expected behavior

```text
Primary technique:
- Evidence Synthesis.

Auxiliary:
- Verification.

Action:
- Confirm whether a Brazil price table exists, billing in BRL, taxes,
  conversion, region, and billing cycle.
- Do not automatically convert the global price into a final local price without a caveat.
```

---

## S-17 — Current service status

```yaml
id: S-17
category: current availability
prompt: 'Is the tool X API down right now?'
context: |
    Availability changes quickly.
    There is an official status page and there are user reports.
```

### Expected behavior

```text
Primary technique:
- Light Verification.

Auxiliary:
- Evidence Synthesis, if the status page and the reports diverge.

Priority sources:
- Official status page.
- Official operational communication.
- Evidence from a controlled call, if available and appropriate.

Action:
- Report the time of the check and the scope limitation.
```

### Critical failure

```text
- Answering from memory or from an isolated report.
```

---

## S-18 — Claim with a weak source

```yaml
id: S-18
category: insufficient source
prompt: 'A forum comment says library A was abandoned. Can I assume it is dead?'
context: |
    The official repository, releases, and issues are available.
```

### Expected behavior

```text
Primary technique:
- Verification.

Auxiliary:
- Evidence Synthesis.

Action:
- Check official activity: releases, commits, maintainers,
  issues, roadmap, and announcements.
- Treat the comment as a lead, not proof.
```

### Failure to avoid

```text
- Declaring abandonment based on a community comment alone.
```

---

## S-19 — Conflict between data and narrative

```yaml
id: S-19
category: data versus interpretation
prompt: 'The report claims conversion increased 20%, but the raw table shows a 2% increase.'
context: |
    There may be differences in period, metric, segment,
    rounding, baseline, or a reporting error.
```

### Expected behavior

```text
Primary technique:
- Evidence Synthesis.

Auxiliary:
- Verification.

Action:
- Reconstruct the metric definition, denominator, period,
  segment, and formula.
- Do not assume one source is wrong before normalizing criteria.
```

---

## S-20 — Request explicitly without research

```yaml
id: S-20
category: user constraint
prompt: 'Without searching the internet, explain what a REST API is.'
context: |
    The user explicitly forbids research.
    The explanation can be given from stable knowledge.
```

### Expected behavior

```text
Research:
- Do not use.

Technique:
- No formal technique.

Action:
- Explain directly and honor the prohibition.
```

### Critical failure

```text
- Researching despite the explicit instruction not to.
```

---

## Mandatory regression scenarios

Run these scenarios after changes to [Evidence Synthesis](../techniques/evidence-synthesis.md), [Verification](../techniques/verification.md), [Assumption Tracking](../techniques/assumption-tracking.md), [Decision Making](../techniques/decision-making.md), [Constraint Satisfaction](../techniques/constraint-satisfaction.md), or [pelizzai-reasoning](../SKILL.md).

| ID   | Regression to avoid                                              |
| ---- | ---------------------------------------------------------------- |
| S-01 | Useless research on a stable concept                             |
| S-02 | Answering from memory on a specific version                      |
| S-03 | Price without country or billing context                         |
| S-05 | Ignoring the temporal conflict between documentation and changelog |
| S-07 | Recommending in spite of explicit requirements                   |
| S-08 | Choosing a vendor without critical requirements                  |
| S-10 | Treating absence of mention as proof of absence                  |
| S-12 | Confusing rumor, announcement, and closing of an acquisition     |
| S-14 | Ignoring privacy in a recommendation                             |
| S-16 | Converting a global price without considering the region         |
| S-17 | Declaring current status without verification                    |
| S-20 | Violating the explicit prohibition on research                   |

See also: [README.md](README.md) (eval index) and [regression.md](regression.md) (cross-cutting regression suite).

## Result format

```text
Eval:
- [ID]

Classification:
- Type:
- Research needed:
- Recency, version, or scope:
- Risk:

Routing:
- Primary technique:
- Auxiliary techniques:

Research question:
- [verifiable question]

Priority sources:
- [sources]

Sufficiency criteria:
- [minimum evidence required]

Expected conclusion:
- [result or condition to conclude]

Limitations:
- [gaps or uncertainties]

Result:
- Passed (8-10), partially passed (4-7), or failed (0-3).

Score:
- [0 to 10]

Critical failure:
- [yes or no]
```

## Grader instructions

```text
Evaluate the epistemic quality of the answer, not the number of links.
Apply the Rubric, the Critical failures, and the Confidence calibration defined above.

Penalize weak sources when primary sources are available, decorative citations,
miscalibrated confidence, and recommendations without criteria.
```
