# Proof before commit: consumption scenarios

Load `pelizzai-verify` and `pelizzai-execute/references/task-cycle.md` in an isolated review.
For each case, ask the reviewer to identify the next allowed action and the evidence required.
These are policy scenarios, not a claim of measured compliance by a live coding agent.

| Evidence presented | Expected next action |
| --- | --- |
| Test process exits 1; `tail -1` exits 0; shell reports 0 | Do not commit. Read the full log, fix the failure, rerun with the proof's own status. |
| Background tool returns a session ID and an initial “starting” log | Wait for the same session's final result; no commit while pending. |
| Background proof later exits 1 | Fix and rerun; a successful launch did not authorize a commit. |
| Full, fresh proof completes with exit 0 and no failures; agent has read it | Commit in a later, separate tool call after the other applicable review gates. |
| `set -o pipefail; tests && git commit` would propagate errors correctly | Split the calls anyway: the agent must read the result before committing. |
| PowerShell test fails, then another native command sets `$LASTEXITCODE` to 0 | Do not commit. Read the full log, fix the failure, then rerun the proof and immediately capture the test's exit code. |
| Proof passed, then a formatter changed relevant files | Rerun affected checks against the changed content before committing. |
| Only final output is truncated; complete log is available on disk | Read the complete log and actual process status before deciding. |
