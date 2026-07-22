# Planning and Execution Evals

## Objetivo

Este arquivo avalia se a skill [pelizzai-reasoning](../SKILL.md) conduz planejamento, decomposição e execução de tarefas multi-etapa de forma confiável e proporcional.

É a suíte que exercita como **técnica principal** o núcleo de planejamento do harness, hoje sem cobertura dedicada:

- [Plan and Execute](../techniques/plan-and-execute.md) — planejar, validar antes de executar, criar checkpoints e replanejar;
- [Structured Decomposition](../techniques/structured-decomposition.md) — dividir problema complexo em partes, responsabilidades, contratos e dependências;
- [Decision Making](../techniques/decision-making.md) — no modo de busca com poda e backtracking, explorar caminhos interdependentes quando as alternativas são materialmente diferentes.

O agente deve ser capaz de:

```text
- distinguir tarefa que exige plano de tarefa que deve ser executada diretamente;
- separar descoberta de execução quando há partes ou contratos ainda desconhecidos;
- mapear dependências reais entre etapas antes de agir;
- validar pré-condições e resultados em checkpoints proporcionais ao risco;
- replanejar quando uma hipótese ou dependência crítica muda, preservando o trabalho já validado;
- paralelizar apenas ações independentes e sem recurso compartilhado;
- decompor por responsabilidade e contrato, não por arquivo, e detectar lacunas de integração;
- explorar alternativas materialmente distintas com critério de poda quando a decisão é estrutural;
- definir critério de conclusão objetivo e parar quando ele é atendido.
```

Este eval não mede a elegância do plano. Mede se a estrutura de execução é correta, segura, proporcional e verificável.

---

## Técnicas avaliadas

| Técnica                                                               | Uso esperado                                                               |
| --------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| [Plan and Execute](../techniques/plan-and-execute.md)                 | Planejar, validar antes de executar, criar checkpoints e replanejar        |
| [Structured Decomposition](../techniques/structured-decomposition.md) | Dividir por responsabilidade e contrato, mapear dependências e integração  |
| [Decision Making](../techniques/decision-making.md)                   | No modo de busca, explorar caminhos interdependentes com poda e backtracking |
| [ReAct](../techniques/react.md)                                       | Executar etapa, observar resultado e ajustar o próximo passo               |
| [Verification](../techniques/verification.md)                         | Validar pré-condições, resultados e regressões em cada checkpoint          |
| [Assumption Tracking](../techniques/assumption-tracking.md)           | Registrar premissas e dependências não confirmadas que condicionam o plano |
| [Constraint Satisfaction](../techniques/constraint-satisfaction.md)   | Garantir requisitos obrigatórios e proibições ao longo da execução         |
| [Critique and Refine](../techniques/critique-and-refine.md)           | Ajustar o plano após falha, bloqueio ou requisito não atendido             |

---

## Protocolo de avaliação

Para cada cenário, avalie primeiro a estrutura do plano e a próxima ação, **antes** de qualquer execução completa.

O agente avaliado deve produzir, de forma compacta:

```text
Classificação:
- Tipo de tarefa: ação direta, plano linear, plano com decomposição ou exploração de alternativas.
- Risco e impacto:
- Incerteza material:
- Técnica principal:
- Técnicas auxiliares:

Descoberta:
- O que precisa ser conhecido antes de executar (contrato, partes, dependências, premissas).

Plano:
- Etapas com dependências e ordem.
- Pré-condições e checkpoints de validação.
- O que pode ser paralelo e o que deve ser sequencial.

Gatilhos de replanejamento:
- O que invalidaria o plano atual.

Critério de conclusão:
- Como saber que a tarefa terminou corretamente.
```

O agente não deve expor cadeia de pensamento detalhada nem produzir um plano maior que o necessário.

---

## Rubrica

Cada cenário vale 10 pontos.

| Critério                     | Pontos | Descrição                                                                  |
| ---------------------------- | -----: | -------------------------------------------------------------------------- |
| Classificação e técnica      |      2 | Escolhe planejar, decompor, explorar ou agir direto de forma proporcional  |
| Descoberta antes da execução |      2 | Confirma contrato, partes e premissas antes de alterar o sistema           |
| Dependências e ordem         |      2 | Mapeia dependências reais; paraleliza só o que é seguro                    |
| Checkpoints e validação      |      1 | Define validação proporcional ao risco antes de etapas irreversíveis       |
| Replanejamento               |      2 | Replaneja preservando trabalho válido; distingue bloqueio de inviabilidade |
| Minimalidade e conclusão     |      1 | Evita overplanning; define e respeita o critério de conclusão              |

### Falhas graves

O cenário recebe no máximo 3 pontos se o agente:

```text
- executa ação irreversível sem checkpoint nem validação de pré-condição;
- paraleliza ações que compartilham recurso, estado ou dependência;
- decompõe por arquivos em vez de por responsabilidade, ou trata validação de partes isoladas como prova de comportamento integrado;
- descarta trabalho já validado ao replanejar, recomeçando do zero sem necessidade;
- trata configuração ou dependência local como prova de disponibilidade em produção;
- aceita um plano genérico ("Analisar, Implementar, Testar") sem etapas, dependências ou critérios verificáveis;
- aplica plano extenso a um ajuste local trivial e reversível;
- explora alternativas sem critério de poda ou gera apenas variantes superficiais de uma mesma ideia.
```

---

## Critérios globais de aprovação

A implementação passa neste conjunto quando:

```text
- Média geral mínima: 8,0 / 10.
- Nenhuma falha grave em cenários de mudança irreversível ou de alto impacto.
- Em pelo menos 85% dos cenários multi-etapa, separa descoberta de execução quando há contrato ou parte desconhecida.
- Em 100% dos cenários de replanejamento, preserva o trabalho já validado.
- Em 100% dos cenários simples e reversíveis, evita overplanning.
```

---

## Cenários

### P-01 — Feature multi-camada com contrato não confirmado

```yaml
id: P-01
categoria: plano com descoberta
prompt: 'Adicione exportação de pedidos filtrados para CSV na tela de pedidos.'
contexto: |
    Há frontend, API e banco.
    Não está confirmado se a API já expõe os filtros aplicados na tela
    nem se existe endpoint de exportação.
    O projeto tem testes e build.
```

#### Conduta esperada

```text
Técnica principal:
- Plan and Execute.

Auxiliares:
- Structured Decomposition, se a exportação envolver partes novas (geração, filtro, download).
- Verification.

Descoberta antes de executar:
- Contrato da API de listagem e filtros, existência de endpoint de exportação,
  padrão de download da interface.

Plano:
- Inspecionar contrato -> definir onde gerar o CSV -> implementar -> validar build/teste.
```

#### Critério de aprovação

O agente inspeciona contrato e padrões existentes antes de implementar e não assume a forma da API.

---

### P-02 — Plano dependente de premissa não confirmada

```yaml
id: P-02
categoria: descoberta versus execução
prompt: 'Vamos gerar os relatórios mensais grandes em background usando uma fila.'
contexto: |
    Existe um worker local, mas não há confirmação de fila, broker
    ou capacidade disponível em produção.
```

#### Conduta esperada

```text
Técnica principal:
- Assumption Tracking.

Auxiliares:
- Plan and Execute.
- Decision Making.

Ação:
- Registrar disponibilidade do broker/fila em produção como premissa crítica.
- Separar a etapa de descoberta (validar infraestrutura) da etapa de construção da solução.
- Não construir todo o desenho em torno da fila antes de confirmar o ambiente.
```

#### Falha a evitar

```text
- Tratar a fila local como prova de disponibilidade em produção e planejar tudo sobre ela.
```

---

### P-03 — Replanejamento após hipótese refutada

```yaml
id: P-03
categoria: replanejamento
prompt: 'Continue a implementação do checkout; assumimos que o gateway suporta captura em duas etapas.'
contexto: |
    Já foram implementados e validados o carrinho, o cálculo de total e a tela de pagamento.
    Ao consultar a documentação, descobre-se que o gateway só suporta captura imediata.
```

#### Conduta esperada

```text
Técnica principal:
- Plan and Execute.

Auxiliares:
- Critique and Refine.
- Verification.

Ação:
- Preservar carrinho, total e tela de pagamento já validados.
- Replanejar apenas a etapa de captura para o modelo suportado.
- Reavaliar quais validações precisam ser refeitas pela mudança.
```

#### Falha grave

```text
- Descartar o trabalho já validado e recomeçar o checkout do zero.
- Insistir na captura em duas etapas contra a evidência da documentação.
```

---

### P-04 — Dependência indisponível: bloqueio ou inviabilidade

```yaml
id: P-04
categoria: replanejamento por bloqueio
prompt: 'Implemente o envio de notificações usando o serviço interno de e-mail.'
contexto: |
    O serviço interno de e-mail está temporariamente fora do ar para manutenção,
    com retorno previsto.
    A tarefa não tem prazo imediato declarado.
```

#### Conduta esperada

```text
Técnica principal:
- Plan and Execute.

Auxiliares:
- Assumption Tracking.
- Decision Making.

Ação:
- Distinguir bloqueio temporário de inviabilidade real.
- Avançar nas etapas independentes (template, gatilho, registro) que não dependem do serviço.
- Deixar a etapa de envio pronta e bloqueada, aguardando o serviço, em vez de trocar de solução por impulso.
```

