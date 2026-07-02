# Research Evals

## Objetivo

Este arquivo avalia se [`pelizzai-reasoning`](../SKILL.md) conduz pesquisas e recomendações baseadas em evidências de maneira confiável.

O agente deve ser capaz de:

- reconhecer quando informação atual, versão específica ou fonte externa exige pesquisa, e responder diretamente quando pesquisa não é necessária;
- definir exatamente o que precisa ser confirmado;
- priorizar fontes primárias, oficiais e adequadas ao domínio;
- distinguir documentação, código, testes, changelog, anúncio, notícia, opinião e fórum;
- comparar fontes conflitantes sem escolher arbitrariamente, considerando data, versão, ambiente, escopo e aplicabilidade;
- separar fato confirmado, inferência, hipótese, recomendação e desconhecido;
- evitar citações decorativas ou que não sustentam a conclusão;
- declarar limitação quando não houver evidência suficiente.

Este eval não mede apenas se a resposta contém links ou fontes: mede se o agente usa evidência correta para a pergunta correta.

## Técnicas avaliadas

| Técnica                                                             | Uso esperado                                                          |
| ------------------------------------------------------------------- | --------------------------------------------------------------------- |
| [Evidence Synthesis](../techniques/evidence-synthesis.md)           | Combinar fontes, comparar conflitos e produzir conclusão proporcional |
| [Verification](../techniques/verification.md)                       | Confirmar afirmações críticas ou dependentes de versão                |
| [Assumption Tracking](../techniques/assumption-tracking.md)         | Registrar premissas abertas, lacunas ou dependências não verificadas  |
| [Decision Making](../techniques/decision-making.md)                 | Escolher alternativa em recomendações com trade-offs                  |
| [Constraint Satisfaction](../techniques/constraint-satisfaction.md) | Filtrar opções por requisitos, proibições e compatibilidade           |
| [Self-Consistency](../techniques/self-consistency.md)               | Cruzar tentativas independentes como apoio à Verification (usada em S-13) |

## Protocolo de avaliação

Antes de responder completamente, o agente deve produzir uma estratégia compacta:

```text
Classificação:
- Tipo: explicação estável, fato atual, pesquisa técnica, comparação, recomendação ou conflito de fontes.
- Atualidade necessária:
- Versão, data ou escopo relevante:
- Risco de erro:
- Técnica principal:
- Técnicas auxiliares:

Pergunta de pesquisa:
- [o que precisa ser confirmado]

Fontes prioritárias:
- [tipos de fonte ou fonte oficial esperada]

Critérios de suficiência:
- [qual evidência permitiria concluir]

Limitações previsíveis:
- [o que pode permanecer sem confirmação]
```

Depois da pesquisa, a resposta deve conter somente o necessário:

```text
Conclusão:
- [resultado principal]

Evidências:
- [fontes e fatos relevantes]

Limitações:
- [lacunas, conflito, diferença de versão, ambiente ou escopo]

Nível de confiança:
- [alto, médio ou baixo]
```

O agente não deve expor cadeia de pensamento detalhada.

## Rubrica

Cada cenário vale 10 pontos.

| Critério                   | Pontos | Descrição                                          |
| -------------------------- | -----: | -------------------------------------------------- |
| Necessidade de pesquisa    |      1 | Pesquisa quando necessário e evita pesquisa inútil |
| Pergunta e escopo          |      1 | Define fato, versão, data ou condição a confirmar  |
| Qualidade das fontes       |      2 | Prioriza fonte apropriada e próxima do fato        |
| Síntese e conflitos        |      2 | Compara fontes, versões, escopo e divergências     |
| Fatos e inferências        |      1 | Não apresenta hipótese ou opinião como fato        |
| Recomendação               |      1 | Usa critérios e trade-offs quando há escolha       |
| Limitações e confiança     |      1 | Declara lacunas e confiança proporcional           |
| Citações e rastreabilidade |      1 | Usa evidência que sustenta afirmações centrais     |

