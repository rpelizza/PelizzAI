#!/usr/bin/env node

/**
 * PelizzAI — skill conformance validator.
 *
 * Two kinds of rule, from scripts/harness-budget.json.
 *
 * `spec` rules mirror the published Agent Skills specification, as encoded in
 * anthropics/skills quick_validate.py. A skill that breaks one can be rejected
 * by the platform, so these are counted against a ratchet frozen at today's
 * value and any new violation fails the build.
 *
 * `budget` rules are the ECC context-budget thresholds (description length,
 * skill length, table of contents on long references). The current corpus
 * already breaks them, so a hard cap would block every commit and a bare
 * warning would be ignored, which is exactly how ECC grew to 51 MB with its own
 * thresholds published and unenforced. The middle path is a violation ratchet:
 * the count may fall, never rise, and each drop belongs in the commit that
 * earned it.
 *
 * Usage:
 *   node scripts/validate-skills.mjs          report and enforce
 *   node scripts/validate-skills.mjs --json   machine-readable
 *   node scripts/validate-skills.mjs --list   name every current violation
 *
 * Exit codes: 0 no ratchet exceeded; 1 a ratchet rose; 2 the budget file is unusable.
 */

import { readFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, resolve, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const root = resolve(scriptDir, '..');
const budgetPath = join(scriptDir, 'harness-budget.json');

const args = new Set(process.argv.slice(2));
const asJson = args.has('--json');
const listAll = args.has('--list');

let budget;
try {
  budget = JSON.parse(readFileSync(budgetPath, 'utf8'));
} catch (error) {
  console.error(`validate-skills: cannot read harness-budget.json: ${error.message}`);
  process.exit(2);
}

const spec = budget.skillLimits?.spec ?? {};
const limits = budget.skillLimits?.budget ?? {};

// A missing or non-numeric limit makes every `x > limit` comparison false and disarms the rule
// without a sound — the same silent-green failure this whole file exists to prevent. The budget
// being unusable is exit 2, like a broken JSON.
for (const [where, obj, keys] of [
  ['skillLimits.spec', spec, ['nameMaxChars', 'descriptionMaxChars']],
  ['skillLimits.budget', limits, ['descriptionMaxWords', 'skillMaxLines', 'referenceTocAfterLines']],
]) {
  for (const key of keys) {
    const value = where === 'skillLimits.spec' ? obj[key] : obj[key]?.max;
    if (!Number.isFinite(value) || value <= 0) {
      console.error(`validate-skills: ${where}.${key} is not a positive number — the limit would silently stop applying.`);
      process.exit(2);
    }
  }
}
const skillsDir = join(root, budget.metadataFrom);
const toPosix = (p) => p.split(sep).join('/');
const rel = (abs) => toPosix(relative(root, abs));

/**
 * Frontmatter split. Deliberately not a YAML parser: the harness only ever uses
 * scalar keys, and a dependency here would have to be vendored into every
 * consumer. A key is a line starting at column zero that ends in a colon; a
 * value continues until the next such line, which is how multi-line
 * descriptions are measured whole.
 */
function readFrontmatter(absFile) {
  const text = readFileSync(absFile, 'utf8').replace(/\r\n/g, '\n');
  if (!text.startsWith('---\n')) return { ok: false, reason: 'no frontmatter', body: text };
  const end = text.indexOf('\n---', 4);
  if (end === -1) return { ok: false, reason: 'unterminated frontmatter', body: text };

  const block = text.slice(4, end + 1);
  const keys = {};
  let current = null;
  for (const line of block.split('\n')) {
    const match = /^([A-Za-z][A-Za-z0-9_-]*):\s?(.*)$/.exec(line);
    if (match) {
      current = match[1];
      keys[current] = match[2];
    } else if (current !== null) {
      keys[current] += (keys[current] ? '\n' : '') + line;
    }
  }
  for (const key of Object.keys(keys)) keys[key] = keys[key].trim();

  return { ok: true, keys, body: text.slice(end + 4) };
}

function listSkills() {
  if (!existsSync(skillsDir)) return [];
  return readdirSync(skillsDir)
    .map((name) => join(skillsDir, name, 'SKILL.md'))
    .filter((file) => existsSync(file) && statSync(file).isFile())
    .sort();
}

function listReferences() {
  const out = [];
  const walk = (dir) => {
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      const abs = join(dir, entry.name);
      if (entry.isDirectory()) walk(abs);
      else if (entry.isFile() && entry.name.endsWith('.md') && entry.name !== 'SKILL.md') out.push(abs);
    }
  };
  if (existsSync(skillsDir)) walk(skillsDir);
  return out.sort();
}

