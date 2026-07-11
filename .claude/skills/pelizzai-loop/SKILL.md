---
name: pelizzai-loop
description: Use para conduzir loops macro até a entrega — execução tarefa a tarefa, fix→re-review ou investigação em múltiplas rodadas — com OODA (Observar → Orientar → Decidir → Agir), Definition of Done e critérios de parada. Não use para transformar todo microciclo de teste ou ação única em OODA.
---

# PelizzAI Loop

## Objetivo

Dar ao harness a disciplina do **laço**: repetir o ciclo de trabalho até a entrega **com critério de parada explícito** — nem desistir cedo, nem iterar para sempre, nem declarar pronto sem a Definition of Done atingida e verificada.

**Anuncie ao iniciar (quando acionada explicitamente):** "Usando a skill PelizzAI Loop para iterar até a Definition of Done."

---

## O loop macro é OODA

Loops **macro**, nos quais a realidade pode mudar entre iterações, seguem **OODA** (técnica completa: `pelizzai-reasoning` → [techniques/ooda.md](../pelizzai-reasoning/techniques/ooda.md)):

```text
OBSERVAR  — colete a realidade ATUAL: git, saída fresca de testes/lint/build, vereditos de
            review, o state.md validado contra o real. Nunca o snapshot da iteração anterior.
ORIENTAR  — interprete contra o objetivo: o que mudou? a DoD está mais perto? alguma premissa caiu?
DECIDIR   — próxima tarefa / corrigir / replanejar / parar e perguntar / escalar / concluir.
AGIR      — execute (aqui vivem o TDD, o review, as ferramentas — os micro-ciclos ReAct).
REPETIR   — a partir do OBSERVAR, até a Definition of Done.
```

Onde esse loop roda no harness:

| Laço                                    | Condução                        | O que esta skill contribui            |
| --------------------------------------- | ------------------------------- | ------------------------------------- |
| Plano tarefa a tarefa                   | `pelizzai-execution-plans`      | lente OODA + DoD + parada em dúvida   |
| fix → re-review                         | `pelizzai-review` + task-cycle  | re-observar (re-review) após cada fix |
| Investigação em múltiplas rodadas       | `pelizzai-team` / `pelizzai-debugging` | reorientação por evidência nova     |

RED→GREEN e chamadas de ferramenta são microciclos de TDD/ReAct dentro de **Agir**; não repita o vocabulário OODA a cada teste. Um bug direto com uma única sequência repro→fix→verify não aciona esta skill.

## Definition of Done (DoD)

O loop só encerra quando a DoD é atingida **e verificada** (`pelizzai-verification-before-completion`). Defina a DoD **antes** de entrar no loop:

```text
- De um plano: todas as tarefas entregues + validação final do coordenador (review final da branch,
  suíte completa verde com evidência, checklist requisito a requisito do plano).
- De uma tarefa: efeito entregue com a estratégia registrada no plano (TDD, caracterização, validate/dry-run, visual ou estática), spec ✅ e qualidade ✅ com evidência fresca.
- De um fix de bug: sintoma original agora verde pelo oráculo adequado; regressão red→green quando houver comportamento automatizável; nenhuma regressão relevante.
- De uma especificação/workflow: quem for executar consegue trabalhar sem fazer UMA pergunta —
  enquanto restar dúvida, não está pronto.
```

"Quase tudo" não é DoD. Requisito sem entrega = loop continua.

## Critérios de parada (saídas legítimas do loop)

```text
1. DoD atingida e VERIFICADA (evidência fresca) → concluir.
2. Dúvida material no meio do loop → PARE e acione `pelizzai-interview-me`; só retome quando
   TODAS as dúvidas estiverem resolvidas. Nunca "chuta e segue".
3. Bloqueio que você não resolve (circuit breaker estourado, decisão que pertence ao humano)
   → registre phase: blocked no state.md e escale com mensagem acionável.
4. A evidência invalidou o caminho → replaneje (volte ao plano/design), não insista.
5. Custo de continuar maior que o benefício (investigação/rodadas sem circuit breaker próprio
   que pararam de render informação) → escale ou pergunte antes de insistir; nunca saia em
   silêncio por cansaço.
```

Fora esses cinco, **não pare** — em plano aprovado, não pergunte "sigo?" entre tarefas (autonomia entre tarefas, gates nas bordas). Estes cinco critérios são a lista canônica; `techniques/ooda.md` remete a ela.

---

## Lente opcional: loops como workflows delegáveis

Fora da execução de código, "loop" também é um padrão recorrente na vida do usuário (rotina, semana, atividade repetida). Um **workflow** é a especificação de um loop desses; vocabulário útil ao especificá-lo: **Gatilho** (evento ou agenda que dispara cada execução), **Checkpoint** (ponto de decisão humana), **Push right** (adiar o checkpoint para quando tudo estiver pronto), **Brief** (resumo executivo pronto para decisão, nunca o resultado bruto). Use esta lente apenas quando o usuário estiver especificando automações/rotinas — não a imponha ao fluxo de código.

---

## Integração

- `pelizzai-execution-plans` — conduz o laço macro de planos com esta lente (OODA + DoD + parada em dúvida).
- `pelizzai-reasoning` — a técnica OODA (macro) e ReAct (micro) vivem lá; Verification confirma a DoD.
- `pelizzai-tdd` — microciclo para comportamento quando essa for a estratégia selecionada; não torna OODA obrigatório.
- `pelizzai-interview-me` — destino obrigatório da parada por dúvida material.
- `pelizzai-verification-before-completion` — nenhuma saída do loop sem evidência fresca.
- `pelizzai-router` — o Sync & delta é o Observar do início de cada tarefa.
