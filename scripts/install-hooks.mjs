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

function parseArgs(argv) {
  const options = { project: process.cwd(), check: false, remove: false };
  for (let index = 0; index < argv.length; index += 1) {
    switch (argv[index]) {
      case '--project':
        index += 1;
        if (!argv[index]) throw new Error('--project exige um caminho.');
        options.project = argv[index];
        break;
      case '--check':
        options.check = true;
        break;
      case '--remove':
        options.remove = true;
        break;
      case '--help':
      case '-h':
        console.log('Uso: node scripts/install-hooks.mjs [--project <raiz>] [--check|--remove]');
        process.exit(0);
        break;
      default:
        throw new Error(`Argumento desconhecido: ${argv[index]}`);
    }
  }
  if (options.check && options.remove) throw new Error('--check e --remove são exclusivos.');
  return options;
}

function readSettings(path) {
  if (!existsSync(path)) return {};
  const source = readFileSync(path, 'utf8').replace(/^\uFEFF/, '');
  try {
    const parsed = JSON.parse(source);
    if (!parsed || Array.isArray(parsed) || typeof parsed !== 'object') {
      throw new Error('a raiz precisa ser um objeto JSON');
    }
    return parsed;
  } catch (error) {
    throw new Error(`Não foi possível ler ${path}: ${error.message}. O arquivo não foi alterado.`);
  }
}

function isPelizzai(handler) {
  return handler?.type === 'command' && /pelizzai-(?:guardrails|writegate|cadence|session-start)\.mjs/.test(handler.command ?? '');
}

function removePelizzai(settings) {
  if (!settings.hooks || typeof settings.hooks !== 'object') return settings;
  for (const [event, groups] of Object.entries(settings.hooks)) {
    if (!Array.isArray(groups)) continue;
    settings.hooks[event] = groups
      .map((group) => ({ ...group, hooks: Array.isArray(group.hooks) ? group.hooks.filter((handler) => !isPelizzai(handler)) : group.hooks }))
      .filter((group) => !Array.isArray(group.hooks) || group.hooks.length > 0);
    if (settings.hooks[event].length === 0) delete settings.hooks[event];
  }
  if (Object.keys(settings.hooks).length === 0) delete settings.hooks;
  return settings;
}

function installPelizzai(settings) {
  removePelizzai(settings);
  settings.hooks ??= {};
  for (const definition of DEFINITIONS) {
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

function expectedCommands() {
  return DEFINITIONS.flatMap((definition) => definition.commands).sort();
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

  if (options.check) {
    const expected = expectedCommands();
    const actual = installedCommands(settings);
    if (JSON.stringify(actual) !== JSON.stringify(expected)) {
      console.error(`FAIL: hooks PelizzAI não estão registrados integralmente em ${settingsPath}.`);
      process.exitCode = 1;
    } else {
      console.log(`OK: hooks PelizzAI registrados em ${settingsPath}.`);
    }
  } else if (options.remove) {
    writeAtomic(settingsPath, removePelizzai(settings));
    console.log(`Hooks PelizzAI removidos de ${settingsPath}; demais configurações preservadas.`);
  } else {
    const missing = DEFINITIONS.flatMap((definition) => definition.commands)
      .map((command) => command.match(/pelizzai-[\w-]+\.mjs/)?.[0])
      .filter((name) => name && !existsSync(join(project, '.claude', 'hooks', name)));
    if (missing.length) throw new Error(`Hooks não copiados para o projeto: ${[...new Set(missing)].join(', ')}`);
    writeAtomic(settingsPath, installPelizzai(settings));
    console.log(`Hooks PelizzAI registrados em ${settingsPath}; configurações existentes preservadas.`);
  }
} catch (error) {
  console.error(`FAIL: ${error instanceof Error ? error.message : String(error)}`);
  process.exitCode = 1;
}
