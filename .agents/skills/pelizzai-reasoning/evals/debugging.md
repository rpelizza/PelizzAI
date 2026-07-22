# Debugging Evals

## Objetivo

Este arquivo avalia se a skill [pelizzai-reasoning](../SKILL.md) conduz debugging e investigação de incidentes de forma confiável.

O agente deve ser capaz de:

```text
- reconhecer quando um erro é direto e quando exige investigação;
- diferenciar sintoma, causa imediata, causa raiz e fatores contribuintes;
- preservar evidência mínima antes de contenção e coletar evidência diagnóstica antes do fix definitivo;
- formular uma ou mais hipóteses conforme a incerteza, sem quantidade ritual;
- selecionar testes e observações com alto valor informacional;
- evitar conclusões baseadas em correlação, memória ou primeira impressão;
- aplicar contenção proporcional quando houver impacto ativo;
- corrigir mecanismo causal, não apenas sintoma;
- validar cenário original, regressões e prevenção de recorrência.
```

Este eval não mede apenas se o agente encontrou uma resposta plausível. Mede se o processo de investigação foi seguro, verificável e proporcional ao risco.

## Técnicas avaliadas

| Técnica                                                             | Uso esperado                                                |
| ------------------------------------------------------------------- | ----------------------------------------------------------- |
| [ReAct](../techniques/react.md)                                     | Inspecionar, testar, observar e atualizar hipóteses         |
| [Root Cause Analysis](../techniques/root-cause-analysis.md)         | Investigar incidentes, recorrência e causas estruturais     |
| [Evidence Synthesis](../techniques/evidence-synthesis.md)           | Combinar logs, código, testes, métricas e documentação      |
| [Assumption Tracking](../techniques/assumption-tracking.md)         | Registrar hipóteses e premissas ainda abertas               |
| [Verification](../techniques/verification.md)                       | Confirmar causa e validar correção                          |
| [Critique and Refine](../techniques/critique-and-refine.md)         | Ajustar correção após falha, review ou regressão            |
| [Constraint Satisfaction](../techniques/constraint-satisfaction.md) | Preservar contratos legados e requisitos de compatibilidade |
| [Decision Making](../techniques/decision-making.md)                 | Escolher contenção reversível sob dano ativo                 |

## Protocolo de avaliação

O agente deve responder ao cenário com uma estratégia compacta, sem expor cadeia de pensamento detalhada.

Formato esperado:

```text
Classificação:
- Tipo: bug direto, bug multi-camada, incidente, regressão ou diagnóstico de ambiente.
- Impacto:
- Escopo:
- Urgência:
- Técnica principal:
- Técnicas auxiliares:

Fatos confirmados:
- [somente observações diretas]

Hipóteses relevantes (omita pluralidade quando a causa direta já estiver provada):
1. [hipótese]
   - Evidência necessária:
   - Próxima validação:
   - Critério de descarte:

Ação imediata:
- [contenção, investigação, correção direta, rollback ou nenhuma]

Correção esperada:
- [somente após confirmação suficiente]

Validação:
- [cenário original, regressões e observabilidade]
```

Não é obrigatório listar todas as hipóteses possíveis. O agente deve priorizar as materialmente plausíveis.

## Rubrica

Cada cenário vale 10 pontos.

| Critério      | Pontos | Descrição                                                       |
| ------------- | -----: | --------------------------------------------------------------- |
| Classificação |      1 | Distingue erro simples, bug estrutural, incidente ou regressão  |
| Evidências    |      2 | Separa fatos observados de suposições e busca fontes adequadas  |
| Hipóteses     |      2 | Usa quantidade proporcional e critérios de confirmação/descarte |
| Próxima ação  |      1 | Escolhe contenção, investigação ou correção direta proporcional |
| Correção      |      2 | Ataca mecanismo causal, não apenas sintoma                      |
| Validação     |      2 | Inclui reprodução, testes relacionados e prevenção de regressão |

### Falhas graves

As falhas graves globais (assumir causa raiz sem evidência, alterar produção por tentativa e erro, workaround temporal como correção, ignorar contenção sob impacto ativo, corrigir só o frontend sob risco estrutural, expor segredos etc.) estão catalogadas no índice de evals — ver [README.md](README.md). Acionar qualquer uma delas limita o cenário a no máximo 3 pontos.

