---
name: pelizzai-brainstorming
description: Explora e ratifica design antes de implementar um produto/projeto greenfield ou feature, refactor e mudança estrutural com trade-offs, requisitos, arquitetura, UX, dados ou risco ainda abertos. Greenfield usa modo completo mesmo com stack definida; mudança existente pode usar modo compacto. Não use para design já aprovado, ajuste trivial ou bug em investigação.
---

# PelizzAI Brainstorming

## Objetivo

Transformar intenção em design decidido pelo usuário antes da implementação. A skill investiga,
expõe alternativas e recomenda; nunca preenche uma decisão de produto para ganhar velocidade.

**Anuncie:** "Usando a skill PelizzAI Brainstorming em modo `<compacto|completo>` para resolver as decisões de design antes de implementar."

<HARD-GATE>
NÃO acione skill de implementação, não escreva código, não crie scaffold e não tome nenhuma ação de
implementação até ter apresentado o design e o usuário tê-lo aprovado. **Isso se aplica a TODOS os
projetos, independentemente da simplicidade aparente** — o design pode ser curto (algumas frases num
escopo realmente simples), mas precisa ser apresentado e aprovado.

A única saída é anterior a esta skill: correção pontual e lane `bounded` já especificada pelo usuário
são resolvidas pelo `pelizzai-router` ANTES do brainstorming (ver Pré-condições). Uma vez dentro
desta fase, a regra vale integralmente — "é simples demais para precisar de design" não é
justificativa, é o antipadrão que a regra existe para barrar.
</HARD-GATE>

## Pré-condições

- O router já classificou efeito, risco, incerteza e overlays.
- Para qualquer escrita de spec/ADR/protótipo, a task/planning branch já existe.
- Na lane `bounded` de um produto existente, com objetivo, aceite e abordagem já fornecidos pelo
  usuário, volte ao router e siga sem brainstorming. Greenfield nunca usa essa exceção.
- Nas lanes `standard`/`exploratory` nenhuma implementação começa antes de a spec de design existir e ter sido apresentada na borda de design — salvo dispensa explícita do usuário. A profundidade escala pela lane (enxuta no `standard` de aceite claro, completa no `exploratory`); o classificador não conclui sozinho "não há trade-off, pulo a spec".

## Escolher profundidade

| Modo | Quando | Saída |
| --- | --- | --- |
| `compacto` | incerteza média, poucas decisões, escopo coeso | contexto focal → design curto → uma aprovação → spec enxuta. |
| `completo` | alta incerteza, arquitetura aberta ou decisões sensíveis acopladas | exploração, alternativas reais, stress proporcional, spec detalhada. |

Produto/projeto greenfield sempre começa em `completo`. Informar qualquer combinação de linguagem,
framework, runtime, banco, serviço ou plataforma reduz incerteza técnica, mas não resolve atores,
jornadas, estados, regras, exceções nem aceite.

Complexidade visual ou número de arquivos não basta para escolher modo; use custo de decisão errada e incerteza real. Em `standard`/`exploratory` a spec é o artefato-padrão: o modo escolhe a profundidade da spec (enxuta vs completa), não se ela existe.

## Fluxo comum

### 1. Explorar contexto focal

Leia apenas o necessário para responder:

```text
- Onde a mudança se encaixa?
- Quais contratos/padrões existentes ela precisa preservar?
- Há prior art de teste e implementação?
- Quais decisões já estão registradas em ADR/out-of-scope?
- Quais skills de domínio e overlays se aplicam?
```

Use subagent read-only somente quando a busca tem frentes independentes. Não faça repo scan completo por reflexo.

Quando tecnologia externa afetar viabilidade ou opções, identifique a versão em manifests/lockfiles
e consulte Context7 antes de formular a pergunta correspondente. Em greenfield sem dependências
instaladas, consulte a documentação atual da stack informada ou das candidatas que pretende
recomendar. Use essa evidência para descartar opções incompatíveis e explicar trade-offs; a escolha
continua no gate do usuário.

### 2. Fixar objetivo e fronteiras

Defina:

- resultado e usuário/consumidor;
- critérios de aceite observáveis;
- fora de escopo;
- restrições e compatibilidade;
- decisões reversíveis vs difíceis de reverter.

Consulte evidência antes de perguntar para não pedir fatos já observáveis. Para decisões do usuário,
faça **uma pergunta por vez**, mesmo quando pareçam independentes: a resposta pode alterar prioridade,
vocabulário e opções das seguintes. Cada turno de descoberta contém:

```text
Decisão: <por que isso muda a solução>
Opções reais: <2–3 quando ajudarem>
Recomendação: <melhor opção> — <motivo em uma linha>
Pergunta: <uma única pergunta>
```

