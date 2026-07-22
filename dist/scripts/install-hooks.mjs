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

// Instalação é OPT-IN, um hook por vez e com confirmação — nunca imposta em bloco. `--only`
// é o que torna essa doutrina operável na linha de comando: instala/checa/remove só os hooks
// que o usuário aceitou, sem tocar nos demais.
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
        if (!argv[index]) throw new Error('--project exige um caminho.');
        options.project = argv[index];
        break;
      case '--only': {
        index += 1;
        if (!argv[index]) throw new Error(`--only exige uma lista (${HOOK_IDS.join(',')}).`);
        const ids = argv[index]
          .split(',')
          .map((id) => id.trim())
          .filter(Boolean);
        const unknown = ids.filter((id) => !HOOK_IDS.includes(id));
        if (unknown.length) {
          throw new Error(`--only não conhece: ${unknown.join(', ')}. Válidos: ${HOOK_IDS.join(', ')}.`);
        }
        if (!ids.length) throw new Error(`--only exige ao menos um hook (${HOOK_IDS.join(',')}).`);
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
          'Uso: node scripts/install-hooks.mjs [--project <raiz>] [--only <lista>] [--check|--remove]\n' +
            `  --only <lista>  aplica só a estes hooks (${HOOK_IDS.join(', ')}), separados por vírgula.\n` +
            '                  Sem --only, a operação cobre os quatro.\n' +
            '  --check         inventário: instalação parcial é opt-in legítimo e não falha.\n' +
            '                  Com --only, exige que os hooks listados estejam registrados.',
        );
        process.exit(0);
        break;
      default:
        throw new Error(`Argumento desconhecido: ${argv[index]}`);
    }
  }
  if (options.check && options.remove) throw new Error('--check e --remove são exclusivos.');
  return options;
}

// DEFINITIONS recortadas pelo --only (um grupo some quando nenhum comando dele foi pedido).
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
      throw new Error('a raiz precisa ser um objeto JSON');
    }
    return parsed;
  } catch (error) {
    throw new Error(`Não foi possível ler ${path}: ${error.message}. O arquivo não foi alterado.`);
  }
}

// `only` restringe o reconhecimento aos hooks pedidos — é o que permite remover/reinstalar um
// hook sem derrubar os companheiros que o usuário já havia aceitado.
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
  removePelizzai(settings, only); // idempotência sem colateral: só os hooks desta operação
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
    // Instalação PARCIAL é opt-in deliberado, não defeito: o bootstrap propõe os hooks um a um,
    // com confirmação, e o usuário aceita os que quiser. Sem --only o --check é INVENTÁRIO, não
    // catraca: ausência não reprova. Ele só reprova (a) handler registrado mais vezes do que o
    // padrão prevê — o mesmo hook disparando duas vezes é defeito real — e (b) com --only, a
    // ausência de algo que o chamador declarou esperar. Um handler PelizzAI em forma diferente
    // da que este instalador escreve (aspas/caminho à mão) é anotado, não reprovado: está
    // registrado e funciona.
    // ATENÇÃO: o writegate aparece DUAS vezes no padrão (matcher Bash + Write|Edit|MultiEdit|
    // NotebookEdit). Duplicidade é contagem ACIMA do padrão, nunca "apareceu repetido".
    const actual = installedCommands(settings);
    const canonical = new Map();
    for (const command of expectedCommands(DEFINITIONS)) canonical.set(command, (canonical.get(command) ?? 0) + 1);
    const counted = new Map();
    for (const command of actual) counted.set(command, (counted.get(command) ?? 0) + 1);

    const problems = [];
    const duplicated = [...counted]
      .filter(([command, n]) => canonical.has(command) && n > canonical.get(command))
      .map(([command]) => hookId(command));
    if (duplicated.length) problems.push(`handlers registrados mais de uma vez: ${[...new Set(duplicated)].join(', ')}`);
    if (options.only) {
      // Presença exigida comando a comando (multiset): writegate só conta como registrado
      // quando os DOIS matchers estão lá.
      const pool = [...actual];
      const absent = [];
      for (const command of expectedCommands(definitions)) {
        const at = pool.indexOf(command);
        if (at === -1) absent.push(hookId(command));
        else pool.splice(at, 1);
      }
      if (absent.length) problems.push(`hooks pedidos em --only e não registrados: ${[...new Set(absent)].join(', ')}`);
    }

    if (problems.length) {
      console.error(`FAIL: ${problems.join('; ')} em ${settingsPath}.`);
      process.exitCode = 1;
    } else {
      const ids = [...new Set(actual.map(hookId))];
      const registered = options.only ? ids.filter((id) => options.only.includes(id)) : ids;
      const optIn = options.only ? [] : HOOK_IDS.filter((id) => !ids.includes(id));
      const foraDoPadrao = [...counted.keys()].filter((command) => !canonical.has(command));
      const inventario = registered.length ? registered.join(', ') : 'nenhum';
      const pendentes = optIn.length ? ` | não registrados (opt-in, não é falha): ${optIn.join(', ')}` : '';
      const anotacao = foraDoPadrao.length ? ` | fora da forma escrita por este instalador: ${foraDoPadrao.join(', ')}` : '';
      console.log(`OK: hooks PelizzAI em ${settingsPath}${escopo}: ${inventario}${pendentes}${anotacao}.`);
    }
  } else if (options.remove) {
    writeAtomic(settingsPath, removePelizzai(settings, options.only));
    console.log(`Hooks PelizzAI removidos de ${settingsPath}${escopo}; demais configurações preservadas.`);
  } else {
    const missing = expectedCommands(definitions)
      .map((command) => command.match(/pelizzai-[\w-]+\.mjs/)?.[0])
      .filter((name) => name && !existsSync(join(project, '.claude', 'hooks', name)));
    if (missing.length) throw new Error(`Hooks não copiados para o projeto: ${[...new Set(missing)].join(', ')}`);
    writeAtomic(settingsPath, installPelizzai(settings, definitions, options.only));
    console.log(`Hooks PelizzAI registrados em ${settingsPath}${escopo}; configurações existentes preservadas.`);
  }
} catch (error) {
  console.error(`FAIL: ${error instanceof Error ? error.message : String(error)}`);
  process.exitCode = 1;
}
