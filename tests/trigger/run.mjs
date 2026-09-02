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
 *   node tests/trigger/run.mjs --runs 5         repeat every case N times and report rates
 *   node tests/trigger/run.mjs --harness <dir>  test another checkout of the harness (an A/B arm)
 *   node tests/trigger/run.mjs --json <file>    write every run's verdict, notes and transcript path
 *
 * `--harness` points at any directory holding `.claude/` and `CLAUDE.md` — typically a git
 * worktree frozen at an older commit. The prompts, the fixture and the expectations always come
 * from THIS checkout, so two arms are scored by the same rule; only the doctrine under test moves.
 * Agents are stochastic: a single run is an anecdote, and `--runs` is how a case becomes a rate.
 *
 * This is NOT wired into CI: it costs tokens and needs credentials. It is run
 * before a slice lands, and its output belongs in the slice's PR.
 *
 * Exit codes: 0 every run of every case passed; 1 any run failed; 2 the agent CLI is
 * unavailable or the arguments are unusable.
 */

import { readFileSync, existsSync, mkdirSync, rmSync, writeFileSync, cpSync, readdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { writeFixture } from './fixture.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '..', '..');

const argv = process.argv.slice(2);
const flags = new Set(argv.filter((a) => a.startsWith('--')));
function valueOf(flag) {
  const index = argv.indexOf(flag);
  return index !== -1 ? argv[index + 1] : null;
}
const model = valueOf('--model');
const harnessArg = valueOf('--harness');
const runsArg = valueOf('--runs');
const jsonArg = valueOf('--json');
const consumed = new Set([model, harnessArg, runsArg, jsonArg].filter(Boolean));
const only = argv.filter((a) => !a.startsWith('--') && !consumed.has(a));
const keep = flags.has('--keep') || Boolean(jsonArg);
const withHooks = flags.has('--hooks');
const withGit = flags.has('--git');
const harness = harnessArg ? resolve(harnessArg) : root;
const runs = runsArg ? Number(runsArg) : 1;

if (!Number.isInteger(runs) || runs < 1) {
  console.error('trigger: --runs requires a positive integer');
  process.exit(2);
}
if (!existsSync(join(harness, '.claude', 'skills')) || !existsSync(join(harness, 'CLAUDE.md'))) {
  console.error(`trigger: --harness ${harness} has no .claude/skills or CLAUDE.md — nothing to install`);
  process.exit(2);
}

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
function makeScratch(id, run) {
  const dir = join(tmpdir(), 'pelizzai-trigger', `${id}-${process.pid}-r${run}`);
  rmSync(dir, { recursive: true, force: true });
  mkdirSync(join(dir, 'project', 'src', 'pages'), { recursive: true });
  const project = join(dir, 'project');

  cpSync(join(harness, '.claude'), join(project, '.claude'), { recursive: true });
  cpSync(join(harness, 'CLAUDE.md'), join(project, 'CLAUDE.md'));

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
    // A git step that fails silently leaves the scratch without the protected branch the flag
    // promises — the writegate then guards nothing and the case scores a transcript that never
    // exercised the protection. Fail the case loudly instead of measuring that.
    const git = (...a) => {
      const r = spawnSync('git', a, { cwd: project, encoding: 'utf8', windowsHide: true });
      if (r.status !== 0) {
        throw new Error(`--git setup failed at "git ${a.join(' ')}" (${r.status}): ${r.stderr || r.stdout}`);
      }
      return r;
    };
    git('init', '-b', 'main');
    git('config', 'user.email', 'trigger@pelizzai.test');
    git('config', 'user.name', 'trigger');
    git('add', '-A');
    git('commit', '-m', 'scratch baseline');
  } else if (withHooks) {
    // Deliberately allowed (the two variables never move together), but never silently: without a
    // repo the writegate has no branch to protect and only the other hooks are exercised.
    console.error('trigger: --hooks without --git — the writegate is inert in this configuration.');
  }

  /**
   * With `--hooks`, register them the way a user would: by running the installer,
   * not by hand-writing settings.json. If the installer is what is broken, the
   * test should find that too.
   */
  if (withHooks) {
    // The harness under test brings its own installer when it has one. An older snapshot without
    // one (an A/B arm) is installed by THIS checkout's installer, restricted to the hooks that
    // snapshot actually ships: registering a hook file that does not exist would only add
    // "cannot find module" noise to every tool call of the arm being measured.
    const ownInstaller = join(harness, 'scripts', 'install-hooks.mjs');
    const installer = existsSync(ownInstaller) ? ownInstaller : join(root, 'scripts', 'install-hooks.mjs');
    const installArgs = [installer, '--project', project];
    if (installer !== ownInstaller) {
      const hooksDir = join(harness, '.claude', 'hooks');
      const shipped = existsSync(hooksDir)
        ? readdirSync(hooksDir)
            .map((file) => /^pelizzai-(guardrails|writegate|cadence|session-start)\.mjs$/.exec(file)?.[1])
            .filter(Boolean)
        : [];
      if (shipped.length === 0) throw new Error(`--hooks: ${harness} ships no installable hook`);
      installArgs.push('--only', shipped.join(','));
    }
    const install = spawnSync(process.execPath, installArgs, { encoding: 'utf8', windowsHide: true });
    if (install.status !== 0) {
      throw new Error(`install-hooks failed (${install.status}): ${install.stderr || install.stdout}`);
    }
  }

  return { dir, project };
}

