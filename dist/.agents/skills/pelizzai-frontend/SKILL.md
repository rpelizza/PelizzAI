---
name: pelizzai-frontend
description: Use para qualquer trabalho de frontend/UI no PelizzAI: criar ou alterar páginas, componentes, fluxos, estados visuais, dashboards, formulários, landing pages, design systems, CSS, responsividade, acessibilidade, microinterações e QA visual. Acione especialmente quando a tarefa menciona "frontend", "UI", "tela", "componente", "layout", "estilizar", "melhorar visual", "responsivo", "Figma", "design", "evitar AI slop" ou quando uma tarefa de execução tocar a experiência do usuário.
---

# PelizzAI Frontend

## Objetivo

Entregar interfaces que pareçam projetadas por alguém que entendeu o produto, o usuário e a base de código. Evite "AI slop": UI bonita de longe, mas genérica, sem função clara, cheia de placeholders, gradientes automáticos, cards decorativos, dados falsos, estados incompletos, texto vago e responsividade quebrada.

Esta skill não é só estética. Ela é um gate de produto, implementação e verificação visual.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Frontend para desenhar, implementar e verificar a experiência de UI."

---

## Princípio central

> Uma boa interface nasce de evidência. Primeiro entenda o produto existente, depois escolha uma direção visual específica, implemente com os padrões reais do projeto e só declare pronto após ver a tela funcionando.

Frontend aceitável precisa passar por quatro provas:

```text
1. Produto: resolve o fluxo real do usuário, com conteúdo realista e estados completos.
2. Sistema: respeita stack, componentes, tokens, rotas, dados e convenções existentes.
3. Design: tem direção visual própria, coerente com o domínio, sem clichês automáticos de IA.
4. Verificação: foi visto na menor matriz de navegador/viewports capaz de revelar a falha provável.
```

### Precedência: intenção aprovada vence heurística

Instrução explícita do usuário, spec/Figma aprovado, brand guide e design system do produto prevalecem sobre as preferências e proibições **default** desta skill. Anti-slop não significa apagar uma direção intencional: gradiente, glassmorphism, raio grande, hero ou outra escolha normalmente suspeita continuam válidos quando fazem parte do sistema aprovado e servem ao fluxo.

Quando não houver direção aprovada, as regras abaixo impedem defaults genéricos de IA. Quando houver, execute-a com fidelidade, use os tokens/componentes reais e sinalize somente conflito funcional, acessível ou técnico — não redesenhe por gosto pessoal.

---

## Fluxo obrigatório

### 1. Ler o contexto antes de desenhar

Antes de escrever UI:

```text
[ ] Identifique stack, rotas, framework, biblioteca de componentes, CSS, ícones e testes.
[ ] Leia telas/componentes vizinhos que resolvem problemas semelhantes.
[ ] Encontre tokens existentes: cores, spacing, radius, fontes, sombras, breakpoints.
[ ] Entenda de onde vêm os dados reais: API, store, props, loader, form state, mocks de teste.
[ ] Procure estados já padronizados: loading, empty, error, disabled, selected, success.
```

Se houver design system ou componentes locais, use-os. Só crie componente visual novo quando os existentes não resolverem o caso ou quando a tarefa pedir uma nova linguagem.

Em app existente, a primeira obrigação é continuidade. Diferenciação visual não autoriza quebrar navegação, densidade, vocabulário ou padrões que o usuário já aprendeu.

### 2. Definir a direção visual em uma frase

Antes de codar, formule uma tese específica:

```text
"Esta tela deve parecer <qualidade visual> porque o usuário precisa <objetivo real> em um contexto de <domínio/pressão/ritmo>."
```

Exemplos bons:

```text
- "Painel operacional compacto e calmo, porque gestores voltam a ele muitas vezes por dia para decidir rápido."
- "Editor editorial, arejado e tipográfico, porque o usuário precisa comparar versões longas sem fadiga."
- "Fluxo financeiro austero, com contraste forte e feedback explícito, porque erro de entrada tem custo alto."
```

Exemplos ruins:

```text
- "Moderno e clean."
- "Premium com gradiente."
- "Dashboard bonito."
```

