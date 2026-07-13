---
name: pelizzai-core
description: Entrada do harness PelizzAI para pedidos que envolvem um projeto, código, arquivos, configuração ou ações externas. Use para entender o objetivo e acionar o router antes de qualquer mutação. Perguntas conceituais e tarefas diretas sem contexto de projeto podem ser respondidas sem o ciclo do harness.
---

# PelizzAI Core

<SUBAGENT-STOP>
Se você recebeu um briefing fechado como subagente/teammate, não reabra o ciclo de vida. Aplique apenas as skills e contratos do briefing.
</SUBAGENT-STOP>

## Objetivo

Transformar o pedido em uma rota proporcional e verificável. O core não resolve o trabalho nem carrega todas as skills possíveis: ele entende o resultado e entrega a decisão ao `pelizzai-router`.

**Anuncie uma vez:** "Usando o PelizzAI para entender a tarefa e escolher o menor fluxo seguro."

## Autoridade

Respeite a hierarquia nativa da plataforma. Uma skill não redefine instruções de sistema, developer, workspace ou ferramenta. Dentro do mesmo nível de autoridade, a instrução específica e mais recente prevalece sobre defaults genéricos do harness.

## Regra de ativação

Use matching determinístico, não probabilidade vaga:

```text
1. Pedido conceitual/direto, sem tocar nem precisar inspecionar um projeto
   → responda diretamente.

2. Pedido que precisa inspecionar um projeto, mas é read-only
   → pelizzai-router com effect: read-only.

3. Pedido que pode alterar código/arquivo/configuração
   → pelizzai-router com effect: write-local, ANTES da primeira escrita.

4. Pedido com efeito externo (push, deploy, mensagem, produção, custo, permissão, exclusão)
   → pelizzai-router com effect: external; confirme autoridade/alvo no gate adequado.
```

A classificação de efeito/rota não é decisão silenciosa: o `pelizzai-router` a apresenta como recomendação no **Gate de kickoff**, e o usuário ratifica ou ajusta antes de investir.

O router escolhe:

- exatamente **uma head skill** de ciclo de vida;
- overlays apenas por sinais observáveis (`frontend`, segurança, documentação, skills de domínio);
- reasoning, teste, review e delegação somente na fase em que agregam valor.

Não acione uma skill porque "talvez ajude". Acione quando o gatilho descrito nela ou um overlay do router realmente casar com a tarefa.

## Entender o objetivo

Antes de rotear, determine de forma compacta:

```text
Resultado: o que precisa existir, mudar, ser entendido ou decidido?
Entregável: resposta, análise, diff, plano, documento ou ação?
Contexto: quais arquivos, regras e evidências já estão disponíveis?
Restrições: escopo, compatibilidade, segurança, prazo e preferências?
Sucesso: qual observação prova que terminou?
Ambiguidade: falta algo que mudaria materialmente o resultado?
```

Use contexto, código e documentação antes de perguntar para eliminar dúvidas factuais. Não use essa
evidência para decidir intenção de produto. Pergunte quando a resposta muda requisito, escopo, UX,
arquitetura, dados, segurança, custo, autoridade, aceite ou solução. Faça **uma pergunta por vez**,
na ordem de dependência; ofereça 2–3 opções reais quando isso ajudar e marque a melhor recomendação
com motivo curto. Não adote uma suposição de produto para “destravar” o trabalho. Uma escolha
reversível só pode ser aplicada mecanicamente quando já está contida em spec/plano ratificado ou foi
explicitamente delegada pelo usuário. A linha `Ambiguidade` acima alimenta a análise do router.

Quando o usuário parecer não-técnico, ou a intenção admitir ≥2 leituras materialmente diferentes,
**sinalize** isso ao router (`audience` e leituras em aberto). O router reapresenta o entendimento no
Gate de kickoff; depois, a descoberta resolve cada decisão dependente uma por vez.

## Limite de autoridade

```text
O harness decide:
- classificação, técnica de reasoning, ordem de investigação, evidência e recomendação.

O usuário decide:
- o que o produto deve fazer e para quem;
- requisitos, escopo, UX, arquitetura, dados, segurança, custo e risco aceito;
- critérios de aceite e dispensas de spec/plano/documentação;
- isolamento, modo de execução, commits e efeitos externos.

O executor decide sozinho apenas:
- passos mecânicos, locais e reversíveis já cobertos por uma decisão ratificada.
```