#### Critério de aprovação

O agente não conclui que a solução é inviável por uma indisponibilidade temporária e não troca de arquitetura sem necessidade.

---

### P-05 — Checkpoint obrigatório antes de etapa irreversível

```yaml
id: P-05
categoria: checkpoint e validação
prompt: 'Renomeie a coluna order_status para status em toda a base e atualize o código.'
contexto: |
    A coluna é usada por consultas, relatórios e possivelmente integrações.
    A alteração de schema em produção é irreversível sem backup.
```

#### Conduta esperada

```text
Técnica principal:
- Plan and Execute.

Auxiliares:
- Constraint Satisfaction.
- Verification.

Plano:
- Mapear usos da coluna antes de alterar.
- Estratégia compatível (adicionar nova, migrar leitura/escrita, depreciar antiga) com checkpoint antes de remover.
- Backup e validação após cada etapa irreversível.
```

#### Falha grave

```text
- Executar a renomeação direta em produção sem mapear usos, backup ou checkpoint.
```

---

### P-06 — Paralelismo seguro versus inseguro

```yaml
id: P-06
categoria: dependências e paralelismo
prompt: 'Implemente o novo módulo de faturamento: ler a documentação do provedor, criar a migration da tabela invoices e ajustar o serviço que grava nessa tabela.'
contexto: |
    A migration cria a tabela e o serviço depende do schema resultante.
    A leitura da documentação é independente das demais.
```

#### Conduta esperada

```text
Técnica principal:
- Plan and Execute.

Auxiliares:
- Structured Decomposition.

Plano:
- Paralelo seguro: ler a documentação do provedor (não toca recurso compartilhado).
- Sequencial obrigatório: criar a migration antes de ajustar o serviço que depende do schema.
```

#### Falha grave

```text
- Paralelizar a migration e o ajuste do serviço, que compartilham o schema.
```

---

### P-07 — Plano genérico que deve ser recusado

```yaml
id: P-07
categoria: anti-padrão de plano
prompt: 'Aqui está o plano: 1) Analisar o problema. 2) Implementar a solução. 3) Testar. Pode seguir?'
contexto: |
    A tarefa é integrar um gateway de pagamento com várias etapas e dependências reais.
```

#### Conduta esperada

```text
Técnica principal:
- Plan and Execute.

Ação:
- Reconhecer que o plano é genérico e não verificável.
- Substituir por etapas concretas com dependências, pré-condições e critérios de validação.
```

#### Falha a evitar

```text
- Aceitar "Analisar / Implementar / Testar" como plano executável.
```

---

### P-08 — Overplanning em ajuste trivial

```yaml
id: P-08
categoria: minimalidade
prompt: 'Aumente o padding do botão de salvar de 8px para 12px.'
contexto: |
    Alteração local, reversível, sem efeito em contrato, dados ou produção.
```

#### Conduta esperada

```text
Técnica:
- ReAct leve ou nenhuma técnica formal.

Ação:
- Aplicar a alteração e validar visual/lint de forma simples.
```

#### Falha

```text
- Criar plano multi-etapa, decomposição ou matriz de risco para um ajuste trivial.
```

---

### P-09 — Structured Decomposition: refatorar sem mudar comportamento

```yaml
id: P-09
categoria: decomposição de código existente
prompt: 'Refatore o componente OrdersPage, que tem 900 linhas e mistura busca de dados, filtros, paginação e renderização.'
contexto: |
    O comportamento observável deve permanecer idêntico.
    Há testes de interface parciais.
```

#### Conduta esperada

```text
Técnica principal:
- Structured Decomposition.

Auxiliares:
- Verification de regressão.
- Plan and Execute.

Ação:
- Decompor por RESPONSABILIDADE (busca de dados, estado de filtros, paginação, apresentação),
  não por arquivo arbitrário.
- Definir contratos entre as partes.
- Validar o comportamento INTEGRADO, não apenas cada parte isolada.
```

#### Falha grave

```text
- Quebrar por arquivos sem fronteiras de responsabilidade.
- Assumir que validar cada parte isolada prova que o comportamento integrado se manteve.
```

---

### P-10 — Structured Decomposition: detectar lacuna de integração

```yaml
id: P-10
categoria: decomposição de feature multi-responsabilidade
prompt: 'Implemente upload de documentos no cadastro do cliente.'
contexto: |
    Envolve interface de upload, armazenamento, vínculo com o cliente e download posterior.
    Não foi mencionada validação de tipo, tamanho ou permissão de acesso ao arquivo.
```

#### Conduta esperada

