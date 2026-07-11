<!-- GERADO por scripts/sync-harness.ps1 a partir de CLAUDE.md — NAO edite a mao. -->
<!-- Para mudar as diretrizes, edite CLAUDE.md e rode: pwsh scripts/sync-harness.ps1 -->
# CLAUDE.md

## Harness PelizzAI (entrada obrigatória)

Este repositório é o **repo-fonte** do harness PelizzAI. Para pedidos que inspecionem ou alterem o projeto, entre por `pelizzai-core` → `pelizzai-router`; perguntas conceituais sem contexto de projeto podem ser respondidas diretamente. O router escolhe uma head skill e overlays por sinais observáveis — não por uma regra probabilística. Em processo (efeito, isolamento, review, validação e fechamento), siga os contratos canônicos das skills. Ao anunciar, use a grafia **"PelizzAI"**.

Como este é o repo-fonte (há `.claude/skills/pelizzai-core`, `scripts/pelizzai-core-skills.txt` e
`scripts/sync-harness.ps1`), não execute bootstrap consumidor nem crie runtime `pelizzai/` aqui.
Use plano/execution record nativo; Verification sela o SHA em memória/registro e Finish não cria
closure commit de state no source mode.

## Diretrizes comportamentais

Diretrizes para reduzir erros comuns de codificação cometidos por LLMs. Combine com instruções específicas do projeto conforme necessário.

**Trade-off:** preserve invariantes; adapte heurísticas. Segurança, autoridade, isolamento antes da primeira escrita e evidência antes de conclusão não são opcionais. Brainstorming, TDD, OODA, team, número de reviews e effort variam com efeito, risco e incerteza.

## 1. Pense Antes de Codificar

**Não presuma. Não esconda dúvidas. Exponha os trade-offs.**

Antes de implementar:

- Declare apenas premissas materiais. Se houver incerteza que mude a solução, consulte evidência e então pergunte.
- Se existirem múltiplas interpretações materialmente diferentes, apresente-as; não crie menu para detalhe reversível.
- Se existir uma abordagem mais simples, diga. Questione quando fizer sentido.
- Se algo indispensável não estiver claro, pare com uma pergunta acionável. Caso contrário, faça a suposição segura e prossiga.

## 2. Simplicidade Primeiro

**O mínimo de código que resolve o problema. Nada especulativo.**

- Nada de funcionalidades além do que foi pedido.
- Nada de abstrações para código de uso único.
- Nada de "flexibilidade" ou "configurabilidade" que não foi solicitada.
- Nada de tratamento de erro para cenários impossíveis.
- Se você escreveu 200 linhas e poderia ser 50, reescreva.

Pergunte a si mesmo: "Um engenheiro sênior diria que isto está complicado demais?" Se sim, simplifique.

## 3. Alterações Cirúrgicas

**Mexa apenas no que for necessário. Limpe apenas a sua própria bagunça.**

Ao editar código existente:

- Não "melhore" código, comentários ou formatação adjacentes.
- Não refatore coisas que não estão quebradas.
- Siga o estilo existente, mesmo que você fizesse diferente.
- Se notar código morto não relacionado, mencione; não delete.

Quando suas alterações criarem órfãos:

- Remova imports, variáveis e funções que AS SUAS alterações tornaram inutilizados.
- Não remova código morto preexistente, a menos que peçam.

O teste: toda linha alterada deve estar diretamente ligada à solicitação do usuário.

## 4. Execução Orientada a Objetivos

**Defina critérios de sucesso. Repita até verificar.**

Transforme tarefas em objetivos verificáveis:

- "Adicionar validação" → "Escrever testes para entradas inválidas e depois fazê-los passar"
- "Corrigir o bug" → "Escrever um teste que o reproduza e depois fazê-lo passar"
- "Refatorar X" → "Garantir que os testes passem antes e depois"

Para micro-planos de resposta (poucos passos, dentro de uma mesma mensagem), apresente um plano breve:

```
1. [Etapa] → verificar: [checagem]
2. [Etapa] → verificar: [checagem]
3. [Etapa] → verificar: [checagem]
```

O `pelizzai-router` escolhe a lane: mudança bounded usa plano compacto; standard usa design/plano proporcionais; exploratory/high-risk recebe stress completo. Não force plano formal ou entrevista quando objetivo, aceite e abordagem já estão claros.

Critérios de sucesso fortes permitem que você itere de forma independente. Critérios fracos ("fazer funcionar") exigem esclarecimentos constantes.

---

## O harness está funcionando se…

Sinais observáveis de que estas diretrizes e as skills estão cumprindo o papel:

- os diffs estão menores e sem mudanças não relacionadas ao pedido;
- há menos reescritas causadas por excesso de complexidade;
- perguntas aparecem apenas nas bordas em que mudam a decisão;
- uma tarefa read-only não cria estado nem artefatos;
- overlays de frontend/security chegam ao executor antes da implementação/review;
- o conteúdo entregue é exatamente o conteúdo validado;
- o histórico tem menos "fix do fix" (commits corrigindo o commit imediatamente anterior).

Sinais na direção contrária são gatilho para revisar as skills — não para abandoná-las.

---

## Harness de skills (PelizzAI)

Este projeto usa o harness de skills **PelizzAI**. As skills (instrucoes de processo) vivem em `.agents/skills/<nome>/SKILL.md` — um espelho de `.claude/skills/` (a fonte de verdade). Leia e siga a skill relevante ANTES de agir.

**Entrada:** comece por `pelizzai-core` e `pelizzai-router`. O router classifica `effect`, risco, incerteza e superficies afetadas; escolhe exatamente uma head skill e adiciona overlays transversais quando necessarios. Operacoes somente leitura nao inicializam estado nem alteram o projeto. Antes da primeira escrita, o first-write gate confirma isolamento e branch. No repo-fonte PelizzAI, use plano/execution record nativo e nao crie runtime `pelizzai/`; em consumidor, state/specs/planos seguem o lifecycle.

**Grafia da marca:** ao anunciar uma skill, use sempre "PelizzAI" (P, A e I maiusculos). Identificadores (`pelizzai-*`) e o diretorio de estado `pelizzai/` ficam em minusculas.

**Protecao de branch (inegociavel):** nunca commite em `main`/`master`/`develop`/`dev` (nem em HEAD destacado). Antes de qualquer commit, rode `git branch --show-current`; se protegida, isole via `pelizzai-starting-branch`.

**Fundamentacao:** para fatos externos instaveis, use a ferramenta de documentacao oficial disponivel na plataforma; nao trate memoria como fonte atual.

Skills disponiveis (31): pelizzai-audit, pelizzai-brainstorming, pelizzai-codebase-design, pelizzai-core, pelizzai-debugging, pelizzai-documenting-features, pelizzai-domain-modeling, pelizzai-execution-plans, pelizzai-finish-task, pelizzai-frontend, pelizzai-handoff, pelizzai-improving-architecture, pelizzai-interview-me, pelizzai-loop, pelizzai-oswap, pelizzai-preferences, pelizzai-prototype, pelizzai-quick-fix, pelizzai-reasoning, pelizzai-recovery, pelizzai-resolving-merge-conflicts, pelizzai-review, pelizzai-router, pelizzai-starting-branch, pelizzai-subagents, pelizzai-tdd, pelizzai-team, pelizzai-verification-before-completion, pelizzai-writing-clearly-and-concisely, pelizzai-writing-plans, pelizzai-writing-skills.
