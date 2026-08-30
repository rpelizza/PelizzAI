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
 *   isolate via pelizzai-isolate.
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
 * a bug or false positive here never locks the user out). A missing state.md is NOT such a case
 * when the repo carries the harness (pelizzai/ or the pelizzai-core skill): there the gate never
 * ran and the write BLOCKS — ratifying the gate writes the marker and creates the file, so no
 * legitimate flow is locked out. Only a repo with no harness footprint at all fails open, with
 * at most one warning per window (no spam).
 *
 * Install (opt-in, recommended by pelizzai-onboard at bootstrap, merged without overwriting
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

import { readFileSync, writeFileSync, existsSync, realpathSync, statSync, lstatSync, readlinkSync } from 'node:fs';
import { join, parse, isAbsolute, dirname, basename } from 'node:path';
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

// Backslash is a path separator ONLY on Windows. On POSIX it is a legal filename character —
// treating `pelizzai\x` as `pelizzai/x` there collapsed a PRODUCT file into the metadata
// carve-out (the OS writes one root-level file literally named "pelizzai\x").
const WIN = process.platform === 'win32';

// Forward slashes and no trailing slash, for prefix comparison robust to \ and / (Windows only).
function norm(p) {
  let s = String(p);
  if (WIN) s = s.replace(/\\/g, '/');
  return s.replace(/\/+$/, '');
}

// Windows and macOS compare paths case-insensitively; Linux is case-sensitive.
const CI = process.platform === 'win32' || process.platform === 'darwin';

// macOS pitfall the CI caught: the temp tree lives behind a symlink (/var -> /private/var), so
// `git rev-parse --show-toplevel` reports the PHYSICAL root while the payload's cwd — and every
// relative target joined to it — stays LOGICAL. All in-root writes then looked outside the root
// and the hook failed OPEN on exactly the platform the suite first ran on. Canonicalize to the
// physical path; a target that does not exist yet resolves through its parent; anything that
// cannot be resolved keeps its raw spelling (fail-open, as everywhere else in this file).
function realpathOr(p, depth = 0) {
  if (!p) return p; // '' must stay '' — resolving it would invent a root out of the cwd
  try {
    return realpathSync(p);
  } catch {
    /* target missing — but the component itself may still be a DANGLING link */
  }
  // A dangling link fails both realpath and exists, yet a write THROUGH it lands on the target —
  // pelizzai/dangling -> ../new-file would otherwise classify as metadata while the OS creates
  // product. lstat sees the link itself; its target resolves against the physical parent.
  try {
    if (depth < 8 && lstatSync(p).isSymbolicLink()) {
      const target = readlinkSync(p);
      const base = realpathOr(dirname(p), depth + 1);
      return isAbsolute(target) ? physicalResolve('', target, depth + 1) : physicalResolve(base, target, depth + 1);
    }
  } catch {
    /* not a link either — fall through to the parent resolution */
  }
  try {
    return join(realpathSync(dirname(p)), basename(p));
  } catch {
    return p;
  }
}

// `..` must be applied AFTER the link resolution, never before: a lexical normalize collapses
// `pelizzai/link/../src` to `pelizzai/src` (metadata, allowed) while the OS resolves `link`
// first and lands the write on real product OUTSIDE pelizzai/ — a clean bypass of Rules A and
// B through the carve-out. So each component is resolved against the PHYSICAL path built so
// far, and `..` climbs the resolved parent. `baseDir` must already be physical.
function physicalResolve(baseDir, target, depth = 0) {
  const abs = isAbsolute(target);
  const root = abs ? parse(target).root : '';
  let cur = abs ? realpathOr(root, depth) : baseDir;
  const rest = abs ? target.slice(root.length) : target;
  for (const seg of rest.split(WIN ? /[\\/]+/ : /\/+/)) {
    if (!seg || seg === '.') continue;
    if (seg === '..') {
      cur = dirname(cur);
      continue;
    }
    cur = realpathOr(join(cur, seg), depth); // resolves a link component; a not-yet-existing one appends
  }
  return cur;
}

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
    // Same escape model as splitSegments; here the escape RESOLVES into the token content
    // (\" is a literal quote in the word, \\ a backslash). Single quotes stay POSIX-literal.
    if (quote === '"' && ch === '\\' && (seg[i + 1] === '"' || seg[i + 1] === '\\')) {
      cur += seg[i + 1];
      i++;
      continue;
    }
    if (quote) {
      if (ch === quote) quote = null;
      else cur += ch;
      continue;
    }
    // Outside quotes, backslash also escapes whitespace and the shell operators: `> pelizzai\ x`
    // names the PRODUCT file "pelizzai x" (cutting the token at the space made the target
    // collapse into the pelizzai/ carve-out and slip past Rule A), and `echo \> file` passes
    // a literal ">" — inventing a redirect there blocked commands that write nothing.
    if (ch === '\\' && ESCAPABLE.has(seg[i + 1])) {
      cur += seg[i + 1];
      i++;
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

// Characters a backslash escapes OUTSIDE quotes (shared by splitSegments and parseSegment):
// quotes and the backslash itself, whitespace (`\ ` names a file with a space), and the shell
// operators (`\>` is a literal ">", never a redirect; `\|`, `\;`, `\&` never separate). A
// backslash before any OTHER character is an ordinary character — Windows paths (C:\temp\x)
// must survive untouched.
const ESCAPABLE = new Set(['"', "'", '\\', ' ', '\t', '>', '|', ';', '&']);

// Splits a command into segments at &&, ||, ;, | and newlines — ONLY when the separator
// sits OUTSIDE quotes (same quote model as parseSegment: plain '/" toggling). The raw
// regex split was quote-blind: `sed -i 's|a|b|' pelizzai/...` broke mid-expression, the
// wrong "last operand" became the target and the hook blocked the very pelizzai/ carve-out
// its message promises (issue #74) — while `grep 'a|b' x > product` hid a REAL product
// redirect inside the mangled quote and failed open. Quote chars stay in the output;
// parseSegment strips them.
function splitSegments(command) {
  const segments = [];
  let cur = '';
  let quote = null;
  for (let i = 0; i < command.length; i++) {
    const ch = command[i];
    // Escapes (issue #74 follow-up): inside double quotes \" does not close the string; outside
    // quotes \x escapes the ESCAPABLE set and \<newline> is a line continuation. Single quotes
    // are POSIX-literal (no escapes).
    if (quote === '"' && ch === '\\' && (command[i + 1] === '"' || command[i + 1] === '\\')) {
      cur += ch + command[i + 1];
      i++;
      continue;
    }
    if (quote) {
      if (ch === quote) quote = null;
      cur += ch;
      continue;
    }
    if (ch === '\\') {
      const next = command[i + 1];
      if (next === '\r' && command[i + 2] === '\n') {
        i += 2; // line continuation: join the physical lines
        continue;
      }
      if (next === '\n') {
        i++;
        continue;
      }
      if (ESCAPABLE.has(next)) {
        cur += ch + next; // kept raw: parseSegment resolves the pair
        i++;
        continue;
      }
    }
    if (ch === '"' || ch === "'") {
      quote = ch;
      cur += ch;
      continue;
    }
    if (ch === '&' && command[i + 1] === '&') {
      segments.push(cur);
      cur = '';
      i++;
      continue;
    }
    if (ch === '|') {
      if (command[i + 1] === '|') i++;
      segments.push(cur);
      cur = '';
      continue;
    }
    if (ch === ';' || ch === '\n') {
      segments.push(cur);
      cur = '';
      continue;
    }
    if (ch === '\r' && command[i + 1] === '\n') {
      segments.push(cur);
      cur = '';
      i++;
      continue;
    }
    cur += ch;
  }
  segments.push(cur);
  return segments;
}

// Command substitutions — $(...) with nesting, and `...` — are REAL executions: bash runs them
// even inside double quotes, so `echo "$(printf x > product)"` writes product. Extracts every
// inner script for a recursive parse and replaces the span with a neutral token in the outer
// text, so the outer parse is not mangled by the substitution's own operators. Single quotes
// keep substitutions literal. Best-effort like the rest of the matcher (a quoted paren inside
// $() can shorten the span; what it cannot parse safely does not block).
function extractSubstitutions(command) {
  const inners = [];
  let outer = '';
  let quote = null;
  for (let i = 0; i < command.length; i++) {
    const ch = command[i];
    if (quote === "'") {
      if (ch === "'") quote = null;
      outer += ch;
      continue;
    }
    if (ch === '\\') {
      outer += ch + (command[i + 1] ?? '');
      i++;
      continue;
    }
    if (ch === "'") {
      quote = "'";
      outer += ch;
      continue;
    }
    if (ch === '"') {
      quote = quote === '"' ? null : '"';
      outer += ch;
      continue;
    }
    if (ch === '$' && command[i + 1] === '(') {
      let depth = 1;
      let j = i + 2;
      for (; j < command.length && depth > 0; j++) {
        if (command[j] === '(') depth++;
        else if (command[j] === ')') depth--;
      }
      inners.push(command.slice(i + 2, j - 1));
      outer += 'SUBST';
      i = j - 1;
      continue;
    }
    if (ch === '`') {
      let j = i + 1;
      while (j < command.length && command[j] !== '`') j++;
      inners.push(command.slice(i + 1, j));
      outer += 'SUBST';
      i = j;
      continue;
    }
    outer += ch;
  }
  return { outer, inners };
}

// Write targets of a shell command (Bash sibling matcher). Best-effort and honest:
// covers the common cases; what it cannot parse safely does not block.
function extractShellTargets(command, depth = 0) {
  const targets = [];
  if (depth < 5) {
    const { outer, inners } = extractSubstitutions(command);
    for (const inner of inners) targets.push(...extractShellTargets(inner, depth + 1));
    command = outer;
  }
  for (const seg of splitSegments(command)) {
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
    `PelizzAI writegate: write redirected - ${reason}\n` +
      `(Opt-in fail-closed isolation/kickoff hook. If the write is legitimate outside the flow, ` +
      `isolate via pelizzai-isolate, ratify the gate, or disable the hook in .claude/settings.json.)\n`
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

  const gitRoot = realpathOr(git(cwd, ['rev-parse', '--show-toplevel']));
  if (!gitRoot) return 0; // outside a git repo (scratchpad/external) or git missing → allow
  cwd = realpathOr(cwd); // physical cwd, so relative targets land on the same spelling as gitRoot

  // Only targets INSIDE the root matter; scratchpad/temp outside the root never blocks.
  const inRoot = targets
    .map((t) => physicalResolve(cwd, t))
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
  // git. LIMIT (symlink): the classification is by PHYSICAL path — physicalResolve follows
  // directory links component-by-component and applies `..` on the RESOLVED parent, so both
  // `pelizzai/../src` and `pelizzai/link/../src` (link -> product) correctly count as product.
  // Residual limit: a link created BETWEEN this check and the actual write (TOCTOU) is not
  // seen; the compensating controls remain — pelizzai-guardrails blocks destructive git and
  // human review sees the real target.
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
      `protected/detached branch (${branch || 'detached HEAD'}). Isolate via pelizzai-isolate ` +
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
    // HARNESS EVIDENCE (2026-08-26 hardening): a missing state.md used to fail-open for every
    // consumer, which made Rule B unenforceable in the exact window it exists for — a consumer
    // that carries the harness but whose kickoff gate never ran (the trigger tests caught an
    // agent editing product right through this gap). The head skills write the marker BEFORE
    // the first product write and writing pelizzai/data/state.md is always allowed, so blocking
    // here locks out no legitimate flow: ratifying the gate creates the file. The fail-open +
    // warn survives ONLY where it is honest — a repo with no trace of the harness at all
    // (e.g. the hook registered off-label in global settings).
    // DIRECTORIES only: a repo that happens to carry a regular FILE named `pelizzai` is not a
    // harness footprint, and reading it as one would hard-block an unrelated project.
    const isDir = (p) => {
      try {
        return statSync(p).isDirectory();
      } catch {
        return false;
      }
    };
    const harnessPresent =
      isDir(join(gitRoot, 'pelizzai')) ||
      isDir(join(gitRoot, '.claude', 'skills', 'pelizzai-core')) ||
      isDir(join(gitRoot, '.agents', 'skills', 'pelizzai-core'));
    if (harnessPresent) {
      return block(
        'this consumer carries the harness but pelizzai/data/state.md does not exist — the kickoff ' +
          'gate never ran. Run the kickoff/post-plan gate WITH the user — isolation, execution mode, ' +
          'and commit strategy —, record "kickoff: ratified" in pelizzai/data/state.md (writes under ' +
          'pelizzai/ are always allowed and create the file), and then write the product.'
      );
    }
    // No trace of the harness in this repo: cannot decide safely → fail-open + warn once.
    warnOnce(
      gitRoot,
      'no pelizzai/data/state.md and no harness footprint to check the kickoff; allowing the write. ' +
        'If this project uses the harness, run the kickoff gate and record "kickoff: ratified" ' +
        'before writing product.'
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
