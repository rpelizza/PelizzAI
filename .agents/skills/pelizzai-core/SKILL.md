---
name: pelizzai-core
description: Use essa skill em qualquer conversa - estabeleça como procurar e usar SKILLS, exigindo a invocação de SKILLS antes de QUALQUER resposta, inclusive perguntas de esclarecimento.
---

<SUBAGENT-STOP>
Se você foi designado como subagente para executar uma tarefa específica, ignore essa SKILL.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
Se você achar que existe pelo menos 1% de chance de uma SKILL ser aplicada na tarefa que você está fazendo, você DEVE ABSOLUTAMENTE acionar essa SKILL.

SE UMA SKILL SE APLICA À SUA TAREFA, VOCÊ NÃO TEM ESCOLHA. VOCÊ DEVE USÁ-LA.

Isso não é negociável. Isso não é opcional. Você não pode usar racionalizações para escapar disso.
</EXTREMELY-IMPORTANT>

## Prioridades

O harness `PelizzAI` se sobrepõe ao comportamento padrão do sistema, mas **instruções explícitas do usuário sempre têm prioridade sobre o PelizzAI**.

1. **Instruções explícitas do usuário** (CLAUDE.md, GEMINI.md, AGENTS.md, solicitações diretas) — prioridade máxima
2. **Harness "PelizzAI"** — prevalecem sobre o comportamento padrão do sistema em caso de conflito
3. **Prompt padrão do sistema** — prioridade mínima

## Anúncio de skills (regra global)

Ao acionar qualquer skill do harness, **anuncie** em uma linha o que vai fazer, usando **sempre a grafia exata da marca: "PelizzAI"** (P, A e I maiúsculos — nunca "Pelizzai", "pelizzAI" ou "PELIZZAI" em prosa). Padrão:

> "Usando a skill PelizzAI \<Nome\> para \<objetivo\>."

Os identificadores de skill (`pelizzai-core`, `pelizzai-router`, …), caminhos de arquivo e o diretório `pelizzai/` do projeto alvo permanecem em minúsculas — a regra vale para a marca em texto corrido.

## Camada global de preferências

Use `pelizzai-preferences` como camada global quando a tarefa envolver comunicação, engenharia, código, validação, segurança, documentação, portabilidade ou decisões de execução. Ela não substitui skills específicas; ela define o piso de comportamento. Regras do usuário, `CLAUDE.md`/`AGENTS.md`, skills de domínio e instruções de uma skill especializada continuam tendo prioridade.

Não acione `pelizzai-preferences` para tarefas triviais que possam ser respondidas diretamente sem risco ou contexto de projeto. Para qualquer tarefa não trivial, considere-a junto do roteamento principal.

## Higiene de contexto

A janela de contexto é um recurso da tarefa — administre-a de forma deliberada:

- **Zona segura: ~120k tokens.** Acima disso a qualidade degrada; planeje as fronteiras antes de chegar lá.
- Fases criativas (design → plano) acontecem numa **janela contínua**; a execução usa **contexto fresco por tarefa**.
- **Handoff bifurca; compact continua**: para mudar de rumo, despache com briefing novo (o procedimento mora na `pelizzai-handoff`); para continuar o mesmo trabalho, compacte — e **nunca no meio de uma fase** (feche a fase primeiro).
- Após compaction, confie no `pelizzai/data/state.md` e no `git log`, não na sua memória.

O detalhe operacional (bordas de fase, retomada) mora na `pelizzai-execution-plans`.

## Como acessar as skills

**Quando a sua plataforma tem carregamento nativo de skills, use-o sempre** — não leia os arquivos manualmente, para garantir que a skill seja ativada corretamente:

**No Claude Code**: Use a ferramenta `Skill`. Ao invocar uma skill, o conteúdo dela é carregado e apresentado a você — siga-o diretamente.

**No Codex**: As skills são carregadas nativamente. Siga as instruções apresentadas quando uma skill for ativada.

**No Copilot CLI**: Use a ferramenta `skill`. As habilidades são detectadas automaticamente a partir dos plugins instalados.

**No Gemini CLI**: As habilidades são ativadas por meio da ferramenta `activate_skill`. O Gemini carrega os metadados das skills no início da sessão e ativa o conteúdo completo sob demanda.

