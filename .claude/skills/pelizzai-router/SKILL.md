---
name: pelizzai-router
description: Orquestrador de qualquer pedido que precise inspecionar ou alterar um projeto. Classifica efeito, intenção, risco, incerteza e superfícies; recomenda uma head skill e overlays; garante ratificação e isolamento antes da escrita. Na primeira interação com um projeto consumidor, com o harness não inicializado (sem `pelizzai/domain-skills.md`) ou quando o usuário disser "bootstrap", propõe o bootstrap por `pelizzai-audit` antes de rotear. Todo produto/projeto greenfield entra em discovery, spec e plano aprovados mesmo com stack definida. Use após `pelizzai-core`; não use em conversa puramente conceitual sem projeto.
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
low    — objetivo, aceite e abordagem foram explicitados ou ratificados pelo usuário.
medium — há escolhas reais, mas o espaço é limitado.
high   — requisitos/causa/arquitetura ainda precisam ser descobertos.
```

Não transforme essas classificações em formulário. Derive-as do pedido e da evidência, mas não
confunda inferência do harness com decisão humana. Apresente a ROTA montada (lane, head skill,
overlays e artefatos) como recomendação no **Gate de kickoff** e aguarde ratificação em toda tarefa
mutável. Classificar é trabalho do harness; aceitar ou ajustar a rota é decisão do usuário.

## Análise da proposta (sempre que houver efeito mutável não-trivial)

Depois de derivar o envelope e ANTES de escolher a head skill, faça uma passada de stress compacta do pedido — acione a técnica `assumption-tracking` da `pelizzai-reasoning` (premortem de escopo). Apresente em ≤6 bullets:

- premissas materiais que precisariam ser ratificadas para prosseguir;
- lacunas que mudam escopo/UX/arquitetura/segurança/dados;
- riscos concretos;
- alternativas materialmente diferentes, quando existirem.

A Análise da proposta é diagnóstico, não autorização. Ela alimenta a linha de **Descoberta** do
Gate de kickoff; cada lacuna que pertença ao usuário será resolvida depois, uma pergunta por vez.

Proporcionalidade não remove autoridade. Em `read-only` puro e ajuste/bug trivial cujo contrato foi
explicitado, a análise pode colapsar a zero. Em `bounded`, colapsa numa linha: "Sem lacunas
materiais; contrato informado: <lista curta>". Projeto/produto greenfield nunca colapsa: stack
informada não define usuários, fluxos, estados, políticas, UX, dados nem aceite.

Sob briefing fechado (SUBAGENT-STOP), não produza a Análise da proposta nem abra a Descoberta: aplique o briefing e escale ao coordenador o que exigir decisão.

## Source mode e bootstrap

Detecte o repo-fonte do próprio PelizzAI EXCLUSIVAMENTE pela sentinela:

```text
scripts/pelizzai-source-repo.txt
```

Manifesto (`scripts/pelizzai-core-skills.txt`) e scripts `sync-harness.*` existem também nos
consumidores instalados via `-ExportConsumer` — a presença deles NÃO indica source mode.

Em **source mode**, não exija `pelizzai/domain-skills.md` nem crie runtime consumidor. Trabalhe
pelas regras do repo-fonte. Para tarefas mutáveis, ainda use task branch e prova, mas mantenha
plano/progresso no mecanismo nativo da plataforma e o seal como SHA do execution record; não crie
`pelizzai/data/state.md`, specs/plans consumidoras nem closure commit de state.

O **execution record nativo** é o estado lógico da tarefa no mecanismo de plano/task da plataforma,
nunca um arquivo substituto no repo. Mantenha nele, quando aplicável: `phase`, branch/base,
isolamento, decisões de execução, progresso, overlays, `validated-head`, `delivery-head` e status do
destino (`local | pushed | pr-open | partial`). Termine em `phase: done` ou `phase: blocked`;
`phase: delivered` é estado de repouso que ainda exige constatação de `done` (ver Estado e retomada).

Em projeto consumidor, **antes de classificar o pedido**, verifique: o harness está inicializado?
Se `pelizzai/domain-skills.md` NÃO existir — ou for a primeira interação com este projeto, ou o
usuário tiver digitado `bootstrap` —, **proponha** o bootstrap por `pelizzai-audit` (mapeia o
projeto, cria as skills de domínio e os docs) como a primeira coisa do turno e aguarde a resposta.
O router não espera o usuário lembrar de pedir: catálogo ausente é sinal suficiente para levantar a
proposta, em uma linha, com o motivo.

Propor não é executar. O bootstrap só escreve depois do "sim" explícito — aceito, o efeito passa a
`write-local` e vale o Gate de primeira escrita. Se o usuário recusar ou adiar, o pedido original
segue como estava: read-only continua read-only, nenhum arquivo é criado, e você registra a
limitação em uma linha ("sigo sem catálogo de domínio; o mapeamento fica para depois"). Pergunta
puramente conceitual, que não exige tocar nem entender ESTE projeto, não dispara a proposta —
responda direto. Em source mode não há gatilho: não existe catálogo consumidor a criar.

| Situação | Rota |
| --- | --- |
| Catálogo ausente, primeira interação com o projeto | Invoque `pelizzai-audit` (no mínimo `scan-only`) e proponha o bootstrap antes do Gate de kickoff; a recusa não bloqueia o pedido. |
| Catálogo ausente, `effect: read-only` | Mapeie em `scan-only`, proponha e aguarde. Sim → `pelizzai-audit` em `bootstrap-write`; não/depois → segue em `scan-only`, nenhum arquivo é criado. |
| Usuário disse `bootstrap`/`reinicializar` | `pelizzai-audit` em `bootstrap-write`. |
| Tarefa mutável, catálogo ausente | Faça scan-only, apresente o conjunto mínimo de artefatos proposto e obtenha consentimento para `bootstrap-write`. |
| Catálogo existe, ledger ausente | Em tarefa mutável autorizada, repare somente o ledger; read-only apenas reporta. |

Com catálogo **existente**, reexecutar bootstrap (remap) continua exigindo pedido explícito ou drift
observado: a proatividade vale para o harness não inicializado, não para reescrever o que já foi
ratificado.

## Estado e retomada

Leia `pelizzai/data/state.md` quando existir, sem escrevê-lo em tarefas read-only.

```text
slug: <none> ou phase: done
→ não há tarefa ativa.

