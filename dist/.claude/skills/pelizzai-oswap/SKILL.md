---
name: pelizzai-oswap
description: Overlay de segurança para mudanças que tocam autenticação/autorização, input não confiável, SQL/query, dados sensíveis, upload, CORS/SSRF, dependências/supply chain, integridade, logging ou exceções. Aplica o OWASP Top 10 atual ao diff e produz fixes/evidência antes do review final e de validated-head. Use também quando o usuário pedir revisão OWASP; nunca adie para finish-task.
---

# PelizzAI OWASP

## Objetivo

Revisar o diff e as trust boundaries afetadas, encontrando caminhos plausíveis de exploração ou
falha segura antes de integrar.

Baseline: [OWASP Top 10:2025](https://owasp.org/Top10/2025/0x00_2025-Introduction/). Ao manter esta
skill, confirme a edição oficial atual; não preserve categorias antigas por memória.

**Anuncie:** "Usando a skill PelizzAI OWASP para revisar as superfícies de segurança desta mudança."

## Quando

O router/plano registra este overlay assim que o escopo ou diff toca auth, autorização, entrada
externa, query, segredo/PII, upload, rede/URL, dependência/build, integridade, logging/alerta ou
tratamento de falha. Review pode promovê-lo quando descobrir uma superfície não prevista.

## Escopo

- tarefa ainda não commitada: working tree completa, inclusive staged/untracked;
- candidato final: `base-sha..candidate-head`;
- pedido read-only: range/PR explicitamente delimitado, sem criar state.

Liste entradas, atores, trust boundaries, ativos e efeitos externos. Não revise o repo inteiro por
reflexo, mas siga uma cadeia chamada pelo diff quando isso for necessário para provar autorização
ou sanitização.

## OWASP Top 10:2025 — lentes aplicáveis

| # | Categoria | Pergunta para o diff |
| --- | --- | --- |
| A01 | Broken Access Control | Autorização por objeto/ação? IDOR? SSRF/acesso interno controlado? |
| A02 | Security Misconfiguration | Defaults, debug, CORS/headers, permissões ou fail-open? |
| A03 | Software Supply Chain Failures | Dependência/build/publish necessários, pinados e com proveniência/integridade? |
| A04 | Cryptographic Failures | Segredo/dado em claro? Algoritmo, chave, armazenamento e transporte adequados? |
| A05 | Injection | Input chega a SQL, shell, template, LDAP ou interpreter sem parametrização/escaping? |
| A06 | Insecure Design | Trust boundary, abuso, rate/size limit e regra de negócio foram modelados? |
| A07 | Authentication Failures | Sessão/token, expiração, rotação, brute-force e recuperação estão corretos? |
| A08 | Software or Data Integrity Failures | Desserialização, update, artefato ou dado cruza boundary sem integridade? |
| A09 | Security Logging & Alerting Failures | Evento gera log sem segredo/PII e alerta acionável? |
| A10 | Mishandling of Exceptional Conditions | Erro, timeout, retry, partial failure e estado anormal falham com segurança? |

Carregue apenas categorias tocadas. OWASP é uma taxonomia de lentes, não uma lista para marcar sem
evidência.

## Achado e prova

Para cada suspeita:

```text
categoria + severidade
arquivo:linha
precondição → entrada → boundary → efeito → impacto
evidência observada
fix mínimo
teste/check que falha antes e passa depois, quando automatizável
```

Sem caminho plausível, rebaixe ou retire; não invente exploit. Nova dependência exige fonte oficial
e scanner/lockfile disponível, sem alegar ausência de CVE quando a consulta não rodou.

## Lifecycle

Fix de segurança altera o candidato: implemente antes do seal, execute a prova, consolide e reabra
as categorias/reviews afetados. Critical/High bloqueiam `validated-head`; risco aceito exige decisão
explícita do dono e registro durável apropriado. Finish-task nunca executa este overlay.

## Red flags

```text
- Oferta tardia na finish-task.
- Checklist das dez categorias sem relação com o diff.
- Achado crítico teórico sem boundary/caminho.
- Aprovar input/autorização sem seguir o dado até o enforcement.
- Consultar CVE/dependência de memória.
- Corrigir depois de validated-head sem invalidar o seal.
```

## Integração

É overlay do router/writing-plans/execution-plans/review e combina com skills de domínio. Use
Evidence Synthesis quando logs/scanners/fontes divergem; não transforme a taxonomia em reasoning
universal.