Faixas de resultado por cenário: **Passou** = 8-10; **Parcial** = 4-7; **Falhou** = 0-3 (ou qualquer falha grave, que limita o teto a 3).

### Falhas graves

O cenário recebe no máximo 3 pontos se o agente:

```text
- responde por memória quando a pergunta depende de fato atual, versão, preço, regra, cargo, política ou disponibilidade;
- usa fonte secundária ou informal para substituir fonte primária disponível;
- cita fonte que não sustenta a afirmação apresentada;
- ignora conflito material entre fontes;
- usa documentação de versão diferente sem declarar a limitação;
- recomenda produto, biblioteca ou serviço sem considerar requisitos explícitos;
- trata ausência de evidência como prova de ausência;
- declara certeza alta sem evidência proporcional;
- inventa busca, teste, fonte ou resultado.
```

## Calibração de confiança

O nível de confiança declarado deve ser proporcional à evidência. Confiança esperada por tipo de cenário:

| Tipo de cenário                                                              | Confiança esperada quando bem resolvido |
| ---------------------------------------------------------------------------- | --------------------------------------- |
| Conceito estável ou fonte primária fornecida (S-01, S-15, S-20)              | Alto                                    |
| Fato atual confirmado em fonte oficial (S-02, S-03, S-04, S-16, S-17)        | Alto, com data ou versão                |
| Conflito, comparação ou benchmark (S-05, S-06, S-07, S-11, S-12, S-13, S-19) | Médio até separar escopo ou critérios   |
| Recomendação sob requisitos abertos (S-08, S-09, S-14)                       | Baixo até definir critérios materiais   |
| Evidência negativa ou inconclusiva (S-10, S-18)                              | Baixo, declarando inconclusivo          |

Declarar confiança alta sem evidência proporcional, ou baixa quando a fonte primária já resolve, é desvio de calibração.

## Critérios globais de aprovação

A implementação passa neste conjunto quando:

```text
- Média geral mínima: 8,0 / 10.
- Nenhuma falha grave em cenários de informação atual, segurança, preço, compatibilidade ou recomendação.
- Em pelo menos 85% dos cenários dependentes de versão, o agente declara e verifica a versão correta.
- Em pelo menos 80% dos cenários de conflito, o agente identifica escopo, tempo ou ambiente antes de concluir.
- Em 100% dos cenários estáveis e puramente conceituais, evita pesquisa desnecessária.
```

## Cenários

## S-01 — Conceito estável sem pesquisa

```yaml
id: S-01
categoria: explicação estável
prompt: 'Explique a diferença entre HTTP GET e POST.'
contexto: |
    O usuário quer uma explicação geral.
    Não pede regras atuais, framework específico ou comportamento de uma API.
```

### Conduta esperada

```text
Pesquisa:
- Não necessária.

Técnicas:
- Nenhuma técnica formal ou ReAct leve, se necessário.

Ação:
- Explicar diretamente com exemplos simples.
```

### Falha a evitar

```text
- Pesquisar documentação externa sem necessidade.
- Criar síntese de múltiplas fontes para conceito básico.
```

---

## S-02 — API com versão específica

```yaml
id: S-02
categoria: pesquisa técnica
prompt: 'A biblioteca X suporta OAuth com Google no FastAPI 0.115?'
contexto: |
    A biblioteca X e o FastAPI evoluem com frequência.
    O usuário não forneceu documentação.
```

### Conduta esperada

```text
Técnica principal:
- Evidence Synthesis.

Auxiliares:
- Verification.
- Assumption Tracking, se versão da biblioteca ou configuração não estiver definida.

Fontes prioritárias:
- Documentação oficial da biblioteca.
- Repositório e changelog oficial.
- Documentação do FastAPI para a versão relevante.
- Exemplo oficial ou teste mínimo, quando necessário.

Conclusão:
- Deve limitar afirmações ao fluxo e versões confirmados.
```

### Falha grave

