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

Use contexto, código e documentação antes de perguntar. Pergunte apenas quando a resposta muda escopo, risco, custo, autoridade ou solução. Se uma suposição segura e reversível bastar, declare-a brevemente e prossiga.

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
| Feature/refactor/infra com decisão de design | `pelizzai-brainstorming` |
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
- padrões do projeto → skills de domínio do catálogo;
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
- Confundir heurística (OODA/TDD/team) com invariante universal.
- Começar a escrever antes do router e do gate de primeira escrita.
```

## Instrução final

Entenda o objetivo, classifique o efeito e entregue ao router. Use a menor combinação de skills que preserve os invariantes e produza evidência suficiente.