Pergunta aberta é válida quando opções enviesariam a resposta. Nunca esconda uma decisão dentro de
uma “premissa segura”.

### 3. Conduzir a descoberta quando houver lacuna material

Quando contexto e objetivo revelarem lacunas de escopo, UX, arquitetura, segurança ou dados, não as
resolva por suposição. Ordene internamente as lacunas por dependência e impacto, mas apresente
somente a próxima decisão. Exemplo:

```text
Encontrei decisões de produto ainda abertas. A primeira condiciona as demais:

Decisão: <lacuna> — muda <escopo|UX|arquitetura|segurança|dados>.
Opções: A) <...> · B) <...> · C) <...>.
Recomendação: <B> — <motivo>.
Pergunta: qual opção você escolhe?
```

O turno para após a pergunta. Silêncio, recomendação e Context7 não valem como resposta. Depois da
escolha, registre a decisão, recalcule as lacunas e faça somente a próxima pergunta. Pular a
descoberta inteira exige pedido explícito; nesse caso, não invente respostas: registre as decisões
não tomadas como limitações e confirme se ainda existe uma spec implementável.

Não reabra o que o gate de kickoff do router já ratificou: agrupe apenas as lacunas materiais ainda em aberto. Em `bounded` sem lacuna material, o gate não aparece.

Sob briefing fechado (SUBAGENT-STOP), não produza análises de rota nem abra gates: aplique o briefing e escale ao coordenador o que exigir decisão.

### 4. Explorar alternativas quando existirem

Apresente 2–3 abordagens somente se forem realmente válidas e materialmente diferentes. Compare
pelo que importa e recomende uma. Peça a escolha do usuário antes de incorporá-la ao design.

Se há uma única abordagem compatível com os contratos, explique-a diretamente; não invente alternativas para cumprir ritual.

### 5. Desenhar a solução

Cubra proporcionalmente:

```text
responsabilidades e fronteiras
interfaces/contratos e fluxo de dados
estados e tratamento de erro
compatibilidade/migração/rollback quando aplicável
estratégia de validação e seams reais
observabilidade/security quando o risco exigir
```

Para UI, aplique o overlay `pelizzai-frontend` já no design: fluxo real, estados, conteúdo, sistema existente, acessibilidade e direção visual. Isso não autoriza implementar antes da aprovação.

Para módulos, use `pelizzai-codebase-design` apenas quando fronteiras/seams ainda são uma decisão. Para domínio, use `pelizzai-domain-modeling` quando o vocabulário/ADR realmente mudar — não para apenas ler o glossário.

### 6. Stress proporcional

Ao estressar o design, cace ATIVAMENTE as lacunas e apresente-as como lista numerada — não deixe uma passar só porque o usuário não a citou. Procure apenas as falhas plausíveis para a superfície real:

```text
casos não tratados e estados indefinidos
validação ausente
falha de autorização/segurança ou exposição de dados
compatibilidade/migração/rollback
premissa de escala ou integração não confirmada
contradição entre spec, plano e código
```

