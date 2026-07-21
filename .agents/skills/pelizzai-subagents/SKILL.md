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
> tarefa continua sendo uma working tree compartilhada — ela não isola agentes entre si.
> Investigação é sempre paralelizável; a escrita segue o isolamento ratificado: em `branch`, o
> coordenador aplica em série; em `worktree`, frentes com **caminhos disjuntos** escrevem em
> paralelo dentro do worktree único da tarefa.

<MEMBRO-DO-TIME-STOP>
Se você é o subagente despachado, execute apenas a sua tarefa: acione `pelizzai-reasoning`, aplique as skills de domínio coladas no seu briefing (elas prevalecem sobre padrões genéricos) e a camada global `pelizzai-preferences`, e devolva o resultado no formato combinado. Não delegue sub-subagentes nem orquestre o fluxo. Em tarefa de implementação, **não commite** — a consolidação é do coordenador, após review e verificação.

Sob briefing fechado (MEMBRO-DO-TIME-STOP/SUBAGENT-STOP), não produza análises de rota nem abra gates: aplique o briefing, **sinalize no retorno** (`DONE_WITH_CONCERNS`/`NEEDS_CONTEXT`) se faltou skill de domínio cobrindo a stack da sua tarefa, e escale ao coordenador o que exigir decisão.

Você **não decide lacuna de produto**. Se requisito, escopo, UX, arquitetura, dados, segurança,
custo ou critério de aceite não estiver escrito no briefing, no plano ou na spec, **nomeie a
lacuna** — o que falta, o que ela muda na entrega e 2–3 opções que você enxerga, com a que
recomenda — e devolva `NEEDS_CONTEXT`. Não preencha por convenção, default, Context7 ou "inferência
razoável", mesmo que a escolha pareça óbvia e reversível; quem leva a lacuna ao humano é o
coordenador.
</MEMBRO-DO-TIME-STOP>

---

## Mecânica

```text
- Ferramenta Agent/Task: o subagente tem janela de contexto própria, SÓ devolve seu texto final ao
  coordenador, NÃO conversa com outros subagentes, e ENCERRA ao retornar (sem memória entre chamadas).
- agentTypes: Explore (busca read-only), Plan (arquiteto read-only), general-purpose, ou customizado.
  Read-only (Explore/Plan) NÃO editam arquivos — papéis de escrita exigem general-purpose ou customizado.
- Paralelismo: para subagentes independentes, emita várias chamadas Agent numa única mensagem.
  Leitura em paralelo é segura; escrita exige arquivos disjuntos e depende do isolamento ratificado
  (state consumidor ou execution record source): em `branch`, um writer por vez e o coordenador
  integra as escritas EM SÉRIE; em `worktree`, escrita paralela é permitida em CAMINHOS DISJUNTOS
  dentro do worktree único da tarefa (nunca um worktree por agente). Worktree isola a tarefa do
  principal, não os agentes entre si — quem serializa é a regra, não o Git; review, stage, commit e
  cursor são sempre do coordenador.
```

## Briefing autossuficiente

O subagente **não herda o seu contexto** — construa o prompt. Em execução de plano, use
`task-brief.*` apenas com plano Markdown persistente compatível; plano nativo usa conteúdo colado.
O handoff dir é gitignored no consumidor e temp em source mode (ver task-cycle §1):

```text
- Objetivo: o resultado único e claro esperado.
- Contexto necessário: caminhos, contratos, decisões já tomadas, convenções (o subagente não viu a conversa).
- Regras/skills locais relevantes: monte um ESPECIALISTA — quando o subagente encarna um papel de
  área (ex.: implementador-backend), nomeie-o pela área e cole o pacote **COMPLETO** de skills de
  domínio dessa área (consumidor usa o catálogo; source mode usa o repo-fonte), não só as que parecem
  aplicar à tarefa específica. Em dúvida se uma skill de domínio do catálogo pertence à área,
  inclua-a: o custo de incluir é menor que o de ignorar uma regra do projeto. Cole os pontos
  operacionais — o subagente deve aplicá-los em vez de padrões genéricos. Se a área não tem skill
  cobrindo, diga isso e peça que o subagente sinalize a lacuna no retorno.
- Camada global: instrua o subagente a aplicar `pelizzai-preferences` e a raciocinar via
  `pelizzai-reasoning`; em conflito, as SKILLS DE DOMÍNIO coladas e as regras do projeto PREVALECEM.
- Raciocínio: técnica principal sugerida de `pelizzai-reasoning` conforme a tarefa. Para APIs de
  libs externas, fundamente na documentação oficial atual disponível — não na memória.
- Contrato de entrega: o formato EXATO do retorno (lista de achados arquivo:linha; diff; relatório X/Y/Z).
- Salvo-conduto (no texto do briefing): é sempre OK parar e dizer "isso é difícil demais para mim" —
  trabalho ruim é pior que trabalho nenhum; o subagente não será penalizado por escalar.
- Lacuna material (no texto do briefing): se requisito, escopo, UX, arquitetura, dados, segurança
  ou aceite não estiver escrito no briefing, no plano ou na spec, PARE, NOMEIE a lacuna (o que
  falta + o que ela muda + 2–3 opções com a recomendada), devolva `NEEDS_CONTEXT` e declare-a
  também em `Desvios do plano:`. Não preencha por default nem por "inferência razoável" — quem leva
  a decisão ao humano é o coordenador, pela `pelizzai-interview-me` (modo lacuna).
- Restrições: o que não tocar; só leitura, quando aplicável.
```

