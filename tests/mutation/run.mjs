#!/usr/bin/env node
/**
 * PelizzAI — mutation suite for the instruments.
 *
 * Each mutation plants a defect in a disposable copy of the repository and asserts that the named
 * instrument CATCHES it. A green checker that no mutation can turn red is theater; this file is
 * how the instruments prove they are not. Only defects an instrument still enforces are planted:
 * size is reported, not enforced, so no mutation grows a file and expects a failure.
 *
 * The STALE guard (from the Noetron oracle suite): if a mutation's edit leaves the file
 * unchanged, the anchor text moved and the mutation tested NOTHING — that counts as a miss, never
 * as a pass. It is what keeps this suite from going green by rot.
 *
 * Every mutation resolves against the sandbox, never against the working tree.
 *
 * Usage: node tests/mutation/run.mjs        Exit 0 all caught; 1 any missed or stale.
 */
import { cpSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');

function runTool(sandbox, script, args = []) {
  return spawnSync(process.execPath, [join(sandbox, 'scripts', script), ...args], {
    encoding: 'utf8',
    cwd: sandbox,
    windowsHide: true,
  });
}

const MUTATIONS = [
  {
    defect: 'an unquoted colon returns to a description (the silent-trigger bug)',
    file: '.claude/skills/pelizzai-quick-fix/SKILL.md',
    edit: (t) => t.replace(/^description: "(.*)"$/m, 'description: The cheapest route: use for a low-risk tweak.'),
    tool: (s) => runTool(s, 'validate-skills.mjs'),
    expect: /description-yaml-scalar/,
  },
  {
    defect: 'a skill H1 reverts to a name that no longer exists',
    file: '.claude/skills/pelizzai-diagnose/SKILL.md',
    edit: (t) => t.replace(/^# PelizzAI Diagnose$/m, '# PelizzAI Debugging'),
    tool: (s) => runTool(s, 'validate-skills.mjs'),
    expect: /h1-matches-name/,
  },
  {
    defect: 'a skill is renamed in its frontmatter but not on disk (two identifiers for one skill)',
    file: '.claude/skills/pelizzai-experiment/SKILL.md',
    edit: (t) => t.replace(/^name: pelizzai-experiment$/m, 'name: pelizzai-prototype'),
    tool: (s) => runTool(s, 'validate-skills.mjs'),
    expect: /name-matches-directory/,
  },
  {
    defect: 'a route declares a head file that was deleted or moved (the budget measures a ghost)',
    file: 'scripts/harness-budget.json',
    edit: (t) => t.replace('".claude/skills/pelizzai-execute/references/task-cycle.md"', '".claude/skills/pelizzai-execute/references/task-cycle-v2.md"'),
    tool: (s) => runTool(s, 'measure-hotpath.mjs'),
    expect: /BUDGET ERRORS[\s\S]*task-cycle-v2\.md, which does not exist/,
  },
  {
    defect: 'a head skill links a reference nobody budgeted (invisible hot-path growth)',
    file: '.claude/skills/pelizzai-quick-fix/SKILL.md',
    edit: (t) => t + '\nSee [extra rules](references/extra-rules.md) for details.\n',
    prepare: (sandbox) => {
      const dir = join(sandbox, '.claude', 'skills', 'pelizzai-quick-fix', 'references');
      mkdirSync(dir, { recursive: true }); // the lean skill ships no references/ — cpSync alone would ENOENT
      cpSync(join(sandbox, '.claude', 'skills', 'pelizzai-quick-fix', 'SKILL.md'), join(dir, 'extra-rules.md'));
    },
    tool: (s) => runTool(s, 'measure-hotpath.mjs'),
    expect: /DRIFT/,
  },
  {
    defect: 'a core skill disappears from the manifest but not from disk',
    file: 'scripts/pelizzai-core-skills.txt',
    edit: (t) => t.replace(/^pelizzai-evolve\r?\n/m, ''),
    tool: (s) => runTool(s, 'sync-harness.mjs', ['--check', '--source-mode']),
    // The sandbox now carries dist/, so --check --source-mode passes clean without the mutation —
    // and the expect names the ONE message this defect produces. The old broad regex over an
    // always-failing run was an assertion that could not fail.
    expect: /source repo has skills outside the manifest[\s\S]*pelizzai-evolve/i,
  },
  {
    defect: "the managed block's end marker is deleted from AGENTS.md",
    file: 'AGENTS.md',
    edit: (t) => t.replace('<!-- pelizzai:end -->', ''),
    tool: (s) => runTool(s, 'sync-harness.mjs', ['--check']),
    expect: /AGENTS\.md out of sync/,
  },
];

const sandboxRoot = mkdtempSync(join(tmpdir(), 'pelizzai-mutation-'));
let missed = 0;

try {
  for (const [i, m] of MUTATIONS.entries()) {
    const sandbox = join(sandboxRoot, `m${i}`);
    for (const dir of ['.claude', '.agents', '.cursor', 'scripts', 'dist']) {
      cpSync(join(root, dir), join(sandbox, dir), { recursive: true });
    }
    for (const f of ['CLAUDE.md', 'AGENTS.md', 'GEMINI.md', 'README.md']) {
      cpSync(join(root, f), join(sandbox, f));
    }

    const target = join(sandbox, m.file);
    const original = readFileSync(target, 'utf8');
    const mutated = m.edit(original);
    if (mutated === original) {
      console.error(`STALE  ${m.defect} — the anchor text moved, this mutation tested nothing`);
      missed++;
      continue;
    }
    writeFileSync(target, mutated);
    if (m.prepare) m.prepare(sandbox);

    const result = m.tool(sandbox);
    const output = `${result.stdout}\n${result.stderr}`;
    if (result.status !== 0 && m.expect.test(output)) {
      console.log(`caught ${m.defect}`);
    } else {
      console.error(`MISSED ${m.defect} — exit ${result.status}; reported instead:`);
      console.error(output.split('\n').slice(0, 8).map((l) => `  ${l}`).join('\n'));
      missed++;
    }
  }
} finally {
  rmSync(sandboxRoot, { recursive: true, force: true });
}

console.log(`\n${MUTATIONS.length - missed}/${MUTATIONS.length} mutations caught.`);
process.exit(missed ? 1 : 0);
