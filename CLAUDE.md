# CLAUDE.md

## Harness PelizzAI (entrada obrigatória)

Este repositório é o harness **PelizzAI**. A entrada de toda tarefa é a skill `pelizzai-core` (que exige acionar uma skill aplicável antes de qualquer resposta) e o `pelizzai-router` (que classifica o track e roteia). As diretrizes abaixo **complementam** as skills: em processo (planos, branches, reviews, fechamento), as skills do harness prevalecem. Ao anunciar uma skill, use sempre a grafia exata da marca: **"PelizzAI"**.

## Diretrizes comportamentais

Diretrizes para reduzir erros comuns de codificação cometidos por LLMs. Combine com instruções específicas do projeto conforme necessário.

**Trade-off:** Estas diretrizes priorizam cautela em vez de velocidade. Para tarefas triviais, use bom senso — mas o "bom senso" não anula a regra do 1% da `pelizzai-core`: se uma skill se aplica (mesmo a um ajuste trivial, ex.: `pelizzai-quick-fix`), acione-a; a proporcionalidade vive DENTRO das skills, não em pulá-las.

## 1. Pense Antes de Codificar

**Não presuma. Não esconda dúvidas. Exponha os trade-offs.**

Antes de implementar:

- Declare suas premissas explicitamente. Se houver incerteza, pergunte.
- Se existirem múltiplas interpretações, apresente-as; não escolha em silêncio.
- Se existir uma abordagem mais simples, diga. Questione quando fizer sentido.
- Se algo não estiver claro, pare. Diga o que está confuso. Pergunte.

## 2. Simplicidade Primeiro

**O mínimo de código que resolve o problema. Nada especulativo.**

- Nada de funcionalidades além do que foi pedido.
- Nada de abstrações para código de uso único.
- Nada de "flexibilidade" ou "configurabilidade" que não foi solicitada.
- Nada de tratamento de erro para cenários impossíveis.
- Se você escreveu 200 linhas e poderia ser 50, reescreva.

Pergunte a si mesmo: "Um engenheiro sênior diria que isto está complicado demais?" Se sim, simplifique.

## 3. Alterações Cirúrgicas

**Mexa apenas no que for necessário. Limpe apenas a sua própria bagunça.**

Ao editar código existente:

- Não "melhore" código, comentários ou formatação adjacentes.
- Não refatore coisas que não estão quebradas.
- Siga o estilo existente, mesmo que você fizesse diferente.
- Se notar código morto não relacionado, mencione; não delete.

Quando suas alterações criarem órfãos:

- Remova imports, variáveis e funções que AS SUAS alterações tornaram inutilizados.
- Não remova código morto preexistente, a menos que peçam.

O teste: toda linha alterada deve estar diretamente ligada à solicitação do usuário.

## 4. Execução Orientada a Objetivos

**Defina critérios de sucesso. Repita até verificar.**

Transforme tarefas em objetivos verificáveis:

- "Adicionar validação" → "Escrever testes para entradas inválidas e depois fazê-los passar"
- "Corrigir o bug" → "Escrever um teste que o reproduza e depois fazê-lo passar"
- "Refatorar X" → "Garantir que os testes passem antes e depois"

Para micro-planos de resposta (poucos passos, dentro de uma mesma mensagem), apresente um plano breve:

```
1. [Etapa] → verificar: [checagem]
2. [Etapa] → verificar: [checagem]
3. [Etapa] → verificar: [checagem]
```

Tarefas multi-etapa de verdade seguem o fluxo formal do harness: o plano nasce na `pelizzai-writing-plans`, vive em `pelizzai/plans/` e é estressado com `pelizzai-interview-me` antes da execução — este formato breve não o substitui.

Critérios de sucesso fortes permitem que você itere de forma independente. Critérios fracos ("fazer funcionar") exigem esclarecimentos constantes.

---

## O harness está funcionando se…

Sinais observáveis de que estas diretrizes e as skills estão cumprindo o papel:

- os diffs estão menores e sem mudanças não relacionadas ao pedido;
- há menos reescritas causadas por excesso de complexidade;
- as perguntas de esclarecimento vêm ANTES da implementação, não depois do erro;
- o histórico tem menos "fix do fix" (commits corrigindo o commit imediatamente anterior).

Sinais na direção contrária são gatilho para revisar as skills — não para abandoná-las.