## Verificação e integração

O resultado de um subagente **não** é verdade até ser conferido. Para implementação, passe pelas
duas lentes do `pelizzai-review` no perfil proporcional (`combined` ou `split`). No `split`, a
cegueira é assimétrica: a **lente spec cega** recebe só diff + spec/plano + domain skills da área e
**NÃO recebe o relatório** do subagente (julga o código contra o contrato, sem a narrativa); a
**lente qualidade/evidência** recebe o relatório e verifica as alegações com prova fresca. O
coordenador (a sessão principal) cruza as lentes e **nunca** é a lente cega. Depois, aplique
`pelizzai-verification-before-completion` antes de consolidar. Para pesquisa, cruze achados
conflitantes e desconfie de relatório não verificado.

Se o subagente sinalizou lacuna de skill de domínio para a stack da tarefa, o coordenador acumula
essas lacunas e as consolida numa única proposta no fechamento (eixo adoption-driven de
`pelizzai-finish-task`) — nunca cria skill no meio da tarefa. Essa via **não** para a execução.

**Lacuna material é a outra via, e essa para a frente.** Se o subagente NOMEOU uma decisão de
requisito, escopo, UX, arquitetura, dados, segurança, custo ou aceite que não estava no briefing,
no plano nem na spec, ela não se resolve no despacho seguinte: o coordenador **não decide** por si
nem pelo subagente. Ele consolida as lacunas abertas — agrupar e ordenar por dependência, nunca
escolher — e as leva ao humano por `pelizzai-interview-me` no modo lacuna (uma pergunta por vez,
2–3 opções com a recomendada) antes de re-despachar. A decisão ratificada volta ao plano e ao
briefing; só então a frente continua.

---

## Anti-padrões

```text
- Esperar que subagentes se coordenem sozinhos (eles não se falam) — isso é trabalho do coordenador.
- Mandar um papel de escrita a um agentType read-only (Explore/Plan não editam).
- Briefing vago, ou assumir que o subagente tem o histórico da conversa.
- Tratar o relatório do subagente como verdade sem conferir (diff do git / evidência fresca).
- Entregar o relatório do subagente à lente spec cega, ou o coordenador se despachar como essa lente.
- Montar o subagente-especialista sem o pacote completo de domain skills da sua área.
- Subagente preencher por default ou "inferência razoável" uma decisão que não está no briefing/plano/spec, em vez de nomear a lacuna e devolver NEEDS_CONTEXT.
- Coordenador resolver a lacuna material sozinho (ou re-despachar por cima dela) em vez de levá-la ao humano pela `pelizzai-interview-me` — consolidar não é decidir.
- Usar subagents para um TIME de papéis que precisam dialogar — isso é `pelizzai-team`.
```

---

## Integração

**Combina com:**

- `pelizzai-team` — o time completo (vários papéis, task list, diálogo); subagents é a delegação a UM agente.
- `pelizzai-reasoning` / `pelizzai-preferences` — camada de raciocínio e piso global instruídos no briefing (skills de domínio prevalecem).
- `pelizzai-execution-plans` — modo `subagents`: um subagente por tarefa, despachado pelo coordenador.
- `pelizzai-interview-me` — destino da lacuna material que o subagente nomear: o coordenador a leva ao humano antes de re-despachar.
- `pelizzai-review` / `pelizzai-verification-before-completion` — conferir o resultado antes de consolidar.
- `pelizzai-audit` — catálogo de skills de domínio coladas no briefing.
