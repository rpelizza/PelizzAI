---
name: pelizzai-router
description: Orquestrador de qualquer pedido que precise inspecionar ou alterar um projeto. Classifica efeito, intenção, risco, incerteza e superfícies; escolhe uma head skill e overlays proporcionais; garante isolamento antes da primeira escrita. Use após `pelizzai-core`, inclusive para análises read-only de repositório. Não use em conversa puramente conceitual sem contexto de projeto.
---

# PelizzAI Router

<SUBAGENT-STOP>
Se você recebeu uma subtarefa fechada, não roteie novamente. Siga o briefing e escale se faltar contexto.
</SUBAGENT-STOP>

## Objetivo

Produzir a menor rota que resolve a tarefa com segurança. O router decide o **ciclo de vida**; `pelizzai-reasoning` decide as **heurísticas** dentro de cada fase.

**Anuncie:** "Usando a skill PelizzAI Router para classificar efeito, risco e fluxo da tarefa."

## Envelope de decisão

Antes de acionar outra skill, derive:

```text
effect:      read-only | write-local | external
intent:      bootstrap | feature | bug | ajuste | refactor | infra | review | conflito
risk:        low | medium | high
uncertainty: low | medium | high
surfaces:    ui | security | data | public-contract | docs | none
```

### Effect

| Effect | Critério | Regra |
| --- | --- | --- |
| `read-only` | explicar, analisar, mapear, revisar ou diagnosticar sem alterar estado | Pode inspecionar; nunca cria/edita state, catálogo, profile, branch ou arquivos. |
| `write-local` | alterar código, arquivo, configuração ou artefato versionável | Isolamento antes da primeira escrita persistente. |
| `external` | push/PR/deploy/mensagem/custo/permissão/produção/exclusão | Valide autoridade, alvo, reversibilidade e confirmação no gate da ação. Isolamento Git só precede a ação quando ela também escreve no repositório. |

Uma tarefa pode começar read-only (investigação) e mudar para write-local quando o usuário pedir o fix. Reclassifique **antes** da primeira mutação.

### Risk

```text
low    — local, reversível, sem contrato/dados/segurança.
medium — comportamento persistente, integração limitada ou contrato público aditivo/reversível
         com aceite claro.
high   — dados, auth, segurança, produção, contrato público breaking ou de grande blast radius,
         irreversibilidade ou múltiplos sistemas.
```

### Uncertainty

```text
low    — objetivo, aceite e abordagem estão claros/evidenciados.
medium — há escolhas reais, mas o espaço é limitado.
high   — requisitos/causa/arquitetura ainda precisam ser descobertos.
```

Não transforme essas classificações em formulário para o usuário. Derive-as do pedido e da evidência em silêncio; pergunte apenas se uma decisão material pertence a ele. Mas apresente a ROTA montada (lane, head skill, overlays) como recomendação única no **Gate de kickoff** antes de investir — isso não é um formulário, é um bloco só.

## Análise da proposta (sempre que houver efeito mutável não-trivial)

Depois de derivar o envelope e ANTES de escolher a head skill, faça uma passada de stress compacta do pedido — acione a técnica `assumption-tracking` da `pelizzai-reasoning` (premortem de escopo). Apresente em ≤6 bullets:

- premissas materiais que o harness assumiria para prosseguir;
- lacunas que mudam escopo/UX/arquitetura/segurança/dados;
- riscos concretos;
- alternativas materialmente diferentes, quando existirem.

A Análise da proposta é resultado apresentado, não pergunta; ela alimenta a linha de **Descoberta** do Gate de kickoff quando há lacuna material — nunca bloqueia sozinha.

Proporcionalidade (não vira formulário nem cerimônia): só dispara em tarefa **mutável não-trivial** com incerteza material. Em `read-only` puro e em ajuste/bug trivial com tudo claro, a análise **colapsa a zero** — sem linha, sem preâmbulo (risco alto com escopo claro eleva prova/gates/overlays, não a incerteza; não force a análise por risco isolado). Em `bounded`/ajuste com uma ou outra premissa aberta, colapsa numa linha: "Sem lacunas materiais; premissas assumidas: <lista curta>".

