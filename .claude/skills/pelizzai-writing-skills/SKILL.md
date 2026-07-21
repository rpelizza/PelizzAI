---
name: pelizzai-writing-skills
description: Use essa skill para criar, editar, validar ou otimizar uma skill **a pedido do usuário**, e como motor de autoria e manutenção das skills de **DOMÍNIO** de um projeto. Acione-a (a) no bootstrap, chamada pela `pelizzai-audit`, para enumerar generosamente as candidatas que os padrões do repo justificam — uma por fluxo/responsabilidade recorrente — e redigi-las depois que o usuário ratifica a lista, fundamentadas em `context7`/doc oficial e nas regras de skills da Anthropic; (b) na manutenção das skills de domínio — stack que muda de versão, retrabalho que se repete no git, stack nova adotada sem cobertura, ou cadência vencida (≥10 commits, >10 dias, repo-scan a cada 15 dias); e (c) quando o usuário disser "criar skill", "transforme isso numa skill", "otimizar a descrição" ou "atualizar as skills de domínio". A manutenção proativa atua SOMENTE sobre skills de domínio — as skills do harness (`pelizzai-*`) só são criadas ou editadas a pedido explícito do usuário. E NUNCA sobrescreve uma skill às cegas: o diff vai ao usuário antes de gravar, com aprovação por skill.
---

# PelizzAI Writing Skills

## Objetivo

Esta skill é o **motor de autoria e manutenção de skills** do harness PelizzAI. Ela faz dois trabalhos:

| Trabalho       | Quando                                                                 | Resultado                                                        |
| -------------- | --------------------------------------------------------------------- | --------------------------------------------------------------- |
| **Autoria**    | O usuário quer uma skill nova; ou a `pelizzai-audit` pede skills de domínio no bootstrap | Uma ou várias skills bem escritas, fundamentadas e catalogadas   |
| **Manutenção** | A stack muda de versão; padrões se repetem no git; a cadência vence    | Skills de domínio atualizadas (com diff e confirmação) e registradas |

**Anuncie ao iniciar:** "Usando a skill PelizzAI Writing Skills para criar/manter skills."

<MEMBRO-DO-TIME-STOP>
Se você é um **membro** de um time (subagente/teammate) encarregado de redigir **uma** skill de domínio, escreva apenas a sua e devolva o rascunho ao coordenador — não orquestre o bootstrap inteiro nem mexa no catálogo/ledger. Acione `pelizzai-reasoning` para a sua subtarefa.
</MEMBRO-DO-TIME-STOP>

---

## Princípio central

> Uma skill é escrita uma vez e invocada milhares de vezes, em contextos que você não viu. Escreva para **generalizar**, não para acertar um caso específico. Mantenha enxuto, explique o **porquê** de cada regra (teoria da mente, não comandos rígidos), e **nunca** sobrescreva o trabalho de outra pessoa sem mostrar o que muda.

---

## Autoridade

Respeite a hierarquia nativa da plataforma. Dentro do mesmo nível, instrução específica do usuário/projeto prevalece sobre defaults desta skill. Segurança e ausência de surpresas não são preferências de estilo.

---

## Regras de autoria (resumo)

Detalhe completo em **[references/skill-authoring.md](references/skill-authoring.md)** — leia antes de redigir uma skill. Em resumo:

- **Frontmatter:** só `name` e `description`. A `description` é o gatilho — inclua **o que a skill faz E os sinais/frases observáveis de quando usá-la**. Seja **incisivo**: o sub-acionamento é a falha dominante (o harness tende a acionar de menos); nomear os *near misses* é o que evita o skill storm, não encolher o gatilho. A `description` **nunca resume o workflow** — um resumo do processo faz o agente seguir a description e PULAR o corpo.
- **Divulgação progressiva (3 níveis):** metadados (sempre no contexto) → corpo do `SKILL.md` (ideal <500 linhas) → recursos agrupados sob demanda (`scripts/`, `references/`, `assets/`). Se o corpo passar de ~500 linhas, mova profundidade para `references/` com ponteiros claros.
- **Estilo:** imperativo nas instruções; explique o porquê (teoria da mente); **generalize** — escreva para muitos contextos, não para os casos de teste; comece com rascunho e melhore com um olhar renovado.
- **Evals:** skills com saída **verificável** (transformar arquivo, extrair dados, gerar código, fluxo fixo) se beneficiam de casos de teste em `evals/`; skills subjetivas (estilo, arte) geralmente não. Ver `references/skill-authoring.md`.

