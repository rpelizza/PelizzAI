---
name: pelizzai-starting-branch
description: Use antes do primeiro artefato de uma tarefa que poderá gerar commits. Detecta workspace multi-projeto e confirma com o usuário o conjunto afetado, descobre a base real do repositório, cria a branch de tarefa/planejamento e, após o plano, mantém a branch no working tree atual ou a move com segurança para um worktree. Nunca impõe develop nem trabalha em HEAD destacado/protegido.
---

# PelizzAI Starting Branch

## Objetivo

Criar o isolamento **antes de spec, plano ou código**, a partir de uma base comprovada. A mesma
branch começa como branch de tarefa/planejamento; se o usuário escolher worktree depois do plano,
o worktree é criado **dessa branch**, preservando os artefatos já produzidos.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Starting Branch para preparar o isolamento desta tarefa."

## Invariantes

```text
- Uma tarefa = um repositório Git. Monorepo é um repositório; workspace multi-repo abre um
  state/registro de execução por repositório. Não esconda uma lista no campo project.
- Workspace é detectado, nunca presumido: marcadores no cwd e um nível acima (§2). O conjunto de
  projetos afetados é SEMPRE confirmado com o usuário; o `pelizzai/` é root-level do workspace.
- base-ref e base-sha são resolvidos antes da primeira mudança e não mudam durante a tarefa.
- branch é criada antes de spec/plano/código. Durante o planejamento, isolation pode ficar pending.
- Worktree pós-plano reutiliza a branch existente; não cria uma branch vazia a partir da base.
- Esta skill não usa `git pull`. Atualização remota é `git fetch <remote> <ref>` explícito.
- Nunca use checkout destacado seguido de pull; remote-only vira start-point ou branch local tracking.
- Nunca reset/delete/stash automaticamente para “arrumar” uma base ou liberar um worktree.
- Em source mode, não crie runtime `pelizzai/`; devolva branch/base/isolation ao execution record
  nativo. Campos de state abaixo valem para projeto consumidor.
```

## 1. Identificar o único repositório

```bash
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git worktree list --porcelain
git remote -v
```

Se não for Git, ofereça `git init` antes de escrever. Se a pasta contiver vários repositórios e o
escopo do pedido não identificar um deles sem ambiguidade, confirme **qual único repositório**
pertence à tarefa atual; abra tarefas separadas para os demais.

HEAD vazio/destacado, rebase/merge em curso ou branch protegida (`main`, `master`, `develop`,
`dev` **e o default real descoberto no §3**, como `trunk`) nunca é destino de commits. Se já houver mudanças, preserve-as criando a branch de tarefa a
partir do HEAD atual após confirmação. Se já houver commits indevidos na protegida, crie a branch
de resgate e pare: entregue um handoff para o humano reconciliar a protegida. Não rode
`reset --hard`, não force branch e não apague histórico.

Se já estiver numa branch não protegida, confirme se ela é a branch desta tarefa. Reutilize apenas
quando a resposta e o registro disponível concordarem (`state.md` no consumidor; execution record
nativo em source mode). Sem registro anterior, use a evidência de Git + titularidade explícita das
mudanças; branch/sujeira ambígua não é adotada por palpite.

## 2. Detectar workspace multi-projeto

Uma tarefa continua pertencendo a **um** repositório Git (§1) — isso não muda. O que o harness
precisa saber antes de criar qualquer coisa é se esse repositório vive dentro de um **workspace**:
o workspace decide onde o `pelizzai/` mora e quais projetos o pedido realmente toca. Verifique os
marcadores no cwd e um nível acima:

```bash
marcadores="package.json pnpm-workspace.yaml turbo.json lerna.json nx.json pyproject.toml Cargo.toml go.work"
ls $marcadores 2>/dev/null             # cwd
(cd .. && ls $marcadores 2>/dev/null)  # um nível acima
find . -maxdepth 2 -name ".git"        # irmãos com repositório próprio (dir ou arquivo de worktree)
```

Havendo workspace ou múltiplos projetos:

```text
1. Infira da descrição da tarefa quais projetos são afetados (nome de diretório/pacote, menção a
   frontend/backend/worker etc.). Inferir serve para montar a lista candidata, nunca para fechá-la.
2. SEMPRE confirme com o usuário o conjunto afetado antes de prosseguir. O conjunto é decisão
   dele: apresente a lista inferida com a recomendação e aguarde. Conjunto adivinhado é lacuna
   material — vai para a `pelizzai-interview-me`, não para um default.
3. Workspace de múltiplos repositórios Git: cada projeto afetado ganha isolamento próprio. Rode
   §1 e §3–§8 de forma independente por repositório, e abra um registro de execução (state
   consumidor ou execution record nativo) por repositório. Não esconda uma lista no campo `project`.
4. Monorepo (um repositório Git, vários pacotes): o isolamento é único — uma branch cobre os
   pacotes tocados. A confirmação do conjunto afetado continua valendo; ela delimita o escopo do
   diff, não o número de branches.
```

