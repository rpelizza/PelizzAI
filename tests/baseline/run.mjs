#!/usr/bin/env node

/**
 * PelizzAI — paired baseline.
 *
 * Runs the same task twice: once with the harness installed, once against a bare
 * project with no CLAUDE.md and no skills. Captures tokens and wall-clock for
 * each side and reports the delta.
 *
 * This is the only measurement in the repository that can answer the question the
 * harness exists to answer. The contract suite proves a sentence is present. The
 * trigger tests prove a skill fired. Neither says whether the delivery is better
 * than it would have been without any of it, and no amount of doctrine substitutes
 * for running the task both ways.
 *
 * The numbers are the cheap half. Quality is judged by reading both outputs, which
 * is why the runner writes them side by side and stops there rather than scoring
 * them: a grader that reads only the diff will reward the shorter answer, and the
 * harness is not trying to produce shorter answers.
 *
 * Usage:
 *   node tests/baseline/run.mjs tasks/add-validation.txt
 *   node tests/baseline/run.mjs tasks/add-validation.txt --model sonnet --keep
 *
 * Exit codes: 0 both sides ran; 1 a side failed to produce a transcript;
 * 2 the agent CLI is unavailable or the task file is missing.
 */

import { readFileSync, existsSync, mkdirSync, rmSync, writeFileSync, cpSync } from 'node:fs';
import { dirname, join, resolve, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '..', '..');

const argv = process.argv.slice(2);
const flags = new Set(argv.filter((a) => a.startsWith('--')));
const modelIndex = argv.indexOf('--model');
const model = modelIndex !== -1 ? argv[modelIndex + 1] : null;
const taskArg = argv.find((a) => !a.startsWith('--') && a !== model);

if (!taskArg) {
  console.error('usage: node tests/baseline/run.mjs <task-file> [--model NAME] [--keep]');
  process.exit(2);
}
const taskFile = resolve(here, taskArg);
if (!existsSync(taskFile)) {
  console.error(`baseline: task file not found: ${taskArg}`);
  process.exit(2);
}

const cli = spawnSync('claude', ['--version'], { encoding: 'utf8' });
if (cli.status !== 0) {
  console.error('baseline: the `claude` CLI is not on PATH. A baseline needs a real agent on both sides.');
  process.exit(2);
}

const taskId = basename(taskFile).replace(/\.txt$/, '');
const prompt = readFileSync(taskFile, 'utf8');
const stamp = `${taskId}-${process.pid}`;
const workspace = join(tmpdir(), 'pelizzai-baseline', stamp);

/**
 * The two sides differ in exactly one thing: whether the harness is present.
 * Same fixture, same prompt, same model, same turn budget. Anything else that
 * differs makes the delta unattributable.
 */
function makeSide(name, withHarness) {
  const dir = join(workspace, name);
  const project = join(dir, 'project');
  mkdirSync(join(project, 'src'), { recursive: true });

  const fixture = join(here, 'fixtures', taskId);
  if (existsSync(fixture)) cpSync(fixture, project, { recursive: true });
  else writeFileSync(join(project, 'package.json'), '{\n  "name": "baseline",\n  "private": true\n}\n');

  if (withHarness) {
    cpSync(join(root, '.claude'), join(project, '.claude'), { recursive: true });
    cpSync(join(root, 'CLAUDE.md'), join(project, 'CLAUDE.md'));
  }

  const home = join(dir, 'home');
  mkdirSync(join(home, '.claude'), { recursive: true });
  return { dir, project, home };
}

/** Usage is reported per assistant message; the run's cost is their sum. */
function accumulate(raw) {
  const usage = { input: 0, output: 0, cacheCreate: 0, cacheRead: 0, messages: 0 };
  const outputs = [];
  for (const line of raw.split('\n')) {
    if (!line.trim().startsWith('{')) continue;
    let event;
    try {
      event = JSON.parse(line);
    } catch {
      continue;
    }
    if (event?.type !== 'assistant' || !event.message) continue;
    usage.messages += 1;
    const u = event.message.usage ?? {};
    usage.input += u.input_tokens ?? 0;
    usage.output += u.output_tokens ?? 0;
    usage.cacheCreate += u.cache_creation_input_tokens ?? 0;
    usage.cacheRead += u.cache_read_input_tokens ?? 0;
    for (const block of event.message.content ?? []) {
      if (block?.type === 'text' && block.text?.trim()) outputs.push(block.text);
    }
  }
  return { usage, text: outputs.join('\n\n') };
}

function runSide(name, withHarness) {
  const side = makeSide(name, withHarness);
  const args = [
    '-p',
    prompt,
    '--dangerously-skip-permissions',
    '--max-turns',
    '30',
    '--output-format',
    'stream-json',
    '--verbose',
  ];
  if (model) args.push('--model', model);

  process.stdout.write(`  ${name} ... `);
  const started = Date.now();
  const run = spawnSync('claude', args, {
    cwd: side.project,
    encoding: 'utf8',
    timeout: 900_000,
    maxBuffer: 128 * 1024 * 1024,
    env: { ...process.env, HOME: side.home, USERPROFILE: side.home },
  });
  const durationMs = Date.now() - started;

  const raw = `${run.stdout ?? ''}\n${run.stderr ?? ''}`;
  writeFileSync(join(side.dir, 'transcript.jsonl'), raw);
  const { usage, text } = accumulate(raw);
  writeFileSync(join(side.dir, 'answer.md'), text || '(no assistant text captured)');

  console.log(`${(durationMs / 1000).toFixed(1)}s, ${usage.output.toLocaleString('en-US')} output tokens`);
  return { name, dir: side.dir, durationMs, usage, ok: usage.messages > 0 };
}

console.log(`paired baseline: ${taskId}${model ? ` (model: ${model})` : ''}\n`);
const withHarness = runSide('with-harness', true);
const without = runSide('without-harness', false);

const pct = (a, b) => (b === 0 ? '—' : `${(((a - b) / b) * 100).toFixed(0)}%`);
const fmt = (n) => n.toLocaleString('en-US');

console.log('\n  metric                with harness      without      delta');
console.log(`  ${'-'.repeat(20)} ${'-'.repeat(13)} ${'-'.repeat(12)} ${'-'.repeat(10)}`);
const rows = [
  ['output tokens', withHarness.usage.output, without.usage.output],
  ['input tokens', withHarness.usage.input, without.usage.input],
  ['cache read', withHarness.usage.cacheRead, without.usage.cacheRead],
  ['assistant turns', withHarness.usage.messages, without.usage.messages],
  ['seconds', Math.round(withHarness.durationMs / 1000), Math.round(without.durationMs / 1000)],
];
for (const [label, a, b] of rows) {
  console.log(`  ${label.padEnd(20)} ${fmt(a).padStart(13)} ${fmt(b).padStart(12)} ${pct(a, b).padStart(10)}`);
}

const report = { task: taskId, model, withHarness, without, capturedAt: null };
writeFileSync(join(workspace, 'baseline.json'), JSON.stringify(report, null, 2));

console.log(`\n  answers written side by side, for the half a number cannot judge:`);
console.log(`    ${join(withHarness.dir, 'answer.md')}`);
console.log(`    ${join(without.dir, 'answer.md')}`);
console.log(`  data: ${join(workspace, 'baseline.json')}`);

if (!flags.has('--keep') && withHarness.ok && without.ok) {
  console.log('  (--keep to retain the transcripts)');
}

process.exit(withHarness.ok && without.ok ? 0 : 1);
