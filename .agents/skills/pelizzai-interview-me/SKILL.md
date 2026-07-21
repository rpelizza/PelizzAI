---
name: pelizzai-interview-me
description: Mecanismo canônico de tampar lacunas com o humano — a LLM não preenche decisão por default, convenção, Context7 ou inferência razoável. Obrigatória para abrir e para estressar design e plano (descoberta, pós-design, pós-plano) e sempre que a execução esbarrar em decisão que a spec/plano não cobrem: requisito ambíguo, contrato de interface indefinido, escolha de escopo/UX/arquitetura/dados/segurança/custo/aceite. Use também quando o usuário pedir perguntas ou stress. Pare a tarefa, faça uma pergunta por vez com 2–3 opções e a recomendada, registre a resposta no plano e só então retome.
---

# PelizzAI Interview Me

## Objetivo

Obter do humano as decisões que evidência não fornece. Esta skill é o **mecanismo canônico de tampar
lacunas** do harness: toda decisão não coberta por spec, plano ou ratificação anterior passa por
aqui, em qualquer fase — descoberta, design, plano ou execução. Preencher lacuna por default,
convenção, Context7 ou "inferência razoável" é violação, mesmo quando a escolha parece óbvia e
reversível.

Eficiência aqui significa perguntas bem ordenadas, não decisões agrupadas nem respostas presumidas.
Entrevista não substitui leitura do projeto nem serve para fabricar lacunas.

**Anuncie:** "Usando a skill PelizzAI Interview Me para resolver as decisões materiais ainda abertas."

## Modos

| Modo | Gatilho | Saída |
| --- | --- | --- |
| descoberta | objetivo/aceite tem interpretações materialmente diferentes | objetivo, escopo, restrições e decisão |
| stress focal | ideia/design/plano já existe, mas há premissa ou risco concreto | decisão, risco aceito/mitigado e alteração necessária |
| lacuna | a execução esbarrou em decisão que spec e plano não cobrem | decisão ratificada, registrada no plano, execução retomada |
| entrevista explícita | usuário pediu perguntas/entrevista | profundidade pedida, sem prolongar além do útil |

`pelizzai-brainstorming` cria o design. Esta skill resolve decisões humanas pendentes; se ainda não
há design ou opções concretas, devolva ao brainstorming.

## Onde é obrigatória

Nestes pontos a entrevista **não é oferta**: conduza-a até o fim e liste as lacunas antes de repassar
o controle.

1. **Antes do design** — o pedido admite duas ou mais leituras materialmente diferentes: entreviste
   para fixar objetivo, escopo, restrições e aceite antes de a `pelizzai-brainstorming` desenhar
   qualquer coisa.
2. **Depois do design, antes de a spec fechar** — estresse o design e **exponha as lacunas** (casos
   não tratados, validação ausente, falha de autorização/segurança, estados indefinidos,
   contradições). Devolva o controle ao brainstorming para ele concluir spec e aprovação.
3. **Depois do plano, antes da execução** — estresse o plano da `pelizzai-writing-plans`: cada
   decisão técnica material sem origem de ratificação vira pergunta aqui, nunca fato consumado.
4. **Durante a execução, a cada lacuna** — protocolo na seção "Modo lacuna".

O ciclo greenfield (descoberta → spec → stress → aprovação → plano → stress → aprovação) percorre
1–3 sempre, mesmo com a stack já definida. Uma lane `bounded` que o próprio usuário já especificou
(objetivo, aceite e abordagem dados) dispensa 1–3, mas **nunca dispensa o item 4**: o gatilho é a
lacuna, não a lane.

Encerrar mais cedo só é permitido depois que as lacunas tiverem sido **realmente identificadas e
resolvidas** — ou explicitamente aceitas pelo usuário. Nunca pule a etapa "para economizar tempo": o
custo de descobrir a lacuna depois da implementação é sempre maior.

## O que é lacuna — e o que não é

Lacuna é a decisão cuja resposta muda **produto/UX, escopo, arquitetura, dados, segurança, custo ou
aceite**. Se nada disso muda, não é lacuna, não vira pergunta e a entrevista não vira cerimônia.

```text
NÃO é lacuna — resolva sozinho:
- fato verificável no repositório (código, teste, manifest, lockfile, spec, plano, state);
- fato externo verificável na versão em uso via Context7 ou documentação oficial;
- passo mecânico dentro de fronteira já ratificada em spec, plano ou decisão anterior;
- detalhe de implementação sem efeito observável (nome interno, ordem de helpers, formatação,
  refactor local que preserva o contrato).

É lacuna — PARE e pergunte:
- requisito, aceite ou prioridade que admite duas leituras materialmente diferentes;
- contrato de interface indefinido (assinatura, payload, erro, estado vazio, autorização);
- escolha de escopo, UX, arquitetura ou modelo de dados que spec e plano não escreveram;
- trade-off de custo, performance ou risco que ninguém aceitou explicitamente;
- contradição entre spec, plano e código.
```

Uma decisão de produto não deixa de ser lacuna porque existe um default comum, seguro ou reversível
— o default vira a **recomendação** da pergunta, não a resposta. Context7 e documentação oficial
fundamentam opções; nunca ratificam uma decisão que pertence ao usuário.

## Antes de perguntar

