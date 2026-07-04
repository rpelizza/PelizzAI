---
name: pelizzai-recovery
description: Recuperação segura quando o estado REAL (git) diverge do esperado (`pelizzai/data/state.md`). Use quando a `pelizzai-router` detectar inconsistência state.md×git na retomada; após sessão interrompida ou crash no meio de uma tarefa; com worktree órfão; ou quando o usuário disser "recuperar", "estado inconsistente", "deu ruim no git". NUNCA execute operação destrutiva de git para "resolver" uma divergência sem passar por esta skill.
---

# PelizzAI Recovery

## Objetivo

Reconciliar o estado registrado com a realidade do git SEM perder trabalho: capturar o estado real, criar um ponto de retorno, deixar o usuário escolher o caminho e commitar a reconciliação do cursor — nesta ordem.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Recovery para recuperar o estado com segurança."

> **Princípio:** primeiro o ponto de retorno, depois qualquer decisão. Caminho destrutivo é SEMPRE decisão do usuário — nunca sua.

## Quando

- `pelizzai-router` (Passo 0) detecta divergência state.md×git na retomada.
- Sessão interrompida/crash no meio de uma tarefa (working tree suja, WIP de origem incerta).
- Worktree órfão (registrado no state.md mas ausente no `git worktree list`, ou vice-versa).
- Usuário: "recuperar", "estado inconsistente", "deu ruim no git".

## Processo

### 1. PARE — nenhuma operação de ESCRITA (git ou arquivos) até o fim do Passo 3; diagnóstico primeiro

### 2. Capture o estado REAL e compare

```bash
git status
git stash list
git worktree list
git log --oneline -5
git branch --show-current
```

Compare com `pelizzai/data/state.md` (slug/phase/branch/isolation/worktree-path) e liste as divergências concretas: "o state diz branch X; o git está em Y", "o worktree registrado não existe", "há WIP que o progresso não menciona".

### 3. Ponto de retorno ANTES de qualquer operação destrutiva

Com working tree suja: `git stash push -u -m "recovery/<slug>/<data>"` (stash **nomeado**) ou um commit WIP na branch atual. **Nunca prossiga sem ele** — o ponto de retorno é o que torna qualquer caminho abaixo reversível.

### 4. MENU de recuperações — o usuário decide

Apresente as opções aplicáveis, com a SUA recomendação e o porquê (baseados no diagnóstico do Passo 2):

```text
Encontrei divergência entre o estado registrado e o git: <resumo das divergências>.
Como recuperar?

1. Retomar de onde parou — restaurar/continuar o trabalho da tarefa ativa (recomendado quando o WIP é bom)
2. Consolidar o WIP — commitar o que existe como está e seguir
3. Descartar as mudanças — voltar ao último estado limpo (DESTRUTIVO; o ponto de retorno do Passo 3 já existe)
4. Reconciliar só o cursor — o trabalho está certo; só o state.md está desatualizado

Qual opção?
```

**Nunca decida um caminho destrutivo sozinho** — a opção 3 só roda após escolha explícita do usuário.

### 5. Reconcilie o state.md e COMMITE o cursor imediatamente

Atualize `pelizzai/data/state.md` para refletir a realidade pós-recuperação (slug/phase/branch/progresso; linha datada no `## Histórico` registrando a recuperação) e commite já, com esta **escada de fallback**:

```text
- Branch protegida (main/master/develop/dev, ou HEAD vazio — fail-closed)? NÃO commite nela:
  crie uma branch segura via `pelizzai-starting-branch` e pouse a reconciliação lá.
- Conflito impedindo o commit? Stash nomeado com as instruções de retomada ESCRITAS no próprio
  state.md (qual stash, como aplicar) — e commite ao menos o state.md.
- Nunca deixe a reconciliação nem commitada nem stashed: cursor solto é a próxima inconsistência.
```

### 6. Retome ou escale

Divergência resolvida → devolva o fluxo (`pelizzai-router` re-roteia; se a recuperação fechou a tarefa, `pelizzai-finish-task` faz o fechamento formal). Situação além do menu (histórico reescrito, remoto divergente, suspeita de perda real de dados) → escale ao humano com o diagnóstico do Passo 2 e o ponto de retorno do Passo 3.

## Red flags

```text
- "reset --hard resolve" sem ponto de retorno (o hook opt-in pelizzai-guardrails bloqueia por um motivo).
- Reconciliar o cursor e NÃO commitá-lo (a próxima sessão herda a mesma inconsistência).
- Decidir descarte sem confirmação explícita do usuário.
- Começar a "arrumar" o git antes de capturar o estado real (Passo 2).
```

## Integração

- `pelizzai-router` — aciona esta skill ao detectar divergência state.md×git na retomada.
- `pelizzai-starting-branch` — cria a branch segura da escada de fallback (Passo 5).
- `pelizzai-execution-plans` — dona do `state.md` (cursor) que esta skill reconcilia.
- `pelizzai-finish-task` — se a recuperação fechar a tarefa, o fechamento formal é dela.
