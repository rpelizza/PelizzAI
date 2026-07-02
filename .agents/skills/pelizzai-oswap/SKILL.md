---
name: pelizzai-oswap
description: Use para revisar a SEGURANÇA de uma mudança (diff) antes de integrar — checklist OWASP Top 10 focado no que mudou, especialmente quando toca autenticação/autorização, input do usuário, queries/SQL, dados sensíveis/segredos, upload, desserialização, CORS/headers, SSRF ou novas dependências. Oferecida pela `pelizzai-finish-task` antes do push/PR, e é a dimensão de segurança do review (`pelizzai-review`). Acione quando o usuário disser "revisão de segurança", "checar OWASP", "isso é seguro?".
---

# PelizzAI OWASP

## Objetivo

Revisão de segurança focada no **diff** (não no código inteiro), guiada pelo **OWASP Top 10**. Objetivo: pegar vulnerabilidades **introduzidas pela mudança** antes de integrar.

**Anuncie ao iniciar:** "Usando a skill PelizzAI OWASP para checar a segurança desta mudança (OWASP Top 10)."

> **Princípio:** revise o que mudou, no contexto de quem chama. Um achado sem caminho de exploração plausível é ruído; um achado com caminho de exploração é prioridade.

---

## Quando usar

```text
- Oferecida pela pelizzai-finish-task quando o diff toca superfície sensível.
- Como dimensão de segurança do review (pelizzai-review).
- A pedido do usuário.
- Especialmente: auth, input do usuário, SQL/queries, dados sensíveis/segredos, upload,
  desserialização, novas dependências, CORS/headers, SSRF.
```

## Processo

1. **Escopo do diff** — `git diff <base>..HEAD`. Liste os pontos de entrada e os dados externos que a mudança introduz ou altera.
2. **Checklist OWASP Top 10** (foco no que o diff toca):

| #   | Categoria                  | O que checar no diff                                                                 |
| --- | -------------------------- | ------------------------------------------------------------------------------------ |
| A01 | Broken Access Control      | Autorização verificada em cada novo endpoint/ação? IDOR (acessar recurso de outro por id)? |
| A02 | Cryptographic Failures     | Segredos/dados sensíveis em texto claro? Hash de senha adequado (bcrypt/argon2)? TLS? |
| A03 | Injection                  | Input concatenado em SQL/shell/template? Use queries parametrizadas / escaping.       |
| A04 | Insecure Design            | Falta rate limiting, validação de regra de negócio, limite de tamanho?               |
| A05 | Security Misconfiguration  | Debug ligado, CORS `*`, headers de segurança ausentes, defaults inseguros?           |
| A06 | Vulnerable Components       | Nova dependência: versão com CVE? pinada? realmente necessária?                      |
| A07 | Auth Failures              | Sessão/token: expiração, rotação, força de senha, proteção contra brute-force?       |
| A08 | Integrity Failures          | Desserialização insegura? Update/CI sem verificação de integridade?                  |
| A09 | Logging Failures            | Loga segredos/PII? Falta log de eventos de segurança?                                |
| A10 | SSRF                       | Requisição a URL controlada pelo usuário sem allowlist?                              |

3. **Validar o exploit** — para cada suspeita, descreva o caminho concreto de exploração. Sem caminho plausível, baixe a severidade.
4. **Reportar** — por achado: categoria OWASP, severidade (crítico/alto/médio/baixo), local (`arquivo:linha`), exploit e **correção concreta**.

---

## Red flags

```text
Nunca: revisar o código inteiro quando o pedido é sobre uma mudança (foque no diff); reportar
       achado teórico sem caminho de exploração como se fosse crítico; aprovar sem checar input
       não confiável e autorização nos pontos novos.
Sempre: tratar input do usuário como hostil; checar as versões de novas dependências; entregar
        uma correção acionável, não só apontar o problema.
```

---

## Integração

**Oferecida por:** `pelizzai-finish-task` (antes do push/PR, quando o diff toca superfície sensível).

**Combina com:** `pelizzai-review` — aquela foca em qualidade/correção; esta foca em segurança. `pelizzai-reasoning` (Evidence Synthesis para correlacionar o exploit).