function parseTranscript(raw) {
  const skills = [];
  const tools = [];
  const shellCommands = [];
  let assistantTurns = 0;
  let modelSeen = null;
  for (const line of raw.split('\n')) {
    if (!line.trim().startsWith('{')) continue;
    let event;
    try {
      event = JSON.parse(line);
    } catch {
      continue;
    }
    // The init event names the model that actually answered — the only honest record of it when
    // `--model` was not given and the CLI default moved between two batteries.
    if (event?.type === 'system' && event.subtype === 'init' && typeof event.model === 'string') {
      modelSeen = event.model;
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
        if ((name === 'Bash' || name === 'PowerShell') && typeof block.input?.command === 'string') {
          shellCommands.push({ command: block.input.command, at: tools.length + skills.length - 1 });
        }
      }
    }
  }
  return { skills, tools, shellCommands, assistantTurns, modelSeen };
}

/**
 * `forbidTools: [Edit, Write]` proves nothing while Bash stays open: `printf x > file` or a git
 * mutation changes the project without either tool. This names the shell-write signatures we can
 * detect honestly. BEST-EFFORT by design — a `>` inside a quoted string can false-positive and an
 * exotic writer can slip through — but every signature listed here is one the old suite scored as
 * a clean pass. Returns the matched signature, or null for a read-only command.
 */
function shellWriteSignature(command) {
  const patterns = [
    [/(^|\s)\d*>{1,2}\s*(?![&\s])/, 'output redirect'],
    [/\b(tee|mv|cp|rm|mkdir|touch|chmod|ln)\b/, 'file-mutating utility'],
    [/\bsed\s+(-[a-zA-Z]*\s+)*-i/, 'sed -i'],
    [/\bgit\s+(add|commit|checkout\s+-b|switch\s+-c|push|merge|rebase|reset|restore|stash|mv|rm)\b/, 'git mutation'],
    [/\b(Set-Content|Add-Content|Out-File|New-Item)\b/i, 'PowerShell writer'],
    [/\b(npm|pnpm|yarn)\s+(install|add|remove|update)\b/, 'package mutation'],
  ];
  for (const [re, label] of patterns) {
    if (re.test(command)) return label;
  }
  return null;
}

const results = [];

