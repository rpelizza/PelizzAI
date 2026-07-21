# Estado da tarefa — PelizzAI

> Cursor da tarefa ativa. Vive em `pelizzai/data/state.md` (raiz do repositório ou workspace).
> Doutrina — quem escreve cada campo, Ciclo de vida da entrega (`delivered` → `done`), reconciliação
> e higiene do histórico — mora em `pelizzai-execution-plans` → SKILL.md §Estado e retomada.
> Referencie, não duplique: aqui ficam os campos, lá fica o processo.
> Sem tarefa ativa = `slug: <none>`. `phase: blocked` = travada, aguardando decisão humana.

## Tarefa ativa

- slug: <none>
- track: <feature | bug | ajuste | refactor | infra | review>
- lane: <bounded | standard | exploratory | high-risk>   # profundidade classificada pelo router, ratificada no kickoff
- phase: <brainstorm | plan | exec | review | delivered | done | abandoned | blocked>   # a finish-task NÃO declara `done`: sela `delivered` (conteúdo + destino executado); `done` é constatado depois contra o git; `abandoned` = arquivada sem merge
- branch: <nome-da-branch>
- base-ref: <ref exata usada para criar a branch, ex.: origin/main ou refs/heads/trunk>
- base-sha: <SHA completo resolvido de base-ref antes da primeira mudança>
- validated-head: <none | SHA completo do último commit de conteúdo aprovado na validação final>
- confirmar: <none | condição observável para constatar `done` — ex.: "base-ref contém validated-head (PR/branch integrada)" | "entrega local aceita pelo usuário">
- kickoff: <pendente | ratificado AAAA-MM-DD>   # gate consolidado (conteúdo do plano + isolamento/modo/commits) ratificado pelo usuário
- isolation: <pending | branch | worktree>   # <pending> até a ratificação; nunca gravado como default silencioso
- worktree-path: <none | caminho do worktree, quando isolation: worktree>
- execution-mode: <pending | team | subagents | inline>   # <pending> até a ratificação; as três opções sempre visíveis (team nunca omitido)
- commit-strategy: <pending | granular | squash-final>   # <pending> até a ratificação; squash-final somente com pedido explícito do usuário
- effect: <read-only | write-local | external>
- risk: <low | medium | high>
- overlays: <none | nomes separados por vírgula>   # skills transversais exigidas, ex.: pelizzai-frontend, pelizzai-oswap
- audience: <technical | layperson>
- spec: <pending | caminho da spec | dispensada explicitamente AAAA-MM-DD | not-applicable>
- plan: <pending | caminho do plano em execução, ex.: pelizzai/plans/AAAA-MM-DD-<topico>.md>
- project: <none | caminho do único repositório Git desta tarefa>

## Progresso

<!-- Uma linha por tarefa do plano. Relatório longo (QA, review, investigação, decisão de rodada)
     NÃO fica aqui: grave em pelizzai/data/reports/<AAAA-MM-DD>-<slug>-<tema>.md (ignorado) e deixe
     só o link. Passou de ~60 linhas? O harness propõe compactar uma vez (advisory, nunca bloqueia). -->

- T1 ✅ <sha|AAAA-MM-DD> — <nota ≤1 linha | → data/reports/<arquivo>>
- next: <próximo passo concreto>
- pending: <itens em aberto / dúvidas>

## Histórico

<!-- Índice durável de entregas. No selo `delivered`, o bloco íntegro da tarefa migra para
     pelizzai/data/history/<AAAA-MM-DD>-<slug>.md (VERSIONADO), o cursor volta ao tamanho deste
     template e aqui fica UMA linha — carimbada com `done`/`abandoned` quando constatada. -->

- <AAAA-MM-DD> — estado inicializado (pelizzai-router / pelizzai-starting-branch / pelizzai-execution-plans)
- <AAAA-MM-DD> <slug> — delivered [→ done | abandoned <AAAA-MM-DD>] — <resultado em ≤10 palavras> → data/history/<AAAA-MM-DD>-<slug>.md

_Última atualização: <AAAA-MM-DD>_