Sob briefing fechado (SUBAGENT-STOP), não produza a Análise da proposta nem abra a Descoberta: aplique o briefing e escale ao coordenador o que exigir decisão.

## Source mode e bootstrap

Detecte o repo-fonte do próprio PelizzAI EXCLUSIVAMENTE pela sentinela:

```text
scripts/pelizzai-source-repo.txt
```

Manifesto (`scripts/pelizzai-core-skills.txt`) e `scripts/sync-harness.ps1` existem também nos
consumidores instalados via `-ExportConsumer` — a presença deles NÃO indica source mode.

Em **source mode**, não exija `pelizzai/domain-skills.md` nem crie runtime consumidor. Trabalhe
pelas regras do repo-fonte. Para tarefas mutáveis, ainda use task branch e prova, mas mantenha
plano/progresso no mecanismo nativo da plataforma e o seal como SHA do execution record; não crie
`pelizzai/data/state.md`, specs/plans consumidoras nem closure commit de state.

O **execution record nativo** é o estado lógico da tarefa no mecanismo de plano/task da plataforma,
nunca um arquivo substituto no repo. Mantenha nele, quando aplicável: `phase`, branch/base,
isolamento, decisões de execução, progresso, overlays, `validated-head`, `delivery-head` e status do
destino (`local | pushed | pr-open | partial`). Termine em `phase: done` ou `phase: blocked`.

Em projeto consumidor:

| Situação | Rota |
| --- | --- |
| `effect: read-only`, catálogo ausente | `pelizzai-audit` em `scan-only`; nenhum arquivo é criado. |
| Usuário disse `bootstrap`/`reinicializar` | `pelizzai-audit` em `bootstrap-write`. |
| Tarefa mutável, catálogo ausente | Faça scan-only, apresente o conjunto mínimo de artefatos proposto e obtenha consentimento para `bootstrap-write`. |
| Catálogo existe, ledger ausente | Em tarefa mutável autorizada, repare somente o ledger; read-only apenas reporta. |

"Primeira interação" não é gatilho suficiente para reexecutar bootstrap. O sinal é o estado real do projeto ou um pedido explícito.

## Estado e retomada

Leia `pelizzai/data/state.md` quando existir, sem escrevê-lo em tarefas read-only.

```text
slug: <none> ou phase: done
→ não há tarefa ativa.

phase: blocked
→ apresente o bloqueio antes de iniciar outra mutação.

tarefa ativa que corresponde ao pedido
→ valide state contra Git e retome sem repetir decisões confirmadas.

tarefa ativa diferente do pedido novo
→ não sobrescreva; informe o conflito e decida com o usuário entre concluir/pausar ou abrir
  outra frente isolada.
```

Validação:

- branch: compare a branch registrada com `git branch --show-current`;
- worktree: valide caminho + branch por `git worktree list` ou execute dentro do worktree;
- base: confirme `base-ref`/`base-sha` quando registrados;
- plano: o caminho registrado precisa existir no ambiente de execução.

Em divergência que arrisque trabalho, use `pelizzai-recovery`; nunca reconcilie destrutivamente por palpite.

## Gate de primeira escrita

Para `write-local`/`external`, invoque `pelizzai-starting-branch` **antes** de criar ou alterar:

- `pelizzai/data/state.md`;
- specs, planos ou ADRs;
- código, config, testes, scaffolds ou protótipos;
- catálogo/profile/skills de domínio do bootstrap.

Nos tracks com design/plano, abra uma **task/planning branch** normal primeiro. O gate pós-plano pode:

- continuar nessa branch; ou
- após um checkpoint dos artefatos de planejamento, liberar a branch no working tree principal e montar um worktree a partir da **mesma branch existente**.

