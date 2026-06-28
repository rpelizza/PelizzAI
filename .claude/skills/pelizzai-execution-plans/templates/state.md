# Estado da tarefa — PelizzAI

> Cursor da tarefa ativa. Vive em `pelizzai/data/state.md` (raiz do repositório ou workspace).
> Lido pela `pelizzai-execution-plans` no início de cada tarefa e validado contra o git.
> - Criado/atualizado por: `pelizzai-execution-plans` (durante a execução) e `pelizzai-finish-task` (no fechamento).
> Sem tarefa ativa = `slug: <none>`. `phase: done` = tarefa anterior fechada (começa do zero).
> `phase: blocked` = travada, aguardando decisão humana.

## Tarefa ativa

- slug: <none>
- track: <feature | bug | adjustment | refactor | infra | review>
- phase: <brainstorm | plan | exec | review | done | blocked>
- branch: <nome-da-branch>
- isolation: branch   # o harness trabalha só com branches (sem worktrees)
- execution-mode: <team | subagents | inline>
- commit-strategy: <granular | squash-final>
- plan: <caminho do plano em execução, ex.: pelizzai/plans/AAAA-MM-DD-<topico>.md>
- project: <none | projeto-alvo da tarefa (em workspace)>

## Progresso

- delivered: <o que já foi concluído>
- next: <próximo passo concreto>
- pending: <itens em aberto / dúvidas>

## Histórico

- <AAAA-MM-DD> — estado inicializado pela pelizzai-execution-plans

_Última atualização: <AAAA-MM-DD>_
