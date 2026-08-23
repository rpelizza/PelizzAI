#!/usr/bin/env node

import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';

const DEFINITIONS = [
  {
    event: 'PreToolUse',
    matcher: 'Bash',
    commands: [
      'node "$CLAUDE_PROJECT_DIR/.claude/hooks/pelizzai-guardrails.mjs"',
      'node "$CLAUDE_PROJECT_DIR/.claude/hooks/pelizzai-writegate.mjs"',
    ],
  },
  {
    event: 'PreToolUse',
    matcher: 'Write|Edit|MultiEdit|NotebookEdit',
    commands: ['node "$CLAUDE_PROJECT_DIR/.claude/hooks/pelizzai-writegate.mjs"'],
  },
  {
    event: 'UserPromptSubmit',
    matcher: '',
    commands: ['node "$CLAUDE_PROJECT_DIR/.claude/hooks/pelizzai-cadence.mjs"'],
  },
  {
    event: 'SessionStart',
    matcher: 'startup|resume|clear|compact',
    commands: ['node "$CLAUDE_PROJECT_DIR/.claude/hooks/pelizzai-session-start.mjs"'],
  },
];

// Installation is OPT-IN, one hook at a time and with confirmation — never imposed as a block.
// `--only` is what makes that doctrine operable on the command line: it installs/checks/removes
// only the hooks the user accepted, without touching the rest.
const HOOK_PATTERN = /pelizzai-(guardrails|writegate|cadence|session-start)\.mjs/;
const HOOK_IDS = ['guardrails', 'writegate', 'cadence', 'session-start'];

function hookId(command) {
  return HOOK_PATTERN.exec(String(command ?? ''))?.[1] ?? '';
}

function parseArgs(argv) {
  const options = { project: process.cwd(), check: false, remove: false, only: null };
  for (let index = 0; index < argv.length; index += 1) {
    switch (argv[index]) {
      case '--project':
        index += 1;
        if (!argv[index]) throw new Error('--project requires a path.');
        options.project = argv[index];
        break;
      case '--only': {
        index += 1;
        if (!argv[index]) throw new Error(`--only requires a list (${HOOK_IDS.join(',')}).`);
        const ids = argv[index]
          .split(',')
          .map((id) => id.trim())
          .filter(Boolean);
        const unknown = ids.filter((id) => !HOOK_IDS.includes(id));
        if (unknown.length) {
          throw new Error(`--only does not recognize: ${unknown.join(', ')}. Valid: ${HOOK_IDS.join(', ')}.`);
        }
        if (!ids.length) throw new Error(`--only requires at least one hook (${HOOK_IDS.join(',')}).`);
        options.only = ids;
        break;
      }
      case '--check':
        options.check = true;
        break;
      case '--remove':
        options.remove = true;
        break;
      case '--help':
      case '-h':
        console.log(
          'Usage: node scripts/install-hooks.mjs [--project <root>] [--only <list>] [--check|--remove]\n' +
            `  --only <list>   applies only to these hooks (${HOOK_IDS.join(', ')}), comma-separated.\n` +
            '                  Without --only, the operation covers all four.\n' +
            '  --check         inventory: partial installation is legitimate opt-in and does not fail.\n' +
            '                  With --only, requires the listed hooks to be registered.',
        );
        process.exit(0);
        break;
      default:
        throw new Error(`Unknown argument: ${argv[index]}`);
    }
  }
  if (options.check && options.remove) throw new Error('--check and --remove are mutually exclusive.');
  return options;
}

// DEFINITIONS trimmed by --only (a group disappears when none of its commands was requested).
function selectDefinitions(only) {
  if (!only) return DEFINITIONS;
  return DEFINITIONS.map((definition) => ({
    ...definition,
    commands: definition.commands.filter((command) => only.includes(hookId(command))),
  })).filter((definition) => definition.commands.length > 0);
}

function readSettings(path) {
  if (!existsSync(path)) return {};
  const source = readFileSync(path, 'utf8').replace(/^\uFEFF/, '');
  try {
    const parsed = JSON.parse(source);
    if (!parsed || Array.isArray(parsed) || typeof parsed !== 'object') {
      throw new Error('the root must be a JSON object');
    }
    return parsed;
  } catch (error) {
    throw new Error(`Could not read ${path}: ${error.message}. The file was not changed.`);
  }
}

// `only` restricts recognition to the requested hooks — this is what allows removing/reinstalling
// one hook without tearing down the companions the user had already accepted.
function isPelizzai(handler, only = null) {
  if (handler?.type !== 'command') return false;
  const id = hookId(handler.command);
  if (!id) return false;
  return !only || only.includes(id);
}

function removePelizzai(settings, only = null) {
  if (!settings.hooks || typeof settings.hooks !== 'object') return settings;
  for (const [event, groups] of Object.entries(settings.hooks)) {
    if (!Array.isArray(groups)) continue;
    settings.hooks[event] = groups
      .map((group) => ({ ...group, hooks: Array.isArray(group.hooks) ? group.hooks.filter((handler) => !isPelizzai(handler, only)) : group.hooks }))
      .filter((group) => !Array.isArray(group.hooks) || group.hooks.length > 0);
    if (settings.hooks[event].length === 0) delete settings.hooks[event];
  }
  if (Object.keys(settings.hooks).length === 0) delete settings.hooks;
  return settings;
}