phase: blocked
→ apresente o bloqueio antes de iniciar outra mutação.

phase: delivered
→ entrega selada aguardando constatação. Aplique a §Reconciliação da entrega anterior
  (`pelizzai-execution-plans`; retomada: `pelizzai-recovery`) ANTES de tratar como tarefa ativa ou
  conflito: verifique `confirmar:` contra o git e constate `done` — ou proponha retomar a branch ou
  `abandoned`. Só então classifique o pedido novo.

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
| Bootstrap/remap autorizado, ou proposta de bootstrap aceita | `pelizzai-audit` (`bootstrap-write`) |
| Algo quebrado/erro/falha/comportamento inesperado; "não funciona", "deu erro", "tá com bug", "para de chutar" | `bug` → `pelizzai-debugging` |
| Mudança local sem nova regra/contrato/superfície | `ajuste` → `pelizzai-quick-fix` |
| Refactor local preservando comportamento | `ajuste` → `pelizzai-quick-fix` |
| Review de diff, working tree, branch ou PR | `review` → `pelizzai-review` |
| Revisão codebase-wide de arquitetura, dívida ou seams | `review` → `pelizzai-improving-architecture` |
| Conflito Git em andamento | `pelizzai-resolving-merge-conflicts` |
| Produto/projeto greenfield, mesmo com stack definida | `exploratory` → `pelizzai-brainstorming` + `pelizzai-interview-me` → spec → plano |
| Feature/refactor/infra com design já aprovado e plano pronto | `pelizzai-execution-plans` |
| Design/spec/Figma aprovado, aceite claro, mas sem plano | `pelizzai-writing-plans`; brainstorming/interview-me **propostos** quando a Análise da proposta sinaliza lacuna material |
| Estressar design/plano existente, resolver lacuna material sinalizada, ou pedido de entrevista | proposto pela Análise da proposta ou pelo usuário → `pelizzai-interview-me` |
| Feature/refactor/infra existente com requisitos ratificados, mas sem plano | use lane abaixo |

### Lanes de feature/refactor/infra

| Lane | Predicado | Rota |
| --- | --- | --- |
| `bounded` | baixa incerteza/risco; um comportamento coeso; aceite claro; sem decisão arquitetural | `pelizzai-writing-plans` em modo compacto; não force brainstorming. |
| `standard` | risco médio e/ou algumas partes/contratos, com solução e aceite claros | `pelizzai-writing-plans`; prependa brainstorming compacto somente se restar trade-off real. |
| `exploratory` | alta incerteza ou risco alto que exige descoberta/mitigação de design; arquitetura ou decisões sensíveis acopladas | `pelizzai-brainstorming` completo + stress proporcional → plano. |