## Critérios globais de aprovação

A implementação passa neste conjunto quando:

```text
- Média geral mínima: 8,0 / 10.
- Nenhuma falha grave nos cenários de produção, segurança, duplicidade ou perda de dados.
- Em pelo menos 85% dos cenários multi-camada, o agente distingue sintoma de causa provável.
- Em pelo menos 80% dos cenários, a correção proposta inclui validação de regressão.
- Nenhum cenário de incidente crítico é tratado apenas com mudança visual ou atraso temporal.
```

## Cenários

### D-01 — Erro de import evidente

```yaml
id: D-01
categoria: bug direto
prompt: "O build falha com Cannot find module './users.service'. O arquivo real se chama './user.service'."
contexto: |
    O erro ocorre localmente e no CI.
    Não há outro sintoma relatado.
```

#### Conduta esperada

```text
Técnica:
- ReAct leve + Verification.

Ação:
- Corrigir import.
- Executar typecheck, build ou teste afetado.

Não usar:
- Root Cause Analysis completa.
- Plano extenso.
```

Também não usar o modo de busca com poda da [Decision Making](../techniques/decision-making.md): o espaço de causas é determinístico e não há caminhos interdependentes a ramificar.

#### Critério de aprovação

O agente não inventa causa estrutural nem realiza investigação excessiva.

### D-02 — Endpoint lento sob alto volume

```yaml
id: D-02
categoria: performance
prompt: 'O endpoint GET /orders demora mais de 12 segundos para alguns clientes.'
contexto: |
    O endpoint faz consulta ao banco, serializa pedidos e chama uma API externa
    para enriquecer parte da resposta.
    Não há profiling disponível ainda.
```

#### Conduta esperada

```text
Técnica principal:
- Root Cause Analysis.

Auxiliares:
- ReAct.
- Evidence Synthesis.
- Verification.

Evidências prioritárias:
- Latência por etapa.
- Plano de execução da query.
- Número de queries.
- Tempo de chamada externa.
- Tamanho de payload.
- Volume de registros.
```

#### Falhas a evitar

```text
- Adicionar cache sem medir o gargalo.
- Concluir que o banco é lento sem profiling.
- Migrar para microserviços como primeira resposta.
```

### D-03 — Pedidos duplicados

```yaml
id: D-03
categoria: incidente distribuído
prompt: 'Pedidos estão sendo criados duas vezes em produção.'
contexto: |
    Há frontend, gateway, API, banco e worker.
    Usuários relatam clique duplo, mas não há evidência confirmada.
    O sistema permite retry de requisições e reprocessamento de mensagens.
```

#### Conduta esperada

```text
Técnica principal:
- Root Cause Analysis.

Ação imediata:
- Verificar impacto e aplicar contenção reversível se necessário.
- Preservar logs, request IDs, correlation IDs, dados de fila e registros duplicados.

Hipóteses:
- Clique duplo.
- Retry de cliente.
- Retry de gateway.
- Ausência de idempotência.
- Worker reprocessando mensagem.
- Banco permitindo duplicidade.

Correção estrutural esperada:
- Idempotência e proteção de persistência.
```

#### Falha grave

```text
- Resolver apenas com debounce ou setTimeout na interface.
- Declarar clique duplo como causa raiz sem verificar requests e persistência.
```

#### Exemplo resolvido de pontuação

Aplicação da rubrica a uma resposta para D-03 que ataca só o sintoma:

```text
Resposta avaliada (resumo):
- Classifica como "clique duplo no botão".
- Propõe debounce de 300 ms no frontend.
- Valida só clicando uma vez na tela.

Pontuação por critério:
- Classificação (1): 0 — trata incidente distribuído como bug de UI.
- Evidências (2): 0 — não separa relato de fato; não preserva request/correlation IDs.
- Hipóteses (2): 0 — fixa a 1ª hipótese, ignora retry, worker e idempotência.
- Próxima ação (1): 0 — nenhuma contenção reversível sob impacto em produção.
- Correção (2): 0 — debounce não trata o mecanismo causal (criação dupla persistida).
- Validação (2): 0 — não reproduz no caminho real nem cobre regressão.

Total bruto: 0/10.
Falha grave acionada (debounce como correção + causa raiz sem evidência) -> teto de 3.
Pontuação final: 0/10. Resultado: falhou.
```

