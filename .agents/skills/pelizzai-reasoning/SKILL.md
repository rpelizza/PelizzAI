---
name: pelizzai-reasoning
description: Seleciona técnicas de raciocínio quando há incerteza material, investigação, decisão entre alternativas, síntese de evidência, planejamento não trivial ou validação de alto impacto. Use dentro da head skill para atacar a pergunta dominante; não é obrigatória para ação mecânica direta cujo contrato e prova já estão claros.
---

# PelizzAI Reasoning

## Objetivo

Use esta skill para selecionar, combinar e aplicar técnicas de raciocínio de forma proporcional à tarefa: quando investigar, quando agir direto, quando planejar, quando buscar evidências, quando comparar alternativas, quando pedir esclarecimento, quando validar, quando concluir e quando bloquear ou escalar uma decisão.

Esta skill não substitui skills de domínio, regras do projeto, documentação técnica, ferramentas ou instruções explícitas do usuário. Ela orquestra o raciocínio; o catálogo e a matriz abaixo definem operacionalmente cada decisão.

---

## Princípio central

> Use a menor quantidade de raciocínio estruturado necessária para diagnosticar, recomendar e
> verificar. Reasoning escolhe **como pensar**; não concede autoridade para escolher **o produto**.

Não carregue todas as técnicas por padrão. Não transforme tarefas simples em processos longos. Não use uma técnica apenas porque ela existe.

---

## Prioridades

Siga esta ordem de prioridade:

1. Instruções explícitas do usuário.
2. Regras obrigatórias do sistema e do ambiente.
3. Regras específicas do projeto, workspace ou repositório.
4. Requisitos de segurança, privacidade, permissões e compatibilidade.
5. Esta skill e suas técnicas.
6. Preferências técnicas, estéticas ou de implementação.

---

## Ativação

Use esta skill quando a tarefa envolver ao menos uma destas condições:

- múltiplas etapas;
- código, ferramentas ou integrações com incerteza, dependências ou risco material;
- fatos verificáveis ou potencialmente atuais;
- incerteza material;
- decisão entre alternativas;
- requisitos, restrições ou proibições;
- risco de regressão, perda de dados, custo ou impacto externo;
- bug, incidente, diagnóstico ou comportamento inesperado;
- recomendação técnica relevante;
- necessidade de validar uma resposta antes de concluir.

Não aplique fluxo completo para tarefas simples, criativas, diretas ou puramente editoriais.

Exemplos que normalmente não exigem técnicas adicionais:

```text
- Traduzir uma frase.
- Reescrever um parágrafo.
- Corrigir typo.
- Explicar conceito estável e básico.
- Renomear variável local.
```

---

## Triagem inicial

Antes de escolher uma técnica, determine:

```text
Objetivo:
- O que o usuário quer receber ou alcançar?

Escopo:
- O que está incluído e excluído?

Risco:
- O que acontece se a resposta ou ação estiver errada?

Incerteza:
- O que ainda não está confirmado?

Dependências:
- Há arquivos, código, ferramentas, APIs, fontes ou permissões necessárias?

Impacto:
- A tarefa altera dados, código, configuração, custo, segurança ou usuários?

Critério de conclusão:
- Como saber que a tarefa foi concluída corretamente?
```

Não faça perguntas factuais por reflexo. Primeiro use contexto, arquivos, documentação, código e
ferramentas. Quando restar decisão de requisito, escopo, UX, arquitetura, dados, segurança, custo,
risco aceito ou aceite, pergunte ao usuário uma decisão por vez e recomende a melhor opção.

Para um pedido novo de feature/refactor com efeito mutável e incerteza material, produza a **Análise da proposta** com [Proposal Stress](techniques/proposal-stress.md) (premortem de escopo) antes de rotear — premissas, lacunas materiais, riscos e alternativas — como resultado apresentado pelo `pelizzai-router`, não como pergunta. Read-only e ajuste trivial não a disparam; risco alto isolado eleva prova e gates, não a incerteza.

Use `pelizzai-interview-me` em todo greenfield e quando houver decisão humana material. Evidência
resolve fatos; não resolve preferência, política ou intenção do usuário.

---

## Seletor operacional: método e prova pelo efeito

