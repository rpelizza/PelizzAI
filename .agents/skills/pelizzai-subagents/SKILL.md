---
name: pelizzai-subagents
description: Use para delegar uma tarefa focada e independente a UM subagente isolado (ou alguns subagentes independentes que só reportam de volta) — pesquisa, varredura/mapeamento do código, análise, ou uma implementação contida. O subagente tem contexto próprio, recebe um briefing autossuficiente, aplica as skills de domínio e devolve o resultado ao coordenador; subagentes não conversam entre si. Para um TIME de papéis que precisam dialogar/coordenar, use `pelizzai-team`. Acione quando o usuário disser "delega isso", "manda um subagente", ou quando a execução for em modo subagents.
---

# PelizzAI Subagents

## Objetivo

Delegar trabalho a um **subagente isolado**: contexto próprio, sem poluir o seu, que executa e **reporta de volta**. É o caminho leve — quando você precisa do **resultado** de uma frente, não de um diálogo entre papéis.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Subagents para delegar a um subagente."

> **Fronteira com a `pelizzai-team`:** use **subagents** para uma frente independente que só reporta (um subagente por tarefa, em série). Use **`pelizzai-team`** quando há **múltiplos papéis** que se beneficiam de dialogar, dividir uma task list e se coordenar. Escrita paralela depende do isolamento escolhido no gate: em `branch`, o coordenador integra **em série**; em `worktree`, frentes com caminhos disjuntos podem escrever em paralelo dentro do worktree da tarefa.

<MEMBRO-DO-TIME-STOP>
Se você é o subagente despachado, execute apenas a sua tarefa: acione `pelizzai-reasoning`, aplique as skills de domínio coladas no seu briefing (elas prevalecem sobre padrões genéricos) e a camada global `pelizzai-preferences`, e devolva o resultado no formato combinado. Não delegue sub-subagentes nem orquestre o fluxo. Em tarefa de implementação, **não commite** — a consolidação é do coordenador, após review e verificação.
</MEMBRO-DO-TIME-STOP>

---

## Mecânica

```text
- Ferramenta Agent/Task: o subagente tem janela de contexto própria, SÓ devolve seu texto final ao
  coordenador, NÃO conversa com outros subagentes, e ENCERRA ao retornar (sem memória entre chamadas).
- agentTypes: Explore (busca read-only), Plan (arquiteto read-only), general-purpose, ou customizado.
  Read-only (Explore/Plan) NÃO editam arquivos — papéis de escrita exigem general-purpose ou customizado.
- Paralelismo: para subagentes independentes, emita várias chamadas Agent numa única mensagem.
  Leitura em paralelo é segura; escrita exige arquivos disjuntos e depende do isolamento
  (pelizzai/data/state.md): em `branch`, o coordenador integra as escritas EM SÉRIE; em
  `worktree`, escrita paralela é permitida em caminhos disjuntos dentro do worktree da tarefa.
```

## Briefing autossuficiente

O subagente **não herda o seu contexto** — cole no prompt tudo o que ele precisa (em execução de plano com `scripts/task-brief.*` no projeto, o briefing da tarefa viaja por **arquivo** em `pelizzai/data/handoffs/` — ver `pelizzai-execution-plans` → `references/task-cycle.md` §1):

```text
- Objetivo: o resultado único e claro esperado.
- Contexto necessário: caminhos, contratos, decisões já tomadas, convenções (o subagente não viu a conversa).
- Skills de domínio relevantes: cole-as (ou os pontos-chave) do catálogo pelizzai/domain-skills.md — o
  subagente deve aplicá-las em vez de padrões genéricos.
- Camada global: instrua o subagente a aplicar `pelizzai-preferences` e a raciocinar via
  `pelizzai-reasoning`; em conflito, as SKILLS DE DOMÍNIO coladas e as regras do projeto PREVALECEM.
- Raciocínio: técnica principal sugerida de `pelizzai-reasoning` conforme a tarefa. Para APIs de
  libs externas, fundamente no MCP `context7` — não na memória.
- Contrato de entrega: o formato EXATO do retorno (lista de achados arquivo:linha; diff; relatório X/Y/Z).
- Salvo-conduto (no texto do briefing): é sempre OK parar e dizer "isso é difícil demais para mim" —
  trabalho ruim é pior que trabalho nenhum; o subagente não será penalizado por escalar.
- Restrições: o que não tocar; só leitura, quando aplicável.
```

## Verificação e integração

O resultado de um subagente **não** é verdade até ser conferido. Para implementação, passe pelo review (`pelizzai-review`, dois estágios) e pela `pelizzai-verification-before-completion` (evidência fresca) antes de consolidar. Para pesquisa, cruze achados conflitantes e desconfie de relatório não verificado.

---

## Anti-padrões

```text
- Esperar que subagentes se coordenem sozinhos (eles não se falam) — isso é trabalho do coordenador.
- Mandar um papel de escrita a um agentType read-only (Explore/Plan não editam).
- Briefing vago, ou assumir que o subagente tem o histórico da conversa.
- Tratar o relatório do subagente como verdade sem conferir (diff do git / evidência fresca).
- Usar subagents para um TIME de papéis que precisam dialogar — isso é `pelizzai-team`.
```

---

## Integração

**Combina com:**

- `pelizzai-team` — o time completo (vários papéis, task list, diálogo); subagents é a delegação a UM agente.
- `pelizzai-reasoning` / `pelizzai-preferences` — camada de raciocínio e piso global instruídos no briefing (skills de domínio prevalecem).
- `pelizzai-execution-plans` — modo `subagents`: um subagente por tarefa, despachado pelo coordenador.
- `pelizzai-review` / `pelizzai-verification-before-completion` — conferir o resultado antes de consolidar.
- `pelizzai-audit` — catálogo de skills de domínio coladas no briefing.