### D-04 — Falha de autenticação só em produção

```yaml
id: D-04
categoria: ambiente
prompt: 'O login funciona localmente, mas retorna 401 em produção desde o último deploy.'
contexto: |
    Possíveis diferenças: variáveis de ambiente, segredo JWT, algoritmo,
    URL de callback, proxy, clock do servidor, versão de biblioteca.
```

#### Conduta esperada

```text
Técnica principal:
- Root Cause Analysis.

Auxiliares:
- Evidence Synthesis.
- Assumption Tracking.
- ReAct.

Ação:
- Comparar ambiente saudável e ambiente com falha.
- Inspecionar configurações sem expor segredos.
- Revisar diff de deploy e logs de autenticação.
- Considerar rollback como contenção se impacto for relevante.
```

#### Falhas a evitar

```text
- Pedir ou exibir segredo JWT.
- Trocar credenciais por tentativa e erro.
- Assumir que o deploy é causa apenas por precedência temporal.
```

### D-05 — Dados desatualizados na interface

```yaml
id: D-05
categoria: estado e cache
prompt: 'Depois de editar um pedido, a tela continua mostrando o valor antigo por alguns minutos.'
contexto: |
    A API retorna o valor atualizado imediatamente.
    Existe cache no navegador e cache distribuído no backend.
    Não está claro qual camada entrega o dado antigo.
```

#### Conduta esperada

```text
Técnica principal:
- Root Cause Analysis.

Hipóteses:
- Cache local da interface não foi invalidado.
- Query cache possui stale time incorreto.
- Cache distribuído não foi invalidado.
- Endpoint de leitura usa réplica atrasada.
- A interface renderiza estado antigo.

Evidência prioritária:
- Response real da API.
- Headers de cache.
- Chaves e TTL.
- Estado da query na interface.
- Fonte do dado exibido.
```

#### Critério de aprovação

O agente não conclui "é cache" sem localizar a camada e mecanismo específicos.

### D-06 — Regressão após alteração de validação

```yaml
id: D-06
categoria: regressão
prompt: 'Após adicionar validação de CPF, o teste de criação de usuário falha.'
contexto: |
    O teste anterior usava um identificador inválido.
    Não está definido se a alteração de regra era desejada para todos os fluxos,
    inclusive seeds, fixtures, ambiente de teste e integrações legadas.
```

#### Conduta esperada

```text
Técnica principal:
- Critique and Refine.

Auxiliares:
- Verification.
- ReAct.

Ação:
- Comparar nova regra, requisitos e dados de teste.
- Decidir se o teste deve mudar, se a validação deve ser contextual
  ou se há contrato legado a preservar.
```

Use [Constraint Satisfaction](../techniques/constraint-satisfaction.md) quando houver requisito de compatibilidade entre fluxos (seeds, fixtures, integrações legadas).

#### Falha a evitar

```text
- Apenas trocar o CPF do teste sem confirmar se todos os fluxos devem ser validados.
```

### D-07 — Worker processa mensagem duas vezes

```yaml
id: D-07
categoria: mensageria
prompt: 'Alguns e-mails transacionais são enviados duas vezes.'
contexto: |
    A fila usa entrega ao menos uma vez.
    O worker pode reiniciar durante processamento.
    Não existe confirmação se o provedor recebeu duas solicitações
    ou se o worker publicou duas vezes.
```

#### Conduta esperada

```text
Técnica principal:
- Root Cause Analysis.

Hipóteses:
- Mensagem foi entregue novamente após falha antes do ack.
- Worker publicou duas vezes.
- Retry do provedor ocorreu.
- Falta de chave de deduplicação.
- Estado de envio não foi persistido de forma idempotente.

Correção esperada:
- Idempotência e rastreabilidade por identificador de mensagem.
- Política explícita de retry.
- Registro de envio antes ou durante execução conforme semântica escolhida.
```

#### Falha grave

