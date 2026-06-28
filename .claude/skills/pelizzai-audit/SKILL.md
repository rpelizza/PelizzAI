---
name: pelizzai-audit
description: Use essa skill no PRIMEIRO contato do usuário com o harness PelizzAI ou quando ele digitar "bootstrap". Ela faz o mapeamento completo do contexto — projeto único ou workspace, novo ou existente, stacks/frameworks/linguagens, MCPs instalados, skills de domínio, git/GitHub/GitLab — e orquestra a criação das skills de domínio (via `pelizzai-writing-skills`) e da documentação do harness (catálogo e ledger). Acione-a também sempre que o harness ainda não tiver sido inicializado neste projeto (sem `pelizzai/domain-skills.md`), ou quando o usuário pedir para "remapear", "reescanear" ou "reinicializar" o PelizzAI.
---

# PelizzAI Audit

<FIRST-TIME-USING-PELIZZAI>
Na **primeira vez** que o usuário interagir com o harness PelizzAI, ou sempre que ele digitar **"bootstrap"**, esta skill **PRECISA** ser invocada antes de qualquer trabalho. Sem este mapeamento, o harness atua às cegas.

O harness está inicializado neste projeto quando existe o arquivo `pelizzai/domain-skills.md`. Se ele **não** existe, trate como primeira vez.
</FIRST-TIME-USING-PELIZZAI>

## Objetivo

Mapear o contexto de trabalho para que o PelizzAI atue com precisão: identificar **o que** é o projeto (único ou workspace, novo ou existente), **com que** é construído (stacks, frameworks, linguagens, ferramentas), **o que já existe** de infraestrutura (MCPs, git/host remoto, skills de domínio) e, a partir disso, **preparar o harness** — criando as skills de domínio e a documentação que o tornam assertivo.

O mapeamento é **insumo**, não fim: ele existe para habilitar as próximas tarefas, não para produzir um relatório por si só.

**Anuncie ao iniciar:** "Usando a skill Pelizzai Audit para mapear seu contexto e preparar o harness."

---

## Princípio central

> Mapeie antes de agir, mas mapeie na medida certa. Um projeto novo e vazio precisa de uma entrevista; um monorepo maduro precisa de um repo-scan paralelo. Ajuste a profundidade ao que existe — e converta cada descoberta em um artefato útil (skill de domínio, recomendação ou registro), nunca em ruído.

Não transforme o bootstrap em interrogatório nem em auditoria interminável. Recomende mudanças (git, MCPs, integrações); **não as imponha** sem confirmação do usuário.

---

## Como executar o mapeamento

Conduza o levantamento com um **time de agentes**: use `pelizzai-team` (preferência) ou, se for indisponível/desnecessário, `pelizzai-subagents`. O mapeamento é naturalmente paralelizável — cada frente do inventário (estrutura, stacks, MCPs, git/host, skills existentes) é uma frente disjunta, ideal para um membro do time.

- Coordene pelo protocolo da `pelizzai-team`: um briefing por frente, arquivos/áreas próprios, e síntese ao final.
- Cada frente é **leitura** (read-only): prefira o agentType `Explore` no modo subagents.

---

## Fluxo lógico do bootstrap

```mermaid
flowchart TD
    Start([Primeira interacao OU bootstrap]) --> Eng[Motor de mapeamento:\npelizzai-team / pelizzai-subagents]
    Eng --> Inv[Inventario paralelo do contexto]
    Inv --> Tri{Workspace ou projeto unico?}
    Tri --> New{Projeto novo ou existente?}

    New -- Novo --> Int[pelizzai-interview-me\ncoletar intencao]
    Int --> Bra[pelizzai-brainstorming\ndesenho aprovado]
    Bra --> Wri

    New -- Existente / Workspace --> Scan[Repo-scan completo:\npadroes, stacks, frameworks, convencoes]
    Scan --> Wri[pelizzai-writing-skills:\ncria o maximo de skills de dominio\ncom context7 + regras Anthropic]

    Wri --> Doc[Documentacao do harness:\npelizzai/domain-skills.md catalogo\npelizzai/data/review-domain-skills.md ledger]
    Doc --> Rec[Recomendacoes ao usuario:\ngit init, GitHub/GitLab, MCPs, context7]
    Rec --> End([Harness pronto para atuar])
```

---

## Fase 1 — Triagem do alvo

Determine, antes de tudo, **o que** você está mapeando:

