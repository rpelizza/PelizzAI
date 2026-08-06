#!/usr/bin/env node

import { createHash } from 'node:crypto';
import {
  cpSync,
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  renameSync,
  rmSync,
  statSync,
  writeFileSync,
} from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const root = resolve(scriptDir, '..');
const srcSkills = join(root, '.claude', 'skills');
const dstSkills = join(root, '.agents', 'skills');
const claudeMd = join(root, 'CLAUDE.md');
const agentsMd = join(root, 'AGENTS.md');
const geminiMd = join(root, 'GEMINI.md');
const coreManifest = join(root, 'scripts', 'pelizzai-core-skills.txt');
const sourceSentinel = join(root, 'scripts', 'pelizzai-source-repo.txt');
const distDir = join(root, 'dist');
// The consumer contract SEED: generated from CLAUDE.md in the source repo and shipped inside
// the core skills (so it travels in .agents/, dist/, and every export automatically). Every
// consumer sync reads it to create/append/resync the three entry files — which is why dist/
// does not ship CLAUDE.md/AGENTS.md/GEMINI.md at all: the first sync (or bootstrap) anchors
// them in place, preserving whatever the project already has.
const contractAsset = join(srcSkills, 'pelizzai-audit', 'assets', 'contract.md');

const REF_IGNORE = new Set([
  'pelizzai-cadence',
  'pelizzai-core-skills',
  'pelizzai-guardrails',
  'pelizzai-session-start',
  'pelizzai-writegate',
  'pelizzai-source-repo',
]);

// ── Contract anchor ─────────────────────────────────────────────────────────
// In a CONSUMER, the harness owns a marker-delimited BLOCK inside CLAUDE.md, AGENTS.md, and
// GEMINI.md — never the whole file. The project keeps its own content around the block; the
// export and the consumer sync create, append, skip, or resync ONLY the block. Byte equality
// of the block against what the source generates is what lets any session detect drift with a
// plain diff. The SOURCE repo keeps whole-file generation: there the files are the authority.
const CONTRACT_OPEN = '<!-- pelizzai:contract -->';
const CONTRACT_CLOSE = '<!-- /pelizzai:contract -->';

// The marked block of `text`, or null when the markers are absent/malformed.
function extractContract(text) {
  const start = text.indexOf(CONTRACT_OPEN);
  if (start < 0) return null;
  const end = text.indexOf(CONTRACT_CLOSE, start);
  if (end < 0) return null;
  return text.slice(start, end + CONTRACT_CLOSE.length);
}

// Four-case upsert of the contract block into a consumer file:
//   file absent            → created (freshHeader + block);
//   markers present, equal → unchanged;
//   markers present, drift → resynced (ONLY the block is replaced, in place);
//   no markers             → appended at the end — unless `legacyStart` matches a file the
//     PRE-anchor export generated wholesale: that content is harness-owned (any hand edit was
//     already being overwritten on every export), so it is replaced from the match to the end,
//     preserving whatever the project keeps BEFORE it.
function upsertContract(existing, block, { freshHeader = '', legacyStart = null } = {}) {
  if (existing === null) return { action: 'created', content: `${freshHeader}${block}\n` };
  const start = existing.indexOf(CONTRACT_OPEN);
  const end = existing.indexOf(CONTRACT_CLOSE, start);
  if (start >= 0 && end > start) {
    const current = existing.slice(start, end + CONTRACT_CLOSE.length);
    if (current === block) return { action: 'unchanged', content: existing };
    return {
      action: 'resynced',
      content: existing.slice(0, start) + block + existing.slice(end + CONTRACT_CLOSE.length),
    };
  }
  if (legacyStart) {
    const legacyAt = existing.indexOf(legacyStart);
    if (legacyAt >= 0) {
      return { action: 'migrated', content: `${existing.slice(0, legacyAt)}${block}\n` };
    }
  }
  const sep = existing.endsWith('\n\n') ? '' : existing.endsWith('\n') ? '\n' : '\n\n';
  return { action: 'appended', content: `${existing}${sep}${block}\n` };
}

