#!/usr/bin/env node

/**
 * PelizzAI — hot-path meter.
 *
 * Reports what each route costs to enter, before the first line of work.
 *
 * The number that matters is not the size of the corpus on disk: no turn ever
 * loads the corpus. It is the size of what the doctrine mandates reading, which
 * is the entrypoint file, the always-loaded skills, the frontmatter of every
 * skill (permanently resident as `available_skills`), and any reference a head
 * skill requires unconditionally.
 *
 * Ceilings in scripts/harness-budget.json are a ratchet: they were frozen at the
 * values measured when the budget was introduced, so any growth fails the build.
 * Lowering one is deliberate and belongs in the commit that earned it.
 *
 * Usage:
 *   node scripts/measure-hotpath.mjs            human-readable report
 *   node scripts/measure-hotpath.mjs --json     machine-readable, for BENCHMARK.md
 *   node scripts/measure-hotpath.mjs --markdown table for pasting into a report
 *
 * Exit codes: 0 every route within its ceiling; 1 any ceiling exceeded or any
 * declared file missing; 2 the budget file itself is unusable.
 */

import { readFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, resolve, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const root = resolve(scriptDir, '..');
const budgetPath = join(scriptDir, 'harness-budget.json');

const args = new Set(process.argv.slice(2));
const asJson = args.has('--json');
const asMarkdown = args.has('--markdown');

/** Bytes as the model sees them: LF-normalised, so CRLF checkouts do not inflate the count. */
function measure(relPath) {
  const abs = join(root, relPath);
  if (!existsSync(abs)) return null;
  return Buffer.byteLength(readFileSync(abs, 'utf8').replace(/\r\n/g, '\n'), 'utf8');
}

/** The YAML frontmatter block only — what stays in context whether or not the skill fires. */
function frontmatterBytes(absFile) {
  const text = readFileSync(absFile, 'utf8').replace(/\r\n/g, '\n');
  if (!text.startsWith('---\n')) return 0;
  const end = text.indexOf('\n---', 4);
  if (end === -1) return 0;
  return Buffer.byteLength(text.slice(4, end + 1), 'utf8');
}

function listSkillFiles(relDir) {
  const abs = join(root, relDir);
  if (!existsSync(abs)) return [];
  return readdirSync(abs)
    .map((name) => join(abs, name, 'SKILL.md'))
    .filter((file) => existsSync(file) && statSync(file).isFile())
    .sort();
}

function toPosix(p) {
  return p.split(sep).join('/');
}

let budget;
try {
  budget = JSON.parse(readFileSync(budgetPath, 'utf8'));
} catch (error) {
  console.error(`measure-hotpath: cannot read ${toPosix(relative(root, budgetPath))}: ${error.message}`);
  process.exit(2);
}

const missing = [];
const skillFiles = listSkillFiles(budget.metadataFrom);
const metadataBytes = skillFiles.reduce((sum, file) => sum + frontmatterBytes(file), 0);
const skillCount = skillFiles.length;

function fragmentFiles(name) {
  const files = budget.fragments?.[name];
  if (!files) {
    missing.push(`fragment "${name}" is referenced by a route but not defined`);
    return [];
  }
  return files;
}

const rows = budget.routes.map((route) => {
  const parts = [];
  let total = 0;

  for (const fragment of route.fragments ?? []) {
    for (const file of fragmentFiles(fragment)) {
      const bytes = measure(file);
      if (bytes === null) {
        missing.push(`route "${route.id}" declares ${file}, which does not exist`);
        continue;
      }
      parts.push({ file, bytes });
      total += bytes;
    }
  }

  if (route.metadata) {
    parts.push({ file: `frontmatter of ${skillCount} skills`, bytes: metadataBytes });
    total += metadataBytes;
  }

  for (const file of route.head ?? []) {
    const bytes = measure(file);
    if (bytes === null) {
      missing.push(`route "${route.id}" declares head ${file}, which does not exist`);
      continue;
    }
    parts.push({ file, bytes });
    total += bytes;
  }

  return {
    id: route.id,
    label: route.label,
    bytes: total,
    tokens: Math.round(total / 4),
    ceilingBytes: route.ceilingBytes,
    targetBytes: route.targetBytes,
    overBy: total - route.ceilingBytes,
    gapToTarget: total - route.targetBytes,
    parts,
  };
});

/** Drift: a head skill that links a reference nobody budgeted. */
const declared = new Set([
  ...Object.values(budget.fragments ?? {}).flat(),
  ...budget.routes.flatMap((route) => route.head ?? []),
  // An onDemand entry is either a bare path or `{ path, reason }`. Spreading the raw array put
  // objects in this Set, where they never matched a path string: the entry looked declared, the
  // drift check stayed silent about it, and the reason — the only place that records WHY a
  // reference is conditional — was the shape that broke it.
  ...(budget.onDemand ?? []).map((entry) => (typeof entry === 'string' ? entry : entry?.path)),
]);
const drift = [];
const linkPattern = /\]\(([^)]*(?:references|techniques)\/[^)]+\.md)\)/g;

