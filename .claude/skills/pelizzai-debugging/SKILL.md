---
name: pelizzai-debugging
description: Loop de feedback primeiro, red antes do fix. Use ao encontrar qualquer bug, falha de teste ou comportamento inesperado, ANTES de propor correções — correção de sintoma é falha. É o head skill do track de **bug** (roteado pela `pelizzai-router`). Roda inline. Acione quando o usuário disser "não funciona", "tá com bug", "deu erro", "comportamento estranho", "para de chutar", ou quando um teste quebrar durante qualquer outra tarefa.
---

# PelizzAI Debugging

## Objetivo

Fixes aleatórios desperdiçam tempo e criam novos bugs; patches rápidos mascaram o problema real.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Debugging para investigar a causa raiz antes de corrigir."

> **Princípio:** SEMPRE encontre a causa raiz antes de tentar corrigir. Correção de sintoma é falha.

## A Lei de Ferro

```text
NENHUM FIX SEM INVESTIGAÇÃO DA CAUSA RAIZ PRIMEIRO.
```

Se você não completou a Fase 1, não pode propor correções. Use `pelizzai-reasoning` (*Root Cause Analysis*) para conduzir a investigação. O **fix** roda **inline** — nunca paralelize a correção de um bug. Exceção restrita à **investigação** (Fases 1–3): quando ≥3 fixes já falharam ou há hipóteses independentes entre si, um time **read-only** de hipóteses concorrentes (`pelizzai-team`) pode investigar e reportar — a Fase 4 volta sempre para a sessão principal, inline.

**Prefixo único de instrumentação:** gere uma tag única no início da sessão de debugging (ex.: `[DEBUG-a4f2]`) e prefixe com ela TODO log de debug que você adicionar — logs do loop, de fronteira, de hipótese. O cleanup vira um único grep. Log sem tag sobrevive; log com tag morre.

---

## As quatro fases (complete cada uma antes da próxima)

> As fases são um ciclo **OODA** (`pelizzai-loop`): Fase 1 = **Observar** (construir o loop de feedback), Fase 2 = **Orientar** (comparar com o que funciona), Fase 3 = **Decidir** (hipóteses ranqueadas), Fase 4 = **Agir** (teste que falha + fix na origem). Hipótese refutada → volte ao Observar com a informação nova.

### Fase 1 — Observar: construa o loop de feedback PRIMEIRO

Esta fase É a skill; o resto é mecânico. Antes de qualquer teoria, construa o **loop de feedback**: um comando que reproduz o sintoma sob demanda. O critério de saída da fase é um comando **nomeado, JÁ EXECUTADO ao menos uma vez** — cole a invocação e a saída — que seja:

```text
- red-capable: assere o SINTOMA EXATO que o usuário reportou, não "não crashou";
- determinístico: mesmo resultado a cada execução (bug flaky → aumente a TAXA de
  reprodução; ver a seção de não-determinismo do menu de táticas);
- rápido: segundos, não minutos — um loop de 30s flaky mal vale; um de 2s determinístico
  é tight, um superpoder de debugging;
- executável por você (o agente), sem depender de um humano clicar — quando só um humano
  pode operar, use o script HITL do menu.
```

**Sem esse comando, não há Fase 2.** Se você se pegar lendo código para montar teoria antes desse comando existir, PARE e volte a construir o loop. O menu ORDENADO de 10 táticas de construção (failing test → … → script HITL) e o tratamento de bugs não-determinísticos estão em **[references/feedback-loops.md](references/feedback-loops.md)**.

```text
1. Enquanto constrói o loop, colete a evidência barata: leia as mensagens de erro com atenção
   (stack trace inteiro, linhas, arquivos, códigos) — muitas vezes contêm a solução.
2. Cheque mudanças recentes (git diff/log, novas deps, config, ambiente) — um commit recente
   na área é suspeito nº 1.
3. Minimize o loop: corte UM elemento por vez (fixture, flag, passo) re-rodando o loop após
   cada corte. Pronto quando todo elemento restante é load-bearing — remover qualquer um faz
   o bug sumir ou o loop quebrar.
4. Monte o loop com os comandos canônicos do projeto — o perfil `pelizzai/profile.md` tem os
   comandos exatos de test/build/lint; não os chute.
```

