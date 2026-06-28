---
name: pelizzai-writing-skills
description: Use essa skill para criar, editar ou otimizar uma skill **a pedido do usuário**, e como motor do **sistema autônomo de manutenção das skills de DOMÍNIO** de um projeto. Acione-a (a) no bootstrap, chamada pela `pelizzai-audit`, para gerar o máximo de skills de domínio a partir do repo-scan, fundamentadas no MCP `context7` e nas regras de skills da Anthropic; (b) na manutenção das skills de domínio — stack que muda de versão, padrões que se repetem no git, ou cadência vencida (≥10 commits, >10 dias, ou repo-scan a cada 10 dias); e (c) quando o usuário disser "criar skill", "transforme isso numa skill", "otimizar a descrição" ou "atualizar as skills de domínio". A manutenção autônoma atua SOMENTE sobre skills de domínio — as skills do harness (`pelizzai-*`) só são criadas ou editadas a pedido explícito do usuário, NUNCA pelo sistema autônomo. E NUNCA sobrescreve uma skill às cegas: mostra o diff, preserva customizações e pede confirmação por skill.
---

# PelizzAI Writing Skills

## Objetivo

Esta skill é o **motor de autoria e manutenção de skills** do harness PelizzAI. Ela faz dois trabalhos:

| Trabalho       | Quando                                                                 | Resultado                                                        |
| -------------- | --------------------------------------------------------------------- | --------------------------------------------------------------- |
| **Autoria**    | O usuário quer uma skill nova; ou a `pelizzai-audit` pede skills de domínio no bootstrap | Uma ou várias skills bem escritas, fundamentadas e catalogadas   |
| **Manutenção** | A stack muda de versão; padrões se repetem no git; a cadência vence    | Skills de domínio atualizadas (com diff e confirmação) e registradas |

**Anuncie ao iniciar:** "Usando a skill Pelizzai Writing Skills para criar/manter skills."

<MEMBRO-DO-TIME-STOP>
Se você é um **membro** de um time (subagente/teammate) encarregado de redigir **uma** skill de domínio, escreva apenas a sua e devolva o rascunho ao coordenador — não orquestre o bootstrap inteiro nem mexa no catálogo/ledger. Acione `pelizzai-reasoning` para a sua subtarefa.
</MEMBRO-DO-TIME-STOP>

---

## Princípio central

> Uma skill é escrita uma vez e invocada milhares de vezes, em contextos que você não viu. Escreva para **generalizar**, não para acertar um caso específico. Mantenha enxuto, explique o **porquê** de cada regra (teoria da mente, não comandos rígidos), e **nunca** sobrescreva o trabalho de outra pessoa sem mostrar o que muda.

---

## Prioridades

1. Instruções explícitas do usuário.
2. Regras de segurança (Princípio da Ausência de Surpresas — sem malware/exploit/skills enganosas).
3. Convenções do harness PelizzAI e deste projeto.
4. As regras de autoria da Anthropic (ver `references/skill-authoring.md`).
5. Preferências de estilo.

---

## Regras de autoria (resumo)

Detalhe completo em **[references/skill-authoring.md](references/skill-authoring.md)** — leia antes de redigir uma skill. Em resumo:

- **Frontmatter:** só `name` e `description`. A `description` é o gatilho — inclua **o que a skill faz E quando usá-la**, e seja "incisivo" (o harness tende a acionar de menos). Toda a informação de "quando usar" vai na `description`, não no corpo.
- **Divulgação progressiva (3 níveis):** metadados (sempre no contexto) → corpo do `SKILL.md` (ideal <500 linhas) → recursos agrupados sob demanda (`scripts/`, `references/`, `assets/`). Se o corpo passar de ~500 linhas, mova profundidade para `references/` com ponteiros claros.
- **Estilo:** imperativo nas instruções; explique o porquê (teoria da mente); **generalize** — escreva para muitos contextos, não para os casos de teste; comece com rascunho e melhore com um olhar renovado.
- **Evals:** skills com saída **verificável** (transformar arquivo, extrair dados, gerar código, fluxo fixo) se beneficiam de casos de teste em `evals/`; skills subjetivas (estilo, arte) geralmente não. Ver `references/skill-authoring.md`.

---

## Skills de domínio: regras específicas

Skills de domínio capturam os padrões, stacks e convenções **deste projeto**, tornando o harness assertivo.