Classifique separadamente **o efeito da tarefa**, **a incerteza** e **o dinamismo do ambiente**. A head skill define o ciclo de vida; esta skill escolhe as heurísticas. Nenhuma head skill deve impor OODA, RCA ou TDD sem o gatilho correspondente.

| Efeito predominante | Estratégia de implementação e validação |
| --- | --- |
| Comportamento novo ou alterado | `pelizzai-tdd`: teste comportamental red→green pelo contrato público |
| Bug comportamental | Regressão red→green quando houver seam automatizável; outro oráculo reproduzível quando não houver |
| Refatoração sem mudança de comportamento | Suíte/cobertura de caracterização verde antes; refatorar em passos pequenos; mesma suíte verde depois |
| Configuração, IaC ou migração | `validate`/`plan`/`dry-run`, compatibilidade e estratégia de rollback; teste unitário só para lógica separável |
| UI/UX/visual | Overlay obrigatório `pelizzai-frontend`, teste de comportamento quando aplicável e verificação visual real |
| Documentação/copy | Checagem estática proporcional: lint, links, exemplos, build/render ou inspeção do diff |

Uma tarefa pode combinar estratégias: um formulário novo usa TDD para comportamento **e** `pelizzai-frontend` para estados, acessibilidade, responsividade e QA visual. Registre a combinação no plano; não force um teste vermelho artificial para provar CSS, Markdown ou um `terraform plan`.

---

## Carregamento progressivo de técnicas

1. Escolha a técnica que responde à **pergunta dominante** da fase.
2. Leia apenas o arquivo dessa técnica e as auxiliares que fecham uma lacuna distinta.
3. Adicione ou troque técnica quando nova evidência mudar a pergunta; não mantenha um pipeline por inércia.
4. Considere o custo de contexto: cada técnica precisa justificar uma decisão ou prova observável.

Não há quota fixa. Em geral uma principal basta; alto impacto pode exigir várias lentes, enquanto
uma tarefa direta pode exigir nenhuma. Um pipeline (ver **Composições recomendadas**) encadeia
fases ao longo do tempo — não carrega todo o catálogo simultaneamente.

---

## Catálogo de técnicas

Leia a técnica correspondente antes de aplicá-la.

| Técnica                  | Quando usar                                                                      | Arquivo                                                               |
| ------------------------ | -------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| ReAct                    | Executar ações, usar ferramentas, observar resultados e ajustar próximo passo    | [react.md](techniques/react.md)                                       |
| OODA                     | Loop macro Observar→Orientar→Decidir→Agir: situações dinâmicas, execução longa, re-observar a realidade a cada iteração | [ooda.md](techniques/ooda.md)                                         |
| Plan and Execute         | Tarefas multi-etapa, dependências, checkpoints e replanejamento                  | [plan-and-execute.md](techniques/plan-and-execute.md)                 |
| Structured Decomposition | Dividir problema complexo em partes, responsabilidades, contratos e dependências | [structured-decomposition.md](techniques/structured-decomposition.md) |
| Constraint Satisfaction  | Garantir requisitos, proibições, compatibilidade e limites                       | [constraint-satisfaction.md](techniques/constraint-satisfaction.md)   |
| Assumption Tracking      | Rastrear premissas, hipóteses e condições ainda não confirmadas                  | [assumption-tracking.md](techniques/assumption-tracking.md)           |
| Evidence Synthesis       | Comparar documentos, fontes, logs, testes, dados e evidências conflitantes       | [evidence-synthesis.md](techniques/evidence-synthesis.md)             |
| Verification             | Confirmar código, fatos, cálculos, contratos, resultados e limitações            | [verification.md](techniques/verification.md)                         |
| Decision Making          | Escolher entre alternativas válidas, com trade-offs e reversibilidade            | [decision-making.md](techniques/decision-making.md)                   |
| Tree of Thoughts         | Explorar caminhos concorrentes com poda e backtracking controlados               | [tree-of-thoughts.md](techniques/tree-of-thoughts.md)                 |
| Self-Consistency         | Comparar tentativas independentes quando convergência agrega confiança           | [self-consistency.md](techniques/self-consistency.md)                 |
| Root Cause Analysis      | Investigar causa incerta, recorrência, flakiness, incidentes e falhas entre sistemas | [root-cause-analysis.md](techniques/root-cause-analysis.md)        |
| Critique and Refine      | Melhorar artefato após feedback, falha, inconsistência ou requisito não atendido | [critique-and-refine.md](techniques/critique-and-refine.md)           |

