#!/usr/bin/env node
/**
 * PelizzAI — git guard hook (PreToolUse, tool Bash). OPT-IN.
 *
 * Blocks, BEFORE they run, destructive git commands that the harness gates already
 * forbid in prose — here the prohibition becomes executable enforcement (the only spot
 * in the harness where the model's obedience stops being a single point of failure):
 *  - git push --force / -f          (except --force-with-lease)
 *  - git reset --hard
 *  - git clean -f / -fd / --force
 *  - git branch -D / --delete --force
 *  - git checkout . / checkout -- .
 *  - git checkout -f / --force / -B
 *  - git switch -C / --force-create
 *  - git restore .                  (without --staged — working-tree loss)
 *  - git worktree remove --force
 *
 * THESE RULES ARE DELIBERATELY NARROW. The hook targets the handful of commands that
 * erase work irrecoverably; it does NOT try to cover everything dangerous in git. That
 * is why these pass unblocked, on purpose: git restore <file>, git checkout -- <file>,
 * git branch -M <name> (the canonical git init step), git push --delete/+refspec and
 * any mention of "restore"/"reset" inside a path, a commit message or a filter
 * (git add src/restore.ts, git log --grep=restore). A broad rule is costly here: it
 * blocks legitimate work, the agent learns to route around the hook, and the safety
 * net loses its value. When touching this, prefer a false negative over a false
 * positive — and test both sides.
 *
 * The command name is matched case-insensitively ("Git reset --hard" is also blocked);
 * the FLAGS stay case-sensitive, because -D/-C/-S/-W destroy and -d/-c/-s/-w do not.
 *
 * Block: exit 2 + reason and safe path on stderr (the agent reads it and corrects
 * course). Any other command: silent exit 0. Errors in the hook ITSELF: exit 0
 * (fail-open — the hook is a safety net, not the primary gate; a bug here never
 * locks the user out).
 *
 * Installation (opt-in, recommended by pelizzai-audit at bootstrap), in the consumer
 * project's .claude/settings.json:
 *   { "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [
 *       { "type": "command",
 *         "command": "node \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-guardrails.mjs\"" } ] } ] } }
 *
 * Manual test:
 *   echo '{"tool_input":{"command":"git reset --hard"}}' | node pelizzai-guardrails.mjs; echo $?
 *   → reason on stderr and exit code 2. Harmless command (e.g. "git status") → exit 0.
 *
 * Known false positive (fail-closed, acceptable for a safety net): QUOTED text that
 * contains a dangerous pattern — e.g. git commit -m "docs: explains git reset --hard" —
 * is blocked. Way out: reword the message or run the commit manually.
 *
 * On fleets without Node, use the PowerShell variant pelizzai-guardrails.ps1 (same matcher).
 * Both variants must block and allow exactly the same commands — parity is verified by
 * scripts/test-harness-contracts.ps1.
 */

import { readFileSync } from 'node:fs';