Quando a tarefa vier de `pelizzai-brainstorming` ou de uma especificação/tela/Figma aprovada, a
direção visual já aprovada prevalece: execute-a com fidelidade. Alteração local herda essa direção
sem gate; não invente uma nova tese estética nem uma nova personalidade no meio da execução.

**Gate de direção visual (redesign ou tela nova, antes de implementar):** sem direção aprovada, uma
tela nova ou um redesenho não começa por suposição silenciosa — a tese é apresentada e ratificada
antes de escrever UI. Ler produto e sistema e propor a direção continua sendo seu trabalho (a
inteligência é preservada); a direção, o dark mode, os gráficos/métricas e o layout viram
recomendação a ratificar, não decisão aplicada em silêncio.

```text
Direção visual proposta (responda "ok" ou ajuste):
- Recomendada: <tese em 1 frase> — <por que serve ao fluxo/domínio>
- Alternativas: <2-3 direções materialmente diferentes> — SOMENTE quando há ambiguidade estética real
- Decisões duráveis: <dark mode | gráficos/métricas exibidos | densidade/layout> — recomendação por item
```

- Ambiguidade estética real → 2-3 direções materialmente diferentes, uma recomendada.
- Design system/brand guide já decide a linguagem → uma recomendação basta; não fabrique alternativas.
- Quando ver antes reduz retrabalho, ofereça mockups/wireframes navegáveis no navegador antes de implementar.

Sob briefing fechado (SUBAGENT-STOP), não produza análises de rota nem abra gates: aplique o briefing e escale ao coordenador o que exigir decisão.

### 3. Fazer um plano visual compacto

Para mudanças pequenas, mantenha o plano na cabeça. Para mudanças médias/grandes, registre brevemente antes de implementar:

```text
- Estrutura: hierarquia da tela, áreas primárias/secundárias, navegação.
- Componentes: quais reutilizar, quais criar, quais estados cobrir.
- Conteúdo: títulos, rótulos, CTAs, mensagens de erro/vazio.
- Tokens: cores, tipografia, spacing, radius, sombras, ícones.
- Responsividade: como a tela muda em mobile, tablet e desktop.
- Verificação: quais viewports e fluxos serão inspecionados no navegador.
```

Não apresente longas defesas estéticas ao usuário durante a execução. Use o plano para guiar decisões e só exponha quando houver trade-off material.

---

## Regras anti-slop

### Proibições fortes

Sem base explícita na spec/design system/produto, não entregue:

```text
- Hero marketing quando o pedido é uma ferramenta/app/tela operacional.
- Cards dentro de cards, seções flutuantes decorativas ou excesso de containers sem função.
- Paleta dominada por roxo/azul neon, creme/terracota, preto+verde ácido ou gradiente genérico sem justificativa do domínio.
- Orbs, blobs, bokeh, glassmorphism ou brilho difuso como decoração padrão.
- Números grandes com legendas pequenas se os números não forem o conteúdo principal real.
- Placeholders como "Lorem ipsum", "Feature 1", "User Name", "Data here" ou dados inventados em tela final.
- Texto de marketing para controles funcionais.
- Layout que só funciona no viewport em que foi escrito.
- Animações espalhadas para mascarar falta de hierarquia.
- Botões que mudam tamanho por causa de loading, ícone, hover ou texto traduzido.
- Ícones desenhados à mão quando já existe biblioteca de ícones no projeto.
```

Use dados fictícios apenas quando a tarefa for protótipo ou story/teste isolado. Mesmo assim, faça dados plausíveis para o domínio e deixe claro no código/teste que são fixtures.

### Sinais de que você está caindo em AI slop

Pare e revise se perceber:

```text
- A tela poderia servir para qualquer SaaS trocando o logo.
- As cores não têm relação com o domínio, urgência ou hierarquia da tarefa.
- O texto descreve a interface em vez de ajudar o usuário a agir.
- Quase tudo tem a mesma importância visual.
- Existem muitos efeitos, mas nenhum melhora compreensão, velocidade ou confiança.
- O estado vazio não diz o que fazer.
- O erro pede desculpas, mas não explica como resolver.
- O mobile é só a versão desktop espremida.
- O componente ignora teclado, foco, contraste ou redução de movimento.
```

