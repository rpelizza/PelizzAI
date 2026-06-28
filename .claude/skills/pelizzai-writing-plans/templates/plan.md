# Template de plano de implementação — PelizzAI

Copie a estrutura abaixo para `pelizzai/plans/AAAA-MM-DD-<feature>.md`. Preencha tudo com conteúdo real — sem placeholders. Cada tarefa é uma fatia vertical; cada passo é uma ação de 2-5 min.

---

## Cabeçalho (obrigatório no topo do plano)

```markdown
# [Nome da feature] — Plano de implementação

> **Para quem executa (agentes/humanos):** SUB-SKILL OBRIGATÓRIA — use `pelizzai-execution-plans`
> para executar este plano tarefa a tarefa (ela escolhe o modo: team / subagents / inline). Os
> passos usam checkbox (`- [ ]`) para rastreamento.

**Goal:** [uma frase descrevendo o que isto constrói]

**Arquitetura:** [2-3 frases sobre a abordagem]

**Tech Stack:** [tecnologias/bibliotecas principais]

**Skills de domínio aplicáveis:** [liste as do catálogo pelizzai/domain-skills.md que valem aqui]

---
```

## Estrutura de cada tarefa

````markdown
### Tarefa N: [Nome do componente]

**Files:**

- Criar: `caminho/exato/para/arquivo.ext`
- Modificar: `caminho/exato/existente.ext:123-145`
- Testar: `testes/caminho/exato/teste.ext`

**Skills de domínio a aplicar:** [nomeie as relevantes a esta tarefa]

- [ ] **Passo 1: Escreva o teste que falha**

```python
def test_comportamento_especifico():
    resultado = funcao(entrada)
    assert resultado == esperado
```

- [ ] **Passo 2: Rode o teste e veja-o falhar**

Rode: `pytest testes/caminho/teste.py::test_nome -v`
Esperado: FAIL com "function not defined"

- [ ] **Passo 3: Implemente o mínimo para passar**

```python
def funcao(entrada):
    return esperado
```

- [ ] **Passo 4: Rode o teste e veja-o passar**

Rode: `pytest testes/caminho/teste.py::test_nome -v`
Esperado: PASS

- [ ] **Passo 5: Commit**

```bash
git add testes/caminho/teste.py src/caminho/arquivo.py
git commit -m "feat: adiciona comportamento especifico"
```
````

## Lembre-se

```text
- Caminhos de arquivo exatos, sempre.
- Código completo em cada passo que mexe em código.
- Comandos exatos com a saída esperada.
- DRY, YAGNI, TDD, commits frequentes.
- API externa: ancore na doc real e atual (context7), não na memória.
- Siga e NOMEIE as skills de domínio do projeto nas tarefas relevantes.
- Sem placeholders: "TBD", "tratar edge cases", "igual à Tarefa N" são defeitos de plano.
```
