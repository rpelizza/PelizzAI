---
name: pelizzai-review
description: Skill de code review do harness PelizzAI. Use após CADA tarefa na execução de um plano, ao concluir uma feature relevante, antes de integrar uma entrega ou quando o usuário pedir review de working tree, branch ou PR. Aplica as lentes spec (cega) e qualidade/evidência — por padrão em dois despachos (`split`) — e orienta como receber feedback com rigor técnico. Para segurança/OWASP, componha `pelizzai-oswap`.
---

# PelizzAI Review

## Objetivo

Pegar problemas antes que eles se propaguem. O reviewer recebe **contexto fabricado** — descrição, requisitos/plano e o diff — **nunca o histórico da sua sessão**. Isso mantém o reviewer focado no produto, não no seu raciocínio, e preserva o seu contexto para continuar.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Review para revisar o código."

---

## Princípio central

> Revise cedo e sempre. Um review é uma verificação independente do produto: leia o código de fato,
> não confie no relatório de quem implementou e dê um veredito claro com evidência — nunca um
> "parece bom". A **profundidade** de cada lente é proporcional ao risco; a **existência** do review
> não é.

---

## Quando revisar

```text
Obrigatório:
- Após CADA tarefa na execução de um plano (pelizzai-execution-plans) — sem exceção por "é simples".
  O perfil registrado (`split` por padrão, `combined` só por ratificação) muda a FORMA do review,
  nunca se ele acontece.
- Ao concluir uma feature relevante.
- No candidato final de uma entrega planejada, antes de `validated-head` — e antes de integrar à base.
- Quando o usuário pede review.

Opcional, mas valioso:
- Quando travado (perspectiva nova).
- Antes de uma refatoração (baseline).
- Depois de corrigir um bug complexo.
```

---

## Perfis de review por tarefa

Na execução de um plano, cada tarefa passa por **duas lentes com cegueira assimétrica** — a lente
**spec** e a lente **qualidade/evidência**, nesta ordem. O implementador **não commitou** — o código
está na working tree. A assimetria é deliberada:

- **Lente spec (cega):** recebe SOMENTE o diff, a spec/plano da tarefa e as domain skills da área.
  **O revisor da lente spec NÃO recebe o relatório do implementador — julga o código contra o contrato, sem a narrativa do autor.**
  Sem a história de quem escreveu, ela mede a implementação real contra o pedido, linha a linha, sem
  ser ancorada pelas alegações otimistas do autor.
- **Lente qualidade/evidência:** recebe o relatório do autor e **verifica as alegações** — os testes
  rodaram mesmo? A prova é fresca (comando + saída + exit code)? Os desvios do plano foram
  declarados? Roda de fato os checks aplicáveis para confirmar ou derrubar o que o relatório afirma,
  além de avaliar a qualidade do código.

O plano escolhe o perfil, que decide se as lentes usam um ou dois despachos. **O padrão recomendado
é `split`** — só com dois despachos a cegueira existe de fato; num despacho só ela vira mera ordem
de leitura, e um revisor que já leu o relatório não desconhece a narrativa do autor. `combined` é
**exceção**, e o usuário a ratifica explicitamente no passo 4 do gate de setup
(`pelizzai-execution-plans`).

| Perfil | Predicado | Forma |
| --- | --- | --- |
| `split` (**recomendado por padrão**) | o caso normal, inclusive tarefa bounded; **obrigatório** em risco médio/alto, superfície sensível, contrato público, dados, migração, múltiplas partes | a lente spec **cega** aprova antes de despachar a lente qualidade/evidência; despachos independentes |
| `combined` (exceção ratificada) | tarefa bounded, low-risk, coesa, sem segurança/dados/migração/contrato público — **e** o usuário ratificou o perfil no gate | um despacho e um relatório; spec primeiro, qualidade/evidência depois — a cegueira aqui é só lógica (uma passada, o revisor vê tudo) |

**Proporcionalidade sem afrouxar a cegueira:** a cegueira assimétrica das duas lentes entra no
`split`, que é o perfil **recomendado por padrão** — inclusive para tarefa bounded, em qualquer lane.
O que a proporcionalidade regula é a **profundidade** de cada lente (quanto se investiga, quantos
checks se roda), não se o review acontece nem se ele é cego. O perfil reduz handoffs, não critérios.
Se o diff revelar risco maior ou o `combined` sofrer rejeição estrutural, promova para `split` sem
pedir nova ratificação; rebaixar para `combined` sempre exige uma escolha explícita do usuário.

**Consolidação e conflito são do coordenador:** ele cruza os verdicts das duas lentes e, quando elas
divergem, decide com evidência própria (rodando ele mesmo o check em disputa) ou escala ao usuário.
O coordenador **nunca** é a lente cega — ele já viu o relatório e o raciocínio do autor, então não
pode julgar às cegas; a lente spec cega é sempre um revisor independente.

### Estágio 1 — Lente spec (conformidade, cega)

