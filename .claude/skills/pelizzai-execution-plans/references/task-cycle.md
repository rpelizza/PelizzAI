# Ciclo por tarefa — protocolo detalhado

O protocolo que cada tarefa segue na execução de um plano, válido nos três modos (team, subagents,
inline). A prova e a forma do review variam por artefato e risco; os gates de escopo, qualidade e
evidência permanecem observáveis.

## 0. Autonomia entre as tarefas e a parada por lacuna material

O coordenador roda o ciclo abaixo de ponta a ponta **sem pedir licença a cada passo**: dentro de um
plano ratificado, passo mecânico e verificável se executa — não se pergunta "sigo?" ao fim de cada
tarefa nem se pede permissão para comando local reversível. A autonomia é de **execução**; a decisão
continua sendo do humano.

Fora de `BLOCKED` e do circuit breaker (§5), a única coisa que interrompe uma frente no meio é a
**lacuna material**: requisito, escopo, UX, arquitetura, dados, segurança, custo, risco aceito ou
critério de aceite que a spec e o plano não decidiram. Ela tem caminho fixo, não é uma pausa vaga:

```text
1. O membro PARA a sua tarefa e NOMEIA a lacuna: o que não está decidido, o que ela muda na entrega
   e as 2–3 opções que enxerga, com a que recomenda. Devolve NEEDS_CONTEXT. Nunca preenche por
   convenção, default, Context7 ou "inferência razoável", e nunca fala direto com o usuário.
2. O coordenador NÃO decide no lugar dele nem por si. Confere se a resposta já está no plano/spec:
   se estiver, era falta de contexto — ele fornece e re-despacha. Se não, é lacuna material.
3. O coordenador CONSOLIDA as lacunas materiais abertas — consolidar é agrupar e ordenar por
   dependência, NUNCA decidir — e as leva ao humano por `pelizzai-interview-me` no modo lacuna:
   uma pergunta por vez, com opções reais e a recomendada (porquê em uma linha).
4. A decisão ratificada é registrada no plano (`## Decisões técnicas deste plano`, origem:
   entrevista de execução; a lacuna sai de `## Lacunas materiais expostas` resolvida) e a frente
   retoma de onde parou, com o briefing atualizado.
```

**Lacuna de DOMAIN SKILL é outra coisa e segue outro caminho:** o membro sinaliza
(`DONE_WITH_CONCERNS`), a execução **não** para, e o coordenador acumula as lacunas para uma
proposta única no fechamento (§4). Uma é decisão do usuário e para a frente; a outra é manutenção do
catálogo e nunca vira gate por tarefa.

## 1. Briefing autossuficiente (por arquivo quando os scripts existem; senão por colagem)

O membro (teammate/subagente) **nunca lê o arquivo do plano** — isso evita poluição de contexto e mantém o foco. Quem entrega o contexto é o coordenador, por um destes dois canais:

- **Por ARQUIVO (preferido, quando o script existe **e** há plano Markdown persistente compatível):** rode `task-brief <plano> <N>` — ele extrai a Tarefa N + Global Constraints para o handoff dir seguro (gitignored no consumidor; temp em source mode), e o briefing aponta para ESSE arquivo. O relatório vai ao mesmo diretório e a resposta no chat fica em **≤15 linhas**. Para review, `review-package --working-tree` inclui staged, unstaged e untracked. O mesmo pacote atende combined/split. Range `<base-sha> <HEAD>` é só final. O princípio "contexto construído, nunca herdado" se mantém.
- **Por colagem (fallback, sem script ou sem plano persistente):** o coordenador extrai o **texto completo** da tarefa do plano/execution record nativo e o cola no prompt do membro. Não crie arquivo consumidor só para satisfazer o helper.

O briefing de cada tarefa inclui:

```text
- Texto completo da tarefa (do brief em arquivo, ou colado do plano, com valores exatos a usar
  verbatim) — incluindo as Global Constraints do cabeçalho do plano.
- Skills de domínio aplicáveis do catálogo (coladas, ou seus pontos-chave) — o membro não herda o
  seu contexto. Em dúvida se uma skill de domínio do catálogo se aplica à tarefa, inclua-a: o custo
  de incluir é menor que o de ignorar uma regra do projeto. Se a superfície da tarefa toca uma stack
  SEM domain skill cobrindo, o membro aplica o que tem e SINALIZA a lacuna no retorno
  (`DONE_WITH_CONCERNS`); nunca cria skill no meio da tarefa.
- Skills transversais em `overlays:` no state (frontend, segurança, documentação etc.), com os
  gates que cada uma exige. Propague-as para implementador **e reviewers**; não basta nomeá-las.
