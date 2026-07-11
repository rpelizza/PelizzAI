---
name: pelizzai-debugging
description: Head skill do track de bug. Use ao encontrar bug, falha de teste, incidente ou comportamento inesperado. Faz triagem entre causa direta, bug determinístico incerto, falha flaky/distribuída e incidente com dano ativo; escolhe reasoning e validação proporcionais, contém dano reversivelmente antes de investigar e não obriga RCA, OODA ou quantidade fixa de hipóteses.
---

# PelizzAI Debugging

## Objetivo

Corrigir a causa comprovada com o menor processo que preserve evidência, segurança e regressão.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Debugging para classificar a falha, conter impacto se necessário e corrigi-la com evidência."

## Invariantes

```text
NENHUM FIX DEFINITIVO SEM EVIDÊNCIA SUFICIENTE DA CAUSA.
CONTENÇÃO REVERSÍVEL NÃO É FIX E PODE PRECEDER A INVESTIGAÇÃO.
```

- Não confunda sintoma, hipótese, causa confirmada, contenção e prevenção.
- Não imponha RCA a uma causa direta nem OODA a uma sequência curta.
- Não invente um número de hipóteses. Mantenha apenas as materialmente plausíveis.
- O fix roda inline. Delegue somente investigação read-only de hipóteses realmente independentes; a sessão principal decide e implementa.

---

## Passo 0 — há dano ativo?

Antes da reprodução, verifique se usuários, dados, segurança, disponibilidade ou custo continuam sendo afetados.

Se **sim**:

```text
1. Confirme alvo, alcance e autorização.
2. Preserve a evidência mínima que a contenção apagaria (métricas, IDs, logs, versão/diff).
3. Aplique a menor contenção reversível disponível: rollback conhecido, feature flag, pausar consumer,
   bloquear rota vulnerável ou reduzir exposição — conforme o sistema e as permissões.
4. Monitore o sinal de impacto e confirme se estabilizou.
5. Só então investigue a correção estrutural.
```

Se não houver contenção segura ou faltar autoridade, escale imediatamente com alvo, impacto, opção proposta e risco. **Nunca bloqueie a contenção aguardando uma reprodução perfeita.**

---

## Passo 1 — classifique antes de escolher o reasoning

| Classe | Sinais | Reasoning | Hipóteses | Caminho |
| --- | --- | --- | --- | --- |
| **Causa direta** | compilador, stack trace ou contrato aponta uma causa local inequívoca | ReAct + Verification | zero ou uma | reproduzir o erro → corrigir → rodar o mesmo oráculo |
| **Determinístico incerto** | falha sempre, mas a origem ainda não está provada | RCA leve + ReAct | uma basta se discrimina; adicione outras só se competirem | loop mínimo → evidência → hipótese falsificável → fix |
| **Flaky, recorrente ou distribuído** | taxa variável, concorrência, rede, múltiplas camadas/retries | RCA + Evidence Synthesis; Assumption Tracking quando útil | várias somente enquanto materialmente plausíveis | medir taxa → correlacionar fronteiras → testar hipótese mais informativa |
| **Incidente com dano ativo** | produção degradada, exposição, perda/custo em curso | Constraint Satisfaction + Decision Making na contenção; RCA depois | depois de estabilizar | conter → monitorar → reclassificar e investigar |

Use `pelizzai-loop`/OODA apenas quando houver **múltiplas rodadas** e cada rodada mudar evidência, hipótese ou realidade externa. OODA é o macro-loop de controle; não é técnica diagnóstica.

---

## Passo 2 — construa o oráculo mais barato que prove o sintoma

Prefira um comando executável e já rodado que falhe pelo sintoma exato. No consumidor, use
`pelizzai/profile.md` quando existir; em source mode ou sem profile, descubra o comando nos
manifests, scripts e workflows reais. Não chute nem crie profile para investigar. O menu de táticas
vive em [references/feedback-loops.md](references/feedback-loops.md); **esta SKILL.md é canônica
para triagem e ordem**, portanto a linguagem legada de “Fase 1 obrigatória” da referência não
precede contenção nem recria as quatro fases universais.

O oráculo pode ser teste, typecheck/build, script mínimo, query controlada, trace, métrica ou taxa de reprodução. Para falha flaky, registre condições e frequência; para incidente não reproduzível fora de produção, métricas/logs correlacionados podem ser o oráculo inicial.

Colete somente a evidência que diferencia caminhos:

```text
- mensagem completa, stack trace, input e ambiente;
- mudanças recentes e diff da área;
- exemplo equivalente que funciona;
- fluxo do valor até o primeiro ponto em que se torna incorreto;
- em múltiplas camadas, entrada/saída e correlation/request ID em cada fronteira.
```

Telemetria existente pode ser lida imediatamente. Qualquer instrumentação que altere código/config
passa por `pelizzai-starting-branch` **antes** da edição; eventual deploy passa também pelo gate
`external`. Se adicionar instrumentação temporária, crie um prefixo único `[DEBUG-<id>]`, use-o em
todo log novo e remova-a antes da implementação definitiva.

