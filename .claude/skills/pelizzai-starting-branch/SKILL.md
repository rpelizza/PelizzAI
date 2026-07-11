---
name: pelizzai-starting-branch
description: Use antes do primeiro artefato de uma tarefa que poderá gerar commits. Descobre a base real do repositório, cria a branch de tarefa/planejamento e, após o plano, mantém a branch no working tree atual ou a move com segurança para um worktree. Nunca impõe develop nem trabalha em HEAD destacado/protegido.
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
`dev` **e o default real descoberto no §2**, como `trunk`) nunca é destino de commits. Se já houver mudanças, preserve-as criando a branch de tarefa a
partir do HEAD atual após confirmação. Se já houver commits indevidos na protegida, crie a branch
de resgate e pare: entregue um handoff para o humano reconciliar a protegida. Não rode
`reset --hard`, não force branch e não apague histórico.

Se já estiver numa branch não protegida, confirme se ela é a branch desta tarefa. Reutilize apenas
quando a resposta e o registro disponível concordarem (`state.md` no consumidor; execution record
nativo em source mode). Sem registro anterior, use a evidência de Git + titularidade explícita das
mudanças; branch/sujeira ambígua não é adotada por palpite.

## 2. Descobrir a base real

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
5. Com candidato inequívoco e atual, use-o e reporte ref + SHA; não transforme o default comprovado
   em pergunta. Pergunte somente quando houver ambiguidade, ref possivelmente obsoleta ou conflito
   com uma preferência explícita.

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

## 3. Nomear a branch de tarefa/planejamento

Derive `<tipo>/<slug-kebab>` (slug ASCII, minúsculo, até 50 caracteres) e use-o quando estiver
livre. Informe o nome; pergunte somente em colisão, convenção incompatível ou preferência explícita.
O tipo vem do efeito real da tarefa, não de preferência fixa:

| Natureza | Tipo sugerido |
| --- | --- |
| feature | `feat` |
| bug | `fix` |
| refactor | `refactor` |
| docs apenas | `docs` |
| teste apenas | `test` |
| tooling/config/deps | `chore`, `build` ou `ci` |
| performance | `perf` |

## 4. Abrir a branch antes do planejamento

Para tracks com spec/plano, crie a branch no working tree atual **antes** de escrever esses
artefatos. A escolha branch/worktree continua pendente até o gate pós-plano:

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

Em consumidor, antes da primeira mutação do produto, estagie somente `state.md`, inspecione e faça
um commit metadata de setup (`chore: inicia tarefa <slug>`). Exija working tree limpa. Isso impede
que o state inicial contamine o review do bug/ajuste/bootstrap. Em source mode, não há state nem
commit de setup; branch/worktree + execution record bastam.

## 5. Aplicar o isolamento escolhido após o plano

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
7. Em consumidor, grave `isolation: worktree` e `worktree-path`, estagie somente `state.md`,
   inspecione e faça um commit metadata de setup. Exija working tree limpa antes da Tarefa 1.
   Em source mode, atualize apenas o execution record nativo; não crie state.

O caminho fica fora da árvore do repositório. Se o ambiente bloquear a criação, informe e peça
confirmação para permanecer em branch; não degrade em silêncio.

## 6. Baseline proporcional

Antes da implementação, rode a evidência de baseline apropriada ao artefato e ao perfil do projeto:
suíte/teste focal para comportamento, characterization para legado, parser/dry-run para config,
render/lint para docs e aplicação rodando para UI. Baseline falho é reportado antes da mudança; o
usuário decide investigar ou prosseguir com a falha registrada.

## 7. Estado e reporte

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
- Misturar vários repositórios em um único state.
- `git add -A`, stash, reset, force-delete ou limpeza automática para liberar o worktree.
```

## Integração

**Chamada por:** router antes de brainstorming/spec/plano; `pelizzai-execution-plans` no gate
pós-plano; debugging/quick-fix antes de escrever código.

**Combina com:** `pelizzai-execution-plans`, `pelizzai-recovery`, `pelizzai-finish-task` e
`pelizzai-audit`.
