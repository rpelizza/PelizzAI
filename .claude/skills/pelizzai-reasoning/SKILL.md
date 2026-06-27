---
name: pelizzai-reasoning
description: Orquestra técnicas de raciocínio para tarefas que exigem planejamento, investigação, validação, decisão ou uso de ferramentas. Selecione apenas as técnicas necessárias, carregue-as progressivamente e execute com esforço proporcional ao risco, à incerteza e ao impacto.
---

# PelizzAI Reasoning

## Objetivo

Use esta skill para selecionar, combinar e aplicar técnicas de raciocínio de forma proporcional à tarefa: quando investigar, quando agir direto, quando planejar, quando buscar evidências, quando comparar alternativas, quando pedir esclarecimento, quando validar, quando concluir e quando bloquear ou escalar uma decisão.

Esta skill não substitui skills de domínio, regras do projeto, documentação técnica, ferramentas ou instruções explícitas do usuário. Ela orquestra o raciocínio; o catálogo e a matriz abaixo definem operacionalmente cada decisão.

---

## Princípio central

> Use a menor quantidade de raciocínio estruturado necessária para produzir um resultado correto, seguro, verificável e útil.

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
- código, arquivos, ferramentas ou integrações;
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

Não faça perguntas por reflexo. Primeiro use contexto disponível, arquivos, documentação, código e ferramentas adequadas.

Use a skill `pelizza-interview-me` somente quando houver ambiguidade material que não possa ser resolvida com evidência disponível.

---

## Carregamento progressivo de técnicas

1. Escolha **uma técnica principal**.
2. Adicione no máximo **duas técnicas auxiliares**.
3. Leia apenas os arquivos necessários para a tarefa atual.
4. Adicione outra técnica somente quando nova evidência justificar.
5. Em tarefas de alto impacto, até três técnicas auxiliares são permitidas quando realmente necessárias.

O teto de **uma principal + duas auxiliares** (três em alto impacto) vale **por fase de raciocínio**. Um pipeline (ver a seção **Composições recomendadas**) encadeia fases ao longo do tempo: cada seta é uma transição de fase, não o carregamento simultâneo de cinco técnicas.

**Principal vs auxiliar:** a técnica principal governa o objetivo central e a ordem das demais; as auxiliares dão suporte pontual e são acionadas sob demanda. Quando a matriz listar várias candidatas, escolha como principal a que responde à pergunta dominante da tarefa — executar, planejar, investigar, decidir ou validar — e trate as outras como auxiliares.

---

## Catálogo de técnicas

Leia a técnica correspondente antes de aplicá-la.

| Técnica                  | Quando usar                                                                      | Arquivo                                                               |
| ------------------------ | -------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| ReAct                    | Executar ações, usar ferramentas, observar resultados e ajustar próximo passo    | [react.md](techniques/react.md)                                       |
| Plan and Execute         | Tarefas multi-etapa, dependências, checkpoints e replanejamento                  | [plan-and-execute.md](techniques/plan-and-execute.md)                 |
| Structured Decomposition | Dividir problema complexo em partes, responsabilidades, contratos e dependências | [structured-decomposition.md](techniques/structured-decomposition.md) |
| Constraint Satisfaction  | Garantir requisitos, proibições, compatibilidade e limites                       | [constraint-satisfaction.md](techniques/constraint-satisfaction.md)   |
| Assumption Tracking      | Rastrear premissas, hipóteses e condições ainda não confirmadas                  | [assumption-tracking.md](techniques/assumption-tracking.md)           |
| Evidence Synthesis       | Comparar documentos, fontes, logs, testes, dados e evidências conflitantes       | [evidence-synthesis.md](techniques/evidence-synthesis.md)             |
| Verification             | Confirmar código, fatos, cálculos, contratos, resultados e limitações            | [verification.md](techniques/verification.md)                         |
| Decision Making          | Escolher entre alternativas válidas, com trade-offs e reversibilidade            | [decision-making.md](techniques/decision-making.md)                   |
| Tree of Thoughts         | Explorar caminhos concorrentes com poda e backtracking controlados               | [tree-of-thoughts.md](techniques/tree-of-thoughts.md)                 |
| Self-Consistency         | Comparar tentativas independentes quando convergência agrega confiança           | [self-consistency.md](techniques/self-consistency.md)                 |
| Root Cause Analysis      | Investigar bugs, incidentes, sintomas, causas e prevenção de recorrência         | [root-cause-analysis.md](techniques/root-cause-analysis.md)           |
| Critique and Refine      | Melhorar artefato após feedback, falha, inconsistência ou requisito não atendido | [critique-and-refine.md](techniques/critique-and-refine.md)           |

> A skill `pelizzai-interview-me` é uma **skill irmã**, não uma das 12 técnicas: acione-a para resolver ambiguidade material por entrevista, conforme a Triagem inicial e a matriz.

---

## Matriz de seleção

