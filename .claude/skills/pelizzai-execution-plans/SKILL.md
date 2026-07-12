---
name: pelizzai-execution-plans
description: Executa um plano aprovado tarefa por tarefa, escolhendo prova/review proporcionais, mantendo state no consumidor ou execution record no source mode e selando o candidato final. Use quando houver plano/PRD/issues prontos para implementar. Nunca escreva em branch protegida; starting-branch prepara o isolamento antes da execução.
---

# PelizzAI Execution Plans

## Objetivo

Executar um plano aprovado com **disciplina por tarefa**: cada tarefa recebe a estratégia de
teste/validação adequada ao artefato, passa pelas lentes de spec + qualidade no perfil de review
proporcional e só então é
consolidada. No final, overlays que podem escrever rodam antes de o conteúdo ser selado por
review, suíte e checklist. A skill mantém estado retomável e impede integrar conteúdo diferente
do que foi validado.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Execution Plans para executar o plano, tarefa por tarefa."

<MEMBRO-DO-TIME-STOP>
Se você é um **membro** (teammate/subagente) encarregado de **uma tarefa**, implemente apenas a
sua: siga a estratégia de teste declarada, as skills de domínio e as skills transversais/overlays
coladas no briefing; respeite `pelizzai-preferences` e devolva `DONE`, `DONE_WITH_CONCERNS`,
`BLOCKED` ou `NEEDS_CONTEXT`. Não orquestre nem commite. Ver `references/task-cycle.md`.
</MEMBRO-DO-TIME-STOP>

---

## Princípio central

> Execute um plano aprovado com gates humanos nas **bordas** e autonomia entre tarefas. Nenhuma
> tarefa é consolidada sem evidência apropriada ao artefato e review. Nenhum conteúdo muda depois
> de `validated-head`; consumidor acrescenta só o closure metadata-only, source mode nenhum commit.

---

## Gate de setup pós-plano (OBRIGATÓRIO antes da Tarefa 1)

O normal é a branch de tarefa/planejamento já existir: `pelizzai-starting-branch` a criou **antes**
da spec/plano e gravou `base-ref`/`base-sha`. Se um plano externo (PRD/issues) chegou sem branch,
invoque-a agora antes de continuar.

Com o plano aprovado e **antes de qualquer escrita de produto**, apresente **UM bloco consolidado**
com as decisões pré-preenchidas — cada uma com a recomendação e uma linha de porquê — e **aguarde a
ratificação**. Não é autonomia nem pulverização: a classificação (lane/risco/topologia) continua
rodando e agora POPULA os defaults recomendados. Leia primeiro `pelizzai/profile.md`
(§Defaults de execução ratificados): campo preenchido = a recomendação já vem da política do
projeto; `<unset>` = calcule o default proporcional. `destination` **nunca** sai do profile —
push/PR/publicação são decididos por tarefa na `pelizzai-finish-task`.

```text
**Gate de setup pós-plano — plano "<nome>" com N tarefas (responda "ok" ou ajuste item a item):**
0. Plano: <aprovar conteúdo | ajustar antes>
1. Isolamento: [recomendado: <branch|worktree> — <porquê>] | alternativa: <...>
2. Branch: <tipo>/<slug> sobre <base descoberta> [confirme o nome]
3. Modo de execução: [recomendado: <inline|subagents|team> — <porquê>] | inline | subagents | team
4. Commits: [recomendado: granular] | squash-final (somente com seu pedido)
5. Review por tarefa: [recomendado: <perfil> conforme o plano]
```

Regras do bloco: o item 3 mantém **as três opções sempre visíveis** — **team nunca é omitido** —
mesmo quando inline é a recomendação; recomende team/subagents quando o paralelismo é real e a
coordenação compensa, sem impor (a escolha é do usuário; não existe ranking `team > subagents >
inline`). O item 4 traz **squash-final somente com pedido explícito do usuário**. O item 0 ratifica
o **conteúdo** do plano (o QUÊ); os itens 1-5 são o **como** — itens distintos na MESMA mensagem,
nunca duas perguntas sequenciais. Plano gerado pelo harness precisa de aprovação explícita no item
0; PRD/issues fornecidos pelo próprio usuário já contam como ratificados e o item 0 apenas confirma.
Um "ok" aceita todas as recomendações; o usuário sobrescreve item a item. **Aguarde a resposta** —
silêncio e o próprio default NÃO valem como aprovação. NUNCA antes do "ok": código da Tarefa 1,
criação/mudança de worktree, squash, ou gravação dessas decisões como finais.

