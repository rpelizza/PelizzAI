---
name: pelizzai-writing-skills
description: Cria, edita e valida skills a pedido do usuário e mantém skills de DOMÍNIO de um projeto. Use no bootstrap para o menor conjunto justificado; na manutenção por stack/rework/cadência; e quando o usuário pedir criar ou otimizar uma skill. Nunca altera skills `pelizzai-*` autonomamente; preserva customizações e mostra o diff. Confirmação adicional é necessária para manutenção proativa, não para edição local já pedida explicitamente.
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

- **Frontmatter:** só `name` e `description`. A `description` é o gatilho — inclua **o que a skill faz E sinais observáveis de quando usá-la**. Seja preciso, não agressivo: broad triggers causam skill storm. A `description` não resume o workflow; o corpo contém o processo.
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
- Skill de stack/lib externa deve ser fundamentada na documentação oficial da versão real;
  use `context7` quando disponível, senão fonte oficial. Skill de convenção interna se fundamenta
  no código, testes, ADRs e histórico do próprio projeto.
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

---

## Modo Bootstrap (chamado pela `pelizzai-audit`)

Acionado em `bootstrap-write`, depois que a `pelizzai-audit` mapeou o contexto e criou a task branch. Scan-only não chama este modo.

```text
1. Receba somente o inventário evidenciado da pelizzai-audit e os skill roots ativos.
2. Liste o MENOR conjunto de candidatas. Uma candidata precisa representar invariante recorrente,
   específico e ainda não coberto, que mudaria uma decisão do agente. Zero é válido; 1–3 é comum.
2.5. Se o consentimento de bootstrap já incluiu nomes/escopo das candidatas, não pergunte de novo.
   Reabra a decisão somente se o scan mudou materialmente o conjunto proposto.
3. Redija inline uma candidata simples. Use um subagent por candidata independente quando houver
   ganho de contexto; use team apenas se várias candidatas realmente precisarem coordenação.
   Os membros que REDIGEM skills precisam de capacidade de ESCRITA (general-purpose ou subagent com
   ferramentas de escrita) e de acesso à documentação oficial necessária — agentes read-only
   servem só para pesquisa/leitura, não para gravar a skill.
4. Para cada skill: siga as regras de autoria; valide o frontmatter; registre no catálogo e no ledger
   (incluindo a origem: repo-scan ou interview).
5. Semeie o ledger (`last-review`/`last-full-scan`) com a **data do bootstrap (hoje)** — as skills
   nascem do repo-scan do HEAD atual, então o bootstrap É a primeira revisão; semear com o 1º commit
   de um repo maduro dispara um nudge espúrio já na primeira tarefa. Escreva o catálogo `pelizzai/domain-skills.md` — sua existência
   marca o bootstrap como concluído. Ver Templates.
6. Ofereça instalar o hook de cadência (opt-in; ver `references/domain-skill-maintenance.md`).
7. Mostre catálogo, diff e validação. Peça nova decisão apenas para escopo/conteúdo não coberto pela
   autorização existente ou para efeito externo.
```

> Em projeto **novo** (sem código), não há padrões a extrair: use `pelizzai-brainstorming` e stress
> somente quando risco/incerteza justificarem; depois crie skills a partir do design aprovado.

---

## Modo Manutenção

Mantém as skills de **domínio** vivas conforme o projeto evolui. Detalhe completo em **[references/domain-skill-maintenance.md](references/domain-skill-maintenance.md)**. Dois eixos:

> **Escopo (inegociável):** a manutenção autônoma — os dois eixos e a cadência — atua **somente** sobre skills de domínio. As skills do harness (`pelizzai-*`) **nunca** são alteradas pelo sistema autônomo; só são criadas ou editadas a pedido explícito do usuário.

- **Version-driven (refresh):** a stack mudou de versão maior ou ganhou dependência significativa → reler a doc da versão atual (context7) e **atualizar** a skill afetada. O drift é detectado comparando os manifests atuais com o **Stack baseline** de `pelizzai/profile.md` (gravado pela `pelizzai-audit` no bootstrap).
- **Rework-driven (histórico):** o mesmo ajuste foi feito à mão várias vezes no git → o padrão vira uma regra na skill.

<HARD-GATE>
**Refresh nunca sobrescreve às cegas.** Leia a skill atual, mude **só** o que a nova versão/padrão
exige, preserve customizações e mostre o diff. Manutenção sugerida autonomamente exige aprovação;
pedido explícito de edição já autoriza a mudança local no escopo pedido. Recriar por cima sem
preservar conteúdo é proibido.
</HARD-GATE>

Cadência proativa segue **propor → confirmar → aplicar → registrar**. Edição explicitamente pedida
segue **inspecionar → aplicar cirurgicamente → validar → mostrar diff**.

---

## Cadência e gatilhos (híbrido)

A auto-manutenção combina lógica **portável na skill** (núcleo) com um **hook de reforço** no Claude Code. Mecânica detalhada em **[references/domain-skill-maintenance.md](references/domain-skill-maintenance.md)**.

```text
- Ao FECHAR uma tarefa (núcleo, portável — vale em .claude/.agents/.cursor; DISPARO PRIMÁRIO):
  leia o ledger, conte commits desde `last-review` (git rev-list --since) e os dias decorridos.
  Se >= 30 commits OU > 14 dias → proponha a revisão UMA vez ("avisa uma vez, nunca bloqueia").
  O eixo de DIAS é a âncora (cadência de ~sprint); os commits só antecipam num burst real.
- Repo-scan completo: se > 21 dias desde `last-full-scan` → proponha um re-scan e atualização ampla.
- A cada 20 interações (hook de reforço, só Claude Code): rede de segurança que checa o delta do
  git e injeta um lembrete quando o limiar é cruzado, com supressão de 7 dias após avisar. Ver
  `references/domain-skill-maintenance.md` e o script `.claude/hooks/pelizzai-cadence.mjs`. Opt-in:
  instalado no bootstrap com confirmação.
```

Os limiares (30 commits / 14 dias de revisão / 21 dias de full-scan / 20 interações / 7 dias de supressão) são calibrados para times ativos; ajuste-os ao ritmo do projeto. Nada na cadência **bloqueia** o trabalho do usuário — apenas sugere.

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
- Gatilho amplo que aciona a skill por utilidade hipotética em vez de sinal observável.
- Duplicar a mesma domain skill em roots sem verificar paridade.
```

---

## Fluxo operacional resumido

```text
1. Identifique o modo: Autoria (nova skill) ou Manutenção (atualizar existentes).
2. AUTORIA: capture a intenção → reúna evidência → baseline proporcional → escreva a skill mínima
   → valide/forward-test → registre no catálogo e ledger quando for domain skill.
3. BOOTSTRAP: liste o menor conjunto → CONFIRME → redija no modo proporcional → sincronize roots
   → catalogue → semeie o ledger → aceite final do usuário.
4. MANUTENÇÃO: detecte o eixo (versão/histórico) → leia a skill atual → confirme se for proposta
   proativa → mude só o necessário → valide proporcionalmente → mostre o diff → registre no ledger.
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
- fundamentar no context7 a confiar na memória;
- mostrar o diff a sobrescrever;
- confirmação para manutenção proativa; execução direta para edição já pedida;
- references/ a um SKILL.md gigante;
- catalogar e registrar a deixar a manutenção depender de memória humana.

Toda skill de domínio entra no catálogo e no ledger.
Nenhuma atualização proativa é aplicada sem confirmação; toda atualização mostra diff e evidência.
A cadência sugere; nunca bloqueia.
```