O `pelizzai/` é **root-level do workspace**, não um por pacote: `domain-skills.md`, `profile.md` e
`data/` vivem na raiz declarada dona dos artefatos — é essa raiz que a `pelizzai-audit` mapeia e é
por ela que o hook de cadência localiza o ledger (ele resolve pelo `cwd` assumindo `pelizzai/` na
raiz). Em workspace com múltiplos repositórios, um state escalar não cobre todos: ou se faz
bootstrap por repo, ou se declara explicitamente a raiz dona.

Nomes: use o mesmo `<tipo>/<slug>` em todos os projetos afetados, a menos que o usuário peça nomes
específicos por projeto.

## 3. Descobrir a base real

Não use a preferência histórica `develop > dev > main`. Descubra o default do repositório:

```bash
# Execute apenas se `origin` existir; falha de rede não invalida refs locais já conhecidas.
git fetch origin --prune
git symbolic-ref --quiet --short refs/remotes/origin/HEAD

# Só se origin/HEAD estiver ausente: consulta o HEAD anunciado pelo remoto, sem checkout.
git remote show origin

# Fallback local: é apenas um nome candidato e só vale se a ref correspondente existir.
git config --get init.defaultBranch

# Inventário para confirmar candidatos e evitar adivinhação.
git for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin
```

Algoritmo:

1. Se `origin/HEAD` resolver para commit, proponha essa ref.
2. Se estiver ausente, use o `HEAD branch` anunciado por `git remote show origin`, desde que
   `origin/<nome>` resolva.
3. Sem default remoto, aceite `init.defaultBranch` somente se `refs/heads/<nome>` ou
   `refs/remotes/origin/<nome>` existir.
4. Sem candidato inequívoco, mostre as refs existentes e pergunte a base. Nunca crie `develop`
   como convenção do harness.
5. Com candidato inequívoco e atual, apresente ref + SHA com recomendação e faça uma pergunta:
   "Confirma esta base?". Aguarde. Uma base materialmente diferente é um recomeço explícito;
   `base-ref`/`base-sha` continuam imutáveis durante a tarefa.

O nome apontado pelo default descoberto passa a ser tratado como branch protegida pelo harness,
mesmo que não se chame main/master/develop/dev.

Para uma base remota, atualize só ela e use a remote-tracking ref como start-point:

```bash
git fetch origin <nome-da-base>
base_ref=origin/<nome-da-base>
base_sha=$(git rev-parse "$base_ref^{commit}")
```

Para base puramente local:

```bash
base_ref=refs/heads/<nome-da-base>
base_sha=$(git rev-parse "$base_ref^{commit}")
```

`base-ref` registra a ref efetivamente usada e `base-sha` registra o SHA completo. Se o fetch
falhar, apresente a idade/limitação da ref local e peça confirmação; não finja que ela está atual.

## 4. Nomear a branch de tarefa/planejamento

Depois de ratificar a base, derive `<tipo>/<slug-kebab>` (ASCII, minúsculo, até 50 caracteres).
Apresente o nome recomendado com motivo e faça uma única pergunta: "Confirma este nome?". Só crie
a branch após resposta afirmativa. Não trave nome/base em silêncio. O tipo vem do efeito real:

| Natureza | Tipo sugerido |
| --- | --- |
| feature | `feat` |
| bug | `fix` |
| refactor | `refactor` |
| docs apenas | `docs` |
| teste apenas | `test` |
| tooling/config/deps | `chore`, `build` ou `ci` |
| performance | `perf` |

## 5. Abrir a branch antes do planejamento

Para tracks com spec/plano, após base e nome ratificados, crie a branch no working tree atual
**antes** de escrever esses artefatos. A escolha de manter branch ou mover para worktree continua
pendente até o gate pós-plano:

```bash
git switch -c <tipo>/<slug> --no-track <base-ref>
```

Em consumidor, registre imediatamente `project`, `branch`, `base-ref`, `base-sha`,
`validated-head: <none>`, `isolation: <pending>` e `worktree-path: <none>`. Em source mode,
devolva esses valores ao execution record sem criar state. Specs/planos persistentes e state
consumidor agora nascem na branch que futuramente alimentará o worktree.

Para um fluxo direto sem planejamento, aplique já a escolha de isolamento:

- Branch: use o comando acima e registre `isolation: branch`.
- Worktree: `git worktree add -b <branch> <caminho-fora-do-repo> <base-ref>` e registre o caminho.

Em consumidor, **grave** o `state.md` com suas ferramentas de arquivo e siga — gravar basta. **Não
crie commit só de metadata** (`chore: inicia tarefa <slug>`): o cursor viaja no primeiro commit de
conteúdo da tarefa, junto aos paths exatos que ele descreve. Ele é metadata do harness, não conteúdo
da entrega — se aparecer no pacote de review da Tarefa 1, é ruído conhecido, nunca motivo para um
commit extra. Em source mode, não há state nem commit de setup; branch/worktree + execution record
bastam.

