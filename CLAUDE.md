# CLAUDE.md

## Harness PelizzAI (entrada obrigatória)

Este repositório é o **repo-fonte** do harness PelizzAI. Para pedidos que inspecionem ou alterem o projeto, entre por `pelizzai-core` → `pelizzai-router`; perguntas conceituais sem contexto de projeto podem ser respondidas diretamente. O router escolhe uma head skill e overlays por sinais observáveis — não por uma regra probabilística. Em processo (efeito, isolamento, review, validação e fechamento), siga os contratos canônicos das skills. Ao anunciar, use a grafia **"PelizzAI"**.

O que marca este repositório como repo-fonte é a sentinela `scripts/pelizzai-source-repo.txt`
(critério único de source mode — manifesto e sync existem também nos consumidores e não provam
nada). Aqui, não execute bootstrap consumidor nem crie runtime `pelizzai/`. Use plano/execution
record nativo; Verification sela o SHA em memória/registro e Finish não cria closure commit de
state no source mode. Para distribuir a projetos consumidores, use o sync portátil
(`node scripts/sync-harness.mjs --export-consumer <destino>`, ou o wrapper `.ps1`/`.sh`) — nunca
cópia manual (ela levaria a
sentinela junto e promoveria o consumidor a repo-fonte por engano).

## Diretrizes comportamentais

Diretrizes para reduzir erros comuns de codificação cometidos por LLMs. Combine com instruções específicas do projeto conforme necessário.

**Trade-off:** preserve invariantes; adapte heurísticas. Segurança, autoridade do usuário, isolamento antes da primeira escrita e evidência antes de conclusão não são opcionais. Brainstorming, TDD, OODA, team, número de reviews e effort variam com efeito, risco e incerteza. O harness pode escolher como raciocinar, investigar e recomendar; não pode escolher pelo usuário requisitos, escopo, UX, arquitetura, dados, risco aceito ou critérios de aceite.

**Context7 é a fonte técnica preferencial do harness.** Sempre que biblioteca, framework, API,
serviço, ferramenta, versão ou capacidade externa puder mudar a solução, primeiro identifique no
repositório a tecnologia e a versão realmente usada; depois consulte Context7 para confirmar APIs,
limites, migrações e alternativas. Em greenfield, use-o desde a leitura técnica inicial para
qualificar sugestões e perguntas. Em projeto existente, combine-o com manifests, lockfiles, código
e testes. Se indisponível, use documentação oficial atual e declare a limitação. Context7 elimina
dúvidas factuais e melhora recomendações; nunca ratifica uma decisão pertencente ao usuário.

## 1. Pense Antes de Codificar

**Não presuma. Não esconda dúvidas. Exponha os trade-offs.**

Antes de implementar:

- Declare apenas premissas materiais. Se houver incerteza que mude a solução, consulte evidência e então pergunte.
- Se existirem múltiplas interpretações materialmente diferentes, apresente a melhor recomendação e pergunte qual o usuário escolhe.
- Se existir uma abordagem mais simples, diga. Questione quando fizer sentido.
- Se algo pertencente ao produto não estiver explícito, pare com **uma pergunta por vez**, começando pela decisão que condiciona as demais. Ofereça 2–3 opções reais quando ajudarem, marque a recomendada e explique o motivo em uma linha.
- Evidência do projeto e Context7/documentação oficial eliminam perguntas factuais; não autorizam a LLM a responder decisões de produto pelo usuário. Uma decisão reversível só pode ser tomada mecanicamente quando já está contida numa spec ou plano ratificado.

## 2. Simplicidade Primeiro

**O mínimo de código que resolve o problema. Nada especulativo.**

- Nada de funcionalidades além do que foi pedido.
- Nada de abstrações para código de uso único.
- Nada de "flexibilidade" ou "configurabilidade" que não foi solicitada.
- Nada de tratamento de erro para cenários impossíveis.
- Se você escreveu 200 linhas e poderia ser 50, reescreva.

Pergunte a si mesmo: "Um engenheiro sênior diria que isto está complicado demais?" Se sim, simplifique.

