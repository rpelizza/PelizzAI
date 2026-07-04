---
name: pelizzai-documenting-features
description: Documentação para HUMANOS do contrato estável de uma feature (rotas, comandos, APIs, telas) em `docs/<área>/<feature>.md`. Use quando a `pelizzai-finish-task` oferecer a doc ao fechar uma FEATURE, ou quando o usuário disser "documenta essa feature", "escreve a doc de uso", "faz a documentação de <feature>". NÃO é para artefatos do harness — specs/planos/ADRs vivem em `pelizzai/` e são de processo, não doc humana.
---

# PelizzAI Documenting Features

## Objetivo

Registrar para HUMANOS (devs do time, futuros mantenedores, usuários técnicos) o contrato estável de uma feature — o que ela expõe e como usá-la — separado dos artefatos de processo do harness.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Documenting Features para documentar a feature."

> **Princípio:** documente o CONTRATO (rotas, comandos, APIs, telas — o que é estável), não a implementação volátil. Doc que narra a implementação envelhece no primeiro refactor.

## Onde e como

- Arquivo: `docs/<área>/<feature>.md` (crie `docs/` se não existir; se o projeto já tem estrutura de docs, siga-a).
- **NUNCA dentro de `pelizzai/`** — o estado do harness é off-limits para docs humanas.
- Se o projeto tem um índice de docs (`docs/README.md`, sumário, mkdocs/docusaurus), linke a doc nova nele.

## Estrutura da doc

```markdown
# <Feature>

## Propósito
Por que existe; que problema resolve (2–3 frases).

## Como funciona
Visão de alto nível do comportamento observável — sem detalhes de implementação.

## Uso
Rotas/comandos/APIs/telas com exemplos concretos (request/response, comando + saída, passos na UI).

## Gotchas
Limites, pré-condições, erros comuns e como diagnosticá-los.
```

## Commit

A doc entra em **commit próprio** — `docs(<feature>): <descrição>` — respeitando o gate de branch protegida (nunca commitar em main/master/develop/dev; ver `pelizzai-starting-branch`). Quando ofertada pela `pelizzai-finish-task`, o commit acontece ANTES do push/PR — o gate da working tree garante que nada fica dangling.

## Red flags

```text
- Documentar a implementação (funções internas, estrutura de arquivos) em vez do contrato.
- Doc dentro de pelizzai/ (specs/planos/ADRs são artefatos de processo, não doc humana).
- Doc sem exemplo concreto de uso.
- Deixar a doc sem commit próprio (dangling na working tree).
```

## Integração

- `pelizzai-finish-task` — oferece esta skill (opt-in, não bloqueia) quando a entrega foi uma FEATURE.
- `pelizzai-writing-clearly-and-concisely` — a redação do texto da doc.
- `pelizzai-preferences` (§ Documentação) — README e docs sempre consistentes com o estado real do projeto.