const specViolations = [];
const budgetViolations = { descriptionMaxWords: [], skillMaxLines: [], referenceTocAfterLines: [] };

for (const file of listSkills()) {
  const name = rel(file);
  const fm = readFrontmatter(file);

  if (!fm.ok) {
    specViolations.push({ file: name, rule: 'frontmatter', detail: fm.reason });
    continue;
  }

  const unexpected = Object.keys(fm.keys).filter(
    (key) => !(spec.allowedFrontmatterKeys ?? []).includes(key),
  );
  if (unexpected.length > 0) {
    specViolations.push({ file: name, rule: 'frontmatter-keys', detail: `unexpected: ${unexpected.join(', ')}` });
  }

  const declaredName = fm.keys.name ?? '';
  if (!declaredName) {
    specViolations.push({ file: name, rule: 'name', detail: 'missing' });
  } else {
    if (declaredName.length > spec.nameMaxChars) {
      specViolations.push({ file: name, rule: 'name-length', detail: `${declaredName.length} chars` });
    }
    if (spec.namePattern && !new RegExp(spec.namePattern).test(declaredName)) {
      specViolations.push({ file: name, rule: 'name-kebab-case', detail: declaredName });
    }
  }

  const description = (fm.keys.description ?? '').replace(/^["']|["']$/g, '');
  if (!description) {
    specViolations.push({ file: name, rule: 'description', detail: 'missing' });
    continue;
  }
  if (description.length > spec.descriptionMaxChars) {
    specViolations.push({
      file: name,
      rule: 'description-length',
      detail: `${description.length} chars, spec allows ${spec.descriptionMaxChars}`,
    });
  }
  /**
   * The H1 is the platform's fallback title: when the description fails to parse, this is what
   * appears in the catalogue instead. Thirteen of thirty skills still carried the title they had
   * before the slice-03b rename — so the fallback would have announced a skill name that no longer
   * exists. Renaming a directory is not renaming a skill.
   */
  const heading = fm.body.match(/^#\s+(.+)$/m)?.[1]?.trim() ?? '';
  const expected = declaredName.replace(/^pelizzai-/, '').replace(/-/g, '');
  const seen = heading.toLowerCase().replace(/[^a-z0-9]/g, '');
  if (declaredName && (!heading || !seen.includes(expected))) {
    specViolations.push({
      file: name,
      rule: 'h1-matches-name',
      detail: heading ? `"${heading}" does not name ${declaredName}` : 'no H1',
    });
  }

  /**
   * A colon followed by a space starts a mapping in YAML. An unquoted description
   * containing one either fails to parse or silently truncates, and the platform
   * falls back to the H1 title — so the skill sits in the catalogue with no
   * trigger text at all and simply never fires. The frontmatter reader above is
   * a regex and cannot see this; a real YAML parser can, and does.
   */
  const rawDescription = fm.keys.description ?? '';
  const quoted = /^\s*(["'|>])/.test(rawDescription);
  if (!quoted && /:(\s|$)/.test(rawDescription)) {
    specViolations.push({
      file: name,
      rule: 'description-yaml-scalar',
      detail: `unquoted colon near "${rawDescription.match(/\S*:(?:\s|$)/)?.[0] ?? ''}"`,
    });
  }
  if (spec.descriptionForbidsAngleBrackets && /[<>]/.test(description)) {
    const found = description.match(/[^\s]*[<>][^\s]*/)?.[0] ?? '';
    specViolations.push({ file: name, rule: 'description-angle-brackets', detail: found });
  }

  const words = description.split(/\s+/).filter(Boolean).length;
  if (limits.descriptionMaxWords && words > limits.descriptionMaxWords.max) {
    budgetViolations.descriptionMaxWords.push({ file: name, detail: `${words} words` });
  }

  const lines = readFileSync(file, 'utf8').replace(/\r\n/g, '\n').split('\n').length;
  if (limits.skillMaxLines && lines > limits.skillMaxLines.max) {
    budgetViolations.skillMaxLines.push({ file: name, detail: `${lines} lines` });
  }
}

for (const file of listReferences()) {
  const text = readFileSync(file, 'utf8').replace(/\r\n/g, '\n');
  const lines = text.split('\n').length;
  if (!limits.referenceTocAfterLines || lines <= limits.referenceTocAfterLines.max) continue;
  const hasToc =
    /^#{2,3}\s+(Contents|Table of contents)\b/im.test(text) ||
    /^\s*(?:[-*]|\d+\.)\s+\[[^\]]+\]\(#/m.test(text);
  if (!hasToc) {
    budgetViolations.referenceTocAfterLines.push({ file: rel(file), detail: `${lines} lines, no table of contents` });
  }
}

const checks = [
  {
    id: 'spec',
    label: 'Agent Skills specification',
    count: specViolations.length,
    allowed: spec.allowedViolations ?? 0,
    items: specViolations,
  },
  ...Object.entries(budgetViolations).map(([id, items]) => ({
    id,
    label: `budget: ${id}`,
    count: items.length,
    allowed: limits[id]?.allowed ?? 0,
    items,
  })),
];

// The same silent-green trap as the max limits: a non-numeric `allowed` (say, "invalid") makes
// `count > allowed` false forever and the ratchet stops ratcheting. Validate the EFFECTIVE
// values, after the ?? 0 defaults above — the budget being unusable is exit 2.
for (const check of checks) {
  if (!Number.isInteger(check.allowed) || check.allowed < 0) {
    console.error(
      `validate-skills: the "allowed" value for ${check.id} is not a non-negative integer — the ratchet would silently stop applying.`
    );
    process.exit(2);
  }
}

const risen = checks.filter((check) => check.count > check.allowed);
const fell = checks.filter((check) => check.count < check.allowed);
const ok = risen.length === 0;

if (asJson) {
  console.log(JSON.stringify({ checks, ok }, null, 2));
  process.exit(ok ? 0 : 1);
}

console.log('PelizzAI skill conformance\n');
const pad = (s, n) => String(s).padEnd(n);
const lpad = (s, n) => String(s).padStart(n);
console.log(`  ${pad('check', 26)} ${lpad('found', 7)} ${lpad('allowed', 8)}  status`);
console.log(`  ${'-'.repeat(26)} ${'-'.repeat(7)} ${'-'.repeat(8)}  ------`);
for (const check of checks) {
  const status =
    check.count > check.allowed
      ? `ROSE by ${check.count - check.allowed}`
      : check.count < check.allowed
        ? `fell by ${check.allowed - check.count} — lower "allowed"`
        : 'held';
  console.log(`  ${pad(check.id, 26)} ${lpad(check.count, 7)} ${lpad(check.allowed, 8)}  ${status}`);
}

if (listAll || !ok) {
  for (const check of checks) {
    const show = listAll ? check.items : check.count > check.allowed ? check.items : [];
    if (show.length === 0) continue;
    console.log(`\n  ${check.label}:`);
    for (const item of show) {
      console.log(`    ${item.file}${item.rule ? ` [${item.rule}]` : ''} — ${item.detail}`);
    }
  }
}

if (fell.length > 0) {
  console.log(
    '\nSome counts are below their ratchet. Lower the "allowed" value in harness-budget.json\n' +
      'in this same commit, so the gain is locked in and cannot be spent later.',
  );
}

if (!ok) {
  console.error(
    '\nA violation count rose. Fix the new violation, or state in the commit why the ratchet moves.',
  );
}

process.exit(ok ? 0 : 1);
