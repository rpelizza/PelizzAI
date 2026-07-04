---
name: pelizzai-writing-plans
description: Use quando houver uma spec, um design aprovado (`pelizzai-brainstorming`), um PRD ou requisitos para uma tarefa multi-etapa — ANTES de tocar no código. É a skill que transforma o design aprovado num plano de implementação executável, salvo em `pelizzai/plans/`. Acione após o brainstorming, ou quando o usuário disser "criar o plano", "plano de implementação", "quebrar em tarefas".
---

# PelizzAI Writing Plans

## Objetivo

Escrever um plano de implementação **completo**, assumindo que quem vai executar tem **zero contexto** da base de código. Documente tudo o que essa pessoa precisa: quais arquivos tocar em cada tarefa, o código, como testar, os comandos exatos. Entregue o trabalho como **tarefas bite-sized**, em **fatias verticais**, seguindo TDD e com commits frequentes. DRY. YAGNI.

Assuma um desenvolvedor competente que conhece quase nada do seu toolset, do domínio do problema e de bom design de testes.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Writing Plans para criar o plano de implementação."

**Salve o plano em:** `pelizzai/plans/AAAA-MM-DD-<feature>.md` (padrão de diretório `pelizzai/`; preferências do usuário quanto ao local prevalecem).

---

## Princípio central

> Um bom plano transforma um problema em uma sequência de fatias verticais, cada uma testável e commitável por si só. Cada passo contém o conteúdo real (código, comando, saída esperada) — nunca um placeholder. Quem executa não deveria precisar fazer uma única pergunta.

---

## Verificação de escopo

Se a spec cobre múltiplos subsistemas independentes, ela deveria ter sido quebrada em sub-projetos no `pelizzai-brainstorming`. Se não foi, sugira separar em **planos distintos** — um por subsistema. Cada plano deve produzir software funcional e testável por si só.

**Teste fog-vs-tarefa** (o que entra no plano AGORA vs fica como pendência): "eu consigo formular a **pergunta** com precisão agora?" — não "consigo respondê-la agora". Pergunta precisa e sem resposta vira uma tarefa de investigação/protótipo no plano; névoa que nem pergunta tem ainda **não** é fatiada em tarefas — registre como pendência da spec e planeje até a fronteira do que se enxerga.

## Estrutura de arquivos

Antes de definir as tarefas, mapeie quais arquivos serão criados ou modificados e a responsabilidade de cada um — é aqui que as decisões de decomposição se fixam. Use `pelizzai-reasoning` (*Structured Decomposition*).

```text
- Projete unidades com fronteiras claras e interfaces bem definidas; um arquivo, uma responsabilidade.
- Prefira arquivos menores e focados a arquivos grandes que fazem demais.
- Arquivos que mudam juntos vivem juntos. Divida por responsabilidade, não por camada técnica.
- Em base existente, siga os padrões estabelecidos; não reestruture unilateralmente.
```

## Granularidade bite-sized (cada passo = uma ação de 2-5 min)

```text
- "Escreva o teste que falha"            → passo
- "Rode o teste e veja-o falhar"         → passo
- "Implemente o mínimo para passar"      → passo
- "Rode o teste e veja-o passar"         → passo
- "Commit"                               → passo
```

## Fatias verticais (não horizontais)

Cada tarefa é uma **fatia vertical**: um comportamento de ponta a ponta, testável e commitável de forma independente — não "todos os testes" seguidos de "toda a implementação". Esse é o ciclo do `pelizzai-tdd` (um teste → uma implementação → repetir). Tarefas independentes podem ser assumidas por executores diferentes — em paralelo real quando o usuário escolher `worktree` no gate de setup (caminhos disjuntos), ou integradas **em série** pelo coordenador quando escolher `branch` (ver `pelizzai-execution-plans`). Um plano com frentes independentes bem separadas é o que torna a recomendação de worktree + team honesta no gate.

## Right-sizing das tarefas (pelo custo do gate)

A tarefa é a **menor unidade que vale o gate de um reviewer fresco**: divida apenas onde um reviewer poderia **rejeitar uma tarefa aprovando a vizinha** — se duas "tarefas" só podem ser aprovadas ou rejeitadas juntas, são uma. Corolário: um **plano de 1 tarefa é legítimo** para uma feature pequena e óbvia — o fluxo inteiro (spec → plano → gate → execução → review), na escala mínima.

## Durabilidade: plano imediato × artefato que sobrevive à sessão

O plano deste fluxo é executado **imediatamente** (contexto fresco) — por isso os caminhos exatos de arquivo são obrigatórios. A regra INVERTE para artefatos que **sobrevivem à sessão** (issues, handoffs via `pelizzai-handoff`, briefs para trabalho assíncrono): neles, **durabilidade vence precisão** — descreva **contratos comportamentais** (o que o sistema faz, interfaces e tipos por nome), **critérios de aceite independentes e verificáveis** e o **fora-de-escopo explícito** (previne gold-plating); NÃO cite paths de arquivo nem números de linha, que apodrecem antes de serem lidos — quem executa depois explora o codebase fresco.

## Skills de domínio

Se o projeto tem skills de domínio (catálogo `pelizzai/domain-skills.md`), o plano **deve** seguir suas convenções e **nomeá-las nas tarefas relevantes**, para que o executor (e qualquer subagente/teammate) as aplique em vez de padrões genéricos. Se `pelizzai/domain-skills.md` **não existir**, o harness não foi inicializado — rode `pelizzai-audit` (bootstrap) antes de escrever o plano. Para bibliotecas/frameworks externos, ancore as tarefas na **API real e atual** — use o MCP `context7` (ou a web) quando não tiver certeza de assinaturas ou opções; não confie na memória.

## Documento do plano