- Convenções e contratos necessários (caminhos, interfaces, decisões já tomadas).
- Camada global: aplique `pelizzai-preferences` (idioma, segredos, .env, qualidade de produção) e
  raciocine via `pelizzai-reasoning`; em conflito, as SKILLS DE DOMÍNIO coladas neste briefing e as
  regras do projeto PREVALECEM sobre preferences/reasoning.
- Estratégia de teste/validação escolhida pela matriz do §2. Para APIs externas, fundamente na
  Context7 para a versão observada; documentação oficial atual é fallback, nunca memória.
- Raciocínio: quando a tarefa envolve incerteza, decisão ou diagnóstico, a técnica dominante
  sugerida de `pelizzai-reasoning` (decomposição, RCA, comparação, verification — ver a matriz da
  skill); omita para tarefa mecânica de contrato claro — não imponha técnica sem gatilho.
- Perfil de review registrado no plano: `split` (default) ou `combined` ratificado, com a
  justificativa de risco.
- O formato de retorno esperado e o status (ver abaixo), incluindo o campo obrigatório
  `Desvios do plano:` (ou `nenhum`).
- Teste operacional de desvio (frase canônica, no TEXTO do briefing):
  "se a decisão não está escrita no plano nem na spec, ela não está aprovada — apresente antes de implementar".
  Decisão técnica, de escopo ou de abordagem que surja durante a implementação e não esteja no
  plano/spec interrompe a tarefa: o membro NOMEIA a lacuna e devolve `NEEDS_CONTEXT` **com 2–3
  opções e a recomendada** (porquê em uma linha); nunca é preenchida em silêncio nem devolvida como
  pergunta aberta sem opções. Quem leva a lacuna ao humano é o coordenador, por
  `pelizzai-interview-me` no modo lacuna (§0) — o membro não conversa com o usuário.
- Salvo-conduto de escalada (frase canônica, no TEXTO do briefing): "É sempre OK parar e dizer
  'isso é difícil demais para mim'. Trabalho ruim é pior que trabalho nenhum. Você não será
  penalizado por escalar (reporte BLOCKED)."
```

Responda às perguntas do membro **antes** de o trabalho começar; re-despache se faltar contexto.

## 2. Escolher a estratégia pelo artefato

Não force TDD onde não existe comportamento executável observável. O briefing declara **uma
estratégia primária** e a evidência esperada; tarefas mistas podem combinar linhas:

| Artefato / intenção | Estratégia primária | Evidência mínima |
| --- | --- | --- |
| Comportamento executável novo ou bug reproduzível | **TDD** (`pelizzai-tdd`) | RED observado → GREEN → refactor; teste de comportamento |
| Refactor ou legado sem contrato seguro | **Characterization** | comportamento atual capturado e verde antes da mudança; regressão depois |
| Config, schema, migration, script, build ou integração | **Validate** | parser/dry-run/fixture/integração real e rollback quando aplicável |
| UI, layout, estados responsivos ou interação visual | **Visual + funcional** | teste funcional quando útil + aplicação rodando, screenshots/viewport/estados via `pelizzai-frontend` |
| Docs, Markdown, prompts, policies ou artefato estático | **Static/scenario** | lint/render/link/schema/grep ou cenário de consumo; nunca teste fictício só para dizer “TDD” |

TDD é a estratégia primária quando o gate de adequação da skill passa; não basta conseguir escrever
qualquer teste. Para exclusões e mudanças puramente mecânicas, use a suíte de regressão + checks
estáticos proporcionais. O membro testa/valida, faz self-review e **não commita**.

## 3. Review proporcional com duas lentes

Toda tarefa passa pelas lentes **spec** e **qualidade**, nesta ordem, com **cegueira assimétrica**:
a lente spec julga o código às cegas contra o contrato; a lente qualidade é a lente de **evidência**
e recebe o relatório do autor para verificá-lo. O perfil decide se elas usam um ou dois despachos:

| Perfil | Quando | Execução |
| --- | --- | --- |
| `split` (default) | o caso normal, inclusive lane bounded; **obrigatório** em risco médio/alto, contrato público, segurança, dados, migração, múltiplas partes ou rejeição estrutural | estágio spec aprova antes de despachar qualidade; despachos independentes |
| `combined` (exceção ratificada) | lane bounded, risco baixo, escopo coeso, sem segurança/dados/migração/contrato público — **e** o usuário ratificou o perfil no passo 4 do Gate de setup | um reviewer e um relatório, primeiro spec e depois qualidade |

Proporcionalidade: o que varia com o risco é a **profundidade** de cada lente, não a existência do
review nem a cegueira. O perfil de **lentes separadas com cegueira** é o default em qualquer lane —
só com dois despachos a lente spec desconhece a narrativa do autor. Se o diff revelar superfície que
muda o risco, promova `combined` para `split` sem nova ratificação; rebaixar para `combined` é
sempre escolha explícita do usuário, nunca economia de uma rodada.

```text
(0) Material: gere `review-package --working-tree`; o mesmo pacote cobre staged, unstaged e
    untracked. Não use range antes de a tarefa ser commitada.
