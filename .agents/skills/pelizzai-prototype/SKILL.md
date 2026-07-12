---
name: pelizzai-prototype
description: Overlay para construir um experimento descartável que responda uma pergunta de design mais barato que implementar ou discutir. Use para incerteza concreta de estado, integração, viabilidade ou UI. Não use como etapa obrigatória, demo polida ou atalho para produção; exige branch antes de escrita e remoção/absorção antes do seal.
---

# PelizzAI Prototype

## Objetivo

Comprar informação com o menor experimento possível. O protótipo existe para responder **uma
pergunta**; quando a resposta aparece, ele termina.

**Anuncie:** "Usando PelizzAI Prototype para responder `<pergunta>` com um experimento descartável."

## Gate

Use somente quando:

```text
[ ] existe uma incerteza material e falsificável;
[ ] análise, prior art ou teste menor não respondem com custo menor;
[ ] a resposta pode mudar o design;
[ ] há critério de parada e destino do código.
```

Os itens acima são o teste de adequação (decidir que um spike é o movimento certo continua seu
trabalho); eles **não** autorizam sozinhos escrever o experimento. Um protótipo descartável é decisão
estrutural e exige **aval explícito do usuário**, ratificado no gate certo — não no gate interno da
skill:

- com descoberta/plano → proponha o spike no gate de descoberta (`pelizzai-brainstorming`) ou no gate de setup pós-plano;
- track de escrita sem plano → inclua o spike no confirm de kickoff da head skill.

Recomende e aguarde: "posso gastar `<timebox>` num spike descartável para responder `<pergunta>`?
destino: `<apagar|absorver|virar tarefa>`". Sem "sim", não escreva o experimento.

Sob briefing fechado (SUBAGENT-STOP), não produza análises de rota nem abra gates: aplique o briefing e escale ao coordenador o que exigir decisão.

Protótipo escreve: passe por `pelizzai-starting-branch` antes. Use path temporário ignorado ou path
de protótipo já adotado pelo projeto. Source mode nunca cria runtime `pelizzai/`; prefira temp do
sistema ou estrutura nativa. Não inclua segredo/dado real desnecessário.

## Escolha a forma pela pergunta

| Pergunta | Experimento provável |
| --- | --- |
| Estado/regra/algoritmo | script/CLI mínimo com casos que discriminam os modelos |
| Integração/viabilidade | spike fino na fronteira real, sandbox/fixture e timeout explícito |
| UI/fluxo | uma ou mais variantes apenas quando há alternativas reais; overlay `pelizzai-frontend` e conteúdo plausível |

Não force várias variantes “radicalmente diferentes” quando uma hipótese basta. Não use UI para
responder pergunta de domínio nem mock para remover justamente a fronteira que está sendo testada.

## Contrato do experimento

Antes de codar, registre no plano/execution record:

```text
pergunta
hipótese/alternativas materiais
observação que confirma ou refuta
timebox/custo máximo
o que deliberadamente não terá qualidade de produção
destino: apagar | absorver | transformar em tarefa
```

Implemente o mínimo executável. “Descartável” reduz polish e abstração, não elimina segurança básica
nem a prova que responde à pergunta. Rode o cenário, preserve saída/limitações e pare no critério.

## Encerrar

1. Resuma evidência, resposta e confiança; inconclusivo é resultado válido.
2. Atualize design/plano nativo com a decisão. ADR só se estiver autorizado, houver path correto e
   passar o critério da `pelizzai-domain-modeling`; nunca registre automaticamente em `pelizzai/`.
3. Apague o código descartável ou absorva apenas as partes que passam pelo ciclo normal de
   implementação/teste/review.
4. Confirme que nenhum protótipo, fixture sensível, dependência ou flag temporária ficou antes do
   review final/seal.

## Red flags

```text
- Protótipo sem pergunta falsificável.
- Virar mini-produto com polish, abstrações e scope creep.
- Manter código experimental sem decisão explícita.
- Declarar viabilidade usando mock que remove o risco real.
- ADR automático ou runtime consumidor em source mode.
- Pular frontend em protótipo visual ou tratá-lo como QA final de produção.
```
