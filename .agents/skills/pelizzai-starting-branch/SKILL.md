---
name: pelizzai-starting-branch
description: Use ao iniciar qualquer tarefa que vá gerar commits, ANTES de qualquer mudança de código. Cria o isolamento seguro da tarefa (branch normal ou git worktree) e protege contra commits em branch protegida (main/master/develop/dev — fail-closed inclusive em HEAD destacado/rebase), também em workspaces multi-projeto. Acione também quando o usuário disser "criar a branch", "criar o worktree", "começar a tarefa", ou dentro do gate de setup pós-plano da `pelizzai-execution-plans`.
---

# PelizzAI Starting Branch

## Objetivo

Antes de qualquer tarefa tocar no código, garantir que o trabalho aconteça **isolado** — numa **branch bem nomeada a partir da base certa**, ou num **worktree** dedicado quando o usuário escolher paralelismo isolado. Nunca commitar direto em branch protegida.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Starting Branch para preparar o isolamento desta tarefa."

> **Política do harness:** o isolamento é uma **escolha do usuário** — `branch` (troca no lugar) ou `worktree` (working tree isolado). A decisão vem registrada em `pelizzai/data/state.md` (gate do router ou gate de setup pós-plano). Se não houver decisão registrada (entrada direta, ou sobra de tarefa já fechada), **pergunte aqui** antes de criar.

---

## Princípio central

> Detectar a branch atual → identificar a base → confirmar o isolamento (branch/worktree) → inferir os projetos afetados → sugerir o tipo e o nome → confirmar com o usuário → criar. Nunca assuma a base nem o nome; nunca commite em branch protegida.

---

## Gate de branch protegida (fail-closed, não-negociável)

Antes de qualquer `git add`/commit, rode `git branch --show-current`. Se for `main`, `master`, `develop`, `dev` — **ou vazio** (HEAD destacado / meio de rebase → fail-closed, trate como NÃO seguro) → **pare e crie o isolamento antes de qualquer mudança**. Não há exceção, nem para tarefa trivial.

---

## Processo

### 0. Confirmar o isolamento (branch ou worktree)

Leia `isolation` em `pelizzai/data/state.md`:

```text
- isolation: branch ou worktree (desta tarefa, registrado pelo gate) → honre, não re-pergunte.
- isolation: <pending>, ausente, ou sobra de tarefa fechada (slug: <none> / phase: done) → PERGUNTE:

  Como você prefere trabalhar nesta tarefa?
  1. Branch — troca no lugar, no working tree atual (recomendado para a maioria)
  2. Worktree — uma cópia isolada do projeto em outra pasta; vale a pena quando partes
     independentes podem ser construídas em paralelo

- Track ajuste: não pergunte — isolamento é branch, apenas avise ("Como é um ajuste pontual,
  vou trabalhar numa branch").

Menu canônico: pelizzai-execution-plans, Gate de setup pós-plano (o resumo acima é para a
entrada direta, quando não há decisão registrada).
```

### 1. Detectar o estado atual

```bash
git rev-parse --is-inside-work-tree
current=$(git branch --show-current)
git worktree list                                                            # worktrees já existentes
git branch --list develop dev main master                                   # candidatas locais
git remote -v
git branch -r --list "origin/develop" "origin/dev" "origin/main" "origin/master"  # candidatas só no remoto (se houver remoto)
```

Uma base conta como existente se estiver **local OU no remoto** — uma `develop`/`dev` só no remoto é base válida (branch a partir de `origin/develop`). Só caia no menu do Passo 2 quando **nem local nem remoto** tiverem candidata.

- **Não é repositório git** (`git rev-parse` falha): se a tarefa vai gerar código, ofereça em linguagem simples iniciar o versionamento com `git init` antes de qualquer mudança. Sem repositório não há proteção de histórico, branch nem worktree. Se o usuário recusar, prossiga ciente de que não haverá proteção de histórico.
- **Já está num worktree isolado desta tarefa** (confira `git worktree list` contra o `state.md`): não crie outro — siga.
- `current` é protegida (`main`/`master`/`develop`/`dev`) ou vazia → **crie o isolamento antes de qualquer mudança** (siga para o passo 2).
- `current` já é uma feature branch → pergunte: "Continuar na branch `<current>` ou criar uma nova para esta tarefa?"

