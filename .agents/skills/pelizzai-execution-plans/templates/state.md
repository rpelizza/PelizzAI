# Estado da tarefa — PelizzAI

> Cursor da tarefa ativa. Vive em `pelizzai/data/state.md` (raiz do repositório ou workspace).
> Lido pela `pelizzai-execution-plans` no início de cada tarefa e validado contra o git.
> - Criado por: o primeiro entre `pelizzai-router` / `pelizzai-starting-branch` / `pelizzai-execution-plans` que precisar gravar.
> - Atualizado por: `pelizzai-router` (decisões iniciais), `pelizzai-execution-plans` (gate de setup pós-plano consolidado ratificado, cursor/progresso, reconciliação delivered→done), `pelizzai-starting-branch` (branch/isolation/worktree-path) e `pelizzai-finish-task` (selagem em `delivered`).
> Sem tarefa ativa = `slug: <none>`. `phase: blocked` = travada, aguardando decisão humana.
>
> **Ciclo de vida da entrega (`delivered` → `done`).** A `pelizzai-finish-task` NÃO declara `done`:
> encerra em `phase: delivered` (conteúdo selado + destino executado — PR aberto, branch publicada ou
> mantido local) e grava `confirmar:` com a condição observável que vira `done`. Esse marcador sobe
> junto no PR (é commitado na branch de tarefa antes de você sair dela). `done` é **constatação, nunca
> declaração**: na abertura da próxima tarefa (`pelizzai-execution-plans`/`pelizzai-router`) e na
> retomada (`pelizzai-recovery`/session-start), o harness verifica `confirmar:` contra o git
> (base-ref contém `validated-head`? PR mergeado? branch integrada?) e só então grava `done` + data +
> evidência de 1 linha, migrando o bloco para `data/history/` (ver Progresso/Histórico). Se a
> constatação FALHAR (PR fechado sem merge), o harness informa e propõe retomar a branch ou arquivar
> como `abandoned` — decisão do usuário. O state reconciliado entra no **primeiro commit da task branch
> NOVA**, nunca num commit em branch protegida (escrita de metadata em `pelizzai/` é permitida em
> qualquer branch; o commit continua exigindo branch de tarefa).
> Tarefa NOVA nunca herda as decisões da anterior: ao abrir uma tarefa, primeiro reconcilie a entrega
> anterior (`delivered`→`done`, acima) e então sobrescreva
> lane/kickoff/audience/discovery/spec/spec-approval/domain-skills-decision/plan/plan-approval/
> isolation/execution-mode/commit-strategy/overlays/confirmar com os placeholders da
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
- phase: <brainstorm | plan | exec | review | delivered | done | abandoned | blocked>   # delivered = selado + destino executado (gravado pela finish-task); done = constatado na próxima abertura/retomada; abandoned = entrega arquivada sem merge por decisão do usuário quando a constatação de done falha
- branch: <nome-da-branch>
- base-ref: <ref exata usada para criar a branch, ex.: origin/main ou refs/heads/trunk>
- base-sha: <SHA completo resolvido de base-ref antes da primeira mudança>
- validated-head: <none | SHA completo do último commit de conteúdo aprovado na validação final>
- confirmar: <none | condição observável para constatar `done` — ex.: "base-ref contém validated-head (PR/branch integrada)" | "entrega local aceita pelo usuário">   # gravado pela finish-task quando phase: delivered; a próxima abertura/retomada constata done contra o git
- kickoff: <pendente | ratificado AAAA-MM-DD>   # marcador máquina-legível: o gate consolidado (conteúdo do plano + isolamento/modo/commits) foi ratificado pelo usuário; writegate e retomada dependem dele
- isolation: <pending | branch | worktree>   # <pending> até a ratificação do usuário no gate consolidado; nunca gravado como default silencioso
- worktree-path: <none | caminho do worktree, quando isolation: worktree>
- execution-mode: <pending | team | subagents | inline>   # <pending> até a ratificação no gate consolidado; nunca default silencioso; as três opções são sempre visíveis (team nunca omitido)
- commit-strategy: <pending | granular | squash-final>   # <pending> até a ratificação; nunca default silencioso; squash-final somente com pedido explícito do usuário
- effect: <read-only | write-local | external>
- risk: <low | medium | high>
- overlays: <none | nomes separados por vírgula>   # skills transversais exigidas, ex.: pelizzai-frontend, pelizzai-oswap
- audience: <technical | layperson>
- discovery: <pending | ratificada AAAA-MM-DD | dispensada explicitamente AAAA-MM-DD | not-applicable>
- spec: <pending | caminho da spec | dispensada explicitamente AAAA-MM-DD | not-applicable>
- spec-approval: <pending | ratificada AAAA-MM-DD | not-applicable>
- domain-skills-decision: <pending | ratificada AAAA-MM-DD | not-applicable>
- plan: <pending | caminho do plano em execução, ex.: pelizzai/plans/AAAA-MM-DD-<topico>.md>
- plan-approval: <pending | ratificado AAAA-MM-DD | not-applicable>
- project: <none | caminho do único repositório Git desta tarefa>

## Progresso

<!-- Uma linha por tarefa do plano. Relatório longo (QA, review, investigação, decisão de rodada)
     NÃO fica aqui: grave em pelizzai/data/reports/<AAAA-MM-DD>-<slug>-<tema>.md (ignorado) e deixe
     só o link. Ao passar de ~150 linhas, o harness propõe compactar (advisory, uma vez). -->

- T1 ✅ <sha|AAAA-MM-DD> — <nota ≤1 linha | → data/reports/<arquivo>>
- next: <próximo passo concreto>
- pending: <itens em aberto / dúvidas>

## Histórico

<!-- Log durável de eventos do cursor + índice de entregas constatadas. Ao constatar `done` (ou
     `abandoned`), o bloco íntegro da tarefa migra para pelizzai/data/history/<AAAA-MM-DD>-<slug>.md
     (VERSIONADO) e no state fica só a linha de índice (`done` ou `— abandoned —`). Bloco íntegro =
     todos os campos de `## Tarefa ativa` desta tarefa + suas linhas T<n>/next/pending de
     `## Progresso`, com os links de data/reports/ copiados verbatim. Migração de bloco íntegro é sem
     perda → automática na reconciliação; CONDENSAR conteúdo é destrutivo → só propor-confirmar. -->

- <AAAA-MM-DD> — estado inicializado (pelizzai-router / pelizzai-starting-branch / pelizzai-execution-plans)
- <AAAA-MM-DD> <slug> — done — <resultado em ≤10 palavras> → data/history/<AAAA-MM-DD>-<slug>.md
- <AAAA-MM-DD> <slug> — abandoned — <motivo em ≤10 palavras> → data/history/<AAAA-MM-DD>-<slug>.md

_Última atualização: <AAAA-MM-DD>_