```text
- NUNCA use o prefixo `pelizzai-` (reservado às skills do harness).
- Nomeie com o prefixo do projeto + verbo descritivo: ex.: `<projeto>-gerar-relatorio`, `<projeto>-migrar-schema`.
- Cada skill de domínio deve ser FUNDAMENTADA: use o MCP `context7` para basear a skill na
  documentação real da lib/framework (versão correta), não na memória. Sem context7, use a web.
- Toda skill de domínio criada/atualizada entra no catálogo `pelizzai/domain-skills.md` e no
  ledger `pelizzai/data/review-domain-skills.md` (ver Templates).
```

---

## Modo Bootstrap (chamado pela `pelizzai-audit`)

Acionado na primeira interação / "bootstrap", depois que a `pelizzai-audit` mapeou o contexto.

```text
1. Receba o inventário da pelizzai-audit (stacks, frameworks, módulos, convenções, MCPs).
   Se o `context7` estiver ausente, PROPONHA instalá-lo antes de gerar — sem ele a fundamentação cai
   para web/memória justamente onde o MCP-chave faria diferença.
2. Liste as skills de domínio CANDIDATAS — o máximo de skills úteis que os padrões justificam
   (uma por fluxo/responsabilidade recorrente: build/deploy, geração de código, testes, migrações,
   integrações, convenções de UI, etc.). Não invente skills sem padrão real por trás.
3. Redija em PARALELO com a `pelizzai-team` (que cobre também a delegação a um único subagente) —
   uma skill candidata por membro, cada um fundamentando a sua via context7. Escala com o nº de candidatas.
   Os membros que REDIGEM skills precisam de capacidade de ESCRITA (general-purpose ou subagent com
   ferramentas de escrita) e de acesso ao context7 — agentes read-only (Explore/Plan) servem só para a
   pesquisa/leitura de fundamentação, não para gravar a skill.
4. Para cada skill: siga as regras de autoria; valide o frontmatter; registre no catálogo e no ledger
   (incluindo a origem: repo-scan ou interview).
5. Semeie o ledger (`last-review`/`last-full-scan`) com a data do 1º commit do repo; em projeto NOVO
   sem commits, use a data de hoje. Escreva o catálogo `pelizzai/domain-skills.md` — sua existência
   marca o bootstrap como concluído. Ver Templates.
6. Ofereça instalar o hook de cadência (opt-in; ver `references/domain-skill-maintenance.md`).
7. Apresente ao usuário a lista de skills criadas (catálogo) para revisão. Nada é definitivo sem o aval dele.
```

> Em projeto **novo** (sem código), não há padrões a extrair: o ramo correto é `pelizzai-interview-me` → `pelizzai-brainstorming` antes de voltar aqui para criar as primeiras skills a partir do design aprovado.

---

## Modo Manutenção

Mantém as skills de **domínio** vivas conforme o projeto evolui. Detalhe completo em **[references/domain-skill-maintenance.md](references/domain-skill-maintenance.md)**. Dois eixos:

> **Escopo (inegociável):** a manutenção autônoma — os dois eixos e a cadência — atua **somente** sobre skills de domínio. As skills do harness (`pelizzai-*`) **nunca** são alteradas pelo sistema autônomo; só são criadas ou editadas a pedido explícito do usuário.

- **Version-driven (refresh):** a stack mudou de versão maior ou ganhou dependência significativa → reler a doc da versão atual (context7) e **atualizar** a skill afetada.
- **Rework-driven (histórico):** o mesmo ajuste foi feito à mão várias vezes no git → o padrão vira uma regra na skill.

<HARD-GATE>
**Refresh nunca sobrescreve às cegas.** Ao atualizar uma skill existente: leia a skill atual, mude **só** o que a nova versão/padrão exige, **preserve as customizações** que o projeto adicionou, e **mostre o diff ao usuário antes de gravar**. Aprovação é **por skill**. Recriar uma skill do zero por cima de outra é proibido.
</HARD-GATE>

Atualização é sempre **propor → confirmar → aplicar → registrar**. Não há modo "mãos livres".

---

## Cadência e gatilhos (híbrido)

A auto-manutenção combina lógica **portável na skill** (núcleo) com um **hook de reforço** no Claude Code. Mecânica detalhada em **[references/domain-skill-maintenance.md](references/domain-skill-maintenance.md)**.