---

## Validação comportamental proporcional

Trate skills como comportamento versionado. Use a menor evidência que detecta a regressão relevante; detalhe em **[references/skill-authoring.md](references/skill-authoring.md)**.

```text
- Mudança comportamental de alto risco ou comportamento ainda desconhecido precisa de baseline:
  falha real documentada, eval existente ou cenário mínimo. Evidência do repo/feedback pode bastar;
  edição editorial dispensa baseline comportamental.
- Escreva a menor regra que corrige a classe de falha; não sobreajuste ao exemplo.
- Versione pressure test somente quando ele protege falha material/recorrente. Não crie um arquivo
  de teste para cada ajuste de wording.
- Fluxo fixo/script: teste executável. Roteamento/heurística: forward-test com contexto limpo.
  Estilo subjetivo: exemplos contrastivos e inspeção, sem fingir determinismo.
- Reexecute a regressão afetada e uma smoke suite composta. Mais amostras somente quando a
  variância observada justificar.
- Se uma regra só funciona com proibições crescentes, revise o predicado de ativação antes de
  adicionar outra exceção.
```

---

## Skills de domínio: regras específicas

Skills de domínio capturam os padrões, stacks e convenções **deste projeto**, tornando o harness assertivo.

```text
- NUNCA use o prefixo `pelizzai-` (reservado às skills do harness).
- Nomeie com o prefixo do projeto + verbo descritivo: ex.: `<projeto>-gerar-relatorio`, `<projeto>-migrar-schema`.
- Skill de stack/lib externa deve ser **fundamentada em context7 ou documentação oficial atual**
  da versão travada no lockfile; sem essa fundamentação disponível, não escreva a skill de stack —
  fundamente ou adie (nunca invente de memória). Skill de convenção interna se fundamenta no código,
  testes, ADRs e histórico do próprio projeto, onde `context7` é preferencial, não um bloqueio.
- Toda skill de domínio criada/atualizada entra no catálogo `pelizzai/domain-skills.md` e no
  ledger `pelizzai/data/review-domain-skills.md` (ver Templates).
```

### Skill roots no projeto consumidor

Detecte os roots realmente instalados e registre-os no `pelizzai/profile.md`.

```text
Repo-fonte PelizzAI:
  edite .claude/skills e rode sync-harness para gerar .agents.

Consumidor com um root:
  grave a domain skill no root ativo (.claude/skills OU .agents/skills).

Consumidor com ambos:
  use o canonical-skill-root do profile, espelhe a domain skill no outro root e verifique hash.
```

Nunca crie uma domain skill num diretório que a plataforma atual não carrega. Catálogo e ledger registram o caminho real.

### Sync obrigatório como parte da edição

Depois que o usuário autorizou criar, alterar ou remover uma skill, sincronizar os roots gerados é
parte mecânica dessa mesma alteração — não peça uma segunda autorização:

```text
1. Edite somente o canonical-skill-root.
2. Se scripts/sync-harness.mjs existir, rode automaticamente:
   node scripts/sync-harness.mjs
   node scripts/sync-harness.mjs --check [--source-mode no repo-fonte]
3. Os wrappers sync-harness.ps1 e sync-harness.sh são entradas equivalentes, não implementações
   diferentes. Use o disponível quando `node` não estiver diretamente exposto pelo agente.
4. Ao criar/remover skill core no repo-fonte, inclua --update-manifest antes do --check.
5. Sem script de geração, espelhe conforme o profile e compare hashes.
```

Não sincronize uma proposta de manutenção ainda não ratificada. Depois da ratificação, não deixe
skill canônica e mirrors divergentes nem transfira esse passo ao usuário.

---

## Modo Bootstrap (chamado pela `pelizzai-audit`)

Acionado em `bootstrap-write`, depois que a `pelizzai-audit` mapeou o contexto e criou a task branch. Scan-only não chama este modo.

