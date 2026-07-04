#!/usr/bin/env node
/**
 * PelizzAI — hook SessionStart (matcher startup|clear|compact). OPT-IN.
 *
 * Emite um lembrete CURTO no início da sessão: carregar a pelizzai-core antes de
 * responder qualquer coisa (regra do 1%) e, se pelizzai/data/state.md tiver tarefa
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
    'PelizzAI: antes de responder QUALQUER coisa, carregue a skill pelizzai-core e honre a regra do 1% — se uma skill se aplica (mesmo a um ajuste trivial), acione-a.',
    'Toda tarefa que toca o projeto passa por pelizzai-core → pelizzai-router.',
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