---

## Passo 3 — teste hipóteses proporcionalmente

Uma causa direta comprovável não precisa de brainstorming causal. Quando houver incerteza:

```text
1. Registre fatos confirmados separados de hipóteses.
2. Para cada hipótese material, escreva uma predição falsificável.
3. Escolha a observação que mais discrimina as hipóteses com menor custo/risco.
4. Mude uma variável por vez; não empilhe fixes.
5. Evidência refutou a hipótese → descarte-a e reoriente.
```

Mostre o ranking ao usuário apenas quando conhecimento operacional dele puder mudá-lo; não interrompa um bug local óbvio com cerimônia. Use `pelizzai-team` para investigação read-only somente quando hipóteses independentes puderem ser testadas em paralelo ou após thrashing real. Três fixes definitivos falhos são circuit breaker: pare, resuma evidência e questione hipótese/arquitetura antes de tentar outro.

---

## Passo 4 — implemente e prove

Antes de qualquer mutação no repositório — teste, instrumentação ou fix — use
`pelizzai-starting-branch`. No consumidor, carregue as skills aplicáveis de
`pelizzai/domain-skills.md`; em source mode, use regras/skills do próprio repo. Reverta experimentos
descartáveis que não pertençam ao fix. Contenção operacional autorizada que não escreve no repo
não espera uma branch.

Escolha a estratégia pela natureza da mudança, conforme `pelizzai-reasoning`:

```text
- Bug de comportamento com seam automatizável: teste de regressão red→green via pelizzai-tdd.
- Erro estático direto (import, tipo, build): o typecheck/build que reproduz pode ser prova suficiente;
  adicione teste somente se proteger comportamento útil.
- Refatoração necessária ao fix: caracterização verde antes, passos pequenos, mesma suíte verde depois.
- Config/IaC/migração: validate/plan/dry-run e rollback; teste unitário só para lógica separável.
- UI: pelizzai-frontend é overlay obrigatório; comportamento quando aplicável + verificação visual.
- Documentação: lint/links/exemplos/build/render ou inspeção estática proporcional.
```

Implemente **um** fix na origem, sem "já que estou aqui". Depois:

```text
1. Rode de novo o oráculo original — agora verde.
2. Rode a validação relevante e confirme nenhuma regressão.
3. Revise a working tree com `pelizzai-review`; aplique findings e reexecute as provas afetadas.
4. Consolide o conteúdo em commit definitivo. Se uma estratégia squash-final explicitamente
   autorizada produziu WIPs, consolide-a agora, antes do seal; finish-task não reescreve histórico.
5. Rode `pelizzai-verification-before-completion` contra o HEAD consolidado, grave
   `validated-head` e só então chame `pelizzai-finish-task`: closure metadata-only no consumidor;
   fechamento do execution record, sem runtime/closure, em source mode.
```

Se não existir seam adequado para uma regressão importante, registre o achado arquitetural e encaminhe a `pelizzai-improving-architecture`; não escreva teste tautológico num seam errado.

---

## Fechamento proporcional

Sempre:

```text
[ ] Oráculo original reexecutado e verde.
[ ] `rg "\[DEBUG-"` não encontra instrumentação desta sessão.
[ ] Protótipos e mudanças experimentais removidos.
[ ] Diff contém somente o fix e sua prova.
```

Para falha recorrente, distribuída, de segurança ou incidente, registre também: causa confirmada, fatores contribuintes, contenção, prevenção/detecção e "o que teria evitado isto?". Para um import incorreto evidente, não invente post-mortem.

## Red flags

```text
- Investigar longamente enquanto o dano continua e há contenção reversível disponível.
- Declarar causa raiz a partir de correlação temporal.
- Exigir 3–5 hipóteses para erro direto ou aceitar uma só em sistema distribuído sem evidência.
- Usar OODA como nome para cada comando/teste.
- Corrigir duplicidade apenas com debounce/delay no frontend.
- Aumentar timeout, desativar segurança ou esconder sintoma como solução definitiva.
- Empilhar mudanças e depois perguntar qual funcionou.
- Escrever teste artificial só para dizer que usou TDD.
```

## Integração

**Roteada por:** `pelizzai-router` (track `bug`).

**Usa condicionalmente:** `pelizzai-reasoning` (seleção acima), `pelizzai-loop` (somente macro-loop em rodadas), [feedback-loops.md](references/feedback-loops.md), skills de domínio, `pelizzai-starting-branch`, `pelizzai-tdd` (bug comportamental automatizável), `pelizzai-frontend` (UI), `pelizzai-verification-before-completion`, `pelizzai-review` e `pelizzai-finish-task`.

Para APIs/libs externas, confirme a documentação oficial atual disponível. Para seam ausente, use `pelizzai-improving-architecture` com o vocabulário de `pelizzai-codebase-design`.
