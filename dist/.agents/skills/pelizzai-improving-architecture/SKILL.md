---
name: pelizzai-improving-architecture
description: Head skill read-only para revisão PROATIVA codebase-wide de arquitetura, dívida técnica e seams ausentes. Use periodicamente (a cada poucos dias de trabalho intenso no projeto), quando o usuário pedir análise arquitetural ampla ou o que vale refatorar, e quando debugging registrar uma lacuna estrutural. Entrega candidatos priorizados por evidência; não edita código, relatório, ADR ou out-of-scope. Review de diff/branch/PR usa pelizzai-review.
---

# PelizzAI Improving Architecture

## Objetivo

Encontrar onde a arquitetura está cobrando custo **observável** e devolver poucas oportunidades
acionáveis, sem transformar preferência estética em refactor nem uma análise read-only em escrita.

**Anuncie:** "Usando a skill PelizzAI Improving Architecture para revisar a arquitetura por evidência."

## Contrato de efeito

O modo padrão é `read-only`:

```text
- não cria branch, state, HTML, ADR, spec, out-of-scope ou qualquer arquivo;
- entrega o relatório no chat/recurso nativo da plataforma;
- não corrige os candidatos encontrados;
- só executa checks focalizados quando eles discriminam uma hipótese arquitetural.
```

Se o usuário pedir um artefato persistente ou escolher implementar um candidato, volte ao router,
reclassifique para `write-local` e passe por `pelizzai-starting-branch` **antes** da primeira escrita.
Consumidor usa os paths do harness; source mode usa paths nativos do repo e nunca cria `pelizzai/`.

## Escopo

Arquitetura degrada em silêncio: cada tarefa olha o próprio diff e ninguém olha o todo. Por isso o
gatilho não é só o pedido do usuário — é também a **cadência**: a cada poucos dias de trabalho
intenso no projeto, o harness oferece esta revisão. Oferecer é proativo; rodar e implementar
continuam sendo escolha do usuário.

Use para:

- revisão periódica ampla de arquitetura/dívida/seams;
- fricção recorrente sustentada por bugs, mudanças ou navegação reais;
- seam ausente que impediu uma regressão útil.

Não use para:

- bug ativo (`pelizzai-debugging`);
- review de diff, working tree, branch ou PR (`pelizzai-review`);
- implementar um refactor já decidido (lane/plano do router);
- interromper uma tarefa em andamento: a oferta periódica espera a tarefa fechar.

## Processo adaptativo

### 1. Fixe a pergunta

Derive o escopo do pedido e da evidência existente. Pergunte somente quando duas fronteiras
plausíveis mudarem materialmente o resultado. Não transforme "repo inteiro" em formulário.

### 2. Colete fricção, não smells por checklist

Inspecione o mínimo capaz de testar sinais reais:

```text
- mudanças semelhantes espalhadas por muitos lugares;
- bugs/fixes recorrentes na mesma fronteira;
- seam ausente ou teste que precisa conhecer implementação demais;
- módulo pass-through cujo custo reaparece nos callers;
- contrato largo para uso estreito;
- conceito que exige saltos excessivos entre módulos;
- dependência/ciclo que aumenta blast radius.
```

Use histórico, testes, imports/callers e ADRs quando ajudarem. Subagentes read-only só quando houver
frentes independentes. Ausência de métrica perfeita não autoriza inventar frequência ou impacto.

### 3. Teste cada hipótese

Para cada candidato material:

1. descreva a fricção observada;
2. aplique o teste da deleção: sem essa camada, a complexidade some ou apenas migra?;
3. encontre contraexemplo/prior art que possa refutar a hipótese;
4. verifique ADR/constraint que explique o desenho atual;
5. estime alcance, reversibilidade e risco de migração.

Use `pelizzai-codebase-design` como vocabulário/lente, não como segunda head skill. Reasoning útil:
Evidence Synthesis para sinais dispersos, Assumption Tracking para lacunas e Decision Making para
priorização. Não force OODA sem rodadas reais nem TDD numa análise.

### 4. Priorize com honestidade

Classifique cada candidato:

| Classe | Evidência |
| --- | --- |
| Forte | fricção recorrente + mecanismo causal + direção plausível |
| Vale explorar | sinal real, mas benefício ou desenho ainda precisa discovery |
| Especulativo | hipótese útil sem evidência suficiente; não recomendar implementação |

Prefira 1–5 candidatos. Se nada justificar mudança, diga isso; "nenhuma refatoração recomendada"
é uma conclusão válida.

### 5. Entregue o relatório

Para cada candidato, informe:

```text
evidência: arquivos/linhas, histórico ou teste relevante
fricção: custo concreto hoje
mecanismo: por que a estrutura produz esse custo
direção: mudança de fronteira, sem inventar a interface final
ganho esperado e trade-offs
confiança: Forte | Vale explorar | Especulativo
próxima prova mais barata
```

Inclua também "manter como está" quando for alternativa racional. Visualização só quando relações
entre módulos ficarem materialmente mais claras; use recurso inline/nativo no modo read-only.

## Depois da escolha

Ao fim da análise, sem sair do modo read-only, ofereça registrar o que for durável — propor-confirmar,
nunca escrita por reflexo:

- Candidato escolhido: router decide `bounded | standard | exploratory`; arquitetura aberta
  normalmente passa por brainstorming, mas refactor claro pode ir direto ao plano.
- Decisão arquitetural durável que valha memória (adotar uma nova fronteira, ou manter a atual por um
  trade-off real): **ofereça** registrar um ADR via `pelizzai-domain-modeling`. A gravação só ocorre
  depois de reclassificar para `write-local` e passar pela primeira-write gate; o relatório em si não
  escreve.
- Rejeição com razão durável: **ofereça** registrar em ADR/out-of-scope; não escreva automaticamente.
- Seam ausente: entregue a evidência ao fluxo de design, sem fabricar teste tautológico.

## Red flags

```text
- Criar relatório/ADR/out-of-scope durante análise read-only.
- Confundir review arquitetural amplo com code review de diff.
- Recomendar refactor só por tamanho, estilo ou "clean code".
- Inventar interface definitiva antes do design.
- Ignorar ADR/constraint que explica o trade-off atual.
- Reescrever o mundo em vez de priorizar poucos candidatos.
- Forçar subagentes, visual ou checks sem ganho de sinal.
```

## Definition of Done

```text
[ ] cada recomendação aponta para evidência verificável;
[ ] hipótese, fato e inferência estão separados;
[ ] trade-offs e alternativa de não agir foram considerados;
[ ] nenhum estado foi alterado no modo read-only;
[ ] próxima rota está clara sem iniciar implementação implicitamente.
```