```text
1. Receba o inventário evidenciado da pelizzai-audit (stacks, frameworks, módulos, convenções, MCPs)
   e os skill roots ativos. Se o `context7` estiver ausente, PROPONHA instalá-lo antes de gerar —
   sem ele a fundamentação cai para web/memória justamente onde o MCP-chave faria diferença.
2. Liste as skills de domínio CANDIDATAS — o máximo de skills úteis que os padrões justificam (uma
   por fluxo/responsabilidade recorrente: build/deploy, geração de código, testes, migrações,
   integrações, convenções de UI, etc.). O filtro é VERACIDADE, não escassez: não invente skills sem
   padrão real por trás, e não corte uma candidata verdadeira só para manter a lista curta. Cada
   candidata nomeia o padrão observado e a decisão/erro do agente que ela muda.
2.5. GATE: apresente a lista de candidatas ao usuário (nome + o que cada uma cobriria) e AGUARDE a
   confirmação antes de redigir — criar skills grava arquivos no repositório dele. Ele pode cortar,
   somar ou ajustar candidatas; zero domain skills é um resultado possível QUANDO ele o ratifica
   diante da proposta — a decisão de não criar é do usuário, não do classificador. Se o
   consentimento de bootstrap já incluiu nomes/escopo das candidatas, não repita a pergunta; reabra
   a decisão só se o scan mudou materialmente o conjunto proposto.
3. Redija em PARALELO as candidatas confirmadas com a `pelizzai-team` — uma skill candidata por
   membro, cada um fundamentando a sua via context7. **Escala com o nº de candidatas:** 5 candidatas
   confirmadas são 5 frentes, não uma fila. Com uma única candidata (ou quando um time for
   desnecessário), delegue via `pelizzai-subagents`. Os membros que REDIGEM skills precisam de
   capacidade de ESCRITA (general-purpose ou subagent com ferramentas de escrita) e de acesso ao
   context7/doc oficial — agentes read-only servem só para a pesquisa/leitura de fundamentação, não
   para gravar a skill.
4. Para cada skill: siga as regras de autoria; valide o frontmatter; registre no catálogo e no ledger
   (incluindo a origem: repo-scan ou interview).
5. Semeie o ledger (`last-review`/`last-full-scan`) com a **data do bootstrap (hoje)** — as skills
   nascem do repo-scan do HEAD atual, então o bootstrap É a primeira revisão; semear com o 1º commit
   de um repo maduro dispara um nudge espúrio já na primeira tarefa. Escreva o catálogo `pelizzai/domain-skills.md` — sua existência
   marca o bootstrap como concluído. Ver Templates.
6. Ofereça instalar o hook de cadência (opt-in; ver `references/domain-skill-maintenance.md`).
7. Apresente ao usuário o catálogo das skills criadas, com diff e validação — nada é definitivo sem
   o aval dele. Peça nova decisão apenas para escopo/conteúdo não coberto pela autorização existente
   ou para efeito externo.
```

> Em projeto **novo** (sem código), não há padrões a extrair: conclua primeiro descoberta
> sequencial, design, stress e spec aprovada. Depois proponha domain skills fundamentadas na stack e
> no design ratificados; só escreva as escolhidas pelo usuário e só então siga para o plano.

---

## Modo Manutenção

Mantém as skills de **domínio** vivas conforme o projeto evolui. Detalhe completo em **[references/domain-skill-maintenance.md](references/domain-skill-maintenance.md)**. Três eixos — dois **atualizam** o que já existe, um **cria** a primeira skill de uma stack nova:

> **Escopo (inegociável):** a detecção proativa dos três eixos e da cadência atua somente sobre
> skills de domínio e apenas propõe mudanças. As skills do harness (`pelizzai-*`) nunca são alteradas
> sem pedido explícito do usuário.

- **Version-driven (refresh — ATUALIZA):** a stack mudou de versão maior ou ganhou dependência significativa → reler a doc da versão atual (context7) e **atualizar** a skill existente afetada. O drift é detectado comparando os manifests atuais com o **Stack baseline** de `pelizzai/profile.md` (gravado pela `pelizzai-audit` no bootstrap).
- **Rework-driven (histórico — ATUALIZA):** o mesmo ajuste foi feito à mão várias vezes no git → o padrão vira uma regra na skill existente.
- **Adoption-driven (nova stack — CRIA):** a tarefa adotou dependência/serviço significativo **ainda não coberto** por skill do catálogo (top-level novo nos manifests, ausente do **Stack baseline** e do catálogo) → **propor CRIAR** a primeira skill dessa stack, **fundamentada em context7 ou documentação oficial atual** da versão travada — não apenas atualizar. A proposta é SEMPRE apresentada no fechamento, agrupada; criar/adiar/não-criar é decisão do usuário. É o único eixo que CRIA fora do bootstrap: ele acompanha a evolução da stack entre bootstraps, em vez de deixar a cobertura envelhecer até o próximo repo-scan.

