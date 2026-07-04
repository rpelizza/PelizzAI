---
name: pelizzai-improving-architecture
description: Fricção como bússola — revisão PROATIVA de arquitetura. Use periodicamente (a cada poucos dias de trabalho intenso no projeto), quando a `pelizzai-debugging` registrar um seam ausente para o teste de regressão, ou quando o usuário pedir "revisar a arquitetura", "o que vale refatorar?", "dívida técnica". NÃO é para reagir a um bug (isso é o track de bug) nem para reescrever o mundo.
---

# PelizzAI Improving Architecture

## Objetivo

Arquitetura degrada em silêncio: cada tarefa olha o próprio diff e ninguém olha o todo. Esta skill faz a revisão proativa — encontrar, com evidência de fricção real, os pontos onde a arquitetura está cobrando pedágio, e apresentá-los ao usuário como **candidatos**, não como refactors já decididos.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Improving Architecture para revisar a arquitetura proativamente."

## Quando (e quando não)

```text
USE:     periodicamente (a cada poucos dias de trabalho intenso); quando a pelizzai-debugging
         registrou um SEAM AUSENTE (não havia onde escrever o teste de regressão); quando o
         usuário pedir uma revisão de arquitetura.
NÃO USE: para reagir a um bug (track de bug → pelizzai-debugging); para reescrever o mundo
         (o resultado é um MENU de candidatos, nunca um plano de refactor total); no meio de
         uma tarefa em andamento (feche-a primeiro).
```

## Processo

### 1. Explorar organicamente (read-only)

Despache um subagente ou time **read-only** (`pelizzai-team`/`pelizzai-subagents`, agentes de leitura) com um briefing de fricção, não de checklist:

```text
- Não siga heurísticas rígidas: anote onde VOCÊ sentiu fricção lendo o código.
- Sinais que valem anotar: pular entre muitos módulos pequenos para entender UM conceito;
  funções puras extraídas "por testabilidade" cujos bugs reais moram em quem as chama
  (a lógica perdeu localidade); interfaces mais largas que o uso real.
- Aplique o teste da deleção (pelizzai-codebase-design): apague o módulo mentalmente —
  a complexidade some (pass-through) ou reaparece nos callers (ele pagava o próprio custo)?
- Colete os achados já registrados: seams ausentes flagrados pela pelizzai-debugging.
```

### 2. Relatório visual EFÊMERO

Monte um HTML self-contained em **`pelizzai/data/reports/`** (gitignored — nunca versionado) e abra-o no navegador. Um card por candidato:

```text
- Arquivos:  os caminhos envolvidos.
- Problema:  1 frase.
- Solução:   1 frase (direção, não interface — ver red flags).
- Ganhos:    bullets de ≤6 palavras usando SÓ o vocabulário do glossário (pelizzai/context.md)
             e da pelizzai-codebase-design (profundidade, localidade, alavancagem, seam…).
             "Mais fácil de manter" não está no glossário — não entra.
- Diagrama:  before/after (caixas e setas bastam).
- Badge:     Forte / Vale explorar / Especulativo.
- Conflito com ADR: callout explícito quando houver ("contradiz ADR-0007 — mas vale reabrir
  porque…"). Só liste candidatos que valham reabrir a decisão; não liste todo refactor
  teórico que um ADR proíbe.
```

### 3. O usuário escolhe

Apresente o relatório e deixe o usuário escolher **um** candidato. O escolhido entra no fluxo normal do harness — `pelizzai-brainstorming` + plano para refactor arquitetural, ou track de ajuste, conforme o porte. Esta skill **não propõe interfaces** no relatório: a interface nasce no design, com o processo inteiro.

### 4. Rejeição vira registro

Candidato rejeitado com razão durável → registre **automaticamente** em ADR (se passar no critério triplo da `pelizzai-domain-modeling`) ou em `pelizzai/out-of-scope/`, e anuncie em 1 linha — para a próxima revisão não re-sugerir.

## Red flags

```text
- Propor interfaces dentro do relatório (a interface nasce no design, não no menu).
- Escrever o relatório fora de pelizzai/data/reports/ ou versioná-lo (é EFÊMERO: gitignored, aberto no navegador).
- Ganhos fora do vocabulário do glossário/codebase-design ("mais limpo", "mais fácil de manter").
- Ignorar ADRs — todo conflito com ADR ganha callout explícito.
- Re-sugerir candidato já rejeitado com razão registrada (cheque adr/ e out-of-scope/ antes).
- "Já ir refatorando" candidatos direto do relatório — UM candidato escolhido, fluxo normal.
```

## Integração

**Acionada por:** cadência do usuário (revisão periódica) e `pelizzai-debugging` (seam ausente é achado arquitetural).

**Usa:** `pelizzai-codebase-design` (vocabulário: profundidade, localidade, seam, teste da deleção), `pelizzai-domain-modeling` (glossário; ADR e `pelizzai/out-of-scope/` para rejeições), `pelizzai-team`/`pelizzai-subagents` (exploração read-only), `pelizzai-brainstorming` (o candidato escolhido entra pelo fluxo de design).

> Baseline desta skill: prática testada em campo em harness de referência (benchmark 2026-07-04); cenário de regressão em `test-pressure-1.md`.
