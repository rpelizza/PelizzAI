# Template de plano de implementação — PelizzAI

Copie a estrutura abaixo para `pelizzai/plans/AAAA-MM-DD-<feature>.md`. Preencha tudo com conteúdo real — sem placeholders. Cada tarefa é uma fatia vertical; cada passo é uma ação de 2-5 min.

---

## Cabeçalho (obrigatório no topo do plano)

```markdown
# [Nome da feature] — Plano de implementação

> **Para quem executa (agentes/humanos):** SUB-SKILL OBRIGATÓRIA — use `pelizzai-execution-plans`
> para executar este plano tarefa a tarefa (ela escolhe o modo: team / subagents / inline). Os
> passos usam checkbox (`- [ ]`) para rastreamento.

**Objetivo:** [uma frase descrevendo o que isto constrói]

**Arquitetura:** [2-3 frases sobre a abordagem]

**Stack técnica:** [tecnologias/bibliotecas principais]

**Skills de domínio aplicáveis (catálogo):** [liste as de pelizzai/domain-skills.md que valem aqui; se nenhuma, escreva 'nenhuma']

**Global Constraints (copiadas VERBATIM da spec):**

- [requisito projeto-wide 1 — ex.: "todas as datas em UTC"]
- [requisito projeto-wide 2]

_Toda tarefa herda estas constraints implicitamente; o coordenador as inclui no briefing de cada membro (que só vê a própria tarefa). Se a spec não tiver nenhuma, escreva 'nenhuma'._

---
```

## Estrutura de cada tarefa

````markdown
### Tarefa N: [Nome do componente]

**Files:**

- Criar: `caminho/exato/para/arquivo.ext`
- Modificar: `caminho/exato/existente.ext:123-145`
- Testar: `testes/caminho/exato/teste.ext`

**Skills de domínio a aplicar nesta tarefa:** [nomeie as relevantes; ex.: `<projeto>-convencao-api`; se nenhuma, escreva 'nenhuma']

**Interfaces:**

- Consome: `nomeExato(arg: Tipo): Retorno` — vem de [Tarefa M / código existente em `caminho`]
- Produz: `outroNome(arg: Tipo): Retorno` — consumido por [Tarefa P]

_O implementador só vê a própria tarefa; este bloco é como ele descobre os nomes e tipos exatos que as tarefas vizinhas usam. Se a tarefa é autocontida, escreva 'nenhuma'._

- [ ] **Passo 1: Escreva o teste que falha** → verifique: o teste usa só a interface pública, no seam acordado

```python
def test_comportamento_especifico():
    resultado = funcao(entrada)
    assert resultado == esperado
```

- [ ] **Passo 2: Rode o teste e veja-o falhar** → verifique: a saída esperada abaixo

Rode: `pytest testes/caminho/teste.py::test_nome -v`
Esperado: FAIL com "function not defined"

- [ ] **Passo 3: Implemente o mínimo para passar** → verifique: nada além do que o teste atual exige

```python
def funcao(entrada):
    return esperado
```

- [ ] **Passo 4: Rode o teste e veja-o passar** → verifique: a saída esperada abaixo

Rode: `pytest testes/caminho/teste.py::test_nome -v`
Esperado: PASS

- [ ] **Passo 5: Pronto para review → consolidar** — NÃO commite no meio da tarefa: o commit é o gate do coordenador, após spec ✅ + qualidade ✅ (em modo inline, o próprio controlador consolida). Ver `pelizzai-execution-plans` → `references/task-cycle.md`. → verifique: `git status` mostra apenas os arquivos desta tarefa
````

## Lembre-se

```text
- Caminhos de arquivo exatos, sempre.
- Código completo em cada passo que mexe em código.
- Comandos exatos com a saída esperada.
- TODO passo carrega seu `→ verifique:` inline — plano sem check por passo é vago por construção.
- Global Constraints verbatim da spec no cabeçalho; bloco Interfaces (Consome/Produz) por tarefa.
- DRY, YAGNI, TDD, commits frequentes.
- API externa: ancore na doc real e atual (context7), não na memória.
- Siga e NOMEIE as skills de domínio do projeto nas tarefas relevantes.
- Sem placeholders: "TBD", "tratar edge cases", "igual à Tarefa N" são defeitos de plano.
```
