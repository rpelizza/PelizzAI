---
name: pelizzai-frontend
description: Use essa skill para implementar a interface do usuário (UI) de um plano de execução. A UI é o ponto de contato do usuário com o plano, e deve ser clara, intuitiva e responsiva. Esta skill fornece diretrizes, padrões e exemplos para criar uma UI consistente e de alta qualidade.
---

# Design de Frontend

Aborde este projeto como o líder de design de um pequeno estúdio conhecido por criar identidades visuais únicas para cada cliente — identidades que jamais seriam confundidas com as de outros. Este cliente já rejeitou propostas que pareciam baseadas em modelos genéricos e está pagando por uma perspectiva autêntica: faça escolhas deliberadas e com personalidade sobre paleta de cores, tipografia e layout que sejam específicas para este briefing, e assuma um risco estético real que você saiba justificar.

## Fundamente o design no tema

Se o briefing não definir claramente qual é o produto ou o tema, defina-o você mesmo antes de começar a projetar: identifique um tema concreto, o público-alvo e a função principal da página, e explicite essa escolha. Se você tiver informações sobre as preferências do usuário, o contexto do que está sendo construído ou projetos anteriores, utilize isso como referência. É no universo do próprio tema — com seus materiais, instrumentos, artefatos e linguagem característica — que nascem as escolhas originais. Trabalhe sempre com o conteúdo e o tema reais do briefing.

## Princípios de design

No design para a web, a seção de destaque inicial (o _hero_) funciona como uma tese. Comece com o elemento mais característico do universo do tema, na forma que fizer mais sentido: um título impactante, uma imagem, uma animação, uma demonstração em tempo real ou um elemento interativo. Seja intencional na escolha: aquele padrão de "número grande com legenda pequena, estatísticas de apoio e detalhes em degradê" é uma solução clichê; utilize-o apenas se for realmente a melhor opção.

A tipografia transmite a personalidade da página. Combine fontes de destaque (_display_) e de corpo de texto de forma deliberada — evitando recorrer às mesmas famílias tipográficas que você usaria em qualquer outro projeto — e estabeleça uma hierarquia tipográfica clara, com pesos, larguras e espaçamentos intencionais. Faça com que o tratamento tipográfico seja, por si só, uma parte memorável do design, e não apenas um meio neutro de apresentar o conteúdo.

A estrutura transmite informação. Elementos estruturais — como numeração, títulos de apoio (_eyebrows_), divisores e rótulos — devem comunicar algo verdadeiro sobre o conteúdo, em vez de apenas decorá-lo. Muitos designs genéricos utilizam marcadores numéricos (01 / 02 / 03), mas isso só é adequado se o conteúdo realmente seguir uma sequência — como um processo real ou uma linha do tempo onde a ordem transmite informações essenciais ao leitor. Questione se escolhas como marcadores numéricos realmente fazem sentido antes de incorporá-las.

Utilize o movimento de forma deliberada. Avalie onde — e se — a animação pode servir ao tema: uma sequência de carregamento da página, uma revelação acionada pela rolagem, microinterações ao passar o mouse ou uma atmosfera ambiente. Um momento bem orquestrado costuma causar mais impacto do que efeitos dispersos; escolha a abordagem que a direção do projeto exige. No entanto, às vezes menos é mais, e o excesso de animação pode dar a impressão de que o design foi gerado por IA.

Alinhe a complexidade à visão do projeto. Abordagens maximalistas exigem uma execução elaborada; abordagens minimalistas exigem precisão no espaçamento, na tipografia e nos detalhes. A elegância reside na boa execução da visão escolhida.

Dê atenção especial ao conteúdo textual. Muitas vezes, o _briefing_ de design não contém o conteúdo real, cabendo a você criar os textos. O texto pode fazer com que o design pareça tão genérico quanto um modelo pronto. Consulte a seção sobre redação abaixo para obter mais orientações.

## Processo: _brainstorming_, exploração, planejamento, crítica, construção, nova crítica

