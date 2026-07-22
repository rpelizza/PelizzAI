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
import { dirname, join, relative, resolve } from 'node:path';
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

const REF_IGNORE = new Set([
  'pelizzai-cadence',
  'pelizzai-core-skills',
  'pelizzai-guardrails',
  'pelizzai-session-start',
  'pelizzai-writegate',
  'pelizzai-source-repo',
]);

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
        if (!argv[index]) throw new Error(`${arg} exige um caminho.`);
        options.exportConsumer = argv[index];
        break;
      case '--install-hooks':
      case '-installhooks':
        options.installHooks = true;
        break;
      case '--help':
      case '-h':
      case '-help':
        console.log(`Uso:
  node scripts/sync-harness.mjs [--check] [--source-mode]
  node scripts/sync-harness.mjs --update-manifest
  node scripts/sync-harness.mjs --export-consumer <destino> [--install-hooks]

Wrappers equivalentes: scripts/sync-harness.ps1 e scripts/sync-harness.sh.`);
        process.exit(0);
        break;
      default:
        throw new Error(`Argumento desconhecido: ${arg}`);
    }
  }

  if (options.sourceMode && !options.check) {
    throw new Error('--source-mode só é válido com --check.');
  }
  if (options.exportConsumer && (options.check || options.updateManifest || options.sourceMode)) {
    throw new Error('--export-consumer não combina com --check/--update-manifest/--source-mode.');
  }
  if (options.installHooks && !options.exportConsumer) {
    throw new Error('--install-hooks só é válido com --export-consumer.');
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
  const skills = listSkillNames();
  const header = `<!-- GERADO por scripts/sync-harness.mjs a partir de CLAUDE.md — NÃO edite à mão. -->
<!-- Para mudar as diretrizes, edite CLAUDE.md e rode o sync-harness da sua plataforma. -->

`;
  const body = readText(claudeMd).trimEnd();
  const harness = `

---

## Harness de skills (PelizzAI)

Este projeto usa o harness de skills **PelizzAI**. As skills vivem em \`.agents/skills/<nome>/SKILL.md\`, espelho de \`.claude/skills/\`. Leia e siga a skill relevante antes de agir.

**Entrada:** comece por \`pelizzai-core\` e \`pelizzai-router\`. O router classifica efeito, risco, incerteza e superfícies; escolhe uma head skill e overlays. Operações somente leitura não inicializam estado. Antes da primeira escrita, confirme isolamento e branch. No repo-fonte use plano/execution record nativo; no consumidor, state/specs/planos seguem o lifecycle.

**Proteção de branch:** nunca commite em \`main\`/\`master\`/\`develop\`/\`dev\` nem em HEAD destacado. Isole via \`pelizzai-starting-branch\`.

**Autoridade do usuário:** o harness classifica, raciocina, pesquisa com Context7/documentação oficial e recomenda; o usuário decide requisitos, escopo, UX, arquitetura, dados, risco aceito e critérios de aceite. Faça uma pergunta por vez, com a melhor opção recomendada. Greenfield passa por descoberta, spec e plano estressados e ratificados.

**Context7:** trate-o como fonte técnica preferencial quando bibliotecas, frameworks, APIs, versões ou capacidades externas influenciarem a tarefa. Inspecione manifests/lockfiles primeiro, consulte a documentação da versão relevante e use a evidência para melhorar perguntas e recomendações; nunca a transforme em voto do usuário.

**Gate de ratificação:** isolamento, modo de execução (com \`team\` sempre visível) e estratégia de commit são recomendações ratificadas antes de serem aplicadas; \`squash-final\` só a pedido explícito. Push/PR/publicação são confirmados por tarefa.

Skills disponíveis (${skills.length}): ${skills.join(', ')}.
`;
  return `${header}${body}${harness.trimEnd()}\n`;
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
  return `# skills core do PelizzAI — GERADO por scripts/sync-harness.mjs --update-manifest.
# Regenere apenas no repo-fonte. Consumidores usam este manifesto para separar core de domínio.
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
  markdown.push(claudeMd);
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
  if (result.status !== 0) throw new Error(`${script} falhou com exit ${result.status}.`);
}

function exportConsumer(destination, installHooks) {
  if (!existsSync(sourceSentinel)) {
    throw new Error('--export-consumer só roda no repo-fonte (sentinela ausente).');
  }
  if (!existsSync(destination) || !statSync(destination).isDirectory()) {
    throw new Error(`Destino não existe ou não é diretório: ${destination}`);
  }
  const target = resolve(destination);
  if (target === root) throw new Error('Destino não pode ser o próprio repo-fonte.');

  const core = readCoreManifest();
  if (!core?.length) throw new Error('Manifesto de core ausente; rode --update-manifest.');

  const targetSkills = join(target, '.claude', 'skills');
  mkdirSync(targetSkills, { recursive: true });
  for (const name of core) {
    const source = join(srcSkills, name);
    if (!existsSync(source)) throw new Error(`Skill core ausente na fonte: ${name}`);
    copyExact(source, join(targetSkills, name));
  }

  const orphans = listSkillNames(targetSkills).filter(
    (name) => name.startsWith('pelizzai-') && !core.includes(name),
  );
  if (orphans.length) console.warn(`AVISO: pelizzai-* fora do core no destino: ${orphans.join(', ')}`);

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

  const cursorAdapter = join(root, '.cursor', 'rules', 'pelizzai.mdc');
  if (!existsSync(cursorAdapter)) {
    throw new Error('Adaptador Cursor ausente na fonte: .cursor/rules/pelizzai.mdc');
  }
  const targetCursorRules = join(target, '.cursor', 'rules');
  mkdirSync(targetCursorRules, { recursive: true });
  cpSync(cursorAdapter, join(targetCursorRules, 'pelizzai.mdc'));

  const marker = '## Diretrizes comportamentais';
  const sourceClaude = readText(claudeMd);
  const markerIndex = sourceClaude.indexOf(marker);
  if (markerIndex < 0) throw new Error(`CLAUDE.md sem a seção '${marker}'.`);
  const bridge = `# CLAUDE.md

## Harness PelizzAI (entrada obrigatória)

Este repositório consome o PelizzAI. Para pedidos de projeto, entre por \`pelizzai-core\` → \`pelizzai-router\`. O router escolhe uma head skill, técnicas de reasoning e overlays; Context7/documentação oficial fundamenta a leitura técnica; toda decisão material volta ao usuário.

Este é um consumidor: não há \`scripts/pelizzai-source-repo.txt\`. O manifesto separa core de skills de domínio; atualizações do harness nunca sobrescrevem as skills específicas do projeto.

`;
  writeTextAtomic(join(target, 'CLAUDE.md'), `${bridge}${sourceClaude.slice(markerIndex)}`);

  const targetSync = join(targetScripts, 'sync-harness.mjs');
  runNode(targetSync, [], target);
  runNode(targetSync, ['--check'], target);

  if (installHooks) {
    runNode(join(targetScripts, 'install-hooks.mjs'), ['--project', target], target);
  }

  console.log(
    `Export consumidor concluído: ${target} (${core.length} skills core; adaptador Cursor; domínio e ` +
      `pelizzai/ preservados; hooks ${installHooks ? 'registrados' : 'copiados, registro pendente de decisão do usuário'}).`,
  );
}

