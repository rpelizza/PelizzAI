#!/usr/bin/env node
/**
 * PelizzAI — hook writegate (PreToolUse). OPT-IN. Fail-CLOSED no invariante, fail-OPEN no erro.
 *
 * Rede de segurança que move da obediência do modelo para enforcement executável as DUAS
 * autonomias irreversíveis que o redesign introduziu: escrever produto sem isolamento e
 * escrever código antes de o gate ser ratificado. NÃO decide rota — apenas devolve o
 * controle ao gate humano. Espelha o espírito e o envelope de segurança do
 * pelizzai-guardrails.mjs (leia-o antes de alterar este arquivo).
 *
 * Dispara ANTES da escrita, em dois matchers irmãos que compartilham este mesmo arquivo:
 *  - Write | Edit | MultiEdit | NotebookEdit  → lê tool_input.file_path / .notebook_path;
 *  - Bash                                     → detecta redirecionamento de escrita no
 *    tool_input.command (>, >>, &>, tee, sed -i, Set-Content/Add-Content/Out-File) para
 *    caminhos DENTRO da raiz do projeto. Mesma regra dos dois lados.
 *
 * REGRA A (invariante, ambos os modos) — isolamento antes da primeira escrita:
 *   escrever caminho de PRODUTO (fora de pelizzai/) dentro da raiz do repo estando em branch
 *   protegida (main/master/develop/dev, o default do origin/HEAD) ou em HEAD destacado → BLOQUEIA.
 *   CARVE-OUT: escrita de metadata em pelizzai/** é liberada mesmo aqui (o sistema se atualizando;
 *   é só de escrita de arquivo — o commit segue no fluxo de branch de tarefa). Saída (produto):
 *   isolar via pelizzai-starting-branch.
 *
 * REGRA B (só consumidor: existe pelizzai/ e NÃO é o repo-fonte) — nada de código antes do gate:
 *   escrever caminho de PRODUTO (fora de pelizzai/) enquanto pelizzai/data/state.md NÃO
 *   contém o marcador "kickoff: ratificado" → BLOQUEIA. Quando o state usa os campos de
 *   aprovação greenfield, qualquer campo ainda pending também bloqueia. Escritas em pelizzai/ (state, plano,
 *   spec) são sempre liberadas: são os artefatos que registram o próprio gate.
 *   Em SOURCE MODE (repo-fonte PelizzAI: sentinela pelizzai-source-repo.txt) a Regra B é PULADA — ali o
 *   marcador vive no execution record nativo, não em arquivo, e só a Regra A vale.
 *
 * Bloqueio: exit 2 + motivo e caminho seguro no stderr (o agente lê e corrige a rota).
 * Erros do PRÓPRIO hook e casos em que NÃO dá para decidir com segurança: exit 0 (fail-open —
 * um bug ou falso positivo aqui nunca trava o usuário). Quando não consegue ler o kickoff em
 * consumidor sem state.md, permite a escrita e avisa no máximo 1x por janela (não spamma).
 *
 * Instalação (opt-in, recomendada pela pelizzai-audit no bootstrap, mesclada sem sobrescrever
 * hooks/permissões já existentes), em .claude/settings.json do projeto consumidor — os DOIS
 * matchers são necessários para cobrir também a escrita via shell:
 *   { "hooks": { "PreToolUse": [
 *       { "matcher": "Write|Edit|MultiEdit|NotebookEdit", "hooks": [
 *           { "type": "command",
 *             "command": "node \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-writegate.mjs\"" } ] },
 *       { "matcher": "Bash", "hooks": [
 *           { "type": "command",
 *             "command": "node \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-writegate.mjs\"" } ] } ] } }
 *
 * Teste manual:
 *   echo '{"tool_input":{"file_path":"src/app.ts"},"cwd":"/caminho/do/repo"}' | node pelizzai-writegate.mjs; echo $?
 *   → em branch protegida ou sem "kickoff: ratificado" no state.md: motivo no stderr e exit 2.
 *     Em branch de tarefa com o kickoff ratificado, ou fora do repo: exit 0.
 *
 * O usuário pode desabilitar o hook em .claude/settings.json — nunca é bloqueio inescapável.
 * Em frota sem Node, use a variante PowerShell pelizzai-writegate.ps1 (comportamento idêntico).
 */

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, resolve, isAbsolute } from 'node:path';
import { execFileSync } from 'node:child_process';
import { tmpdir } from 'node:os';

