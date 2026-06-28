---
name: pelizzai-router
description: Essa skill deve ser invocada após entender o objetivo do usuário e o contexto da tarefa. Ela roteia a solicitação para a skill mais adequada, com base no objetivo do usuário, no contexto da tarefa e nas skills disponíveis.
---

# PelizzAI Router

## Objetivo

Escolher a menor combinação de skills que resolve a solicitação do usuário com segurança, sem pular disciplinas importantes do harness.

## Regra de roteamento

Depois de entender objetivo, entregável, contexto, restrições e critério de sucesso:

```text
1. Acione a skill específica do trabalho principal.
2. Acione `pelizzai-preferences` como camada global se a tarefa envolver comunicação, engenharia, código, validação, segurança, documentação, portabilidade ou decisões de execução.
3. Acione skills complementares apenas quando adicionarem disciplina real ao trabalho.
```

`pelizzai-preferences` não substitui skills específicas. Ela ajusta idioma, qualidade técnica, segurança, validação e portabilidade conforme o contexto.

Não use `pelizzai-preferences` para tarefas triviais sem risco, como uma resposta direta de uma linha, quando nenhuma preferência global mudaria o resultado.
