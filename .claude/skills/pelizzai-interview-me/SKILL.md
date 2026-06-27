---
name: pelizzai-interview-me
description: Use essa skill para entrevistar para entender o objetivo do usuário, estressar um plano ou estressar uma idéia (brainstorming). Ela deve ser invocada quando o usuário não tiver um objetivo claro ou quando precisar de ajuda para definir um objetivo ou plano. A skill deve fazer perguntas abertas e direcionadas para entender o objetivo do usuário, o contexto da tarefa e as skills disponíveis. Ela deve ser capaz de identificar lacunas no conhecimento do usuário e sugerir recursos ou estratégias para preencher essas lacunas.
---

# Pelizzai Interview Me

## Visão geral

A skill "Pelizzai Interview Me" é projetada para ajudar os usuários a esclarecer seus objetivos antes de um brainstorming, após um brainstorming para encontrar lacunas, estressar planos ou gerar ideias através de entrevistas estruturadas, feitas **uma de cada vez**, resolvendo cada ramificação antes de passar para a próxima até que haja um entendimento completo. Ela faz perguntas abertas e direcionadas para entender o contexto da tarefa, as habilidades disponíveis e identificar lacunas no conhecimento do usuário, sugerindo recursos ou estratégias para preenchê-las.

**Princípio fundamental**: uma pergunta de cada vez, sempre acompanhada da sua recomendação; explore o código quando a resposta estiver nele; **exponha ativamente as lacunas do projeto**; pare quando não houver mais decisões pendentes.

**Anuncie ao iniciar:** "Usando a skill Pelizzai Interview Me para ajudá-lo a esclarecer seus objetivos e gerar ideias."

Para cada pergunta, ofereça 4 opções de resposta, sendo uma delas "Outro" para que o usuário possa fornecer uma resposta personalizada. As perguntas devem ser abertas e direcionadas, incentivando o usuário a refletir sobre seus objetivos e necessidades.

**Formas de acesso — exigem uma entrevista aprofundada que exponha lacunas:**

- **Por solicitação do usuário** ("me questione", "me entreviste", "teste a robustez deste plano") — encaminhado pelo `pelizzai-router`.

- **Como uma etapa obrigatória no fluxo da funcionalidade** — Antes do `brainstorming` para esclarecer suas dúvidas, após o `brainstorming` para estressar plano e após o `writing-plans` para estressar o plano. Neste modo, não é opcional: conduza a entrevista até o fim e **liste as lacunas** antes do repasse. Você só pode encerrar mais cedo depois que as lacunas tiverem sido **realmente identificadas e resolvidas** — ou explicitamente aceitas pelo usuário; nunca pule essa etapa para "economizar tempo".

## Fronteira com o _brainstorming_

- **`brainstorming`** — ainda não há um design; criar do zero (propósito, abordagens, design, aprovação).
- **`interview-me`** — já existe um plano/design/ideia; submetê-lo a testes rigorosos, identificar lacunas, resolver decisões pendentes.

Se, durante a entrevista, ficar claro que não existe um plano real, redirecione para o `brainstorming`.

## Processo

1. **Mapeie a árvore de decisão**: identifique todas as decisões pendentes, lacunas de conhecimento e áreas de incerteza. Liste cada decisão como um nó na árvore, com ramificações para cada opção possível.
2. Se necessário, use a skill `pelizzai-reasoning` para analisar cada decisão e suas ramificações, considerando os trade-offs e implicações de cada escolha.
3. **Faça uma pergunta de cada vez**: apresente uma decisão ou lacuna de conhecimento, forneça opções de resposta e incentive o usuário a refletir sobre suas escolhas.
4. **Explore cada ramificação**: para cada resposta, explore as implicações e consequências, identificando novas decisões ou lacunas de conhecimento que surgem.
5. **Investigue antes de perguntar**: antes de fazer uma pergunta, investigue o contexto e as informações disponíveis para evitar perguntas desnecessárias ou repetitivas.
6. **Registre as decisões** à medida que forem tomadas (faça um breve resumo ao concluir cada ramo).
7. **Dê preferência a perguntas de múltipla escolha** sempre que possível — são mais fáceis de responder do que perguntas abertas.
8. **Exponha as lacunas explicitamente** — investigue ativamente o que o projeto NÃO contempla: erros ou edge cases não tratados, validações ausentes, falhas de segurança ou autorização, estados indefinidos, premissas de escalabilidade/desempenho, caminhos não testados e contradições. Aponte essas questões claramente; não deixe uma lacuna passar despercebida apenas porque o usuário não a mencionou.

## Critério de encerramento

Pare quando: todos os ramos da árvore estiverem resolvidos; não houver nenhuma decisão pendente que altere a implementação; e o usuário puder descrever o plano sem ambiguidade. Não prolongue o processo apenas por prolongar.

## Artefato de saída

Ao finalizar, produza um resumo do **plano submetido a testes de estresse**: cada decisão, a escolha feita e a justificativa, e — **obrigatório** — uma lista explícita e numerada das **lacunas/riscos revelados** e como cada um foi resolvido ou conscientemente aceito pelo usuário. Um resumo sem a seção de lacunas está incompleto (um projeto real sempre apresenta falhas que vale a pena identificar).

**Transferência pelo chamador (não pule diretamente para `writing-plans`):**

- **Como etapa de projeto `brainstorming`** → NÃO invoque `writing-plans`. **Retorne o controle para `brainstorming`** para que a etapa conclua sua lista de verificação restante (Escrever documento de projeto → Autoavaliação da especificação → Revisão da especificação pelo usuário).
- **Como etapa de planejamento `writing-plans`** → retorne para `writing-plans`, que prossegue para a execução respeitando o `execution-mode` registrado.
- **Independente** (usuário solicitou teste de estresse em um plano existente) → prossiga para `writing-plans` caso o plano avance para a implementação.
- **Em qualquer modo**, se o plano se mostrar inviável, retorne para `brainstorming`.

## Sinais de Alerta (Red Flags)

**Nunca:**

- Despeje várias perguntas de uma só vez.
- Pergunte algo que você poderia descobrir lendo o código.
- Faça uma pergunta sem apresentar sua própria recomendação.
- Continue a entrevista depois que não houver mais decisões em aberto.
- Passe a tarefa adiante (ou permita que o usuário prossiga) sem ter exposto explicitamente as lacunas do design — revelar essas falhas é justamente o objetivo.
- Trate a etapa obrigatória de validação do fluxo de funcionalidades como algo que pode ser pulado "para economizar tempo".

## Integração

**Combina com:** `brainstorming` (criar do zero) e `writing-plans` (transformar o plano testado sob pressão em um plano de implementação).