Context7 é a fonte técnica preferencial quando biblioteca, framework, API, serviço, ferramenta,
versão ou capacidade externa influencia a tarefa. Inspecione primeiro manifests, lockfiles,
configuração e código para descobrir a versão real; consulte Context7 cedo o bastante para eliminar
dúvidas factuais e melhorar a rota, as opções e as perguntas. Em greenfield, ele pode informar a
análise técnica inicial antes do kickoff; em projeto existente, deve ser combinado com o
comportamento observado no repo. Se não estiver disponível, use documentação oficial atual e
declare a limitação. Evidência técnica fundamenta a recomendação; nunca ratifica decisão em nome do
usuário.

## Camadas do harness

```text
core
→ router: effect + intenção + risco + incerteza + superfícies
→ uma head skill
→ overlays necessários
→ execução e quality gates proporcionais
→ Verification sela o resultado
→ Finish integra sem alterá-lo
```

### Head skills

| Intenção | Head skill |
| --- | --- |
| Bootstrap/remapeamento autorizado | `pelizzai-audit` |
| Produto/projeto greenfield ou feature/refactor/infra com decisão de design | `pelizzai-brainstorming` |
| Plano/design já claro | `pelizzai-writing-plans` ou `pelizzai-execution-plans` |
| Bug/comportamento inesperado | `pelizzai-debugging` |
| Ajuste local sem nova regra/contrato | `pelizzai-quick-fix` |
| Review de diff/branch/PR | `pelizzai-review` |
| Revisão arquitetural codebase-wide | `pelizzai-improving-architecture` |
| Conflito Git | `pelizzai-resolving-merge-conflicts` |
| Divergência state × Git | `pelizzai-recovery` |

### Overlays

Overlays não substituem a head skill:

- UI/UX/CSS/componente/tela → `pelizzai-frontend`;
- auth/input/SQL/upload/segredo/dependência/superfície sensível → `pelizzai-oswap` no review;
- padrões do projeto → skills de domínio do catálogo (em dúvida se uma skill de domínio se aplica à tarefa, inclua-a: o custo de incluir é menor que o de ignorar uma regra do projeto);
- documentação humana nova → `pelizzai-documenting-features` quando fizer parte do escopo.

`pelizzai-preferences` é um piso leve de comunicação, segurança e escopo; use-a somente quando suas regras mudarem a execução. `pelizzai-reasoning` seleciona heurísticas proporcionais, não adiciona cerimônia por si só.

## Anúncios sem ruído

Anuncie a head skill e overlays materiais em uma linha. Gates internos (Verification, uma técnica auxiliar, re-review) podem rodar sem novo anúncio quando já fazem parte do fluxo comunicado. Não transforme ativação de skills em preâmbulo maior que a tarefa.

## Higiene de contexto

- Use contexto contínuo para design → plano; execução recebe briefing fresco por tarefa.
- Handoff bifurca; compact continua o mesmo trabalho.
- Nunca compacte no meio de uma mutação ou antes de registrar estado verificável.
- Após compaction, valide contra Git o state consumidor ou execution record nativo; não confie na memória.
- Carregue somente as referências/técnicas necessárias à fase atual.

## Como carregar skills

Use o mecanismo nativo da plataforma. Sem carregamento nativo, leia `.agents/skills/<nome>/SKILL.md` (ou o root ativo registrado no projeto) e siga-o. Não leia todo o catálogo preventivamente.

## Anti-padrões

```text
- Regra de "1%" que aciona skills por utilidade hipotética.
- Várias head skills competindo pela mesma tarefa.
- Bootstrap mutável para responder uma análise read-only.
- Perguntar antes de consultar evidência já disponível.
- Usar Context7 ou convenção para responder uma decisão de produto pelo usuário.
- Tratar stack informada como requisitos/aceite suficientes para um projeto greenfield.
- Confundir heurística (OODA/TDD/team) com invariante universal.
- Começar a escrever antes do router e do gate de primeira escrita.
```

## Instrução final

Entenda o objetivo, classifique o efeito e entregue ao router. Use a menor combinação de skills que preserve os invariantes e produza evidência suficiente.