```text
- Responder somente com conhecimento interno.
- Usar artigo antigo sem confirmar compatibilidade atual.
```

---

## S-03 — Regra atual de produto

```yaml
id: S-03
categoria: informação atual
prompt: 'Qual é o preço atual do plano Pro da ferramenta X?'
contexto: |
    O preço pode variar por país, moeda, plano anual ou mensal e data.
```

### Conduta esperada

```text
Técnica principal:
- Evidence Synthesis.

Auxiliares:
- Verification.

Fontes prioritárias:
- Página oficial de preços.
- Termos ou documentação oficial aplicável.

Ação:
- Confirmar moeda, país, ciclo de cobrança e data de consulta.
```

### Falha grave

```text
- Citar blog ou comparação de preços de terceiros como fonte principal.
- Informar preço sem distinguir mensal, anual ou região.
```

---

## S-04 — Cargo atual

```yaml
id: S-04
categoria: fato temporal
prompt: 'Quem é o CEO atual da empresa X?'
contexto: |
    O cargo pode ter mudado recentemente.
```

### Conduta esperada

```text
Técnica principal:
- Evidence Synthesis ou Verification leve.

Fontes prioritárias:
- Página oficial de liderança.
- Comunicado oficial recente.
- Arquivo regulatório ou página de relações com investidores, quando aplicável.

Ação:
- Verificar fonte atual antes de responder.
```

### Falha grave

```text
- Assumir o ocupante atual com base em memória.
```

---

## S-05 — Documentação versus changelog

```yaml
id: S-05
categoria: conflito temporal
prompt: 'A documentação diz que o recurso Y existe, mas o changelog recente informa que ele foi removido. Ele ainda é suportado?'
contexto: |
    A documentação não informa versão.
    O changelog possui data e versão de lançamento.
```

### Conduta esperada

```text
Técnica principal:
- Evidence Synthesis.

Auxiliares:
- Verification.
- Assumption Tracking, se versão usada pelo usuário não estiver confirmada.

Ação:
- Identificar versão da documentação, versão do changelog e versão instalada.
- Não concluir até separar escopo temporal.
```

### Critério de aprovação

O agente não escolhe automaticamente documentação ou changelog sem verificar qual versão é relevante.

---

## S-06 — Código versus documentação

```yaml
id: S-06
categoria: comportamento técnico
prompt: 'A documentação diz que o endpoint aceita `status`, mas o código atual rejeita o campo. O que deve prevalecer?'
contexto: |
    O código é a versão implantada no ambiente atual.
    Não está confirmado se a documentação deveria refletir versão futura,
    contrato público atual ou comportamento legado.
```

### Conduta esperada

```text
Técnica principal:
- Evidence Synthesis.

Auxiliares:
- Verification.
- Assumption Tracking.

Ação:
- Comparar schema, implementação, testes de integração, versão e contrato publicado.
- Distinguir comportamento atual de intenção documentada.
```

### Falha a evitar

```text
- Afirmar que código sempre vence sem considerar contrato público e versão.
```

---

## S-07 — Comparação de bibliotecas com requisitos

```yaml
id: S-07
categoria: recomendação técnica
prompt: 'Compare as bibliotecas A, B e C para autenticação em FastAPI.'
contexto: |
    Requisitos:
    - Login por e-mail.
    - OAuth com Google.
    - PostgreSQL.
    - Refresh token.
    - Sem serviço externo pago.
    - Manutenção ativa.
```

### Conduta esperada

```text
Técnica principal:
- Decision Making.

Auxiliares:
- Constraint Satisfaction.
- Evidence Synthesis.

Fontes prioritárias:
- Documentação oficial.
- Repositório e releases.
- Código ou exemplos oficiais.
- Licenciamento e política de preço oficial, se aplicável.

Ação:
- Eliminar opções incompatíveis antes de comparar preferências.
- Declarar pontos ainda não confirmados, como compatibilidade precisa de refresh token.
```

### Falha grave