---

## Design de produto

### Hierarquia e composição

Comece pelo trabalho real do usuário:

```text
1. Qual decisão ou ação a pessoa precisa tomar?
2. Qual informação ela precisa ver primeiro?
3. O que é secundário, raro ou destrutivo?
4. O que pode ficar escondido, colapsado ou fora da tela inicial?
```

Depois componha a UI:

```text
- Uma área primária clara por tela ou por painel.
- Densidade compatível com uso: operacional = compacto e escaneável; editorial = mais respiro.
- Alinhamento consistente; assimetria só quando comunica algo.
- Espaçamento com escala, não valores aleatórios.
- Divisores, labels, badges e numeração apenas quando carregam significado.
```

### Conteúdo e microcopy

Escreva como produto, não como anúncio.

```text
- Botões usam verbos específicos: "Salvar alterações", "Convidar usuário", "Gerar relatório".
- O mesmo conceito recebe o mesmo nome em toda a tela.
- Títulos dizem o que a área contém, não slogans.
- Erros dizem o que falhou e como corrigir.
- Estados vazios oferecem a próxima ação possível.
- Loading preserva layout e evita salto visual.
```

Não use texto visível para explicar a própria UI ("clique aqui para...", "este card mostra...") quando o componente pode ser autoexplicativo.

### Controles

Escolha controles pelo tipo de decisão:

```text
- Botão: comando explícito.
- Toggle/checkbox: estado binário.
- Segmented control/tabs: modos ou visões mutuamente exclusivos.
- Select/menu: conjunto fechado de opções.
- Slider/stepper/input numérico: valor ajustável.
- Swatch: cor.
- Ícone com tooltip: ação comum e compacta.
```

Use ícone + texto para ações importantes ou ambíguas. Use apenas ícone para ações reconhecíveis, com `aria-label` e tooltip quando a biblioteca oferecer.

### Estados obrigatórios

Para cada tela/componente interativo, cubra:

```text
[ ] Default
[ ] Hover/focus/active
[ ] Loading
[ ] Empty
[ ] Error
[ ] Disabled
[ ] Success/confirmation quando aplicável
[ ] Mobile
[ ] Conteúdo longo ou traduzido
[ ] Permissões/sem acesso quando aplicável
```

Se algum estado não se aplica, saiba por quê. Não deixe buraco por esquecimento.

---

## Implementação

### Seguir o projeto

Prefira padrões locais:

```text
- Componentes, hooks, stores, loaders/actions e helpers existentes.
- Tokens CSS/Tailwind/theme já definidos.
- Biblioteca de ícones já instalada, especialmente lucide quando for o padrão.
- Estratégia de formulários e validação existente.
- Padrão de testes e stories existente.
```

Não adicione biblioteca visual, fonte remota, animação pesada ou dependência de design sem necessidade clara. Se precisar, justifique pelo ganho para o produto.

### CSS e layout

Construa layouts estáveis:

```text
- Defina dimensões previsíveis para toolbars, botões, grids, cards, tiles e painéis.
- Use `minmax`, `clamp`, `aspect-ratio`, `min-height`, `max-width` e containers responsivos quando fizer sentido.
- Evite texto que estoura o container; trate wrap, truncamento ou reflow.
- Não use fonte escalada por viewport width.
- Evite letter-spacing negativo.
- Cards, quando existirem, devem seguir o radius do sistema; sem token/direção, prefira raio discreto (8px ou menos).
- Não coloque card dentro de card.
```

Controle especificidade. Prefira classes/componentes claros a cascatas que brigam entre si.

### Acessibilidade e interação

Trate acessibilidade como parte da entrega:

```text
[ ] Foco visível e ordem de tabulação lógica.
[ ] Elementos interativos com nome acessível.
[ ] Contraste suficiente para texto, ícones e estados.
[ ] Alvos clicáveis confortáveis em touch.
[ ] `prefers-reduced-motion` respeitado.
[ ] Erros de formulário associados aos campos.
[ ] Sem dependência exclusiva de cor para comunicar estado.
```

