#!/usr/bin/env node

/**
 * PelizzAI — behavioural trigger tests.
 *
 * The 682 contract assertions verify that a sentence exists in a file. They
 * would pass identically if the harness never loaded, because they test text,
 * not behaviour. This runner tests behaviour: it starts a real headless agent
 * with the harness installed, feeds it a prompt written to make skipping the
 * harness feel reasonable, and reads the transcript for two things.
 *
 *   1. Did the expected skill actually fire?
 *   2. Did any tool run BEFORE the first skill fired?
 *
 * The second question is the one that matters. An agent that edits a file and
 * then loads the doctrine has not followed the doctrine; it has decorated a
 * decision it already made.
 *
 * Each case runs in a fresh scratch project holding the harness and the small codebase the
 * prompts actually talk about (see fixture.mjs), so nothing in the developer's own repository can
 * rescue a prompt the harness should survive on its own.
 *
 * The user's HOME is NOT isolated, and that is a deliberate trade with a known
 * cost. Isolating it takes the CLI's credentials with it and every run dies at
 * "Not logged in" — which the first version of this file did, silently, while
 * reporting a pass. So the developer's global `~/.claude/CLAUDE.md` and any
 * globally installed skills are in play. If one of them is what makes a case
 * pass, the case is weaker than it looks; the liveness guard below at least
 * guarantees the run happened.
 *
 * Usage:
 *   node tests/trigger/run.mjs                  every case
 *   node tests/trigger/run.mjs skip-the-process one case
 *   node tests/trigger/run.mjs --model haiku    a weaker model, on purpose
 *   node tests/trigger/run.mjs --keep           keep the scratch dirs
 *   node tests/trigger/run.mjs --hooks          register the opt-in hooks first
 *   node tests/trigger/run.mjs --git            make the scratch a repo on a protected branch
 *
 * This is NOT wired into CI: it costs tokens and needs credentials. It is run
 * before a slice lands, and its output belongs in the slice's PR.
 *
 * Exit codes: 0 all cases pass; 1 a case failed; 2 the agent CLI is unavailable.
 */