## 3. Alterações Cirúrgicas

**Mexa apenas no que for necessário. Limpe apenas a sua própria bagunça.**

Ao editar código existente:

- Não "melhore" código, comentários ou formatação adjacentes.
- Não refatore coisas que não estão quebradas.
- Siga o estilo existente, mesmo que você fizesse diferente.
- Se notar código morto não relacionado, mencione; não delete.

Quando suas alterações criarem órfãos:

- Remova imports, variáveis e funções que AS SUAS alterações tornaram inutilizados.
- Não remova código morto preexistente, a menos que peçam.

O teste: toda linha alterada deve estar diretamente ligada à solicitação do usuário.

## 4. Execução Orientada a Objetivos

**Defina critérios de sucesso. Repita até verificar.**

Transforme tarefas em objetivos verificáveis:

- "Adicionar validação" → "Escrever testes para entradas inválidas e depois fazê-los passar"
- "Corrigir o bug" → "Escrever um teste que o reproduza e depois fazê-lo passar"
- "Refatorar X" → "Garantir que os testes passem antes e depois"

Para micro-planos de resposta (poucos passos, dentro de uma mesma mensagem), apresente um plano breve:

```
1. [Etapa] → verificar: [checagem]
2. [Etapa] → verificar: [checagem]
3. [Etapa] → verificar: [checagem]
```

O `pelizzai-router` escolhe e recomenda a lane, head skill, overlays e técnicas de reasoning; o usuário ratifica a rota antes de qualquer tarefa mutável. Uma alteração bounded pode usar plano compacto e dispensar entrevista quando o próprio usuário já forneceu objetivo, aceite e abordagem. **Produto/projeto greenfield nunca é bounded só porque a stack foi informada:** faça descoberta uma pergunta por vez, produza spec, estresse-a, obtenha aprovação, produza plano, estresse-o e obtenha nova aprovação antes da execução. Specs e planos são o default durável; só são omitidos por dispensa explícita do usuário. **Recomende e ratifique: raciocinar é do harness; decidir é do usuário.**

Depois que critérios, spec e plano estão ratificados, a LLM pode executar passos mecânicos e verificáveis dentro dessas fronteiras. Qualquer decisão emergente que altere produto, escopo, UX, arquitetura, dados, segurança, custo ou aceite interrompe a execução e volta ao usuário.

---

## O harness está funcionando se…

Sinais observáveis de que estas diretrizes e as skills estão cumprindo o papel:

- os diffs estão menores e sem mudanças não relacionadas ao pedido;
- há menos reescritas causadas por excesso de complexidade;
- descoberta de produto faz uma pergunta por vez, com a melhor opção recomendada e justificativa curta;
- no kickoff, a rota classificada (lane, descoberta, overlays) é apresentada para o usuário ratificar ou ajustar antes de investir esforço;
- projetos greenfield passam por descoberta → spec → stress → aprovação → plano → stress → aprovação;
- decisões de escopo/UX/arquitetura/dados/segurança são ratificadas — nunca preenchidas por Context7, convenção ou default silencioso;
- Context7 aparece cedo e de forma version-aware em greenfield, features, debugging, upgrades,
  planos e manutenção de skills sempre que houver dependência de tecnologia externa;
- as decisões estruturais (base/branch, isolamento, modo com `team` visível, commits, review, destino) são recomendadas e ratificadas uma por vez, nunca em default silencioso;
- a política de execução ratificada pré-seleciona recomendações, mas só é aplicada em lote quando o usuário delega explicitamente;
- uma tarefa read-only não cria estado nem artefatos;
- overlays de frontend/security chegam ao executor antes da implementação/review;
- a stack aprovada dispara proposta explícita de domain skills antes do plano/execução, e novas lacunas de domínio reaparecem no fechamento;
- o conteúdo entregue é exatamente o conteúdo validado;
- o histórico tem menos "fix do fix" (commits corrigindo o commit imediatamente anterior).

Sinais na direção contrária são gatilho para revisar as skills — não para abandoná-las.
