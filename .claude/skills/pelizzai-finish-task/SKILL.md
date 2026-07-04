---
name: pelizzai-finish-task
description: Use quando uma tarefa ou feature está implementada e os testes passam, ANTES de dar push ou abrir PR. É o fechamento deliberado de toda entrega — HONRA a commit-strategy escolhida no gate de setup, e nada de push, PR ou descarte acontece automático: o destino é sempre decisão explícita do usuário. Acione ao final dos tracks de feature, bug e ajuste (chamada por `pelizzai-execution-plans`, `pelizzai-debugging` e `pelizzai-quick-fix`), ou quando o usuário disser "fechar a tarefa", "abrir PR", "fazer push".
---

# PelizzAI Finish Task

## Objetivo

Depois da implementação, consolidar o trabalho e escolher o caminho de integração **de forma deliberada** — sem push automático, sem PR automático, e **honrando a estratégia de commit que o usuário já escolheu** no gate de setup (não re-decidir no fim o que foi decidido no início).

**Anuncie ao iniciar:** "Usando a skill PelizzAI Finish Task para fechar esta entrega."

> **Princípio:** verificar testes → fechar o cursor → consolidar honrando a estratégia de commit (granular mantém o histórico; squash-final consolida os wip) → perguntar destino → executar → (worktree? oferecer remoção).

---

## Processo

### 0. Gate de branch protegida

Antes de qualquer `git add`/commit, rode `git branch --show-current`. Se for `main`, `master`, `develop`, `dev` — **ou vazio** (HEAD destacado → fail-closed) → **PARE**, não consolide aqui. Volte à `pelizzai-starting-branch` para mover o trabalho a uma feature branch. Neste abort, **não** feche o cursor (não marque `phase: done`); registre o bloqueio em `pelizzai/data/state.md` → `## Progresso` → `pending`. Se já houver trabalho **commitado** na protegida: crie a feature branch a partir do HEAD atual (`git checkout -b <branch>`) e então limpe a protegida — **com duas guardas fail-closed antes do reset destrutivo**: (1) `git status --porcelain` precisa estar VAZIO (mudanças não commitadas seriam destruídas em silêncio — commite-as na feature branch ou pare e pergunte); (2) `git rev-parse --verify origin/<protegida>` precisa existir (sem remoto, não há para onde resetar — pare e pergunte). Só com as duas guardas verdes: `git checkout <protegida> && git fetch && git reset --hard origin/<protegida>`, levando os commits para a feature branch.

### 1. Verificar os testes

Rode os comandos de teste do projeto (use `pelizzai-verification-before-completion` — evidência fresca). Se algum falhar, **pare e reporte** — não apresente opções. Não feche o cursor; registre o teste que falha em `pending`.

### 1.5. Fechar a tarefa no cursor (OBRIGATÓRIO)

Transição terminal da tarefa. Atualize `pelizzai/data/state.md` com suas ferramentas de arquivo:

```text
1. Arquive em ## Histórico: linha datada do que foi entregue (ex.: "- AAAA-MM-DD — <slug>: concluída").
   NÃO registre o destino aqui — ele só é decidido no Passo 4. Complemente a linha com
   "(push/PR/local)" DEPOIS da escolha do Passo 4 e ANTES de executá-la: em granular, um commit
   curto do state.md; em squash-final, emende o commit único ainda não publicado
   (`git add pelizzai/data/state.md` + `git commit --amend --no-edit` — seguro porque nada foi
   pushado; NUNCA emende commit já publicado). O gate da working tree do Passo 4 garante que
   nada fica de fora antes do push.
2. Limpe a identidade da tarefa ativa: slug: <none> e phase: done. NÃO apague commit-strategy
   (o Passo 2 a lê para honrar o squash) nem os demais campos de execução.
3. Resete ## Progresso para placeholders (ou um próximo passo real — nunca o que você acabou de fechar).
4. Atualize "Última atualização" para hoje.
```

