---
name: pelizzai-finish-task
description: Use quando uma tarefa ou feature está implementada e os testes passam, ANTES de dar push ou abrir PR. Consolida os commits (squash opcional) e escolhe entre push, Pull Request, manter local ou descartar — sempre perguntando, nunca automático. Fecha o cursor da tarefa em `pelizzai/data/state.md` (phase: done). Acione ao final dos tracks de feature, bug e ajuste (chamada por `pelizzai-execution-plans`, `pelizzai-debugging` e `pelizzai-quick-fix`), ou quando o usuário disser "fechar a tarefa", "abrir PR", "fazer push".
---

# PelizzAI Finish Task

## Objetivo

Depois da implementação, consolidar o trabalho e escolher o caminho de integração **de forma deliberada** — sem squash automático, sem push automático, sem PR automático.

**Anuncie ao iniciar:** "Usando a skill Pelizzai Finish Task para fechar esta entrega."

> **Princípio:** verificar testes → fechar o cursor → consolidar honrando a estratégia de commit → perguntar squash → perguntar destino → executar.

---

## Processo

### 0. Gate de branch protegida

Antes de qualquer `git add`/commit, rode `git branch --show-current`. Se for `main`, `master`, `develop`, `dev` — **ou vazio** (HEAD destacado → fail-closed) → **PARE**, não consolide aqui. Volte à `pelizzai-starting-branch` para mover o trabalho a uma feature branch. Neste abort, **não** feche o cursor (não marque `phase: done`); registre o bloqueio em `pelizzai/data/state.md` → `## Progresso` → `pending`. Se já houver trabalho **commitado** na protegida: crie a feature branch a partir do HEAD atual (`git checkout -b <branch>`) e então limpe a protegida (`git checkout <protegida> && git fetch && git reset --hard origin/<protegida>`), levando os commits para a feature branch.

### 1. Verificar os testes

Rode os comandos de teste do projeto (use `pelizzai-verification-before-completion` — evidência fresca). Se algum falhar, **pare e reporte** — não apresente opções. Não feche o cursor; registre o teste que falha em `pending`.

### 1.5. Fechar a tarefa no cursor (OBRIGATÓRIO)

Transição terminal da tarefa. Atualize `pelizzai/data/state.md` com suas ferramentas de arquivo:

```text
1. Arquive em ## Histórico: linha datada do que foi entregue (ex.: "- AAAA-MM-DD — <slug>: concluída (push/PR/local)").
2. Limpe a identidade da tarefa ativa: slug: <none> e phase: done. NÃO apague commit-strategy
   (o Passo 2 a lê para honrar o squash) nem os demais campos de execução.
3. Resete ## Progresso para placeholders (ou um próximo passo real — nunca o que você acabou de fechar).
4. Atualize "Última atualização" para hoje.
```

Mantenha esse cursor só no `state.md` — não escreva progresso no `CLAUDE.md` nem no `README.md`. Se `pelizzai/data/state.md` não existir, instancie-o a partir do template da `pelizzai-execution-plans`. O update do cursor **tem que entrar no commit de fechamento** (Passo 2). **Por quê:** a `pelizzai-router` lê o `state.md` a cada nova tarefa; se a tarefa fechada continuar "ativa", a próxima sessão retoma algo já concluído.

### 2. Consolidar (honrar a estratégia de commit)

Leia `commit-strategy` no `state.md`. **Fallback** (campo ausente/ilegível): assuma `granular` e **CONFIRME com o usuário antes de qualquer `git reset --soft`**.

- **`squash-final`:** a execução NÃO commitou por tarefa — spec, plano e código estão acumulados **sem commit** na working tree. Faça `git add -A` e crie o **commit final único** agora (mensagem pelo template do 3a). Pule o Passo 3.
- **`granular`:** o trabalho já está em commits por tarefa. **Commite o fechamento do cursor como commit próprio** (`git add pelizzai/data/state.md` + `git commit -m "chore: fecha tarefa no cursor (state.md)"`).

Depois, determine a base e liste os commits desde a divergência:

```bash
base=$(git merge-base HEAD origin/develop 2>/dev/null || git merge-base HEAD origin/dev 2>/dev/null \
    || git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD origin/master 2>/dev/null \
    || git merge-base HEAD develop 2>/dev/null || git merge-base HEAD dev 2>/dev/null \
    || git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null)
[ -z "$base" ] && { echo "ERRO: base indefinida — PARE e confirme a base com o usuário"; exit 1; }
git log --oneline "$base"..HEAD
```

> **NUNCA** rode `reset --soft`/`checkout` com `base` vazia (é destrutivo). Em PowerShell, determine `base` passo a passo e aborte se vazia.

### 3. (só granular) Perguntar: squash ou manter histórico?

Apresente exatamente:

```text
Você fez N commits nesta branch.

1. Consolidar em um único commit (squash)
2. Manter o histórico granular como está

Qual opção?
```