for (let run = 1; run <= runs; run += 1) {
for (const testCase of cases) {
  const promptFile = join(here, 'prompts', `${testCase.id}.txt`);
  if (!existsSync(promptFile)) {
    results.push({ id: testCase.id, run, pass: false, notes: ['prompt file missing'] });
    continue;
  }

  const scratch = makeScratch(testCase.id, run);
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
  process.stdout.write(`  running ${testCase.id}${runs > 1 ? ` [${run}/${runs}]` : ''} ... `);
  const started = Date.now();
  const agent = spawnSync('claude', args, {
    cwd: scratch.project,
    encoding: 'utf8',
    timeout: 300_000,
    maxBuffer: 64 * 1024 * 1024,
    env: process.env,
  });

  const raw = `${agent.stdout ?? ''}\n${agent.stderr ?? ''}`;
  writeFileSync(join(scratch.dir, 'transcript.jsonl'), raw);
  const { skills, tools, shellCommands, assistantTurns, modelSeen } = parseTranscript(raw);
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
  if (testCase.forbidShellWrites) {
    for (const c of shellCommands) {
      const signature = shellWriteSignature(c.command);
      if (signature) {
        notes.push(`shell mutation (${signature}): ${c.command.replace(/\s+/g, ' ').slice(0, 100)}`);
      }
    }
  }
  if (skills.length === 0 && (testCase.skills ?? []).length > 0) {
    notes.push('no Skill invocation found in the transcript');
  }

  const pass = notes.length === 0;
  console.log(pass ? 'pass' : 'FAIL');
  results.push({
    id: testCase.id,
    run,
    pass,
    notes,
    fired: skills.map((s) => s.name),
    toolsBeforeFirstSkill: tools.filter((t) => t.at < firstSkillAt).map((t) => t.name),
    assistantTurns,
    model: modelSeen,
    seconds: Math.round((Date.now() - started) / 1000),
    transcript: join(scratch.dir, 'transcript.jsonl'),
  });
  if (!keep && pass) rmSync(scratch.dir, { recursive: true, force: true });
}
}

console.log('');
const failed = results.filter((r) => !r.pass);
for (const result of failed) {
  console.log(`FAIL ${result.id}${runs > 1 ? ` [run ${result.run}]` : ''}`);
  for (const note of result.notes) console.log(`     ${note}`);
  console.log(`     skills fired: ${result.fired?.length ? result.fired.join(', ') : '(none)'}`);
  console.log(`     transcript:   ${result.transcript}`);
}

// With `--runs`, the unit of report is the RATE per case: a case that passes 3 of 5 is neither a
// pass nor a failure of the doctrine, it is a number the next doctrine change has to move.
if (runs > 1) {
  console.log('rates per case:');
  for (const testCase of cases) {
    const mine = results.filter((r) => r.id === testCase.id);
    const passes = mine.filter((r) => r.pass).length;
    const signatures = [...new Set(mine.flatMap((r) => r.notes))];
    console.log(`  ${testCase.id.padEnd(22)} ${passes}/${mine.length}${signatures.length ? `  — ${signatures.join(' | ')}` : ''}`);
  }
  console.log('');
}
const modelsSeen = [...new Set(results.map((r) => r.model).filter(Boolean))];
console.log(
  `${results.length - failed.length}/${results.length} runs pass` +
    `${runs > 1 ? ` (${cases.length} cases × ${runs} runs)` : ''}` +
    `${modelsSeen.length ? ` (model: ${modelsSeen.join(', ')})` : model ? ` (model: ${model})` : ''}` +
    `${harnessArg ? ` (harness: ${harness})` : ''}`,
);

if (jsonArg) {
  writeFileSync(
    resolve(jsonArg),
    JSON.stringify(
      { harness, hooks: withHooks, git: withGit, modelRequested: model, modelsSeen, runs, cases: cases.map((c) => c.id), results },
      null,
      2,
    ),
  );
  console.log(`verdicts written to ${resolve(jsonArg)}`);
}

process.exit(failed.length === 0 ? 0 : 1);