- **Workspace ou projeto único?** Vários projetos independentes na mesma pasta (múltiplos `package.json`/`pyproject.toml`/`.git`, subpastas autossuficientes) indicam workspace/monorepo — mapeie cada projeto e a relação entre eles.
- **Novo ou existente?** Pasta vazia ou só com scaffolding (sem código de domínio, sem histórico relevante de git) → **novo**. Caso contrário → **existente**.

## Fase 2 — Inventário do contexto (em paralelo)

Levante, em frentes simultâneas:

```text
- Estrutura: layout de pastas, monorepo vs único, módulos e fronteiras.
- Stacks: linguagens, frameworks, gerenciadores de pacote, build, runtime, banco de dados.
- MCPs: instalados no projeto (.mcp.json, .claude/settings.json) e globais (~/.claude).
- Skills de domínio: já existe alguma skill não-`pelizzai-` neste projeto?
- Versionamento: git inicializado? remoto no GitHub/GitLab? CI/CD? branch atual e fluxo.
- Convenções: CLAUDE.md/AGENTS.md, linters, padrões de teste, estilo de commit.
```

## Fase 3 — Ramificação

**Projeto NOVO:**

1. `pelizzai-interview-me` — coletar a intenção do usuário (o que ele quer construir).
2. `pelizzai-brainstorming` — transformar a intenção em um design aprovado.
3. `pelizzai-writing-skills` — criar as skills de domínio iniciais e a documentação a partir do design.

**Projeto EXISTENTE ou WORKSPACE:**

1. **Repo-scan completo** — padrões, stacks, frameworks, linguagens, convenções e pontos de extensão.
2. `pelizzai-writing-skills` — criar o **máximo de skills de domínio** úteis a partir dos padrões observados, usando o MCP `context7` para fundamentar cada uma na documentação real das libs/frameworks, conforme as regras de criação de skills da Anthropic.

> A criação, a nomenclatura, o catálogo e o ledger das skills de domínio são responsabilidade da `pelizzai-writing-skills`. O `pelizzai-audit` **orquestra** e garante que essa etapa aconteça.

## Fase 4 — Recomendações ao usuário

Recomende (sem impor; aguarde confirmação para qualquer ação que altere o ambiente):

```text
- Git ausente → sugerir `git init` (o harness atua melhor com histórico).
- Sem remoto → sugerir integração com GitHub ou GitLab.
- MCPs → pesquisar na web os MCPs mais relevantes para a stack identificada e sugerir.
- context7 ausente → sugerir a instalação. É um MCP essencial para o PelizzAI fundamentar
  skills e respostas na documentação real, em vez de adivinhar.
```

## Fase 5 — Documentação do harness

Garanta que o bootstrap deixe dois artefatos (criados/atualizados via `pelizzai-writing-skills`):

- **`pelizzai/domain-skills.md`** — catálogo das skills de domínio: o que cada uma faz e quando usá-la.
- **`pelizzai/data/review-domain-skills.md`** — ledger de manutenção: quando cada skill de domínio foi criada/atualizada e a referência de git correspondente.

A existência de `pelizzai/domain-skills.md` é o sinal de que o harness já foi inicializado neste projeto.

---

## Critério de conclusão

```text
[ ] Alvo classificado (workspace/único, novo/existente).
[ ] Inventário do contexto levantado (stacks, MCPs, git/host, skills, convenções).
[ ] Skills de domínio criadas ou confirmadas como já existentes (via pelizzai-writing-skills).
[ ] Catálogo (domain-skills.md) e ledger (review-domain-skills.md) presentes/atualizados.
[ ] Recomendações apresentadas ao usuário (git, host, MCPs, context7).
```

---

## Anti-padrões

```text
- Pular o bootstrap na primeira interação e começar a trabalhar às cegas.
- Transformar o mapeamento em interrogatório ou em auditoria sem fim.
- Impor mudanças (git init, instalar MCP, criar skills) sem confirmação do usuário.
- Criar skill de domínio com prefixo `pelizzai-` (reservado ao harness).
- Mapear um monorepo como se fosse um projeto único (ou vice-versa).
- Concluir sem deixar o catálogo e o ledger que tornam o mapeamento reaproveitável.
```

---

## Integração

**Combina com:**

- `pelizzai-team` / `pelizzai-subagents` — motor paralelo do mapeamento.
- `pelizzai-interview-me` / `pelizzai-brainstorming` — ramo de projeto novo.
- `pelizzai-writing-skills` — cria as skills de domínio, o catálogo e o ledger.
- `pelizzai-reasoning` — raciocínio do mapeamento (Structured Decomposition, Evidence Synthesis).
