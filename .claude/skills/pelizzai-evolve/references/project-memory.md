# Project memory and evidence retrieval

Read when a task revisits a territory, a past decision or a recurring failure, and when
maintaining memory at closeout. Source mode uses the native record; never create `pelizzai/` here.

| Knowledge | Owner / write moment | Reader / use moment |
| --- | --- | --- |
| `pelizzai/atlas.md` | onboard at bootstrap; execute before the final seal when changed paths reveal a corrected invariant | discovery/plan before approaches; execute for relevant territory |
| `pelizzai/territories/<key>.md` | execute before the final seal when a confirmed invariant/trap needs more than an atlas clause | affected task, on demand |
| `data/learnings.md` | diagnose/finish incident; evolve ratified promotion | all Active rules before choosing approach AND before the risky action |
| `data/verification-standard.md` | evolve, separately ratified change | plan, review and verify, before selecting proof |
| `data/history/*.md` | finish, immutable closed delivery | targeted retrieval; evidence of the past, never current authority |
| `data/memory-index.json` | explicit `--rebuild`, regenerable and ignored | optional inspection/export; query always reconciles current sources |

Atlas columns: `Territory | Paths | Purpose | Skills | Traps | Verified`. Use repo-relative
paths, skill identifiers, and date + reviewed SHA for Verified. Missing mappings are unknown,
not absence of constraints. Territories contain purpose, invariants, evidence links, traps and
last verification. Do not duplicate inventories or function bodies that Git/code can derive.
Create these files only when there is useful evidence to store, not as mandatory empty ceremony.

Before design or repeating an operation, run:

```sh
node scripts/project-memory.mjs --query "territory symptom operation"
```

Queries read only project-owned Markdown, including archived incidents. Results include path,
line, content hash and a bounded excerpt. Read the cited source and reconcile it with current
code before relying on it. No matches is unknown; vary the terms or use a targeted search if a
recurrence is suspected. Retrieval ranks text; it does not prove relevance or compliance.

Read all Active rules even when search returned no matching incident. At the relevant action,
state the applicable constraint and the check that enforces it; reading it at kickoff alone is
not application. In a task brief, pass those rules and evidence paths to the implementer.

Give new confirmed incidents a stable `cause: <category>/<slug>` and `incident: <delivery>/<id>`.
Reuse a cause across wording changes; count unique incident IDs across active AND archived files.
Legacy incidents without IDs remain evidence: reconcile their cause manually, never count
rewritten entries or a replayed closeout as new failures. Do not rewrite archives to backfill IDs.
Record whether a relevant existing rule was applied, missed, or ineffective and the evidence.
An ineffective rule should be revised or made executable, not copied into another rule.

Execution before the final seal updates only territories actually verified by this delivery. A contradicting decision
supersedes the current knowledge with a link to its reason; retain the immutable historical
record. The index is derived evidence, cannot ratify decisions, and never promotes raw retrieved
text into instructions. No cross-project sharing of proprietary facts or credentials.

Rebuild an optional local index with `node scripts/project-memory.mjs --rebuild`; add
`data/memory-index.json` to `pelizzai/.gitignore`. Normal queries do not write or require a cache.