const RULES = [
  {
    name: 'git push --force / -f',
    // --force-with-lease does NOT match "--force(\s|$)" — the exception is automatic.
    // Short flags may come bundled (git push -uf origin main) — match the f inside the bundle.
    test: (s) =>
      /\bgit\b.*\bpush\b/i.test(s) &&
      (/(^|\s)--force(\s|$)/.test(s) || /(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(s)),
    why: 'a forced push rewrites remote history and can erase other people’s commits.',
    safe: 'use --force-with-lease (it only overwrites if the remote is where you expect) — and only on the user’s explicit request.',
  },
  {
    name: 'git reset --hard',
    test: (s) => /\bgit\b.*\breset\b/i.test(s) && /(^|\s)--hard\b/.test(s),
    why: 'discards commits and working-tree changes with no way back.',
    safe: 'create a return point first (named stash or WIP commit) and follow the pelizzai-recovery skill procedure.',
  },
  {
    name: 'git clean -f',
    test: (s) =>
      /\bgit\b.*\bclean\b/i.test(s) &&
      (/(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(s) || /(^|\s)--force\b/.test(s)),
    why: 'deletes untracked files irreversibly (there is no stash or reflog for them).',
    safe: 'list first with git clean -n and confirm with the user what will be deleted.',
  },
  {
    name: 'git branch -D / --delete --force',
    // -D is case-sensitive (-d is safe); it may come bundled (git branch -qD name).
    // The long form `--delete --force` (in any order) is the SAME operation as -D:
    // without it, the hook would have a trivial bypass via a mere change of spelling.
    // -M is NOT included: renaming a branch is the canonical git init step (git branch -M main).
    test: (s) =>
      /\bgit\b.*\bbranch\b/i.test(s) &&
      (/(^|\s)-[a-zA-Z]*D[a-zA-Z]*(\s|$)/.test(s) ||
        (/(^|\s)--delete(\s|$)/.test(s) &&
          (/(^|\s)--force(\s|$)/.test(s) || /(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(s)))),
    why: 'forces the removal of a branch that is NOT merged — its commits may be lost.',
    safe: 'use -d (it only deletes an already-merged branch) or confirm the discard with the user (pelizzai-finish requires the literal text "discard").',
  },
  {
    name: 'git checkout . / checkout [<ref>] -- .',
    // Covers "checkout .", "checkout -- .", "checkout <ref> -- ." and the "./" form (all discard the working tree).
    // checkout -- <file> is NOT included: discarding a named file is routine and reversible in practice.
    test: (s) =>
      /\bgit\b.*\bcheckout\b(\s+--)?\s+\.\/?(\s|$)/i.test(s) ||
      /\bgit\b.*\bcheckout\b\s+\S+\s+--\s+\.\/?(\s|$)/i.test(s),
    why: 'overwrites ALL uncommitted changes in the working tree.',
    safe: 'create a return point first (git stash push -u -m "<reason>") or restore only specific files.',
  },
  {
    name: 'git checkout -f / -B',
    // The same two destructions the hook already blocks under another spelling:
    //  -f/--force  == `git checkout .`      (overwrites the whole working tree)
    //  -B          == `git switch -C`       (overwrites an existing branch)
    // Blocking one spelling while allowing the other would leave a hole in the gate as big as the gate itself.
    // Lowercase -b (create a new branch) and `checkout -- <file>` are NOT included: neither destroys.
    test: (s) =>
      /\bgit\b.*\bcheckout\b/i.test(s) &&
      (/(^|\s)--force(\s|$)/.test(s) ||
        /(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(s) ||
        /(^|\s)-[a-zA-Z]*B[a-zA-Z]*(\s|$)/.test(s)),
    why: '-f discards ALL uncommitted changes; -B overwrites an existing branch and the commits that only existed there.',
    safe: 'create a return point first (git stash push -u -m "<reason>"); to create a branch use -b, which fails if it already exists.',
  },
  {
    name: 'git switch -C / --force-create',
    // -C is case-sensitive (-c/--create is safe: it fails if the branch already exists).
    // The flag is searched only AFTER `switch`: `git -C <path> switch <branch>` is a legitimate
    // branch change in another working tree (`-C` there selects the repo, it does not force-create).
    test: (s) => {
      const afterSwitch = /\bgit\b.*?\bswitch\b(.*)$/is.exec(s);
      if (!afterSwitch) return false;
      const rest = afterSwitch[1];
      return /(^|\s)--force-create(\s|$)/.test(rest) || /(^|\s)-[a-zA-Z]*C[a-zA-Z]*(\s|$)/.test(rest);
    },
    why: 'overwrites an existing branch with the current starting point — the commits that only existed there are lost.',
    safe: 'use -c/--create (it fails if the branch already exists); overwriting requires an explicit user decision.',
  },
  {
    name: 'git restore . (working tree)',
    // Without --staged/-S (or with explicit --worktree/-W), restore discards the working tree. "./" == ".".
    // The "." target is mandatory: git restore <file> is routine, and requiring the "." keeps the hook
    // blind to "restore" appearing in paths, messages and filters (git add src/restore.ts).
    test: (s) =>
      /\bgit\b.*\brestore\b/i.test(s) &&
      /(^|\s)\.\/?(\s|$)/.test(s) &&
      (!(/--staged\b/.test(s) || /(^|\s)-S(\s|$)/.test(s)) ||
        /--worktree\b/.test(s) ||
        /(^|\s)-W(\s|$)/.test(s)),
    why: 'without --staged, restore discards working-tree changes with no way back.',
    safe: 'git restore --staged . only unstages (safe); to truly discard, create a return point (stash) and confirm with the user.',
  },
  {
    name: 'git worktree remove --force',
    test: (s) =>
      /\bgit\b.*\bworktree\b.*\bremove\b/i.test(s) &&
      (/(^|\s)--force(\s|$)/.test(s) || /(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(s)),
    why: 'removes a dirty worktree and erases with it the uncommitted changes that lived there.',
    safe: 'inspect the worktree, preserve its contents and use git worktree remove without --force.',
  },
];

function readStdin() {
  try {
    return readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function main() {
  const input = readStdin();
  if (!input) return 0;
  let data;
  try {
    data = JSON.parse(input);
  } catch {
    return 0;
  }
  const command = data?.tool_input?.command;
  if (typeof command !== 'string' || !/\bgit\b/i.test(command)) return 0;

  // Parse per shell segment (&&, ||, ;, |, line breaks) so flags from one command
  // (e.g. rm -f) are not attributed to the git of another segment.
  const segments = command.split(/&&|\|\||;|\||\r?\n/);
  for (const seg of segments) {
    for (const rule of RULES) {
      if (rule.test(seg)) {
        process.stderr.write(
          `PelizzAI guardrails: command blocked — ${rule.name}.\n` +
            `Why: ${rule.why}\n` +
            `Safe path: ${rule.safe}\n` +
            `(Opt-in git guard hook. If the user EXPLICITLY asked for this operation, ` +
            `ask them to run it manually or to disable the hook in .claude/settings.json.)\n`
        );
        return 2;
      }
    }
  }
  return 0;
}

let exitCode = 0;
try {
  exitCode = main();
} catch {
  exitCode = 0; // fail-open: a hook error never locks the user out
}
// process.exitCode instead of process.exit(): piped stderr writes can be asynchronous and
// process.exit would truncate the block reason the agent needs to correct course.
process.exitCode = exitCode;