for (const route of budget.routes) {
  for (const head of route.head ?? []) {
    const abs = join(root, head);
    if (!existsSync(abs)) continue;
    const text = readFileSync(abs, 'utf8');
    for (const match of text.matchAll(linkPattern)) {
      const target = toPosix(
        relative(root, resolve(dirname(abs), match[1].replace(/^\.\//, ''))),
      );
      if (!declared.has(target) && !drift.some((d) => d.target === target)) {
        drift.push({ from: head, target });
      }
    }
  }
}

const failures = rows.filter((row) => row.overBy > 0);
// Drift is a failure, not a note: a mandatory read nobody budgeted is exactly how the hot path
// grows invisibly — the leak this instrument exists to close.
const ok = failures.length === 0 && missing.length === 0 && drift.length === 0;

if (asJson) {
  console.log(
    JSON.stringify(
      { skillCount, metadataBytes, routes: rows, drift, missing, ok },
      null,
      2,
    ),
  );
  process.exit(ok ? 0 : 1);
}

const fmt = (n) => n.toLocaleString('en-US');

if (asMarkdown) {
  console.log('| route | bytes | tokens | ceiling | target | gap to target |');
  console.log('|---|---:|---:|---:|---:|---:|');
  for (const row of rows) {
    console.log(
      `| \`${row.id}\` | ${fmt(row.bytes)} | ~${fmt(row.tokens)} | ${fmt(row.ceilingBytes)} | ${fmt(row.targetBytes)} | ${row.gapToTarget > 0 ? '+' : ''}${fmt(row.gapToTarget)} |`,
    );
  }
} else {
  console.log('PelizzAI hot path — cost of entering each route\n');
  console.log(`  skills: ${skillCount}   frontmatter always resident: ${fmt(metadataBytes)} B\n`);
  const pad = (s, n) => String(s).padEnd(n);
  const lpad = (s, n) => String(s).padStart(n);
  console.log(
    `  ${pad('route', 12)} ${lpad('bytes', 9)} ${lpad('tokens', 8)} ${lpad('ceiling', 9)} ${lpad('target', 9)}  status`,
  );
  console.log(`  ${'-'.repeat(12)} ${'-'.repeat(9)} ${'-'.repeat(8)} ${'-'.repeat(9)} ${'-'.repeat(9)}  ------`);
  for (const row of rows) {
    const status =
      row.overBy > 0
        ? `OVER by ${fmt(row.overBy)}`
        : row.gapToTarget > 0
          ? `${fmt(row.gapToTarget)} above target`
          : 'at target';
    console.log(
      `  ${pad(row.id, 12)} ${lpad(fmt(row.bytes), 9)} ${lpad('~' + fmt(row.tokens), 8)} ${lpad(fmt(row.ceilingBytes), 9)} ${lpad(fmt(row.targetBytes), 9)}  ${status}`,
    );
  }
}

if (drift.length > 0) {
  console.error('\nDRIFT: head skills link references that no route budgets and onDemand does not list:');
  for (const item of drift) console.error(`  ${item.from} -> ${item.target}`);
  console.error('Declare each one in the route that requires it, or add it to onDemand.');
}

if (missing.length > 0) {
  console.error('\nBUDGET ERRORS:');
  for (const item of missing) console.error(`  ${item}`);
}

if (failures.length > 0) {
  console.error('\nCEILING EXCEEDED:');
  for (const row of failures) {
    console.error(`  ${row.id}: ${fmt(row.bytes)} B against a ceiling of ${fmt(row.ceilingBytes)} B`);
  }
  console.error(
    '\nGrowth in the hot path is zero-sum. Name what comes out, or move the material behind a\n' +
      'pointer with its token cost declared. Lowering a ceiling belongs in the commit that earned it.',
  );
}

process.exit(ok ? 0 : 1);
