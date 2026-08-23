#!/usr/bin/env node
/**
 * PelizzAI — writegate hook (PreToolUse). OPT-IN. Fail-CLOSED on the invariant, fail-OPEN on error.
 *
 * Safety net that moves the TWO irreversible autonomies the redesign introduced from model
 * obedience to executable enforcement: writing product without isolation and writing code
 * before the gate is ratified. It does NOT decide the route — it only hands control back
 * to the human gate. Mirrors the spirit and safety envelope of pelizzai-guardrails.mjs
 * (read it before changing this file).
 *
 * Fires BEFORE the write, on two sibling matchers that share this same file:
 *  - Write | Edit | MultiEdit | NotebookEdit  → reads tool_input.file_path / .notebook_path;
 *  - Bash                                     → detects write redirection in
 *    tool_input.command (>, >>, &>, tee, sed -i, Set-Content/Add-Content/Out-File) to
 *    paths INSIDE the project root. Same rule on both sides. Null sinks (NUL, $null,
 *    /dev/null) and targets that resolve OUTSIDE the root (incl. $env:TEMP, %TEMP%, absolutes)
 *    are never product writes and never block.
 *
 * RULE A (invariant, both modes) — isolation before the first write:
 *   writing a PRODUCT path (outside pelizzai/) inside the repo root while on a protected branch
 *   (main/master/develop/dev, plus origin/HEAD's default) or on a detached HEAD → BLOCKS.
 *   CARVE-OUT: metadata writes in pelizzai/** are allowed even here (the system updating itself;
 *   it is file writes only — the commit still follows the task-branch flow). Way out (product):
 *   isolate via pelizzai-starting-branch.
 *
 * RULE B (consumer only: pelizzai/ exists and this is NOT the source repo) — no code before the gate:
 *   writing a PRODUCT path (outside pelizzai/) while pelizzai/data/state.md does NOT
 *   contain the marker "kickoff: ratified" → BLOCKS. Writes in pelizzai/ (state, plan,
 *   spec) are always allowed: they are the artifacts that record the gate itself.
 *   DELIBERATE SCOPE: the hook locks ONE marker — the kickoff. The greenfield stages
 *   (discovery → spec → stress → approval → plan → stress → approval) remain
 *   mandatory, but they live in the skills, NOT in runtime enforcement: turning them into
 *   a file turnstile locked out legitimate work whenever the state fell one step behind
 *   the conversation. Doctrine in the skills; in the hook, only the invariant.
 *   In SOURCE MODE (PelizzAI source repo: sentinel pelizzai-source-repo.txt) Rule B is SKIPPED — there the
 *   marker lives in the native execution record, not in a file, and only Rule A applies.
 *
 * Block: exit 2 + reason and safe path on stderr (the agent reads it and corrects the route).
 * Errors in the hook ITSELF and cases it cannot decide safely: exit 0 (fail-open —
 * a bug or false positive here never locks the user out). When it cannot read the kickoff in a
 * consumer without state.md, it allows the write and warns at most once per window (no spam).
 *
 * Install (opt-in, recommended by pelizzai-audit at bootstrap, merged without overwriting
 * existing hooks/permissions), in the consumer project's .claude/settings.json — BOTH
 * matchers are required to also cover writes via shell:
 *   { "hooks": { "PreToolUse": [
 *       { "matcher": "Write|Edit|MultiEdit|NotebookEdit", "hooks": [
 *           { "type": "command",
 *             "command": "node \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-writegate.mjs\"" } ] },
 *       { "matcher": "Bash", "hooks": [
 *           { "type": "command",
 *             "command": "node \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-writegate.mjs\"" } ] } ] } }
 *
 * Manual test:
 *   echo '{"tool_input":{"file_path":"src/app.ts"},"cwd":"/path/to/repo"}' | node pelizzai-writegate.mjs; echo $?
 *   → on a protected branch or without "kickoff: ratified" in state.md: reason on stderr and exit 2.
 *     On a task branch with the kickoff ratified, or outside the repo: exit 0.
 *
 * The user can disable the hook in .claude/settings.json — it is never an inescapable block.
 * On fleets without Node, use the PowerShell variant pelizzai-writegate.ps1 (identical behavior).
 */

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, resolve, isAbsolute } from 'node:path';
import { execFileSync } from 'node:child_process';
import { tmpdir } from 'node:os';