Nunca crie worktree da base limpa depois de escrever spec/plano em outro working tree.

## Classificar intenção e escolher lane

| Pedido | Track/head |
| --- | --- |
| Bootstrap/remap autorizado | `pelizzai-audit` (`bootstrap-write`) |
| Algo quebrado/erro/falha/comportamento inesperado | `bug` → `pelizzai-debugging` |
| Mudança local sem nova regra/contrato/superfície | `ajuste` → `pelizzai-quick-fix` |
| Refactor local preservando comportamento | `ajuste` → `pelizzai-quick-fix` |
| Review de diff, working tree, branch ou PR | `review` → `pelizzai-review` |
| Revisão codebase-wide de arquitetura, dívida ou seams | `review` → `pelizzai-improving-architecture` |
| Conflito Git em andamento | `pelizzai-resolving-merge-conflicts` |
| Feature/refactor/infra com design já aprovado e plano pronto | `pelizzai-execution-plans` |
| Design/spec/Figma aprovado, aceite claro, mas sem plano | `pelizzai-writing-plans`; brainstorming/interview-me **propostos** quando a Análise da proposta sinaliza lacuna material |
| Estressar design/plano existente, resolver lacuna material sinalizada, ou pedido de entrevista | proposto pela Análise da proposta ou pelo usuário → `pelizzai-interview-me` |
| Feature/refactor/infra com requisitos claros, mas sem plano | use lane abaixo |

### Lanes de feature/refactor/infra

| Lane | Predicado | Rota |
| --- | --- | --- |
| `bounded` | baixa incerteza/risco; um comportamento coeso; aceite claro; sem decisão arquitetural | `pelizzai-writing-plans` em modo compacto; não force brainstorming. |
| `standard` | risco médio e/ou algumas partes/contratos, com solução e aceite claros | `pelizzai-writing-plans`; prependa brainstorming compacto somente se restar trade-off real. |
| `exploratory` | alta incerteza ou risco alto que exige descoberta/mitigação de design; arquitetura ou decisões sensíveis acopladas | `pelizzai-brainstorming` completo + stress proporcional → plano. |

Um endpoint pequeno, aditivo e com contrato claro pode ser `standard` com review/overlays mais
fortes; risco eleva prova e gates, não cria incerteza artificial. Uma mudança grande e mecânica
pode ter baixa incerteza. Linhas/arquivos são sinais, não o critério principal.

## Overlays obrigatórios

Derive overlays por superfície e propague-os para plano, task brief, review e Verification; registre
no state consumidor ou execution record nativo.

| Sinal | Overlay/conduta |
| --- | --- |
| tela, componente, CSS, layout, UX, acessibilidade | `pelizzai-frontend` desde design/implementação até QA visual. |
| auth, input externo, SQL, upload, segredo, CORS, SSRF, dependência | `pelizzai-oswap` antes da validação final. |
| padrões específicos do projeto | consumidor: skills de `pelizzai/domain-skills.md`; source mode: regras/skills do repo-fonte. |
| documentação humana parte do escopo | `pelizzai-documenting-features` antes da validação final. |

`Playwright`, browser e screenshot são ferramentas do overlay frontend, não substitutos dele.

## Defaults proporcionais de execução

Compute os defaults de setup como **recomendação**, não como decisão aplicada em silêncio. Leia primeiro `pelizzai/profile.md` (seção `## Defaults de execução ratificados`, quando existir): valor preenchido é a recomendação a exibir; `<unset>` recai no default proporcional abaixo.

```text
bounded/ajuste/bug comum:
  isolation: branch
  execution-mode: inline
  commit-strategy: granular

plano com frentes realmente independentes:
  isolation: worktree(s) recomendado; execution-mode: subagents/team quando há independência real.

squash-final:
  só quando o histórico intermediário não tem valor; consolida ANTES da validação final.
```

