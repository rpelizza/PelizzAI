---
name: pelizzai-quick-fix
description: Head skill para ajuste local, coeso, claro e de baixo risco — texto, label, cor, botão ou campo em tela existente, constante, rename/refactor mecânico, configuração óbvia. Sinais típicos: ~1 arquivo e menos de ~50 linhas (sinais de escala, não limites rígidos). Superfície pública = rota, comando, endpoint, API ou config NOVA — ajuste não cria nenhuma delas nem muda regra de negócio. Algo quebrado usa `pelizzai-debugging`; nova superfície/contrato ou decisão de design reclassifica pela lane do router.
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
- NÃO cria superfície pública — rota, comando, endpoint, API ou config nova — nem muda regra de
  negócio ou decide arquitetura (botão, campo ou label numa tela existente NÃO é superfície
  pública: é ajuste);
- prova e rollback são diretos;
- o diff esperado é pequeno o bastante para um review formal não agregar sinal material
  (~1 arquivo e <~50 linhas são os sinais típicos de escala, não limites rígidos).
```

Linhas e arquivos ajudam a detectar crescimento, mas não decidem sozinhos. Aceite claro é critério
de ENTRADA do quick-fix, nunca motivo de promoção. Promova somente quando surgir coisa nova: NOVA
superfície pública/contrato com aceite claro → lane `bounded` e plano compacto; decisão real de
design ou incerteza → `standard`/`exploratory` e brainstorming proporcional. Na dúvida entre ajuste
e bounded, recomende `ajuste` no kickoff — promover depois é barato; um plano para trocar um botão
não é. Algo **quebrado** usa debugging.

## Processo

A `pelizzai-router` calcula as recomendações deste ajuste; esta head skill é o único emissor do
setup. Ajuste usa o **confirm compacto de uma linha** — não o menu de perguntas do gate pós-plano.
A `pelizzai-starting-branch` descobre a base e propõe o nome SEM parada própria (base sem candidato
inequívoco ainda para lá); a head skill apresenta tudo numa linha, com as decisões visíveis e
nomeadas, e aguarda:

`Kickoff: quick-fix na branch <tipo>/<slug> @ <base-ref> (<sha-curto>) — isolamento: branch · modo: inline · commits: granular. Ok? (overrides: worktree · subagents/team · squash-final · outro nome/base)`

Um "ok" ratifica base, nome e as três decisões de uma vez — todas estão nomeadas na linha, nada foi
silencioso; um override nomeado ajusta só aquele item e mantém os demais. Só então a branch é
criada. Não pulverize esta linha em perguntas separadas: o menu uma-decisão-por-turno pertence ao
gate pós-plano dos tracks com plano. Sob briefing fechado (SUBAGENT-STOP), não abra gates: aplique
o briefing e escale ao coordenador o que exigir decisão.

```text
1. Branch — a pelizzai-starting-branch descobre a base e propõe `<tipo>/<slug>`; a ratificação
   acontece no confirm compacto acima e só depois dele a branch é criada (nunca em branch protegida).
1.5. Regras locais — no consumidor, confira `pelizzai/domain-skills.md`; em source mode, use as
   regras/skills do próprio repo. Siga somente as aplicáveis à área.
1.6. Registrar a ratificação (após o "ok" do confirm compacto) — grave o marcador `kickoff: ratificado <AAAA-MM-DD>`
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
   apenas o closure de metadata (state + history da tarefa);
   source mode fecha o execution record sem arquivo/commit de closure.
```

> O track de ajuste pula review formal somente enquanto permanecer low-risk, coeso e sem nova
> superfície/regra. A prova adequada + Verification cobrem o fechamento. Se o diff revelar risco,
> promova a lane e aplique `pelizzai-review` antes de consolidar.

---

## Red flags

```text
Nunca: tratar como quick-fix algo que cria nova superfície ou muda regra de negócio; promover a
       bounded/plano só porque o aceite é claro (aceite claro é critério de entrada, não gatilho de
       promoção); pulverizar o confirm compacto em perguntas separadas; pular a branch isolada
       ("é só um textinho" — o gate de branch protegida vale igual); pular a verificação;
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
