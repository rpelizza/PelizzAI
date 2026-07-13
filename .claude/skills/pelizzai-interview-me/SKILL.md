---
name: pelizzai-interview-me
description: Obtém decisões humanas por entrevista sequencial ou submete ideia, design e plano a stress focal. Use em todo produto/projeto greenfield, quando o usuário pedir perguntas, quando evidência não resolve decisão de escopo/UX/arquitetura/dados/segurança/aceite ou quando standard/exploratory ainda tem premissas críticas. Faça uma pergunta por vez e recomende a melhor opção; não use para fatos já observáveis nem para ajuste bounded já especificado.
---

# PelizzAI Interview Me

## Objetivo

Obter decisões humanas que evidência não pode fornecer. Eficiência aqui significa perguntas bem
ordenadas, não decisões agrupadas nem respostas presumidas. Entrevista não substitui leitura do
projeto nem serve para fabricar lacunas.

**Anuncie:** "Usando a skill PelizzAI Interview Me para resolver as decisões materiais ainda abertas."

## Modos

| Modo | Gatilho | Saída |
| --- | --- | --- |
| descoberta | objetivo/aceite tem interpretações materialmente diferentes | objetivo, escopo, restrições e decisão |
| stress focal | ideia/design/plano já existe, mas há premissa ou risco concreto | decisão, risco aceito/mitigado e alteração necessária |
| entrevista explícita | usuário pediu perguntas/entrevista | profundidade pedida, sem prolongar além do útil |

`pelizzai-brainstorming` cria o design. Esta skill resolve decisões humanas pendentes; se ainda não
há design ou opções concretas, devolva ao brainstorming.

Esta skill é obrigatória no ciclo greenfield e proposta nos demais fluxos quando houver lacuna
material. Evidência local que resolve um fato dispensa a pergunta; evidência não responde uma
preferência ou política de produto pelo usuário.

## Antes de perguntar

1. Leia pedido, spec/plano, state e somente o código/documentação relevantes.
2. Separe fatos observados, inferências e decisões que pertencem ao usuário.
3. Remova perguntas factuais cuja resposta já está no projeto. Não remova decisão de produto porque
   existe um default comum, seguro ou reversível; transforme-o na recomendação da pergunta.
4. Ordene o restante por dependência e impacto.

Não estime esforço como fato sem medir. Quando duas interpretações mudarem materialmente escopo ou
custo, mostre a evidência disponível e a consequência de cada uma.

## Como perguntar

- Faça **exatamente uma pergunta por turno**. Ordene-a pela decisão de maior impacto que condiciona
  as seguintes; após a resposta, recalcule o roteiro da entrevista.
- Use 2–3 opções somente quando forem reais e suficientemente completas; destaque
  `Recomendado: <opção> — <motivo>` antes da pergunta.
- Use pergunta aberta para descoberta, linguagem de produto ou quando listar opções enviesaria a
  resposta.
- Não force “Outro”, quatro opções ou múltipla escolha por formato.
- Explique por que a resposta muda a entrega. Corte perguntas cosméticas que não alteram o resultado;
  escolhas reversíveis de produto continuam pertencendo ao usuário, mas podem ser explicitamente
  delegadas por ele.

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

Não invente uma lista de riscos para provar profundidade. A lane `bounded` costuma dispensar esta
skill, mas `bounded` com lacuna material também pode oferecê-la — o gatilho é a lacuna, não a lane.
Standard usa stress focal; exploratory/greenfield percorre as decisões sequencialmente e encerra
quando spec/plano podem ser aprovados sem a LLM inventar requisitos.

## Critério de parada

Pare quando:

- nenhuma decisão humana aberta muda requisito, escopo, UX, arquitetura, dados, segurança, risco,
  autoridade, aceite ou solução;
- premissas críticas têm prova, dono ou aceitação explícita;
- o próximo passo e seu critério de sucesso estão claros.

Não busque “entendimento completo” de todo o sistema. Se uma resposta cria nova decisão dependente,
continue; se cria trabalho técnico investigável, devolva-o ao fluxo como tarefa, não como pergunta.

## Saída e handback

A entrevista **termina com a lista numerada de lacunas e como cada uma muda a solução** — caça ativa,
não prosa: aponte cada lacuna material ainda que o usuário não a tenha citado e diga como ela foi
resolvida, explicitamente aceita ou convertida em tarefa de investigação.
Um resumo sem a seção de lacunas está incompleto.

Retorne de forma compacta:

```text
Decisões:
- escolha — motivo/evidência

Lacunas (numeradas — cada uma com o que muda na solução):
1. lacuna — muda escopo/UX/arquitetura/segurança/dados — resolvida, aceita ou vira tarefa
2. ...

Premissas abertas:
- somente as que ainda limitam a execução

Próximo passo:
- skill/artefato que retoma o controle
```

Se nenhum risco novo foi encontrado, diga isso; não fabrique um nem declare que todo projeto tem uma
lacuna. Retorne ao chamador (`pelizzai-brainstorming`, `pelizzai-writing-plans` ou router). Esta
skill não escolhe team, subagents, branch ou commit strategy.

## Red flags

```text
- Perguntar o que código/spec já responde.
- Mais de uma pergunta por turno.
- Lote de perguntas que impede recalcular opções após cada resposta.
- Quatro opções artificiais e recomendação sem evidência.
- Pular entrevista em produto/projeto greenfield porque a stack está definida.
- Tratar documentação externa como resposta a uma decisão do usuário.
- Continuar depois que o próximo passo não depende mais do usuário.
- Declarar que todo projeto necessariamente tem uma lacuna.
```

## Integração

Combina com `pelizzai-brainstorming`, `pelizzai-writing-plans` e `pelizzai-reasoning` somente quando
o router ou a evidência identificarem ambiguidade material.