(a) Lente spec (CEGA): recebe SOMENTE o diff + a spec/plano da tarefa + as domain skills da área.
    O revisor da lente spec NÃO recebe o relatório do implementador — julga o código contra o contrato, sem a narrativa do autor.
    É ADVERSARIAL por instrução: compara implementação real vs requisitos LINHA A LINHA,
    procurando faltas, extras (escopo além do pedido) e mal-entendidos.
(b) Lente qualidade / evidência: recebe o relatório do autor e VERIFICA as alegações — testes
    rodados? prova FRESCA? desvios declarados? — além de legibilidade, design, reuso e segurança.
    Não confia cegamente no relatório: o revisor rodou de fato os checks aplicáveis ao artefato e
    colou saída + exit code. "Testes passam" inferido NÃO conta como aprovado; check que não rodou
    = UNVERIFIED, nunca ✅.
```

Aprovação exige **os dois** verdicts: spec ✅ **e** qualidade ✅, estejam no mesmo relatório ou em
estágios separados. No perfil `combined` a assimetria é lógica: primeiro o julgamento cego contra o
contrato, só depois a leitura do relatório para verificar a evidência — nunca o inverso. Conflito
entre as lentes → o coordenador decide com evidência PRÓPRIA ou escala; a narrativa do autor nunca
arbitra. Itens "⚠️ não verificável" exigem avaliação do coordenador contra o plano antes de marcar
concluído.

Anti-corrupção do pipeline (regras completas na `pelizzai-review`): não instrua o reviewer sobre o que NÃO flagrar nem pré-classifique severidade; finding causado pelo próprio plano sobe ao humano; Minors acumulam num ledger triado no review final; os findings do review final são corrigidos por UM único fixer.

## 4. Status do membro

O membro reporta um destes status:

| Status               | Significado                                   | Conduta do coordenador                                         |
| -------------------- | --------------------------------------------- | -------------------------------------------------------------- |
| `DONE`               | Trabalho completo                             | Segue para o review                                            |
| `DONE_WITH_CONCERNS` | Completo, mas com ressalvas                   | Leia as ressalvas antes de prosseguir; lacuna de domain skill vai ao registro e é acumulada para o eixo adoption-driven no fechamento (não vira gate por tarefa) |
| `NEEDS_CONTEXT`      | Falta informação **ou** lacuna material nomeada | Contexto que você tem (está no plano/spec): forneça e re-despache. Lacuna material (decisão do usuário): consolide e leve ao humano por `pelizzai-interview-me` antes de a frente continuar — consolidar não é decidir (§0) |
| `BLOCKED`            | Não consegue concluir                         | Avalie: dar contexto → mudar abordagem/quebrar tarefa → escalar ao humano (o modelo já é o topo — ver §8) |

Todo relatório de tarefa — em qualquer status — inclui o campo obrigatório **`Desvios do plano:`**
(ou `nenhum`): decisões técnicas, de escopo ou de abordagem que saíram do que o plano/spec
escreveram, com a justificativa de cada uma. O coordenador **confere esse campo antes de aceitar
`DONE`**: desvio material não ratificado não vira concluído — pelo teste operacional de desvio, volta
ao usuário pela `pelizzai-interview-me` (modo lacuna, §0) antes do review, nunca é absorvido em
silêncio e nunca é ratificado pelo próprio coordenador.

Nunca ignore uma escalação nem re-despache sem mudar nada.

## 5. Circuit breaker do loop de review

```text
- Limite: 3 ciclos de fix→re-review POR LENTE, POR TAREFA. No perfil `combined`, use um contador
  compartilhado; promova para `split` se ficar incerto qual lente está falhando.
- A mesma issue rejeitada 2x → escala na 2ª.
- Rejeição estrutural ("a abordagem está fundamentalmente errada") → escala imediatamente.
- Resets (não desista cedo demais): zere o contador de spec ao spec ✅, o de qualidade ao
  qualidade ✅, e AMBOS ao iniciar uma nova tarefa — um loop na Tarefa N não afeta a N+1.