1. Leia pedido, spec/plano, o registro da tarefa (state consumidor ou execution record nativo) e somente o código/documentação relevantes.
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

## Modo lacuna: tampar o buraco durante a execução

Gatilho: implementando uma tarefa — inline, como subagente ou como membro de time — você esbarra numa
decisão que spec e plano não cobrem. Vale o teste operacional de desvio: **se a decisão não está
escrita na spec, no plano nem no registro da tarefa (state consumidor ou execution record nativo),
ela não está aprovada — apresente antes de implementar.**

1. **PARE a tarefa.** Não implemente "a leitura mais provável" para mostrar depois, não deixe TODO,
   flag ou parâmetro configurável para adiar a decisão, e não continue por outro arquivo enquanto
   guarda a dúvida. Código escrito sobre lacuna preenchida sozinho é retrabalho, não progresso.
2. **Nomeie a lacuna em uma frase**: o que está indefinido e qual dos efeitos materiais ela muda
   (produto/UX, escopo, arquitetura, dados, segurança, custo ou aceite).
3. **Traga 2–3 opções reais**, cada uma com a consequência em uma linha, e marque
   `Recomendado: <opção> — <motivo>`. Opções de fachada (uma boa e duas absurdas) não são opções; a
   inteligência está em construir alternativas boas e fundamentá-las com evidência do repo/Context7.
4. **Uma pergunta por vez**, começando pela decisão que condiciona as demais; recalcule as opções
   seguintes depois de cada resposta. Nunca despeje o bloco inteiro de lacunas como questionário.
5. **Registre a resposta no plano**, em `## Decisões técnicas deste plano`, na linha canônica
   (`decisão — ratificada: entrevista de execução — rejeitada: <alternativa> — porquê: <motivo>`); se
   sobrou risco residual, acrescente-o a `## Lacunas materiais expostas`. Source mode ou tarefa sem
   arquivo de plano: registre no execution record nativo, de forma verificável, sem criar
   `pelizzai/`.
6. **Retome a tarefa** exatamente do ponto em que parou, agora dentro de fronteira ratificada.

**Sob briefing fechado** (`SUBAGENT-STOP` / `MEMBRO-DO-TIME-STOP`) o executor não abre gate nem
entrevista o usuário: pare no passo 1, monte os passos 2 e 3 e retorne `NEEDS_CONTEXT` com a lacuna
nomeada, as opções e a recomendada, declarando-a também em `Desvios do plano:`. Quem conduz a
entrevista é o coordenador; ele re-despacha a tarefa depois da ratificação.

Se a lacuna for grande a ponto de desfazer o plano, não a tampe por entrevista pontual: devolva a
`pelizzai-writing-plans` (replanejar) ou a `pelizzai-brainstorming` (redesenhar).

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

Não invente uma lista de riscos para provar profundidade. A lane `bounded` costuma dispensar o stress
de design e de plano, mas `bounded` com lacuna material continua chamando esta skill — o gatilho é a
lacuna, não a lane. Standard usa stress focal; exploratory/greenfield percorre as decisões
sequencialmente e encerra quando spec/plano podem ser aprovados sem a LLM inventar requisitos.

Quando a lacuna vier marcada pela **Análise da proposta** do `pelizzai-router`
([proposal-stress.md](../pelizzai-reasoning/techniques/proposal-stress.md)), entre já em stress focal
sobre as premissas materiais que ela apontou: aquela análise é o inventário; esta entrevista é a
resolução.

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
lacuna. Retorne ao chamador (`pelizzai-brainstorming`, `pelizzai-writing-plans`,
`pelizzai-execution-plans` ou router). No modo lacuna, o handback é a tarefa interrompida: retome-a
com a decisão já escrita no plano. Esta skill não escolhe team, subagents, branch ou commit strategy.

## Red flags

```text
- Preencher a lacuna sozinho por default, convenção, Context7 ou "inferência razoável".
- Implementar a leitura mais provável e apresentar a decisão como fato consumado.
- Guardar as lacunas para perguntar em lote no fim da tarefa.
- Perguntar o que código/spec já responde, ou fabricar lacuna onde não há efeito material.
- Mais de uma pergunta por turno.
- Lote de perguntas que impede recalcular opções após cada resposta.
- Quatro opções artificiais e recomendação sem evidência.
- Pular o stress obrigatório de design ou de plano "para economizar tempo".
- Pular entrevista em produto/projeto greenfield porque a stack está definida.
- Repassar o controle sem ter exposto explicitamente as lacunas — revelá-las é o objetivo.
- Tratar documentação externa como resposta a uma decisão do usuário.
- Continuar depois que o próximo passo não depende mais do usuário.
- Declarar que todo projeto necessariamente tem uma lacuna.
```

## Integração

- `pelizzai-brainstorming` — entrevista antes do design e stress obrigatório depois dele.
- `pelizzai-writing-plans` — stress obrigatório do plano; decisão emergente vira pergunta aqui.
- `pelizzai-execution-plans` / `pelizzai-loop` — destino da parada por dúvida material no meio da
  execução (modo lacuna); `pelizzai-subagents` e `pelizzai-team` escalam ao coordenador.
- `pelizzai-reasoning` — a Análise da proposta
  ([proposal-stress.md](../pelizzai-reasoning/techniques/proposal-stress.md)) inventaria as premissas
  materiais que esta entrevista resolve.
