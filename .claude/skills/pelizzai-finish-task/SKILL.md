---
name: pelizzai-finish-task
description: Use depois que overlays, consolidação e validação final selaram o conteúdo em validated-head. No consumidor, fecha o cursor com um commit metadata-only de state.md; no repo-fonte, valida o seal sem criar runtime/closure. Mantém local por default ou publica/abre PR com autorização. Nunca altera conteúdo ou histórico depois do seal.
---

# PelizzAI Finish Task

## Objetivo

Integrar **o conteúdo que foi validado**, sem uma última rodada oculta de mutações. Squash,
security, frontend, documentação, fixes e testes pertencem ao fluxo anterior. Esta skill:

```text
consumer: validated-head → closure só de state.md → delivery-head
source:   validated-head ─────────────────────────→ delivery-head
```

**Anuncie ao iniciar:** "Usando a skill PelizzAI Finish Task para integrar o conteúdo já validado."

## Source mode — sem runtime consumidor

Se o sentinel do repo-fonte estiver presente, não procure/crie `pelizzai/data/state.md`. Receba do
execution record `branch`, `base-ref`, `base-sha` e `validated-head`; exija branch segura,
`git rev-parse HEAD == validated-head` e working tree limpa. Defina
`delivery-head=validated-head`, pule o closure commit e vá direto a
**Resolver o destino**. Sem pedido externo, mantenha local. Ao terminar, marque o execution record
`phase: done` com `validated-head`, `delivery-head` e status do destino. Qualquer divergência volta
ao lifecycle.

As seções de state/closure abaixo são exclusivas do projeto consumidor.

## Invariantes

```text
- Uma tarefa/state representa um único repositório Git.
- Ao entrar, HEAD == validated-head.
- A única sujeira permitida é pelizzai/data/state.md com o seal ainda não commitado.
- Depois do seal, não roda squash/rebase/reset, overlay, formatter, codegen, teste que escreva
  snapshot, doc generator nem fix.
- O único commit novo toca somente pelizzai/data/state.md.
- Manter local é o default sem efeito externo. Push/PR/remover worktree/descarte exigem decisão explícita.
- Nunca use reset --hard, branch -D, worktree remove --force ou stash automático.
```

## 1. Gate fail-closed do conteúdo selado

Leia `project`, `branch`, `base-ref`, `base-sha`, `validated-head`, `isolation` e
`worktree-path` do state. Confirme que `project` é a raiz do repositório atual e rode:

```bash
git branch --show-current
git rev-parse HEAD
git rev-parse "<base-sha>^{commit}"
git rev-parse "<validated-head>^{commit}"
git status --porcelain --untracked-files=all
git diff --name-only
git diff --cached --name-only
```

Pare e volte ao fluxo que valida quando qualquer item falhar:

- branch vazia/protegida (`main`, `master`, `develop`, `dev` ou o nome de `base-ref`) ou diferente do state;
- `validated-head` ausente, abreviado, inválido ou diferente de `git rev-parse HEAD`;
- mudança staged;
- arquivo alterado/untracked diferente de `pelizzai/data/state.md`;
- evidência de review/checklist/verification anterior ao último fix;
- overlay aplicável ainda pendente.

Se `commit-strategy: squash-final`, confirme que a consolidação ocorreu **antes** do seal (em
geral, um commit de conteúdo no range `base-sha..validated-head`). Não tente corrigir o histórico
aqui; volte à `pelizzai-execution-plans` e revalide o novo candidato.

Se houver commits indevidos numa branch protegida, preserve-os criando uma branch de resgate e
pare. Entregue instruções manuais para reconciliar a protegida; não faça reset automático.

## 2. Closure commit metadata-only

No `pelizzai/data/state.md` já modificado pelo seal:

1. Preserve `validated-head`, `base-ref`, `base-sha`, branch e decisões da tarefa.
2. Acrescente ao Histórico uma linha datada de conclusão, sem prometer push/PR ainda.
3. Defina `slug: <none>` e `phase: done`.
4. Limpe `delivered`/`next`/`pending` para os placeholders da próxima tarefa e atualize a data.

Estagie **somente** o state:

```bash
git add -- pelizzai/data/state.md
git diff --cached --name-only
git commit -m "chore: fecha tarefa no cursor"
```

Antes de oferecer destino, prove as três guardas:

```bash
# deve listar exatamente pelizzai/data/state.md
git diff --name-only <validated-head>..HEAD

# nenhuma diferença de produto fora do state
git diff --quiet <validated-head>..HEAD -- . ':(exclude)pelizzai/data/state.md'

# deve estar vazio
git status --porcelain --untracked-files=all
```

Grave `closure-head=$(git rev-parse HEAD)` e `delivery-head=$closure-head` apenas para as operações desta execução. Hook que
incluiu outro arquivo ou deixou sujeira invalida o fechamento; pare, não faça outro commit corretivo.