**Em plataformas SEM carregamento nativo** (você chegou aqui via `AGENTS.md`, `GEMINI.md` ou uma regra de IDE): leia o arquivo `SKILL.md` da skill diretamente (`.agents/skills/<nome>/SKILL.md`, espelho de `.claude/skills/`) e siga-o — a leitura manual é o mecanismo correto nesses ambientes, nunca uma desculpa para pular a skill. Consulte a documentação da sua plataforma se houver um mecanismo próprio.

## Entender o objetivo do usuário

Antes de decidir como responder ou executar uma tarefa, identifique o objetivo real do usuário.

Não se limite ao pedido literal. Determine qual resultado prático o usuário espera obter.

Analise, nesta ordem:

1. **Resultado desejado**
   Identifique o que o usuário quer receber, modificar, decidir, criar, resolver ou alcançar.

2. **Entregável esperado**
   Determine o formato mais adequado para a resposta, quando aplicável: explicação, plano, código, arquivo, análise, decisão, mensagem, documento, comando, pesquisa, revisão ou execução de uma ação.

3. **Contexto disponível**
   Use todas as informações fornecidas pelo usuário, arquivos, conversa anterior, instruções do projeto e contexto do ambiente antes de fazer perguntas.

4. **Restrições e preferências**
   Identifique requisitos explícitos, como tecnologia, linguagem, formato, prazo, estilo, orçamento, segurança, compatibilidade, fontes permitidas ou proibições.

5. **Critério de sucesso**
   Determine como saber se a tarefa foi concluída corretamente. Priorize o objetivo do usuário, não apenas a execução superficial do pedido.

6. **Ambiguidades relevantes**
   Diferencie ambiguidades que impedem materialmente a execução daquelas que podem ser resolvidas com uma suposição razoável.
    - Faça uma pergunta apenas quando a resposta for necessária para evitar erro relevante, risco, desperdício significativo ou resultado incompatível com o objetivo do usuário.
    - Não peça esclarecimentos sobre detalhes que possam ser inferidos com segurança a partir do contexto.
    - Quando adotar uma suposição relevante, declare-a de forma breve e prossiga.
    - Quando houver múltiplas interpretações plausíveis, escolha a mais consistente com o contexto e com o resultado prático esperado.

7. **Escopo da tarefa**
   Identifique o que deve ser feito agora e o que está fora do pedido atual. Não amplie o escopo sem necessidade.

8. **Ação mais útil**
   Após compreender o objetivo, escolha a próxima ação que mais aproxima o usuário do resultado desejado. Isso pode incluir usar uma skill aplicável, pesquisar, analisar arquivos, escrever, executar código ou responder diretamente, conforme as regras deste harness.

### Regra de ouro

Não trate pedidos curtos como pedidos simples.
Antes de responder, avalie a intenção, o contexto, as restrições e o resultado esperado.

Ao mesmo tempo, não transforme toda solicitação em uma entrevista.
Quando houver contexto suficiente para agir com segurança, prossiga.

# Usando as skills

## Regras

**Acione uma skill sempre que houver pelo menos 1% de chance de ela ser útil para a tarefa ANTES de tentar resolver manualmente e ANTES de qualquer resposta ou outra ação.** Se uma skill não for adequada para uma situação, você pode ignorá-la, mas deve justificar a decisão. Para a maioria dos casos, você poderá usar a skill `pelizzai-router` após entender o objetivo do usuário e o contexto da tarefa.

# Mapa de fluxos do harness

A entrada é sempre esta skill (`pelizzai-core`); depois de entender o objetivo, o `pelizzai-router` orquestra. Na primeira interação (ou ao digitar **"bootstrap"**), a `pelizzai-audit` mapeia o projeto e cria as skills de domínio antes de qualquer tarefa. Pergunta **puramente conceitual** não dispara o bootstrap — a `pelizzai-audit` só entra quando a resposta exigir tocar ou entender o projeto.