function check(sourceMode) {
  let problems = 0;
  const difference = treeDiffCount(srcSkills, dstSkills);
  if (difference) {
    console.error(`FAIL: .agents/skills fora de sincronia (${difference} arquivo(s)).`);
    problems += 1;
  }
  const expected = buildAgentsMd();
  if (!existsSync(agentsMd) || readText(agentsMd) !== expected) {
    console.error('FAIL: AGENTS.md fora de sincronia com CLAUDE.md.');
    problems += 1;
  }
  if (!existsSync(geminiMd) || readText(geminiMd) !== expected) {
    console.error('FAIL: GEMINI.md fora de sincronia com CLAUDE.md.');
    problems += 1;
  }
  const broken = testRefs();
  if (broken.length) {
    console.error(`FAIL: referências pelizzai-* quebradas: ${broken.join(', ')}`);
    problems += 1;
  }

  const core = readCoreManifest();
  if (!core) {
    console.error('FAIL: manifesto ausente. Rode --update-manifest no repo-fonte.');
    problems += 1;
  } else {
    const directories = listSkillNames();
    const dangling = core.filter((name) => !directories.includes(name));
    const domain = directories.filter((name) => !core.includes(name));
    const duplicates = core.filter((name, index) => core.indexOf(name) !== index);
    if (dangling.length) {
      console.error(`FAIL: manifesto lista skills inexistentes: ${dangling.join(', ')}`);
      problems += 1;
    }
    if (duplicates.length) {
      console.error(`FAIL: manifesto contém duplicatas: ${[...new Set(duplicates)].join(', ')}`);
      problems += 1;
    }
    if (sourceMode && domain.length) {
      console.error(`FAIL: repo-fonte tem skills fora do manifesto: ${domain.join(', ')}`);
      problems += 1;
    } else if (domain.length) {
      console.log(`INFO: ${domain.length} skill(s) de domínio: ${domain.join(', ')}`);
    }
  }

  if (problems) return 1;
  console.log(
    `OK: harness em sincronia (.agents, AGENTS.md, GEMINI.md, refs, manifesto; modo ${sourceMode ? 'repo-fonte' : 'consumidor'}).`,
  );
  return 0;
}

function generate(updateManifest) {
  copyExact(srcSkills, dstSkills);
  const agents = buildAgentsMd();
  writeTextAtomic(agentsMd, agents);
  writeTextAtomic(geminiMd, agents);
  if (updateManifest) {
    if (!existsSync(sourceSentinel)) throw new Error('--update-manifest só roda no repo-fonte.');
    writeTextAtomic(coreManifest, buildCoreManifest());
    console.log(`Manifesto atualizado (${readCoreManifest().length} skills core).`);
  } else if (!existsSync(coreManifest)) {
    console.warn('NOTA: manifesto ausente; rode --update-manifest no repo-fonte.');
  }
  const difference = treeDiffCount(srcSkills, dstSkills);
  const broken = testRefs();
  console.log(`.agents/skills espelhado (divergências: ${difference}).`);
  console.log(`AGENTS.md e GEMINI.md gerados (${listSkillNames().length} skills).`);
  console.log(`referências pelizzai-* quebradas: ${broken.length}`);
  if (difference || broken.length) return 1;
  console.log('Sync concluído com sucesso.');
  return 0;
}

try {
  const options = parseArgs(process.argv.slice(2));
  if (options.exportConsumer) {
    exportConsumer(options.exportConsumer, options.installHooks);
  } else if (options.check) {
    process.exitCode = check(options.sourceMode);
  } else {
    process.exitCode = generate(options.updateManifest);
  }
} catch (error) {
  fail(error instanceof Error ? error.message : String(error));
}