```text
- Ao FECHAR uma tarefa (núcleo, portável — vale em .claude/.agents/.cursor):
  leia o ledger, conte commits desde `last-review` (git rev-list --since) e os dias decorridos.
  Se >= 10 commits OU > 10 dias → proponha a revisão UMA vez ("avisa uma vez, nunca bloqueia").
- Repo-scan completo: se > 10 dias desde `last-full-scan` → proponha um re-scan e atualização ampla.
- A cada 10 interações (hook de reforço, só Claude Code): o hook checa o delta do git e injeta um
  lembrete curto quando o limiar é cruzado. Ver `references/domain-skill-maintenance.md` e o
  script `.claude/hooks/pelizzai-cadence.mjs`. O hook é opt-in: instalado no bootstrap com confirmação.
```

Os limiares (10/10/10) são o padrão; ajuste-os ao ritmo do projeto. Nada na cadência **bloqueia** o trabalho do usuário — apenas sugere.

---

## Ledger e catálogo

Dois artefatos por projeto, criados/atualizados por esta skill:

- **`pelizzai/domain-skills.md`** — catálogo: o que cada skill de domínio faz e quando usar. Template: [templates/domain-skills.md](templates/domain-skills.md).
- **`pelizzai/data/review-domain-skills.md`** — ledger: por skill, data de criação, última atualização, último commit/ref revisado, o eixo da mudança e a origem (repo-scan/interview); + `last-review` e `last-full-scan` globais. Template: [templates/review-domain-skills.md](templates/review-domain-skills.md).

Semeie o ledger com a **data do 1º commit** (`git log --reverse --format=%cd --date=short | head -1`; em frota sem POSIX, use o equivalente e pegue a 1ª linha) para o contador funcionar desde a primeira tarefa. Em projeto novo sem commits, semeie com a data de hoje.

---

## Otimização da descrição

Depois que uma skill está pronta, você pode **otimizar a `description`** para melhorar o acionamento (combater o sub-acionamento). Ver `references/skill-authoring.md` (seção "Descrição"). Regra de ouro: a `description` deve dizer o que a skill faz **e** listar os contextos/frases que devem acioná-la.

---

## Anti-padrões

```text
- Sobrescrever uma skill existente sem ler, sem diff e sem confirmação (perde customizações).
- Auto-aplicar atualizações de skill em modo "mãos livres" (reprovado em campo no harness anterior).
- Criar skill de domínio com prefixo `pelizzai-`, ou sem fundamentar via context7.
- Sobreajustar a skill aos casos de teste em vez de generalizar.
- Inflar o SKILL.md além de ~500 linhas em vez de usar `references/`.
- Inventar skills de domínio sem um padrão real do projeto por trás.
- Deixar a cadência bloquear o trabalho, ou repetir o nudge mais de uma vez.
- Esquecer de atualizar o catálogo e o ledger após criar/alterar uma skill.
```

---

## Fluxo operacional resumido

```text
1. Identifique o modo: Autoria (nova skill) ou Manutenção (atualizar existentes).
2. AUTORIA: capture a intenção → pesquise (context7) → escreva o SKILL.md (regras Anthropic)
   → (opcional) evals → registre no catálogo e no ledger.
3. BOOTSTRAP: liste candidatas → redija em paralelo (time/subagentes) → catalogue → semeie o ledger.
4. MANUTENÇÃO: detecte o eixo (versão/histórico) → leia a skill atual → mude só o necessário →
   mostre o diff → confirme → aplique → registre no ledger.
5. CADÊNCIA: ao fechar a tarefa, cheque o ledger e proponha revisão se o limiar foi cruzado.
```

---

## Integração

**Combina com:**

- `pelizzai-audit` — chama esta skill no bootstrap; aqui mora o motor de criação das skills de domínio.
- `pelizzai-team` — redigir muitas skills candidatas em paralelo (cobre também a delegação a um único subagente; `pelizzai-subagents` é skill irmã ainda não materializada).
- `pelizzai-reasoning` — raciocínio da autoria (Structured Decomposition) e da manutenção (Critique and Refine, Evidence Synthesis).
- `pelizzai-interview-me` / `pelizzai-brainstorming` — ramo de projeto novo, antes de criar as primeiras skills.
- `pelizzai-writing-clearly-and-concisely` — redigir o corpo das skills com clareza.

---

## Instrução final para o agente

```text
Crie skills que generalizam e mantenha-as vivas sem nunca destruir o trabalho de quem veio antes.

Prefira:
- fundamentar no context7 a confiar na memória;
- mostrar o diff a sobrescrever;
- propor-confirmar a "mãos livres";
- references/ a um SKILL.md gigante;
- catalogar e registrar a deixar a manutenção depender de memória humana.

Toda skill de domínio entra no catálogo e no ledger.
Nenhuma atualização de skill é aplicada sem o diff e a confirmação do usuário.
A cadência sugere; nunca bloqueia.
```