```mermaid
flowchart TD
    U([Mensagem do usuario]) --> P[pelizzai-core: exigir skill antes de responder]
    P --> G[Entender o objetivo do usuario]
    G --> RT[pelizzai-router]
    RT --> BOOT{Harness inicializado?\npelizzai/domain-skills.md existe?}
    BOOT -- "Nao / 1a interacao / 'bootstrap'" --> AUD[pelizzai-audit: mapeia projeto/workspace,\nMCPs, git/host, cria skills de dominio + docs]
    AUD --> CLS
    BOOT -- Sim --> CLS{Classificar a intencao}
    CLS --> TRACKS[Tracks: feature / bug / ajuste / refactor / infra / review / conflito / conceitual]
```

Fluxos por track (o detalhe e os encadeamentos estão na `pelizzai-router`):

```mermaid
flowchart TD
    CLS{Intencao} -- feature/refactor/infra --> BR[brainstorming] --> IV1[interview-me\nestressa design] --> WP[writing-plans] --> IV2[interview-me\nestressa plano] --> GATE[GATE DE SETUP POS-PLANO\nconduzido pela execution-plans:\n1. worktree ou branch?\n2. nome tipo/slug + criacao via starting-branch\n3. modo: team / subagents / inline\n4. commit: granular / squash-final]
    GATE --> EXP[execution-plans\nloop OODA por tarefa]
    EXP --> CY[tdd por tarefa -> review 2 estagios -> consolidar] --> MORE{mais tarefas?}
    MORE -- sim --> CY
    MORE -- nao --> VAL[validacao final da entrega\nreview final + suite completa + checklist do plano] --> VC[verification-before-completion] --> FIN[finish-task\nhonra a commit-strategy; destino: push/PR/local/descartar]

    CLS -- bug --> DBG[debugging: 4 fases OODA, causa raiz] --> SB2[starting-branch] --> TDD2[tdd: teste que falha + fix] --> VC2[verification] --> RV2[review] --> FIN
    CLS -- ajuste --> QF[quick-fix] --> SB3[starting-branch: branch com alerta] --> TDD3[verificacao minima\nteste so se houver comportamento] --> VC3[verification] --> FIN
    CLS -- review --> RVR[review: 2 estagios por tarefa de plano;\navulso = estagio de qualidade c/ evidencia] -.oferta.-> OW[oswap: OWASP]
    CLS -- conflito --> MC[resolving-merge-conflicts]
    CLS -- conceitual --> ANS[responder direto]
```

O `pelizzai-loop` dá a lente do laço: o ciclo **OODA** (Observar → Orientar → Decidir → Agir) repetido até a Definition of Done; em dúvida material, pare e use `pelizzai-interview-me`. A `pelizzai-preferences` é a camada global ao longo de tudo. Para bibliotecas, frameworks e APIs externas, fundamente no MCP `context7` — não na memória.

# Catálogo de skills

| Grupo                      | Skills                                                                                  |
| -------------------------- | --------------------------------------------------------------------------------------- |
| Entrada e orquestração     | `pelizzai-core` (esta) · `pelizzai-router` · `pelizzai-audit` (bootstrap) · `pelizzai-preferences` (camada global) |
| Raciocínio e comunicação   | `pelizzai-reasoning` (técnicas + OODA) · `pelizzai-interview-me` · `pelizzai-writing-clearly-and-concisely` |
| Ciclo de feature           | `pelizzai-brainstorming` → `pelizzai-writing-plans` → `pelizzai-execution-plans`         |
| Execução por tarefa        | `pelizzai-tdd` · `pelizzai-team` · `pelizzai-subagents` · `pelizzai-loop` (OODA + DoD) · `pelizzai-handoff` (bifurcar para sessão nova) |
| Tracks dedicados           | `pelizzai-debugging` (bug) · `pelizzai-quick-fix` (ajuste)                               |
| Design e exploração        | `pelizzai-codebase-design` · `pelizzai-domain-modeling` · `pelizzai-prototype` · `pelizzai-improving-architecture` |
| Isolamento e fechamento    | `pelizzai-starting-branch` (branch/worktree) · `pelizzai-finish-task` · `pelizzai-resolving-merge-conflicts` · `pelizzai-recovery` (estado divergente) · `pelizzai-documenting-features` (doc humana da feature) |
| Qualidade e segurança      | `pelizzai-review` · `pelizzai-oswap` · `pelizzai-verification-before-completion`         |
| Frontend                   | `pelizzai-frontend`                                                                      |
| Autoria de skills          | `pelizzai-writing-skills`                                                                |