Para fins de calibração: atualmente, designs gerados por IA tendem a se concentrar em três estilos: (1) fundo em tom creme quente (próximo a #F4F1EA) com tipografia _display_ serifada de alto contraste e um detalhe em terracota; (2) fundo quase preto com um único detalhe em verde-ácido vibrante ou vermelhão; (3) layout estilo jornal _broadsheet_, com linhas divisórias finíssimas, bordas sem arredondamento e colunas densas, lembrando jornais impressos. Os três são válidos para certos _briefings_, mas funcionam mais como padrões automáticos do que como escolhas deliberadas, surgindo independentemente do tema. Quando o _briefing_ definir uma direção visual, siga-a à risca — as palavras do próprio _briefing_ sempre prevalecem, inclusive quando solicitam um desses estilos. Quando houver liberdade de escolha, não a desperdice optando por um desses padrões. Assim como ocorre com um designer humano contratado, muitas vezes é preciso encontrar um equilíbrio cuidadoso entre fazer o que você domina e aproveitar cada projeto como uma oportunidade para experimentar e aprender.

Trabalhe em duas etapas. Primeiro, faça um _brainstorming_ e elabore um plano de design conciso com base no _briefing_ fornecido: crie um sistema compacto de _tokens_ abrangendo cores, tipografia, layout e assinatura visual. Cores: descreva a paleta indicando de 4 a 6 valores hexadecimais nomeados. Tipografia: defina fontes para pelo menos duas funções (uma fonte _display_ com personalidade, usada com moderação; uma fonte complementar para corpo de texto; e uma fonte utilitária para legendas ou dados, se necessário). Layout: crie um conceito de layout, utilizando descrições em frases curtas e _wireframes_ em ASCII para gerar e comparar ideias. Assinatura visual: defina o elemento único e marcante que caracterizará a página e que incorpore a essência do _briefing_ de forma adequada.

Em seguida, antes de iniciar a construção, revise o plano comparando-o com o _briefing_: se alguma parte parecer um padrão genérico que você produziria para qualquer página semelhante (teste com um _prompt_ parecido para ver se chega a um resultado similar) — em vez de uma escolha feita especificamente para aquele _briefing_ —, revise essa parte e explique o que foi alterado e por quê. Somente após confirmar que seu plano de design possui um caráter único você deve começar a escrever o código, seguindo rigorosamente o plano revisado e baseando nele todas as decisões sobre cores e tipografia.

Ao escrever o código, tenha cuidado com a estruturação da especificidade dos seletores CSS. É fácil criar classes CSS que anulam umas às outras (especialmente com um seletor baseado em tipo, como `.section`, e um seletor baseado em elemento, como `.cta`). Isso acontece com frequência ao lidar com espaçamentos (paddings/margins) entre seções.

Tente realizar grande parte desse planejamento e iteração mentalmente, apresentando ideias ao usuário apenas quando estiver mais confiante de que elas irão encantá-lo.

## Moderação e autocrítica

Reserve sua ousadia para um único ponto de destaque. Faça do elemento principal o ponto memorável, mantenha o restante sóbrio e disciplinado, e elimine qualquer decoração que não atenda ao objetivo do projeto. Às vezes, não correr riscos pode ser, em si, um risco! Estabeleça um padrão mínimo de qualidade sem precisar anunciá-lo: design responsivo (adaptado para dispositivos móveis), foco de teclado visível e respeito às preferências de redução de movimento. Critique seu próprio trabalho enquanto desenvolve, tirando capturas de tela se o ambiente permitir — uma imagem vale mais que mil tokens. Lembre-se do conselho de Chanel: antes de sair de casa, olhe-se no espelho e remova um acessório. Criadores humanos possuem memória e buscam sempre inovar; portanto, ter um espaço para anotar rapidamente o que você já testou pode ajudar em iterações futuras.

## Mais sobre redação no design

As palavras surgem em um design por um motivo: facilitar a compreensão e, consequentemente, o uso. Elas são matéria-prima do design, não mera decoração. Aplique ao texto a mesma intencionalidade que você dedicaria ao espaçamento e às cores. Antes de escrever, pergunte-se o que o design precisa comunicar e qual a melhor forma de expressar isso para ajudar o usuário a navegar pela experiência.

Escreva sob a perspectiva do usuário final. Nomeie os elementos com base no que as pessoas controlam e reconhecem, e não na forma como o sistema foi construído. Uma pessoa gerencia notificações, não configurações de webhook. Descreva a função de um elemento de forma clara e direta, em vez de tentar "vendê-lo". Ser específico é sempre melhor do que tentar ser espirituoso.

Use a voz ativa como padrão. Um controle deve indicar exatamente o que acontece quando é acionado: "Salvar alterações", em vez de "Enviar". Uma ação deve manter o mesmo nome ao longo de todo o fluxo; assim, um botão com o rótulo "Publicar" gera uma notificação (toast) dizendo "Publicado". O vocabulário de uma interface serve como sinalização para quem navega pelo produto. Coesão e consistência são fundamentais para que as pessoas aprendam a se orientar no sistema. Trate o erro e o estado de vazio como oportunidades para orientar o usuário, e não apenas como reflexos de um estado emocional. Explique o que deu errado e como resolver a situação, utilizando a voz da própria interface em vez de uma voz humana. Mensagens de erro não pedem desculpas e nunca são vagas sobre o ocorrido. Uma tela vazia é um convite à ação.

Mantenha um tom de voz coloquial e preciso: use verbos simples, letras maiúsculas apenas no início das frases, evite palavras desnecessárias e alinhe o tom à marca e ao público. Garanta que cada elemento desempenhe uma única função: um rótulo serve para identificar, um exemplo serve para demonstrar, e nenhum elemento deve exercer uma função dupla de forma implícita.
