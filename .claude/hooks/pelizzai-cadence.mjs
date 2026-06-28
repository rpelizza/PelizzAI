#!/usr/bin/env node
/**
 * PelizzAI — hook de cadência (UserPromptSubmit).
 *
 * Reforço da auto-manutenção de skills de domínio. NÃO é a fonte de verdade:
 * o núcleo da cadência vive na skill `pelizzai-writing-skills` (portável entre IDEs).
 * Este hook só existe no Claude Code e serve para contar interações e, a cada N,
 * lembrar de revisar as skills quando o limiar de commits/dias for cruzado.
 *
 * Garantias de segurança:
 *  - No-op silencioso se o harness ainda não foi inicializado (sem ledger).
 *  - A checagem cara (git) só roda a cada N interações; nas demais, só incrementa o contador.
 *  - SEMPRE termina com exit 0 — nunca bloqueia o prompt do usuário.
 *  - Engole qualquer erro (git ausente, FS, etc.) sem ruído.
 *  - No máximo um lembrete por janela de N interações.
 *
 * Instalação (opt-in, normalmente no bootstrap), em .claude/settings.json:
 *   { "hooks": { "UserPromptSubmit": [ { "hooks": [
 *       { "type": "command",
 *         "command": "node \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-cadence.mjs\"" } ] } ] } }
 *
 * Em frota sem Node, use a variante PowerShell pelizzai-cadence.ps1 (mesmo diretório).
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { execFileSync } from 'node:child_process';

const EVERY = 10;            // checa a cada N interações
const COMMIT_THRESHOLD = 10; // >= N commits desde a última revisão
const DAY_THRESHOLD = 10;    // > N dias desde a última revisão / último full-scan

function readStdin() {
  try {
    return readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function safeGit(cwd, args) {
  try {
    return execFileSync('git', args, {
      cwd,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
      timeout: 4000,
    }).trim();
  } catch {
    return '';
  }
}

function daysBetween(iso, now) {
  const then = Date.parse(iso + 'T00:00:00');
  if (Number.isNaN(then)) return 0;
  return Math.floor((now - then) / 86400000);
}

function emit(context) {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'UserPromptSubmit',
        additionalContext: context,
      },
    })
  );
}

function main() {
  let cwd = process.cwd();
  try {
    const input = readStdin();
    if (input) {
      const data = JSON.parse(input);
      if (data && typeof data.cwd === 'string' && data.cwd) cwd = data.cwd;
    }
  } catch {
    /* usa process.cwd() */
  }

  const ledgerPath = join(cwd, 'pelizzai', 'data', 'review-domain-skills.md');
  if (!existsSync(ledgerPath)) return; // harness não inicializado neste projeto

  // contador de interações
  const statePath = join(cwd, 'pelizzai', 'data', '.cadence-state.json');
  let state = { count: 0 };
  try {
    if (existsSync(statePath)) state = JSON.parse(readFileSync(statePath, 'utf8'));
  } catch {
    /* reinicia o estado */
  }
  state.count = (state.count || 0) + 1;
  try {
    mkdirSync(dirname(statePath), { recursive: true });
    writeFileSync(statePath, JSON.stringify(state));
  } catch {
    /* sem persistência — segue */
  }

  if (state.count % EVERY !== 0) return; // só checa (e nudga) a cada N interações

  // datas do ledger (primeiras YYYY-MM-DD encontradas após cada rótulo)
  let ledger = '';
  try {
    ledger = readFileSync(ledgerPath, 'utf8');
  } catch {
    return;
  }
  const lastReview = (ledger.match(/last-review:\D*(\d{4}-\d{2}-\d{2})/) || [])[1];
  const lastScan = (ledger.match(/last-full-scan:\D*(\d{4}-\d{2}-\d{2})/) || [])[1];
  if (!lastReview) return;

  const now = Date.now();
  const commits = parseInt(
    safeGit(cwd, ['rev-list', '--count', `--since=${lastReview} 00:00`, 'HEAD']) || '0',
    10
  );
  const daysReview = daysBetween(lastReview, now);
  const daysScan = lastScan ? daysBetween(lastScan, now) : 0;

  const reviewDue = commits >= COMMIT_THRESHOLD || daysReview > DAY_THRESHOLD;
  const scanDue = lastScan && daysScan > DAY_THRESHOLD;
  if (!reviewDue && !scanDue) return;

  const parts = [];
  if (reviewDue)
    parts.push(
      `${commits} commit(s) e ${daysReview} dia(s) desde a última revisão de skills de domínio`
    );
  if (scanDue) parts.push(`${daysScan} dia(s) desde o último repo-scan completo`);

  emit(
    `PelizzAI (cadência): ${parts.join('; ')}. ` +
      `Considere acionar a skill pelizzai-writing-skills (modo manutenção) para revisar/atualizar ` +
      `as skills de domínio. Sugira ao usuário uma vez; não bloqueie o trabalho.`
  );
}

try {
  main();
} catch {
  /* nunca falhe o prompt do usuário */
}
process.exit(0);
