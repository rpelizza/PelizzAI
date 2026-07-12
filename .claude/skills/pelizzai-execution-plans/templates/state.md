# Estado da tarefa — PelizzAI

> Cursor da tarefa ativa. Vive em `pelizzai/data/state.md` (raiz do repositório ou workspace).
> Lido pela `pelizzai-execution-plans` no início de cada tarefa e validado contra o git.
> - Criado por: o primeiro entre `pelizzai-router` / `pelizzai-starting-branch` / `pelizzai-execution-plans` que precisar gravar.
> - Atualizado por: `pelizzai-router` (decisões iniciais), `pelizzai-execution-plans` (gate de setup pós-plano consolidado ratificado, cursor/progresso), `pelizzai-starting-branch` (branch/isolation/worktree-path) e `pelizzai-finish-task` (fechamento).
> Sem tarefa ativa = `slug: <none>`. `phase: done` = tarefa anterior fechada (começa do zero).
> `phase: blocked` = travada, aguardando decisão humana.
> Tarefa NOVA nunca herda as decisões da anterior: ao abrir uma tarefa, sobrescreva
> lane/kickoff/audience/isolation/execution-mode/commit-strategy/overlays com os placeholders da
> nova tarefa.
> Isso vale para carryover ACIDENTAL de state; a política de projeto explicitamente ratificada em
> `pelizzai/profile.md` (§Defaults de execução ratificados) NÃO é herança — ela pré-seleciona a
> recomendação do recap de uma linha, que a tarefa nova re-exibe para ratificação.
> Após compaction, confie NESTE arquivo e no `git log` — não na sua memória (a memória
> pós-compaction re-despacha tarefas já concluídas).
> Contrato atual: **uma tarefa pertence a exatamente um repositório Git**. Em workspace
> multi-repo, abra uma tarefa/estado por repositório; `project` não é uma lista implícita.

## Tarefa ativa

- slug: <none>
- track: <feature | bug | ajuste | refactor | infra | review>
- lane: <bounded | standard | exploratory | high-risk>   # profundidade classificada pelo router, ratificada no kickoff
- phase: <brainstorm | plan | exec | review | done | blocked>
- branch: <nome-da-branch>
- base-ref: <ref exata usada para criar a branch, ex.: origin/main ou refs/heads/trunk>
- base-sha: <SHA completo resolvido de base-ref antes da primeira mudança>
- validated-head: <none | SHA completo do último commit de conteúdo aprovado na validação final>
- kickoff: <pendente | ratificado AAAA-MM-DD>   # marcador máquina-legível: o gate consolidado (conteúdo do plano + isolamento/modo/commits) foi ratificado pelo usuário; writegate e retomada dependem dele
- isolation: <pending | branch | worktree>   # <pending> até a ratificação do usuário no gate consolidado; nunca gravado como default silencioso
- worktree-path: <none | caminho do worktree, quando isolation: worktree>
- execution-mode: <pending | team | subagents | inline>   # <pending> até a ratificação no gate consolidado; nunca default silencioso; as três opções são sempre visíveis (team nunca omitido)
- commit-strategy: <pending | granular | squash-final>   # <pending> até a ratificação; nunca default silencioso; squash-final somente com pedido explícito do usuário
- effect: <read-only | write-local | external>
- risk: <low | medium | high>
- overlays: <none | nomes separados por vírgula>   # skills transversais exigidas, ex.: pelizzai-frontend, pelizzai-oswap
- audience: <technical | layperson>
- plan: <caminho do plano em execução, ex.: pelizzai/plans/AAAA-MM-DD-<topico>.md>
- project: <none | caminho do único repositório Git desta tarefa>

## Progresso

- delivered: <o que já foi concluído>
- next: <próximo passo concreto>
- pending: <itens em aberto / dúvidas>

## Histórico

- <AAAA-MM-DD> — estado inicializado (pelizzai-router / pelizzai-starting-branch / pelizzai-execution-plans)

_Última atualização: <AAAA-MM-DD>_