<HARD-GATE>
**Refresh nunca sobrescreve às cegas.** Ao atualizar uma skill existente: leia a skill atual, mude
**só** o que a nova versão/padrão exige, **preserve as customizações** que o projeto adicionou, e
**mostre o diff ao usuário ANTES de gravar**. Aprovação é **por skill** — nunca em lote, nunca
implícita no "sim" dado a outra. Recriar uma skill do zero por cima de outra é proibido.
</HARD-GATE>

Atualização é sempre **propor → confirmar → aplicar → registrar**. Não há modo "mãos livres". Numa
edição que o usuário já pediu, a proposta é o próprio diff: mostre-o antes de gravar, no escopo
pedido, sem reabrir a autorização que ele acabou de dar.

---

## Cadência e gatilhos (híbrido)

A auto-manutenção combina lógica **portável na skill** (núcleo) com um **hook de reforço** no Claude Code. Mecânica detalhada em **[references/domain-skill-maintenance.md](references/domain-skill-maintenance.md)**.

```text
- Ao FECHAR uma tarefa (núcleo, portável — vale em .claude/.agents/.cursor; DISPARO PRIMÁRIO):
  leia o ledger, conte commits desde `last-review` (git rev-list --since) e os dias decorridos.
  Se >= 10 commits OU > 10 dias → proponha a revisão UMA vez ("avisa uma vez, nunca bloqueia").
  O eixo de DIAS é a âncora (cadência curta); os commits só antecipam num burst real.
- Repo-scan completo: se > 15 dias desde `last-full-scan` → proponha um re-scan e atualização ampla.
- A cada 10 interações (hook de reforço, só Claude Code): rede de segurança que checa o delta do
  git e injeta um lembrete quando o limiar é cruzado, com supressão de 7 dias após avisar. Ver
  `references/domain-skill-maintenance.md` e o script `.claude/hooks/pelizzai-cadence.mjs`. Opt-in:
  instalado no bootstrap com confirmação.
```

Os limiares (10 commits / 10 dias de revisão / 15 dias de full-scan / 10 interações / 7 dias de supressão) são deliberadamente curtos para manter a manutenção perto do trabalho real; ajuste-os ao ritmo do projeto. Nada na cadência **bloqueia** o trabalho do usuário — apenas sugere.

---

## Ledger e catálogo

Dois artefatos por projeto, criados/atualizados por esta skill:

- **`pelizzai/domain-skills.md`** — catálogo: o que cada skill de domínio faz e quando usar. Template: [templates/domain-skills.md](templates/domain-skills.md).
- **`pelizzai/data/review-domain-skills.md`** — ledger: por skill, data de criação, última atualização, último commit/ref revisado, o eixo da mudança e a origem (repo-scan/interview); + `last-review` e `last-full-scan` globais. Template: [templates/review-domain-skills.md](templates/review-domain-skills.md).

Semeie o ledger com a **data do bootstrap (hoje)**, tanto em repo novo quanto existente — o bootstrap acabou de criar as skills a partir do HEAD atual, então "última revisão = agora". Semear com o 1º commit de um repo maduro faz `daysReview`/`commits` nascerem estourados e dispara um nudge espúrio na primeira tarefa. `count=0` no dia do bootstrap é o correto (sobe conforme novos commits chegam). Ver `references/domain-skill-maintenance.md` → "Seeding".

---

## Otimização da descrição

Depois que uma skill está pronta, você pode **otimizar a `description`** para melhorar o acionamento (combater o sub-acionamento). Ver `references/skill-authoring.md` (seções "Frontmatter" e "Leading words"). Regra de ouro: a `description` diz o que a skill faz **e** lista os contextos/frases que devem acioná-la — e **nunca resume os passos do workflow** (o agente segue o resumo e pula o corpo). **Front-load a leading word** da skill — a palavra-âncora que já carrega o comportamento no pretraining (*seam*, *red*, *tracer bullet*).

