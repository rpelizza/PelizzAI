---
name: pelizzai-debugging
description: Use ao encontrar qualquer bug, falha de teste ou comportamento inesperado, ANTES de propor correções. Exige investigar a causa raiz antes de qualquer fix — correção de sintoma é falha. Conduz uma investigação disciplinada em quatro fases (causa raiz → padrão → hipótese → implementação), escreve um teste que falha reproduzindo o bug, corrige a raiz e fecha o ciclo com review e `pelizzai-finish-task`. É o head skill do track de **bug** (roteado pela `pelizzai-router`). Roda inline. Acione quando o usuário disser "não funciona", "tá com bug", "deu erro", "comportamento estranho".
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

---

## As quatro fases (complete cada uma antes da próxima)

> As fases são um ciclo **OODA** (`pelizzai-loop`): Fase 1 = **Observar** (reproduzir, coletar evidência), Fase 2 = **Orientar** (comparar com o que funciona), Fase 3 = **Decidir** (uma hipótese testável), Fase 4 = **Agir** (teste que falha + fix na origem). Hipótese refutada → volte ao Observar com a informação nova.

### Fase 1 — Investigação da causa raiz

```text
1. Leia as mensagens de erro com atenção (stack trace inteiro, linhas, arquivos, códigos) — muitas vezes contêm a solução.
2. Reproduza de forma consistente (passos exatos; acontece sempre?). Sem reprodução → junte mais dados, não chute.
3. Cheque mudanças recentes (git diff/log, novas deps, config, ambiente) — um commit recente na área é suspeito nº 1.
4. Em sistemas multi-componente: instrumente cada fronteira (o que entra/sai de cada camada) e rode UMA vez para ver ONDE quebra, antes de propor fix.
5. Rastreie o fluxo de dados: onde o valor ruim nasce? quem chamou com ele? Corrija na ORIGEM, não no sintoma.
```

### Fase 2 — Análise de padrão

```text
1. Ache exemplos que funcionam (código similar que funciona no mesmo projeto).
2. Compare com referências (leia a implementação de referência COMPLETA, não por cima).
3. Identifique TODAS as diferenças entre o que funciona e o que quebra (nenhuma é "irrelevante").
4. Entenda as dependências (componentes, config, ambiente, premissas).
```

### Fase 3 — Hipótese e teste

```text
1. Forme UMA hipótese clara: "Acho que X é a causa raiz porque Y". Escreva-a.
2. Teste minimamente: a MENOR mudança possível, uma variável por vez.
3. Verifique antes de continuar: funcionou → Fase 4; não funcionou → NOVA hipótese (não empilhe fixes).
4. Não sabe? Diga "não entendo X" — não finja, pesquise (context7 quando a suspeita é lib externa).
```

### Fase 4 — Implementação

**Antes de tocar no código:** confirme que NÃO está em branch protegida — invoque `pelizzai-starting-branch` (branch) antes de escrever o teste ou o fix. (As Fases 1-3 podem instrumentar e experimentar de forma **temporária e descartável** — logs de fronteira, a menor mudança de hipótese —, mas **reverta tudo antes da Fase 4**: nenhuma mudança que vá ser COMMITADA acontece antes do gate, e uma working tree suja quebra o `git pull --ff-only` da starting-branch. Stash/descarte a instrumentação antes de criar a branch.) Leia também `pelizzai/domain-skills.md` e aplique as skills de domínio da área afetada ao escrever o teste e o fix — o fix segue as convenções do projeto, não padrões genéricos.

```text
1. Crie o teste que FALHA (reprodução mais simples possível) — via pelizzai-tdd. OBRIGATÓRIO antes de corrigir.
2. Implemente UM fix (a causa raiz; uma mudança; sem "já que estou aqui").
3. Verifique: o teste passa? nenhum outro quebrou? Confirme com pelizzai-verification-before-completion.
   → encadeie pelizzai-review (revise o diff da working tree, trate Critical/Important) e então
     pelizzai-finish-task para consolidar e integrar — não deixe o bug corrigido parado na branch.
4. Se o fix não funcionar: PARE. Conte os fixes tentados. < 3 → volte à Fase 1 com a info nova.
   ≥ 3 → PARE e questione a arquitetura: acione `pelizzai-interview-me` para estressar a hipótese/arquitetura
   com o usuário; se revelar problema estrutural/de design, escale para `pelizzai-brainstorming` (track feature).
   Não tente o fix nº 4 sem essa discussão.
```

---

## Red flags — PARE e siga o processo

```text
- "Fix rápido por ora, investigo depois" / "Só muda X e vê se funciona".
- "Adiciona várias mudanças, roda os testes" / "Pula o teste, valido manual".
- "Provavelmente é X, deixa eu corrigir" (sintoma ≠ causa raiz).
- "Mais uma tentativa de fix" (com 2+ já tentadas) → 3+ falhas = problema de arquitetura.
- Cada fix revela um novo problema em outro lugar.
```

Racionalizações comuns ("é simples, não precisa de processo"; "emergência, sem tempo"; "escrevo o teste depois") são todas falsas: debugging sistemático é MAIS rápido que chutar; o primeiro fix define o padrão; teste antes prova que pega.

---

## Integração

**Roteada por:** `pelizzai-router` (track `bug`), que já traz o contexto e a isolação decididos.

**Usa:** `pelizzai-reasoning` (Root Cause Analysis; as fases seguem o OODA de `pelizzai-loop`), as **skills de domínio** do projeto (`pelizzai/domain-skills.md` — a área afetada), `pelizzai-team` (investigação com hipóteses concorrentes, read-only, só quando ≥3 fixes falharam ou hipóteses independentes — nunca o fix), `pelizzai-starting-branch` (branch antes da Fase 4), `pelizzai-tdd` (teste que falha), `pelizzai-verification-before-completion` (confirmar o fix), `pelizzai-review` (revisar o fix), `pelizzai-finish-task` (fechar o ciclo). Para causa raiz em lib externa, fundamente no `context7`.