## 6. Aplicar o isolamento escolhido após o plano

O nome e a base já foram ratificados antes da branch de planejamento. Se o usuário pedir renomear
depois, use `git branch -m <novo-nome>` após confirmação; nunca `-M`. A base não é reescrita aqui.

### Manter como branch

Confirme que `git branch --show-current` é a branch registrada e, em consumidor, grave
`isolation: branch` mais as decisões do gate. Antes da Tarefa 1, faça checkpoint dos artefatos
intencionais de planejamento/state com paths exatos e exija working tree limpa. Em source mode,
checkpoint apenas um plano persistente explicitamente pedido; plano nativo não gera arquivo.
Não recrie a branch nem recalcule a base.

### Mover a branch existente para um worktree

1. Na branch de tarefa, faça checkpoint **somente quando existirem** artefatos persistentes
   intencionais de planejamento (`plan`, spec/ADR e, no consumidor, `state.md`). Use paths exatos;
   nunca `git add -A`. Plano nativo em source mode não cria commit vazio.
2. Se houver artefatos, inspecione `git diff --cached` e crie o commit. Se o usuário não autorizar
   esse checkpoint, mantenha `isolation: branch`; mudanças não commitadas não atravessam
   worktrees. Com ou sem novo commit, capture `checkpoint-sha = git rev-parse HEAD`.
3. Exija `git status --porcelain` vazio. Mudança estranha ou alheia gera handoff/decisão humana;
   não faça stash automático.
4. Libere a branch no working tree principal:
   - base local existente: `git switch <nome-local-da-base>`;
   - base somente remota: crie a local tracking sem detached HEAD,
     `git switch -c <nome-da-base> --track <base-ref>`;
   - base que seja tag/SHA ou nome local colidente: pare e combine uma branch de estacionamento.
5. Crie o worktree **com a branch existente**, sem `-b`:

```bash
git worktree add <caminho-fora-do-repo> <tipo>/<slug>
```

6. Dentro dele, confirme branch, `HEAD == checkpoint-sha` e presença dos artefatos persistentes,
   quando existirem.
7. Em consumidor, grave `isolation: worktree` e `worktree-path` no `state.md` dentro do worktree —
   sem commit de metadata; esse toque entra no primeiro commit de conteúdo. Antes da Tarefa 1, exija
   que nada além dele esteja sujo. Em source mode, atualize apenas o execution record nativo; não
   crie state.

O caminho fica fora da árvore do repositório. Se o ambiente bloquear a criação, informe e peça
confirmação para permanecer em branch; não degrade em silêncio.

## 7. Baseline proporcional

Antes da implementação, rode a evidência de baseline apropriada ao artefato e ao perfil do projeto:
suíte/teste focal para comportamento, characterization para legado, parser/dry-run para config,
render/lint para docs e aplicação rodando para UI. Baseline falho é reportado antes da mudança; o
usuário decide investigar ou prosseguir com a falha registrada.

## 8. Estado e reporte

Em consumidor, o `state.md` final do setup contém:

```text
project: <raiz deste único repo>
branch: <tipo>/<slug>
base-ref: <ref exata>
base-sha: <SHA completo>
validated-head: <none>
isolation: <branch | worktree>
worktree-path: <none | caminho>
```

Reporte branch, base-ref + base-sha, isolamento, caminho e baseline. Em source mode, este reporte
é o execution record. Em retomada, compare os dados persistidos/nativos com Git; divergência
material chama `pelizzai-recovery`, não heurística.

## Red flags

```text
- Impor/criar develop porque “é a convenção”.
- `git pull` sem remote/ref explícitos, ou pull em HEAD destacado.
- Escrever spec/plano na base e só depois criar uma branch vazia/worktree da base.
- Criar worktree pós-plano com `-b` a partir da base, perdendo a branch de planejamento.
- Recalcular base-sha no fechamento; ele é um snapshot do início.
- Pular a detecção de workspace, ou fechar sozinho o conjunto de projetos afetados sem confirmar.
- Espalhar um `pelizzai/` por pacote em vez de mantê-lo na raiz do workspace.
- Misturar vários repositórios em um único state.
- `git add -A`, stash, reset, force-delete ou limpeza automática para liberar o worktree.
- Criar a branch antes de o usuário ratificar base e nome recomendados.
```

## Integração

**Chamada por:** router antes de brainstorming/spec/plano; `pelizzai-execution-plans` no gate
pós-plano; debugging/quick-fix antes de escrever código.

**Combina com:** `pelizzai-execution-plans`, `pelizzai-recovery`, `pelizzai-finish-task` e
`pelizzai-audit`.