// Branches protegidas por default (Regra A). origin/HEAD enriquece a lista em runtime.
const PROTECTED = ['main', 'master', 'develop', 'dev'];
// Marcadores máquina-legíveis dos gates sequenciais no state.md (kickoff/pós-plano ratificado
// pelo usuário: conteúdo + isolamento + modo + commit). O writegate e a retomada dependem dele.
const KICKOFF_RATIFIED = /kickoff:\s*ratificado/i;
const PENDING_USER_APPROVAL = /^\s*-?\s*(discovery|spec-approval|domain-skills-decision|plan-approval):\s*<?pending>?\s*$/im;
// Sentinela DEDICADA do repo-fonte PelizzAI (source mode): presente, a Regra B é pulada.
// Critério único e inequívoco: manifesto e sync-harness existem também nos consumidores
// instalados via -ExportConsumer e NÃO indicam source mode.
const SOURCE_SENTINELS = [
  ['scripts', 'pelizzai-source-repo.txt'],
];
// Fail-open "não pôde decidir": avisa no máximo 1x por janela (por repo) para não spammar.
const WARN_SNOOZE_MS = 86400000; // 24h

function readStdin() {
  try {
    return readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

// git com o cwd do stdin; '' em QUALQUER falha (git ausente, fora de repo, ref inexistente).
function git(cwd, args) {
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

// Barras para frente e sem barra final, para comparação de prefixo robusta a \ e /.
function norm(p) {
  return String(p).replace(/\\/g, '/').replace(/\/+$/, '');
}

// Windows e macOS comparam caminhos sem case; Linux com case.
const CI = process.platform === 'win32' || process.platform === 'darwin';

// child é o próprio root ou está DENTRO dele.
function eqOrInside(child, root) {
  let c = norm(child);
  let r = norm(root);
  if (CI) {
    c = c.toLowerCase();
    r = r.toLowerCase();
  }
  return c === r || c.startsWith(r + '/');
}

// Parser de UM segmento de shell, ciente de aspas: separa tokens e ALVOS de redirecionamento.
// Ciente de aspas para não confundir um '>' dentro de string (ex.: git commit -m "a > b")
// com um redirecionamento real. Ignora dup de fd (>&N) e descarta prefixos de fd (2>, &>).
function parseSegment(seg) {
  const tokens = [];
  const redirects = [];
  let cur = '';
  let quote = null; // "'" ou '"' quando dentro de aspas
  let expectTarget = false; // o próximo token completo é alvo de redirecionamento
  const flush = () => {
    if (cur === '') return;
    if (expectTarget) {
      if (!cur.startsWith('&')) redirects.push(cur); // '&' → dup de fd (>&2), não é arquivo
      expectTarget = false;
    } else if (!/^[0-9]+$|^&$/.test(cur)) {
      tokens.push(cur); // descarta prefixo de fd solto (o "2" de "2>")
    }
    cur = '';
  };
  for (let i = 0; i < seg.length; i++) {
    const ch = seg[i];
    if (quote) {
      if (ch === quote) quote = null;
      else cur += ch;
      continue;
    }
    if (ch === '"' || ch === "'") {
      quote = ch;
      continue;
    }
    if (ch === '>') {
      flush(); // fecha um eventual fd (2, &) antes do '>'
      if (seg[i + 1] === '>') i++; // '>>' (append) conta como um único redirecionamento
      expectTarget = true;
      continue;
    }
    if (ch === ' ' || ch === '\t') {
      flush();
      continue;
    }
    cur += ch;
  }
  flush();
  return { tokens, redirects };
}

// Alvos de escrita de um comando shell (matcher irmão de Bash). Best-effort e honesto:
// cobre os casos comuns; o que não conseguir parsear com segurança, não bloqueia.
function extractShellTargets(command) {
  const targets = [];
  for (const seg of command.split(/&&|\|\||;|\||\r?\n/)) {
    const { tokens, redirects } = parseSegment(seg);
    for (const r of redirects) targets.push(r);
    for (let i = 0; i < tokens.length; i++) {
      const t = tokens[i].toLowerCase();
      // tee [-flags] arquivo...  /  Tee-Object -FilePath arquivo
      if (t === 'tee' || t === 'tee-object') {
        for (let j = i + 1; j < tokens.length; j++) {
          const a = tokens[j];
          if (/^-(?:literal)?(?:file)?path$/i.test(a) && j + 1 < tokens.length) {
            targets.push(tokens[j + 1]);
            j++;
            continue;
          }
          if (!a.startsWith('-')) targets.push(a);
        }
      }
      // Set-Content / Add-Content / Out-File: -Path/-LiteralPath ou primeiro posicional.
      if (t === 'set-content' || t === 'add-content' || t === 'out-file') {
        let took = false;
        for (let j = i + 1; j < tokens.length && !took; j++) {
          const a = tokens[j];
          if (/^-(?:literal)?(?:file)?path$/i.test(a) && j + 1 < tokens.length) {
            targets.push(tokens[j + 1]);
            took = true;
          } else if (!a.startsWith('-')) {
            targets.push(a);
            took = true;
          }
        }
      }
      // sed -i / --in-place <arquivo> (último operando não-flag do segmento).
      if (t === 'sed') {
        const inPlace = tokens
          .slice(i + 1)
          .some((x) => /^-i(?:\..*)?$/.test(x) || x === '--in-place' || /^-[a-z]*i[a-z]*$/i.test(x));
        if (inPlace) {
          for (let j = tokens.length - 1; j > i; j--) {
            if (!tokens[j].startsWith('-')) {
              targets.push(tokens[j]);
              break;
            }
          }
        }
      }
    }
  }
  return targets.filter((p) => p && !p.startsWith('-'));
}

function block(reason) {
  process.stderr.write(
    `PelizzAI writegate: escrita bloqueada — ${reason}\n` +
      `(Hook opt-in fail-closed de isolamento/kickoff. Se a escrita for legítima fora do fluxo, ` +
      `isole via pelizzai-starting-branch, ratifique o gate, ou desabilite o hook em .claude/settings.json.)\n`
  );
  return 2;
}

// Aviso best-effort, no máximo 1x por janela e por repo — nunca afeta o exit code.
function warnOnce(gitRoot, message) {
  try {
    const key = norm(gitRoot).toLowerCase().replace(/[^a-z0-9]/g, '_').slice(-60);
    const statePath = join(tmpdir(), `pelizzai-writegate-${key}.json`);
    const now = Date.now();
    let warnUntil = 0;
    try {
      if (existsSync(statePath)) warnUntil = JSON.parse(readFileSync(statePath, 'utf8')).warnUntil || 0;
    } catch {
      /* estado corrompido: reavisa */
    }
    if (now < warnUntil) return; // ainda dentro da janela de silêncio
    process.stderr.write(`PelizzAI writegate (aviso): ${message}\n`);
    try {
      writeFileSync(statePath, JSON.stringify({ warnUntil: now + WARN_SNOOZE_MS }));
    } catch {
      /* sem persistência — segue */
    }
  } catch {
    /* aviso é opcional; jamais interfere no fluxo */
  }
}

function main() {
  let data;
  try {
    data = JSON.parse(readStdin() || '{}');
  } catch {
    return 0; // payload ilegível → não é papel do hook travar
  }
  let cwd = process.cwd();
  if (data && typeof data.cwd === 'string' && data.cwd) cwd = data.cwd;
  const ti = (data && data.tool_input) || {};

  // Alvos: file_path (Write/Edit/MultiEdit), notebook_path (NotebookEdit), shell (Bash).
  const targets = [];
  if (typeof ti.file_path === 'string' && ti.file_path) targets.push(ti.file_path);
  if (typeof ti.notebook_path === 'string' && ti.notebook_path) targets.push(ti.notebook_path);
  if (typeof ti.command === 'string' && ti.command) targets.push(...extractShellTargets(ti.command));
  if (targets.length === 0) return 0; // nada a guardar (ex.: Bash somente leitura)

  const gitRoot = git(cwd, ['rev-parse', '--show-toplevel']);
  if (!gitRoot) return 0; // fora de repo git (scratchpad/externos) ou git ausente → permite

  // Só interessam alvos DENTRO da raiz; scratchpad/temp fora da raiz nunca bloqueia.
  const inRoot = targets
    .map((t) => (isAbsolute(t) ? t : join(cwd, t)))
    .map((t) => resolve(t))
    .filter((t) => eqOrInside(t, gitRoot));
  if (inRoot.length === 0) return 0;

  // Metadata do harness (pelizzai/**) vs. PRODUTO (fora de pelizzai/). Tanto o carve-out da
  // Regra A quanto a Regra B se apoiam nessa separação.
  const pelizzaiDir = join(gitRoot, 'pelizzai');
  const products = inRoot.filter((t) => !eqOrInside(t, pelizzaiDir));

  // ── Regra A (ambos os modos): branch protegida/destacada bloqueia escrita de PRODUTO in-root.
  // CARVE-OUT DE METADATA: escrever dentro de pelizzai/** é LIBERADO mesmo em branch protegida ou
  // HEAD destacado — é metadata do harness (state/plano/spec/reports), o sistema se atualizando,
  // nunca produto. Isso destrava a reconciliação do state na própria branch protegida à qual o dev
  // volta após o merge do PR. NOTA DE SEGURANÇA: o carve-out é SÓ de escrita de ARQUIVO e não abre
  // brecha de produto nem de commit — produto (fora de pelizzai/) segue bloqueado por esta mesma
  // Regra A; a metadata só é COMMITADA no primeiro commit da branch de tarefa nova (o fluxo nunca
  // exige commit em protegida); e o pelizzai-guardrails continua barrando git destrutivo.
  // LIMITE (symlink): a classificação metadata-vs-produto é por CAMINHO — resolve() normaliza `..`
  // (por isso `pelizzai/../src` corretamente vira produto), mas NÃO segue symlinks. Um symlink dentro
  // de pelizzai/ apontando para fora (ex.: `pelizzai/link -> ../src`) poderia fazer uma escrita real
  // em produto ser lida como metadata e liberada em branch protegida. O carve-out NÃO é airtight
  // quanto a symlink; os controles compensatórios permanecem: pelizzai-guardrails barra o git
  // destrutivo e o review humano enxerga o alvo real.
  const branch = git(cwd, ['branch', '--show-current']); // '' = HEAD destacado (ou sem branch)
  let isProtected = branch === '' || PROTECTED.includes(branch);
  if (!isProtected) {
    // Enriquecimento pelo default do remoto; se falhar, degrada para a lista estática
    // (NÃO para fail-open — a Regra A precisa continuar armada sem origin/HEAD).
    const originHead = git(cwd, ['symbolic-ref', '--short', 'refs/remotes/origin/HEAD']);
    if (originHead) {
      const tail = originHead.split('/').pop();
      if (tail && tail === branch) isProtected = true;
    }
  }
  if (isProtected && products.length > 0) {
    return block(
      `branch protegida/destacada (${branch || 'HEAD destacado'}). Isole via pelizzai-starting-branch ` +
        `antes de escrever produto — isolamento antes da primeira escrita é invariante ` +
        `(escrita de metadata em pelizzai/ é liberada mesmo aqui).`
    );
  }

  // Source mode (repo-fonte PelizzAI): o marcador vive no execution record → Regra B pulada.
  const sourceMode = SOURCE_SENTINELS.every((parts) => existsSync(join(gitRoot, ...parts)));
  if (sourceMode) return 0;

  // ── Regra B (só consumidor): escrita de PRODUTO exige kickoff ratificado no state.md.
  if (products.length === 0) return 0; // só artefatos de setup em pelizzai/ → liberado

  const statePath = join(gitRoot, 'pelizzai', 'data', 'state.md');
  if (!existsSync(statePath)) {
    // Consumidor sem state.md: não dá para ler o kickoff com segurança → fail-open + aviso 1x.
    warnOnce(
      gitRoot,
      'sem pelizzai/data/state.md para verificar o kickoff; permitindo a escrita. Se este projeto ' +
        'usa o harness, conduza o gate de kickoff e registre "kickoff: ratificado" antes de escrever produto.'
    );
    return 0;
  }
  let state = '';
  try {
    state = readFileSync(statePath, 'utf8');
  } catch {
    return 0; // não conseguiu ler o marcador → fail-open
  }
  if (KICKOFF_RATIFIED.test(state) && !PENDING_USER_APPROVAL.test(state)) return 0;

  if (PENDING_USER_APPROVAL.test(state)) {
    return block(
      'há aprovação humana pendente no lifecycle (discovery/spec/domain skills/plano). ' +
        'Resolva uma decisão por vez com o usuário e atualize o state antes de escrever produto.'
    );
  }

  return block(
    'o kickoff ainda não foi ratificado (falta "kickoff: ratificado" em pelizzai/data/state.md). ' +
      'Conduza o gate de kickoff/pós-plano COM o usuário — isolamento, modo de execução e estratégia ' +
      'de commit —, grave "kickoff: ratificado" em pelizzai/data/state.md e então escreva o código.'
  );
}

let exitCode = 0;
try {
  exitCode = main();
} catch {
  exitCode = 0; // fail-open: erro do PRÓPRIO hook nunca trava o usuário
}
process.exit(exitCode);