Aguarde a escolha; **nunca** faça squash automático.

### 3a. Se squash

Rascunhe a mensagem pelo template, apresente para aprovação e só então aplique. Mensagem em **português do Brasil**.

```text
Commit summary: máx 50 chars · <tipo>(<escopo>): <descrição curta> · tempo presente, impessoal, sem pontuação final.
Tipos: feat, fix, docs, style, refactor, test, chore, perf, build, ci.
Corpo: o QUE mudou e POR QUÊ, em voz passiva/impessoal. BREAKING CHANGE: <só se aplicável>.
```

Após aprovação e **com `base` não-vazia**: `git reset --soft "$base"` + `git commit`.

### 3b. Se manter histórico

Mantenha os commits por tarefa. Confirme que o fechamento do cursor (Passo 2 granular) já está commitado (`git status --short pelizzai/data/state.md` deve estar limpo). Pule para o Passo 4.

### 3c. Security review (oferta — não bloqueia)

Se o diff toca superfície sensível (auth, input do usuário, queries/SQL, dados sensíveis/segredos, upload, desserialização, CORS/headers, nova dependência), ofereça uma vez:

> Esta mudança mexe em <área sensível>. Quer que eu rode a `pelizzai-oswap` (OWASP Top 10) antes de integrar?

Se aceito, invoque `pelizzai-oswap`. Fixes de segurança rodam **após** o commit de fechamento → commite-os como `fix(security): …` separado, antes do push.

### 3d. Frontend preview (oferta — não bloqueia)

Se o diff toca **frontend** (componentes, páginas, rotas, estilos), ofereça uma vez:

> Esta entrega mexe no frontend. Quer que eu valide a UI rodando (`pelizzai-frontend`) antes de fechar?

Se a validação **reprovar** (layout quebrado, estado faltando), corrija e commite como `fix(ui): …` separado, antes do push (o gate da working tree do Passo 4 impede push sujo).

### 4. Perguntar: destino

Apresente exatamente:

```text
Como integrar?

1. Push direto (sem PR)
2. Push e abrir Pull Request
3. Manter local — não fazer nada agora
4. Descartar a branch

Qual opção?
```

**Gate da working tree (antes de qualquer push):** nunca dê push com algo não commitado (cursor, fixes de segurança, docs). Se houver, commite primeiro.

- **4a. Push direto:** só se a base **não** for protegida. **Fail-closed:** só empurre direto se a API responder explicitamente que a base não é protegida (HTTP 404 em `.../protection`); qualquer outro resultado (protegida, auth, 403, rede) → ofereça PR (opção 2).
- **4b. Push + PR:** `git push -u origin <branch>` + `gh pr create --base <base> --title ... --body ...` (Resumo + Como testar). Se `gh` não autenticado, peça `gh auth login` e pare.
- **4c. Manter local:** reporte branch e HEAD; nada mais.
- **4d. Descartar:** exija o usuário digitar **'descartar'**; só então `git checkout <base>` + `git branch -D <branch>`.

### 5. Nudge de revisão de skills (leve, nunca bloqueia)

A tarefa foi integrada. Verifique no ledger `pelizzai/data/review-domain-skills.md` se acumulou histórico suficiente para sugerir uma revisão das skills de domínio (conta commits desde `last-review`; **≥10 commits ou >10 dias** → sugira uma vez acionar a `pelizzai-writing-skills` em modo manutenção). Abaixo do limiar: não diga nada. Detalhe em `pelizzai-writing-skills` → `references/domain-skill-maintenance.md`. (Núcleo portável da cadência — sem hooks aqui.)

---

## Multi-projeto

Se a tarefa afetou múltiplos projetos (ver `pelizzai-starting-branch`), rode o fluxo completo por projeto. Pergunte uma vez se a escolha de squash/destino vale para todos ou se decide por projeto.

---

## Red flags

```text
Nunca: push/PR sem confirmação explícita; squash automático; force-push sem pedido; descartar sem
       texto 'descartar'; prosseguir com teste falhando; pushar com working tree suja.
Sempre: fechar o cursor (Passo 1.5: phase: done, slug: <none>, arquivar no Histórico) e fazer isso
        entrar no commit de fechamento; mostrar a lista de commits antes do squash; mostrar os menus
        verbatim; detectar base protegida antes do push direto; permitir decisão por projeto.
```

---

## Integração

**Chamada por:** `pelizzai-execution-plans` (após todas as tarefas), `pelizzai-debugging` (fecha o track de bug após o fix verificado), `pelizzai-quick-fix` (fecha o track de ajuste).

**Combina com:** `pelizzai-starting-branch` (abre a branch que esta skill fecha), `pelizzai-verification-before-completion` (verifica os testes), `pelizzai-oswap` (segurança), `pelizzai-frontend` (UI), `pelizzai-resolving-merge-conflicts` (se o push/integração gerar conflito), `pelizzai-writing-skills` (cadência de revisão de skills).