import { readFileSync, existsSync, mkdirSync, rmSync, writeFileSync, cpSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { writeFixture } from './fixture.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '..', '..');

const argv = process.argv.slice(2);
const flags = new Set(argv.filter((a) => a.startsWith('--')));
const modelIndex = argv.indexOf('--model');
const model = modelIndex !== -1 ? argv[modelIndex + 1] : null;
const only = argv.filter((a) => !a.startsWith('--') && a !== model);
const keep = flags.has('--keep');
const withHooks = flags.has('--hooks');
const withGit = flags.has('--git');

const spec = JSON.parse(readFileSync(join(here, 'expectations.json'), 'utf8'));
const cases = only.length > 0 ? spec.cases.filter((c) => only.includes(c.id)) : spec.cases;

if (cases.length === 0) {
  console.error(`trigger: no case matches ${only.join(', ')}`);
  process.exit(2);
}

const cli = spawnSync('claude', ['--version'], { encoding: 'utf8' });
if (cli.status !== 0) {
  console.error(
    'trigger: the `claude` CLI is not on PATH, so behaviour cannot be observed.\n' +
      'These tests need a real agent; there is no offline substitute for asking whether a skill fired.',
  );
  process.exit(2);
}

/**
 * A minimal project. Enough shape for a route to be classifiable, not enough to
 * distract: one source file the prompts refer to, one plan, and the harness.
 */
function makeScratch(id) {
  const dir = join(tmpdir(), 'pelizzai-trigger', `${id}-${process.pid}`);
  rmSync(dir, { recursive: true, force: true });
  mkdirSync(join(dir, 'project', 'src', 'pages'), { recursive: true });
  const project = join(dir, 'project');

  cpSync(join(root, '.claude'), join(project, '.claude'), { recursive: true });
  cpSync(join(root, 'CLAUDE.md'), join(project, 'CLAUDE.md'));

  writeFixture(project);

  /**
   * `skip-the-process` cites line 84 by number. If the fixture drifts, the prompt starts lying to
   * the agent and the case measures whether it notices a wrong line number instead of whether it
   * respects the gate. Fail loudly here rather than score that.
   */
  const settings = readFileSync(join(project, 'src', 'pages', 'Settings.tsx'), 'utf8').split('\n');
  if (!/type="submit">Aceitar</.test(settings[83] ?? '')) {
    throw new Error(`fixture drift: line 84 of Settings.tsx is ${JSON.stringify(settings[83])}`);
  }

  /**
   * `--git` makes the scratch a real repository on a protected branch. Without it
   * `pelizzai-writegate` has no branch to protect and silently does nothing, so a
   * run with hooks registered still leaves the write guard untested — the harness
   * would look weaker than it is for a reason that lives in the fixture. Kept
   * separate from `--hooks` so the two variables never move together.
   */
  if (withGit) {
    const git = (...a) => spawnSync('git', a, { cwd: project, encoding: 'utf8', windowsHide: true });
    git('init', '-b', 'main');
    git('config', 'user.email', 'trigger@pelizzai.test');
    git('config', 'user.name', 'trigger');
    git('add', '-A');
    git('commit', '-m', 'scratch baseline');
  }

  /**
   * With `--hooks`, register them the way a user would: by running the installer,
   * not by hand-writing settings.json. If the installer is what is broken, the
   * test should find that too.
   */
  if (withHooks) {
    const install = spawnSync(
      process.execPath,
      [join(root, 'scripts', 'install-hooks.mjs'), '--project', project],
      { encoding: 'utf8', windowsHide: true },
    );
    if (install.status !== 0) {
      throw new Error(`install-hooks failed (${install.status}): ${install.stderr || install.stdout}`);
    }
  }

  return { dir, project };
}

function parseTranscript(raw) {
  const skills = [];
  const tools = [];
  let assistantTurns = 0;
  for (const line of raw.split('\n')) {
    if (!line.trim().startsWith('{')) continue;
    let event;
    try {
      event = JSON.parse(line);
    } catch {
      continue;
    }
    if (event?.type === 'assistant' && event.message) assistantTurns += 1;
    const content = event?.message?.content;
    if (!Array.isArray(content)) continue;
    for (const block of content) {
      if (block?.type !== 'tool_use') continue;
      const name = block.name;
      if (name === 'Skill') {
        const id = block.input?.skill ?? '';
        skills.push({ name: String(id).split(':').pop(), at: tools.length + skills.length });
      } else {
        tools.push({ name, at: tools.length + skills.length });
      }
    }
  }
  return { skills, tools, assistantTurns };
}

const results = [];

for (const testCase of cases) {
  const promptFile = join(here, 'prompts', `${testCase.id}.txt`);
  if (!existsSync(promptFile)) {
    results.push({ id: testCase.id, pass: false, notes: ['prompt file missing'] });
    continue;
  }

  const scratch = makeScratch(testCase.id);
  const prompt = readFileSync(promptFile, 'utf8');
  const args = [
    '-p',
    prompt,
    '--dangerously-skip-permissions',
    '--max-turns',
    String(testCase.maxTurns ?? 4),
    '--output-format',
    'stream-json',
    '--verbose',
  ];
  if (model) args.push('--model', model);

  // No shell. The CLI is a native executable, and routing the call through cmd.exe
  // mangles any prompt containing an apostrophe: the first version of this file
  // silently delivered two words of a two-sentence question and reported a pass.
  process.stdout.write(`  running ${testCase.id} ... `);
  const run = spawnSync('claude', args, {
    cwd: scratch.project,
    encoding: 'utf8',
    timeout: 300_000,
    maxBuffer: 64 * 1024 * 1024,
    env: process.env,
  });

  const raw = `${run.stdout ?? ''}\n${run.stderr ?? ''}`;
  writeFileSync(join(scratch.dir, 'transcript.jsonl'), raw);
  const { skills, tools, assistantTurns } = parseTranscript(raw);
  const firstSkillAt = skills.length > 0 ? skills[0].at : Infinity;
  const notes = [];

  /**
   * Liveness first. Without this, a case whose only assertions are prohibitions
   * ("no Edit, no Write") passes when the agent never ran at all: nothing was
   * forbidden because nothing happened. That is a non-discriminating assertion,
   * and the negative case — the one that keeps the suite honest — is exactly
   * where it hides. A run that produced no assistant turn is a broken run.
   */
  if (assistantTurns === 0) {
    const reason = raw.trim().split('\n')[0]?.slice(0, 120) || '(no output at all)';
    notes.push(`the agent produced no assistant turn — the run did not happen: ${reason}`);
  }

  for (const wanted of testCase.skills ?? []) {
    if (!skills.some((s) => s.name === wanted)) notes.push(`skill never fired: ${wanted}`);
  }
  for (const forbidden of testCase.forbidBeforeSkill ?? []) {
    const early = tools.filter((t) => t.name === forbidden && t.at < firstSkillAt);
    if (early.length > 0) notes.push(`${forbidden} ran before any skill (premature action)`);
  }
  for (const forbidden of testCase.forbidTools ?? []) {
    if (tools.some((t) => t.name === forbidden)) notes.push(`${forbidden} was used at all, and must not be`);
  }
  if (skills.length === 0 && (testCase.skills ?? []).length > 0) {
    notes.push('no Skill invocation found in the transcript');
  }

  const pass = notes.length === 0;
  console.log(pass ? 'pass' : 'FAIL');
  results.push({
    id: testCase.id,
    pass,
    notes,
    fired: skills.map((s) => s.name),
    transcript: join(scratch.dir, 'transcript.jsonl'),
  });
  if (!keep && pass) rmSync(scratch.dir, { recursive: true, force: true });
}

console.log('');
const failed = results.filter((r) => !r.pass);
for (const result of failed) {
  console.log(`FAIL ${result.id}`);
  for (const note of result.notes) console.log(`     ${note}`);
  console.log(`     skills fired: ${result.fired?.length ? result.fired.join(', ') : '(none)'}`);
  console.log(`     transcript:   ${result.transcript}`);
}
console.log(`${results.length - failed.length}/${results.length} cases pass${model ? ` (model: ${model})` : ''}`);

process.exit(failed.length === 0 ? 0 : 1);