// Default protected branches (Rule A). origin/HEAD enriches the list at runtime.
const PROTECTED = ['main', 'master', 'develop', 'dev'];
// Machine-readable markers for the sequential gates in state.md (kickoff/post-plan ratified
// by the user: content + isolation + mode + commit). The writegate and resumption depend on it.
// Also accepts "ratificado": legacy pt-BR states written before the English harness.
const KICKOFF_RATIFIED = /kickoff:\s*rati(?:fied|ficado)/i;
// DEDICATED sentinel of the PelizzAI source repo (source mode): when present, Rule B is skipped.
// Single unambiguous criterion: the manifest and sync-harness also exist in consumers
// installed via -ExportConsumer and do NOT indicate source mode.
const SOURCE_SENTINELS = [
  ['scripts', 'pelizzai-source-repo.txt'],
];
// "Could not decide" fail-open: warns at most once per window (per repo) to avoid spam.
const WARN_SNOOZE_MS = 86400000; // 24h

function readStdin() {
  try {
    return readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

// git with the stdin cwd; '' on ANY failure (git missing, outside a repo, nonexistent ref).
function git(cwd, args) {
  try {
    return execFileSync('git', args, {
      cwd,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
      timeout: 4000,
    }).trim();
  } catch {
    return '';
  }
}

// Forward slashes and no trailing slash, for prefix comparison robust to \ and /.
function norm(p) {
  return String(p).replace(/\\/g, '/').replace(/\/+$/, '');
}

// Windows and macOS compare paths case-insensitively; Linux is case-sensitive.
const CI = process.platform === 'win32' || process.platform === 'darwin';

// child is the root itself or is INSIDE it.
function eqOrInside(child, root) {
  let c = norm(child);
  let r = norm(root);
  if (CI) {
    c = c.toLowerCase();
    r = r.toLowerCase();
  }
  return c === r || c.startsWith(r + '/');
}

// Parser for ONE shell segment, quote-aware: splits tokens and redirection TARGETS.
// Quote-aware so it does not mistake a '>' inside a string (e.g. git commit -m "a > b")
// for a real redirection. Ignores fd dup (>&N) and drops fd prefixes (2>, &>).
function parseSegment(seg) {
  const tokens = [];
  const redirects = [];
  let cur = '';
  let quote = null; // "'" or '"' when inside quotes
  let expectTarget = false; // the next complete token is a redirection target
  const flush = () => {
    if (cur === '') return;
    if (expectTarget) {
      if (!cur.startsWith('&')) redirects.push(cur); // '&' → fd dup (>&2), not a file
      expectTarget = false;
    } else if (!/^[0-9]+$|^&$/.test(cur)) {
      tokens.push(cur); // drop a stray fd prefix (the "2" in "2>")
    }
    cur = '';
  };
  for (let i = 0; i < seg.length; i++) {
    const ch = seg[i];
    if (quote) {
      if (ch === quote) quote = null;
      else cur += ch;
      continue;
    }
    if (ch === '"' || ch === "'") {
      quote = ch;
      continue;
    }
    if (ch === '>') {
      flush(); // closes any pending fd (2, &) before the '>'
      if (seg[i + 1] === '>') i++; // '>>' (append) counts as a single redirection
      expectTarget = true;
      continue;
    }
    if (ch === ' ' || ch === '\t') {
      flush();
      continue;
    }
    cur += ch;
  }
  flush();
  return { tokens, redirects };
}

// Sinks that are NOT repository files: the null devices of Windows (NUL, NUL:), of
// PowerShell ($null) and of POSIX (/dev/null and the rest of /dev/). Redirecting to them
// DISCARDS output, it does not write product — `node x.js > NUL` used to resolve to a relative
// path inside the root and block wrongly.
const NULL_SINKS = new Set(['nul', 'nul:', '$null', 'con', 'con:', '/dev/null']);
function isNullSink(target) {
  const t = String(target).trim().replace(/\\/g, '/').toLowerCase();
  return NULL_SINKS.has(t) || t.startsWith('/dev/');
}

// Expands environment variable references in the target: $env:NAME (PowerShell), %NAME% (cmd),
// ${NAME} and $NAME (POSIX). Without this, `> $env:TEMP/build.log` was read as a RELATIVE path
// inside the root and blocked — when the file is not even born in the repository.
// A reference that does not resolve → undecidable target → returns null and the hook does not
// block (fail-open, the same honesty as the rest of the matcher: what cannot be parsed
// safely does not become an invariant).
function expandVars(target) {
  let unresolved = false;
  const lookup = (name) => {
    const value = process.env[name]; // on Windows, process.env is already case-insensitive
    if (value === undefined || value === '') {
      unresolved = true;
      return '';
    }
    return value;
  };
  const expanded = String(target)
    .replace(/\$env:([A-Za-z_][A-Za-z0-9_]*)/gi, (_, n) => lookup(n))
    .replace(/%([A-Za-z_][A-Za-z0-9_]*)%/g, (_, n) => lookup(n))
    .replace(/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/g, (_, n) => lookup(n))
    .replace(/\$([A-Za-z_][A-Za-z0-9_]*)/g, (_, n) => lookup(n));
  return unresolved ? null : expanded;
}

// Write targets of a shell command (Bash sibling matcher). Best-effort and honest:
// covers the common cases; what it cannot parse safely does not block.
function extractShellTargets(command) {
  const targets = [];
  for (const seg of command.split(/&&|\|\||;|\||\r?\n/)) {
    const { tokens, redirects } = parseSegment(seg);
    for (const r of redirects) targets.push(r);
    for (let i = 0; i < tokens.length; i++) {
      const t = tokens[i].toLowerCase();
      // tee [-flags] file...  /  Tee-Object -FilePath file
      if (t === 'tee' || t === 'tee-object') {
        for (let j = i + 1; j < tokens.length; j++) {
          const a = tokens[j];
          if (/^-(?:literal)?(?:file)?path$/i.test(a) && j + 1 < tokens.length) {
            targets.push(tokens[j + 1]);
            j++;
            continue;
          }
          if (!a.startsWith('-')) targets.push(a);
        }
      }
      // Set-Content / Add-Content / Out-File: -Path/-LiteralPath or first positional.
      if (t === 'set-content' || t === 'add-content' || t === 'out-file') {
        let took = false;
        for (let j = i + 1; j < tokens.length && !took; j++) {
          const a = tokens[j];
          if (/^-(?:literal)?(?:file)?path$/i.test(a) && j + 1 < tokens.length) {
            targets.push(tokens[j + 1]);
            took = true;
          } else if (!a.startsWith('-')) {
            targets.push(a);
            took = true;
          }
        }
      }
      // sed -i / --in-place <file> (last non-flag operand of the segment).
      if (t === 'sed') {
        const inPlace = tokens
          .slice(i + 1)
          .some((x) => /^-i(?:\..*)?$/.test(x) || x === '--in-place' || /^-[a-z]*i[a-z]*$/i.test(x));
        if (inPlace) {
          for (let j = tokens.length - 1; j > i; j--) {
            if (!tokens[j].startsWith('-')) {
              targets.push(tokens[j]);
              break;
            }
          }
        }
      }
    }
  }
  // Drops flags, null sinks, and targets with an unresolvable variable; expands the rest so
  // that the comparison against the repo root (in main) sees the REAL path, not the shell literal.
  return targets
    .filter((p) => p && !p.startsWith('-') && !isNullSink(p))
    .map(expandVars)
    .filter((p) => p && !isNullSink(p));
}

function block(reason) {
  process.stderr.write(
    `PelizzAI writegate: write blocked — ${reason}\n` +
      `(Opt-in fail-closed isolation/kickoff hook. If the write is legitimate outside the flow, ` +
      `isolate via pelizzai-starting-branch, ratify the gate, or disable the hook in .claude/settings.json.)\n`
  );
  return 2;
}

// Best-effort warning, at most once per window and per repo — never affects the exit code.
function warnOnce(gitRoot, message) {
  try {
    const key = norm(gitRoot).toLowerCase().replace(/[^a-z0-9]/g, '_').slice(-60);
    const statePath = join(tmpdir(), `pelizzai-writegate-${key}.json`);
    const now = Date.now();
    let warnUntil = 0;
    try {
      if (existsSync(statePath)) warnUntil = JSON.parse(readFileSync(statePath, 'utf8')).warnUntil || 0;
    } catch {
      /* corrupt state: warn again */
    }
    if (now < warnUntil) return; // still inside the snooze window
    process.stderr.write(`PelizzAI writegate (warning): ${message}\n`);
    try {
      writeFileSync(statePath, JSON.stringify({ warnUntil: now + WARN_SNOOZE_MS }));
    } catch {
      /* no persistence — carry on */
    }
  } catch {
    /* the warning is optional; never interferes with the flow */
  }
}

function main() {
  let data;
  try {
    data = JSON.parse(readStdin() || '{}');
  } catch {
    return 0; // unreadable payload → not the hook's job to lock things up
  }
  let cwd = process.cwd();
  if (data && typeof data.cwd === 'string' && data.cwd) cwd = data.cwd;
  const ti = (data && data.tool_input) || {};

  // Targets: file_path (Write/Edit/MultiEdit), notebook_path (NotebookEdit), shell (Bash).
  const targets = [];
  if (typeof ti.file_path === 'string' && ti.file_path) targets.push(ti.file_path);
  if (typeof ti.notebook_path === 'string' && ti.notebook_path) targets.push(ti.notebook_path);
  if (typeof ti.command === 'string' && ti.command) targets.push(...extractShellTargets(ti.command));
  if (targets.length === 0) return 0; // nothing to guard (e.g. read-only Bash)

  const gitRoot = git(cwd, ['rev-parse', '--show-toplevel']);
  if (!gitRoot) return 0; // outside a git repo (scratchpad/external) or git missing → allow

  // Only targets INSIDE the root matter; scratchpad/temp outside the root never blocks.
  const inRoot = targets
    .map((t) => (isAbsolute(t) ? t : join(cwd, t)))
    .map((t) => resolve(t))
    .filter((t) => eqOrInside(t, gitRoot));
  if (inRoot.length === 0) return 0;

  // Harness metadata (pelizzai/**) vs. PRODUCT (outside pelizzai/). Both Rule A's carve-out
  // and Rule B rest on this separation.
  const pelizzaiDir = join(gitRoot, 'pelizzai');
  const products = inRoot.filter((t) => !eqOrInside(t, pelizzaiDir));

  // ── Rule A (both modes): protected/detached branch blocks in-root PRODUCT writes.
  // METADATA CARVE-OUT: writing inside pelizzai/** is ALLOWED even on a protected branch or a
  // detached HEAD — it is harness metadata (state/plan/spec/reports), the system updating itself,
  // never product. This unblocks state reconciliation on the very protected branch the dev returns
  // to after the PR merge. SECURITY NOTE: the carve-out is for FILE writes ONLY and opens no
  // product or commit loophole — product (outside pelizzai/) stays blocked by this same Rule A;
  // the metadata is only COMMITTED in the first commit of the new task branch (the flow never
  // requires a commit on a protected branch); and pelizzai-guardrails keeps blocking destructive
  // git. LIMIT (symlink): the metadata-vs-product classification is by PATH — resolve() normalizes
  // `..` (which is why `pelizzai/../src` correctly counts as product) but does NOT follow symlinks.
  // A symlink inside pelizzai/ pointing outside (e.g. `pelizzai/link -> ../src`) could make a real
  // product write be read as metadata and allowed on a protected branch. The carve-out is NOT
  // airtight against symlinks; the compensating controls remain: pelizzai-guardrails blocks
  // destructive git and human review sees the real target.
  const branch = git(cwd, ['branch', '--show-current']); // '' = detached HEAD (or no branch)
  let isProtected = branch === '' || PROTECTED.includes(branch);
  if (!isProtected) {
    // Enrichment via the remote's default; on failure, degrades to the static list
    // (NOT to fail-open — Rule A must stay armed without origin/HEAD).
    const originHead = git(cwd, ['symbolic-ref', '--short', 'refs/remotes/origin/HEAD']);
    if (originHead) {
      const tail = originHead.split('/').pop();
      if (tail && tail === branch) isProtected = true;
    }
  }
  if (isProtected && products.length > 0) {
    return block(
      `protected/detached branch (${branch || 'detached HEAD'}). Isolate via pelizzai-starting-branch ` +
        `before writing product — isolation before the first write is an invariant ` +
        `(metadata writes in pelizzai/ are allowed even here).`
    );
  }

  // Source mode (PelizzAI source repo): the marker lives in the execution record → Rule B skipped.
  const sourceMode = SOURCE_SENTINELS.every((parts) => existsSync(join(gitRoot, ...parts)));
  if (sourceMode) return 0;

  // ── Rule B (consumer only): a PRODUCT write requires a ratified kickoff in state.md.
  if (products.length === 0) return 0; // only setup artifacts in pelizzai/ → allowed

  const statePath = join(gitRoot, 'pelizzai', 'data', 'state.md');
  if (!existsSync(statePath)) {
    // Consumer without state.md: cannot read the kickoff safely → fail-open + warn once.
    warnOnce(
      gitRoot,
      'no pelizzai/data/state.md to check the kickoff; allowing the write. If this project ' +
        'uses the harness, run the kickoff gate and record "kickoff: ratified" before writing product.'
    );
    return 0;
  }
  let state = '';
  try {
    state = readFileSync(statePath, 'utf8');
  } catch {
    return 0; // could not read the marker → fail-open
  }
  if (KICKOFF_RATIFIED.test(state)) return 0;

  return block(
    'the kickoff has not been ratified yet ("kickoff: ratified" is missing from pelizzai/data/state.md). ' +
      'Run the kickoff/post-plan gate WITH the user — isolation, execution mode, and commit ' +
      'strategy —, record "kickoff: ratified" in pelizzai/data/state.md, and then write the code.'
  );
}

let exitCode = 0;
try {
  exitCode = main();
} catch {
  exitCode = 0; // fail-open: an error in the hook ITSELF never locks the user out
}
process.exit(exitCode);
