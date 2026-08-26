# Verification standard — PelizzAI

> What **correct** means in this project. Read by `pelizzai-verify`
> before judging a delivery, by `pelizzai-review` when briefing reviewers, and by
> `pelizzai-plan` when drafting validation. Written by `pelizzai-onboard` at bootstrap
> and by `pelizzai-evolve` in its own ratified change — **never during a correction**: if an
> output fails, fix the output, not the criterion.
> Budget: **150 lines hard**; Baseline at most **25 rows** (split per package before trimming).

## Acceptance criteria

<!-- Pass/fail, never a 0–5 score. Concrete, objective, observable. Example:
     "Submitting an empty email shows *Enter your email*" passes or fails;
     "UX quality: 4/5" is an opinion wearing a number. -->

- <criterion — observable pass/fail>

## Procedure

<!-- Reading the code is not exercising the artifact: review proves intent, execution proves
     behavior. Name the command and the output that proves each criterion; for a web app,
     drive it in a browser the way a user would and observe the rendered result. -->

- <criterion> → <command / interaction> → <output that proves it>

## Baseline

<!-- The latest known-good state PER SURFACE (endpoint, screen, command, bundle, suite) — one
     row each, with its numbers and evidence pointer. A new approval of a surface REPLACES its
     row (the superseded numbers live in pelizzai/data/history/, in the task that moved them).
     Appending instead of replacing buries the current truth behind stale rows, and a
     regression check reading the wrong row passes a real regression. A surface a task retired
     leaves in the same ratified change. -->

| Surface | Known-good state (numbers) | Evidence | Task |
| --- | --- | --- | --- |
| <surface> | <metric/result> | <path or command output ref> | <slug> |

_Last ratified change: <YYYY-MM-DD> — <one line: what changed and why>_