### 2. Detectar a base (automático, depois confirmar)

Ordem de prioridade:

```text
1. develop (local ou remoto) → propor como base
2. dev → propor como base
3. fallback → main ou master (a que existir)
```

Se só existir `main`/`master`, pergunte:

```text
Não encontrei `develop`. O que fazer?
1. Criar `develop` a partir de <default> e usar como base
2. Usar <default> mesmo como base
3. Outro nome de base (qual?)
```

Aguarde a resposta antes de prosseguir.

### 3. Workspaces multi-projeto

Verifique marcadores de workspace no cwd e um nível acima:

```bash
ls package.json pnpm-workspace.yaml turbo.json lerna.json nx.json pyproject.toml Cargo.toml go.work 2>/dev/null
find . -maxdepth 2 -name ".git" -type d
```

Se houver múltiplos projetos:

```text
1. Infira da descrição da tarefa quais projetos são afetados (nome de diretório/pacote, menção a frontend/backend/worker, etc.).
2. SEMPRE confirme com o usuário o conjunto afetado antes de prosseguir.
3. Para cada projeto afetado, rode os passos 1-2 e 4-7 de forma independente — cada projeto ganha seu isolamento.
```

### 4. Sugerir o tipo de conventional commit (a partir do track)

**Sugira** o tipo inferido do track já classificado pelo router e **peça confirmação** (não devolva a escolha crua ao usuário):

| Track / natureza da tarefa            | Tipo sugerido        |
| ------------------------------------- | -------------------- |
| feature                               | `feat`               |
| bug                                   | `fix`                |
| ajuste (correção óbvia / constante)   | `fix` ou `chore`     |
| refactor                              | `refactor`           |
| infra / tooling / deps / config       | `chore` / `build` / `ci` |
| só documentação                       | `docs`               |
| só testes                             | `test`               |
| performance                           | `perf`               |

Tabela completa disponível se o usuário quiser outro: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `ci`, `build`, `style`, `revert`.

### 5. Propor o nome da branch/worktree

Formato: `<tipo>/<slug-kebab-curto>` (slug ≤ 50 chars, ASCII, minúsculo, hífens). Gere o slug da descrição, mostre ao usuário e **peça confirmação ou alternativa**. O mesmo `<tipo>/<slug>` nomeia a branch e (se worktree) a pasta do worktree. Exemplos:

```text
feat/customer-export-csv
fix/login-redirect-loop
refactor/extract-billing-service
chore/upgrade-angular-19
```

### 6. Criar o isolamento

**6a. `isolation: branch`** — troca no lugar:

```bash
git fetch origin                      # só se houver remoto
git checkout <base>
git pull --ff-only                    # só se houver remoto
git checkout -b <tipo>/<slug>
```

**6b. `isolation: worktree`** — working tree isolado, **fora da árvore do repositório** (nunca dentro, para não poluir o scan/build):

```bash
git fetch origin                                        # só se houver remoto
git worktree add ../<repo>-worktrees/<tipo>-<slug> -b <tipo>/<slug> <base>
cd ../<repo>-worktrees/<tipo>-<slug>
```

Depois de criar o worktree, rode o **baseline** do projeto (instalar deps se preciso e a suíte de testes): se os testes já falham ANTES de qualquer mudança, **reporte e pergunte** se prossegue mesmo assim ou investiga primeiro — sem baseline verde, bugs novos e pré-existentes se confundem. Se o ambiente/sandbox bloquear a criação do worktree, **avise** e degrade para branch (com confirmação) — nunca falhe em silêncio.

Multi-projeto: repita por projeto. Use o mesmo `<tipo>/<slug>` em todos, a menos que o usuário peça nomes específicos por projeto.

### 7. Registrar no estado

Grave em `pelizzai/data/state.md` (com suas ferramentas de arquivo): `branch: <tipo>/<slug>`, `isolation: <branch | worktree>` e, se worktree, `worktree-path: <caminho>`. Isso fecha o ciclo do estado: a `pelizzai-finish-task` lê esses campos ao consolidar (e oferece remover o worktree no fechamento), e a `pelizzai-execution-plans` valida `branch`/worktree contra o git ao retomar. Se `pelizzai/data/state.md` ainda não existir, instancie-o a partir do template da `pelizzai-execution-plans` antes de gravar.