---

## Anti-padrões

```text
- Sobrescrever uma skill existente sem ler/preservar customizações ou sem mostrar o diff.
- Auto-aplicar atualizações de skill em modo "mãos livres" (reprovado em campo no harness anterior).
- Criar skill de domínio com prefixo `pelizzai-`, sem evidência adequada ou num root inativo.
- Sobreajustar a skill aos casos de teste em vez de generalizar.
- Inflar o SKILL.md além de ~500 linhas em vez de usar `references/`.
- Inventar skills de domínio sem um padrão real do projeto por trás.
- Deixar a cadência bloquear o trabalho, ou repetir o nudge mais de uma vez.
- Esquecer de atualizar o catálogo e o ledger após criar/alterar uma skill.
- Fazer edição comportamental sem baseline/eval/forward-test proporcional ao risco.
- Resumir o workflow na description (o agente segue o resumo e pula o corpo).
- Gatilho vago que disputa qualquer pedido sem nomear os near misses (skill storm) — ou tão estreito
  que a skill nunca dispara (sub-acionamento, a falha dominante).
- Cortar candidata verdadeira para "manter o conjunto pequeno", ou redigir N candidatas em fila
  quando o time as escreveria em paralelo.
- Duplicar a mesma domain skill em roots sem verificar paridade.
```

---

## Fluxo operacional resumido

```text
1. Identifique o modo: Autoria (nova skill) ou Manutenção (atualizar existentes).
2. AUTORIA: capture a intenção → reúna evidência → baseline proporcional → escreva a skill mínima
   → valide/forward-test → registre no catálogo e ledger quando for domain skill.
3. BOOTSTRAP: enumere generosamente as candidatas verdadeiras → CONFIRME a lista com o usuário
   (gate 2.5) → redija em paralelo (time; subagente quando for uma só) → sincronize roots →
   catalogue → semeie o ledger → aceite final do usuário.
4. MANUTENÇÃO: detecte o eixo (versão/histórico/adoção) → version/rework leem a skill existente e
   mudam só o necessário; adoption PROPÕE criar a skill da stack nova (context7/doc oficial atual) →
   confirme se for proposta proativa → valide proporcionalmente → mostre o diff → registre no ledger
   com o eixo.
5. CADÊNCIA: ao fechar a tarefa, cheque o ledger e proponha revisão se o limiar foi cruzado.
```

---

## Integração

**Combina com:**

- `pelizzai-audit` — chama esta skill no bootstrap; aqui mora o motor de criação das skills de domínio.
- `pelizzai-team` — redigir muitas skills candidatas em paralelo; `pelizzai-subagents` para a delegação a um único subagente.
- `pelizzai-reasoning` — raciocínio da autoria (Structured Decomposition) e da manutenção (Critique and Refine, Evidence Synthesis).
- `pelizzai-interview-me` / `pelizzai-brainstorming` — ramo de projeto novo, antes de criar as primeiras skills.
- `pelizzai-writing-clearly-and-concisely` — redigir o corpo das skills com clareza.

---

## Instrução final para o agente

```text
Crie skills que generalizam e mantenha-as vivas sem nunca destruir o trabalho de quem veio antes.

Prefira:
- fundamentar no context7 a confiar na memória, sem tratar documentação como decisão do usuário;
- enumerar as candidatas que os padrões justificam a encolher a lista por escassez;
- redigir em paralelo (uma candidata por membro) a enfileirar candidatas confirmadas;
- mostrar o diff a sobrescrever;
- propor-confirmar a "mãos livres";
- references/ a um SKILL.md gigante;
- catalogar e registrar a deixar a manutenção depender de memória humana.

Toda skill de domínio entra no catálogo e no ledger.
Nenhuma atualização de skill é aplicada sem o diff e a confirmação do usuário; a aprovação é por
skill e vem acompanhada da evidência.
A criação incremental (eixo adoption) segue o mesmo propor→confirmar e nunca escreve skill de stack
sem fundamentação em context7 ou documentação oficial atual.
A cadência sugere; nunca bloqueia.
```
