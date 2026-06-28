---
name: pelizzai-quick-fix
description: Use para ajustes pequenos e triviais (texto, label, cor, constante, correção óbvia) — no máximo ~1 arquivo, menos de ~50 linhas, sem nova superfície pública e sem nova regra de negócio. É o head skill do track de **ajuste** (roteado pela `pelizzai-router`): pula brainstorming e writing-plans, mas mantém branch isolada, teste mínimo e fechamento limpo. Acione quando o usuário pedir uma mudança pontual e óbvia. Se for algo QUEBRADO, use `pelizzai-debugging`; se crescer, escale para `pelizzai-brainstorming`.
---

# PelizzAI Quick Fix

## Objetivo

Um caminho enxuto para mudanças triviais. Evita o custo de design + plano quando não há decisão de arquitetura a tomar — **sem** abrir mão de branch isolada, verificação e fechamento.

**Anuncie ao iniciar:** "Usando a skill Pelizzai Quick Fix para este ajuste pontual."

> **Princípio:** trivial ≠ desleixado. Pule o design, não a disciplina.

## Critérios (precisa de TODOS)

É `quick-fix` quando a mudança:

```text
- toca ~1 arquivo (no máximo alguns, fortemente relacionados);
- tem menos de ~50 linhas;
- NÃO cria nova superfície pública (rota, comando, endpoint, API, nova config);
- NÃO muda comportamento/regra de negócio;
- não exige decisão de arquitetura.
```

Se QUALQUER critério for excedido — na avaliação ou no meio do trabalho — **escale para `feature`** (`pelizzai-brainstorming` → `pelizzai-writing-plans`). Se for algo **quebrado** (erro, comportamento errado), use `pelizzai-debugging`, não esta skill.

## Processo

A `pelizzai-router` já preparou o contexto de um `ajuste`: `isolation: branch` (avisa "vou trabalhar numa branch" — nunca worktree, e o harness é branches-only), `execution-mode` (normalmente `inline`) e `commit-strategy`. Honre — não re-pergunte.

```text
1. Branch — invoque pelizzai-starting-branch (nunca em branch protegida).
2. Mudança + verificação mínima — escolha o balde honestamente:
   - Comportamento testável (constante, condição, valor retornado): pelizzai-tdd — menor teste que falha primeiro, depois a mudança.
   - Refatoração que preserva comportamento (rename/extract/inline): NÃO escreva teste novo — garanta cobertura verde antes (characterization tests), depois refatore no verde.
   - Config/IaC (comportamental mas não testável em unidade): valide por apply/dry-run/validate da ferramenta e registre via pelizzai-verification-before-completion.
   - Puramente cosmético, sem comportamento (cor, label, copy): nada a testar em unidade — valide com a checagem manual registrada via pelizzai-verification-before-completion.
   Não se auto-classifique uma mudança de comportamento como "cosmética"/"config" para pular o teste.
3. Verifique — rode o comando de teste do projeto e confirme verde (pelizzai-verification-before-completion antes de dizer "pronto").
4. Feche — invoque pelizzai-finish-task (honra a commit-strategy registrada).
```

> O track de ajuste **pula o code-review formal** por ser trivial (<~50 linhas, sem nova superfície/regra); a verificação mínima + `pelizzai-finish-task` cobrem o fechamento. Se a mudança crescer e exigir review, ela já deixou de ser ajuste — escale para feature.

---

## Red flags

```text
Nunca: tratar como quick-fix algo que cria nova superfície ou muda regra de negócio; pular a branch
       isolada ("é só um textinho" — o gate de branch protegida vale igual); pular a verificação;
       insistir no caminho leve depois que a mudança cresceu (escale para feature).
```

---

## Integração

**Roteada por:** `pelizzai-router` (track `ajuste`).

**Usa:** `pelizzai-starting-branch`, `pelizzai-tdd` (TDD completo quando há comportamento testável; mudança só cosmética não tem o que testar em unidade), `pelizzai-verification-before-completion`, `pelizzai-finish-task`.

**Escala para:** `pelizzai-brainstorming` (se virar feature) ou `pelizzai-debugging` (se for um bug).
