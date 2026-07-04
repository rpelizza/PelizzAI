# Estado da tarefa — PelizzAI

> Cursor da tarefa ativa. Vive em `pelizzai/data/state.md` (raiz do repositório ou workspace).
> Lido pela `pelizzai-execution-plans` no início de cada tarefa e validado contra o git.
> - Criado por: o primeiro entre `pelizzai-router` / `pelizzai-starting-branch` / `pelizzai-execution-plans` que precisar gravar.
> - Atualizado por: `pelizzai-router` (decisões iniciais), `pelizzai-execution-plans` (gate de setup pós-plano, cursor/progresso), `pelizzai-starting-branch` (branch/isolation/worktree-path) e `pelizzai-finish-task` (fechamento).
> Sem tarefa ativa = `slug: <none>`. `phase: done` = tarefa anterior fechada (começa do zero).
> `phase: blocked` = travada, aguardando decisão humana.
> Tarefa NOVA nunca herda as decisões da anterior: ao abrir uma tarefa, sobrescreva
> isolation/execution-mode/commit-strategy com os placeholders para os gates perguntarem de novo.
> Após compaction, confie NESTE arquivo e no `git log` — não na sua memória (a memória
> pós-compaction re-despacha tarefas já concluídas).

## Tarefa ativa

- slug: <none>
- track: <feature | bug | ajuste | refactor | infra | review>
- phase: <brainstorm | plan | exec | review | done | blocked>
- branch: <nome-da-branch>
- isolation: <pending | branch | worktree>   # escolhido pelo usuário no gate (pós-plano nos tracks com plano)
- worktree-path: <none | caminho do worktree, quando isolation: worktree>
- execution-mode: <pending | team | subagents | inline>
- commit-strategy: <pending | granular | squash-final>   # granular = commits definitivos mantidos; squash-final = consolidação final já autorizada
- audience: <technical | layperson>
- plan: <caminho do plano em execução, ex.: pelizzai/plans/AAAA-MM-DD-<topico>.md>
- project: <none | projeto-alvo da tarefa (em workspace)>

## Progresso

- delivered: <o que já foi concluído>
- next: <próximo passo concreto>
- pending: <itens em aberto / dúvidas>

## Histórico

- <AAAA-MM-DD> — estado inicializado (pelizzai-router / pelizzai-starting-branch / pelizzai-execution-plans)

_Última atualização: <AAAA-MM-DD>_