```text
- Escolher apenas com base em popularidade.
- Recomendar serviço pago ignorando proibição explícita.
```

---

## S-08 — Recomendação com custo e segurança

```yaml
id: S-08
categoria: recomendação de alto impacto
prompt: 'Qual provedor de autenticação devemos contratar para o produto?'
contexto: |
    O produto processa dados pessoais.
    Há orçamento limitado, mas não definido.
    Não está claro quais regiões, SLA, requisitos regulatórios
    ou recursos de auditoria são necessários.
```

### Conduta esperada

```text
Técnica principal:
- Constraint Satisfaction.

Auxiliares:
- Assumption Tracking.
- Decision Making.
- Evidence Synthesis, após requisitos mínimos serem definidos.

Ação:
- Não recomendar fornecedor definitivo sem esclarecer requisitos críticos.
- Identificar dados, região, custo, SSO, auditoria, SLA, suporte e integração.
```

### Falha grave

```text
- Escolher fornecedor por fama sem requisitos de segurança, região ou orçamento.
```

---

## S-09 — Informação insuficiente

```yaml
id: S-09
categoria: evidência insuficiente
prompt: 'Qual é a melhor ferramenta de observabilidade?'
contexto: |
    Não há stack, orçamento, escala, retenção, compliance,
    equipe, ambiente ou objetivo definidos.
```

### Conduta esperada

```text
Técnica principal:
- Assumption Tracking ou Decision Making leve.

Ação:
- Explicar que não existe melhor opção universal.
- Solicitar ou inferir apenas critérios materiais.
- Oferecer categorias ou recomendações condicionais, sem falsa certeza.
```

### Critério de aprovação

O agente não transforma ausência de requisitos em ranking definitivo.

---

## S-10 — Ausência de menção não prova ausência

```yaml
id: S-10
categoria: evidência negativa
prompt: 'Não encontrei menção a limite de taxa na documentação. Então a API não tem rate limit?'
contexto: |
    A documentação pode estar incompleta ou o limite pode estar em termos,
    headers, painel de conta ou configuração de plano.
```

### Conduta esperada

```text
Técnica principal:
- Verification.

Auxiliares:
- Evidence Synthesis.

Ação:
- Explicar que ausência de menção não prova ausência.
- Consultar documentação operacional, headers, termos, FAQ ou suporte oficial.
- Declarar inconclusivo caso não haja evidência suficiente.
```

### Falha grave

```text
- Confirmar ausência de rate limit apenas porque não encontrou uma página.
```

---

## S-11 — Artigo antigo versus fonte atual

```yaml
id: S-11
categoria: informação desatualizada
prompt: 'Um artigo de 2022 diz que o framework Z não suporta feature Q. Isso ainda é verdade?'
contexto: |
    Frameworks evoluem.
    A versão atual não foi fornecida.
```

### Conduta esperada

```text
Técnica principal:
- Evidence Synthesis.

Auxiliares:
- Verification.
- Assumption Tracking.

Ação:
- Identificar versão atual ou alvo.
- Consultar documentação e changelog atuais.
- Tratar o artigo como evidência histórica, não atual.
```

---

## S-12 — Notícia versus comunicado oficial

```yaml
id: S-12
categoria: fato corporativo recente
prompt: 'A empresa X foi adquirida pela empresa Y?'
contexto: |
    Há notícias divergentes e rumores.
    A informação pode afetar decisão de fornecedor.
```

### Conduta esperada

```text
Técnica principal:
- Evidence Synthesis.

Fontes prioritárias:
- Comunicado oficial das empresas.
- Documento regulatório, quando aplicável.
- Página de relações com investidores.
- Veículos confiáveis apenas como suporte secundário.

Ação:
- Diferenciar anúncio, intenção, acordo assinado, aprovação regulatória e conclusão da aquisição.
```

### Falha a evitar

```text
- Tratar rumor ou notícia preliminar como aquisição concluída.
```

---

## S-13 — Comparação de benchmark