Verifique que o implementador construiu **exatamente** o que foi pedido — nada a mais, nada a menos.
No `split` (o padrão), esta lente é **cega**: você não recebe o relatório do implementador — julga o
diff contra o contrato, sem a narrativa do autor. No `combined` ratificado, o único revisor enxerga o
relatório, mas aplica esta rubrica **primeiro**, medindo o código contra o pedido antes de ler
qualquer alegação. Em ambos: **leia o código de fato**, não aceite alegações.

```text
- Faltando: implementou tudo o que foi pedido? Pulou ou esqueceu algum requisito?
  Alegou que algo funciona mas não implementou?
- Extra/desnecessário: construiu o que não foi pedido? Super-engenharia? "Nice to haves" fora da spec?
- Mal-entendidos: interpretou diferente do pretendido? Resolveu o problema errado? Certo, mas do jeito errado?
- Traceabilidade por linha: toda linha alterada rastreia diretamente a um requisito do pedido?
  Linha sem rastro é scope creep — achado de primeira classe, não observação.
```

Use o template **[references/spec-reviewer.md](references/spec-reviewer.md)** (sem rodar testes — Verification é do Estágio 2). Resultado: **✅ Conforme a spec** (tudo bate após inspeção do código), **❌ Problemas** (liste o que falta/sobra, com `arquivo:linha`), ou **⚠️ Não verificável** → exige avaliação do coordenador contra o plano antes de concluir (ver `pelizzai-execution-plans` → `references/task-cycle.md` §3-§4).

### Estágio 2 — Lente qualidade/evidência

No perfil `split`, só despache esta lente após spec passar. No `combined`, aplique-a na segunda
parte do mesmo relatório. **Esta é a lente que recebe o relatório do implementador** e verifica as
alegações contra evidência fresca — os testes rodaram mesmo? A prova é fresca (comando + saída + exit
code)? Os desvios do plano foram declarados no campo `Desvios do plano:`? Uma alegação que você não
conseguiu confirmar rodando o check é **UNVERIFIED**, nunca ✅. Use a rubrica completa em
**[references/code-reviewer.md](references/code-reviewer.md)**. Avalie: separação de responsabilidades, tratamento de erro, segurança de tipos, DRY sem abstração prematura, edge cases, arquitetura, segurança, testes (verificam comportamento real, não mocks), prontidão para produção. Além disso:

```text
- Cada arquivo tem UMA responsabilidade clara e interface bem definida?
- As unidades são decompostas para serem entendidas e testadas de forma independente?
- A implementação segue a estrutura de arquivos do plano?
- Esta mudança criou arquivos já grandes, ou inchou demais arquivos existentes?
  (Não aponte tamanho pré-existente — foque no que ESTA mudança contribuiu.)
- Julgue a mudança também contra as SKILLS DE DOMÍNIO do projeto (`pelizzai/domain-skills.md` no
  consumidor; em source mode, as regras/skills do próprio repo-fonte). Em conflito com padrões
  genéricos, as skills de domínio e as regras do projeto PREVALECEM.
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

Use um **reviewer independente** — é o default: no `split` a lente spec cega precisa ser outro
agente, e o coordenador nunca a encarna. Só com `combined` ratificado o coordenador pode aplicar as
duas rubricas inline, e ainda assim na ordem spec → qualidade. A lente spec usa
**[references/spec-reviewer.md](references/spec-reviewer.md)**; qualidade/evidência e review final usam
**[references/code-reviewer.md](references/code-reviewer.md)**. Em `combined`, incorpore as duas
rubricas num único briefing, mantendo a ordem. Preencha com:

```text
- Descrição: o que foi construído.
- Requisitos/Plano: o que deveria fazer (texto da tarefa ou caminho do plano em pelizzai/plans/).
- Relatório do implementador: as alegações do autor (testes rodados, prova, desvios do plano). Vai
  SOMENTE para a lente qualidade/evidência (que o verifica) e para o revisor único do `combined`.
  NUNCA para a lente spec cega do `split` — ela julga o código contra o contrato, sem a narrativa.
- Diff a revisar:
  - Por tarefa (spec E qualidade/evidência, combined ou split) → gere `review-package --working-tree`. O pacote contém,
    separadamente, `git diff --cached`, `git diff` e o conteúdo dos untracked. Não use range:
    a tarefa ainda não foi commitada e um range vazio esconderia todo o trabalho.
  - Review final → gere `review-package <base-sha> <HEAD_SHA>` e use o range commitado.
    `base-sha` vem do `state.md` consumidor ou execution record nativo; não redescubra a base.
