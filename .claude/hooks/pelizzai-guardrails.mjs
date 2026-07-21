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
 *  - git switch -C / --force-create
 *  - git restore .                  (sem --staged — perda da working tree)
 *  - git worktree remove --force
 *
 * ESTAS REGRAS SÃO DELIBERADAMENTE ESTREITAS. O hook mira o punhado de comandos que
 * apagam trabalho de forma irrecuperável; ele NÃO tenta cobrir todo git perigoso. Por
 * isso passam sem bloqueio, de propósito: git restore <arquivo>, git checkout -- <arquivo>,
 * git branch -M <nome> (passo canônico do git init), git push --delete/+refspec e
 * qualquer menção a "restore"/"reset" dentro de um path, de uma mensagem de commit ou de
 * um filtro (git add src/restore.ts, git log --grep=restore). Regra larga aqui custa caro:
 * ela trava trabalho legítimo, o agente aprende a contornar o hook e a rede de segurança
 * perde valor. Ao mexer, prefira falso negativo a falso positivo — e teste os dois lados.
 *
 * O nome do comando é reconhecido sem distinção de maiúsculas ("Git reset --hard" também
 * é bloqueado); as FLAGS continuam case-sensitive, porque -D/-C/-S/-W destroem e
 * -d/-c/-s/-w não.
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
 * As duas variantes devem bloquear e liberar exatamente os mesmos comandos — a paridade
 * é verificada pelo scripts/test-harness-contracts.ps1.
 */

import { readFileSync } from 'node:fs';

const RULES = [
  {
    name: 'git push --force / -f',
    // --force-with-lease NÃO casa com "--force(\s|$)" — a exceção é automática.
    // Flags curtas podem vir agrupadas (git push -uf origin main) — casar o f dentro do bundle.
    test: (s) =>
      /\bgit\b.*\bpush\b/i.test(s) &&
      (/(^|\s)--force(\s|$)/.test(s) || /(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(s)),
    why: 'push forçado reescreve o histórico remoto e pode apagar commits de outras pessoas.',
    safe: 'use --force-with-lease (só sobrescreve se o remoto estiver onde você espera) — e somente com pedido explícito do usuário.',
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
    name: 'git branch -D',
    // -D case-sensitive (-d é seguro); pode vir agrupada (git branch -qD nome).
    // -M NÃO entra: renomear branch é o passo canônico de git init (git branch -M main).
    test: (s) => /\bgit\b.*\bbranch\b/i.test(s) && /(^|\s)-[a-zA-Z]*D[a-zA-Z]*(\s|$)/.test(s),
    why: 'força a remoção de uma branch NÃO mesclada — os commits dela podem se perder.',
    safe: 'use -d (só remove branch já mesclada) ou confirme o descarte com o usuário (a pelizzai-finish-task exige o texto "descartar").',
  },
  {
    name: 'git checkout . / checkout [<ref>] -- .',
    // Cobre "checkout .", "checkout -- .", "checkout <ref> -- ." e a forma "./" (todas descartam a working tree).
    // checkout -- <arquivo> NÃO entra: descartar um arquivo nomeado é operação rotineira e reversível na prática.
    test: (s) =>
      /\bgit\b.*\bcheckout\b(\s+--)?\s+\.\/?(\s|$)/i.test(s) ||
      /\bgit\b.*\bcheckout\b\s+\S+\s+--\s+\.\/?(\s|$)/i.test(s),
    why: 'sobrescreve TODAS as mudanças não commitadas da working tree.',
    safe: 'crie um ponto de retorno primeiro (git stash push -u -m "<motivo>") ou restaure só arquivos específicos.',
  },
  {
    name: 'git switch -C / --force-create',
    // -C case-sensitive (-c/--create é seguro: falha se a branch já existir).
    test: (s) =>
      /\bgit\b.*\bswitch\b/i.test(s) &&
      (/(^|\s)--force-create(\s|$)/.test(s) || /(^|\s)-[a-zA-Z]*C[a-zA-Z]*(\s|$)/.test(s)),
    why: 'sobrescreve uma branch existente com o ponto de partida atual — os commits que só existiam nela se perdem.',
    safe: 'use -c/--create (falha se a branch já existir); sobrescrever exige decisão explícita do usuário.',
  },
  {
    name: 'git restore . (working tree)',
    // Sem --staged/-S (ou com --worktree/-W explícito), restore descarta a working tree. "./" == ".".
    // O alvo "." é obrigatório: git restore <arquivo> é rotina, e exigir o "." mantém o hook
    // cego para "restore" que aparece em paths, mensagens e filtros (git add src/restore.ts).
    test: (s) =>
      /\bgit\b.*\brestore\b/i.test(s) &&
      /(^|\s)\.\/?(\s|$)/.test(s) &&
      (!(/--staged\b/.test(s) || /(^|\s)-S(\s|$)/.test(s)) ||
        /--worktree\b/.test(s) ||
        /(^|\s)-W(\s|$)/.test(s)),
    why: 'sem --staged, restore descarta as mudanças da working tree sem volta.',
    safe: 'git restore --staged . apenas tira do stage (seguro); para descartar de verdade, crie um ponto de retorno (stash) e confirme com o usuário.',
  },
  {
    name: 'git worktree remove --force',
    test: (s) =>
      /\bgit\b.*\bworktree\b.*\bremove\b/i.test(s) &&
      (/(^|\s)--force(\s|$)/.test(s) || /(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(s)),
    why: 'remove um worktree sujo e apaga com ele as mudanças não commitadas que estavam lá.',
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
