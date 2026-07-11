#!/usr/bin/env node
/**
 * PelizzAI — hook de guarda git (PreToolUse, tool Bash). OPT-IN.
 *
 * Bloqueia, ANTES de rodarem, comandos git destrutivos que os gates do harness já
 * proíbem em prosa — aqui a proibição vira enforcement executável (o único ponto do
 * harness onde a obediência do modelo deixa de ser single point of failure):
 *  - git push forçado ou destrutivo (--force/-f/+refspec/--delete/--mirror/:ref)
 *  - git reset --hard
 *  - git clean -f / -fd / --force
 *  - git branch -D/-M/-f/--force
 *  - git checkout de paths ou checkout -f/-B; switch -C/--force-create
 *  - git restore de working tree (restore apenas --staged continua permitido)
 *  - git worktree remove --force
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
    name: 'git push forçado/destrutivo',
    // --force-with-lease NÃO casa com "--force(\s|$)" — a exceção é automática.
    // Flags curtas podem vir agrupadas (git push -uf origin main) — casar o f dentro do bundle.
    test: (s) =>
      /\bgit\b.*\bpush\b/i.test(s) &&
      (/(^|\s)--force(\s|$)/.test(s) ||
        /(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(s) ||
        /(^|\s)\+\S+(\s|$)/.test(s) ||
        /(^|\s)(--delete|--mirror|--prune)(\s|$)/.test(s) ||
        /(^|\s)-[a-zA-Z]*d[a-zA-Z]*(\s|$)/.test(s) ||
        /(^|\s):\S+(\s|$)/.test(s)),
    why: 'pode reescrever ou apagar refs remotas e commits de outras pessoas.',
    safe: 'use push normal; se reescrita for indispensável, use --force-with-lease e obtenha autorização explícita. Exclusão remota deve ser executada conscientemente pelo usuário.',
  },
  {
    name: 'git reset --hard',
    test: (s) => /\bgit\b.*\breset\b/i.test(s) && /(^|\s)--hard\b/.test(s),
    why: 'descarta commits e mudanças da working tree sem volta.',
    safe: 'crie um ponto de retorno primeiro (stash nomeado ou commit WIP) e siga o procedimento da skill pelizzai-recovery.',
  },
  {
    name: 'git clean -f',
    test: (s) =>
      /\bgit\b.*\bclean\b/i.test(s) &&
      (/(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(s) || /(^|\s)--force\b/.test(s)),
    why: 'apaga arquivos não rastreados de forma irreversível (não há stash nem reflog para eles).',
    safe: 'liste antes com git clean -n e confirme com o usuário o que será apagado.',
  },
  {
    name: 'git branch force-delete/force-rename',
    // -D/-M são case-sensitive (-d/-m são as variantes não forçadas).
    test: (s) =>
      /\bgit\b.*\bbranch\b/i.test(s) &&
      (/(^|\s)-[a-zA-Z]*[DM][a-zA-Z]*(\s|$)/.test(s) ||
        /(^|\s)--force(\s|$)/.test(s) ||
        /(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(s)),
    why: 'pode remover branch não mesclada ou sobrescrever um nome de branch existente.',
    safe: 'use -d/-m sem força; descarte ou sobrescrita exige decisão explícita e operação manual.',
  },
  {
    name: 'git checkout de paths',
    // Cobre checkout . e qualquer forma checkout [<ref>] -- <path>.
    test: (s) =>
      /\bgit\b.*\bcheckout\b(\s+--)?\s+\.\/?(\s|$)/i.test(s) ||
      /\bgit\b.*\bcheckout\b.*\s--\s+\S+/i.test(s),
    why: 'sobrescreve mudanças não commitadas nos paths selecionados.',
    safe: 'crie um ponto de retorno primeiro e confirme os paths; para stage, use git restore --staged.',
  },
  {
    name: 'git checkout/switch force-create',
    test: (s) =>
      (/\bgit\b.*\bcheckout\b/i.test(s) &&
        (/(^|\s)--force(\s|$)/.test(s) ||
          /(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(s) ||
          /(^|\s)-[a-zA-Z]*B[a-zA-Z]*(\s|$)/.test(s))) ||
      (/\bgit\b.*\bswitch\b/i.test(s) &&
        (/(^|\s)--force-create(\s|$)/.test(s) ||
          /(^|\s)--discard-changes(\s|$)/.test(s) ||
          /(^|\s)-[a-zA-Z]*C[a-zA-Z]*(\s|$)/.test(s) ||
          /(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(s))),
    why: 'pode sobrescrever a branch alvo ou descartar mudanças locais ao trocar de branch.',
    safe: 'preserve a working tree primeiro e use switch/checkout sem flags de força; para recuperação, siga pelizzai-recovery.',
  },
  {
    name: 'git restore de working tree',
    test: (s) => {
      if (!/\bgit\b.*\brestore\b/i.test(s)) return false;
      const staged = /--staged\b/.test(s) || /(^|\s)-[a-zA-Z]*S[a-zA-Z]*(\s|$)/.test(s);
      const worktree = /--worktree\b/.test(s) || /(^|\s)-[a-zA-Z]*W[a-zA-Z]*(\s|$)/.test(s);
      return !staged || worktree;
    },
    why: 'restore sem modo exclusivamente staged descarta mudanças da working tree.',
    safe: 'git restore --staged <paths> apenas tira do stage; para descartar conteúdo, crie um ponto de retorno e obtenha confirmação.',
  },
  {
    name: 'git worktree remove --force',
    test: (s) =>
      /\bgit\b.*\bworktree\b.*\bremove\b/i.test(s) &&
      (/(^|\s)--force(\s|$)/.test(s) || /(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(s)),
    why: 'pode remover um worktree sujo e apagar mudanças não commitadas.',
    safe: 'inspecione o worktree, preserve o conteúdo e use git worktree remove sem --force.',
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
  if (typeof command !== 'string' || !/\bgit\b/i.test(command)) return 0;

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