- NÃO conta como ciclo (evita falso positivo): BLOCKED (já é escalação, nunca tally);
  DONE_WITH_CONCERNS cujas ressalvas são observações e o review passa; implementador que
  CONTESTA a rejeição ("o revisor diz que falta X, mas está na linha Y") → trate como
  NEEDS_CONTEXT e reconfirme com o revisor (revisores são subagentes e erram).
- Ao estourar o limite: pare de despachar; grave `phase: blocked` no state consumidor ou execution
  record nativo. No consumidor, registre em `## Progresso` → `pending` o bloqueio (tarefa, estágio,
  nº de ciclos falhos, os motivos de rejeição distintos
  EM ORDEM, os fixes tentados e o padrão: issues independentes / mesma issue recorrente /
  conflito estrutural); commite SÓ o cursor no consumidor (source mode não cria commit de cursor); escale ao
  humano com uma mensagem ACIONÁVEL (o que foi feito + cada motivo + fixes + padrão + opções:
  esclarecer a spec via pelizzai-writing-plans / quebrar a tarefa / revisar o plano);
  deixe a working tree INTACTA (nunca git reset --hard). Se o humano mandar continuar,
  re-despache reaproveitando o WIP — não recomece do zero.
```

## 6. Commit como gate

```text
- O membro NÃO commita. O trabalho fica na working tree até as DUAS lentes passarem.
- Só após spec ✅ e qualidade ✅ (com fixes aplicados) o COORDENADOR consolida.
- O coordenador estagia paths exatos da tarefa e, no consumidor, o state; inspeciona
  `git diff --cached` e nunca usa `git add -A`.
- Para permitir reutilização segura do review em uma entrega bounded de tarefa única, exija que não
  reste conteúdo unstaged/untracked da tarefa, capture `reviewed-tree = git write-tree` antes do
  commit e compare depois com `git rev-parse HEAD^{tree}`. Divergência invalida a reutilização.
- Granular: um commit DEFINITIVO por tarefa. No consumidor, o toque do cursor entra no MESMO
  commit; em source mode, o execution record nativo avança sem arquivo. O histórico é mantido.
- Squash-final: um commit de TRABALHO por tarefa (`wip(<slug>): <tarefa>`) — nunca acumule a
  working tree inteira sem commit até o fim (um crash perderia tudo). Depois das tarefas e
  overlays, a `pelizzai-execution-plans` consolida os WIP num único commit **antes** do review
  final e de `validated-head`. A `pelizzai-finish-task` não reescreve histórico. No consumidor o
  cursor entra no WIP; em source mode não existe commit de cursor.
```

## 7. Avançar o cursor

No consumidor, antes do commit da tarefa atualize `pelizzai/data/state.md` (em `## Progresso`,
acrescente **uma linha** `T<n> ✅ <sha|data> — <nota ≤1 linha>` — relatório longo vai para
`pelizzai/data/reports/` com só o link —, ajuste `next` e `pending`, mantenha `phase: exec`) e
inclua-o no stage junto aos paths exatos da tarefa. O commit definitivo (granular) ou wip
(squash-final) carrega o cursor — inclusive na Tarefa 1, que leva junto o state gravado no setup:
**não existe commit só de metadata para iniciar a tarefa**. Ao concluir o plano e selar o conteúdo, a
`pelizzai-finish-task` sela `phase: delivered` no único closure commit metadata-only, migrando o
bloco íntegro da tarefa para `data/history/` — o cursor volta ao tamanho do template e `done` é
constatado depois.

Em source mode, avance o execution record nativo após o commit e não crie state/closure.

## 8. Seleção de modelo por papel

Política do harness: membros, revisores e o coordenador usam o **modelo mais capaz disponível, com
effort/reasoning no nível máximo** — nunca rebaixe modelo nem effort para economizar, em nenhum
papel e em nenhuma tarefa. **Arquitetura, os reviews (as duas lentes e o review final) e a validação
final da entrega são inegociavelmente o topo.** Especifique o modelo e o effort explicitamente para
não herdar um default menor da sessão.

Proporcionalidade continua valendo — só que em profundidade de processo (entrevista, brainstorming,
TDD, perfil de review, overlays), nunca em capacidade do modelo. Tarefa mecânica se resolve rodando
menos processo no topo, não rodando um modelo menor.

Como já se parte do topo, “subir o modelo” não é um degrau de escalada: os degraus do BLOCKED são
dar mais contexto → mudar a abordagem/quebrar a tarefa → escalar ao humano. Corrija primeiro
contexto, ferramenta ou decomposição. O coordenador registra preocupações, não finge certeza.
