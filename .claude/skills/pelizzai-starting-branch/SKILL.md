---
name: pelizzai-starting-branch
description: Use ao iniciar qualquer tarefa que vá gerar commits, ANTES de qualquer mudança de código. Protege contra commits em branch protegida (main/master/develop/dev — fail-closed inclusive em HEAD destacado/rebase), cria uma branch nomeada por conventional commit a partir da base certa, e trata workspaces multi-projeto. Política do harness: trabalhamos SÓ com branches (sem worktrees). Registra a isolação em `pelizzai/data/state.md`. Acione também quando o usuário disser "criar a branch", "começar a tarefa", ou antes de `pelizzai-execution-plans`.
---

# PelizzAI Starting Branch

## Objetivo

Antes de qualquer tarefa tocar no código, garantir que o trabalho aconteça em uma **branch de feature bem nomeada, a partir da base certa**. Nunca commitar direto em branch protegida.

**Anuncie ao iniciar:** "Usando a skill Pelizzai Starting Branch para preparar a branch desta tarefa."

> **Política do harness:** trabalhamos **somente com branches** — sem `git worktree`. A isolação é sempre `branch` (troca no lugar). Não crie nem proponha worktrees.

---

## Princípio central

> Detectar a branch atual → identificar a base → inferir os projetos afetados → propor o nome → confirmar com o usuário → criar. Nunca assuma a base nem o nome; nunca commite em branch protegida.

---

## Gate de branch protegida (fail-closed, não-negociável)

Antes de qualquer `git add`/commit, rode `git branch --show-current`. Se for `main`, `master`, `develop`, `dev` — **ou vazio** (HEAD destacado / meio de rebase → fail-closed, trate como NÃO seguro) → **pare e crie uma branch antes de qualquer mudança**. Não há exceção, nem para tarefa trivial.

---

## Processo

### 1. Detectar o estado atual

```bash
git rev-parse --is-inside-work-tree
current=$(git branch --show-current)
git branch --list develop dev main master                                   # candidatas locais
git remote -v
git branch -r --list "origin/develop" "origin/dev" "origin/main" "origin/master"  # candidatas só no remoto (se houver remoto)
```

Uma base conta como existente se estiver **local OU no remoto** — uma `develop`/`dev` só no remoto é base válida (branch a partir de `origin/develop`).

- **Não é repositório git** (`git rev-parse` falha): se a tarefa vai gerar código, ofereça em linguagem simples iniciar o versionamento com `git init` antes de qualquer mudança. Sem repositório não há proteção de histórico nem branch.
- `current` é protegida (`main`/`master`/`develop`/`dev`) ou vazia → **crie uma nova branch antes de qualquer mudança** (siga para o passo 2).
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
3. Para cada projeto afetado, rode os passos 1-2 e 4-6 de forma independente — cada projeto ganha sua branch.
```

### 4. Escolher o tipo de conventional commit

Peça ao usuário o tipo que casa com a tarefa:

| Tipo       | Para                                  |
| ---------- | ------------------------------------- |
| `feat`     | Nova funcionalidade                   |
| `fix`      | Correção de bug                       |
| `chore`    | Tooling, deps, build, config          |
| `docs`     | Apenas documentação                   |
| `refactor` | Mudança sem alterar comportamento     |
| `test`     | Adicionar/corrigir testes             |
| `perf`     | Melhoria de performance               |
| `ci`       | Configuração de CI                    |
| `build`    | Mudanças no sistema de build          |
| `style`    | Apenas formatação                     |
| `revert`   | Reverter commit anterior              |

### 5. Propor o nome da branch

Formato: `<tipo>/<slug-kebab-curto>` (slug ≤ 50 chars, ASCII, minúsculo, hífens). Gere o slug da descrição, mostre ao usuário e peça confirmação ou alternativa. Exemplos:

```text
feat/customer-export-csv
fix/login-redirect-loop
chore/upgrade-angular-19
```

### 6. Criar a branch

Isolação = **branch** (sempre). Troca no lugar:

```bash
git fetch origin                      # só se houver remoto
git checkout <base>
git pull --ff-only                    # só se houver remoto
git checkout -b <tipo>/<slug>
```

Multi-projeto: repita por projeto. Use o mesmo `<tipo>/<slug>` em todos, a menos que o usuário peça nomes específicos por projeto.

### 7. Registrar no estado

Grave em `pelizzai/data/state.md` (com suas ferramentas de arquivo): `branch: <tipo>/<slug>` e `isolation: branch`. Isso fecha o ciclo do estado: a `pelizzai-finish-task` lê esses campos ao consolidar, e a `pelizzai-execution-plans` valida `branch` contra o git ao retomar. Se `pelizzai/data/state.md` ainda não existir, instancie-o a partir do template da `pelizzai-execution-plans` antes de gravar.

### 8. Reportar

```text
Branch criada: <tipo>/<slug>
Base: <base>
Projetos: <lista>
Pronto para começar a tarefa.
```

---

## Referência rápida

| Situação                              | Ação                                         |
| ------------------------------------- | -------------------------------------------- |
| Em `main`/`master`/`develop`/`dev`    | Criar nova branch — nunca commitar aqui      |
| HEAD destacado / vazio                | Fail-closed: tratar como NÃO seguro, criar branch |
| Já em uma feature branch              | Perguntar: continuar ou nova branch          |
| `develop` existe                      | Usar como base                               |
| Só `main`/`master`                    | Oferecer criar `develop` primeiro            |
| Workspace multi-projeto               | Confirmar conjunto afetado, fluxo por projeto |
| `gh`/remoto sem autenticação          | Pular operações de remoto; seguir só local   |

---

## Sinais de alerta (red flags)

**Nunca:**

- Commitar direto em `main`, `master`, `develop` ou `dev` (nem em HEAD destacado).
- Criar a branch sem confirmar o tipo e o nome com o usuário.
- Rodar `git checkout -b` sem `git pull --ff-only` na base primeiro (quando há remoto).
- Pular a detecção de multi-projeto em workspaces.
- Assumir a base — sempre confirme.
- Propor ou criar worktrees — o harness trabalha só com branches.

---

## Integração

**Chamada por:**

- `pelizzai-execution-plans` — OBRIGATÓRIA antes de executar o plano (isolamento).
- Qualquer fluxo que vá produzir commits.

**Combina com:**

- `pelizzai-finish-task` — fecha a branch (squash e escolha de destino push/PR/local/descartar).
- `pelizzai-audit` — padrão de diretório `pelizzai/` e o `pelizzai/data/state.md`.