Mantenha esse cursor só no `state.md` — não escreva progresso no `CLAUDE.md` nem no `README.md`. Se `pelizzai/data/state.md` não existir, instancie-o a partir do template da `pelizzai-execution-plans`. O update do cursor **tem que entrar no commit de fechamento** (Passo 2). **Por quê:** a `pelizzai-router` lê o `state.md` a cada nova tarefa; se a tarefa fechada continuar "ativa", a próxima sessão retoma algo já concluído.

### 2. Consolidar (honrar a estratégia de commit — sem re-perguntar)

Leia `commit-strategy` no `state.md`. **Fallback** (campo ausente/ilegível/`<pending>`): **pergunte agora** (menu do gate: granular / squash-final) e registre — nunca assuma para uma operação destrutiva.

- **`granular`:** o trabalho de plano já está em **commits definitivos por tarefa** — o histórico é **mantido como está**; **não pergunte squash** (o usuário já decidiu granular no setup; só faça squash se ele pedir explicitamente agora). **Se houver trabalho ainda sem commit na working tree** (caso normal dos tracks bug e ajuste, cujo fix fica na working tree até aqui), commite-o PRIMEIRO como commit definitivo (`<tipo>(<escopo>): <descrição>`). Então **commite o fechamento do cursor como commit próprio** (`git add pelizzai/data/state.md` + `git commit -m "chore: fecha tarefa no cursor (state.md)"`). Siga para o Passo 3.
- **`squash-final`:** a execução deixou **commits de trabalho** (`wip(<slug>): …`) por tarefa. A consolidação num commit único **já foi autorizada** na escolha da estratégia: determine a base (abaixo), rascunhe a mensagem final pelo template do 2a, **apresente a mensagem para aprovação** e aplique `git reset --soft "$base"`, depois **sempre** `git add pelizzai/data/state.md` (o fechamento do cursor do Passo 1.5 está SEMPRE não-commitado neste ponto — sem este stage ele fica fora do commit final) e `git add -A` para qualquer trabalho residual da working tree, e só então `git commit`. Depois siga para o Passo 3c.

Para o squash-final, determine a base e liste os commits desde a divergência:

```bash
base=$(git merge-base HEAD origin/develop 2>/dev/null || git merge-base HEAD origin/dev 2>/dev/null \
    || git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD origin/master 2>/dev/null \
    || git merge-base HEAD develop 2>/dev/null || git merge-base HEAD dev 2>/dev/null \
    || git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null)
[ -z "$base" ] && { echo "ERRO: base indefinida — PARE e confirme a base com o usuário"; exit 1; }
git log --oneline "$base"..HEAD
```

> **NUNCA** rode `reset --soft`/`checkout` com `base` vazia (é destrutivo). Em PowerShell, determine `base` passo a passo e aborte se vazia.

### 2a. Template da mensagem do commit final (squash-final)

Mensagem em **português do Brasil**; apresente para aprovação antes de aplicar:

```text
Commit summary: máx 50 chars · <tipo>(<escopo>): <descrição curta> · tempo presente, impessoal, sem pontuação final.
Tipos: feat, fix, docs, style, refactor, test, chore, perf, build, ci.
Corpo: o QUE mudou e POR QUÊ, em voz passiva/impessoal. BREAKING CHANGE: <só se aplicável>.
```

Aplique **somente com `base` não-vazia**, na sequência completa do Passo 2: `git reset --soft "$base"` → `git add pelizzai/data/state.md` (sempre) → `git add -A` (trabalho residual) → `git commit`.

### 3. Confirmação do granular (squash-final pula este passo)