### Fase 2 — Orientar: análise de padrão

```text
1. Ache exemplos que funcionam (código similar que funciona no mesmo projeto).
2. Compare com referências (leia a implementação de referência COMPLETA, não por cima).
3. Identifique TODAS as diferenças entre o que funciona e o que quebra (nenhuma é "irrelevante").
4. Em sistemas multi-componente: instrumente cada fronteira com o prefixo da sessão (o que
   entra/sai de cada camada) e rode o loop UMA vez para ver ONDE quebra.
5. Rastreie o fluxo de dados: onde o valor ruim nasce? quem chamou com ele? O fix vai na
   ORIGEM, não no sintoma.
```

### Fase 3 — Decidir: hipóteses ranqueadas e falsificáveis

```text
1. Gere 3–5 hipóteses RANQUEADAS antes de testar a primeira — gerar uma só ancora na
   primeira ideia plausível. Cada hipótese carrega uma predição FALSIFICÁVEL: "se X é a
   causa, mudar Y faz o bug sumir no loop". Sem predição enunciável, é palpite — não entra.
2. Mostre o ranking ao usuário: ele re-ranqueia com conhecimento que você não tem
   ("acabamos de deployar mudança no #3"). Não bloqueie se ele estiver ausente — siga o
   seu ranking e deixe-o registrado.
3. Teste a hipótese nº 1 minimamente: a MENOR mudança possível, UMA variável por vez,
   verificada contra o loop.
4. Predição confirmada → Fase 4. Refutada → próxima hipótese do ranking (não empilhe fixes).
   Ranking esgotado → volte ao Observar com a informação nova.
5. Não sabe? Diga "não entendo X" — não finja, pesquise (context7 quando a suspeita é lib externa).
```

### Fase 4 — Agir: implementação

**Antes de tocar no código:** confirme que NÃO está em branch protegida — invoque `pelizzai-starting-branch` (branch) antes de escrever o teste ou o fix. (As Fases 1-3 podem instrumentar e experimentar de forma **temporária e descartável** — logs de fronteira, a menor mudança de hipótese —, mas **reverta tudo antes da Fase 4**: nenhuma mudança que vá ser COMMITADA acontece antes do gate, e uma working tree suja quebra o `git pull --ff-only` da starting-branch. Stash/descarte a instrumentação antes de criar a branch.) Leia também `pelizzai/domain-skills.md` e aplique as skills de domínio da área afetada ao escrever o teste e o fix — o fix segue as convenções do projeto, não padrões genéricos.

```text
1. Crie o teste que FALHA (via pelizzai-tdd), num seam que exercite o padrão REAL do bug —
   o loop da Fase 1 costuma apontar o seam. OBRIGATÓRIO antes de corrigir. Se o seam correto
   NÃO EXISTE, isso é um ACHADO ARQUITETURAL: registre-o e aponte para a
   pelizzai-improving-architecture — não contorça a arquitetura dentro do fix nem escreva
   um teste tautológico num seam errado.
2. Implemente UM fix (a causa raiz; uma mudança; sem "já que estou aqui").
3. Verifique: o teste passa? nenhum outro quebrou? Confirme com pelizzai-verification-before-completion.
   → rode o POST-MORTEM (abaixo), encadeie pelizzai-review (revise o diff da working tree,
     trate Critical/Important) e então pelizzai-finish-task para consolidar e integrar —
     não deixe o bug corrigido parado na branch.
4. Se o fix não funcionar: PARE. Conte os fixes tentados. < 3 → volte à Fase 1 com a info nova.
   ≥ 3 → PARE e questione a arquitetura: acione `pelizzai-interview-me` para estressar a hipótese/arquitetura
   com o usuário; se revelar problema estrutural/de design, escale para `pelizzai-brainstorming` (track feature).
   Não tente o fix nº 4 sem essa discussão.
```

