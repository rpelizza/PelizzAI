---
name: pelizzai-review
description: Skill de code review proporcional do harness PelizzAI. Use no gate de uma tarefa de plano, antes de integrar uma entrega ou quando o usuário pedir review de working tree, branch ou PR. Aplica as lentes spec e qualidade em perfil combinado ou separado conforme risco e orienta como receber feedback com rigor técnico. Para segurança/OWASP, componha `pelizzai-oswap`.
---

# PelizzAI Review

## Objetivo

Pegar problemas antes que eles se propaguem. O reviewer recebe **contexto fabricado** — descrição, requisitos/plano e o diff — **nunca o histórico da sua sessão**. Isso mantém o reviewer focado no produto, não no seu raciocínio, e preserva o seu contexto para continuar.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Review para revisar o código."

---

## Princípio central

> Revise com profundidade proporcional. Leia o produto de fato, não confie no relatório de quem
> implementou e dê um veredito claro com evidência — nunca um "parece bom".

---

## Quando revisar

```text
Obrigatório:
- No gate de cada tarefa de plano, pelo perfil registrado (`combined` ou `split`).
- No candidato final de uma entrega planejada, antes de `validated-head`.
- Quando o usuário pede review.

Opcional, mas valioso:
- Quando travado (perspectiva nova).
- Antes de uma refatoração (baseline).
- Depois de corrigir um bug complexo.
```

---

## Perfis de review por tarefa

Na execução de um plano, cada tarefa passa pelas lentes **spec** e **qualidade**, nesta ordem. O
implementador **não commitou** — o código está na working tree. O plano escolhe:

| Perfil | Predicado | Forma |
| --- | --- | --- |
| `combined` | bounded, low-risk, coesa, sem segurança/dados/migração/contrato público | um despacho e um relatório; spec primeiro, qualidade depois |
| `split` | risco médio/alto, superfície sensível, contrato público, dados, migração, múltiplas partes | spec aprova antes de despachar qualidade; independência proporcional |

O perfil reduz handoffs, não critérios. Se o diff revelar risco maior ou o combined sofrer rejeição
estrutural, promova para `split`.

### Estágio 1 — Conformidade com a spec

Verifique que o implementador construiu **exatamente** o que foi pedido — nada a mais, nada a menos. **Não confie no relatório**; leia o código.

```text
- Faltando: implementou tudo o que foi pedido? Pulou ou esqueceu algum requisito?
  Alegou que algo funciona mas não implementou?
- Extra/desnecessário: construiu o que não foi pedido? Super-engenharia? "Nice to haves" fora da spec?
- Mal-entendidos: interpretou diferente do pretendido? Resolveu o problema errado? Certo, mas do jeito errado?
- Traceabilidade por linha: toda linha alterada rastreia diretamente a um requisito do pedido?
  Linha sem rastro é scope creep — achado de primeira classe, não observação.
```

Use o template **[references/spec-reviewer.md](references/spec-reviewer.md)** (sem rodar testes — Verification é do Estágio 2). Resultado: **✅ Conforme a spec** (tudo bate após inspeção do código), **❌ Problemas** (liste o que falta/sobra, com `arquivo:linha`), ou **⚠️ Não verificável** → exige avaliação do coordenador contra o plano antes de concluir (ver `pelizzai-execution-plans` → `references/task-cycle.md` §3-§4).

### Estágio 2 — Qualidade do código

No perfil `split`, só despache esta lente após spec passar. No `combined`, aplique-a na segunda
parte do mesmo relatório. Use a rubrica completa em **[references/code-reviewer.md](references/code-reviewer.md)**. Avalie: separação de responsabilidades, tratamento de erro, segurança de tipos, DRY sem abstração prematura, edge cases, arquitetura, segurança, testes (verificam comportamento real, não mocks), prontidão para produção. Além disso:

```text
- Cada arquivo tem UMA responsabilidade clara e interface bem definida?
- As unidades são decompostas para serem entendidas e testadas de forma independente?
- A implementação segue a estrutura de arquivos do plano?
- Esta mudança criou arquivos já grandes, ou inchou demais arquivos existentes?
  (Não aponte tamanho pré-existente — foque no que ESTA mudança contribuiu.)
- Julgue a mudança também contra as regras/skills locais aplicáveis: catálogo no consumidor;
  regras/skills do repo-fonte em source mode.
```

