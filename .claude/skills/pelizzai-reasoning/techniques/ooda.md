# OODA — Observar, Orientar, Decidir, Agir

## Objetivo

Conduzir execuções longas ou dinâmicas como um **loop macro** em que cada iteração recomeça da **realidade atual** — não do snapshot da iteração anterior. É a lente formal do laço de execução do harness (`pelizzai-loop`, `pelizzai-execution-plans`) e do Sync & delta do `pelizzai-router`.

## Princípio central

> Re-observe antes de decidir. Agir sobre um modelo mental desatualizado custa mais do que o `git status`/suíte que o atualizaria — e um loop sem Definition of Done não é disciplina, é deriva.

## Quando usar

- Execução longa em loop até a Definition of Done (executar um plano tarefa por tarefa).
- Situações dinâmicas: a base avança (colegas pusharam), testes/reviews devolvem informação nova, dependências mudam de versão.
- Investigações iterativas em que cada rodada muda o que vale a pena fazer na próxima.
- Retomada de tarefa após pausa/compaction (o mundo pode ter mudado desde o registro).

## Quando evitar

- Tarefa curta de ação única — ali o [ReAct](react.md) sozinho basta.
- Trabalho puramente analítico sobre insumos estáticos (nada muda entre "iterações") — não há o que re-observar.
- Quando um circuit breaker específico já governa o laço (fix→re-review do task-cycle) — o OODA é a lente, não um segundo contador.

## O ciclo

```text
1. OBSERVAR — colete a realidade externa ANTES de decidir:
   estado do git (branch, delta da base, commits novos), saída fresca de testes/lint/build,
   vereditos de review, o estado registrado (pelizzai/data/state.md) validado contra o real.
   Observação é evidência colhida agora — não memória da iteração passada.

2. ORIENTAR — interprete o observado contra o objetivo:
   o que isso muda no plano? A Definition of Done está mais perto ou surgiu um bloqueio?
   Alguma premissa caiu (Assumption Tracking)? O delta observado afeta ESTA tarefa?
   Releia só o que mudou e importa — orientação é atualizar o modelo, não re-briefing completo.

3. DECIDIR — escolha a próxima ação de maior valor:
   próxima tarefa do plano / corrigir o que reprovou / replanejar (a evidência invalidou o caminho)
   / parar e perguntar (dúvida material → pelizzai-interview-me) / escalar (circuit breaker)
   / concluir (DoD atingida — confirme com Verification antes de declarar).

4. AGIR — execute a decisão:
   dentro do Agir vivem os micro-ciclos ReAct (pensar → ferramenta → observar o resultado imediato)
   e as skills executoras (pelizzai-tdd, pelizzai-review, …).

5. REPITA a partir do OBSERVAR — nunca do modelo mental da iteração anterior.
```

## Regras

- **Uma iteração nunca herda o snapshot da anterior.** Re-observe antes de decidir; o custo de um `git status`/suite é menor que o de agir sobre realidade velha.
- **Orientação honesta:** se a evidência contradiz o plano, o plano perde — replaneje ou escale; não continue com plano desatualizado.
- **Decisão registrada:** em execução de plano, cada Decidir avança o cursor (`pelizzai/data/state.md`) — o loop sobrevive a compaction.
- **Critérios de parada:** a lista canônica das saídas legítimas do loop vive na `pelizzai-loop` (5 critérios: DoD verificada; dúvida material → `pelizzai-interview-me`; bloqueio → `phase: blocked` e escalar; evidência invalidou o caminho → replanejar; custo maior que o benefício → escalar/perguntar antes de insistir). Defina a DoD **antes** de entrar no loop.
- **Não vire ritual:** em tarefa trivial, o loop colapsa para um único ciclo — observar rápido, agir, verificar.

## Anti-padrões

```text
- Agir sobre o snapshot da iteração anterior sem re-observar (base avançou, você não viu).
- "Orientar" ignorando evidência que invalida o plano (viés de continuação).
- Loop sem critério de parada (investigação infinita) — defina a DoD antes de entrar no loop.
- Usar OODA para tarefa de ação única (overhead sem ganho — use ReAct).
- Decidir sem registrar (o próximo ciclo — ou a próxima sessão — não sabe onde o loop estava).
```

## Integração no harness

- `pelizzai-loop` — a DoD e a regra de parar-em-dúvida são os limites deste loop.
- `pelizzai-execution-plans` — o laço macro por tarefa É um loop OODA (observar evidência → orientar contra o plano → decidir a próxima tarefa/fix → agir via TDD+review).
- `pelizzai-router` (Sync & delta) — o Observar de início de tarefa: delta do git desde a última tarefa.
- `pelizzai-debugging` — as 4 fases mapeiam o ciclo: Fase 1 (observar/reproduzir), Fase 2 (orientar contra padrões que funcionam), Fase 3 (decidir a hipótese), Fase 4 (agir com teste + fix).
- [ReAct](react.md) — o micro-ciclo dentro do Agir. [Verification](verification.md) — confirma a DoD antes de sair do loop.
