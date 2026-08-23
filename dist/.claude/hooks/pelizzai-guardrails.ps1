#!/usr/bin/env pwsh
# PelizzAI - git guard hook (PreToolUse, tool Bash), PowerShell variant. OPT-IN.
#
# Equivalent to pelizzai-guardrails.mjs, for fleets without Node. Requires PowerShell 7+ (pwsh).
#
# Blocks, BEFORE they run, destructive git commands that the harness gates already
# forbid in prose - here the prohibition becomes executable enforcement:
#  - git push --force / -f          (except --force-with-lease)
#  - git reset --hard
#  - git clean -f / -fd / --force
#  - git branch -D
#  - git checkout . / checkout -- .
#  - git checkout -f / --force / -B
#  - git switch -C / --force-create
#  - git restore .                  (without --staged - working-tree loss)
#  - git worktree remove --force
#
# THESE RULES ARE DELIBERATELY NARROW. The hook targets the handful of commands that
# erase work irrecoverably; it does NOT try to cover everything dangerous in git. That
# is why these pass unblocked, on purpose: git restore <file>, git checkout -- <file>,
# git branch -M <name> (the canonical git init step), git push --delete/+refspec and
# any mention of "restore"/"reset" inside a path, a commit message or a filter
# (git add src/restore.ts, git log --grep=restore). A broad rule is costly here: it
# blocks legitimate work, the agent learns to route around the hook, and the safety
# net loses its value. When touching this, prefer a false negative over a false
# positive - and test both sides.
#
# Block: exit 2 + reason and safe path on stderr. Any other command: silent exit 0.
# Errors in the hook ITSELF: exit 0 (fail-open - the hook is a safety net, not the
# primary gate; a bug here never locks the user out).
#
# Installation (opt-in, recommended by pelizzai-audit), in .claude/settings.json:
#   { "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [
#       { "type": "command",
#         "command": "pwsh -NoProfile -File \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-guardrails.ps1\"" } ] } ] } }
#
# Manual test (in a PowerShell shell):
#   '{"tool_input":{"command":"git reset --hard"}}' | pwsh -NoProfile -File pelizzai-guardrails.ps1; echo $LASTEXITCODE
#   -> reason on stderr and exit code 2. Harmless command (e.g. "git status") -> 0.
#
# Known false positive (fail-closed, acceptable for a safety net): QUOTED text that
# contains a dangerous pattern - e.g. git commit -m "docs: explains git reset --hard" -
# is blocked. Way out: reword the message or run the commit manually.
#
# Parity with the .mjs and contract: both variants must block and allow exactly the
# same commands - verified by scripts/test-harness-contracts.ps1.