Se o reviewer sinalizar **superfície sensível** (auth, input do usuário, query/SQL, segredos, upload, novas dependências), acione `pelizzai-oswap` (OWASP) antes de concluir — não deixe a segurança só como item de lista.

---

## Evidência fresca (bloco Verification, obrigatório)

O reviewer de qualidade seleciona e **roda de fato** os checks que podem provar o artefato
(teste, lint, build, parser, render, dry-run ou cenário), colando comando, saída e exit code num
bloco `### Verification`. Não imponha test/lint/build quando não há diff executável ou relação
causal; review arquitetural codebase-wide usa `pelizzai-improving-architecture`. **Não infira**
passa/falha lendo o diff. Check relevante que não pôde rodar é **UNVERIFIED — nunca ✅**.

---

## Como despachar o reviewer

Use um reviewer independente quando risco/complexidade justificarem; para tarefa bounded, o
coordenador pode aplicar o perfil `combined` inline. A lente spec usa
**[references/spec-reviewer.md](references/spec-reviewer.md)**; qualidade e review final usam
**[references/code-reviewer.md](references/code-reviewer.md)**. Em `combined`, incorpore as duas
rubricas num único briefing, mantendo a ordem. Preencha com:

```text
- Descrição: o que foi construído.
- Requisitos/Plano: o que deveria fazer (texto da tarefa ou caminho do plano em pelizzai/plans/).
- Diff a revisar:
  - Por tarefa (spec E qualidade, combined ou split) → gere `review-package --working-tree`. O pacote contém,
    separadamente, `git diff --cached`, `git diff` e o conteúdo dos untracked. Não use range:
    a tarefa ainda não foi commitada e um range vazio esconderia todo o trabalho.
  - Review final → gere `review-package <base-sha> <HEAD_SHA>` e use o range commitado.
    `base-sha` vem do `state.md` consumidor ou execution record nativo; não redescubra a base.
- Regras/skills locais relevantes (coladas) — o reviewer julga a mudança contra elas.
- Skills transversais/overlays registradas no state/execution record (coladas) — frontend, segurança,
  documentação ou outra restrição aplicável também fazem parte do contrato de review.
```

Use `pwsh scripts/review-package.ps1 --working-tree` ou
`sh scripts/review-package.sh --working-tree`. O helper grava um nome único no handoff dir
gitignored do consumidor ou no temp do sistema em source mode; passe esse arquivo ao reviewer. O
modo `<BASE> <HEAD>` é usado no review final da entrega; fora do lifecycle, somente quando o
usuário pediu explicitamente um range avulso.

O reviewer **nunca** recebe o histórico da sessão.

---

## Anti-corrupção do pipeline de review

Estas regras protegem a independência do review (as demais skills referenciam esta seção):

