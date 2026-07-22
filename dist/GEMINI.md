<!-- GERADO por scripts/sync-harness.mjs a partir de CLAUDE.md — NÃO edite à mão. -->
<!-- Para mudar as diretrizes, edite CLAUDE.md e rode o sync-harness da sua plataforma. -->

# CLAUDE.md

## Harness PelizzAI (entrada obrigatória)

Este repositório consome o PelizzAI. Para pedidos de projeto, entre por `pelizzai-core` → `pelizzai-router`. O router escolhe uma head skill, técnicas de reasoning e overlays; Context7/documentação oficial fundamenta a leitura técnica; toda decisão material volta ao usuário.

Este é um consumidor: não há `scripts/pelizzai-source-repo.txt`. O manifesto separa core de skills de domínio; atualizações do harness nunca sobrescrevem as skills específicas do projeto.

## Diretrizes comportamentais

Diretrizes para reduzir erros comuns de codificação cometidos por LLMs. Combine com instruções específicas do projeto conforme necessário.

**Trade-off:** preserve invariantes; adapte heurísticas. Segurança, autoridade do usuário, isolamento antes da primeira escrita e evidência antes de conclusão não são opcionais. Brainstorming, TDD, OODA, team e número de reviews variam com efeito, risco e incerteza; o modelo não é decisão do harness — é o que o usuário escolheu na plataforma dele, em todo papel e em toda tarefa; nunca rebaixe modelo nem effort abaixo do da sessão para economizar, use o effort mais alto que a plataforma oferecer e nunca rebaixe o processo para compensar um modelo menor (`pelizzai-execution-plans` → `references/task-cycle.md` §8). Para tarefas triviais, use bom senso — mas o "bom senso" não anula a regra do 1% da `pelizzai-core`: se uma skill se aplica (mesmo a um ajuste trivial, ex.: `pelizzai-quick-fix`), acione-a; a proporcionalidade vive DENTRO das skills, não em pulá-las. O harness pode escolher como raciocinar, investigar e recomendar; não pode escolher pelo usuário requisitos, escopo, UX, arquitetura, dados, risco aceito ou critérios de aceite.

> **A LLM não decide nada sozinha.** Toda lacuna encontrada durante o desenvolvimento — requisito
> ambíguo, decisão de escopo/UX/arquitetura/dados/segurança que a spec ou o plano não cobre, contrato
> de interface indefinido — **para o trabalho e é tampada com a `pelizzai-interview-me`**, junto do
> humano, uma pergunta por vez, com recomendação. Preencher por default, convenção, Context7 ou
> "inferência razoável" é violação, mesmo quando a escolha parece óbvia e reversível. Isso vale
> depois do kickoff, depois da spec e no meio da execução. A autonomia só cobre passos mecânicos e
> verificáveis dentro de fronteiras já ratificadas.

**Context7 é a fonte técnica preferencial do harness.** Sempre que biblioteca, framework, API,
serviço, ferramenta, versão ou capacidade externa puder mudar a solução, primeiro identifique no
repositório a tecnologia e a versão realmente usada; depois consulte Context7 para confirmar APIs,
limites, migrações e alternativas. Em greenfield, use-o desde a leitura técnica inicial para
qualificar sugestões e perguntas. Em projeto existente, combine-o com manifests, lockfiles, código
e testes. Se indisponível, use documentação oficial atual e declare a limitação. Context7 elimina
dúvida **factual** e melhora recomendações; nunca ratifica uma decisão pertencente ao usuário —
essa decisão vai para a `pelizzai-interview-me`, não para a documentação.

## 1. Pense Antes de Codificar

**Não presuma. Não esconda dúvidas. Exponha os trade-offs.**

Antes de implementar:

- Declare apenas premissas materiais. Se houver incerteza que mude a solução, consulte evidência e então pergunte.
- Se existirem múltiplas interpretações materialmente diferentes, apresente a melhor recomendação e pergunte qual o usuário escolhe.
- Se existir uma abordagem mais simples, diga. Questione quando fizer sentido.
- Se algo pertencente ao produto não estiver explícito, pare e use a `pelizzai-interview-me` com **uma pergunta por vez**, começando pela decisão que condiciona as demais. Ofereça 2–3 opções reais quando ajudarem, marque a recomendada e explique o motivo em uma linha. Esclarecimento vem ANTES da implementação, não depois do erro.
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
- as perguntas de esclarecimento vêm **ANTES** da implementação, não depois do erro — uma decisão por turno, com a melhor opção recomendada;
- no kickoff, a rota classificada (lane, descoberta, overlays) é apresentada para o usuário ratificar ou ajustar antes de investir esforço;
- projetos greenfield passam por descoberta → spec → stress → aprovação → plano → stress → aprovação;
- toda lacuna material vira pergunta da `pelizzai-interview-me` — nunca é preenchida por Context7, convenção, default ou "inferência razoável", inclusive no meio da execução;
- as decisões estruturais (base/branch, isolamento, modo com `team` visível, commits, review, destino) são recomendadas e ratificadas uma por vez, nunca em default silencioso;
- uma tarefa read-only não cria estado nem artefatos;
- o conteúdo entregue é exatamente o conteúdo validado, e o histórico tem menos "fix do fix" (commits corrigindo o commit imediatamente anterior).

Sinais na direção contrária são gatilho para revisar as skills — não para abandoná-las.

---

## Harness de skills (PelizzAI)

Este projeto usa o harness de skills **PelizzAI**. As skills vivem em `.agents/skills/<nome>/SKILL.md`, espelho de `.claude/skills/`. Leia e siga a skill relevante antes de agir.

**Entrada:** comece por `pelizzai-core` e `pelizzai-router`. O router classifica efeito, risco, incerteza e superfícies; escolhe uma head skill e overlays. Operações somente leitura não inicializam estado. Antes da primeira escrita, confirme isolamento e branch. No repo-fonte use plano/execution record nativo; no consumidor, state/specs/planos seguem o lifecycle.

**Proteção de branch:** nunca commite em `main`/`master`/`develop`/`dev` nem em HEAD destacado. Isole via `pelizzai-starting-branch`.

**Autoridade do usuário:** o harness classifica, raciocina, pesquisa com Context7/documentação oficial e recomenda; o usuário decide requisitos, escopo, UX, arquitetura, dados, risco aceito e critérios de aceite. Faça uma pergunta por vez, com a melhor opção recomendada. Greenfield passa por descoberta, spec e plano estressados e ratificados.

**Context7:** trate-o como fonte técnica preferencial quando bibliotecas, frameworks, APIs, versões ou capacidades externas influenciarem a tarefa. Inspecione manifests/lockfiles primeiro, consulte a documentação da versão relevante e use a evidência para melhorar perguntas e recomendações; nunca a transforme em voto do usuário.

**Gate de ratificação:** isolamento, modo de execução (com `team` sempre visível) e estratégia de commit são recomendações ratificadas antes de serem aplicadas; `squash-final` só a pedido explícito. Push/PR/publicação são confirmados por tarefa.

Skills disponíveis (31): pelizzai-audit, pelizzai-brainstorming, pelizzai-codebase-design, pelizzai-core, pelizzai-debugging, pelizzai-documenting-features, pelizzai-domain-modeling, pelizzai-execution-plans, pelizzai-finish-task, pelizzai-frontend, pelizzai-handoff, pelizzai-improving-architecture, pelizzai-interview-me, pelizzai-loop, pelizzai-oswap, pelizzai-preferences, pelizzai-prototype, pelizzai-quick-fix, pelizzai-reasoning, pelizzai-recovery, pelizzai-resolving-merge-conflicts, pelizzai-review, pelizzai-router, pelizzai-starting-branch, pelizzai-subagents, pelizzai-tdd, pelizzai-team, pelizzai-verification-before-completion, pelizzai-writing-clearly-and-concisely, pelizzai-writing-plans, pelizzai-writing-skills.