Animação deve ajudar percepção de causa, mudança de estado ou orientação espacial. Se for só enfeite, remova.

---

## Verificação visual

Não finalize mudança visual/interativa relevante apenas lendo código. A profundidade da prova segue
o que pode quebrar:

| Mudança | Prova mínima |
| --- | --- |
| Copy, label, token ou estilo local sem mudar geometria/interação | renderize a superfície afetada no viewport de maior risco; screenshot é opcional. Adicione outro viewport se houver risco de wrap, tradução ou breakpoint. |
| Layout, componente, fluxo, interação ou responsividade | desktop + mobile, estados principais e screenshot quando disponível. |

Para a segunda linha da matriz, sempre que o projeto puder rodar em navegador:

```text
1. Inicie ou use o dev server existente.
2. Abra a tela alterada.
3. Verifique pelo menos um viewport desktop e um mobile.
4. Interaja com os estados principais.
5. Corrija sobreposição, quebra de texto, layout shift, console errors e estados ilegíveis.
```

Use screenshots quando disponíveis. Olhe para a imagem como revisor visual, não como autor orgulhoso:

```text
- O primeiro olhar entende o que fazer?
- Há hierarquia clara?
- Algum texto está cortado, colado ou competindo?
- Algum elemento parece template genérico?
- O mobile mantém prioridade e legibilidade?
- Existe algo decorativo que deveria ser removido?
```

Se não for possível rodar a UI, declare isso no resultado final e compense com revisão estática: inspecione CSS, estrutura, estados e testes. Não finja verificação visual.

---

## Integração com o harness

Esta skill é **overlay obrigatório** para qualquer tarefa que altere página, componente, CSS, layout, estados visuais ou experiência de UI — independentemente de a head skill ser feature, bug ou ajuste. O router registra o overlay; `pelizzai-writing-plans` o inclui em **Skills transversais do harness** e na tarefa; o executor deve carregá-lo antes de implementar e antes de revisar.

Playwright, browser MCP e screenshots são **ferramentas** para executar a verificação desta skill, não alternativas ao seu contrato de produto, anti-slop, acessibilidade, estados e responsividade.

**Combina com:**

```text
- `pelizzai-brainstorming`: para definir especificação e direção visual antes de implementação criativa.
- `pelizzai-execution-plans`: para executar tarefas de UI dentro de planos aprovados.
- `pelizzai-tdd`: para comportamento de componentes, formulários, rotas e regressões.
- `pelizzai-review`: para revisar aderência à spec e qualidade.
- `pelizzai-verification-before-completion`: para evidência fresca antes de declarar pronto.
- Skills de domínio do projeto: para padrões reais de produto, design system e stack.
```

Em tarefa de plano, aplique esta skill dentro do ciclo da tarefa. UI não está pronta só porque compila; precisa estar testada, navegável e visualmente verificada.

---

## Definition of Done

Antes de dizer que terminou, confirme:

```text
[ ] A UI resolve o objetivo real do usuário descrito na tarefa/spec.
[ ] Usa padrões/componentes/tokens existentes ou justifica desvios.
[ ] Não contém placeholders, dados fake indevidos ou texto genérico.
[ ] Cobre estados relevantes: loading, empty, error, disabled, success.
[ ] Responsividade foi verificada nos viewports aplicáveis ao risco da mudança.
[ ] Tem foco visível, nomes acessíveis e contraste adequado.
[ ] Não tem decoração sem função nem clichês visuais automáticos.
[ ] Foi verificada no navegador/screenshot quando possível.
[ ] Testes/lint/build relevantes foram executados ou limitação foi declarada.
```

---

## Instrução final para o agente

```text
Projete a interface a partir do produto real.
Siga o sistema existente antes de inventar.
Escolha uma direção visual específica, não uma estética genérica de IA.
Implemente estados completos, responsivos e acessíveis.
Veja a tela funcionando antes de declarar pronto.
Remova qualquer elemento que só esteja ali para parecer bonito.
```