Use o template em **[templates/plan.md](templates/plan.md)**. Todo plano começa com um cabeçalho (Objetivo / Arquitetura / Stack técnica / **Global Constraints** — requisitos projeto-wide copiados **verbatim** da spec, que toda tarefa herda e o coordenador cola no briefing de cada membro — + a sub-skill obrigatória de execução) e cada tarefa traz **Files** (criar/modificar/testar com caminhos exatos), o bloco **Interfaces** (Consome/Produz com assinaturas exatas) e os passos de TDD com **código completo**, **comandos exatos** e **`→ verifique:` em todo passo**.

## Sem placeholders

Todo passo precisa do conteúdo real. Estes são **defeitos de plano** — nunca os escreva:

```text
- "TBD", "TODO", "implementar depois", "preencher detalhes".
- "Adicionar tratamento de erro adequado" / "adicionar validação" / "tratar edge cases".
- "Escrever testes para o acima" (sem o código do teste).
- "Igual à Tarefa N" (repita o código — as tarefas podem ser lidas fora de ordem).
- Passos que dizem o quê sem mostrar o como (passo de código exige bloco de código).
- Referências a tipos/funções/métodos não definidos em nenhuma tarefa.
```

## Autoavaliação (você mesmo, sem subagente)

Após escrever o plano completo, releia a spec com um olhar renovado e confira:

```text
1. Cobertura da spec: para cada requisito, aponte a tarefa que o implementa. Liste lacunas.
2. Varredura de placeholders: procure os padrões da seção acima e corrija.
3. Consistência de tipos: assinaturas e nomes usados em tarefas tardias batem com os definidos antes?
   (clearLayers() na Tarefa 3 e clearFullLayers() na Tarefa 7 é um bug.)
```

Corrija inline. Se faltar tarefa para um requisito, adicione-a.

## Revisão independente do plano (recomendada)

Antes do estresse com `pelizzai-interview-me`, considere uma revisão **independente** do plano por um subagente (`pelizzai-subagents` / `pelizzai-team`) — a autoavaliação do próprio autor tem ponto cego conhecido. O reviewer confere: **completude** (todo requisito da spec virou tarefa?), **alinhamento** com a spec, **qualidade da decomposição** (fatias verticais coesas) e **executabilidade** (passos sem placeholders, código completo). Aplique os achados antes de seguir.

## Estresse obrigatório com `pelizzai-interview-me`

Após salvar o plano, **estresse-o com `pelizzai-interview-me` (OBRIGATÓRIO — não é oferta)** antes de qualquer execução: uma entrevista que **exponha as lacunas e riscos do plano**. Anuncie: "Vou estressar este plano e expor as lacunas antes de executar." Se a entrevista desfizer o plano, volte ao `pelizzai-brainstorming`.

## Handoff para a execução

Plano salvo e estressado → entregue à **`pelizzai-execution-plans`**, que conduz o **GATE DE SETUP PÓS-PLANO** com o usuário (os menus canônicos moram lá), nesta ordem: (1) isolamento — **worktree ou branch normal?**; (2) nome da branch/worktree sugerido e confirmado via `pelizzai-starting-branch` (`feat/`, `fix/`, `refactor/`, …); (3) modo de execução — **team / subagents / inline** (as três opções sempre visíveis); (4) estratégia de commit — **granular ou commit único final**. Tudo registrado em `pelizzai/data/state.md`. **Não decida nada disso aqui** — o plano apenas informa a recomendação (frentes paralelas → worktree + team).

Informe à `pelizzai-execution-plans` o **caminho exato do plano salvo** — ela o registra no campo `plan:` de `pelizzai/data/state.md` (a fonte das tarefas, relida após compaction) antes da Tarefa 1. A `pelizzai-writing-plans` não escreve o `state.md`.

Confirme: "Plano salvo em `pelizzai/plans/<arquivo>.md` e estressado. Vou conduzir o gate de setup (worktree/branch, nome, modo de execução, commits) e executá-lo com a `pelizzai-execution-plans`."

---

## Anti-padrões

```text
- Escrever o plano com placeholders ou passos sem código.
- Fatias horizontais (todos os testes, depois toda a implementação) em vez de verticais.
- Ignorar as skills de domínio do projeto, ou não nomeá-las nas tarefas.
- Ancorar tarefas em API de memória em vez da doc real (context7).
- Decidir o modo de execução, o isolamento ou a estratégia de commit aqui (é do gate de setup
  pós-plano, na pelizzai-execution-plans).
- Pular o estresse obrigatório com pelizzai-interview-me.
- Plano gigante para múltiplos subsistemas em vez de um plano por subsistema.
```

---

## Integração

**Combina com:**

- `pelizzai-brainstorming` — de onde o design aprovado normalmente chega.
- `pelizzai-reasoning` — *Structured Decomposition* (estrutura de arquivos) e *Plan and Execute* (ordem das tarefas).
- `pelizzai-tdd` — cada tarefa é uma fatia vertical com passos de TDD.
- `pelizzai-interview-me` — estresse obrigatório do plano antes de executar.
- `pelizzai-execution-plans` — executa o plano (escolhe o modo team/subagents/inline).
- `pelizzai-audit` — padrão de diretório `pelizzai/` e catálogo de skills de domínio.

---

## Instrução final para o agente

```text
Escreva o plano que um bom engenheiro sem contexto executaria sem fazer uma única pergunta.

Prefira:
- fatias verticais a fatias horizontais;
- código completo a placeholders;
- API real (context7) a memória;
- seguir e nomear as skills de domínio a padrões genéricos.

Salve em pelizzai/plans/. Estresse com pelizzai-interview-me (obrigatório).
Entregue à pelizzai-execution-plans; não decida o modo de execução aqui.
```