> A skill `pelizzai-interview-me` é uma **skill irmã**, não uma das técnicas do catálogo: acione-a para resolver ambiguidade material por entrevista, conforme a Triagem inicial e a matriz.

> **Proposal Stress (Premortem de escopo)** é a rotina de [Assumption Tracking](techniques/assumption-tracking.md) aplicada a um pedido novo, documentada em [proposal-stress.md](techniques/proposal-stress.md): produz a **Análise da proposta** que o `pelizzai-router` apresenta antes de rotear. Não é uma técnica extra do catálogo — é a mesma máquina de premissas com lente de premortem de escopo.

---

## Matriz de seleção

| Situação                                                     | Técnica principal        | Técnicas auxiliares possíveis                                 |
| ------------------------------------------------------------ | ------------------------ | ------------------------------------------------------------- |
| Tarefa simples com ação clara                                | Nenhuma ou ReAct leve    | Verification                                                  |
| Execução longa/dinâmica em loop até a entrega (plano, ambiente que muda) | OODA        | Plan and Execute, Verification                                |
| Feature com múltiplas partes                                 | Plan and Execute         | Structured Decomposition, Verification                        |
| Código existente com partes/contratos desconhecidos          | Structured Decomposition | Plan and Execute, Verification                                |
| Refatoração preservando comportamento                        | Structured Decomposition | Verification de regressão, Constraint Satisfaction            |
| Erro explícito com causa direta                              | ReAct                    | Verification                                                  |
| Bug determinístico com causa incerta                         | Root Cause Analysis leve | ReAct, Verification                                           |
| Bug flaky, recorrente ou distribuído                         | Root Cause Analysis      | Evidence Synthesis, Assumption Tracking, Verification         |
| Incidente com dano ativo                                     | Constraint Satisfaction  | Decision Making, ReAct, Verification; RCA após conter         |
| Escolha entre bibliotecas ou arquiteturas                    | Decision Making          | Constraint Satisfaction, Evidence Synthesis, Tree of Thoughts |
| Pesquisa com várias fontes                                   | Evidence Synthesis       | Verification, Assumption Tracking                             |
| Novo pedido de feature/refactor com incerteza material, antes de rotear | Assumption Tracking + Proposal Stress | Constraint Satisfaction, pelizzai-interview-me |
| Requisitos ambíguos ou incompletos                           | Assumption Tracking      | Constraint Satisfaction, pelizzai-interview-me                |
| Plano dependente de premissa não confirmada                  | Assumption Tracking      | Plan and Execute, Verification                                |
| Múltiplas alternativas interdependentes com impacto material | Tree of Thoughts         | Decision Making, Constraint Satisfaction                      |
| Cálculo, diagnóstico ou extração crítica                     | Verification             | Self-Consistency, Evidence Synthesis                          |
| Resultado falhou em teste, review ou checklist               | Critique and Refine      | Verification, ReAct                                           |
| Mudança de alto impacto                                      | Constraint Satisfaction  | Assumption Tracking, Decision Making, Verification            |

---

## Fronteiras entre técnicas próximas

Use estas distinções quando duas técnicas parecerem candidatas à principal:

- **OODA vs ReAct:** [ReAct](techniques/react.md) é o **micro-ciclo** de uma ação (pensar → agir com ferramenta → observar o resultado imediato). [OODA](techniques/ooda.md) é o **macro-loop** de uma execução inteira: re-**Observar** a realidade externa (git, testes, reviews, o que mudou no mundo), re-**Orientar** contra o objetivo/plano/DoD, **Decidir** a próxima iteração e **Agir** — repetindo até a Definition of Done. Um loop OODA contém muitos ciclos ReAct dentro da fase Agir.
- **RCA vs causa direta:** use [Root Cause Analysis](techniques/root-cause-analysis.md) quando ainda houver uma pergunta causal material. Erro explícito cujo contrato, stack trace ou compilador já identifica a causa usa ReAct + Verification; não invente hipóteses concorrentes. Em incidente com dano ativo, contenção reversível e preservação mínima de evidência precedem a RCA.
- **Tree of Thoughts vs Decision Making:** [Decision Making](techniques/decision-making.md) é a técnica padrão para escolher entre alternativas por trade-offs. Use [Tree of Thoughts](techniques/tree-of-thoughts.md) apenas quando os caminhos são **interdependentes** e exigem **poda e backtracking** — não para comparação linear de opções. As duas raramente atuam juntas.
- **Structured Decomposition vs Plan and Execute:** decomponha com [Structured Decomposition](techniques/structured-decomposition.md) quando **partes, responsabilidades ou contratos ainda são desconhecidos**; passe a [Plan and Execute](techniques/plan-and-execute.md) quando as partes já são conhecidas e o que falta é ordená-las e executá-las.
- **Self-Consistency é auxiliar:** [Self-Consistency](techniques/self-consistency.md) cruza tentativas independentes como apoio à [Verification](techniques/verification.md); não substitui o cálculo, a fonte ou o teste real.
- **Verification + Critique and Refine:** combine [Verification](techniques/verification.md) com [Critique and Refine](techniques/critique-and-refine.md) apenas quando a **causa da falha ainda não está confirmada**. Falha com causa direta usa Critique and Refine com verificação inline, sem dupla leitura ritual.

---

## Composições recomendadas

Cada seta é uma **transição de fase**: a técnica seguinte assume quando a anterior cumpre seu papel. Respeite o teto de carregamento por fase.

### Implementação de feature

```text
Assumption Tracking + Constraint Satisfaction na descoberta
→ Decision Making para recomendar alternativas ao usuário
→ Structured Decomposition após decisões ratificadas
→ Plan and Execute
→ ReAct na execução
→ [OODA somente se houver macro-loop com realidade reobservada]
→ Verification
```

Use Constraint Satisfaction quando houver requisitos rígidos, compatibilidade, segurança ou
proibições. OODA só governa `pelizzai-loop`/`pelizzai-execution-plans` quando existem múltiplas
iterações e a realidade (git, testes, review, ambiente) pode mudar a próxima decisão. Uma tarefa
linear ou um plano de uma fatia não ganha OODA só por ter ferramentas.

### Pesquisa ou recomendação técnica

```text
Constraint Satisfaction
→ Evidence Synthesis
→ Decision Making
→ Verification
```

Use Assumption Tracking quando a recomendação depender de informações ainda não confirmadas.

### Debugging ou incidente

```text
Causa direta: ReAct → Verification
Causa determinística incerta: RCA leve → ReAct → Verification
Flaky/recorrente/distribuído: RCA + Evidence Synthesis → [OODA só se houver rodadas] → Verification
Dano ativo: Constraint Satisfaction + Decision Making → contenção reversível → RCA após estabilizar → Verification
```

O número de hipóteses acompanha a incerteza: uma hipótese direta e falsificável pode bastar; mantenha múltiplas apenas quando causas materialmente plausíveis competirem. Não trate o primeiro sintoma como causa raiz nem transforme um erro explícito em investigação cerimonial.

### Decisão arquitetural

```text
Constraint Satisfaction
→ Tree of Thoughts
→ Decision Making
→ Verification
```

Use Tree of Thoughts apenas quando as alternativas forem interdependentes e exigirem poda; caso contrário, vá direto de Constraint Satisfaction para Decision Making.

### Alteração de alto impacto

```text
Constraint Satisfaction
→ Assumption Tracking
→ Decision Making
→ Plan and Execute
→ Verification
```

Aplica-se às ações listadas na seção **Ações de alto impacto**.

---

## Orçamento de esforço

A profundidade da investigação deve ser proporcional ao risco.

| Nível   | Característica                                                                          | Conduta                                                             |
| ------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| Baixo   | Mudança local, reversível e sem efeito externo                                          | Executar e validar de forma simples                                 |
| Médio   | Código funcional, integração limitada ou decisão relevante                              | Planejar brevemente, validar fluxo principal e erros relevantes     |
| Alto    | Dados, segurança, produção, contratos ou múltiplos sistemas                             | Usar evidência, checkpoints, testes e contingência                  |
| Crítico | Ação irreversível, financeira, jurídica, médica, segurança sensível ou produção crítica | Não avançar sem validação forte, autorização e plano de recuperação |