## 3. Resolver o destino

Se o usuário não pediu publicação, PR, integração ou descarte, **mantenha local** e reporte branch,
`validated-head` e `delivery-head` (mais `closure-head` no consumidor); não interrompa com menu.

Quando houver intenção externa já expressa, confirme somente o alvo que ainda for materialmente
ambíguo. Se o usuário pediu opções, apresente:

```text
Como integrar o conteúdo validado?

1. Publicar esta branch sem abrir PR
2. Publicar esta branch e abrir Pull Request
3. Manter local
4. Preparar descarte/arquivamento manual

Qual opção?
```

Imediatamente antes de qualquer efeito externo, repita:

```bash
test "$(git rev-parse HEAD)" = "<delivery-head>"
git status --porcelain --untracked-files=all
```

No consumidor, repita também `git diff --name-only <validated-head>..<delivery-head>` e exija
somente `pelizzai/data/state.md`. No source mode, exija `delivery-head == validated-head`.
Divergiu? Pare; não publique.

### 3a. Publicar sem PR

Isto publica **a task branch**, não faz merge/push direto na base. Exija remoto `origin` conhecido e
empurre o SHA fechado por refspec explícito:

```bash
git push origin <delivery-head>:refs/heads/<branch>
git branch --set-upstream-to=origin/<branch> <branch>
```

Depois, confirme que `refs/heads/<branch>` no remoto aponta para `delivery-head` e registre
`delivery-status: pushed`. Non-fast-forward, auth, rede ou SHA remoto divergente falha de forma
fechada; não force-push.

### 3b. Publicar e abrir PR

Faça o mesmo push exato e derive o nome de base de `base-ref` (por exemplo,
`origin/trunk` → `trunk`). Depois:

```bash
gh pr create --head <branch> --base <nome-da-base> --title "..." --body "..."
```

O body contém resumo e evidência/como testar. Sem autenticação, reporte o bloqueio; não troque o
destino sozinho.

Com sucesso, capture a URL retornada, confira head/base do PR e registre
`delivery-status: pr-open` + URL. Essa mesma transição fecha uma retomada que estava `partial`.

Push e criação do PR são checkpoints separados. Se o push foi confirmado e `gh pr create` falhar,
registre/reporte `delivery-status: partial`, branch remota + SHA e erro do PR: o conteúdo já foi
publicado, mas o PR não foi criado. Em retomada, reconcilie branch remota e PR existente; pule o
push já confirmado e repita só a criação do PR. Não revalide conteúdo, não crie outro commit de
state e não mude o destino por conta própria.

### 3c. Manter local

Não faça efeito externo. Reporte branch, `validated-head` e `delivery-head`; em source mode registre
`delivery-status: local`.

### 3d. Preparar descarte/arquivamento

Peça a confirmação literal `descartar`. Mesmo confirmada, o harness não força deleção:

- ofereça manter/renomear a branch como arquivo local;
- se já estiver integrada, `git branch -d` é a única deleção automática aceitável;
- se não estiver integrada, entregue ao usuário o comando manual de `branch -D` e seus SHAs,
  mas não o execute;
- worktree sujo nunca é removido; worktree limpo segue o gate do §4, sem `--force`.

## 4. Worktree

Depois de publicar ou manter a branch segura, ofereça remover o worktree. Confirme novamente,
saia para o repositório principal, verifique que ele está limpo e use somente:

```bash
git worktree remove <caminho>
```

Falha significa parar e reportar. Não use `--force`. Não crie outro commit para limpar
`worktree-path`; o state fechado é histórico da execução e será sobrescrito pela próxima tarefa.

## 5. Nudge de manutenção (read-only)

No consumidor, após o destino, verifique o ledger de domain skills. Se os limiares documentados
em `pelizzai-writing-skills` estiverem vencidos, sugira uma vez; não bloqueie nem altere a entrega.
Source mode ou ledger ausente: no-op silencioso.

## Red flags

```text
- Oferecer OWASP/frontend/docs aqui; já é tarde, volte e revalide.
- Squash/reset/rebase/amend depois de validated-head.
- `git add -A` no closure commit.
- Segundo commit de cursor para registrar o destino.
- Push de HEAD sem comparar com delivery-head ou push direto na base.
- Force-push, branch -D, worktree --force, stash/reset automático.
- Tratar vários repositórios como uma só tarefa.
```

## Integração

**Chamada por:** `pelizzai-execution-plans`, `pelizzai-debugging` e `pelizzai-quick-fix`, somente
depois de seus overlays e validação gravarem `validated-head`.

**Combina com:** `pelizzai-starting-branch`, `pelizzai-verification-before-completion`,
`pelizzai-review`, `pelizzai-recovery` e `pelizzai-resolving-merge-conflicts`.
