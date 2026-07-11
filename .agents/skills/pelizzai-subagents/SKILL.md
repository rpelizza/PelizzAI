---
name: pelizzai-subagents
description: Use para delegar uma tarefa focada e independente a UM subagente isolado (ou alguns subagentes independentes que só reportam de volta) — pesquisa, varredura/mapeamento do código, análise, ou uma implementação contida. Subagentes não conversam entre si; para um TIME de papéis que precisam dialogar/coordenar, use `pelizzai-team`. Acione quando o usuário disser "delega isso", "manda um subagente", ou quando a execução for em modo subagents.
---

# PelizzAI Subagents

## Objetivo

Delegar trabalho a um **subagente isolado**: contexto próprio, sem poluir o seu, que executa e **reporta de volta**. É o caminho leve — quando você precisa do **resultado** de uma frente, não de um diálogo entre papéis.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Subagents para delegar a um subagente."

> **Fronteira com a `pelizzai-team`:** use **subagents** para uma frente independente que só
> reporta. Use **team** quando múltiplos papéis precisam dialogar/coordenar. Branch ou worktree da
> tarefa continua sendo uma working tree compartilhada: investigação pode ser paralela; escrita é
> aplicada em série pelo coordenador.

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
  (state consumidor ou execution record source): branch e worktree têm um writer por vez; o coordenador integra as
  escritas EM SÉRIE. Worktree isola a tarefa do principal, não os agentes entre si.
```

## Briefing autossuficiente

O subagente **não herda o seu contexto** — construa o prompt. Em execução de plano, use
`task-brief.*` apenas com plano Markdown persistente compatível; plano nativo usa conteúdo colado.
O handoff dir é gitignored no consumidor e temp em source mode (ver task-cycle §1):

```text
- Objetivo: o resultado único e claro esperado.
- Contexto necessário: caminhos, contratos, decisões já tomadas, convenções (o subagente não viu a conversa).
- Regras/skills locais relevantes: consumidor usa o catálogo; source mode usa o repo-fonte. Cole os
  pontos operacionais — o subagente deve aplicá-los em vez de padrões genéricos.
- Camada global: instrua o subagente a aplicar `pelizzai-preferences` e a raciocinar via
  `pelizzai-reasoning`; em conflito, as SKILLS DE DOMÍNIO coladas e as regras do projeto PREVALECEM.
- Raciocínio: técnica principal sugerida de `pelizzai-reasoning` conforme a tarefa. Para APIs de
  libs externas, fundamente na documentação oficial atual disponível — não na memória.
- Contrato de entrega: o formato EXATO do retorno (lista de achados arquivo:linha; diff; relatório X/Y/Z).
- Salvo-conduto (no texto do briefing): é sempre OK parar e dizer "isso é difícil demais para mim" —
  trabalho ruim é pior que trabalho nenhum; o subagente não será penalizado por escalar.
- Restrições: o que não tocar; só leitura, quando aplicável.
```

## Verificação e integração

O resultado de um subagente **não** é verdade até ser conferido. Para implementação, passe pelas
duas lentes do `pelizzai-review` no perfil proporcional (`combined` ou `split`) e pela
`pelizzai-verification-before-completion` antes de consolidar. Para pesquisa, cruze achados
conflitantes e desconfie de relatório não verificado.

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