O router não pergunta nem aplica esses defaults por conta própria — recomenda e encaminha:

- **Tracks com plano** (bounded/standard/exploratory): defira isolamento, modo e commit ao **Gate de setup pós-plano** consolidado da `pelizzai-execution-plans` — é lá que as três opções de modo (inline · subagents · **team**) ficam sempre visíveis e a estratégia de commit é sempre mostrada.
- **Write-local sem plano** (ajuste/bug): **recomende em silêncio** à head skill; a própria head skill (`pelizzai-quick-fix`/`pelizzai-debugging`) emite um confirm compacto de uma linha antes da primeira escrita. O router **não** emite esse confirm — um único emissor, sem dupla pergunta.

`worktree` e `squash-final` nunca são aplicados sem escolha do usuário. Use subagents/time para independência real, diversidade de hipóteses ou ganho mensurável; não os trate como hierarquicamente melhores que inline.

## Sync & delta

Para tarefa mutável em Git, observe a realidade antes de decidir:

```text
git status --short --branch
git fetch origin                 # somente se houver remoto e a rede estiver disponível
git log --oneline <base>..HEAD
git log --oneline HEAD..origin/<base>  # quando o ref existir
```

Releia apenas o delta relevante. Não faça fetch em análise read-only sem necessidade, nem esconda falha de rede.

## Registro de execução

Somente tarefas mutáveis atualizam o registro: template de state no consumidor; execution record
nativo em source mode, sem criar arquivo. Campos lógicos:

```text
slug, track, lane, phase, effect, risk, overlays,
base-ref, base-sha, branch, isolation, worktree-path,
execution-mode, commit-strategy, audience, kickoff, plan, project,
validated-head (somente após validação final).
```

Ao ratificar o Gate de kickoff, registre a `lane`/`audience`/overlays da rota, mas deixe `kickoff: pendente`: o marcador `kickoff: ratificado <AAAA-MM-DD>` pertence a quem é dono da ratificação de **escrita** — o Gate de setup pós-plano da `pelizzai-execution-plans` (tracks com plano) ou o confirm de uma linha da head skill (`pelizzai-quick-fix`/`pelizzai-debugging` em ajuste/bug) — e é gravado por ele antes da primeira escrita de produto. Nunca carimbe `ratificado` no kickoff de UMA LINHA que informa e segue sem parar; em todo track mutável um confirm/gate downstream é o dono. A retomada honra a rota ratificada sem re-perguntar; uma tarefa nova nunca herda `lane`/`kickoff`/`audience` — o Gate de kickoff dispara de novo. Setup ratificado como política **de projeto** vive em `pelizzai/profile.md`, não é carryover de state.

Uma tarefa nova nunca herda decisões da anterior. O fechamento pertence a `pelizzai-finish-task`.

## Red flags

```text
- Bootstrap mutável para responder pedido read-only.
- Escrever state/spec/plano antes do isolamento.
- Forçar brainstorming completo numa feature bounded.
- Usar linha/arquivo como único medidor de complexidade.
- Tratar frontend/security como oferta tardia.
- Aplicar isolamento, modo de execução ou estratégia de commit sem ratificação do usuário.
- Pulverizar a rota ou o setup em várias micro-perguntas em vez de um bloco agrupado.
- Assumir em silêncio decisão que muda escopo/UX/arquitetura sem apresentá-la na Análise da proposta nem no Gate de kickoff.
- Paralelizar escrita numa working tree compartilhada como se worktree isolasse agentes.
- Herdar `lane`/base/branch/strategy de state de uma tarefa ANTERIOR como carryover acidental — a política de projeto explicitamente ratificada no `profile.md` é a única exceção.
- Acionar várias head skills ao mesmo tempo.
```

## Gate de kickoff (rota como recomendação)

