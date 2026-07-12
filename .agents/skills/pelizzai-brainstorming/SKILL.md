---
name: pelizzai-brainstorming
description: Explora design antes de implementar quando uma feature, refactor ou mudança estrutural ainda possui trade-offs, requisitos incertos, arquitetura, UX ou risco que exige descoberta. Use em modo compacto para decisões limitadas e completo para alta incerteza ou decisões sensíveis acopladas. O gatilho é a lacuna material: sem ela — design aprovado, feature bounded com objetivo e aceite claros, ajuste trivial ou bug com causa já investigada — não use.
---

# PelizzAI Brainstorming

## Objetivo

Resolver as decisões que seriam caras de descobrir durante a implementação, sem transformar toda feature em workshop.

**Anuncie:** "Usando a skill PelizzAI Brainstorming em modo `<compacto|completo>` para resolver as decisões de design antes de implementar."

## Pré-condições

- O router já classificou efeito, risco, incerteza e overlays.
- Para qualquer escrita de spec/ADR/protótipo, a task/planning branch já existe.
- Na lane `bounded` com objetivo, aceite e abordagem claros e risco baixo, volte ao router e siga sem brainstorming; a oferta de uma spec curta cabe ao gate do plano, não a uma exploração forçada aqui.
- Nas lanes `standard`/`exploratory` nenhuma implementação começa antes de a spec de design existir e ter sido apresentada na borda de design — salvo dispensa explícita do usuário. A profundidade escala pela lane (enxuta no `standard` de aceite claro, completa no `exploratory`); o classificador não conclui sozinho "não há trade-off, pulo a spec".

## Escolher profundidade

| Modo | Quando | Saída |
| --- | --- | --- |
| `compacto` | incerteza média, poucas decisões, escopo coeso | contexto focal → design curto → uma aprovação → spec enxuta. |
| `completo` | alta incerteza, arquitetura aberta ou decisões sensíveis acopladas | exploração, alternativas reais, stress proporcional, spec detalhada. |

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

### 2. Fixar objetivo e fronteiras

Defina:

- resultado e usuário/consumidor;
- critérios de aceite observáveis;
- fora de escopo;
- restrições e compatibilidade;
- decisões reversíveis vs difíceis de reverter.

Consulte evidência antes de perguntar. Agrupe perguntas independentes numa mensagem curta; pergunte uma por vez apenas quando a resposta muda a próxima pergunta. Prefira uma recomendação com opção de ajuste a menus artificiais.

### 3. Propor descoberta quando houver lacuna material

Quando o contexto e o objetivo revelam lacunas materiais que mudam escopo, UX, arquitetura, segurança ou dados, não as resolva por suposição silenciosa. Reúna TODAS as lacunas materiais ainda em aberto em UMA única mensagem — nunca pulverizada — e apresente o gate:

```text
**Propor descoberta — encontrei N lacunas materiais (responda escolhendo A, B ou C):**
1. <lacuna> → muda <escopo|UX|arquitetura|segurança|dados>
2. <lacuna> → muda <...>
Recomendo <A: descoberta agora — as lacunas mudam a solução>.
A) Fazer a descoberta agora (stress focal ou `pelizzai-interview-me`).
B) Prosseguir com estas premissas declaradas: <lista> (eu assumo e sigo).
C) Você responde estas N perguntas agora.
```

O gate PARA o turno e exige uma escolha afirmativa. O default recomendado é destacado, nunca auto-confirmado: silêncio ou ausência de resposta não valem como decisão, e a opção B jamais é executada sozinha sobre lacuna material. **A decisão de pular a descoberta é do usuário**, não do classificador; a escolha de B, com as premissas visíveis, é a própria ratificação de seguir sem descoberta.

Não reabra o que o gate de kickoff do router já ratificou: agrupe apenas as lacunas materiais ainda em aberto. Em `bounded` sem lacuna material, o gate não aparece.

Sob briefing fechado (SUBAGENT-STOP), não produza análises de rota nem abra gates: aplique o briefing e escale ao coordenador o que exigir decisão.

### 4. Explorar alternativas quando existirem

Apresente 2–3 abordagens somente se forem realmente válidas e materialmente diferentes. Compare pelo que importa à tarefa: simplicidade, risco, manutenção, migração, performance, UX e reversibilidade.

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

Modo completo, ou descoberta aceita no gate: proponha `pelizzai-interview-me` quando restarem premissas materiais abertas sobre autorização, dados, falhas, estados ou rollout. Cada lacuna encontrada é resolvida, explicitamente aceita pelo usuário, ou convertida em tarefa de investigação antes de sair da borda de design. Risco alto com contrato explícito recebe challenge focal de ameaça/rollback; não invente uma entrevista genérica nem reabra decisões fechadas.

Modo compacto: faça uma passada curta de contraexemplos. Escale para entrevista somente se encontrar ambiguidade material.

Não exija stress interview duas vezes sobre as mesmas decisões. Writing Plans testa executabilidade do plano, não reabre o design aprovado sem evidência nova.

### 7. Aprovar na borda certa

Apresente o design inteiro em tamanho proporcional e peça uma aprovação na borda de design. Nas lanes `standard`/`exploratory`, a spec (enxuta ou completa) é o artefato apresentado nessa borda antes de qualquer implementação; o usuário aprova, pede ajuste ou dispensa a spec explicitamente — e a dispensa fica registrada. Em solução longa, valide uma seção intermediária somente se a resposta puder mudar as seguintes.

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
- Bootstrap de projeto novo: entregue o design a `pelizzai-writing-skills` para criar somente domain skills justificadas; não crie plano automaticamente.

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
- Repo scan completo sem pergunta concreta.
- Pergunta cuja resposta já está no código/spec.
- Sempre inventar três alternativas.
- Aprovação após cada seção sem dependência real.
- Interview obrigatório em design de baixa incerteza.
- Escrever spec/protótipo antes da task branch.
- Usar frontend só como QA tardio em vez de overlay de design.
- Reabrir decisão aprovada sem evidência nova.
- Assumir em silêncio decisão de escopo/UX/arquitetura com lacuna material em vez de propor a descoberta.
- Suprimir a spec de uma lane standard/exploratory sem dispensa explícita do usuário.
```

## Definition of Done

```text
[ ] lacunas materiais foram expostas e cada uma está resolvida ou explicitamente aceita;
[ ] critérios de aceite e fora de escopo são verificáveis;
[ ] overlays e estratégia de validação estão identificados;
[ ] standard/exploratory: a spec proporcional foi produzida por default e apresentada na borda, ou
    o usuário a dispensou explicitamente (dispensa registrada); consumidor salva na task branch,
    source mode registra no execution record nativo sem runtime consumidor;
[ ] a próxima skill recebe contexto suficiente sem repetir a entrevista.
```
