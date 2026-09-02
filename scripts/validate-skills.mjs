#!/usr/bin/env node

/**
 * PelizzAI — skill conformance validator.
 *
 * One kind of rule, from `skillLimits.spec` in scripts/harness-budget.json: the
 * published Agent Skills specification, as encoded in anthropics/skills
 * quick_validate.py, plus the two failure modes the platform does not report
 * but that silently disarm a skill (an unquoted colon in the description, an
 * H1 that names a skill that no longer exists). A skill that breaks one can be
 * rejected by the platform or sit in the catalogue without a trigger, so every
 * violation is an error. There are no size rules here: size is reported by
 * measure-hotpath.mjs and never enforced.
 *
 * Usage:
 *   node scripts/validate-skills.mjs          report and enforce
 *   node scripts/validate-skills.mjs --json   machine-readable
 *
 * Exit codes: 0 no violation; 1 any violation; 2 the budget file is unusable.
 */

import { readFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, resolve, relative, sep, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const root = resolve(scriptDir, '..');
const budgetPath = join(scriptDir, 'harness-budget.json');

const args = new Set(process.argv.slice(2));
const asJson = args.has('--json');

let budget;
try {
  budget = JSON.parse(readFileSync(budgetPath, 'utf8'));
} catch (error) {
  console.error(`validate-skills: cannot read harness-budget.json: ${error.message}`);
  process.exit(2);
}

const spec = budget.skillLimits?.spec ?? {};

// A missing or non-numeric limit makes every `x > limit` comparison false and disarms the rule
// without a sound — the same silent-green failure this whole file exists to prevent. The budget
// being unusable is exit 2, like a broken JSON.
for (const key of ['nameMaxChars', 'descriptionMaxChars']) {
  const value = spec[key];
  if (!Number.isFinite(value) || value <= 0) {
    console.error(`validate-skills: skillLimits.spec.${key} is not a positive number — the limit would silently stop applying.`);
    process.exit(2);
  }
}
if (
  !Array.isArray(spec.allowedFrontmatterKeys) ||
  spec.allowedFrontmatterKeys.length === 0 ||
  spec.allowedFrontmatterKeys.some((key) => typeof key !== 'string' || key.trim() === '')
) {
  console.error('validate-skills: skillLimits.spec.allowedFrontmatterKeys must be a non-empty list of non-empty strings — otherwise keys would be rejected or matched by accident.');
  process.exit(2);
}
// The kebab-case rule is only as real as its pattern: a missing, empty, or invalid namePattern
// would either skip the check or throw mid-scan. Compile it once, here, and reuse it below.
if (typeof spec.namePattern !== 'string' || spec.namePattern.trim() === '') {
  console.error('validate-skills: skillLimits.spec.namePattern must be a non-empty regular expression string.');
  process.exit(2);
}
let namePattern;
try {
  namePattern = new RegExp(spec.namePattern);
} catch (error) {
  console.error(`validate-skills: skillLimits.spec.namePattern is not a valid regular expression: ${error.message}`);
  process.exit(2);
}
// `metadataFrom` names the skills directory. An empty or missing value would resolve to the repo
// root and scan whatever happens to sit there; a path outside the repo would validate someone
// else's skills. Both are an unusable budget, exit 2.
if (typeof budget.metadataFrom !== 'string' || budget.metadataFrom.trim() === '') {
  console.error('validate-skills: metadataFrom must be a non-empty string naming the skills directory (relative to the repo root).');
  process.exit(2);
}
const skillsDir = resolve(root, budget.metadataFrom);
if (skillsDir === root || !(skillsDir + sep).startsWith(root + sep)) {
  console.error(`validate-skills: metadataFrom "${budget.metadataFrom}" must name a directory under the repo root, not the root itself or a path outside it.`);
  process.exit(2);
}
if (!existsSync(skillsDir) || !statSync(skillsDir).isDirectory()) {
  console.error(`validate-skills: metadataFrom "${budget.metadataFrom}" is not an existing directory — nothing would be validated.`);
  process.exit(2);
}
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
  return readdirSync(skillsDir)
    .map((name) => join(skillsDir, name, 'SKILL.md'))
    .filter((file) => existsSync(file) && statSync(file).isFile())
    .sort();
}

const violations = [];

for (const file of listSkills()) {
  const name = rel(file);
  const fm = readFrontmatter(file);

  if (!fm.ok) {
    violations.push({ file: name, rule: 'frontmatter', detail: fm.reason });
    continue;
  }

  const unexpected = Object.keys(fm.keys).filter((key) => !spec.allowedFrontmatterKeys.includes(key));
  if (unexpected.length > 0) {
    violations.push({ file: name, rule: 'frontmatter-keys', detail: `unexpected: ${unexpected.join(', ')}` });
  }

  const declaredName = fm.keys.name ?? '';
  if (!declaredName) {
    violations.push({ file: name, rule: 'name', detail: 'missing' });
  } else {
    if (declaredName.length > spec.nameMaxChars) {
      violations.push({ file: name, rule: 'name-length', detail: `${declaredName.length} chars` });
    }
    if (!namePattern.test(declaredName)) {
      violations.push({ file: name, rule: 'name-kebab-case', detail: declaredName });
    }
    /**
     * The specification binds `name` to the parent directory. A skill whose name drifts from its
     * directory is registered under one identifier and referenced under the other, and every
     * `pelizzai-*` citation of it becomes a dangling reference the moment the platform resolves it.
     */
    const directory = basename(dirname(file));
    if (declaredName !== directory) {
      violations.push({ file: name, rule: 'name-matches-directory', detail: `name "${declaredName}" in directory "${directory}"` });
    }
  }

  const description = (fm.keys.description ?? '').replace(/^["']|["']$/g, '');
  if (!description) {
    violations.push({ file: name, rule: 'description', detail: 'missing' });
    continue;
  }
  if (description.length > spec.descriptionMaxChars) {
    violations.push({
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
    violations.push({
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
    violations.push({
      file: name,
      rule: 'description-yaml-scalar',
      detail: `unquoted colon near "${rawDescription.match(/\S*:(?:\s|$)/)?.[0] ?? ''}"`,
    });
  }
  if (spec.descriptionForbidsAngleBrackets && /[<>]/.test(description)) {
    const found = description.match(/[^\s]*[<>][^\s]*/)?.[0] ?? '';
    violations.push({ file: name, rule: 'description-angle-brackets', detail: found });
  }
}

const skillCount = listSkills().length;
const ok = violations.length === 0;

if (asJson) {
  console.log(JSON.stringify({ skills: skillCount, violations, ok }, null, 2));
  process.exit(ok ? 0 : 1);
}

console.log('PelizzAI skill conformance (Agent Skills specification)\n');
console.log(`  skills checked: ${skillCount}   violations: ${violations.length}`);
if (!ok) {
  console.log('');
  for (const item of violations) {
    console.log(`    ${item.file} [${item.rule}] — ${item.detail}`);
  }
  console.error('\nA skill violates the platform specification and may be rejected or lose its trigger. Fix it; there is no allowance.');
}

process.exit(ok ? 0 : 1);
