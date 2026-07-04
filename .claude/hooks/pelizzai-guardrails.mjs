#!/usr/bin/env node
/**
 * PelizzAI — hook de guarda git (PreToolUse, tool Bash). OPT-IN.
 *
 * Bloqueia, ANTES de rodarem, comandos git destrutivos que os gates do harness já
 * proíbem em prosa — aqui a proibição vira enforcement executável (o único ponto do
 * harness onde a obediência do modelo deixa de ser single point of failure):
 *  - git push --force / -f          (exceto --force-with-lease)
 *  - git reset --hard
 *  - git clean -f / -fd / --force
 *  - git branch -D
 *  - git checkout . / checkout -- .
 *  - git restore .                  (sem --staged — perda da working tree)
 *
 * Bloqueio: exit 2 + motivo e caminho seguro no stderr (o agente lê e corrige a rota).
 * Qualquer outro comando: exit 0 silencioso. Erros do PRÓPRIO hook: exit 0 (fail-open —
 * o hook é rede de segurança, não gate primário; um bug aqui nunca trava o usuário).
 *
 * Instalação (opt-in, recomendada pela pelizzai-audit no bootstrap), em
 * .claude/settings.json do projeto consumidor:
 *   { "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [
 *       { "type": "command",
 *         "command": "node \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-guardrails.mjs\"" } ] } ] } }
 *
 * Teste manual:
 *   echo '{"tool_input":{"command":"git reset --hard"}}' | node pelizzai-guardrails.mjs; echo $?
 *   → motivo no stderr e exit code 2. Comando inofensivo (ex.: "git status") → exit 0.
 *
 * Falso positivo conhecido (fail-closed, aceitável para rede de segurança): texto CITADO
 * que contenha um padrão perigoso — ex.: git commit -m "docs: explica git reset --hard" —
 * é bloqueado. Saída: reformule a mensagem ou rode o commit manualmente.
 *
 * Em frota sem Node, use a variante PowerShell pelizzai-guardrails.ps1 (mesmo matcher).
 */

import { readFileSync } from 'node:fs';

const RULES = [
  {
    name: 'git push --force / -f',
    // --force-with-lease NÃO casa com "--force(\s|$)" — a exceção é automática.
    // Flags curtas podem vir agrupadas (git push -uf origin main) — casar o f dentro do bundle.
    test: (s) =>
      /\bgit\b.*\bpush\b/.test(s) &&
      (/(^|\s)--force(\s|$)/.test(s) || /(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(s)),
    why: 'push forçado reescreve o histórico remoto e pode apagar commits de outras pessoas.',
    safe: 'use --force-with-lease (só sobrescreve se o remoto estiver onde você espera) — e somente com pedido explícito do usuário.',
  },
  {
    name: 'git reset --hard',
    test: (s) => /\bgit\b.*\breset\b/.test(s) && /(^|\s)--hard\b/.test(s),
    why: 'descarta commits e mudanças da working tree sem volta.',
    safe: 'crie um ponto de retorno primeiro (stash nomeado ou commit WIP) e siga o procedimento da skill pelizzai-recovery.',
  },
  {
    name: 'git clean -f',
    test: (s) =>
      /\bgit\b.*\bclean\b/.test(s) &&
      (/(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(s) || /(^|\s)--force\b/.test(s)),
    why: 'apaga arquivos não rastreados de forma irreversível (não há stash nem reflog para eles).',
    safe: 'liste antes com git clean -n e confirme com o usuário o que será apagado.',
  },
  {
    name: 'git branch -D',
    // -D case-sensitive (-d é seguro); pode vir agrupada (git branch -qD nome).
    test: (s) => /\bgit\b.*\bbranch\b/.test(s) && /(^|\s)-[a-zA-Z]*D[a-zA-Z]*(\s|$)/.test(s),
    why: 'força a remoção de uma branch NÃO mesclada — os commits dela podem se perder.',
    safe: 'use -d (só remove branch já mesclada) ou confirme o descarte com o usuário (a pelizzai-finish-task exige o texto "descartar").',
  },
  {
    name: 'git checkout . / checkout [<ref>] -- .',
    // Cobre "checkout .", "checkout -- .", "checkout <ref> -- ." e a forma "./" (todas descartam a working tree).
    test: (s) =>
      /\bgit\b.*\bcheckout\b(\s+--)?\s+\.\/?(\s|$)/.test(s) ||
      /\bgit\b.*\bcheckout\b\s+\S+\s+--\s+\.\/?(\s|$)/.test(s),
    why: 'sobrescreve TODAS as mudanças não commitadas da working tree.',
    safe: 'crie um ponto de retorno primeiro (git stash push -u -m "<motivo>") ou restaure só arquivos específicos.',
  },
  {
    name: 'git restore . (working tree)',
    // Sem --staged/-S (ou com --worktree/-W explícito), restore descarta a working tree. "./" == ".".
    test: (s) =>
      /\bgit\b.*\brestore\b/.test(s) &&
      /(^|\s)\.\/?(\s|$)/.test(s) &&
      (!(/--staged\b/.test(s) || /(^|\s)-S(\s|$)/.test(s)) ||
        /--worktree\b/.test(s) ||
        /(^|\s)-W(\s|$)/.test(s)),
    why: 'sem --staged, restore descarta as mudanças da working tree sem volta.',
    safe: 'git restore --staged . apenas tira do stage (seguro); para descartar de verdade, crie um ponto de retorno (stash) e confirme com o usuário.',
  },
];

function readStdin() {
  try {
    return readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function main() {
  const input = readStdin();
  if (!input) return 0;
  let data;
  try {
    data = JSON.parse(input);
  } catch {
    return 0;
  }
  const command = data?.tool_input?.command;
  if (typeof command !== 'string' || !/\bgit\b/.test(command)) return 0;

  // Analisa por segmento de shell (&&, ||, ;, |, quebras de linha) para não atribuir
  // flags de um comando (ex.: rm -f) ao git de outro segmento.
  const segments = command.split(/&&|\|\||;|\||\r?\n/);
  for (const seg of segments) {
    for (const rule of RULES) {
      if (rule.test(seg)) {
        process.stderr.write(
          `PelizzAI guardrails: comando bloqueado — ${rule.name}.\n` +
            `Por quê: ${rule.why}\n` +
            `Caminho seguro: ${rule.safe}\n` +
            `(Hook opt-in de guarda git. Se o usuário pediu EXPLICITAMENTE esta operação, ` +
            `peça a ele que a rode manualmente ou que desabilite o hook em .claude/settings.json.)\n`
        );
        return 2;
      }
    }
  }
  return 0;
}

let exitCode = 0;
try {
  exitCode = main();
} catch {
  exitCode = 0; // fail-open: erro do hook nunca trava o usuário
}
process.exit(exitCode);