Não investigue indefinidamente.

Pare quando:

```text
- o objetivo foi atendido;
- os critérios de conclusão foram validados;
- não há incerteza material restante;
- a próxima ação não reduz risco nem gera informação útil;
- falta autorização, ferramenta ou contexto indispensável;
- o custo de continuar é maior que o benefício.
```

---

## Uso de ferramentas

Antes de usar uma ferramenta, defina:

```text
- Qual pergunta essa ferramenta deve responder?
- Qual resultado seria suficiente?
- A ferramenta é a fonte mais confiável?
- A ação gera efeito colateral?
- Existe alternativa menos invasiva?
```

Depois de usar uma ferramenta:

```text
- Interprete o resultado real.
- Atualize fatos, hipóteses e premissas.
- Não invente resultado de ferramenta.
- Não afirme que algo foi testado sem teste real.
- Não continue com plano desatualizado após evidência contrária.
```

Use fontes e ferramentas conforme a natureza da pergunta:

```text
Código e comportamento:
- Código-fonte, testes, logs, contratos e execução controlada.

Tecnologia:
- Documentação oficial via MCP `context7` quando disponível (`resolve-library-id` → `query-docs`);
  sem ele, changelog, repositório oficial e web. Prova de conceito quando a doc não bastar.
  Primeiro derive tecnologia e versão de manifests, lockfiles, config e código. Em greenfield sem
  versão instalada, consulte a versão atual da stack informada ou de cada candidata real.
  Use Context7 desde o reconhecimento inicial, e novamente quando design, plano, implementação,
  debugging, upgrade ou manutenção de skill trouxer uma pergunta técnica nova.
  Nunca responda de memória sobre API/versão de lib externa quando o Context7 puder confirmar.
  Context7 pode confirmar capacidade e restrição técnica; nunca escolhe requisito, persona, fluxo,
  política, arquitetura preferida ou critério de aceite em nome do usuário.

Fatos atuais:
- Fonte primária ou oficial atual.

Dados:
- Fonte original, cálculo reproduzível e conferência de consistência.

Arquivos enviados:
- Leitura direta, trechos relevantes e validação contra o conteúdo.
```

---

## Perguntas de esclarecimento

Pergunte quando a resposta muda materialmente requisito, plano, UX, arquitetura, dados, segurança,
custo, risco aceito ou resultado. Em greenfield, presuma que essas decisões ainda precisam ser
obtidas até que a spec mostre o contrário.

Antes de perguntar, verifique:

```text
- O contexto já responde?
- O código ou arquivo responde?
- A documentação responde?
- O usuário já delegou explicitamente esta categoria de decisão?
```

Pergunte quando:

```text
- há conflito entre requisitos;
- falta autorização para ação relevante;
- a escolha altera escopo ou custo;
- uma premissa crítica não pode ser verificada;
- a decisão pertence ao usuário ou responsável externo;
- não existe solução válida com as restrições atuais.
```

Faça uma pergunta por vez. Quando houver opções reais, mostre 2–3, destaque a recomendada e explique
o motivo em uma linha. Não agrupe decisões para reduzir turnos; use a resposta para recalcular a
próxima pergunta.

---

## Ações de alto impacto

Antes de executar ação com efeito externo relevante:

```text
[ ] O objetivo do usuário está claro.
[ ] O alvo foi confirmado.
[ ] Restrições e proibições foram identificadas.
[ ] Impactos foram avaliados.
[ ] Existe rollback, backup ou contingência quando aplicável.
[ ] Permissões foram verificadas.
[ ] Ação é necessária e proporcional.
[ ] Existe validação após execução.
```

São ações de alto impacto, entre outras:

```text
- Alterar banco de dados.
- Mudar contrato público.
- Publicar em produção.
- Alterar permissões.
- Enviar mensagens ou e-mails.
- Excluir dados.
- Criar custo recorrente.
- Processar dados sensíveis.
```

Não execute ação destrutiva, irreversível, financeira, de produção ou que exponha dados sensíveis sem confirmação adequada.

---

## Regras de comunicação

Na resposta ao usuário:

- entregue resultado, não cadeia de pensamento detalhada;
- diferencie fatos confirmados, inferências e hipóteses;
- informe validações realmente executadas;
- declare limitações e premissas abertas quando forem materiais;
- explique trade-offs apenas quando forem relevantes;
- não alegue certeza maior que a evidência permite;
- seja proporcional ao pedido e ao nível técnico do usuário.

Formato recomendado para tarefas relevantes:

```text
Resultado:
- [entrega principal]

Validação:
- [testes, fontes, build, logs ou conferências realizadas]

Decisões e trade-offs:
- [somente quando relevantes]

Limitações:
- [o que não foi confirmado ou depende de contexto externo]
```

---

## Anti-padrões de roteamento

Não faça isto:

```text
- Usar Tree of Thoughts para tarefa linear.
- Usar Self-Consistency para resposta simples.
- Criar plano extenso para ajuste local.
- Fazer Root Cause Analysis para erro de sintaxe evidente.
- Impor OODA a uma sequência curta sem re-observação macro útil.
- Impor TDD a refatoração, CSS, documentação, configuração, IaC ou migração sem comportamento automatizável.
- Pesquisar múltiplas fontes quando existe contrato direto.
- Usar Critique and Refine sem feedback ou problema concreto.
- Usar Verification apenas como checklist decorativo.
- Perguntar antes de consultar evidência disponível.
- Fazer várias perguntas de descoberta no mesmo turno.
- Usar uma técnica, Context7 ou “default seguro” para ratificar uma decisão do usuário.
- Continuar investigando após critérios de conclusão serem atendidos.
- Carregar todas as técnicas sem necessidade.
```

---

## Avaliação (Evals)

As suítes de avaliação medem se esta skill **decide, protege e é proporcional e confiável** — não eloquência. Rode-as ao criar, revisar ou alterar o `SKILL.md` ou qualquer técnica.

| Suíte                                                     | O que valida                                                           |
| --------------------------------------------------------- | ---------------------------------------------------------------------- |
| [README](evals/README.md)                                 | Índice, ordem de execução, falhas graves globais e metas de qualidade  |
| [routing](evals/routing.md)                               | Seleção da técnica certa e ausência de técnicas redundantes            |
| [planning-and-execution](evals/planning-and-execution.md) | Planejamento, decomposição, dependências, checkpoints e replanejamento |
| [debugging](evals/debugging.md)                           | Investigação de bugs, incidentes, causa raiz e contenção               |
| [research](evals/research.md)                             | Pesquisa atual, fontes primárias, conflitos, versões e limitações      |
| [high-impact-actions](evals/high-impact-actions.md)       | Ações destrutivas, financeiras, de produção, segurança e privacidade   |
| [regression](evals/regression.md)                         | Suíte compacta com cenários críticos de todas as áreas                 |

Após alterar uma técnica, rode a suíte especializada correspondente e a `regression` antes de aprovar a mudança.

---

## Fluxo operacional resumido

```text
1. Entenda objetivo, escopo, risco e critério de conclusão.
2. Verifique contexto, regras do projeto e evidências disponíveis.
3. Classifique o efeito e escolha a estratégia de implementação/validação correspondente.
4. Escolha a técnica dominante e somente auxiliares com função distinta.
5. Leia os arquivos Markdown correspondentes.
6. Execute com ReAct quando houver ferramenta, observação ou incerteza.
7. Valide proporcionalmente ao risco e ao efeito.
8. Replaneje somente se nova evidência invalidar o caminho atual.
9. Conclua quando os critérios de conclusão forem atendidos.
```

---

## Instrução final para o agente

```text
Use PelizzAI Reasoning para orquestrar técnicas de raciocínio, não para tornar toda tarefa complexa.

Escolha a menor combinação de técnicas que reduza incerteza, respeite restrições, produza evidência suficiente e permita concluir com segurança.

Prefira:
- evidência a suposição;
- recomendação reversível a compromisso prematuro, sem decidir pelo usuário;
- validação real a confiança subjetiva;
- técnicas específicas a raciocínio genérico;
- conclusão proporcional a investigação infinita.

Não exponha cadeia de pensamento detalhada.
Não invente observações, testes, fontes, alterações ou resultados.
Não use técnica sem gatilho real.
```
