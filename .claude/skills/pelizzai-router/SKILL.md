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

Não transforme essas classificações em formulário para o usuário. Derive-as do pedido e da evidência; pergunte apenas se uma decisão material pertence a ele.

## Source mode e bootstrap

Detecte o repo-fonte do próprio PelizzAI pela presença conjunta de:

```text
.claude/skills/pelizzai-core/SKILL.md
scripts/pelizzai-core-skills.txt
scripts/sync-harness.ps1
```

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
| Design/spec/Figma aprovado, aceite claro, mas sem plano | `pelizzai-writing-plans`; brainstorming só para lacuna material remanescente |
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

Não apresente menus quando há um default seguro e reversível:

```text
bounded/ajuste/bug comum:
  isolation: branch
  execution-mode: inline
  commit-strategy: granular
  → informe os defaults; o usuário pode trocar.

plano com frentes realmente independentes:
  considere worktree(s) e team; explique o ganho e o custo antes de perguntar.

squash-final:
  ofereça apenas quando histórico intermediário não tem valor; consolide ANTES da validação final.
```

Use subagents/time para independência real, diversidade de hipóteses ou ganho mensurável. Não os trate como hierarquicamente melhores que inline.

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
slug, track, phase, effect, risk, overlays,
base-ref, base-sha, branch, isolation, worktree-path,
execution-mode, commit-strategy, audience, plan, project,
validated-head (somente após validação final).
```

Uma tarefa nova nunca herda decisões da anterior. O fechamento pertence a `pelizzai-finish-task`.

## Red flags

```text
- Bootstrap mutável para responder pedido read-only.
- Escrever state/spec/plano antes do isolamento.
- Forçar brainstorming completo numa feature bounded.
- Usar linha/arquivo como único medidor de complexidade.
- Tratar frontend/security como oferta tardia.
- Perguntar branch/team/commit quando defaults seguros bastam.
- Paralelizar escrita numa working tree compartilhada como se worktree isolasse agentes.
- Reaproveitar base/branch/strategy de tarefa anterior.
- Acionar várias head skills ao mesmo tempo.
```

## Instrução final

Classifique efeito, intenção, risco, incerteza e superfícies. Garanta primeira escrita segura, escolha uma head skill, propague overlays e deixe reasoning/test/review variarem proporcionalmente.