```text
- NUNCA instrua o reviewer sobre o que NÃO flagrar, nem pré-classifique severidade no prompt —
  se o prompt que você está escrevendo contém "não aponte…", você está pré-julgando o review.
- Finding causado pelo PRÓPRIO plano (a implementação seguiu o que o plano mandou) sobe ao
  humano — quem escreveu o plano não dá nota no próprio trabalho.
- Minors acumulam num LEDGER e são triados no review final — um roll-up que ninguém lê é um
  descarte silencioso.
- Os findings do review final são corrigidos por UM único fixer (um despacho com todos os
  achados) — nunca um fixer por finding.
```

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
### Verification     — checks aplicáveis RODADOS + saída + exit code; check relevante não rodado = UNVERIFIED
### Assessment       — Pronto para mergear? [Sim | Não | Com correções] + 1-2 frases de justificativa
```

Categorize pela severidade REAL — nem tudo é Critical; um nitpick não é Critical.

---

## Review final da branch

Ao concluir todas as tarefas, revise a **branch inteira** no range commitado
`<base-sha>..<HEAD>` — depois da consolidação `squash-final`, quando escolhida — e não só por
tarefa. Use um reviewer independente e capacidade/effort proporcionais à complexidade e ao
risco; não force effort máximo para toda mudança. Este review acontece **depois** dos overlays
que podem escrever (segurança, frontend e documentação) e antes da suíte completa, checklist e
`pelizzai-verification-before-completion`. Critical/Important abertos bloqueiam a conclusão.

Exceção de reutilização: plano de **uma única tarefa bounded**, perfil `combined`, sem findings nem
mutação de conteúdo posterior pode tratar o review da tarefa como review final quando o tree SHA
pós-commit é exatamente o tree SHA candidato revisado. Continue checks, checklist e Verification.
Na ausência dessa prova — múltiplas tarefas, overlay/fix posterior, risco promovido, compaction sem
evidência ou qualquer dúvida — faça o review final normal.

Qualquer fix — de finding, overlay, teste, checklist ou verificação visual — altera o candidato:
invalide `validated-head`, consolide o fix, rode novamente os overlays afetados e **reabra o
review final** sobre o novo HEAD. “Já foi revisado antes do fix” não vale como aprovação.

**Quem dispara o review final:** `pelizzai-execution-plans` (fechamento de plano). O fix de bug
(`pelizzai-debugging`) usa o **review de mudança avulsa** abaixo ainda na working tree; depois o
debugging consolida o conteúdo, roda Verification contra o HEAD e só então chama finish-task.
O track de ajuste (`pelizzai-quick-fix`) dispensa review formal enquanto continuar trivial.

**Review de mudança avulsa** (bug fora de plano, ou ajuste reclassificado antes do commit): use
`review-package --working-tree` (staged + unstaged + untracked) e aplique o **Estágio 2**
(qualidade) com o bloco `Verification`, **sem** a maquinaria por-tarefa / review-final /
circuit-breaker.

Quick-fix válido não entra nesse procedimento. Se o diff elevar o risco, reclassifique pelo router
e aplique o review da nova rota antes do commit.

**Track de review avulso:** derive o escopo do pedido e do Git (working tree, range
`<BASE>..<HEAD>` ou PR); pergunte apenas se duas interpretações mudarem materialmente o resultado.
Aplique a lente de qualidade + Verification. Este track é read-only e não cria state. Achado
Critical não se corrige dentro do review: vira um novo track de bug/ajuste via router; os demais
achados são entregues para decisão do usuário.

---

## Agir sobre o feedback

```text
- Critical → corrija imediatamente.
- Important → corrija antes de prosseguir.
- Minor → anote para o review final.
- Reviewer errado → faça push back com raciocínio técnico (mostre código/testes que provam).
```

Isso alimenta o circuit breaker da `pelizzai-execution-plans` (3 ciclos por lente, por tarefa;
detalhe e resets em `pelizzai-execution-plans` → `references/task-cycle.md` §5). **Handback de
branch protegida:** se agir sobre o feedback significa escrever código e não há isolamento no state
consumidor ou execution record nativo, passe por `pelizzai-starting-branch` antes — para os fixes
não caírem em branch protegida.

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
- Pular um review exigido pela lane/perfil ou rebaixar o perfil apesar de risco novo.
- Ignorar Critical, ou seguir com Important em aberto.
- Dar feedback sobre código que não leu de fato.
- Marcar nitpick como Critical, ou ser vago ("melhorar o tratamento de erro").
- Relatar como ✅ um check que não rodou (evidência inferida do diff).
- Passar o histórico da sessão ao reviewer (ele recebe só o contexto fabricado).
- Concordância performática ao receber feedback ("você está certíssimo", agradecer).
- No perfil split, despachar qualidade antes de spec passar; no combined, inverter as lentes.
- Instruir o reviewer sobre o que NÃO flagrar, ou pré-classificar severidade no prompt.
- Corrigir os findings do review final com um fixer por finding (é UM fixer para todos).
- Usar `<BASE>..<HEAD>` no review por tarefa; antes do commit, o escopo é sempre `--working-tree`.
- Aceitar como final um review anterior ao último fix ou overlay que escreveu arquivos.
```

---

## Integração

**Combina com:**

- `pelizzai-execution-plans` — review por tarefa (combined/split) e review final; ver `task-cycle.md`.
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

Spec primeiro, qualidade depois — em um ou dois despachos conforme risco. Critical/Important antes de seguir; Minor para o final.
Nunca passe o histórico da sessão ao reviewer. Para segurança, use pelizzai-oswap.
```