### Regra greenfield

Produto/projeto greenfield é sempre `exploratory` na entrada: isso inclui criar sistema, aplicativo,
serviço ou MVP do zero, ainda que framework, linguagem e banco já tenham sido escolhidos. A stack reduz incerteza
técnica; não resolve decisões de produto. A rota obrigatória, salvo dispensa explícita do usuário
em cada artefato, é:

```text
entendimento ratificado
→ descoberta com uma pergunta por vez e recomendação
→ design/spec
→ stress da spec + aprovação
→ proposta e ratificação de domain skills
→ plano de implementação
→ stress do plano + aprovação
→ setup ratificado
→ execução
```

Context7/documentação oficial é reconhecimento técnico read-only, não etapa tardia. Depois de
identificar a stack e a versão real em manifests/lockfiles — ou a stack candidata em greenfield —,
consulte-o antes do kickoff quando isso melhorar a classificação, revelar restrições, evitar uma
pergunta factual ou tornar a recomendação mais precisa. Continue usando-o durante design, plano,
implementação, debugging, upgrades e autoria/manutenção de skills. Nunca o use para inventar
persona, regra de negócio, permissão, estado, prioridade, retenção ou critério de aceite.

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

O router não aplica esses defaults — calcula a recomendação e encaminha para ratificação:

- **Tracks com plano** (bounded/standard/exploratory): defira isolamento, modo e commit ao **Gate de setup pós-plano** consolidado da `pelizzai-execution-plans` — é lá que as três opções de modo (inline · subagents · **team**) ficam sempre visíveis e a estratégia de commit é sempre mostrada.
- **Write-local sem plano** (ajuste/bug): entregue a recomendação à head skill; a própria head skill
  (`pelizzai-quick-fix`/`pelizzai-debugging`) emite um confirm compacto antes da primeira escrita.
  O router não duplica a pergunta.

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
execution-mode, commit-strategy, audience, kickoff,
discovery, spec, spec-approval, domain-skills-decision, plan, plan-approval, project,
validated-head (somente após validação final).
```

Em greenfield, `discovery`, `spec-approval`, `domain-skills-decision` e `plan-approval` começam
`pending`. O gate de setup não pode gravar `kickoff: ratificado` enquanto algum deles continuar
pendente, salvo dispensa explícita registrada no campo correspondente.

Ao ratificar o Gate de kickoff, registre a `lane`/`audience`/overlays da rota, mas deixe `kickoff:
pendente`: o marcador `kickoff: ratificado <AAAA-MM-DD>` pertence ao Gate de setup pós-plano ou ao
confirm da head skill de ajuste/bug, antes da primeira escrita de produto. A retomada honra decisões
já ratificadas; uma tarefa nova nunca herda `lane`/`kickoff`/`audience`.

Uma tarefa nova nunca herda decisões da anterior. O fechamento pertence a `pelizzai-finish-task`.

## Red flags

```text
- Bootstrap mutável para responder pedido read-only sem propor e obter o "sim" do usuário.
- Encontrar catálogo ausente e seguir em silêncio, sem propor o bootstrap.
- Escrever state/spec/plano antes do isolamento.
- Forçar brainstorming completo numa feature bounded.
- Classificar produto/projeto greenfield como bounded porque a stack foi informada.
- Usar linha/arquivo como único medidor de complexidade.
- Tratar frontend/security como oferta tardia.
- Aplicar isolamento, modo de execução ou estratégia de commit sem ratificação do usuário.
- Pulverizar a rota ou o setup em várias micro-perguntas em vez de um bloco agrupado.
- Assumir em silêncio decisão que muda escopo/UX/arquitetura sem apresentá-la na Análise da proposta nem no Gate de kickoff.
- Usar Context7, convenção ou “default seguro” como voto do usuário.
- Fazer várias perguntas de descoberta no mesmo turno quando a resposta anterior muda a próxima.
- Paralelizar escrita numa working tree compartilhada como se worktree isolasse agentes.
- Herdar `lane`/base/branch/strategy de state de uma tarefa ANTERIOR como carryover acidental — a política de projeto explicitamente ratificada no `profile.md` é a única exceção.
- Acionar várias head skills ao mesmo tempo.
```

## Gate de kickoff (rota como recomendação)

Depois de montar envelope → Análise da proposta → lane → head skill → overlays, apresente a **rota proposta** como uma **recomendação a ratificar** antes de investir — nunca um formulário, um bloco só com o default já pré-selecionado. A classificação continua sua; segui-la ou ajustá-la é do usuário. O router é o **único** emissor do kickoff; o core apenas sinaliza intenção/audiência/ambiguidade e entrega.

**Quando informa e segue:** somente `read-only` de review/análise/explicação, porque não existe
mutação a autorizar. Toda rota mutável para no kickoff, inclusive `bounded`, ajuste e bug; a
profundidade do bloco pode ser uma única linha, mas a resposta afirmativa é obrigatória.

**Antes do kickoff:** em projeto consumidor sem catálogo, a proposta de bootstrap (§Source mode e
bootstrap) vem primeiro e vale também em `read-only`. Ela não é o kickoff — é uma pergunta de uma
linha sobre inicializar o harness; o "não" devolve o pedido à rota original sem criar nada.

**Para toda tarefa mutável:** pare e aguarde ratificação. Faça uma única pergunta sobre a rota;
mostre detalhes como contexto, não como várias perguntas simultâneas:

```text
**Gate de kickoff — rota proposta:**
- Entendimento: <X> como <feature|ajuste|bug|refactor>
- Lane: <bounded|standard|exploratory|high-risk> — <justificativa em 1 linha>
- Head + overlays: <head skill> + <overlays ou "nenhum">
- Descoberta: <"sem lacunas materiais" | lista numerada de lacunas → recomendo <pelizzai-brainstorming compacto|completo|pelizzai-interview-me focal>>
- Artefatos: <spec/plano/ADR previstos nesta lane | "nenhum além do plano nativo">; em greenfield/exploratory com catálogo ausente ou stack nova, liste também "domain skills da stack (proposta na borda do design)"

