# Template de plano de implementação — PelizzAI

Copie para `pelizzai/plans/AAAA-MM-DD-<feature>.md` e substitua todo texto entre colchetes por conteúdo real. Cada tarefa é uma fatia vertical verificável; a estratégia varia conforme o efeito.

---

## Cabeçalho obrigatório

```markdown
# [Nome] — Plano de implementação

> **Para quem executa:** SUB-SKILL OBRIGATÓRIA — use `pelizzai-execution-plans`.

**Objetivo:** [resultado em uma frase]

**Arquitetura:** [abordagem e fronteiras em 2–3 frases]

**Stack técnica:** [tecnologias/bibliotecas]

**Skills de domínio aplicáveis:** [nomes de `pelizzai/domain-skills.md` ou `nenhuma`]

**Skills transversais do harness:** [ex.: `pelizzai-frontend`, `pelizzai-oswap`, `pelizzai-documenting-features` ou `nenhuma`]

**Global Constraints (copiadas VERBATIM da spec):**

- [constraint projeto-wide; se não houver, escreva `nenhuma`]

---
```

O coordenador inclui Global Constraints e skills transversais aplicáveis no briefing de cada executor. Não liste overlay por possibilidade remota: UI exige `pelizzai-frontend`; superfície sensível exige `pelizzai-oswap`.

## Estrutura de cada tarefa

````markdown
### Tarefa N: [resultado vertical]

**Files:**

- Criar: `caminho/exato.ext`
- Modificar: `caminho/exato.ext:123`
- Validar: `caminho/exato/de/teste-ou-artefato.ext`

**Skills de domínio a aplicar:** [nomes ou `nenhuma`]

**Skills transversais do harness a aplicar:** [nomes ou `nenhuma`]

**Interfaces:**

- Consome: `nomeExato(arg: Tipo): Retorno` — origem
- Produz: `outroNome(arg: Tipo): Retorno` — consumidor

_Se autocontida, escreva `nenhuma`._

**Estratégia de implementação e validação:**

- Efeito predominante: [comportamento | refatoração | config/IaC/migração | UI visual | documentação]
- Implementação: [TDD red→green | caracterização no verde | validate/plan/dry-run | pelizzai-frontend + QA visual | checagem estática]
- Oráculo: [o que prova o resultado]
- Comando(s): `[comandos canônicos completos]`
- Evidência esperada: [exit code, delta, estado visual ou saída exata]
- Rollback: [quando aplicável; caso contrário, `não aplicável`]
- Perfil de review: [combined | split] — [justificativa por risco/superfície]

- [ ] **Passo 1: Estabeleça o baseline/oráculo** → verifique: [resultado exato]

[comando, teste ou inspeção concreta]

- [ ] **Passo 2: Aplique a menor mudança da fatia** → verifique: [critério local]

```language
[código/config/conteúdo completo]
```

- [ ] **Passo 3: Execute a prova da estratégia** → verifique: [saída exata]

Rode: `[comando exato]`
Esperado: `[resultado observável]`

- [ ] **Passo 4: Pronto para review → consolidar** — não commite no meio da tarefa; o commit é o gate do coordenador após as lentes spec ✅ + qualidade ✅ no perfil registrado. → verifique: `git status` contém somente o escopo desta tarefa
````

Adapte a ordem sem perder a prova:

```text
- Comportamento/regressão: RED observado → implementação mínima → GREEN → refactor no verde.
- Refatoração preservativa: caracterização verde → passo pequeno → mesma caracterização verde.
- Config/IaC/migração: baseline → mudança → validate/plan/dry-run → inspecionar delta e rollback.
- UI: comportamento quando houver + implementar estados → pelizzai-frontend em desktop/mobile → screenshot/navegador.
- Docs/copy: editar → lint/links/exemplos/build-render → inspeção do resultado.
```

## Gates de qualidade do plano

```text
- Paths, interfaces, conteúdo, comandos e saídas são concretos.
- Todo passo possui `→ verifique:`.
- Cada tarefa registra skills transversais, estratégia de implementação/validação e perfil de review.
- UI nunca omite `pelizzai-frontend`; Playwright/browser é ferramenta, não overlay.
- Não há RED artificial para refatoração, CSS, docs, config, IaC ou migração.
- Sem TBD/TODO, "tratar edge cases", "igual à Tarefa N" ou referências indefinidas.
- API externa está ancorada em documentação atual, não memória.
```
