---
name: pelizzai-quick-fix
description: Head skill para ajuste local, coeso, claro e de baixo risco, sem nova superfície pública, regra de negócio ou decisão arquitetural. Use para texto, label, estilo localizado, rename/refactor mecânico ou configuração óbvia quando design/plano não agregam. Tamanho e número de arquivos são sinais, não limites rígidos. Algo quebrado usa `pelizzai-debugging`; se surgir contrato ou decisão, reclassifique pela lane do router.
---

# PelizzAI Quick Fix

## Objetivo

Um caminho enxuto para mudanças triviais. Evita o custo de design + plano quando não há decisão de arquitetura a tomar — **sem** abrir mão de branch isolada, verificação e fechamento.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Quick Fix para este ajuste pontual."

> **Princípio:** trivial ≠ desleixado. Pule o design, não a disciplina.

## Critérios sem contagem rígida

É `quick-fix` quando a mudança:

```text
- objetivo e aceite são inequívocos;
- mudança é local, coesa, reversível e de baixo risco;
- NÃO cria superfície pública, regra de negócio ou decisão de arquitetura;
- prova e rollback são diretos;
- o diff esperado é pequeno o bastante para um review formal não agregar sinal material.
```

Linhas e arquivos ajudam a detectar crescimento, mas não decidem sozinhos. Se surgir contrato com
aceite claro, promova para lane `bounded` e plano compacto; se surgir decisão/incerteza, use
`standard`/`exploratory` e brainstorming proporcional. Algo **quebrado** usa debugging.

## Processo

A `pelizzai-router` calcula as recomendações deste ajuste; esta head skill é o único emissor do
setup. Depois que `pelizzai-starting-branch` ratificou base/nome e criou a branch, pergunte uma
decisão por turno antes da primeira escrita:

1. `Isolamento recomendado: branch — ajuste local. Alternativa: worktree. Qual escolhe?`
2. `Modo recomendado: inline — tarefa curta. Alternativas: subagents · team. Qual escolhe?`
3. `Commits recomendados: granular — checkpoint auditável. Alternativa: squash-final. Qual escolhe?`

Só grave a ratificação após as três respostas. Sob briefing fechado (SUBAGENT-STOP), não abra gates:
aplique o briefing e escale ao coordenador o que exigir decisão.

```text
1. Branch — a pelizzai-starting-branch propõe e ratifica base e `<tipo>/<slug>` antes de criar a
   branch (nunca em branch protegida).
1.5. Regras locais — no consumidor, confira `pelizzai/domain-skills.md`; em source mode, use as
   regras/skills do próprio repo. Siga somente as aplicáveis à área.
1.6. Registrar a ratificação (só após as três respostas) — grave o marcador `kickoff: ratificado <AAAA-MM-DD>`
   (com `isolation`/`execution-mode`/`commit-strategy` ratificados) no state consumidor
   `pelizzai/data/state.md` ou, em source mode, no execution record nativo com a mesma palavra-chave,
   ANTES da primeira escrita de produto. A head skill é o único dono deste marcador no track
   `ajuste`; sem ele o writegate (Regra B) bloqueia a primeira escrita de produto e a retomada não
   reconhece o gate.
2. Mudança + verificação mínima — toda linha alterada deve rastrear diretamente ao pedido
   (linha sem rastro é scope creep: remova ou escale). Escolha o balde honestamente:
   - Comportamento testável (constante, condição, valor retornado): pelizzai-tdd — menor teste que falha primeiro, depois a mudança.
   - Refatoração que preserva comportamento (rename/extract/inline): NÃO fabrique RED — garanta caracterização/suíte verde antes, refatore em passo pequeno e rode a mesma prova depois.
   - Config/IaC/migração: use validate/plan/dry-run e confira compatibilidade/rollback; teste unitário só para lógica separável.
   - UI/CSS/estado visual: aplique obrigatoriamente pelizzai-frontend e use a prova visual
     proporcional definida lá; TDD entra apenas se houver comportamento.
   - Documentação, label ou copy: lint/links/build-render ou inspeção estática proporcional; nada a testar em unidade.
   Não se auto-classifique uma mudança de comportamento como "cosmética"/"config" para pular o teste.
3. Prove a working tree — rode a prova selecionada acima e, quando houver código executável, a
   suíte relevante do projeto. Corrija antes de consolidar.
3.5. Commite o **conteúdo** com paths exatos e mensagem definitiva
   `<tipo>(<escopo>): <descrição>`. Quick-fix já produz um único commit; não crie WIP nem deixe
   squash para a finish-task.
4. Sele e feche — rode `pelizzai-verification-before-completion` contra esse HEAD, grave
   `validated-head` somente após sucesso e invoque `pelizzai-finish-task`: consumidor acrescenta
   apenas o closure de state; source mode fecha o execution record sem arquivo/commit de closure.
```

> O track de ajuste pula review formal somente enquanto permanecer low-risk, coeso e sem nova
> superfície/regra. A prova adequada + Verification cobrem o fechamento. Se o diff revelar risco,
> promova a lane e aplique `pelizzai-review` antes de consolidar.

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

**Usa:** `pelizzai-starting-branch`, regras/skills locais, `pelizzai-reasoning` (seleção da
estratégia), `pelizzai-tdd` somente para comportamento, `pelizzai-frontend` como overlay
obrigatório para UI, `pelizzai-verification-before-completion` e `pelizzai-finish-task`.

**Escala para:** `pelizzai-writing-plans` em bounded, `pelizzai-brainstorming` quando houver decisão
ou incerteza, ou `pelizzai-debugging` quando for bug.