```text
- Tentar "garantir exatamente uma vez" apenas ajustando retry sem tratar idempotência.
```

### D-08 — Erro intermitente em upload

```yaml
id: D-08
categoria: intermitência
prompt: 'Uploads grandes falham aleatoriamente com 502.'
contexto: |
    O problema ocorre apenas em produção.
    Pode haver proxy, timeout, limite de tamanho, memória,
    storage externo, rede ou worker intermediário.
```

#### Conduta esperada

```text
Técnica principal:
- Root Cause Analysis.

Ação:
- Delimitar tamanho, tipo de arquivo, horário, região e frequência.
- Correlacionar logs do cliente, proxy, API e storage.
- Comparar configuração de timeout e limite de payload.
- Reproduzir de forma controlada com arquivos graduais.
```

#### Falhas a evitar

```text
- Aumentar todos os timeouts sem medir.
- Culpar rede sem evidência.
- Tratar 502 como erro exclusivo da aplicação.
```

### D-09 — Deploy recente e aumento de erro

```yaml
id: D-09
categoria: incidente após deploy
prompt: 'Cinco minutos após o deploy, a taxa de erro 500 aumentou de 0,2% para 18%.'
contexto: |
    O deploy incluiu alteração de configuração e mudança de código.
    Não há confirmação de causalidade.
    Usuários estão sendo afetados ativamente.
```

#### Conduta esperada

```text
Fase de contenção:
- Técnica principal: Constraint Satisfaction.
- Auxiliar: Decision Making; ReAct para executar; Verification para monitorar.

Ação imediata:
- Capturar métricas, logs e diff de versão.
- Avaliar e aplicar rollback ou desativação por feature flag como contenção reversível.
- Priorizar restauração do serviço antes de investigação longa.

Depois de estabilizar:
- Técnica principal: Root Cause Analysis.
- Comparar versão anterior e atual.
- Identificar erro por endpoint, stack trace e configuração.
```

#### Critério de aprovação

O agente separa contenção urgente de correção estrutural posterior.

### D-10 — Falha de autorização

```yaml
id: D-10
categoria: segurança
prompt: 'Um usuário comum conseguiu acessar o relatório administrativo de outro cliente.'
contexto: |
    Não se sabe se o problema está em frontend, backend, cache,
    tenant ID, token, rota ou regra de autorização.
    Há possível exposição de dados.
```

#### Conduta esperada

```text
Técnica principal:
- Root Cause Analysis.

Ação imediata:
- Conter exposição: desabilitar rota ou reforçar autorização no servidor.
- Preservar logs de acesso e escopo de dados expostos.
- Avaliar impacto e notificar responsável conforme regras aplicáveis.

Evidência:
- Request autenticado.
- Claims do token.
- Tenant ID.
- Regra de autorização no endpoint.
- Cache e chave de segmentação.
- Logs de acesso.
```

#### Falha grave

```text
- Corrigir apenas escondendo botão no frontend.
- Não tratar como incidente de segurança.
- Continuar expondo rota durante investigação sem avaliar contenção.
```

### D-11 — Cálculo divergente em relatório

```yaml
id: D-11
categoria: dados e cálculo
prompt: 'O relatório mensal mostra R$ 98.450, mas a planilha financeira mostra R$ 101.120.'
contexto: |
    O relatório usa agregação no banco.
    A planilha usa exportação com filtros.
    Não se sabe se a diferença vem de período, arredondamento,
    status excluído ou duplicidade.
```

#### Conduta esperada

```text
Técnica principal:
- Evidence Synthesis.

Auxiliares:
- Verification.
- Root Cause Analysis, caso haja defeito confirmado.

Ação:
- Normalizar período, timezone, filtros, status, arredondamento
  e fonte de dados antes de comparar números.
- Reproduzir cálculo com consulta rastreável.
```

#### Critério de aprovação

O agente não presume que uma das fontes está errada sem comparar critérios de cálculo.

### D-12 — Conflito de documentação e execução

```yaml
id: D-12
categoria: contrato e comportamento
prompt: 'A documentação diz que o endpoint aceita `status`, mas o ambiente atual retorna 400.'
contexto: |
    Pode haver documentação desatualizada, versão diferente,
    validação adicional, erro no request ou divergência de ambiente.
```

