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
import { load, CORE_SCHEMA } from './vendor/js-yaml-4.1.1.mjs';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const root = resolve(scriptDir, '..');
const budgetPath = join(scriptDir, 'harness-budget.json');

const args = new Set(process.argv.slice(2));
const asJson = args.has('--json');
const directoryFlag = process.argv.indexOf('--skills-root');
const requestedDirectory = directoryFlag < 0 ? null : process.argv[directoryFlag + 1];
if (directoryFlag >= 0 && (!requestedDirectory || requestedDirectory.startsWith('--'))) {
  console.error('validate-skills: --skills-root requires a directory.');
  process.exit(2);
}

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
const skillsDir = requestedDirectory ? resolve(requestedDirectory) : resolve(root, budget.metadataFrom);
if (!requestedDirectory && (skillsDir === root || !(skillsDir + sep).startsWith(root + sep))) {
  console.error(`validate-skills: metadataFrom "${budget.metadataFrom}" must name a directory under the repo root, not the root itself or a path outside it.`);
  process.exit(2);
}
if (!existsSync(skillsDir) || !statSync(skillsDir).isDirectory()) {
  console.error(`validate-skills: ${requestedDirectory ? '--skills-root' : 'metadataFrom'} "${requestedDirectory ?? budget.metadataFrom}" is not an existing directory — nothing would be validated.`);
  process.exit(2);
}
const toPosix = (p) => p.split(sep).join('/');
const rel = (abs) => toPosix(relative(root, abs));

// Parse YAML with a pinned, vendored parser. Duplicate keys, invalid quoting and
// non-scalar values must not silently become platform trigger descriptions.
function readFrontmatter(absFile) {
  const text = readFileSync(absFile, 'utf8').replace(/\r\n/g, '\n');
  const match = /^---\n([\s\S]*?)\n---[ \t]*(?:\n|$)/.exec(text);
  if (!match) return { ok: false, reason: 'missing or unterminated frontmatter', body: text };
  try {
    const keys = load(match[1], { schema: CORE_SCHEMA });
    if (!keys || typeof keys !== 'object' || Array.isArray(keys)) {
      return { ok: false, reason: 'frontmatter must be a mapping', body: text };
    }
    return { ok: true, keys, body: text.slice(match[0].length) };
  } catch (error) {
    return { ok: false, reason: error.message, body: text };
  }
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
  if (typeof declaredName !== 'string' || !declaredName.trim()) {
    violations.push({ file: name, rule: 'name', detail: 'must be a non-empty string' });
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

  const description = fm.keys.description;
  if (typeof description !== 'string' || !description.trim()) {
    violations.push({ file: name, rule: 'description', detail: 'must be a non-empty string' });
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
  const expected = String(declaredName).replace(/^pelizzai-/, '').replace(/-/g, '');
  const seen = heading.toLowerCase().replace(/[^a-z0-9]/g, '');
  if (typeof declaredName === 'string' && declaredName.startsWith('pelizzai-') && (!heading || !seen.includes(expected))) {
    violations.push({
      file: name,
      rule: 'h1-matches-name',
      detail: heading ? `"${heading}" does not name ${declaredName}` : 'no H1',
    });
  }

  if (spec.descriptionForbidsAngleBrackets && /[<>]/.test(description)) {
    const found = description.match(/[^\s]*[<>][^\s]*/)?.[0] ?? '';
    violations.push({ file: name, rule: 'description-angle-brackets', detail: found });
  }
}

const skillCount = listSkills().length;
if (skillCount === 0) {
  violations.push({ file: rel(skillsDir), rule: 'skills-root', detail: 'no SKILL.md files found; nothing validated' });
}
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
