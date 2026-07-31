# Security policy

## Where the risk surface is

PelizzAI is mostly markdown, but it is **not just markdown**. The executable components it
distributes are these, and that is where the real risk lives:

| What | When it runs | What it does |
| --- | --- | --- |
| `.claude/hooks/*.mjs` and `*.ps1` | on every prompt or before a tool, **if you install them** | read the intended command/path and may block it |
| `scripts/sync-harness.mjs` and wrappers | when you run the sync or export to a project | write files into the target repository |
| `scripts/install-hooks.mjs` | when you register the hooks | edits your `.claude/settings.json` |
| `scripts/task-brief.*` and `scripts/review-package.*` | when you (or the agent) dispatch a task briefing or a review package | read the repository's plan/diff and write files under `pelizzai/data/handoffs/` (or the system temp) |

The hooks are **opt-in**: they are copied on install, but they only start running once registered —
either with `--install-hooks` or by answering "yes" to the `pelizzai-audit` proposal. You can see
what is registered with `node scripts/install-hooks.mjs --check` and undo it with `--remove`.

The skills themselves execute nothing on their own: they are text that guides an agent. But they
guide an agent that **does** have access to your shell and your files — so a malicious instruction
in a skill is a legitimate vector, and we treat it as such.

## How to report a vulnerability

Send an e-mail to **rafael.pelizza@gmail.com**, preferably with `[PelizzAI][security]` in the
subject so it does not get lost in the inbox.

**Do not open a public issue** for anything exploitable — an issue with reproduction steps is a
published exploit. A public issue is the right channel for an ordinary bug, including a hook false
positive (see below).

When reporting, include: harness version/commit, agent platform and version, the exact
reproduction steps, and the impact you managed to demonstrate. A minimal proof of concept helps
more than a long description.

This is a project maintained by one person, with no contractual SLA. The commitment is to confirm
receipt and reply with an initial assessment as soon as possible; fixing anything exploitable
takes priority over any other work in progress.

## What counts as a vulnerability here

**Counts:**

- an instruction in a skill that leads the agent to exfiltrate a secret, run a destructive
  command, or bypass the user's confirmation;
- a `pelizzai-writegate` bypass that allows writing to a protected branch or without a ratified
  kickoff;
- command injection or path traversal in the sync/export scripts — especially anything that writes
  **outside** the target directory;
- `--export-consumer` carrying the sentinel `scripts/pelizzai-source-repo.txt` to the target (this
  promotes the consumer to source repo and turns protections off);
- any path by which a hostile repository or prompt can make the harness act against the user.

**Does not count** (but send it anyway, as a normal issue):

- **A `guardrails` false positive** — a legitimate command being blocked. It is a usability bug,
  and we take it seriously, but it is not a vulnerability.
- **A `guardrails` false negative** within the declared scope. The rules are deliberately narrow:
  the hook targets the handful of commands that erase work irrecoverably and does **not** try to
  cover everything dangerous in Git. `git push --delete`, `git restore <file>`, and the like pass
  on purpose, and this is documented in the hook's header. A broad rule blocks legitimate work and
  teaches the agent to route around the net — which makes real security worse.
- **Fail-open on a hook's internal error.** If the hook itself breaks, it exits with 0 and lets
  the action proceed. This is a design decision: the hook is a second-level safety net, not a
  primary gate, and a bug in it must never hijack the user's tool. The primary gates live in the
  skills, with the user.

## The trust model, stated plainly

The hooks **reduce** the chance of an agent doing damage; they do not eliminate it, and they were
not designed to contain an adversarial agent. An agent with shell access has many ways around a
string matcher, and `guardrails` never claimed to be a sandbox.

What the harness actually offers is: explicit gates where the decision is the user's, isolation
before the first write, and evidence before any claim of completion. If you need a strong
guarantee against hostile action, that comes from your agent's and your system's sandbox and
permissions — not from here.
