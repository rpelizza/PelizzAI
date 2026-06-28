---
name: pelizzai-review
description: Skill de code review do harness PelizzAI. Use após completar uma tarefa, ao implementar uma feature relevante, ou antes de mergear. Faz review em DOIS estágios — conformidade com a spec, depois qualidade do código com EVIDÊNCIA fresca de teste (rodada, não inferida) — por tarefa, e o review final da branch inteira. Despacha um reviewer (subagente) com contexto fabricado, NUNCA o histórico da sessão. Também orienta como RECEBER feedback de review com rigor técnico (sem concordância performática). Acione quando o usuário disser "revisar o código", "code review", "está pronto para mergear?". Para segurança/OWASP, use `pelizzai-oswap`.
---

# PelizzAI Review

## Objetivo

Pegar problemas antes que eles se propaguem. O reviewer recebe **contexto fabricado** — descrição, requisitos/plano e o diff — **nunca o histórico da sua sessão**. Isso mantém o reviewer focado no produto, não no seu raciocínio, e preserva o seu contexto para continuar.

**Anuncie ao iniciar:** "Usando a skill Pelizzai Review para revisar o código."

---

## Princípio central

> Revise cedo e sempre. Um review é uma verificação independente do produto: leia o código de fato, não confie no relatório de quem implementou, e dê um veredito claro com evidência — nunca um "parece bom".

---

## Quando revisar

```text
Obrigatório:
- Após CADA tarefa na execução de um plano (pelizzai-execution-plans).
- Ao concluir uma feature relevante.
- Antes de mergear para a base.

Opcional, mas valioso:
- Quando travado (perspectiva nova).
- Antes de uma refatoração (baseline).
- Depois de corrigir um bug complexo.
```

---

## Os dois estágios (review por tarefa)

Na execução de um plano, cada tarefa passa por dois estágios, **nesta ordem**. O implementador **não commitou** — o código está na working tree (o review é o gate).

### Estágio 1 — Conformidade com a spec

Verifique que o implementador construiu **exatamente** o que foi pedido — nada a mais, nada a menos. **Não confie no relatório**; leia o código.

```text
- Faltando: implementou tudo o que foi pedido? Pulou ou esqueceu algum requisito?
  Alegou que algo funciona mas não implementou?
- Extra/desnecessário: construiu o que não foi pedido? Super-engenharia? "Nice to haves" fora da spec?
- Mal-entendidos: interpretou diferente do pretendido? Resolveu o problema errado? Certo, mas do jeito errado?
```

Use o template **[references/spec-reviewer.md](references/spec-reviewer.md)** (sem rodar testes — Verification é do Estágio 2). Resultado: **✅ Conforme a spec** (tudo bate após inspeção do código), **❌ Problemas** (liste o que falta/sobra, com `arquivo:linha`), ou **⚠️ Não verificável** → exige avaliação do coordenador contra o plano antes de concluir (ver `pelizzai-execution-plans` → `references/task-cycle.md` §3-§4).

### Estágio 2 — Qualidade do código

**Só despache após o Estágio 1 passar.** Use a rubrica completa em **[references/code-reviewer.md](references/code-reviewer.md)**. Avalie: separação de responsabilidades, tratamento de erro, segurança de tipos, DRY sem abstração prematura, edge cases, arquitetura, segurança, testes (verificam comportamento real, não mocks), prontidão para produção. Além disso:

```text
- Cada arquivo tem UMA responsabilidade clara e interface bem definida?
- As unidades são decompostas para serem entendidas e testadas de forma independente?
- A implementação segue a estrutura de arquivos do plano?
- Esta mudança criou arquivos já grandes, ou inchou demais arquivos existentes?
  (Não aponte tamanho pré-existente — foque no que ESTA mudança contribuiu.)
- Julgue a mudança também contra as SKILLS DE DOMÍNIO do projeto (pelizzai/domain-skills.md).
```

---

## Evidência fresca (bloco Verification, obrigatório)

O reviewer de qualidade **roda de fato** os comandos de teste/lint/build do projeto e **cola a saída + exit code** num bloco `### Verification`. **Não infira** passa/falha lendo o diff. Qualquer check que não pôde rodar é **UNVERIFIED — nunca ✅** — e diga quais comandos rodaram.

---

## Como despachar o reviewer

Despache um subagente (`pelizzai-subagents`) ou, se indisponível, faça inline. O **Estágio 1** usa **[references/spec-reviewer.md](references/spec-reviewer.md)**; o **Estágio 2** e o **review final** usam **[references/code-reviewer.md](references/code-reviewer.md)**. Preencha com:

```text
- Descrição: o que foi construído.
- Requisitos/Plano: o que deveria fazer (texto da tarefa ou caminho do plano em pelizzai/plans/).
- Diff a revisar:
  - Por tarefa (estágio de qualidade) → escopo B do template: working tree NÃO commitada —
    `git diff`, `git diff --staged` e arquivos novos via `git status` (não há commit da tarefa ainda).
  - Review final → escopo A do template: range commitado — `git diff <BASE_SHA>..<HEAD_SHA>`.
- Skills de domínio relevantes (coladas) — o reviewer julga a mudança contra elas.
```

