# Ciclo por tarefa — protocolo detalhado

O protocolo que cada tarefa segue na execução de um plano, válido nos três modos (team, subagents, inline). Inspirado no subagent-driven-development (review em dois estágios) e validado em campo no harness anterior.

## 1. Briefing por colagem (não por arquivo)

O coordenador extrai o **texto completo** da tarefa do plano e o **cola** no prompt do membro. O membro (teammate/subagente) **nunca lê o arquivo do plano** — isso evita poluição de contexto e mantém o foco.

O briefing de cada tarefa inclui:

```text
- Texto completo da tarefa (colado do plano, com valores exatos a usar verbatim).
- Skills de domínio relevantes (coladas, ou seus pontos-chave) — o membro não herda o seu contexto.
- Convenções e contratos necessários (caminhos, interfaces, decisões já tomadas).
- Instrução de raciocínio (pelizzai-reasoning) e de TDD (pelizzai-tdd).
- O formato de retorno esperado e o status (ver abaixo).
```

Responda às perguntas do membro **antes** de o trabalho começar; re-despache se faltar contexto.

## 2. Implementar via TDD

O membro implementa seguindo `pelizzai-tdd`:

```text
- Iron Law: NENHUM código de produção sem um teste que falhe primeiro.
- Fatias verticais (um teste → uma implementação), não horizontais.
- Refatoração que preserva comportamento (track refactor): garanta cobertura verde
  (characterization tests) ANTES de tocar, em vez de começar com teste novo.
- O membro testa e faz self-review, mas NÃO commita.
```

## 3. Review em dois estágios (spec → qualidade)

Nesta ordem, com `pelizzai-review`:

```text
(a) Conformidade com a spec: o código faz exatamente o que a tarefa pede? Nada a mais, nada a menos?
(b) Qualidade do código: legibilidade, design, reuso, segurança — COM evidência de teste FRESCA:
    o revisor rodou de fato os comandos de teste/lint/build do projeto e colou a saída verde.
    "Testes passam" inferido NÃO conta como aprovado.
```

Aprovação exige **os dois** verdicts: spec ✅ **e** qualidade ✅. Itens "⚠️ não verificável" exigem avaliação do coordenador contra o plano antes de marcar concluído.

## 4. Status do membro

O membro reporta um destes status:

| Status               | Significado                                   | Conduta do coordenador                                         |
| -------------------- | --------------------------------------------- | -------------------------------------------------------------- |
| `DONE`               | Trabalho completo                             | Segue para o review                                            |
| `DONE_WITH_CONCERNS` | Completo, mas com ressalvas                   | Leia as ressalvas antes de prosseguir                          |
| `NEEDS_CONTEXT`      | Falta informação                              | Forneça o contexto e re-despache                               |
| `BLOCKED`            | Não consegue concluir                         | Avalie: dar contexto, usar modelo mais capaz, quebrar a tarefa, ou escalar ao humano |

Nunca ignore uma escalação nem re-despache sem mudar nada.

## 5. Circuit breaker do loop de review

```text
- Limite: 3 ciclos de fix→re-review POR ESTÁGIO (spec e qualidade têm contadores separados), POR TAREFA.
- A mesma issue rejeitada 2x → escala na 2ª.
- Rejeição estrutural ("a abordagem está fundamentalmente errada") → escala imediatamente.
- Resets (não desista cedo demais): zere o contador de spec ao spec ✅, o de qualidade ao
  qualidade ✅, e AMBOS ao iniciar uma nova tarefa — um loop na Tarefa N não afeta a N+1.
- NÃO conta como ciclo (evita falso positivo): BLOCKED (já é escalação, nunca tally);
  DONE_WITH_CONCERNS cujas ressalvas são observações e o review passa; implementador que
  CONTESTA a rejeição ("o revisor diz que falta X, mas está na linha Y") → trate como
  NEEDS_CONTEXT e reconfirme com o revisor (revisores são subagentes e erram).
- Ao estourar o limite: pare de despachar; grave phase: blocked e registre em `## Progresso` →
  `pending` o bloqueio (tarefa, estágio, nº de ciclos falhos, os motivos de rejeição distintos
  EM ORDEM, os fixes tentados e o padrão: issues independentes / mesma issue recorrente /
  conflito estrutural); commite SÓ o cursor (chore: registra BLOCKED em <tarefa>); escale ao
  humano com uma mensagem ACIONÁVEL (o que foi feito + cada motivo + fixes + padrão + opções:
  esclarecer a spec via pelizzai-writing-plans / subir o modelo / quebrar a tarefa / revisar o
  plano); deixe a working tree INTACTA (nunca git reset --hard). Se o humano mandar continuar,
  re-despache reaproveitando o WIP — não recomece do zero.
```

## 6. Commit como gate

```text
- O membro NÃO commita. O trabalho fica na working tree até os DOIS reviews passarem.
- Só após spec ✅ e qualidade ✅ (com fixes aplicados) o COORDENADOR consolida.
- Granular: o toque do cursor (state.md) entra no MESMO commit da tarefa.
- Squash-final: acumula; nunca um commit órfão só do cursor.
```

## 7. Avançar o cursor

Após consolidar, atualize `pelizzai/data/state.md`: na seção `## Progresso`, atualize `delivered`, ajuste `next` e `pending`, mantenha `phase: exec`. Ao concluir o plano, a `pelizzai-finish-task` fecha o cursor (`phase: done`).

## 8. Seleção de modelo por papel

Use o modelo adequado ao papel: tarefas mecânicas e bem-especificadas pedem modelos rápidos; integração pede modelos padrão; arquitetura e o **review final da branch** pedem o modelo mais capaz disponível. Especifique o modelo explicitamente para não herdar o default da sessão.
