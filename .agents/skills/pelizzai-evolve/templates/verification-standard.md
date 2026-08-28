# Verification standard — PelizzAI

> What **correct** means in this project. Read by `pelizzai-verify`
> before judging a delivery, by `pelizzai-review` when briefing reviewers, and by
> `pelizzai-plan` when drafting validation. Written by `pelizzai-onboard` at bootstrap
> and by `pelizzai-evolve` in its own ratified change — **never during a correction**: if an
> output fails, fix the output, not the criterion. At closeout, `pelizzai-finish` proposes the
> Baseline row replacement when a surface was approved with new numbers — still ratified, never
> automatic.
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

## Stack startup

<!-- Per runnable surface (service, container, worker, frontend): the bring-up command and what
     observed HEALTHY means. At final verification, pelizzai-verify brings the affected stack
     back up with these commands and watches for that signal — a green suite never substitutes
     for it.
     When the diff touches build-time inputs (Dockerfile, .env consumed by containers, build
     args, dependencies), use the no-cache path: the observed process must contain the diff. -->

| Surface | Bring-up (regular / no-cache when build inputs changed) | Healthy means |
| --- | --- | --- |
| <service> | <e.g. docker compose up -d / down → build --no-cache → up -d> | <healthcheck, readiness endpoint, or startup log line> |

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