| Situação                                                     | Técnica principal        | Técnicas auxiliares possíveis                                 |
| ------------------------------------------------------------ | ------------------------ | ------------------------------------------------------------- |
| Tarefa simples com ação clara                                | Nenhuma ou ReAct leve    | Verification                                                  |
| Feature com múltiplas partes                                 | Plan and Execute         | Structured Decomposition, Verification                        |
| Código existente com partes/contratos desconhecidos          | Structured Decomposition | Plan and Execute, Verification                                |
| Refatoração preservando comportamento                        | Structured Decomposition | Verification de regressão, Constraint Satisfaction            |
| Bug simples e evidente                                       | ReAct                    | Verification                                                  |
| Bug recorrente ou incidente                                  | Root Cause Analysis      | ReAct, Evidence Synthesis, Verification                       |
| Escolha entre bibliotecas ou arquiteturas                    | Decision Making          | Constraint Satisfaction, Evidence Synthesis, Tree of Thoughts |
| Pesquisa com várias fontes                                   | Evidence Synthesis       | Verification, Assumption Tracking                             |
| Requisitos ambíguos ou incompletos                           | Assumption Tracking      | Constraint Satisfaction, pelizzai-interview-me                |
| Plano dependente de premissa não confirmada                  | Assumption Tracking      | Plan and Execute, Verification                                |
| Múltiplas alternativas interdependentes com impacto material | Tree of Thoughts         | Decision Making, Constraint Satisfaction                      |
| Cálculo, diagnóstico ou extração crítica                     | Verification             | Self-Consistency, Evidence Synthesis                          |
| Resultado falhou em teste, review ou checklist               | Critique and Refine      | Verification, ReAct                                           |
| Mudança de alto impacto                                      | Constraint Satisfaction  | Assumption Tracking, Decision Making, Verification            |

---

## Fronteiras entre técnicas próximas

Use estas distinções quando duas técnicas parecerem candidatas à principal:

- **Tree of Thoughts vs Decision Making:** [Decision Making](techniques/decision-making.md) é a técnica padrão para escolher entre alternativas por trade-offs. Use [Tree of Thoughts](techniques/tree-of-thoughts.md) apenas quando os caminhos são **interdependentes** e exigem **poda e backtracking** — não para comparação linear de opções. As duas raramente atuam juntas.
- **Structured Decomposition vs Plan and Execute:** decomponha com [Structured Decomposition](techniques/structured-decomposition.md) quando **partes, responsabilidades ou contratos ainda são desconhecidos**; passe a [Plan and Execute](techniques/plan-and-execute.md) quando as partes já são conhecidas e o que falta é ordená-las e executá-las.
- **Self-Consistency é auxiliar:** [Self-Consistency](techniques/self-consistency.md) cruza tentativas independentes como apoio à [Verification](techniques/verification.md); não substitui o cálculo, a fonte ou o teste real.
- **Verification + Critique and Refine:** combine [Verification](techniques/verification.md) com [Critique and Refine](techniques/critique-and-refine.md) apenas quando a **causa da falha ainda não está confirmada**. Falha com causa direta usa Critique and Refine com verificação inline, sem dupla leitura ritual.

---

## Composições recomendadas

Cada seta é uma **transição de fase**: a técnica seguinte assume quando a anterior cumpre seu papel. Respeite o teto de carregamento por fase.

### Implementação de feature

```text
Structured Decomposition
→ Plan and Execute
→ ReAct
→ Verification
```

Use Constraint Satisfaction quando houver requisitos rígidos, compatibilidade, segurança ou proibições.

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
Root Cause Analysis
→ ReAct
→ Evidence Synthesis
→ Verification
→ Critique and Refine
```

Não trate o primeiro sintoma visível como causa raiz.

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
- Documentação oficial, changelog, repositório oficial e prova de conceito.

Fatos atuais:
- Fonte primária ou oficial atual.

Dados:
- Fonte original, cálculo reproduzível e conferência de consistência.

Arquivos enviados:
- Leitura direta, trechos relevantes e validação contra o conteúdo.
```

---

## Perguntas de esclarecimento

Pergunte somente quando a resposta muda materialmente o plano, a segurança, o escopo, o custo ou o resultado.

Antes de perguntar, verifique:

```text
- O contexto já responde?
- O código ou arquivo responde?
- A documentação responde?
- É possível seguir com decisão reversível?
- Existe uma alternativa segura e conservadora?
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
- Pesquisar múltiplas fontes quando existe contrato direto.
- Usar Critique and Refine sem feedback ou problema concreto.
- Usar Verification apenas como checklist decorativo.
- Perguntar antes de consultar evidência disponível.
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
3. Escolha uma técnica principal e até duas auxiliares.
4. Leia os arquivos Markdown correspondentes.
5. Execute com ReAct quando houver ferramenta, observação ou incerteza.
6. Valide proporcionalmente ao risco.
7. Replaneje somente se nova evidência invalidar o caminho atual.
8. Conclua quando os critérios de conclusão forem atendidos.
```

---

## Instrução final para o agente

```text
Use PelizzAI Reasoning para orquestrar técnicas de raciocínio, não para tornar toda tarefa complexa.

Escolha a menor combinação de técnicas que reduza incerteza, respeite restrições, produza evidência suficiente e permita concluir com segurança.

Prefira:
- evidência a suposição;
- decisão reversível a compromisso prematuro;
- validação real a confiança subjetiva;
- técnicas específicas a raciocínio genérico;
- conclusão proporcional a investigação infinita.

Não exponha cadeia de pensamento detalhada.
Não invente observações, testes, fontes, alterações ou resultados.
Não use técnica sem gatilho real.
```
