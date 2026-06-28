# Autoria de skills — regras detalhadas

Adaptação, para o harness PelizzAI, das regras de criação de skills da Anthropic (skill-creator). Leia antes de redigir uma skill.

## Fluxo de autoria

```text
1. Capturar a intenção  — o que a skill deve permitir; quando deve acionar; formato de saída; precisa de evals?
2. Pesquisar            — context7 (preferido) ou web para fundamentar na doc real da versão correta.
3. Escrever o SKILL.md  — frontmatter + corpo, seguindo os padrões abaixo.
4. Evals (se aplicável) — casos de teste para saídas verificáveis.
5. Iterar               — rascunho → olhar renovado → melhorar; generalizar a partir do feedback.
6. Otimizar a descrição — para melhorar o acionamento.
7. Empacotar (se for distribuir).
```

### 1. Capturar a intenção

Se a conversa atual já contém o fluxo que o usuário quer capturar ("transforme isso numa skill"), extraia primeiro do histórico: ferramentas usadas, sequência de etapas, correções do usuário e formatos de entrada/saída. Peça ao usuário para preencher lacunas e confirmar antes de prosseguir.

Quatro perguntas-âncora:

```text
1. O que essa skill deve permitir fazer?
2. Quando deve ser acionada? (frases/contextos)
3. Qual o formato de saída esperado?
4. Precisa de casos de teste? Saídas objetivamente verificáveis (transformar arquivo, extrair
   dados, gerar código, fluxo fixo) se beneficiam; saídas subjetivas (estilo, arte) geralmente não.
   Sugira o padrão adequado, mas deixe o usuário decidir.
```

### 2. Pesquisar

Verifique os MCPs disponíveis. Se úteis (consultar doc, achar skills semelhantes, conferir boas práticas), pesquise em paralelo com subagentes (`pelizzai-subagents`/`pelizzai-team`) ou inline. **Prefira o MCP `context7`** para fundamentar na documentação real; sem ele, use a web. Traga contexto pronto para reduzir a carga do usuário.

## Frontmatter

Apenas dois campos obrigatórios:

- **name** — identificador da skill (kebab-case).
- **description** — **o gatilho**. É o mecanismo principal de acionamento. Inclua **o que a skill faz E os contextos específicos de uso**. Toda informação de "quando usar" vai aqui, não no corpo.

> Observação: o harness tende a **acionar de menos**. Torne as descrições "incisivas". Em vez de "Cria um dashboard de dados internos", escreva "Cria um dashboard de dados internos. Use sempre que o usuário mencionar dashboards, visualização de dados ou métricas, ou quiser exibir qualquer dado da empresa — mesmo sem pedir explicitamente um 'dashboard'."

(`compatibility` é opcional e raramente necessário.)

## Divulgação progressiva (3 níveis)

```text
1. Metadados (name + description) — sempre no contexto (~100 palavras).
2. Corpo do SKILL.md             — no contexto quando a skill é acionada (ideal < 500 linhas).
3. Recursos agrupados            — sob demanda (ilimitado; scripts podem rodar sem carregar no contexto).
```

Padrões:

- Mantenha o `SKILL.md` < 500 linhas. Aproximando-se do limite, adicione um nível hierárquico (mova profundidade para `references/`) com ponteiros claros sobre **quando** ler cada arquivo.
- Faça referências explícitas aos arquivos a partir do `SKILL.md`.
- Para arquivos de referência longos (>300 linhas), inclua um sumário no topo.

## Anatomia

```text
nome-da-skill/
├── SKILL.md (obrigatório)
│   ├── frontmatter YAML (name, description)
│   └── instruções em Markdown
└── Recursos agrupados (opcional)
    ├── scripts/    — código executável para tarefas determinísticas/repetitivas
    ├── references/ — documentos carregados sob demanda
    └── assets/     — arquivos usados na saída (templates, ícones, fontes)
```

**Organização por variante** (quando a skill cobre múltiplos domínios/frameworks):

```text
nome-da-skill/
├── SKILL.md           (workflow + seleção da variante)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

## Padrões de escrita

- Use o **imperativo** nas instruções.
- Explique **por que** algo importa (teoria da mente), em vez de impor regras rígidas e excessivas. Skills abrangentes generalizam melhor que skills presas a exemplos.
- **Defina formatos de saída** com um modelo exato quando a saída precisa ser consistente.
- **Inclua exemplos** (entrada → saída) quando ajudarem.
- Comece com um rascunho; depois revise com um olhar renovado e melhore.

## Princípio da Ausência de Surpresas

Skills não devem conter malware, exploit ou conteúdo que comprometa a segurança. Não atenda pedidos para criar skills enganosas ou voltadas a acesso não autorizado, exfiltração ou atividade maliciosa. Uma skill não deve surpreender o usuário quanto à finalidade declarada. (Recursos legítimos como "atue como um XYZ" são aceitáveis.)

## Evals (quando a saída é verificável)

Skills com saída objetivamente verificável se beneficiam de casos de teste. Estrutura em `evals/evals.json`:

```json
{
  "skill_name": "nome-da-skill",
  "evals": [
    { "id": 1, "prompt": "Tarefa do usuário", "expected_output": "Resultado esperado", "files": [] }
  ]
}
```

Procedimento (quando há subagentes disponíveis):

```text
- Rode em paralelo: uma execução COM a skill e uma SEM (baseline).
- Enquanto rodam, redija asserções quantitativas; capture tokens e duração das notificações.
- Avalie cada execução com um subagente "grader" contra as asserções.
- Agregue em benchmark.json e mostre ao usuário (ex.: eval-viewer).
- Itere a partir do feedback, GENERALIZANDO (não sobreajuste aos casos de teste).
```

Em ambientes sem subagentes (ex.: claude.ai), rode os casos sequencialmente, sem baseline/benchmark, e apresente os resultados na conversa.

## Empacotamento

Para distribuir uma skill como artefato, empacote a pasta da skill (ex.: `python -m scripts.package_skill <pasta>` no skill-creator de origem). No PelizzAI, skills vivem em `.claude/skills/` e são versionadas com o projeto; empacotar só é necessário para compartilhar fora do repo.