---

## Post-mortem (obrigatório antes de fechar)

Com o fix verificado e ANTES da `pelizzai-finish-task`, feche a sessão de debugging — todos os itens:

```text
[ ] Repro original re-rodada uma última vez (o loop da Fase 1, agora verde).
[ ] grep do prefixo de debug ([DEBUG-…]) = ZERO ocorrências no código.
[ ] Protótipos e harnesses descartáveis deletados.
[ ] Hipótese vencedora registrada na MENSAGEM DE COMMIT do fix — o próximo debugger aprende.
[ ] "O que teria prevenido este bug?" respondida AGORA, depois do fix — você tem informação
    que não tinha no início. A resposta é uma recomendação arquitetural (seam ausente →
    pelizzai-improving-architecture; validação na fronteira errada; teste que faltava), não culpa.
```

---

## Sinais do parceiro humano

Frases do usuário que carregam diagnóstico — decodifique e aja, não argumente:

| Sinal                          | Diagnóstico                                   | Ação                                                    |
| ------------------------------ | --------------------------------------------- | ------------------------------------------------------- |
| "Isso não está acontecendo?"   | você assumiu algo sem verificar               | verifique AGORA, com o loop                              |
| "Para de chutar"               | suas hipóteses não têm predição falsificável  | volte à Fase 1/loop e re-derive o ranking                |
| "A gente tá travado?"          | thrashing — fixes empilhados sem avanço       | PARE; resuma o que sabe, o que falta e o próximo passo   |
| "Já tentamos isso"             | você perdeu o fio do que foi testado          | releia o ranking e os resultados antes de repetir        |

---

## Red flags — PARE e siga o processo

```text
- Ler código para montar teoria ANTES de o comando do loop existir.
- "Fix rápido por ora, investigo depois" / "Só muda X e vê se funciona".
- Testar a primeira hipótese plausível sem gerar as 3–5 ranqueadas.
- "Adiciona várias mudanças, roda os testes" / "Pula o teste, valido manual".
- "Provavelmente é X, deixa eu corrigir" (sintoma ≠ causa raiz).
- Log de debug sem o prefixo único da sessão.
- "Mais uma tentativa de fix" (com 2+ já tentadas) → 3+ falhas = problema de arquitetura.
- Cada fix revela um novo problema em outro lugar.
```

Racionalizações comuns ("é simples, não precisa de processo"; "emergência, sem tempo"; "escrevo o teste depois") são todas falsas: debugging sistemático é MAIS rápido que chutar; o primeiro fix define o padrão; teste antes prova que pega.

---

## Integração

**Roteada por:** `pelizzai-router` (track `bug`), que já traz o contexto e a isolação decididos.

**Usa:** `pelizzai-reasoning` (Root Cause Analysis; as fases seguem o OODA de `pelizzai-loop`), o menu de loops de **[references/feedback-loops.md](references/feedback-loops.md)** (Fase 1), as **skills de domínio** do projeto (`pelizzai/domain-skills.md` — a área afetada), `pelizzai-team` (investigação com hipóteses concorrentes, read-only, só quando ≥3 fixes falharam ou hipóteses independentes — nunca o fix), `pelizzai-starting-branch` (branch antes da Fase 4), `pelizzai-tdd` (teste que falha), `pelizzai-verification-before-completion` (confirmar o fix), `pelizzai-review` (revisar o fix), `pelizzai-finish-task` (fecha o ciclo — sempre DEPOIS do post-mortem). Seam ausente para o teste de regressão é achado arquitetural → `pelizzai-improving-architecture` (vocabulário de seams: `pelizzai-codebase-design`). Para causa raiz em lib externa, fundamente no `context7`.