$ErrorActionPreference = 'SilentlyContinue'
try {
  $raw = [Console]::In.ReadToEnd()
  if (-not $raw) { exit 0 }
  $data = $null
  try { $data = $raw | ConvertFrom-Json } catch { exit 0 }
  $command = $data.tool_input.command
  if (-not ($command -is [string]) -or $command -notmatch '\bgit\b') { exit 0 }

  # -match (case-insensitive) recognizes the command: "Git reset --hard" is also blocked.
  # -cmatch (case-sensitive) is mandatory on the FLAGS: -D/-C/-S/-W destroy, -d/-c/-s/-w do not.
  $rules = @(
    @{ Name = 'git push --force / -f'
       # --force-with-lease does NOT match "--force(\s|$)" - the exception is automatic.
       # Short flags may come bundled (git push -uf origin main) - match the f inside the bundle.
       Test = { param($s) ($s -match '\bgit\b.*\bpush\b') -and (($s -cmatch '(^|\s)--force(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)')) }
       Why  = 'a forced push rewrites remote history and can erase other people''s commits.'
       Safe = 'use --force-with-lease (it only overwrites if the remote is where you expect) - and only on the user''s explicit request.' },
    @{ Name = 'git reset --hard'
       Test = { param($s) ($s -match '\bgit\b.*\breset\b') -and ($s -cmatch '(^|\s)--hard\b') }
       Why  = 'discards commits and working-tree changes with no way back.'
       Safe = 'create a return point first (named stash or WIP commit) and follow the pelizzai-recovery skill procedure.' },
    @{ Name = 'git clean -f'
       Test = { param($s) ($s -match '\bgit\b.*\bclean\b') -and (($s -cmatch '(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)') -or ($s -cmatch '(^|\s)--force\b')) }
       Why  = 'deletes untracked files irreversibly (there is no stash or reflog for them).'
       Safe = 'list first with git clean -n and confirm with the user what will be deleted.' },
    @{ Name = 'git branch -D / --delete --force'
       # -D is case-sensitive (-d is safe); it may come bundled (git branch -qD name).
       # The long form `--delete --force` (in any order) is the SAME operation as -D:
       # without it, the hook would have a trivial bypass via a mere change of spelling.
       # -M is NOT included: renaming a branch is the canonical git init step (git branch -M main).
       Test = { param($s) ($s -match '\bgit\b.*\bbranch\b') -and (($s -cmatch '(^|\s)-[a-zA-Z]*D[a-zA-Z]*(\s|$)') -or (($s -cmatch '(^|\s)--delete(\s|$)') -and (($s -cmatch '(^|\s)--force(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)')))) }
       Why  = 'forces the removal of a branch that is NOT merged - its commits may be lost.'
       Safe = 'use -d (it only deletes an already-merged branch) or confirm the discard with the user (pelizzai-finish-task requires the literal text "discard").' },
    @{ Name = 'git checkout . / checkout [<ref>] -- .'
       # Covers "checkout .", "checkout -- .", "checkout <ref> -- ." and the "./" form (all discard the working tree).
       # checkout -- <file> is NOT included: discarding a named file is a routine operation.
       Test = { param($s) ($s -match '\bgit\b.*\bcheckout\b(\s+--)?\s+\.\/?(\s|$)') -or ($s -match '\bgit\b.*\bcheckout\b\s+\S+\s+--\s+\.\/?(\s|$)') }
       Why  = 'overwrites ALL uncommitted changes in the working tree.'
       Safe = 'create a return point first (git stash push -u -m "<reason>") or restore only specific files.' },
    @{ Name = 'git checkout -f / -B'
       # The same two destructions the hook already blocks under another spelling:
       #  -f/--force == `git checkout .`  (overwrites the whole working tree)
       #  -B         == `git switch -C`   (overwrites an existing branch)
       # Blocking one spelling while allowing the other would leave a hole in the gate as big as the gate itself.
       # Lowercase -b and `checkout -- <file>` are NOT included: neither destroys.
       Test = { param($s) ($s -match '\bgit\b.*\bcheckout\b') -and (($s -cmatch '(^|\s)--force(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*B[a-zA-Z]*(\s|$)')) }
       Why  = '-f discards ALL uncommitted changes; -B overwrites an existing branch and the commits that only existed there.'
       Safe = 'create a return point first (git stash push -u -m "<reason>"); to create a branch use -b, which fails if it already exists.' },
    @{ Name = 'git switch -C / --force-create'
       # -C is case-sensitive (-c/--create is safe: it fails if the branch already exists).
       Test = { param($s) ($s -match '\bgit\b.*\bswitch\b') -and (($s -cmatch '(^|\s)--force-create(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*C[a-zA-Z]*(\s|$)')) }
       Why  = 'overwrites an existing branch with the current starting point - the commits that only existed there are lost.'
       Safe = 'use -c/--create (it fails if the branch already exists); overwriting requires an explicit user decision.' },
    @{ Name = 'git restore . (working tree)'
       # Without --staged/-S (or with explicit --worktree/-W), restore discards the working tree. "./" == ".".
       # The "." target is mandatory: git restore <file> is routine, and requiring the "." keeps the hook
       # blind to "restore" appearing in paths, messages and filters (git add src/restore.ts).
       Test = { param($s) ($s -match '\bgit\b.*\brestore\b') -and ($s -cmatch '(^|\s)\.\/?(\s|$)') -and ((-not (($s -cmatch '--staged\b') -or ($s -cmatch '(^|\s)-S(\s|$)'))) -or ($s -cmatch '--worktree\b') -or ($s -cmatch '(^|\s)-W(\s|$)')) }
       Why  = 'without --staged, restore discards working-tree changes with no way back.'
       Safe = 'git restore --staged . only unstages (safe); to truly discard, create a return point (stash) and confirm with the user.' },
    @{ Name = 'git worktree remove --force'
       Test = { param($s) ($s -match '\bgit\b.*\bworktree\b.*\bremove\b') -and (($s -cmatch '(^|\s)--force(\s|$)') -or ($s -cmatch '(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)')) }
       Why  = 'removes a dirty worktree and erases with it the uncommitted changes that lived there.'
       Safe = 'inspect the worktree, preserve its contents and use git worktree remove without --force.' }
  )

  # Parse per shell segment (&&, ||, ;, |, line breaks) so flags from one command
  # (e.g. rm -f) are not attributed to the git of another segment.
  $segments = $command -split '&&|\|\||;|\||\r?\n'
  foreach ($seg in $segments) {
    foreach ($rule in $rules) {
      if (& $rule.Test $seg) {
        [Console]::Error.WriteLine("PelizzAI guardrails: command blocked - $($rule.Name).")
        [Console]::Error.WriteLine("Why: $($rule.Why)")
        [Console]::Error.WriteLine("Safe path: $($rule.Safe)")
        [Console]::Error.WriteLine('(Opt-in git guard hook. If the user EXPLICITLY asked for this operation, ask them to run it manually or to disable the hook in .claude/settings.json.)')
        exit 2
      }
    }
  }
} catch {
  # fail-open: a hook error never locks the user out
}
exit 0