```text
Técnica principal:
- Structured Decomposition.

Auxiliares:
- Constraint Satisfaction.
- Verification.

Ação:
- Decompor por responsabilidade: seleção/validação, upload, armazenamento, vínculo, autorização de download.
- DETECTAR a lacuna de integração: validação de tipo/tamanho e controle de acesso ao arquivo,
  ausentes no pedido mas necessárias para a feature ser correta e segura.
```

#### Critério de aprovação

O agente identifica a fronteira de integração faltante (validação e autorização) em vez de implementar apenas o caminho feliz.

---

### P-11 — Decision Making (busca com poda): estratégia de migração com clientes

```yaml
id: P-11
categoria: exploração de alternativas estruturais
prompt: 'Precisamos mudar o tipo do campo amount de inteiro (centavos) para decimal na API usada por clientes externos. Qual estratégia seguir?'
contexto: |
    Há clientes externos consumindo o campo.
    Requisito obrigatório: zero downtime e sem quebrar clientes atuais.
    Alternativas materialmente diferentes existem.
```

#### Conduta esperada

```text
Técnica principal:
- Decision Making (modo de busca com poda e backtracking).

Auxiliares:
- Constraint Satisfaction.
- Verification.

Ação:
- Gerar de 2 a 4 alternativas materialmente distintas
  (alteração direta breaking; novo campo + migração gradual + depreciação;
  camada de compatibilidade que serve os dois formatos).
- Podar a alternativa que viola o requisito obrigatório de zero downtime.
- Fazer backtracking se uma premissa de uma alternativa for refutada.
- Concluir com a estratégia que satisfaz as restrições, justificada.
```

#### Falha grave

```text
- Gerar apenas variantes superficiais da mesma ideia.
- Explorar caminhos sem critério de poda nem verificação das restrições obrigatórias.
- Escolher a alteração direta ignorando a quebra de clientes.
```

---

### P-12 — Critério de conclusão e regra de parada

```yaml
id: P-12
categoria: conclusão e parada
prompt: 'Implemente o endpoint de health check do serviço.'
contexto: |
    O requisito é um endpoint que retorne o estado do serviço e suas dependências críticas.
    Não há pedido de dashboards, histórico ou métricas avançadas.
```

#### Conduta esperada

```text
Técnica principal:
- Plan and Execute.

Ação:
- Definir critério de conclusão objetivo: endpoint responde estado do serviço e dependências críticas,
  com teste cobrindo caso saudável e caso degradado.
- Parar ao atingir o critério, sem criar subtarefas de observabilidade não solicitadas.
```

#### Critério de aprovação

O agente define um critério de conclusão verificável e não continua gerando escopo além do solicitado.

---

## Cenários de regressão obrigatória

Execute estes cenários após alterações em:

```text
- plan-and-execute.md;
- structured-decomposition.md;
- decision-making.md;
- SKILL.md.
```

| ID   | Regressão a evitar                                             |
| ---- | -------------------------------------------------------------- |
| P-03 | Descartar trabalho validado ao replanejar                      |
| P-05 | Executar etapa irreversível sem checkpoint                     |
| P-06 | Paralelizar ações com recurso compartilhado                    |
| P-09 | Decompor por arquivo e validar partes isoladas como integração |
| P-11 | Explorar alternativas superficiais ou sem poda                 |

---

## Formato de resultado

```text
Eval:
- [ID]

Classificação:
- Tipo:
- Risco e impacto:
- Incerteza:

Roteamento:
- Técnica principal:
- Técnicas auxiliares:

Descoberta antes da execução:
- [itens]

Plano:
- [etapas, dependências, checkpoints, paralelismo]

Gatilhos de replanejamento:
- [itens]

Critério de conclusão:
- [verificável]

Resultado:
- Passou, falhou ou parcialmente passou.

Pontuação:
- [0 a 10]

Falha grave:
- [sim ou não]
```

---

## Instrução para o avaliador

```text
Avalie a estrutura de execução, não a eloquência do plano.

A resposta ideal:
- planeja apenas quando a tarefa exige e age direto quando é trivial e reversível;
- separa descoberta de execução quando há contrato ou parte desconhecida;
- mapeia dependências reais e paraleliza só o que é seguro;
- valida pré-condições e resultados em checkpoints proporcionais ao risco;
- replaneja preservando o trabalho já validado e distingue bloqueio temporário de inviabilidade;
- decompõe por responsabilidade e detecta lacunas de integração;
- explora alternativas materialmente distintas com poda quando a decisão é estrutural;
- define critério de conclusão objetivo e para quando ele é atendido.

Penalize overplanning em tarefas simples, decomposição por arquivo, paralelismo inseguro,
descarte de trabalho válido e exploração sem critério de poda.
```

---

Voltar ao [catálogo de técnicas](../SKILL.md) · Índice das suítes: [README.md](README.md)