O reviewer **nunca** recebe o histórico da sessão.

---

## Severidade e formato de saída

O reviewer devolve, nesta estrutura (detalhe em `references/code-reviewer.md`):

```text
### Strengths        — o que está bem feito (específico; elogio preciso gera confiança no resto)
### Issues
  #### Critical      — bugs, segurança, perda de dados, funcionalidade quebrada (corrigir já)
  #### Important     — arquitetura, feature faltando, erro mal tratado, lacuna de teste (corrigir antes de seguir)
  #### Minor         — estilo, otimização, polimento de doc (anotar para depois)
  (cada issue: arquivo:linha, o que está errado, por que importa, como corrigir)
### Recommendations
### Verification     — comandos RODADOS (test/lint/build) + saída + exit code; o que não rodou = UNVERIFIED
### Assessment       — Pronto para mergear? [Sim | Não | Com correções] + 1-2 frases de justificativa
```

Categorize pela severidade REAL — nem tudo é Critical; um nitpick não é Critical.

---

## Review final da branch

Ao concluir todas as tarefas, revise a **branch inteira** (range commitado `<BASE>..<HEAD>`), não só por tarefa, com o **modelo mais capaz** disponível. É a última rede antes da conclusão (`pelizzai-verification-before-completion` / `pelizzai-finish-task`).

---

## Agir sobre o feedback

```text
- Critical → corrija imediatamente.
- Important → corrija antes de prosseguir.
- Minor → anote para o review final.
- Reviewer errado → faça push back com raciocínio técnico (mostre código/testes que provam).
```

Isso alimenta o circuit breaker da `pelizzai-execution-plans` (3 ciclos por estágio, por tarefa; detalhe e resets em `pelizzai-execution-plans` → `references/task-cycle.md` §5). **Handback de branch protegida:** se agir sobre o feedback significa escrever código e não há isolamento registrado em `pelizzai/data/state.md`, passe por `pelizzai-starting-branch` antes — para os fixes não caírem em branch protegida.

---

## Receber feedback de review (rigor técnico, não performance)

```text
Padrão de resposta: LER → ENTENDER (reformule o requisito ou pergunte) → VERIFICAR contra o código →
AVALIAR (é tecnicamente correto para ESTE projeto?) → RESPONDER (reconhecimento técnico ou push back
fundamentado) → IMPLEMENTAR um item de cada vez, testando cada um.

NUNCA: "você está certíssimo", "ótimo ponto", "ótimo feedback", nem agradecer — ações falam.
       Não implemente antes de verificar. Não implemente parcialmente quando há itens não entendidos
       (peça esclarecimento de TODOS primeiro — itens podem estar relacionados).
QUANDO acertar: "Corrigido. [o que mudou]" — e o código mostra que você ouviu.
YAGNI: se o reviewer sugere "implementar direito", faça grep do uso real; se não é usado, proponha remover.
Push back quando: quebra algo existente, reviewer sem contexto completo, viola YAGNI, incorreto para a stack,
       ou conflita com decisão de arquitetura do usuário — com raciocínio técnico, não defensividade.
Não consegue verificar? Diga: "Não consigo verificar isto sem [X] — investigo / pergunto / sigo?"
       (nunca implemente às cegas).
Em PR no GitHub, responda no THREAD do comentário inline (não como comentário top-level do PR).
```

---

## Anti-padrões / red flags

```text
- Pular o review porque "é simples".
- Ignorar Critical, ou seguir com Important em aberto.
- Dar feedback sobre código que não leu de fato.
- Marcar nitpick como Critical, ou ser vago ("melhorar o tratamento de erro").
- Relatar como ✅ um check que não rodou (evidência inferida do diff).
- Passar o histórico da sessão ao reviewer (ele recebe só o contexto fabricado).
- Concordância performática ao receber feedback ("você está certíssimo", agradecer).
- Despachar o estágio de qualidade antes do estágio de spec passar.
```

---

## Integração

**Combina com:**

- `pelizzai-execution-plans` — review por tarefa (dois estágios) e review final; ver `task-cycle.md` na `pelizzai-execution-plans`.
- `pelizzai-tdd` — os testes que o review confere nascem do ciclo TDD.
- `pelizzai-starting-branch` — handback quando agir sobre feedback vira escrever código.
- `pelizzai-reasoning` — *Critique and Refine* (agir sobre o feedback) e *Verification* (evidência fresca).
- `pelizzai-oswap` — dimensão de segurança (OWASP) do review.
- `pelizzai-verification-before-completion` / `pelizzai-finish-task` — conclusão após o review final.

---

## Instrução final para o agente

```text
Revise o produto, não o raciocínio. Leia o código; não confie no relatório.

Prefira:
- evidência fresca (comandos rodados) a "parece que passa";
- veredito claro (Sim/Não/Com correções) a "looks good";
- severidade real a marcar tudo como Critical;
- rigor técnico a concordância performática ao receber feedback.

Spec primeiro, qualidade depois. Critical/Important antes de seguir; Minor para o final.
Nunca passe o histórico da sessão ao reviewer. Para segurança, use pelizzai-oswap.
```
