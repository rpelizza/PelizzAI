# Execution capabilities

Read before recommending isolation or an execution mode. Recheck after changing platform,
checkout or runtime. Record evidence in the task record; a platform name is not evidence.

| Capability | Evidence needed | If unavailable or unknown |
| --- | --- | --- |
| Task worktree | Git supports it, project policy permits it, dependencies/config can be reproduced, ports/databases/volumes can be isolated | Use a branch in the current checkout |
| Delegation | A callable agent tool is available and authorized in this session | Implement inline and declare review limitations |
| Concurrent writers | Task worktree is feasible and selected; disjoint owned files; shared services and integration serialized | One writer: inline coordinator |
| Team coordination | Delegation plus actual messaging/lifecycle tools and a task needing coordination | Do not offer team implementation |
| Independent review | Read-only agent, contract and raw diff; clean context when supported | Declare self-review; never call it blind |

Offer only feasible implementation modes. Without a feasible task worktree, offer inline
implementation, optionally with independent read-only research/spec/quality review if delegation
exists. Read-only agents do not need worktrees. Do not create a worktree solely to unlock a menu.
The same framework is not a blocker; shared runtime resources or project policy can be.

Before delegating, determine whether context is inherited, whether agents can communicate,
whether they persist, and whether model selection is supported. Do not generalize one client's
Agent/Task API to another. Inherit the user's model unless they authorized a change.
Use fresh context for blind review when the API allows it; disclose inherited context otherwise.

Separate installation from execution: hook file present, registered in the correct event/matcher,
trusted by the host, and observed firing are four different claims. Record only proven claims.
Codex hooks use `.codex/hooks.json`; Claude Code uses `.claude/settings.json`. A changed Codex
definition requires renewed trust in the host; never grant or bypass trust from the installer.

For a required user decision, follow `pelizzai-interview`: Codex numbered chat options followed
by end of turn; Claude Code's blocking question tool when available. An asynchronous return
does not contain a user's answer.