Modo completo/greenfield: o stress com `pelizzai-interview-me` é **OBRIGATÓRIO**, não uma oferta.
Anuncie na linguagem do usuário ("vou te entrevistar para estressar este design e expor os pontos
fracos antes de seguir") e conduza a entrevista. Toda nova decisão que pertence ao usuário volta como
uma pergunta por vez, com recomendação. Cada lacuna é resolvida, explicitamente aceita ou convertida
em tarefa de investigação antes de sair da borda de design.

Modo compacto: faça uma passada curta de contraexemplos. Escale para entrevista somente se encontrar ambiguidade material.

Não exija stress duas vezes sobre as mesmas decisões. Writing Plans testa executabilidade do plano,
sem reabrir o design aprovado salvo evidência nova.

### 7. Aprovar na borda certa

Apresente o design inteiro em tamanho proporcional e faça **uma pergunta de aprovação** na borda.
Em greenfield/`standard`/`exploratory`, a spec é o artefato apresentado antes de qualquer plano ou
implementação. O usuário aprova, pede ajuste ou dispensa explicitamente; a dispensa fica registrada.

O usuário não precisa aprovar cada parágrafo, cada seam e depois o mesmo conteúdo na spec.

### 8. Persistir a spec

A spec é o artefato-padrão de `standard`/`exploratory`; produza-a por default e use `templates/spec.md` na escala da lane (enxuta no `standard`, completa no `exploratory`). Pular a spec é decisão do usuário, registrada no state/execution record — nunca do classificador. Depois da aprovação:

- consumidor: salve em `pelizzai/specs/AAAA-MM-DD-<topico>-design.md` na task branch;
- source mode: registre o design no plano/execution record nativo, sem criar `pelizzai/`, de forma verificável no record; ofereça materializar como arquivo no caminho nativo do repo quando o usuário quiser durabilidade;
- arquivo versionado no repo-fonte só quando for um artefato explicitamente pedido, no caminho
  nativo do projeto e depois do gate de primeira escrita.

Inclua somente conteúdo durável (ver `templates/spec.md`):

```text
Objetivo e critérios de aceite
Contexto/constraints relevantes
Design e contratos
Estados/falhas/segurança aplicáveis
Testing & Validation Decisions
Fora de escopo
Decisões difíceis de reverter
```

Registre ADR apenas para decisão aprovada que seja difícil de reverter, surpreendente sem contexto e carregue trade-off real. A spec pode apontar para o ADR; não duplique a explicação inteira.

Faça autoavaliação inline: placeholders, contradições, ambiguidade, scope creep e requisitos não verificáveis. Corrija o documento; não crie um ritual separado.

### 9. Transição

- Fluxo normal: entregue a spec aprovada a `pelizzai-writing-plans`.
- Projeto novo — checklist de fechamento da borda de design, cada passo obrigatório antes de sair do design:
  1. Design aprovado → acione `pelizzai-audit` (Gate proativo de domain skills): proponha o conjunto para a stack decidida, com context7; a decisão é do usuário.
  2. Crie somente as ratificadas e registre no catálogo/ledger.
  3. Siga para `pelizzai-writing-plans` quando o pedido original inclui construir o produto; pare após design/bootstrap apenas quando esse era o escopo pedido.

## Protótipos

Use `pelizzai-prototype` apenas quando uma pergunta de estado/lógica/forma visual não pode ser respondida economicamente por análise. O protótipo:

- nasce na task branch ou em diretório efêmero ignorado;
- responde uma pergunta explícita;
- não recebe polish/abstração de produção;
- é absorvido ou removido antes da validação final.

## Visual Companion

Ofereça somente quando o usuário entenderá melhor vendo do que lendo. Exemplos: wireframes, layouts, diagramas ou comparações visuais. Não o use para escolhas textuais ou requisitos.

Oferta curta:

> "Esta decisão fica mais clara visualmente. Quer que eu abra um companion com as opções?"

Se aceitar, leia [visual-companion.md](visual-companion.md), use apenas flags documentadas/testadas e encerre a sessão ao fechar a fase.

## Anti-padrões

```text
- Brainstorming completo para feature bounded.
- Tratar projeto greenfield como bounded porque a stack foi informada.
- Repo scan completo sem pergunta concreta.
- Pergunta cuja resposta já está no código/spec.
- Sempre inventar três alternativas.
- Fazer várias perguntas de descoberta no mesmo turno.
- Oferecer uma recomendação e tratá-la como escolha do usuário.
- Interview obrigatório em design de baixa incerteza.
- Tratar o stress com `pelizzai-interview-me` como oferta opcional em greenfield/modo completo.
- Implementar, scaffoldar ou "só adiantar" código antes da aprovação do design, alegando simplicidade.
- Escrever spec/protótipo antes da task branch.
- Usar frontend só como QA tardio em vez de overlay de design.
- Reabrir decisão aprovada sem evidência nova.
- Assumir em silêncio decisão de escopo/UX/arquitetura com lacuna material em vez de propor a descoberta.
- Usar Context7 para inventar requisito, persona, regra de negócio ou critério de aceite.
- Suprimir a spec de uma lane standard/exploratory sem dispensa explícita do usuário.
- Fechar a borda de design em projeto novo sem apresentar a proposta de domain skills.
```

## Definition of Done

```text
[ ] lacunas materiais foram expostas e cada uma está resolvida ou explicitamente aceita;
[ ] modo completo/greenfield: o stress com `pelizzai-interview-me` aconteceu e o design foi aprovado
    pelo usuário antes de qualquer ação de implementação;
[ ] critérios de aceite e fora de escopo são verificáveis;
[ ] overlays e estratégia de validação estão identificados;
[ ] standard/exploratory: a spec proporcional foi produzida por default e apresentada na borda, ou
    o usuário a dispensou explicitamente (dispensa registrada); consumidor salva na task branch,
    source mode registra no execution record nativo sem runtime consumidor;
[ ] projeto novo: a proposta de domain skills da stack foi apresentada na borda (Gate proativo da
    `pelizzai-audit`) antes de seguir para o plano, e a decisão do usuário está registrada;
[ ] a próxima skill recebe contexto suficiente sem repetir a entrevista.
```