Depois de montar envelope → Análise da proposta → lane → head skill → overlays, apresente a **rota proposta** como uma **recomendação a ratificar** antes de investir — nunca um formulário, um bloco só com o default já pré-selecionado. A classificação continua sua; segui-la ou ajustá-la é do usuário. O router é o **único** emissor do kickoff; o core apenas sinaliza intenção/audiência/ambiguidade e entrega.

**Quando é UMA LINHA que informa e segue (sem parar):** `read-only` de review/análise/explicação (rota anunciada, sem parada); ou lane `bounded`/ajuste/bug com `risk: low` E `uncertainty: low`. Mesmo aí, NOMEIE a base da classificação para permitir veto — ex.: "Classifiquei como ajuste local, risco baixo, incerteza baixa → sigo com `pelizzai-quick-fix`." O setup (branch/base/commit) é confirmado pela head skill antes da primeira escrita, não aqui.

**Quando é um BLOCO que para e aguarda ratificação** (uma pergunta agrupada, nunca N micro-perguntas): lane `standard` ou `exploratory`; ou `risk: high`; ou `uncertainty: medium|high`; ou `effect: external`; ou a rota suprimiria uma descoberta/entrevista que um lane-up restauraria; ou há ≥2 leituras materialmente diferentes. Formato:

```text
**Gate de kickoff — rota proposta (responda "ok" ou ajuste qualquer item):**
- Entendi que você quer <X>; vou tratar como <feature|ajuste|bug|refactor> — confere?   (só quando audience=leigo ou há ≥2 leituras materiais)
- Lane: <bounded|standard|exploratory|high-risk> — <justificativa em 1 linha>
- Head + overlays: <head skill> + <overlays ou "nenhum">
- Descoberta: <"sem lacunas materiais" | lista numerada de lacunas → recomendo <pelizzai-brainstorming compacto|completo|pelizzai-interview-me focal>>
- Artefatos: <spec/plano/ADR previstos nesta lane | "nenhum além do plano nativo">
```

"ok" aceita a rota inteira; o usuário sobe a descoberta, troca a lane ou inclui/remove overlay em uma palavra. O default pré-selecionado é **recomendado/destacado, nunca auto-confirmado**: sem resposta afirmativa, segure o turno — não atravesse a borda análise→plano assumindo o default.

**Audiência:** quando o usuário parece não-técnico ou a intenção admite ≥2 leituras materiais, a primeira linha do bloco reapresenta o entendimento (handshake) antes de rotear; registre `audience: technical | layperson` (ver Registro de execução). Não despeje jargão; siga `pelizzai-writing-clearly-and-concisely`.

**Descoberta:** quando a Análise da proposta sinalizou ≥1 lacuna material (escopo/UX/arquitetura/segurança/dados), **proponha** `pelizzai-brainstorming` (compacto ou completo) ou `pelizzai-interview-me` focal com o default recomendado; aceitar faz a descoberta, ajustar deixa o usuário prosseguir com as premissas declaradas ou responder as perguntas na hora. A decisão de pular a descoberta é do usuário — o router nunca a pula em silêncio numa tarefa que classificou `risk: high` ou `uncertainty ≥ medium`.

**Setup fica fora deste bloco:** isolamento, modo (com `team` sempre visível) e commit são ratificados no Gate de setup pós-plano da `pelizzai-execution-plans` (tracks com plano) ou no confirm de uma linha da head skill (ajuste/bug). O router recomenda em silêncio e não repete a pergunta.

Sob briefing fechado (SUBAGENT-STOP), não produza análises de rota nem abra o Gate de kickoff: aplique o briefing e escale ao coordenador o que exigir decisão.

## Instrução final

Classifique efeito, intenção, risco, incerteza e superfícies. Apresente a Análise da proposta quando houver efeito mutável não-trivial e a rota no **Gate de kickoff**; só invoque a head skill com o kickoff resolvido (anunciado na linha única ou ratificado no bloco). Garanta primeira escrita segura, escolha uma head skill, propague overlays e deixe reasoning/test/review variarem proporcionalmente.
