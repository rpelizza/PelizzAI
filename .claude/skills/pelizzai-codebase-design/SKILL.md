---
name: pelizzai-codebase-design
description: Vocabulário compartilhado para projetar módulos profundos. Use quando o usuário quer projetar ou melhorar a interface de um módulo, achar oportunidades de aprofundamento, decidir onde fica um seam (costura), tornar o código mais testável ou navegável, ou quando outra skill (`pelizzai-tdd`, `pelizzai-brainstorming`, `pelizzai-writing-plans`) precisa do vocabulário de módulos profundos. Acione ao desenhar interfaces, definir fronteiras de unidades, ou avaliar testabilidade.
---

# PelizzAI Codebase Design

Projete **módulos profundos**: muito comportamento atrás de uma interface pequena, num seam limpo, testável pela própria interface. Use esta linguagem e estes princípios sempre que houver código sendo desenhado ou reestruturado. O objetivo é alavancagem para quem chama, localidade para quem mantém e testabilidade para todos.

**Anuncie ao iniciar (quando acionada explicitamente):** "Usando a skill Pelizzai Codebase Design para projetar módulos profundos."

## Glossário

Use estes termos **exatamente** — não troque por "componente", "serviço", "API" ou "boundary". A linguagem consistente é o ponto.

```text
- Módulo: qualquer coisa com interface e implementação. Escala-agnóstico: função, classe, pacote, fatia.
- Interface: tudo o que quem chama precisa saber para usar corretamente — assinatura de tipo, mas também
  invariantes, ordem, modos de erro, config necessária, características de desempenho. (Mais amplo que "assinatura".)
- Implementação: o que está dentro do módulo. Distinta de Adapter.
- Profundidade (Depth): alavancagem na interface — quanto comportamento se exercita por unidade de interface
  que se precisa aprender. PROFUNDO = muito comportamento atrás de interface pequena; RASO = interface quase
  tão complexa quanto a implementação (evite).
- Seam (Michael Feathers): lugar onde dá para alterar comportamento sem editar ali; a LOCALIZAÇÃO da interface.
  Onde colocar o seam é uma decisão de design distinta do que vai atrás dele. (Use "seam", não "boundary".)
- Adapter: coisa concreta que satisfaz uma interface num seam (papel, não substância).
- Alavancagem (Leverage): o que quem chama ganha com profundidade — uma implementação paga em N call sites e M testes.
- Localidade (Locality): o que quem mantém ganha — mudança, bug, conhecimento e verificação concentram num lugar.
```

## Profundo vs raso

```text
Módulo PROFUNDO = interface pequena + muita implementação (poucos métodos, params simples, complexidade escondida).
Módulo RASO     = interface grande + pouca implementação (só repassa) — EVITE.

Ao desenhar a interface, pergunte:
- Dá para reduzir o número de métodos?
- Dá para simplificar os parâmetros?
- Dá para esconder mais complexidade dentro?
```

## Princípios

```text
- Profundidade é propriedade da INTERFACE, não da implementação. Um módulo profundo pode ter partes internas
  pequenas e mockáveis — elas só não fazem parte da interface (seams internos vs o seam externo).
- Teste da deleção: imagine apagar o módulo. Se a complexidade some, era um pass-through; se reaparece nos N
  callers, ele pagava o próprio custo.
- A interface é a superfície de teste. Quem chama e quem testa cruzam o mesmo seam. Se você quer testar ALÉM da
  interface, o módulo provavelmente tem a forma errada.
- Um adapter = seam hipotético. Dois adapters = seam real. Não crie um seam sem algo que de fato varie nele.
```

## Projetando para testabilidade

```typescript
// Testável: recebe a dependência          // Difícil: cria a dependência
function processOrder(order, gateway) {}    function processOrder(order) { const g = new StripeGateway() }

// Testável: retorna resultado               // Difícil: efeito colateral
function calcularDesconto(cart): Desconto {} function aplicarDesconto(cart): void { cart.total -= d }
```

Superfície pequena: menos métodos = menos testes; menos params = setup de teste mais simples.

## Projetar a interface duas vezes

Quando a forma da interface é incerta e o impacto é alto, **projete-a de várias maneiras radicalmente diferentes** e compare por profundidade, localidade e posição do seam. Use a `pelizzai-team`/`pelizzai-subagents` para gerar as alternativas em paralelo e a `pelizzai-reasoning` (*Tree of Thoughts* / *Decision Making*) para escolher.

## Integração

**Usada por:** `pelizzai-tdd` (planejamento — módulos profundos e testabilidade), `pelizzai-brainstorming` (isolamento e clareza), `pelizzai-writing-plans` (estrutura de arquivos).

**Combina com:** `pelizzai-reasoning` (Structured Decomposition, Decision Making), `pelizzai-domain-modeling` (o vocabulário do domínio que nomeia esses módulos).