No granular, confirme que o fechamento do cursor (Passo 2) já está commitado (`git status --short pelizzai/data/state.md` deve estar limpo). **Não ofereça squash** — a decisão de histórico já foi tomada no gate de setup; um pedido explícito do usuário agora é a única exceção (aí use o template do 2a). Siga para o Passo 3c.

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
- **4d. Descartar:** exija o usuário digitar **'descartar'**; se estiver DENTRO do worktree, primeiro volte ao repositório principal (`cd <repo-raiz>` — de dentro do worktree o `git worktree remove` falha e o `git checkout <base>` colide com a branch do próprio worktree); então, se worktree: `git worktree remove <caminho> --force`; e só então `git checkout <base>` + `git branch -D <branch>` — tudo a partir do repositório principal.

### 4.5. Worktree (se `isolation: worktree` no state.md)

Após integrar (4a/4b) ou manter local com o trabalho seguro, **ofereça** remover o worktree: "O worktree `<caminho>` ainda existe. Quer que eu o remova (`git worktree remove`)?" Remova só com confirmação e **a partir do repositório principal** (saia do worktree primeiro — `git worktree remove` falha de dentro dele); se houver mudanças não commitadas nele, **pare e reporte** em vez de forçar. Limpe também o `worktree-path` no `state.md`.

### 5. Nudge de revisão de skills (leve, nunca bloqueia)

Este é o **disparo primário** da cadência (o hook do Claude Code é só rede de segurança). Verifique no ledger `pelizzai/data/review-domain-skills.md` os **dois** gatilhos: (a) revisão — commits desde `last-review` **≥30 ou >14 dias** (o eixo de dias é a âncora de ~sprint; os commits só antecipam num burst real); (b) repo-scan completo — **>21 dias** desde `last-full-scan`. Qualquer um vencido → sugira **uma vez** acionar a `pelizzai-writing-skills` em modo manutenção (mencionando qual gatilho venceu). Abaixo dos limiares: não diga nada. Se o usuário adiar, não repita na mesma sessão. Detalhe em `pelizzai-writing-skills` → `references/domain-skill-maintenance.md`.

---

## Multi-projeto

Se a tarefa afetou múltiplos projetos (ver `pelizzai-starting-branch`), repita **por projeto** os passos 0–1 e 2–4.5 (verificação, consolidação, destino, worktree). O **Passo 1.5 roda UMA única vez**, ao final do último projeto — o cursor do workspace é um só; fechá-lo N vezes duplicaria linhas no Histórico e re-tocaria um cursor já `done`. Se útil, arquive uma linha por projeto nessa única passada. Pergunte uma vez se a escolha de destino vale para todos ou se decide por projeto.

---

## Red flags

```text
Nunca: push/PR sem confirmação explícita; RE-PERGUNTAR squash quando a estratégia é granular
       (a decisão do gate de setup é honrada — squash só a pedido explícito); squash sem a
       estratégia squash-final registrada ou pedido do usuário; force-push sem pedido; descartar
       sem texto 'descartar'; remover worktree sem confirmação (ou com mudanças não commitadas);
       prosseguir com teste falhando; pushar com working tree suja.
Sempre: fechar o cursor (Passo 1.5: phase: done, slug: <none>, arquivar no Histórico) e fazer isso
        entrar no commit de fechamento; no squash-final, mostrar a lista de commits e a mensagem
        final para aprovação antes do reset --soft; mostrar os menus verbatim; detectar base
        protegida antes do push direto; permitir decisão por projeto; oferecer a remoção do
        worktree no fechamento.
```

---

## Integração

**Chamada por:** `pelizzai-execution-plans` (após todas as tarefas), `pelizzai-debugging` (fecha o track de bug após o fix verificado), `pelizzai-quick-fix` (fecha o track de ajuste).

**Combina com:** `pelizzai-starting-branch` (abre a branch que esta skill fecha), `pelizzai-verification-before-completion` (verifica os testes), `pelizzai-oswap` (segurança), `pelizzai-frontend` (UI), `pelizzai-resolving-merge-conflicts` (se o push/integração gerar conflito), `pelizzai-writing-skills` (cadência de revisão de skills).
