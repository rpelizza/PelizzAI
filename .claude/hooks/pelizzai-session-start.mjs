#!/usr/bin/env node
/**
 * PelizzAI — hook SessionStart (matcher startup|clear|compact). OPT-IN.
 *
 * Emite um lembrete CURTO no início da sessão: carregar core/router para tarefas de
 * projeto, classificar o efeito antes de agir e, se pelizzai/data/state.md tiver tarefa
 * ativa (slug != <none> e phase != done), avisar que há retomada via pelizzai-router.
 *
 * Nota de valor: no Claude Code o CLAUDE.md já é re-injetado no startup e após o
 * compact — o ganho real deste hook está no `clear` (que zera tudo) e em plataformas
 * que NÃO re-injetam a entrada sempre-carregada.
 *
 * Garantias: SEMPRE termina com exit 0; engole qualquer erro; nunca bloqueia a sessão.
 *
 * Instalação (opt-in), em .claude/settings.json do projeto consumidor:
 *   { "hooks": { "SessionStart": [ { "matcher": "startup|clear|compact", "hooks": [
 *       { "type": "command",
 *         "command": "node \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-session-start.mjs\"" } ] } ] } }
 *
 * Em frota sem Node, use a variante PowerShell pelizzai-session-start.ps1 (mesmo matcher).
 */

import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

function readStdin() {
  try {
    return readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function main() {
  let cwd = process.cwd();
  try {
    const data = JSON.parse(readStdin() || '{}');
    if (data && typeof data.cwd === 'string' && data.cwd) cwd = data.cwd;
  } catch {
    /* usa process.cwd() */
  }

  const lines = [
    'PelizzAI: em tarefas de projeto, carregue pelizzai-core → pelizzai-router e classifique effect, risco, incerteza e superfícies antes de agir.',
    'Escolha uma head skill e overlays proporcionais; read-only não inicializa estado, e qualquer escrita passa primeiro pelo gate de isolamento.',
  ];

  try {
    const statePath = join(cwd, 'pelizzai', 'data', 'state.md');
    if (existsSync(statePath)) {
      const state = readFileSync(statePath, 'utf8');
      const slug = (state.match(/^\s*-\s*slug:\s*(.+?)\s*$/m) || [])[1];
      const phase = (state.match(/^\s*-\s*phase:\s*(\S+)/m) || [])[1];
      const active =
        slug && slug !== '<none>' && !slug.startsWith('<') &&
        phase && phase !== 'done' && !phase.startsWith('<');
      if (active) {
        lines.push(
          `Há tarefa ATIVA em pelizzai/data/state.md (slug: ${slug}, phase: ${phase}) — ` +
            'retome via pelizzai-router, validando o cursor contra o git antes de prosseguir.'
        );
      }
    }
  } catch {
    /* sem aviso de retomada — segue com o lembrete básico */
  }

  // Consumidor sem catálogo de skills de domínio: sugere UMA vez o caminho de bootstrap
  // read-only (propor→confirmar; nada é criado sem consentimento). Em source mode (repo-fonte)
  // é no-op — ali não há catálogo consumidor. Criar pelizzai/domain-skills.md (mesmo
  // `_nenhuma por enquanto_`) silencia o nudge sem exigir skills de domínio.
  try {
    // Sentinela dedicada: só o repo-fonte a tem (consumidores têm manifesto/sync e NÃO são fonte).
    const sourceMode = existsSync(join(cwd, 'scripts', 'pelizzai-source-repo.txt'));
    if (!sourceMode && !existsSync(join(cwd, 'pelizzai', 'domain-skills.md'))) {
      lines.push(
        'Projeto sem catálogo de skills de domínio (pelizzai/domain-skills.md ausente). Se for ' +
          'trabalhar no código, considere pelizzai-audit em scan-only → propor bootstrap-write. ' +
          'Nada é criado sem sua confirmação.'
      );
    }
  } catch {
    /* sem nudge de bootstrap — segue */
  }

  // Recap da política de execução já ratificada (anti-fadiga): quando o profile registra os
  // Defaults de execução ratificados, o router reaplica como recap de 1 linha em vez de
  // re-perguntar. destination NUNCA é default: push/PR/publicação seguem por tarefa.
  try {
    const profilePath = join(cwd, 'pelizzai', 'profile.md');
    if (existsSync(profilePath)) {
      const profile = readFileSync(profilePath, 'utf8');
      const iso = (profile.match(/isolation-default:\s*(\S+)/) || [])[1];
      const mode = (profile.match(/execution-mode-default:\s*(\S+)/) || [])[1];
      const commit = (profile.match(/commit-strategy-default:\s*(\S+)/) || [])[1];
      const ratified = [];
      if (iso && iso !== 'unset') ratified.push(`isolamento ${iso}`);
      if (mode && mode !== 'unset') ratified.push(`modo ${mode}`);
      if (commit && commit !== 'unset') ratified.push(`commit ${commit}`);
      if (ratified.length) {
        lines.push(
          `Política de execução ratificada do projeto (pelizzai/profile.md): ${ratified.join(', ')} — ` +
            'reaplique como recap de 1 linha; não re-pergunte o que já foi ratificado (destino continua por tarefa).'
        );
      }
    }
  } catch {
    /* sem recap de política — segue */
  }

  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext: lines.join('\n'),
      },
    })
  );
}

try {
  main();
} catch {
  /* nunca falhe o início da sessão */
}
process.exit(0);