### 8. Reportar

```text
Isolamento pronto: <branch | worktree>
Branch: <tipo>/<slug>
Base: <base>
Worktree: <caminho, se aplicável>
Projetos: <lista>
Pronto para começar a tarefa.
```

---

## Referência rápida

| Situação                              | Ação                                         |
| ------------------------------------- | -------------------------------------------- |
| Em `main`/`master`/`develop`/`dev`    | Criar isolamento — nunca commitar aqui       |
| HEAD destacado / vazio                | Fail-closed: tratar como NÃO seguro, isolar  |
| Já em uma feature branch              | Perguntar: continuar ou nova branch          |
| Já num worktree desta tarefa          | Não criar outro; seguir                      |
| `isolation` ausente/`<pending>`       | Perguntar branch × worktree (menu do Passo 0)|
| Track ajuste                          | Branch direto, com alerta (não perguntar)    |
| `develop` existe                      | Usar como base                               |
| Só `main`/`master`                    | Oferecer criar `develop` primeiro            |
| Workspace multi-projeto               | Confirmar conjunto afetado, fluxo por projeto |
| `gh`/remoto sem autenticação          | Pular operações de remoto; seguir só local   |
| Sandbox bloqueia worktree             | Avisar e degradar para branch (confirmando)  |

---

## Erros comuns

| Erro                                           | Correção                                |
| ---------------------------------------------- | --------------------------------------- |
| Criar branch/worktree automaticamente sem confirmar | Sempre confirmar o tipo e o nome com o usuário |
| Usar `main` como base quando há `develop`      | Prioridade: develop > dev > main/master |
| Branch única para monorepo com vários projetos | Uma branch por projeto afetado          |
| Slug longo ou com caracteres especiais         | Máx 50 chars, ASCII, minúsculo, hífens  |
| Esquecer de dar pull na base antes de criar    | Sempre `git pull --ff-only` primeiro    |
| Worktree DENTRO da árvore do repositório       | Sempre fora: `../<repo>-worktrees/…`    |
| Um worktree POR SUBAGENTE                      | Um worktree por TAREFA; frentes paralelas escrevem em caminhos disjuntos dentro dele |

---

## Sinais de alerta (red flags)

**Nunca:**

- Commitar direto em `main`, `master`, `develop` ou `dev` (nem em HEAD destacado).
- Criar branch ou worktree sem confirmar o tipo e o nome com o usuário.
- Decidir o isolamento sozinho quando não há decisão registrada (pergunte — exceto no ajuste: branch com alerta).
- Rodar `git checkout -b` sem `git pull --ff-only` na base primeiro (quando há remoto).
- Criar worktree dentro da árvore do repositório, ou sem rodar o baseline de testes depois.
- Pular a detecção de multi-projeto em workspaces.
- Assumir a base — sempre confirme.

**Sempre:**

- Perguntar antes de criar `develop` se ela não existir.
- Confirmar o conjunto de projetos afetados em monorepo/multi-repo.
- Sugerir o tipo conventional a partir do track (e deixar o usuário trocar).
- Registrar `isolation` (e `worktree-path`, quando houver) no `state.md`.

---

## Integração

**Chamada por:**

- `pelizzai-execution-plans` — dentro do **gate de setup pós-plano**, logo após a pergunta de isolamento (OBRIGATÓRIA antes de executar o plano).
- `pelizzai-debugging` (Fase 4) e `pelizzai-quick-fix` (passo 1) — antes de qualquer mudança de código.
- Qualquer fluxo que vá produzir commits.

**Combina com:**

- `pelizzai-router` — decide/registra o isolamento (ou o marca `<pending>` para o gate pós-plano); esta skill executa.
- `pelizzai-finish-task` — fecha a branch (consolidação, destino push/PR/local/descartar e remoção opcional do worktree).
- `pelizzai-audit` — padrão de diretório `pelizzai/` e o `pelizzai/data/state.md`.
