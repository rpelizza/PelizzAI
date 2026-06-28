---
name: pelizzai-loop
description: Use essa skill para trabalhar em loop até que o objetivo ou a tarefa seja concluída com sucesso.
---

## A lente do "loop"

Um **loop** é um padrão recorrente na vida do usuário: sua carreira, sua semana, sua rotina matinal ou uma atividade específica que se repete. Visualizar a vida como loops dentro de loops revela o quão previsíveis são as atividades — e é justamente isso que as torna candidatas à **delegação**. Use essa perspectiva para identificar loops que valha a pena especificar e proponha outros que o usuário ainda não tenha percebido.

Um **fluxo de trabalho** (_workflow_) é a especificação de um loop concretizada. Você executa um fluxo de trabalho sobre um loop — o loop é a instância do fluxo em execução.

## Vocabulário

Uma linguagem compartilhada, utilizada apenas quando o fluxo de trabalho a exige — nunca uma simples lista de verificação (_checklist_). **Não imponha nada estrutural**: um fluxo de trabalho não precisa de IA, pontos de verificação ou agendamento, a menos que o processo de interrogatório indique essa necessidade.

- **Gatilho** (_Trigger_) — o que dispara cada execução: um **evento** (um novo e-mail, uma nova tarefa/issue) ou um **agendamento** (todas as manhãs). O disparo por evento costuma ser mais eficiente.
- **Ponto de verificação** (_Checkpoint_) — um ponto de interação humana (_human-in-the-loop_) onde o usuário deve verificar algo ou tomar uma decisão. Alguns fluxos de trabalho não possuem nenhum e operam de forma autônoma; outros não utilizam IA alguma.
- **Empurrar para a direita** (_Push right_) — adiar o ponto de verificação o máximo possível. Realize o máximo de trabalho antes de envolver o ser humano, garantindo que ele seja consultado apenas uma vez, em um estágio avançado e com tudo já preparado.
- **Resumo executivo** (_Brief_) — o que é apresentado em um ponto de verificação: um resumo conciso e pronto para decisão — contendo o que foi produzido, o motivo e um link para o ativo em si — nunca o resultado bruto. O usuário lê um resumo, não um rascunho. A rapidez na revisão é fundamental.

## Definição de "concluído" (Definition of Done - DoD)

Uma especificação de fluxo de trabalho é considerada concluída quando um agente responsável pela implementação consegue construí-la sem precisar fazer uma única pergunta. Continue o detalhamento até esse ponto; nada está concluído enquanto restar alguma dúvida.
Caso existam dúvidas durante o loop, o agente deve interromper a execução e solicitar esclarecimentos usando a skill `pelizzai-interview-me`. A execução do fluxo de trabalho só deve ser retomada quando todas as dúvidas forem resolvidas.