#### Conduta esperada

```text
Técnica principal:
- Evidence Synthesis.

Auxiliares:
- Verification.
- Assumption Tracking.

Ação:
- Comparar documentação, versão, schema, código e request real.
- Classificar o conflito antes de corrigir documentação ou código.
```

#### Falha a evitar

```text
- Escolher documentação ou ambiente automaticamente sem verificar escopo e versão.
```

### D-13 — Bug "resolvido" por timeout

```yaml
id: D-13
categoria: correção superficial
prompt: 'Um desenvolvedor adicionou setTimeout de 500 ms antes de buscar os dados e disse que resolveu a tela vazia.'
contexto: |
    A tela depende de estado de autenticação e perfil do usuário.
    Não há evidência de que atraso temporal seja requisito do fluxo.
```

#### Conduta esperada

```text
Técnica principal:
- Critique and Refine.

Auxiliares:
- Root Cause Analysis.
- Verification.

Ação:
- Identificar dependência real entre autenticação, carregamento de perfil,
  estado da interface e chamada de dados.
- Remover atraso arbitrário se não for requisito legítimo.
- Corrigir sincronização, estado ou condição de disparo.
```

#### Falha grave

```text
- Aceitar setTimeout como correção definitiva sem explicar mecanismo causal.
```

### D-14 — Falha por condição de corrida

```yaml
id: D-14
categoria: concorrência
prompt: 'Dois administradores aprovam o mesmo pedido quase ao mesmo tempo e o estoque é debitado duas vezes.'
contexto: |
    A ação passa por API e banco.
    Não existe confirmação sobre transação, lock, versionamento otimista,
    unicidade ou idempotência.
```

#### Conduta esperada

```text
Técnica principal:
- Root Cause Analysis.

Evidência:
- Linha do tempo dos dois requests.
- Estado antes e depois.
- Transações.
- Locks.
- Versão de registro.
- Query de atualização.
- Eventos emitidos.

Correção estrutural possível:
- Controle de concorrência apropriado, transação, lock,
  versionamento otimista ou operação atômica, conforme evidência.
```

#### Falha grave

```text
- Adicionar apenas confirmação visual ou delay entre cliques.
```

### D-15 — Falha não reproduzível com logs insuficientes

```yaml
id: D-15
categoria: investigação inconclusiva
prompt: 'Uma vez por semana um cliente recebe erro 500, mas não há stack trace nem request ID.'
contexto: |
    O problema não foi reproduzido localmente.
    Logs atuais são genéricos e não permitem correlacionar eventos.
```

#### Conduta esperada

```text
Técnica principal:
- Root Cause Analysis.

Ação:
- Não inventar causa.
- Declarar investigação inconclusiva.
- Melhorar observabilidade: request ID, contexto seguro, stack trace,
  métrica por endpoint, versão e correlação de eventos.
- Definir estratégia de captura para próxima ocorrência.
```

#### Critério de aprovação

O agente reconhece ausência de evidência como limitação, não como prova de causa inexistente.

### D-16 — Bug lógico determinístico local

```yaml
id: D-16
categoria: bug lógico determinístico
prompt: 'Uma função que pagina resultados omite o último item de cada página e às vezes repete o primeiro da página seguinte.'
contexto: |
    A função roda em memória, sem rede nem banco.
    O dataset de entrada é fixo e o defeito reproduz sempre.
    Suspeita de off-by-one no cálculo de offset/limit ou na condição de corte.
```

#### Conduta esperada

```text
Técnica principal:
- Root Cause Analysis leve (defeito determinístico e local).

Auxiliares:
- Verification.

Ação:
- Reproduzir com entrada mínima e saída esperada explícita.
- Inspecionar o cálculo de índice/limite e a condição de fronteira (<, <=, offset base 0 vs 1).
- Corrigir a aritmética de fronteira, não mascarar com filtro a posteriori.

Validação:
- Teste de borda: primeira página, última página, página única e lista vazia.
- Verificar ausência de itens omitidos ou duplicados em todas as fronteiras.
```

#### Critério de aprovação

O agente isola a fronteira exata e cobre os casos de borda, sem propor refator amplo para um defeito de uma linha.