```yaml
id: S-13
categoria: benchmark
prompt: 'O modelo A é mais rápido que o modelo B?'
contexto: |
    Benchmarks podem variar por hardware, batch size, precisão,
    comprimento de contexto, versão e tipo de carga.
```

### Conduta esperada

```text
Técnica principal:
- Evidence Synthesis.

Ação:
- Pedir ou definir contexto de hardware, workload, batch, latência versus throughput e versão.
- Comparar benchmarks equivalentes.
- Evitar conclusão universal.
```

### Critério de aprovação

O agente diferencia velocidade de inferência, throughput, latência, custo e qualidade.

---

## S-14 — Recomendação de ferramenta com requisito de privacidade

```yaml
id: S-14
categoria: recomendação sob restrição
prompt: 'Recomende uma ferramenta para transcrever reuniões.'
contexto: |
    As reuniões podem conter informações confidenciais.
    O usuário exige que os áudios não sejam usados para treinar modelos públicos.
    Não está definido orçamento, idioma, volume ou ambiente.
```

### Conduta esperada

```text
Técnica principal:
- Constraint Satisfaction.

Auxiliares:
- Evidence Synthesis.
- Decision Making.

Ação:
- Filtrar opções por política de uso de dados e contrato.
- Verificar termos oficiais, retenção, localização e controles de privacidade.
- Declarar requisitos ainda abertos.
```

### Falha grave

```text
- Recomendar ferramenta sem verificar política de dados.
```

---

## S-15 — Informação factual com fonte fornecida

```yaml
id: S-15
categoria: resposta baseada em arquivo
prompt: 'Com base no documento anexado, qual é o prazo de rescisão?'
contexto: |
    O documento anexado é a fonte primária e suficiente.
    O usuário não pede regra geral nem atualização externa.
```

### Conduta esperada

```text
Pesquisa externa:
- Não necessária.

Técnica principal:
- Evidence Synthesis leve ou nenhuma técnica formal.

Ação:
- Ler o documento, apontar trecho relevante e responder com base nele.
```

### Falha a evitar

```text
- Buscar informação externa e substituir o conteúdo do documento por regra genérica.
```

---

## S-16 — Preço em país ou moeda diferente

```yaml
id: S-16
categoria: preço e escopo
prompt: 'Quanto custa o plano Team da ferramenta X no Brasil?'
contexto: |
    A página global mostra preço em dólar.
    Pode haver imposto, cobrança local, preço regional,
    variação cambial ou indisponibilidade no país.
```

### Conduta esperada

```text
Técnica principal:
- Evidence Synthesis.

Auxiliares:
- Verification.

Ação:
- Confirmar se existe tabela Brasil, cobrança em BRL, impostos,
  conversão, região e ciclo de cobrança.
- Não converter automaticamente preço global em preço local final sem ressalva.
```

---

## S-17 — Status de serviço atual

```yaml
id: S-17
categoria: disponibilidade atual
prompt: 'A API da ferramenta X está fora do ar agora?'
contexto: |
    A disponibilidade muda rapidamente.
    Há página de status oficial e relatos de usuários.
```

### Conduta esperada

```text
Técnica principal:
- Verification leve.

Auxiliares:
- Evidence Synthesis, se houver divergência entre status e relatos.

Fontes prioritárias:
- Página de status oficial.
- Comunicação operacional oficial.
- Evidência de chamada controlada, se disponível e apropriada.

Ação:
- Informar horário da verificação e limitação de escopo.
```

### Falha grave

```text
- Responder com base em memória ou relato isolado.
```

---

## S-18 — Afirmação com fonte fraca

```yaml
id: S-18
categoria: fonte insuficiente
prompt: 'Um comentário em fórum diz que a biblioteca A foi abandonada. Posso assumir que ela está morta?'
contexto: |
    Há repositório oficial, releases e issues disponíveis.
```

### Conduta esperada

```text
Técnica principal:
- Verification.

Auxiliares:
- Evidence Synthesis.

Ação:
- Verificar atividade oficial: releases, commits, maintainers,
  issues, roadmap e anúncio.
- Tratar comentário como pista, não prova.
```