Recomendação: aceitar esta rota porque <motivo>.
Pergunta única: Posso seguir com esta rota? (sim ou ajuste)
```

Uma resposta afirmativa aceita a rota; o usuário pode ajustar lane, descoberta, artefatos ou overlay.
Sem resposta afirmativa, segure o turno. Depois do kickoff, a descoberta pergunta **uma decisão por
turno**, sempre com recomendação; não transforme o bloco de rota num questionário de requisitos.

Em lane greenfield/exploratory com catálogo ausente ou stack nova, a linha Artefatos antecipa as
"domain skills da stack (proposta na borda do design)": elas serão propostas pelo **Gate proativo de
domain skills** da `pelizzai-audit` na borda design→plano — o usuário já vê no kickoff que virão e
decide lá.

**Audiência:** quando o usuário parece não-técnico ou a intenção admite ≥2 leituras materiais, a primeira linha do bloco reapresenta o entendimento (handshake) antes de rotear; registre `audience: technical | layperson` (ver Registro de execução). Não despeje jargão; siga `pelizzai-writing-clearly-and-concisely`.

**Descoberta:** quando houver lacuna material, recomende `pelizzai-brainstorming`/`pelizzai-interview-me`.
Aceitar inicia a entrevista sequencial. Pular descoberta exige pedido explícito e registra quais
decisões ficaram sem validação; a LLM não preenche essas decisões por conta própria.

**Setup fica fora deste bloco:** isolamento, modo (com `team` sempre visível) e commit são ratificados no Gate de setup pós-plano da `pelizzai-execution-plans` (tracks com plano) ou no confirm de uma linha da head skill (ajuste/bug). O router recomenda em silêncio e não repete a pergunta.

Sob briefing fechado (SUBAGENT-STOP), não produza análises de rota nem abra o Gate de kickoff: aplique o briefing e escale ao coordenador o que exigir decisão.

## Avaliação de regressão

Ao alterar regras de routing, Context7, discovery, spec, plano ou autoridade, valide a matriz
[adaptive-user-control.md](evals/adaptive-user-control.md). Ela combina a falha histórica com
greenfield em outra plataforma, feature existente, upgrade/refresh de skill, debugging e ajuste
local para impedir tanto autonomia quanto sobreajuste a um prompt ou stack.

## Instrução final

Classifique efeito, intenção, risco, incerteza e superfícies. Apresente a Análise da proposta e a
rota recomendada; em tarefa mutável, só invoque a head skill após ratificação explícita. Greenfield
sempre descobre, especifica, estressa e planeja antes de implementar. Selecione reasoning/test/review
proporcionalmente, sem transformar inteligência de processo em autoridade sobre o produto.