- SKILLS DE DOMÍNIO da área (coladas) — do catálogo `pelizzai/domain-skills.md` no consumidor, ou
  das regras/skills do repo-fonte em source mode. Preenchem o slot `{SKILLS_DE_DOMÍNIO}` **dos dois
  templates**: a lente spec cega recebe diff + spec/plano + domain skills; a lente qualidade/evidência
  recebe as mesmas skills além do relatório. Skill de domínio prometida e não colada é lente cega sem
  contrato — cole os pontos operacionais, não só os nomes. Sem cobertura na área, escreva "nenhuma"
  e peça que o reviewer sinalize a lacuna.
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
tarefa. Use um reviewer independente, com o **modelo da sessão** — o que o usuário escolheu, nunca
um menor — e o **effort mais alto que a plataforma permitir**: review final é o último filtro antes
do seal, não lugar de economizar por conta própria nem de afinar o processo para compensar modelo
menor. É o passo 1 da
**validação final da entrega** do coordenador (`pelizzai-execution-plans` → "Validação final da
entrega") e acontece **depois** dos overlays que podem escrever (segurança, frontend e documentação)
e antes da suíte completa, checklist e `pelizzai-verification-before-completion`. Critical/Important
abertos bloqueiam a conclusão.

Exceção de reutilização (estreita, e nunca o caminho padrão): plano de **uma única tarefa bounded**,
com efeito `read-only` ou `write-local`, risco baixo, perfil `combined` ratificado pelo usuário, sem
findings e sem mutação de conteúdo posterior pode tratar o review da tarefa como review final quando
o tree SHA pós-commit é exatamente o tree SHA candidato revisado. Continue checks, checklist e
Verification. Basta **um** desses itens faltar — efeito `write-shared`/produção, risco médio/alto,
superfície sensível (segurança, dados, migração, contrato público), perfil `split` (o padrão),
múltiplas tarefas, overlay/fix posterior, compaction sem evidência ou qualquer dúvida — e o review
final normal volta a ser obrigatório. A exceção existe para não duplicar um review comprovadamente
idêntico, não para dispensar a validação final.

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

**Track de review avulso:** recomende o escopo derivado do pedido e do Git e **confirme quando for
ambíguo** — working tree, range `<BASE>..<HEAD>` e PR são interpretações materialmente diferentes;
não revise o alvo errado por suposição. Com uma só leitura plausível, siga sem perguntar. Aplique a
lente de qualidade + Verification. Este track é read-only e não cria state. Achado Critical não se
corrige dentro do review: vira um novo track de bug/ajuste via router; os demais achados são
entregues para decisão do usuário.

Quando o usuário autoriza **aplicar** os achados, aplique **todos** — Critical, Important e Minor
(must/should/nice) num despacho consolidado, não só os Critical; roll-up que ninguém corrige é
descarte silencioso. Cada achado que vira escrita segue a rota do router (quick-fix/tdd/debugging) e,
depois dos fixes, **reabra o review** sobre o novo conteúdo — "já revisei antes do fix" não vale.

Sob briefing fechado (SUBAGENT-STOP), não produza análises de rota nem abra gates: aplique o briefing e escale ao coordenador o que exigir decisão.

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
- Pular o review porque "é simples" — a profundidade é proporcional; a existência do review não é.
- Pular um review exigido pela lane/perfil ou rebaixar o perfil apesar de risco novo.
- Usar `combined` por conta própria: o padrão é `split`, e o downgrade exige ratificação explícita
  do usuário no gate.
- Prometer skills de domínio ao reviewer e despachar o briefing com o slot `{SKILLS_DE_DOMÍNIO}`
  vazio — a lente cega fica sem o contrato do projeto contra o qual deveria julgar.
- Rebaixar modelo ou effort abaixo do da sessão num review (por tarefa ou final) para economizar —
  capacidade é escolha do usuário, e o harness nunca a reduz em silêncio.
- Ignorar Critical, ou seguir com Important em aberto.
- Dar feedback sobre código que não leu de fato.
- Marcar nitpick como Critical, ou ser vago ("melhorar o tratamento de erro").
- Relatar como ✅ um check que não rodou (evidência inferida do diff).
- Passar o histórico da sessão ao reviewer (ele recebe só o contexto fabricado).
- Concordância performática ao receber feedback ("você está certíssimo", agradecer).
- No perfil split, despachar qualidade/evidência antes de spec passar; no combined, inverter as lentes.
- Entregar o relatório do implementador à lente spec cega do split — ela julga o código contra o
  contrato, sem a narrativa do autor; quem recebe e verifica o relatório é a lente qualidade/evidência.
- O coordenador se despachar como lente spec cega: ele já viu o relatório e o raciocínio do autor,
  então não pode julgar às cegas — a lente cega é sempre um revisor independente.
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

Revise cedo e sempre: a profundidade é proporcional ao risco, a existência do review não.
Spec primeiro, qualidade/evidência depois — em DOIS despachos por padrão (`split`); um só despacho (`combined`) apenas com ratificação explícita do usuário. Critical/Important antes de seguir; Minor para o final.
No split, a lente spec é cega (sem o relatório) e recebe diff + spec/plano + skills de domínio da área; a lente qualidade/evidência recebe e verifica o relatório. O coordenador cruza as lentes e nunca é a lente cega.
Nunca passe o histórico da sessão ao reviewer. Para segurança, use pelizzai-oswap.
```