Sob briefing fechado (SUBAGENT-STOP / MEMBRO-DO-TIME-STOP), não produza análises de rota nem abra
gates: aplique o briefing e escale ao coordenador o que exigir decisão.

**Recap-e-prossegue (política já ratificada).** Se `pelizzai/profile.md` já traz a política do
projeto, o bloco vira um **recap de UMA linha** ("Seguindo a política deste projeto: worktree ·
team (≥4 frentes) · granular · destino por-tarefa — muda algo nesta tarefa?") e PROSSEGUE.

**O recap-e-prossegue dispensa apenas os itens 1-5 (setup); o item 0 nunca colapsa.** Todo plano
gerado pelo harness ainda tem o **conteúdo** (o QUÊ) apresentado e ratificado, mesmo com a política
do profile já ratificada — as regras de aprovação do bloco valem sempre para o item 0: aguarde a
resposta, silêncio e o próprio default não valem como aprovação. Só PRD/issues fornecidos pelo
próprio usuário dispensam o item 0 (já contam como ratificados), e aí o recap é de fato uma linha. A
política de projeto cobre o COMO, nunca o QUÊ.

Só volte ao bloco item a item quando (a) o usuário pedir mudança ou (b) os sinais da tarefa
divergirem da
política (ex.: profile=inline mas o plano tem frentes independentes suficientes para team →
sinalize a divergência, recomende o modo adequado e aguarde ratificação só nesse ponto). **Nova
tarefa/plano re-exibe o recap** — nunca assuma a política em silêncio. Um override contra a política
sem trocá-la é anotado (execution record nativo/efêmero, nunca no `profile.md` versionado antes do
seal) e incrementa "Overrides desde então" ao re-ratificar. Trocar a política pede confirm-on-change
("Atualizo o profile do projeto para X? [s/n]") antes de gravar; nunca silenciosa. Em source mode
não há `pelizzai/profile.md`: os defaults ratificados vivem no execution record nativo (mesmo
marcador `kickoff: ratificado`) e o recap lê de lá; sem esse registro, o bloco batched aparece.

**Aplicar o isolamento — invoque `pelizzai-starting-branch` (PÓS-ratificação).** Só depois do "ok":
branch faz checkpoint do setup persistente quando existir e mantém a branch atual; worktree captura
`checkpoint-sha` após o checkpoint opcional, libera a branch no working tree principal, adiciona o
worktree com a **branch existente** e registra o novo path antes da Tarefa 1. Ambos começam a
implementação com working tree limpa. Worktree não autoriza vários writers concorrentes no mesmo
diretório. Qualquer `squash-final` ocorre **antes** de review final/testes/`validated-head`;
`pelizzai-finish-task` nunca reescreve conteúdo ou histórico após o seal.

**Registrar (só após o "ok").** Grave isolation/execution-mode/commit-strategy e o marcador
`kickoff: ratificado <AAAA-MM-DD>` no state consumidor (`pelizzai/data/state.md`) ou, em source mode,
no execution record nativo com as mesmas palavras-chave. Em retomada real com valores já ratificados
e gravados (`kickoff: ratificado`), honre sem re-perguntar. Escritas/review/commit na working tree
são serializados.

---

## Pré-requisitos (gate)

Antes da primeira tarefa, confirme:

```text
[ ] Plano ratificado na borda: plano gerado pelo harness recebeu aprovação explícita do CONTEÚDO
    (item 0 do gate consolidado); PRD/issues fornecidos pelo próprio usuário já contam como
    ratificados. Sem plano → volte a pelizzai-writing-plans.
[ ] Consumidor: catálogo existe (zero domain skills é válido) e state foi preparado.
    Source mode: NÃO crie catálogo/state consumidor; use as regras do repo-fonte e execution record.
[ ] As skills de domínio relevantes foram selecionadas quando o consumidor as possui.
[ ] `overlays` foi inferido pelo efeito/superfície e as skills transversais estão prontas para
    aplicar/colar nos briefings de executores e reviewers.
[ ] O gate de setup pós-plano foi conduzido: isolation/execution-mode/commit-strategy RATIFICADOS
    pelo usuário no bloco consolidado (nenhum default aplicado sem ratificação; nenhum <pending>;
    `kickoff: ratificado`) e o isolamento criado via pelizzai-starting-branch APÓS o "ok".
[ ] NÃO está em branch protegida (default real/base-ref, main/master/develop/dev, ou HEAD vazio).
[ ] Em consumidor, o estado existe em pelizzai/data/state.md (se não, instancie a partir do template e preencha
    slug/track/lane/phase/project/branch/base-ref/base-sha/kickoff/isolation/execution-mode/
    commit-strategy/overlays/plan antes da Tarefa 1; `validated-head: <none>`, `kickoff: pendente`
    até a ratificação) e
    foi validado contra o git (branch: `git branch --show-current`; worktree: `git worktree list`
    ou o comando rodado DENTRO do worktree-path).
```

No consumidor, o diretório `pelizzai/` segue o padrão do harness e o estado vive em
`pelizzai/data/state.md`. Em source mode, o estado vive somente no execution record nativo.

---

## Construir o pacote de skills (obrigatório nos três modos)

Skills de domínio capturam padrões do projeto; skills transversais/overlays capturam uma superfície
da mudança. **Todo executor e reviewer recebe as aplicáveis** — o briefing de CADA tarefa (inline,
subagents ou team) inclui o pacote de domain skills aplicável do catálogo, não só os overlays.
Recalcule overlays pelo diff real: UI inclui
`pelizzai-frontend`; superfície sensível inclui `pelizzai-oswap`; nova superfície estável pode
incluir `pelizzai-documenting-features`. Persistir nomes em `overlays:` não substitui colar seus
gates no briefing.

```text
1. Consumidor: leia `pelizzai/domain-skills.md`; source mode: use regras/skills do repo-fonte.
2. Leia `overlays:` no state/execution record e complemente pelo efeito/superfície observada.
3. Inline: carregue domínio + overlays. Subagents/Team: COLE seus pontos operacionais no briefing.
4. Propague o mesmo pacote ao reviewer; ele precisa julgar requisitos de UI/segurança/docs também.
5. Prioridade: pedido explícito e regras do projeto > skills de domínio > overlays aplicáveis >
   preferences/reasoning genéricos. Conflito material sobe ao coordenador.
6. Se a superfície de uma tarefa toca uma stack SEM domain skill cobrindo (catálogo existe mas não
   cobre), registre UMA "lacuna de domain skill" no state/execution record e sinalize-a no relatório
   da tarefa (membro devolve `DONE_WITH_CONCERNS`); NÃO bloqueie a execução nem crie skill no meio
   da tarefa. O coordenador acumula as lacunas e encaminha ao eixo adoption-driven de
   `pelizzai-writing-skills` no fechamento, numa proposta única e agrupada — nunca um gate por tarefa.
```

No consumidor, catálogo ausente volta a `pelizzai-audit`. Em source mode, ausência é o contrato — o
gate de proposta de domain skills não roda; regras de domínio, se houver, vivem no execution record
nativo. Quando o plano chegou por PRD/issues (sem passar por `pelizzai-writing-plans`/
`pelizzai-brainstorming`) e a stack não está coberta pelo catálogo do consumidor, o gate de setup
pós-plano puxa a proposta proativa de domain skills (recomendar-e-ratificar; dona: `pelizzai-router`/
`pelizzai-writing-plans`/`pelizzai-audit`) antes da Tarefa 1 — esta skill não a re-especifica,
só garante que esse caminho não a pule.

---

## Os três modos de execução

Não há ranking universal; use a menor coordenação que preserve qualidade.

| Modo                 | Skill              | Quando                                                                       |
| -------------------- | ------------------ | ---------------------------------------------------------------------------- |
| **team**             | `pelizzai-team`    | Frentes com dependências que exigem coordenação e troca durante a execução |
| **subagents**        | `pelizzai-subagents` | Tarefas independentes que só precisam **reportar**; um subagente fresco por tarefa, contexto isolado, review por tarefa |
| **inline**           | —                  | Plano pequeno/sequencial em que delegar custaria mais que executar |

```text
Branch e worktree desta tarefa têm UMA working tree de integração. Apenas o coordenador aplica
escritas nela, em série. Agentes podem investigar/revisar em paralelo ou devolver patches; não
mantêm WIP concorrente no diretório compartilhado. Antes do review por tarefa, quiesça writers e
gere `review-package --working-tree`, que deve representar somente a tarefa em revisão.
```

**Desempate:** team quando membros precisam conversar/negociar dependências; subagents quando cada
unidade só precisa reportar; inline quando o trabalho é curto e serial. Paralelismo, sozinho, não
obriga team.

Registre o modo no `state.md` consumidor ou execution record nativo
(`execution-mode: team | subagents | inline`).

---

## Fluxo

```mermaid
flowchart TD
    PL[Plano aprovado na branch de planejamento] --> GATE[Gate pos-plano consolidado:\napresenta recomendacoes,\naguarda ratificacao]
    GATE --> DOM[Carregar dominio + overlays]
    DOM --> PRE[Pre-voo: varrer plano por contradicoes]
    PRE --> CY[Ciclo adaptativo por tarefa\nref: task-cycle.md]
    CY --> T[Implementar com estrategia por artefato\n+ dominio + overlays]
    T --> RV[Review proporcional\ncombined ou split]
    RV --> Q{Aprovado nos dois?}
    Q -- Nao --> FX[Corrigir e re-revisar\ncircuit breaker: 3 ciclos/estagio]
    FX --> RV
    Q -- Sim --> CM[Coordenador avanca o cursor E consolida\num commit so, cursor incluso]
    CM --> MORE{Mais tarefas?}
    MORE -- Sim --> CY
    MORE -- Nao --> OV[Overlays que podem escrever\nsecurity + frontend + docs]
    OV --> CONS[Congelar historico\nsquash-final se escolhido]
    CONS --> VAL[Review final + suite + checklist]
    VAL -- Fix --> OV
    VAL -- Aprovado --> VC[pelizzai-verification-before-completion]
    VC -- Fix --> OV
    VC -- Aprovado --> SEAL[validated-head = HEAD]
    SEAL --> FIN[pelizzai-finish-task\nmetadata-only + destino]
    FIN --> done([Plano entregue])
```

OODA é útil como **controle macro** quando há feedback e estado mutável: observar evidência,
orientar contra a DoD, decidir e agir. Não é o reasoning obrigatório de toda tarefa. O briefing
seleciona a técnica que ataca o problema (decomposição, RCA, hipótese, comparação, verification);
OODA apenas coordena iterações quando existe um loop real.

---

## Pré-voo

Antes da Tarefa 1, leia o plano **uma vez** procurando contradições internas ou conflitos com as skills de domínio/critérios de review. Se houver, apresente tudo ao usuário em **uma** pergunta batched; se estiver limpo, siga em silêncio.

---

## Ciclo por tarefa

O protocolo detalhado — briefing autossuficiente, estratégia por artefato, review proporcional
com duas lentes, circuit breaker e commit como gate — está em
**[references/task-cycle.md](references/task-cycle.md)**. Resumo:

```text
1. Briefing: COLE o texto completo + skills de domínio + overlays + estratégia de evidência e
   perfil de review (`combined` ou `split`)
   (o membro nunca lê o arquivo inteiro do plano; use scripts/task-brief.* somente quando houver
   plano Markdown persistente compatível. Plano nativo usa colagem/brief construído — ver §1,
   incluindo
   `review-package --working-tree`; range é só final). Instrua preferences/reasoning com a
   prioridade certa: regras do projeto > domínio > overlays > camada genérica.
   Responda perguntas ANTES de o trabalho começar.
2. Aplicar TDD, characterization, validate, visual ou static/scenario conforme o artefato. O
   membro NÃO commita.
3. Review com duas lentes: (a) conformidade com a spec; (b) qualidade + evidência FRESCA.
   `combined` aplica ambas em um despacho/relatório para tarefa bounded/low-risk; `split` usa
   estágios sequenciais quando risco, contrato, dados, segurança ou complexidade pedirem.
4. Reprovou? Corrija (re-despachando ao implementador — não corrija à mão, polui o contexto) e
   RE-REVISE na mesma lente. Circuit breaker: 3 ciclos por lente por tarefa; mesma issue 2x
   escala na 2ª; rejeição estrutural escala de imediato; ao estourar → registra phase: blocked
   e escala ao humano com mensagem acionável.
5. As duas lentes aprovaram? O COORDENADOR consolida: estagia paths EXATOS da tarefa e, no
   consumidor, atualiza/estagia state no mesmo commit; em source mode avança o execution record
   sem arquivo. Inspeciona `git diff --cached` e commita (granular: definitivo; squash-final: wip).
   Nunca use `git add -A`.
```

---

## Modo Team

Use `pelizzai-team` quando frentes precisam coordenar dependências. O lead delega briefings com
domínio + overlays e sintetiza. Investigação pode ser paralela; aplicação na working tree, review,
cursor e commit são serializados pelo coordenador.

## Modo Subagents

Use `pelizzai-subagents`. Um subagente **fresco por tarefa**, despachado pelo coordenador, com contexto isolado. O coordenador roteia, aplica o perfil de review e consolida. Execução contínua entre tarefas; sem pausa por tarefa.

## Modo Inline

Para plano pequeno e sequencial, o coordenador executa na própria sessão seguindo o mesmo ciclo.
Inline é uma escolha adequada, não um fallback inferior.

---

## Higiene de contexto

A regra geral (zona segura, fases, "handoff bifurca; compact continua") mora na `pelizzai-core`. Na execução de planos, aplique-a assim:

```text
- Zona segura: ~120k tokens. Acima disso a qualidade degrada — planeje as fronteiras de fase
  ANTES de chegar lá, não quando a janela já está cheia.
- Design → plano nascem numa janela ininterrupta; cada tarefa executa em contexto fresco
  (briefing colado — é o que os modos team/subagents já garantem).
- NUNCA compacte no meio de uma fase ou tarefa: feche a fase (review ✅ + cursor + commit)
  e compacte na borda.
- Handoff bifurca; compact continua: para mudar de rumo ou abrir outra frente, despache com
  briefing novo; para continuar o MESMO trabalho com a janela cheia, compacte na borda de fase.
```

---

## Estado e retomada

Invariantes comuns:

```text
- `phase: done`/slug vazio significa nenhuma tarefa ativa; tarefa nova não herda decisões de state
  da anterior (carryover acidental). A política de projeto ratificada em `pelizzai/profile.md` não é
  herança: pré-seleciona a recomendação do recap, re-exibido e ratificável a cada nova tarefa.
- `base-ref`/`base-sha` são o snapshot inicial e nunca são recalculados no fim.
- mudança de conteúdo invalida `validated-head`; ele só nasce após a validação final.
- `project` é exatamente um repo; outro repo recebe outro registro de execução.
- branch/worktree, HEAD e progresso do registro precisam concordar com Git.
```

**Consumidor:** o cursor vive em `pelizzai/data/state.md` (template em
[templates/state.md](templates/state.md)). Avance-o no mesmo commit da tarefa; os únicos commits
só de cursor são `phase: blocked` e o closure final. Após compaction, reconstrua pelo state, arquivo
`plan:` e Git.

**Source mode:** o cursor vive no plano/execution record nativo. Avance-o após cada commit, leia o
plano nativo para tarefas pendentes e reconstrua pelo record + Git; não procure/crie state, arquivo
de plano consumidor nem commit de cursor. State ausente é o contrato, não uma divergência.

Em ambos os modos, valide branch com `git branch --show-current` e worktree por
`git worktree list`/comando dentro do path registrado. Divergência material chama
`pelizzai-recovery` no modo correspondente; ela preserva WIP antes de reconciliar.

---

## Loop até a entrega (controle adaptativo)

O loop usa evidência e Definition of Done. OODA pode coordenar o macro-loop, mas o reasoning local
é selecionado pela situação. Em dúvida material, pare e use `pelizzai-interview-me`; não transforme
incerteza em mais uma volta automática.

---

## Gates humanos (bordas) e autonomia entre tarefas

```text
GATES (recomendar-e-ratificar nas bordas; nunca aplicar decisão estrutural em silêncio):
- Começar em branch protegida (main/master/develop/dev) — proibido, sem exceção.
- Setup pós-plano: conteúdo do plano (item 0), isolamento, modo de execução com **as três opções
  sempre visíveis** (**team nunca é omitido**), estratégia de commit (**squash-final somente com
  pedido explícito do usuário**), review por tarefa e nome/base da branch são apresentados JUNTOS
  como recomendação, num único bloco consolidado, e ratificados antes da Tarefa 1. Nenhum
  worktree/squash/modo é aplicado enquanto "fica no default" sem ratificação. Recomende
  team/subagents quando o paralelismo é real e a coordenação compensa — sem impor.
- Destino externo: push / PR / descarte e remoção de worktree exigem decisão POR TAREFA; sem pedido
  externo, finish-task mantém local por default. `destination` nunca é herdado de política do profile.
- Conclusão.

AUTONOMIA (sem perguntar a cada passo):
- Entre as tarefas de um plano JÁ APROVADO e com o setup ratificado, execute de forma contínua
  (não pergunte "sigo?"). O recap de política aparece uma vez na borda do setup, não a cada tarefa.
- Pare apenas por: BLOCKED que você não resolve, ambiguidade material, ou plano concluído.

Sob briefing fechado (SUBAGENT-STOP / MEMBRO-DO-TIME-STOP), não abra gates nem recaps de política:
aplique o briefing e escale ao coordenador o que exigir decisão.

NUNCA o modo "mãos-livres" que remove os gates de borda (reprovado em campo no harness anterior).
```

---

## Validação final da entrega (coordenador/líder)

Ao terminar as tarefas, o coordenador valida a entrega inteira. A ordem é um contrato:

### 1. Rodar overlays que podem escrever

Reavalie `base-sha..HEAD` e execute, quando aplicável, **antes** do review final:

```text
- pelizzai-oswap: auth, input, SQL/query, segredo, upload, dependência, autorização etc.;
- pelizzai-frontend: requisitos anti-slop durante a implementação + app rodando, estados e
  viewports na validação visual;
- pelizzai-documenting-features: documentação exigida para nova superfície estável.
```

Overlay aplicável não é oferta tardia da finish-task. Correção ou doc gerada vira conteúdo da
entrega, recebe a evidência proporcional e é commitada antes de seguir.

### 2. Congelar a estratégia de commits

- `granular`: confirme working tree limpa e mantenha os commits definitivos.
- `squash-final`: consolide **agora**, nunca na finish-task. Prefira a alternativa recuperável a
  `reset --soft`: renomeie a branch atual para um nome único `<branch>-preseal-<timestamp>`, crie
  novamente `<branch>` em `base-sha`, aplique `git merge --squash <preseal>` e faça o commit final
  aprovado. A branch preseal preserva o histórico; não a delete automaticamente. Pare se a branch
  já estiver publicada ou se qualquer guarda falhar.

Depois desta etapa, `git status --porcelain` deve estar vazio e `validated-head` continua `<none>`.

### 3. Validar o candidato congelado

```text
1. Capture candidate-head = `git rev-parse HEAD`.
2. REVIEW FINAL via pelizzai-review no range exato `base-sha..candidate-head`. Use reviewer
   independente e capacidade proporcional ao risco. Exceção: uma única tarefa `bounded`, perfil
   `combined`, sem mutação posterior pode reutilizar o review da tarefa se
   `reviewed-tree == candidate-head^{tree}`; qualquer ausência de prova exige review normal.
   Critical/Important bloqueiam.
3. Rode pelo próprio coordenador todos os checks aplicáveis do perfil (test/lint/build/render/
   dry-run/visual etc.), do zero, com saída e exit code. Não invente suíte para artefato estático.
4. Releia plano/spec requisito a requisito e aponte onde cada um foi entregue.
5. Rode pelizzai-verification-before-completion com a evidência fresca.
```

Qualquer fix nos passos 2–5 — inclusive segurança, UI ou docs — invalida o candidato: grave
`validated-head: <none>`, commite o fix, volte ao passo 1 (overlays), reconsolide se a estratégia
for squash-final e **reabra o review final**. Aplique o circuit breaker do task-cycle ao loop.

### 4. Selar e entregar à finish-task

Com tudo aprovado e HEAD ainda igual a `candidate-head`, em consumidor escreva no state
`validated-head: <SHA completo de candidate-head>`, sem commitar; essa é a única sujeira permitida.
Em source mode, grave o SHA no execution record e mantenha a working tree limpa. Chame
`pelizzai-finish-task`: consumidor fecha com um commit metadata-only de state; source mode não cria
closure. Nenhum código, config ou doc pode mudar depois do seal.

---

## Raciocínio — `pelizzai-reasoning`

- Sequência conhecida: *Plan and Execute*; dependências: *Structured Decomposition*.
- Falha inesperada: hipótese + *Root Cause Analysis*; decisão entre alternativas: comparação/ToT.
- Feedback contínuo e realidade mutável: OODA como controlador macro, não como ritual local.
- Antes de consolidar e selar: *Verification* com evidência do artefato.

---

## Anti-padrões

```text
- Executar sem plano aprovado, sem o gate de setup pós-plano, ou sem isolamento (em branch protegida).
- Aplicar isolamento/modo/commit como decisão final sem ratificação do usuário (o correto é
  recomendar-e-ratificar num único bloco consolidado), ou omitir a opção team do menu de modo.
- Pular skills de domínio/overlays — ou não colá-las nos briefings de executor e reviewer.
- Escolher team por preferência universal, ou forçar effort máximo numa tarefa mecânica.
- Deixar o membro/subagente commitar (o commit é gate do coordenador, após as duas lentes de review).
- Aceitar "testes passam" inferido, sem evidência fresca colada.
- Corrigir à mão o trabalho reprovado de um membro (re-despache — corrigir à mão polui o contexto).
- Pular a re-revisão após um fix ("corrigi" é só mais uma alegação não verificada).
- Loop infinito de fix→re-review (ignorar o circuit breaker de 3 ciclos).
- Declarar entregue sem overlays aplicáveis + review final (ou reutilização bounded comprovada) +
  checks + checklist + seal.
- Pausar a cada tarefa de um plano já aprovado (quebra a execução contínua) — ou, no extremo oposto,
  remover os gates de borda (mãos-livres).
- Fazer o subagente ler o arquivo do plano inteiro (cole o texto da tarefa).
- Commit órfão só para mover o cursor DURANTE a execução (exceções legítimas: o registro de
  phase: blocked do circuit breaker e o commit de fechamento do cursor da pelizzai-finish-task
  no modo granular).
- Confiar no state.md sem validar contra o git ao retomar.
- Writers concorrentes na mesma working tree, tornando `--working-tree` impossível de escopar.
- Rodar security/frontend/docs depois da validação final, ou não reabrir review após fix.
- Executar squash/reset/rebase na finish-task depois de `validated-head`.
```

---

## Integração

**Combina com:**

- `pelizzai-writing-plans` — produz o plano na branch de tarefa já aberta.
- `pelizzai-starting-branch` — cria a branch antes do plano e aplica o isolamento pós-plano.
- `pelizzai-tdd` — disciplina para comportamento executável; outras estratégias estão no task-cycle.
- `pelizzai-team` / `pelizzai-subagents` — modos usados conforme a topologia; inline é par legítimo.
- `pelizzai-review` — review por tarefa (spec + qualidade) e review final da branch.
- `pelizzai-loop` — OODA quando houver loop real, Definition of Done e parada por dúvida.
- `pelizzai-reasoning` — ordenação, diagnóstico e verificação.
- `pelizzai-verification-before-completion` / `pelizzai-finish-task` — conclusão com gates.
- `pelizzai-audit` — padrão de diretório `pelizzai/` e catálogo de skills de domínio.

Invoque apenas as skills exigidas pelo efeito, risco, domínio e overlays da tarefa; não transforme o
catálogo inteiro em checklist.

---

## Instrução final para o agente

```text
Execute tarefa por tarefa com estratégia de evidência adequada e review working-tree.
Crie a branch antes de spec/plano; no gate pós-plano consolidado, recomende e ratifique conteúdo do
plano, isolamento, modo (três opções, team visível) e commits antes da Tarefa 1; recap-e-prossegue
quando a política do profile já foi ratificada.
Escolha inline/subagents/team pela topologia, sem ranking universal.
Propague domínio + overlays para executor e reviewers; sinalize lacuna de domain skill no relatório.
Mantenha gates humanos nas bordas; execute com autonomia entre tarefas.
Consolide só após spec ✅ e qualidade ✅ com evidência fresca.
Rode overlays antes de congelar/validar; qualquer fix reabre o review final.
Grave validated-head só após aprovação; finish cria closure só no consumidor.
Estado no state consumidor ou execution record source; um repo por tarefa; valide contra Git.
Nunca comece em branch protegida. Nunca mãos-livres.
```