function writeContract(path, result, label) {
  if (result.action !== 'unchanged') writeTextAtomic(path, result.content);
  console.log(`${label}: contract block ${result.action}.`);
}

function fail(message) {
  console.error(`FAIL: ${message}`);
  process.exitCode = 1;
}

function parseArgs(argv) {
  const options = {
    check: false,
    updateManifest: false,
    sourceMode: false,
    exportConsumer: null,
    installHooks: false,
    buildDist: false,
    skipEntrypoints: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    switch (arg.toLowerCase()) {
      case '--check':
      case '-check':
        options.check = true;
        break;
      case '--update-manifest':
      case '-updatemanifest':
        options.updateManifest = true;
        break;
      case '--source-mode':
      case '-sourcemode':
        options.sourceMode = true;
        break;
      case '--export-consumer':
      case '-exportconsumer':
        index += 1;
        if (!argv[index]) throw new Error(`${arg} requires a path.`);
        options.exportConsumer = argv[index];
        break;
      case '--install-hooks':
      case '-installhooks':
        options.installHooks = true;
        break;
      case '--build-dist':
      case '-builddist':
        options.buildDist = true;
        break;
      case '--skip-entrypoints':
      case '-skipentrypoints':
        // Internal to the dist build: mirror and validate WITHOUT anchoring the three entry
        // files — dist ships without them; the consumer's first sync creates them in place.
        options.skipEntrypoints = true;
        break;
      case '--help':
      case '-h':
      case '-help':
        console.log(`Usage:
  node scripts/sync-harness.mjs [--check] [--source-mode]
  node scripts/sync-harness.mjs --update-manifest
  node scripts/sync-harness.mjs --export-consumer <target> [--install-hooks]
  node scripts/sync-harness.mjs --build-dist

Equivalent wrappers: scripts/sync-harness.ps1 and scripts/sync-harness.sh.`);
        process.exit(0);
        break;
      default:
        throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (options.sourceMode && !options.check) {
    throw new Error('--source-mode is only valid with --check.');
  }
  if (options.exportConsumer && (options.check || options.updateManifest || options.sourceMode)) {
    throw new Error('--export-consumer cannot be combined with --check/--update-manifest/--source-mode.');
  }
  if (options.installHooks && !options.exportConsumer) {
    throw new Error('--install-hooks is only valid with --export-consumer.');
  }
  if (
    options.buildDist &&
    (options.check || options.updateManifest || options.sourceMode || options.exportConsumer)
  ) {
    throw new Error('--build-dist cannot be combined with other flags.');
  }
  return options;
}

function readText(path) {
  return readFileSync(path, 'utf8').replace(/^\uFEFF/, '').replace(/\r\n/g, '\n');
}

function writeTextAtomic(path, content) {
  mkdirSync(dirname(path), { recursive: true });
  const temporary = `${path}.pelizzai-tmp-${process.pid}`;
  writeFileSync(temporary, content, 'utf8');
  renameSync(temporary, path);
}

function listSkillNames(skillsRoot = srcSkills) {
  return readdirSync(skillsRoot, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort((a, b) => a.localeCompare(b));
}

function buildAgentsMd() {
  const header = `<!-- GENERATED by scripts/sync-harness.mjs from CLAUDE.md — do NOT edit by hand. -->
<!-- To change the guidelines, edit CLAUDE.md and run your platform's sync-harness. -->

`;
  const body = readText(claudeMd).trimEnd();
  return `${header}${body}${harnessSection().trimEnd()}\n`;
}

// The AGENTS.md/GEMINI.md tail shared by the source-repo whole file and the consumer block:
// how to enter the harness plus the current skill roster (the CONSUMER's roster when run there).
function harnessSection() {
  const skills = listSkillNames();
  return `

---

## Skills harness (PelizzAI)

This project uses the **PelizzAI** skills harness. Skills live in \`.agents/skills/<name>/SKILL.md\`, a mirror of \`.claude/skills/\`. Read and follow the relevant skill before acting.

**Entry:** start with \`pelizzai-core\` and \`pelizzai-router\`. The router classifies effect, risk, uncertainty, and surfaces; it picks a head skill and overlays. Read-only operations initialize no state. Before the first write, confirm isolation and branch. In the source repo, use the native plan/execution record; in a consumer, state/specs/plans follow the lifecycle.

**Branch protection:** never commit to \`main\`/\`master\`/\`develop\`/\`dev\` or on a detached HEAD. Isolate via \`pelizzai-starting-branch\`.

**User authority:** the harness classifies, reasons, researches with Context7/official documentation, and recommends; the user decides requirements, scope, UX, architecture, data, accepted risk, and acceptance criteria. Ask one question at a time, with the best option recommended. Greenfield goes through discovery, spec, and plan — stress-tested and ratified.

**Context7:** treat it as the preferred technical source whenever libraries, frameworks, APIs, versions, or external capabilities influence the task. Inspect manifests/lockfiles first, consult the documentation for the relevant version, and use the evidence to improve questions and recommendations; never turn it into the user's vote.

**Ratification gate:** isolation, execution mode (with \`team\` always visible), and commit strategy are recommendations ratified before being applied; \`squash-final\` only on explicit request. Push/PR/publication are confirmed per task.

Available skills (${skills.length}): ${skills.join(', ')}.
`;
}

// Consumer CLAUDE.md contract: the consumer bridge plus everything from '## Behavioral
// guidelines' down in the SOURCE CLAUDE.md, wrapped in the anchor markers.
function buildConsumerClaudeContract(sourceClaude) {
  const marker = '## Behavioral guidelines';
  const markerIndex = sourceClaude.indexOf(marker);
  if (markerIndex < 0) throw new Error(`CLAUDE.md is missing the '${marker}' section.`);
  const bridge = `## PelizzAI harness (mandatory entry point)

This repository consumes PelizzAI. For project requests, enter through \`pelizzai-core\` → \`pelizzai-router\`. The router picks a head skill, reasoning techniques, and overlays; Context7/official documentation grounds the technical reading; every material decision goes back to the user.

This is a consumer: there is no \`scripts/pelizzai-source-repo.txt\`. The manifest separates core from domain skills; harness updates never overwrite the project's own skills, and this block is the only part of this file the harness manages — project content outside the markers is preserved.

`;
  return `${CONTRACT_OPEN}\n${bridge}${sourceClaude.slice(markerIndex).trimEnd()}\n${CONTRACT_CLOSE}`;
}

// Consumer AGENTS.md/GEMINI.md contract: the SAME contract core carried by CLAUDE.md's block,
// plus the skills-harness section, wrapped in the anchor markers.
function buildAgentsContractBlock(claudeContract) {
  const core = claudeContract.replace(CONTRACT_OPEN, '').replace(CONTRACT_CLOSE, '').trim();
  const note =
    '<!-- PelizzAI harness block — managed by scripts/sync-harness.mjs; edit outside the markers only. -->';
  return `${CONTRACT_OPEN}\n${note}\n\n${core}${harnessSection().trimEnd()}\n${CONTRACT_CLOSE}`;
}

function walkFiles(base) {
  if (!existsSync(base)) return [];
  const files = [];
  for (const entry of readdirSync(base, { withFileTypes: true })) {
    const full = join(base, entry.name);
    if (entry.isDirectory()) files.push(...walkFiles(full));
    else if (entry.isFile()) files.push(full);
  }
  return files;
}

function hashFile(path) {
  return createHash('sha256').update(readFileSync(path)).digest('hex');
}

function treeDiffCount(left, right) {
  const leftFiles = new Map(walkFiles(left).map((path) => [relative(left, path), hashFile(path)]));
  const rightFiles = new Map(walkFiles(right).map((path) => [relative(right, path), hashFile(path)]));
  const keys = new Set([...leftFiles.keys(), ...rightFiles.keys()]);
  let differences = 0;
  for (const key of keys) {
    if (leftFiles.get(key) !== rightFiles.get(key)) differences += 1;
  }
  return differences;
}

function buildCoreManifest() {
  return `# PelizzAI core skills — GENERATED by scripts/sync-harness.mjs --update-manifest.
# Regenerate only in the source repo. Consumers use this manifest to separate core from domain.
${listSkillNames().join('\n')}\n`;
}

function readCoreManifest(path = coreManifest) {
  if (!existsSync(path)) return null;
  return readText(path)
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'));
}

function testRefs() {
  const skillNames = new Set(listSkillNames());
  const markdown = walkFiles(srcSkills).filter((path) => path.endsWith('.md'));
  if (existsSync(claudeMd)) markdown.push(claudeMd); // a fresh consumer may not have it yet
  const refs = new Set();
  for (const path of markdown) {
    for (const match of readText(path).matchAll(/pelizzai-[a-z][a-z0-9-]*/g)) refs.add(match[0]);
  }
  return [...refs].filter((ref) => !skillNames.has(ref) && !REF_IGNORE.has(ref)).sort();
}

function copyExact(source, destination) {
  rmSync(destination, { recursive: true, force: true });
  mkdirSync(dirname(destination), { recursive: true });
  cpSync(source, destination, { recursive: true });
}

function runNode(script, args, cwd) {
  const result = spawnSync(process.execPath, [script, ...args], {
    cwd,
    encoding: 'utf8',
    stdio: 'inherit',
  });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`${script} failed with exit ${result.status}.`);
}

function copyConsumerPayload(target, { anchorEntrypoints = true } = {}) {
  const resolved = resolve(target);
  if (resolved === root) {
    throw new Error('The target cannot be the source repo itself.');
  }
  if (resolved !== distDir && `${resolved}${sep}`.startsWith(`${root}${sep}`)) {
    throw new Error('The target cannot live inside the source repo (except dist/).');
  }
  const core = readCoreManifest();
  if (!core?.length) throw new Error('Core manifest missing; run --update-manifest.');

  const targetSkills = join(target, '.claude', 'skills');
  mkdirSync(targetSkills, { recursive: true });
  for (const name of core) {
    const source = join(srcSkills, name);
    if (!existsSync(source)) throw new Error(`Core skill missing from the source: ${name}`);
    copyExact(source, join(targetSkills, name));
  }

  const orphans = listSkillNames(targetSkills).filter(
    (name) => name.startsWith('pelizzai-') && !core.includes(name),
  );
  if (orphans.length) console.warn(`WARNING: non-core pelizzai-* in the target: ${orphans.join(', ')}`);

  const targetHooks = join(target, '.claude', 'hooks');
  mkdirSync(targetHooks, { recursive: true });
  for (const path of walkFiles(join(root, '.claude', 'hooks'))) {
    if (path.split(/[\\/]/).pop().startsWith('pelizzai-')) {
      cpSync(path, join(targetHooks, path.split(/[\\/]/).pop()));
    }
  }

  const targetScripts = join(target, 'scripts');
  mkdirSync(targetScripts, { recursive: true });
  const scripts = [
    'pelizzai-core-skills.txt',
    'sync-harness.mjs',
    'sync-harness.ps1',
    'sync-harness.sh',
    'install-hooks.mjs',
    'task-brief.ps1',
    'task-brief.sh',
    'review-package.ps1',
    'review-package.sh',
  ];
  for (const name of scripts) {
    const source = join(root, 'scripts', name);
    if (existsSync(source)) cpSync(source, join(targetScripts, name));
  }
  rmSync(join(targetScripts, 'pelizzai-source-repo.txt'), { force: true });
  rmSync(join(targetScripts, 'test-harness-contracts.ps1'), { force: true });

  const cursorAdapter = join(root, '.cursor', 'rules', 'pelizzai.mdc');
  if (!existsSync(cursorAdapter)) {
    throw new Error('Cursor adapter missing from the source: .cursor/rules/pelizzai.mdc');
  }
  const targetCursorRules = join(target, '.cursor', 'rules');
  mkdirSync(targetCursorRules, { recursive: true });
  cpSync(cursorAdapter, join(targetCursorRules, 'pelizzai.mdc'));

  // The target's own sync anchors the three entry files from the contract asset just copied
  // with the skills (create when absent, append when present, resync drift, migrate legacy) —
  // the same self-repair any later consumer sync performs. The dist build skips the anchoring:
  // dist ships no entry files, and the consumer's first sync creates them in place.
  const entryArgs = anchorEntrypoints ? [] : ['--skip-entrypoints'];
  const targetSync = join(targetScripts, 'sync-harness.mjs');
  runNode(targetSync, [...entryArgs], target);
  runNode(targetSync, ['--check', ...entryArgs], target);
  return core;
}

function exportConsumer(destination, installHooks) {
  if (!existsSync(sourceSentinel)) {
    throw new Error('--export-consumer only runs in the source repo (sentinel missing).');
  }
  if (!existsSync(destination) || !statSync(destination).isDirectory()) {
    throw new Error(`Target does not exist or is not a directory: ${destination}`);
  }
  const target = resolve(destination);
  if (target === root) throw new Error('Target cannot be the source repo itself.');

  const core = copyConsumerPayload(target);

  if (installHooks) {
    runNode(join(target, 'scripts', 'install-hooks.mjs'), ['--project', target], target);
  }

  console.log(
    `Consumer export complete: ${target} (${core.length} core skills; Cursor adapter; domain skills, ` +
      `pelizzai/, and project content in CLAUDE.md/AGENTS.md/GEMINI.md preserved — the harness manages ` +
      `only its anchored contract block; hooks ${installHooks ? 'registered' : 'copied, registration pending user decision'}).`,
  );
}

function buildDist({ quiet = false } = {}) {
  if (!existsSync(sourceSentinel)) {
    throw new Error('--build-dist only runs in the source repo (sentinel missing).');
  }
  rmSync(distDir, { recursive: true, force: true });
  mkdirSync(distDir, { recursive: true });
  const core = copyConsumerPayload(distDir, { anchorEntrypoints: false });
  if (!quiet) {
    console.log(
      `dist/ regenerated (${core.length} core skills; no sentinel, no entry files — the first ` +
        `sync/bootstrap anchors CLAUDE.md/AGENTS.md/GEMINI.md in place): copy its contents to your project root.`,
    );
  }
}

function check(sourceMode, skipEntrypoints = false) {
  let problems = 0;
  const difference = treeDiffCount(srcSkills, dstSkills);
  if (difference) {
    console.error(`FAIL: .agents/skills out of sync (${difference} file(s)).`);
    problems += 1;
  }
  const sentinelPresent = existsSync(sourceSentinel);
  const claudeText = existsSync(claudeMd) ? readText(claudeMd) : '';
  if (sentinelPresent) {
    // Source repo: the shipped asset must match what CLAUDE.md derives, and the root entry
    // files stay wholly generated (there they ARE the authority — no markers).
    const expectedAsset = `${buildConsumerClaudeContract(claudeText)}\n`;
    if (!existsSync(contractAsset) || readText(contractAsset) !== expectedAsset) {
      console.error('FAIL: contract asset out of sync with CLAUDE.md (run the sync).');
      problems += 1;
    }
    const expected = buildAgentsMd();
    if (!existsSync(agentsMd) || readText(agentsMd) !== expected) {
      console.error('FAIL: AGENTS.md out of sync with CLAUDE.md.');
      problems += 1;
    }
    if (!existsSync(geminiMd) || readText(geminiMd) !== expected) {
      console.error('FAIL: GEMINI.md out of sync with CLAUDE.md.');
      problems += 1;
    }
  } else if (!skipEntrypoints && existsSync(contractAsset)) {
    // Anchored consumer: each of the THREE entry files must carry the block the asset derives
    // — the project owns everything around it. A missing file or a tampered block is repaired
    // by the sync itself, so the failure message says exactly that.
    const block = readText(contractAsset).trimEnd();
    const expectedAgents = buildAgentsContractBlock(block);
    for (const [path, label, expectedBlock] of [
      [claudeMd, 'CLAUDE.md', block],
      [agentsMd, 'AGENTS.md', expectedAgents],
      [geminiMd, 'GEMINI.md', expectedAgents],
    ]) {
      const actualBlock = existsSync(path) ? extractContract(readText(path)) : null;
      if (actualBlock !== expectedBlock) {
        console.error(
          `FAIL: ${label} contract block missing or out of sync — run node scripts/sync-harness.mjs to anchor/repair it.`,
        );
        problems += 1;
      }
    }
  } else if (!skipEntrypoints) {
    // Legacy consumer without the shipped asset: whole-file equality, as before.
    if (!existsSync(claudeMd)) {
      console.error('FAIL: CLAUDE.md missing and no contract asset available (reinstall the core skills).');
      problems += 1;
    } else {
      const expected = buildAgentsMd();
      if (!existsSync(agentsMd) || readText(agentsMd) !== expected) {
        console.error('FAIL: AGENTS.md out of sync with CLAUDE.md.');
        problems += 1;
      }
      if (!existsSync(geminiMd) || readText(geminiMd) !== expected) {
        console.error('FAIL: GEMINI.md out of sync with CLAUDE.md.');
        problems += 1;
      }
    }
  }
  const broken = testRefs();
  if (broken.length) {
    console.error(`FAIL: broken pelizzai-* references: ${broken.join(', ')}`);
    problems += 1;
  }

  const core = readCoreManifest();
  if (!core) {
    console.error('FAIL: manifest missing. Run --update-manifest in the source repo.');
    problems += 1;
  } else {
    const directories = listSkillNames();
    const dangling = core.filter((name) => !directories.includes(name));
    const domain = directories.filter((name) => !core.includes(name));
    const duplicates = core.filter((name, index) => core.indexOf(name) !== index);
    if (dangling.length) {
      console.error(`FAIL: manifest lists nonexistent skills: ${dangling.join(', ')}`);
      problems += 1;
    }
    if (duplicates.length) {
      console.error(`FAIL: manifest contains duplicates: ${[...new Set(duplicates)].join(', ')}`);
      problems += 1;
    }
    if (sourceMode && domain.length) {
      console.error(`FAIL: source repo has skills outside the manifest: ${domain.join(', ')}`);
      problems += 1;
    } else if (domain.length) {
      console.log(`INFO: ${domain.length} domain skill(s): ${domain.join(', ')}`);
    }
  }

  if (sourceMode) {
    const distProblems = [];
    if (!existsSync(join(distDir, '.cursor', 'rules', 'pelizzai.mdc'))) {
      distProblems.push('Cursor adapter missing');
    }
    if (existsSync(join(distDir, 'scripts', 'pelizzai-source-repo.txt'))) {
      distProblems.push('source mode sentinel present');
    }
    if (existsSync(join(distDir, 'scripts', 'test-harness-contracts.ps1'))) {
      distProblems.push('contract suite present');
    }
    // dist ships NO entry files: the consumer's first sync/bootstrap anchors them in place
    // (create when absent, append/resync when present) from the contract asset it does ship.
    for (const name of ['CLAUDE.md', 'AGENTS.md', 'GEMINI.md']) {
      if (existsSync(join(distDir, name))) {
        distProblems.push(`${name} present (entry files are anchored at install, not shipped)`);
      }
    }
    if (!existsSync(join(distDir, '.claude', 'skills', 'pelizzai-audit', 'assets', 'contract.md'))) {
      distProblems.push('contract asset missing');
    }
    const distSkillsDiff = treeDiffCount(srcSkills, join(distDir, '.claude', 'skills'));
    if (distSkillsDiff) distProblems.push(`skills out of sync (${distSkillsDiff} file(s))`);
    if (distProblems.length) {
      console.error(`FAIL: dist/ invalid: ${distProblems.join('; ')}. Run the sync (or --build-dist).`);
      problems += 1;
    }
  }

  if (problems) return 1;
  console.log(
    `OK: harness in sync (.agents, AGENTS.md, GEMINI.md, refs, manifest; ${sourceMode ? 'source repo' : 'consumer'} mode).`,
  );
  return 0;
}

function generate(updateManifest, skipEntrypoints = false) {
  const sourceMode = existsSync(sourceSentinel);
  if (sourceMode) {
    // The consumer contract asset is GENERATED from CLAUDE.md and ships with the core skills:
    // it is the seed every consumer sync uses to create/repair the three entry files. Written
    // BEFORE the mirror copy so it travels in .agents/, dist/, and every export.
    mkdirSync(dirname(contractAsset), { recursive: true });
    writeTextAtomic(contractAsset, `${buildConsumerClaudeContract(readText(claudeMd))}\n`);
  }
  copyExact(srcSkills, dstSkills);
  // Consumer: anchor the THREE entry files from the shipped asset — absent → create; present
  // without markers → append (files the pre-anchor sync generated wholesale are migrated in
  // place); identical → skip; drifted/tampered → resync ONLY the block. This is what keeps the
  // PelizzAI instructions always present in the entry files, whatever happens to them between
  // syncs. Source repo: whole-file generation (there the files ARE the authority). Dist build
  // (--skip-entrypoints): no entry files at all — the consumer's first sync anchors them.
  if (!sourceMode && !skipEntrypoints && existsSync(contractAsset)) {
    const block = readText(contractAsset).trimEnd();
    const existingClaude = existsSync(claudeMd) ? readText(claudeMd) : null;
    writeContract(
      claudeMd,
      upsertContract(existingClaude, block, {
        freshHeader: '# CLAUDE.md\n\n',
        legacyStart: '## PelizzAI harness (mandatory entry point)',
      }),
      'CLAUDE.md',
    );
    const agentsBlock = buildAgentsContractBlock(block);
    for (const [path, label] of [
      [agentsMd, 'AGENTS.md'],
      [geminiMd, 'GEMINI.md'],
    ]) {
      const existing = existsSync(path) ? readText(path) : null;
      writeContract(
        path,
        upsertContract(existing, agentsBlock, {
          legacyStart: '<!-- GENERATED by scripts/sync-harness.mjs',
        }),
        label,
      );
    }
  } else if (!skipEntrypoints) {
    if (!existsSync(claudeMd)) {
      throw new Error(
        'CLAUDE.md missing and no contract asset available — reinstall the core skills ' +
          '(.claude/skills/pelizzai-audit/assets/contract.md) and rerun the sync.',
      );
    }
    const agents = buildAgentsMd();
    writeTextAtomic(agentsMd, agents);
    writeTextAtomic(geminiMd, agents);
  }
  if (updateManifest) {
    if (!existsSync(sourceSentinel)) throw new Error('--update-manifest only runs in the source repo.');
    writeTextAtomic(coreManifest, buildCoreManifest());
    console.log(`Manifest updated (${readCoreManifest().length} core skills).`);
  } else if (!existsSync(coreManifest)) {
    console.warn('NOTE: manifest missing; run --update-manifest in the source repo.');
  }
  if (existsSync(sourceSentinel)) {
    console.log('Regenerating dist/ (install-by-copy)…');
    buildDist({ quiet: true });
  }
  const difference = treeDiffCount(srcSkills, dstSkills);
  const broken = testRefs();
  console.log(`.agents/skills mirrored (divergences: ${difference}).`);
  console.log(`AGENTS.md and GEMINI.md generated (${listSkillNames().length} skills).`);
  console.log(`broken pelizzai-* references: ${broken.length}`);
  if (difference || broken.length) return 1;
  console.log('Sync completed successfully.');
  return 0;
}

try {
  const options = parseArgs(process.argv.slice(2));
  if (options.exportConsumer) {
    exportConsumer(options.exportConsumer, options.installHooks);
  } else if (options.buildDist) {
    buildDist();
  } else if (options.check) {
    process.exitCode = check(options.sourceMode, options.skipEntrypoints);
  } else {
    process.exitCode = generate(options.updateManifest, options.skipEntrypoints);
  }
} catch (error) {
  fail(error instanceof Error ? error.message : String(error));
}