function installPelizzai(settings, definitions, only = null) {
  removePelizzai(settings, only); // idempotency without collateral: only this operation's hooks
  settings.hooks ??= {};
  for (const definition of definitions) {
    settings.hooks[definition.event] ??= [];
    let group = settings.hooks[definition.event].find(
      (candidate) => (candidate.matcher ?? '') === definition.matcher && Array.isArray(candidate.hooks),
    );
    if (!group) {
      group = { hooks: [] };
      if (definition.matcher) group.matcher = definition.matcher;
      settings.hooks[definition.event].push(group);
    }
    for (const command of definition.commands) group.hooks.push({ type: 'command', command });
  }
  return settings;
}

function expectedCommands(definitions) {
  return definitions.flatMap((definition) => definition.commands).sort();
}

function installedCommands(settings) {
  const commands = [];
  for (const groups of Object.values(settings.hooks ?? {})) {
    if (!Array.isArray(groups)) continue;
    for (const group of groups) {
      for (const handler of group.hooks ?? []) if (isPelizzai(handler)) commands.push(handler.command);
    }
  }
  return commands.sort();
}

function writeAtomic(path, settings) {
  mkdirSync(dirname(path), { recursive: true });
  const temporary = `${path}.pelizzai-tmp-${process.pid}`;
  writeFileSync(temporary, `${JSON.stringify(settings, null, 2)}\n`, 'utf8');
  renameSync(temporary, path);
}

try {
  const options = parseArgs(process.argv.slice(2));
  const project = resolve(options.project);
  const settingsPath = join(project, '.claude', 'settings.json');
  const settings = readSettings(settingsPath);
  const definitions = selectDefinitions(options.only);
  const escopo = options.only ? ` (--only ${options.only.join(', ')})` : '';

  if (options.check) {
    // PARTIAL installation is deliberate opt-in, not a defect: the bootstrap proposes the hooks
    // one by one, with confirmation, and the user accepts the ones they want. Without --only,
    // --check is an INVENTORY, not a turnstile: absence does not fail. It only fails on (a) a
    // handler registered more times than the standard prescribes — the same hook firing twice is
    // a real defect — and (b) with --only, the absence of something the caller declared they
    // expect. A PelizzAI handler in a different form than the one this installer writes
    // (hand-written quotes/path) is noted, not failed: it is registered and works.
    // ATTENTION: the writegate appears TWICE in the standard (matcher Bash + Write|Edit|MultiEdit|
    // NotebookEdit). Duplication means a count ABOVE the standard, never "it showed up repeated".
    const actual = installedCommands(settings);
    const canonical = new Map();
    for (const command of expectedCommands(DEFINITIONS)) canonical.set(command, (canonical.get(command) ?? 0) + 1);
    const counted = new Map();
    for (const command of actual) counted.set(command, (counted.get(command) ?? 0) + 1);

    const problems = [];
    const duplicated = [...counted]
      .filter(([command, n]) => canonical.has(command) && n > canonical.get(command))
      .map(([command]) => hookId(command));
    if (duplicated.length) problems.push(`handlers registered more than once: ${[...new Set(duplicated)].join(', ')}`);
    if (options.only) {
      // Presence required command by command (multiset): the writegate only counts as registered
      // when BOTH matchers are there.
      const pool = [...actual];
      const absent = [];
      for (const command of expectedCommands(definitions)) {
        const at = pool.indexOf(command);
        if (at === -1) absent.push(hookId(command));
        else pool.splice(at, 1);
      }
      if (absent.length) problems.push(`hooks requested via --only and not registered: ${[...new Set(absent)].join(', ')}`);
    }

    if (problems.length) {
      console.error(`FAIL: ${problems.join('; ')} in ${settingsPath}.`);
      process.exitCode = 1;
    } else {
      const ids = [...new Set(actual.map(hookId))];
      const registered = options.only ? ids.filter((id) => options.only.includes(id)) : ids;
      const optIn = options.only ? [] : HOOK_IDS.filter((id) => !ids.includes(id));
      const foraDoPadrao = [...counted.keys()].filter((command) => !canonical.has(command));
      const inventario = registered.length ? registered.join(', ') : 'none';
      const pendentes = optIn.length ? ` | not registered (opt-in, not a failure): ${optIn.join(', ')}` : '';
      const anotacao = foraDoPadrao.length ? ` | not in the form written by this installer: ${foraDoPadrao.join(', ')}` : '';
      console.log(`OK: PelizzAI hooks in ${settingsPath}${escopo}: ${inventario}${pendentes}${anotacao}.`);
    }
  } else if (options.remove) {
    writeAtomic(settingsPath, removePelizzai(settings, options.only));
    console.log(`PelizzAI hooks removed from ${settingsPath}${escopo}; other settings preserved.`);
  } else {
    const missing = expectedCommands(definitions)
      .map((command) => command.match(/pelizzai-[\w-]+\.mjs/)?.[0])
      .filter((name) => name && !existsSync(join(project, '.claude', 'hooks', name)));
    if (missing.length) throw new Error(`Hooks not copied to the project: ${[...new Set(missing)].join(', ')}`);
    writeAtomic(settingsPath, installPelizzai(settings, definitions, options.only));
    console.log(`PelizzAI hooks registered in ${settingsPath}${escopo}; existing settings preserved.`);
  }
} catch (error) {
  console.error(`FAIL: ${error instanceof Error ? error.message : String(error)}`);
  process.exitCode = 1;
}
