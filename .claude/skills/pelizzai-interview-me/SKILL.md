---
name: pelizzai-interview-me
description: Resolve ambiguidade material por entrevista ou submete uma ideia/design/plano existente a stress focal. Use quando o usuário pedir para ser entrevistado, quando evidência local não resolve uma decisão que muda escopo/risco/solução ou quando uma lane standard/exploratory ainda tem premissas críticas. Não use como etapa obrigatória de toda feature ou plano claro.
---

# PelizzAI Interview Me

## Objetivo

Obter as decisões humanas que a evidência não consegue fornecer, com o menor número de turnos.
Entrevista não substitui leitura do projeto nem serve para fabricar lacunas.

**Anuncie:** "Usando a skill PelizzAI Interview Me para resolver as decisões materiais ainda abertas."

## Modos

| Modo | Gatilho | Saída |
| --- | --- | --- |
| descoberta | objetivo/aceite tem interpretações materialmente diferentes | objetivo, escopo, restrições e decisão |
| stress focal | ideia/design/plano já existe, mas há premissa ou risco concreto | decisão, risco aceito/mitigado e alteração necessária |
| entrevista explícita | usuário pediu perguntas/entrevista | profundidade pedida, sem prolongar além do útil |

`pelizzai-brainstorming` cria o design. Esta skill resolve decisões humanas pendentes; se ainda não
há design ou opções concretas, devolva ao brainstorming.

## Antes de perguntar

1. Leia pedido, spec/plano, state e somente o código/documentação relevantes.
2. Separe fatos observados, inferências e decisões que pertencem ao usuário.
3. Remova perguntas cuja resposta já está no projeto ou tem default seguro/reversível.
4. Ordene o restante por dependência e impacto.

Não estime esforço como fato sem medir. Quando duas interpretações mudarem materialmente escopo ou
custo, mostre a evidência disponível e a consequência de cada uma.

## Como perguntar

- Agrupe perguntas **independentes** num lote curto para reduzir turnos.
- Faça uma por vez quando a próxima depende da resposta anterior.
- Use 2–3 opções somente quando forem reais e suficientemente completas; inclua recomendação com
  motivo quando a evidência sustentar uma.
- Use pergunta aberta para descoberta, linguagem de produto ou quando listar opções enviesaria a
  resposta.
- Não force “Outro”, quatro opções ou múltipla escolha por formato.
- Explique por que a resposta muda a entrega; corte perguntas cosméticas/reversíveis.

Se a ferramenta da plataforma impuser um formato específico de pergunta, siga-o sem alterar a
semântica deste contrato.

## Stress proporcional

Procure apenas falhas plausíveis para a superfície real:

```text
contrato/aceite ausente
estado de erro ou vazio relevante
autorização/segurança/dados
compatibilidade/migração/rollback
premissa de escala ou integração não confirmada
contradição entre spec, plano e código
```

Não invente uma lista de riscos para provar profundidade. Lane bounded normalmente dispensa esta
skill. Standard usa stress focal; exploratory pode exigir várias decisões, mas ainda encerra quando
o próximo passo deixa de depender do usuário.

## Critério de parada

Pare quando:

- nenhuma decisão humana aberta muda escopo, risco, autoridade ou solução;
- premissas críticas têm prova, dono ou aceitação explícita;
- o próximo passo e seu critério de sucesso estão claros.

Não busque “entendimento completo” de todo o sistema. Se uma resposta cria nova decisão dependente,
continue; se cria trabalho técnico investigável, devolva-o ao fluxo como tarefa, não como pergunta.

## Saída e handback

Retorne de forma compacta:

```text
Decisões:
- escolha — motivo/evidência

Riscos ou lacunas materiais:
- risco — mitigação, aceitação ou tarefa de investigação

Premissas abertas:
- somente as que ainda limitam a execução

Próximo passo:
- skill/artefato que retoma o controle
```

Se nenhum risco novo foi encontrado, diga isso; não fabrique um. Retorne ao chamador
(`pelizzai-brainstorming`, `pelizzai-writing-plans` ou router). Esta skill não escolhe team,
subagents, branch ou commit strategy.

## Red flags

```text
- Perguntar o que código/spec já responde.
- Uma pergunta por turno quando poderiam ser respondidas juntas.
- Lote de perguntas dependentes que muda após a primeira resposta.
- Quatro opções artificiais e recomendação sem evidência.
- Entrevista obrigatória em feature bounded clara.
- Continuar depois que o próximo passo não depende mais do usuário.
- Declarar que todo projeto necessariamente tem uma lacuna.
```

## Integração

Combina com `pelizzai-brainstorming`, `pelizzai-writing-plans` e `pelizzai-reasoning` somente quando
o router ou a evidência identificarem ambiguidade material.