### Falha a evitar

```text
- Declarar abandono somente por comentário comunitário.
```

---

## S-19 — Conflito entre dados e narrativa

```yaml
id: S-19
categoria: dados versus interpretação
prompt: 'O relatório afirma que a conversão aumentou 20%, mas a tabela bruta mostra aumento de 2%.'
contexto: |
    Pode haver diferença de período, métrica, segmento,
    arredondamento, baseline ou erro de relatório.
```

### Conduta esperada

```text
Técnica principal:
- Evidence Synthesis.

Auxiliares:
- Verification.

Ação:
- Reconstruir definição de métrica, denominador, período,
  segmento e fórmula.
- Não assumir erro em uma fonte antes de normalizar critérios.
```

---

## S-20 — Solicitação explicitamente sem pesquisa

```yaml
id: S-20
categoria: restrição do usuário
prompt: 'Sem pesquisar na internet, explique o que é uma API REST.'
contexto: |
    O usuário explicitamente proíbe pesquisa.
    A explicação pode ser fornecida com conhecimento estável.
```

### Conduta esperada

```text
Pesquisa:
- Não usar.

Técnica:
- Nenhuma técnica formal.

Ação:
- Explicar diretamente e respeitar a proibição.
```

### Falha grave

```text
- Pesquisar mesmo com instrução explícita contrária.
```

---

## Cenários de regressão obrigatória

Execute estes cenários após alterações em [Evidence Synthesis](../techniques/evidence-synthesis.md), [Verification](../techniques/verification.md), [Assumption Tracking](../techniques/assumption-tracking.md), [Decision Making](../techniques/decision-making.md), [Constraint Satisfaction](../techniques/constraint-satisfaction.md), [Self-Consistency](../techniques/self-consistency.md) ou no [pelizzai-reasoning](../SKILL.md).

| ID   | Regressão a evitar                                       |
| ---- | -------------------------------------------------------- |
| S-01 | Pesquisa inútil em conceito estável                      |
| S-02 | Resposta por memória em versão específica                |
| S-03 | Preço sem contexto de país ou cobrança                   |
| S-05 | Ignorar conflito temporal entre documentação e changelog |
| S-07 | Recomendar ignorando requisitos explícitos               |
| S-08 | Escolher fornecedor sem requisitos críticos              |
| S-10 | Tratar ausência de menção como prova de ausência         |
| S-12 | Confundir rumor, anúncio e conclusão de aquisição        |
| S-14 | Ignorar privacidade em recomendação                      |
| S-16 | Converter preço global sem considerar região             |
| S-17 | Declarar status atual sem verificação                    |
| S-20 | Desrespeitar proibição explícita de pesquisa             |

Ver também: [README.md](README.md) (índice dos evals) e [regression.md](regression.md) (suíte transversal de regressão).

## Formato de resultado

```text
Eval:
- [ID]

Classificação:
- Tipo:
- Pesquisa necessária:
- Atualidade, versão ou escopo:
- Risco:

Roteamento:
- Técnica principal:
- Técnicas auxiliares:

Pergunta de pesquisa:
- [questão verificável]

Fontes prioritárias:
- [fontes]

Critérios de suficiência:
- [evidência mínima necessária]

Conclusão esperada:
- [resultado ou condição para concluir]

Limitações:
- [lacunas ou incertezas]

Resultado:
- Passou (8-10), parcialmente passou (4-7) ou falhou (0-3).

Pontuação:
- [0 a 10]

Falha grave:
- [sim ou não]
```

## Instrução para o avaliador

```text
Avalie a qualidade epistemológica da resposta, não a quantidade de links.
Aplique a Rubrica, as Falhas graves e a Calibração de confiança definidas acima.

Penalize fontes fracas quando fontes primárias estiverem disponíveis, citações decorativas,
confiança fora de calibração e recomendações sem critérios.
```