### D-17 — Falsa causa raiz desmentida pela evidência

```yaml
id: D-17
categoria: hipótese plausível refutada
prompt: 'Após um pico de timeouts no checkout, a primeira hipótese foi "o banco está sobrecarregado". Antes de escalar o banco, peça confirmação.'
contexto: |
    A hipótese inicial plausível é saturação do banco.
    As métricas mostram CPU e conexões do banco baixas no período,
    mas latência alta concentrada nas chamadas a um gateway de pagamento externo.
```

#### Conduta esperada

```text
Técnica principal:
- Root Cause Analysis.

Auxiliares:
- Evidence Synthesis.
- Assumption Tracking.

Ação:
- Tratar "banco sobrecarregado" como hipótese, não como fato.
- Buscar a evidência que diferencia: latência por dependência, CPU/conexões do banco,
  tempo das chamadas ao gateway externo.
- Descartar a 1ª hipótese ao ver banco ocioso e latência no gateway.
- Reorientar para a dependência externa (timeout, retry, circuit breaker, contenção).

Validação:
- Confirmar correlação temporal entre picos de latência e o gateway.
- Validar que a correção no gateway/limite elimina os timeouts no cenário original.
```

#### Falha a evitar

```text
- Escalar ou reconfigurar o banco com base na 1ª hipótese, sem evidência que a sustente.
- Manter a hipótese inicial após a evidência apontar para a dependência externa.
```

## Cenários de regressão obrigatória

Execute estes cenários após alterações em:

```text
- root-cause-analysis.md;
- react.md;
- verification.md;
- evidence-synthesis.md;
- critique-and-refine.md;
- SKILL.md.
```

Arquivos de técnica citados: [Root Cause Analysis](../techniques/root-cause-analysis.md), [ReAct](../techniques/react.md), [Verification](../techniques/verification.md), [Evidence Synthesis](../techniques/evidence-synthesis.md), [Critique and Refine](../techniques/critique-and-refine.md), e a skill [pelizza-reasoning](../SKILL.md).

| ID   | Regressão a evitar                                |
| ---- | ------------------------------------------------- |
| D-01 | Usar RCA em erro direto                           |
| D-03 | Corrigir duplicidade apenas no frontend           |
| D-04 | Expor ou alterar credenciais por tentativa e erro |
| D-05 | Culpar cache sem identificar camada               |
| D-07 | Ignorar semântica de entrega ao menos uma vez     |
| D-09 | Investigar antes de conter incidente ativo        |
| D-10 | Tratar segurança como erro de interface           |
| D-13 | Aceitar timeout como correção estrutural          |
| D-14 | Resolver concorrência com delay                   |
| D-15 | Inventar causa sem evidência                      |
| D-16 | Refatorar amplo em vez de corrigir a fronteira    |
| D-17 | Manter a 1ª hipótese após evidência refutá-la     |

Conjunto irmão de cenários de regressão geral: [regression.md](regression.md).

## Formato de resultado

```text
Eval:
- [ID]

Classificação:
- Tipo:
- Impacto:
- Escopo:
- Urgência:

Roteamento:
- Técnica principal:
- Técnicas auxiliares:

Fatos confirmados:
- [itens]

Hipóteses relevantes:
- [itens]

Ação imediata:
- [contenção, investigação, correção ou rollback]

Correção estrutural:
- [proposta ou "ainda não definida"]

Validação:
- [reprodução, testes, regressões e monitoramento]

Resultado:
- Passou, falhou ou parcialmente passou.

Pontuação:
- [0 a 10]

Falha grave:
- [sim ou não]
```

## Instrução para o avaliador

```text
Avalie o método, não apenas a plausibilidade da solução.

A resposta ideal:
- começa por fatos observáveis;
- trata hipóteses como hipóteses;
- escolhe evidência que diferencia hipóteses;
- protege o sistema antes de investigar longamente quando há impacto ativo;
- propõe correções estruturais apenas após evidência suficiente;
- valida cenário original, casos relacionados e prevenção de recorrência;
- declara limitação quando não há dados suficientes.

Penalize conclusões rápidas, workarounds temporais, alterações por tentativa e erro, ausência de contenção e validação decorativa.
```
