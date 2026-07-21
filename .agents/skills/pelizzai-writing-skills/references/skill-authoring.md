# Autoria de skills — regras detalhadas

Adaptação, para o harness PelizzAI, das regras de criação de skills da Anthropic (skill-creator) e de lições testadas em campo em harnesses de referência maduros. Leia antes de redigir uma skill.

O objetivo é mudar comportamento de forma observável com o menor contexto necessário. Uma skill não fica melhor por ser mais longa, incisiva ou ritualizada; fica melhor quando aciona no contexto certo e bloqueia uma falha real, observada.

## Sumário

| Seção | O que cobre |
| --- | --- |
| Fluxo de autoria | As etapas, da intenção ao empacotamento |
| TDD de skills (RED-GREEN-REFACTOR) | A Lei de Ferro: baseline falho observado antes de escrever |
| Evidência e validação comportamental | A escada: qual forma de evidência cada tipo de mudança exige |
| Pressure tests versionados | Cenários de regressão comportamental junto da skill |
| Meta-testing do fracasso | O agente que violou diagnostica a própria skill |
| Frontmatter | A `description` como gatilho — e nunca como resumo do workflow |
| Leading words e o teste no-op | Âncoras de pretraining; poda por sentença |
| Divulgação progressiva / Anatomia | Estrutura física da skill |
| Fonte e roots de skills | Onde editar; mirrors gerados; sync como parte da edição |
| Padrões de escrita | Imperativo, porquê, exemplos |
| Grau de liberdade | Princípios, pseudocódigo ou script — conforme a fragilidade da tarefa |
| Match the Form to the Failure | A forma da guidance casa com o tipo de falha |
| Persuasão calibrada | Authority/Commitment/Scarcity/Social Proof sim; Liking/Reciprocity proibidos |
| Conclusão prematura e passos pós-conclusão | Completion criterion; fronteiras reais de contexto |
| Scripts | Quando a operação vira código determinístico |
| Micro-teste de wording / Evals | Validação barata antes da cara |
| Ausência de Surpresas / Critério de conclusão / Empacotamento | Segurança, fechamento e distribuição |

## Fluxo de autoria

```text
1. Capturar a intenção   — o que a skill deve permitir; quando deve acionar; formato de saída; precisa de evals?
2. Pesquisar             — Context7 (preferido) ou documentação oficial atual, na versão realmente usada.
3. Baseline falho (RED)  — rodar o cenário SEM a skill e capturar as racionalizações verbatim
                           (ver "TDD de skills" abaixo).
4. Escolher a forma      — princípios, pseudocódigo/checklist ou script determinístico
                           (ver "Grau de liberdade" e "Match the Form to the Failure").
5. Escrever o SKILL.md   — a skill MÍNIMA contra as falhas observadas (GREEN), seguindo os padrões abaixo.
6. Fechar loopholes      — re-rodar sob pressão, fechar cada brecha (REFACTOR) e versionar os cenários
                           como `test-pressure-<n>.md` no diretório da skill.
7. Evals (se aplicável)  — casos de teste para saídas verificáveis (micro-teste de wording ANTES do eval caro).
8. Iterar                — rascunho → olhar renovado → melhorar; generalizar a partir do feedback.
9. Otimizar a descrição  — para melhorar o acionamento (condições de disparo; nunca o resumo do processo).
10. Fechar               — remover duplicação, sincronizar os mirrors aplicáveis, registrar limitações reais;
                           empacotar apenas se for distribuir fora do repo.
```

Não repita uma decisão que o usuário já ratificou. Quando intenção, escopo ou formato ainda forem decisões humanas, pare e pergunte com a `pelizzai-interview-me`, uma pergunta por vez, com a melhor recomendação marcada; não os preencha com defaults. Não pesquise por reflexo quando o conhecimento necessário está no projeto. Para fatos externos que podem ter mudado, prefira Context7 ou documentação oficial — ela fundamenta opções, não decide pelo usuário.

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

Verifique os MCPs disponíveis. Se úteis (consultar doc, achar skills semelhantes, conferir boas práticas), pesquise em paralelo com a `pelizzai-team`, delegue a um único subagente com a `pelizzai-subagents`, ou faça inline. **Prefira o MCP `context7`** para fundamentar na documentação real da versão travada no lockfile; sem ele, use documentação oficial atual e declare a limitação. Traga contexto pronto para reduzir a carga do usuário.

## TDD de skills (RED-GREEN-REFACTOR)

> Escrever skills **É** Test-Driven Development aplicado a documentação de processo.

A Lei de Ferro da autoria: **nenhuma skill nova — e nenhuma edição comportamental de skill existente — sem um baseline falho observado.** O ciclo:

```text
RED      — rode o cenário-alvo SEM a skill, em contexto fresco, e observe a falha real.
           Capture as racionalizações VERBATIM ("os testes aqui são triviais demais para
           valer TDD", "escrevo o teste depois para não perder o fluxo") — são ELAS que a
           skill precisa bloquear, não as falhas que você imagina de antemão. Sem baseline
           falho observado, você não sabe se a skill muda alguma coisa.
GREEN    — escreva a skill MÍNIMA que bloqueia exatamente as falhas capturadas. Nada contra
           falha hipotética: cada regra existe porque uma racionalização real a exige.
REFACTOR — re-rode COM a skill, sob pressão. Cada loophole novo que o agente encontrar vira
           correção dirigida (nova linha na tabela de racionalizações, um princípio mais
           fundacional, reorganização) seguida de re-teste. Versione os cenários usados
           (ver "Pressure tests versionados").
```

Escopo da lei:

```text
- Vale para skills de DOMÍNIO e para as skills do harness (`pelizzai-*`).
- Vale para skill NOVA e para EDIÇÃO COMPORTAMENTAL de skill existente — qualquer mudança
  que altere o que o agente FAZ.
- Edição puramente editorial (typo, formatação, link quebrado) NÃO é comportamental e
  dispensa baseline.
- No bootstrap, o padrão real observado no repo-scan/histórico cumpre o papel do baseline —
  a falha já foi observada no campo. É a mesma regra dita de outro jeito: não invente skill
  sem evidência de falha ou padrão real por trás.
```

Por que a lei é dura: em um harness de referência testado em campo, a skill de TDD precisou de **6 iterações** e de **mais de 10 racionalizações únicas** capturadas e bloqueadas uma a uma até atingir **100% de compliance** sob pressão. Sem o baseline RED, cada uma dessas racionalizações teria sobrevivido invisível — a skill "parecia boa" no texto e falhava em campo.

## Evidência e validação comportamental

A Lei de Ferro exige evidência de falha real. Esta seção diz **qual forma** essa evidência assume — a escada, não um ritual único:

| Mudança | Evidência mínima típica |
| --- | --- |
| typo, link ou formatação | parser/link/static check |
| script ou formato determinístico | fixture + resultado esperado + caso de erro |
| regra de segurança ou ciclo de vida | matriz de comandos/cenários permitidos e bloqueados |
| routing/description | positivos, *near misses* e casos ambíguos |
| disciplina sob pressão | pressure test versionado, re-rodado antes e depois da edição |
| orientação subjetiva | crítica por critérios e exemplos contrastantes |

O baseline falho é obrigatório quando o comportamento ainda é desconhecido, a mudança é de alto impacto ou o agente costuma racionalizar exceções. Evidência já observada no repositório, em uma regressão ou no feedback do usuário cumpre esse papel — é falha real, apenas capturada em outro lugar. O que não cumpre é falha imaginada: não fabrique um cenário para preencher a tabela, nem exija arquivo de pressure test para cada ajuste de wording.

Para mudanças complexas, faça *forward testing*: dê a uma sessão fresca apenas o pedido e a skill nova, sem revelar o diagnóstico desejado. Observe a rota escolhida e corrija a instrução, não a resposta do teste.

## Pressure tests versionados (`test-pressure-<n>.md`)

Todo cenário usado para validar uma skill de disciplina é **versionado junto dela**: arquivos `test-pressure-1.md`, `test-pressure-2.md`, … no diretório da skill, ao lado do `SKILL.md`. São documentos de referência **sem frontmatter** (o frontmatter `name`/`description` é exclusivo do `SKILL.md`). Eles são o **critério de regressão**: qualquer mudança comportamental na skill re-roda os cenários antes e depois da edição.

Anatomia de um bom cenário de pressão:

```text
- 3+ pressões COMBINADAS: tempo ("o deploy é em 20 minutos"), sunk cost ("você já escreveu
  400 linhas"), autoridade ("o tech lead mandou pular"), exaustão ("é a sexta tentativa,
  já são 23h"), social ("todo mundo do time faz assim"). Uma pressão isolada não derruba
  o agente; a combinação sim.
- Opções A/B/C FORÇADAS — uma correta, as demais tentadoras e defensáveis.
- A pergunta é "o que você FAZ?", nunca "o que você deveria fazer" — o condicional convida
  a uma resposta teórica; o presente força a decisão.
- Sem saída fácil: "eu perguntaria ao usuário" sem escolher uma opção é resposta inválida
  no cenário (na vida real, perguntar pode ser certo; no teste, mascara a decisão).
```

Cenários vivos no harness, que servem de modelo de forma e de regressão real:

- `.claude/skills/pelizzai-recovery/test-pressure-1.md` — "só dá um `reset --hard` que resolve" (urgência + autoridade + sunk cost + exaustão).
- `.claude/skills/pelizzai-improving-architecture/test-pressure-1.md` — "já vai refatorando os cinco".

Mudança comportamental nessas skills re-roda o cenário correspondente antes e depois. Os arquivos são espelhados para os roots gerados pelo `sync-harness`; edite apenas o root canônico (ver "Fonte e roots de skills").

## Meta-testing: quando o agente viola com a skill carregada

Falhou COM a skill no contexto? Não adivinhe o conserto: **pergunte ao próprio agente** como a skill deveria ter sido escrita para que ele não tivesse violado. Três diagnósticos:

| O agente responde | Diagnóstico | Correção |
| --- | --- | --- |
| "eu sabia da regra, mas achei que aqui não valia" | ignorou sabendo | falta um **princípio fundacional** — o porquê que fecha a negociação |
| "a skill deveria dizer X" | lacuna literal | adicione **X verbatim** |
| "não vi a seção Y" | problema de organização | **reorganize** — promova a seção, encurte o que vem antes dela |

Uma skill de disciplina está **bulletproof** quando o agente: (1) escolhe a opção correta sob pressão máxima; (2) **cita as seções da skill** ao justificar a escolha; (3) **admite a tentação** ("a opção B era atraente porque…") — sinal de que processou o conflito em vez de não tê-lo visto.

## Frontmatter

Apenas dois campos, ambos obrigatórios:

```yaml
---
name: nome-kebab-case
description: O que a skill faz e os contextos observáveis em que deve ser usada.
---
```

- **name** — identificador da skill (kebab-case), igual ao nome do diretório.
- **description** — **o gatilho**. É o mecanismo principal de acionamento. Inclua **o que a skill faz E os contextos específicos de uso**. Toda informação de "quando usar" vai aqui, não no corpo.

> Observação: o harness tende a **acionar de menos**. Torne as descrições "incisivas". Em vez de "Cria um dashboard de dados internos", escreva "Cria um dashboard de dados internos. Use sempre que o usuário mencionar dashboards, visualização de dados ou métricas, ou quiser exibir qualquer dado da empresa — mesmo sem pedir explicitamente um 'dashboard'."

Incisivo não é vago. As duas falhas são reais e se corrigem juntas:

```text
- Sub-acionamento (falha dominante): a description cita só o nome canônico da tarefa e a skill
  nunca dispara. Correção: enriquecer os GATILHOS — termos que o usuário realmente diria,
  variações casuais e formais, sinônimos do domínio.
- Skill storm: a description é ampla a ponto de disputar qualquer pedido com skills melhores.
  Correção: nomear os NEAR MISSES — palavras em comum não bastam quando a intenção é outra.
```

Uma restrição curta e inegociável pode ficar na descrição quando for essencial para o routing.

**Otimizar o acionamento (método verificável):** monte ~20 queries realistas — metade que **deve** acionar a skill (frasais variados, casual/formal, sem citar a skill pelo nome) e metade *near-miss* que **não** deve (compartilha palavras-chave, mas precisa de outra coisa). Meça a taxa de acionamento e prefira a descrição que melhor **generaliza**, evitando sobreajuste às queries de treino. Expanda para uma suíte maior apenas se a fronteira estiver ambígua ou já tiver regredido.

(`compatibility` é opcional e raramente necessário.)

### A `description` nunca resume o workflow

Descoberta contra-intuitiva, testada em campo em harness de referência: quando a `description` resume o processo, o agente **segue a description e pula o corpo**. Caso real: uma skill com "code review between tasks" na description levou o agente a fazer **um** review em vez dos **dois** que o corpo do fluxo exigia — o resumo virou substituto do fluxo.

```text
- description = O QUE a skill faz + QUANDO acioná-la (condições de disparo, frases-gatilho).
- O PROCESSO (fases, ordem, contagens, comandos) vive no corpo — nunca na description.
- Se a description contém uma sequência de passos ("faz A, depois B e fecha com C"),
  reescreva: mantenha os gatilhos ricos, corte o resumo de processo.
- Constraint inegociável curta ("NUNCA comece em main sem consentimento") pode ficar —
  o proibido é a SEQUÊNCIA de passos, que o agente executa em versão rasa.
```

## Leading words e o teste no-op

**Leading word**: palavra compacta que já vive no pretraining do modelo e funciona como âncora comportamental — *seam*, *tracer bullet*, *red*, *tight*, *fog of war*. Uma leading word certa vale um parágrafo de instrução: ela puxa o comportamento inteiro associado a ela. **Front-load a leading word na `description`** — é o primeiro (às vezes o único) texto da skill que o agente vê.

**Teste no-op**, por sentença: "esta sentença muda o comportamento do agente em relação ao default sem ela?" Decida **rodando** (contexto fresco, com e sem a sentença), **não debatendo**. A poda é por **sentença inteira**, não palavra a palavra — meia sentença podada deixa a negociação aberta.

Modos de falha nomeados:

| Modo | Sintoma |
| --- | --- |
| **Sediment** | adicionar parece seguro, remover parece arriscado — a skill só cresce, camada sobre camada |
| **Sprawl** | o comprimento em si é o custo: dilui a proeminência do que importa |
| **Duplication** | repetir uma regra infla artificialmente a proeminência dela às custas das outras |
| **No-op** | "seja cuidadoso" não muda comportamento nenhum; o fix de "be thorough" (no-op) foi "relentless" (leading word) |

## Divulgação progressiva (3 níveis)

```text
1. Metadados (name + description) — sempre no contexto (~100 palavras).
2. Corpo do SKILL.md             — no contexto quando a skill é acionada (ideal < 500 linhas).
3. Recursos agrupados            — sob demanda (ilimitado; scripts podem rodar sem carregar no contexto).
```

Padrões:

- Mantenha o `SKILL.md` < 500 linhas. Aproximando-se do limite, adicione um nível hierárquico (mova profundidade para `references/`) com ponteiros claros sobre **quando** ler cada arquivo.
- Faça referências explícitas aos arquivos a partir do `SKILL.md`. Não crie uma cadeia profunda de referências.
- Para arquivos de referência longos (>300 linhas), inclua um sumário no topo.
- Mantenha o corpo focado no workflow e nos critérios de decisão; mova tabelas extensas, detalhes de fornecedor e exemplos volumosos para `references/`.

Os números (~100 palavras de metadados, <500 linhas de corpo, 300 linhas para sumário) são **aproximados** — passe deles quando houver motivo. A meta é manter enxuto o que fica sempre no contexto, não cumprir uma cota.

## Anatomia

```text
nome-da-skill/
├── SKILL.md (obrigatório)
│   ├── frontmatter YAML (name, description) — exclusivo do SKILL.md
│   └── instruções em Markdown
├── test-pressure-<n>.md (skills de disciplina) — cenários de regressão, SEM frontmatter
└── Recursos agrupados (opcional)
    ├── scripts/    — código executável para tarefas determinísticas/repetitivas
    ├── references/ — documentos carregados sob demanda
    └── assets/     — arquivos usados na saída (templates, ícones, fontes)
```

Nem toda skill precisa desses diretórios. Não crie README, changelog ou arquivos auxiliares sem função operacional.

**Organização por variante** (quando a skill cobre múltiplos domínios/frameworks):

```text
nome-da-skill/
├── SKILL.md           (workflow + seleção da variante)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

## Fonte e roots de skills

No repo-fonte do PelizzAI:

- edite `.claude/skills/<nome>/`;
- trate `.agents/skills/` como mirror gerado; `.cursor/rules/pelizzai.mdc` é adaptador **manual** — o sync não o gera, atualize-o à mão quando os entrypoints mudarem;
- depois de uma edição autorizada, rode automaticamente `node scripts/sync-harness.mjs` e valide
  com `node scripts/sync-harness.mjs --check --source-mode`; `.ps1` e `.sh` são wrappers.

Num projeto consumidor, detecte o root ativo antes de escrever. Use `.claude/skills/` **ou** `.agents/skills/`, conforme a plataforma e as convenções existentes; não duplique a edição nos dois roots por conta própria. Se o projeto declarar um processo de geração, edite a fonte e rode esse processo automaticamente como parte da edição já autorizada.

## Padrões de escrita

- Use o **imperativo** nas instruções e critérios observáveis.
- Explique **por que** algo importa (teoria da mente), em vez de impor regras rígidas e excessivas — mas só quando o porquê fecha uma racionalização provável. Skills abrangentes generalizam melhor que skills presas a exemplos.
- **Defina formatos de saída** com um modelo exato quando a saída precisa ser consistente.
- **Inclua exemplos** (entrada → saída) quando reduzirem ambiguidade.
- Prefira uma regra central a repetições espalhadas.
- Nomeie limites e caminhos de fallback; diga quando **não** usar a skill.
- Comece com um rascunho; depois revise com um olhar renovado e melhore.

## Grau de liberdade

| Situação | Forma adequada |
| --- | --- |
| Múltiplas soluções válidas; julgamento contextual | princípios e critérios de decisão |
| Padrão preferido com variação aceitável | pseudocódigo, checklist curto ou exemplo parametrizado |
| Operação frágil, repetitiva ou com ordem exata | script determinístico e poucos parâmetros |

Não transforme heurística em invariante. Segurança, autoridade e integridade podem exigir regras rígidas; estilo, decomposição, técnicas de reasoning e quantidade de testes normalmente exigem seleção contextual.

## Match the Form to the Failure

O grau de liberdade responde à **fragilidade da tarefa**; esta seção responde ao **tipo de falha**. Errar a forma torna a skill inócua ou contraproducente:

| Tipo de falha | Forma correta da guidance |
| --- | --- |
| Viola a disciplina sob pressão | **Proibição explícita** + tabela de racionalizações (cada desculpa capturada, com a resposta) |
| Output com a forma errada | **RECEITA POSITIVA** do que o output É (modelo, exemplo, esqueleto) |
| Elemento omitido | Slot **REQUIRED** no template — a ausência fica sintaticamente visível |
| Comportamento condicional errado | Condicional sobre **predicado observável** ("se o arquivo existir", não "se fizer sentido") |

Por que receita positiva para forma de output — evidência A/B de harness maduro: o braço com proibições ("don't X") produziu **MAIS** conteúdo indesejado que o controle **sem guidance nenhuma**. A proibição chama atenção exatamente para o padrão que quer suprimir. Para shaping de output, descreva o que o output **é**; nunca liste o que ele não é.

Corolários:

```text
- SEM nuance clauses: "não faça X a menos que realmente importe" reabre a negociação que a
  regra existia para fechar — sob pressão, tudo "realmente importa".
- Cláusulas de isenção não escopam: "isso não se aplica a Y" vira o buraco por onde tudo
  passa. Se a regra precisa de exceção, REESTRUTURE a regra até a exceção desaparecer.
```

## Persuasão calibrada

Base empírica: Meincke et al. 2025 — princípios clássicos de persuasão elevaram a compliance de LLMs de **33% para 72%**. Skills de disciplina podem (e devem) usar os princípios certos; os errados são proibidos:

| Princípio | Uso em skills |
| --- | --- |
| **Authority** | "VOCÊ DEVE", sem exceções nem atenuantes — o núcleo das skills de disciplina |
| **Commitment** | fazer o agente ANUNCIAR o que vai fazer; checklists com todos; escolha forçada entre opções |
| **Scarcity** | urgência real de sequência: "IMEDIATAMENTE após X" |
| **Social Proof** | consequência universal: "checklist sem todo = passo pulado. Sempre." |
| **Liking** | **PROIBIDO** — elogiar/agradar gera sycophancy, não disciplina |
| **Reciprocity** | **PROIBIDO** — "eu fiz por você, então…" gera sycophancy, não disciplina |

Teste ético antes de usar qualquer técnica: **"essa técnica serviria ao interesse genuíno do usuário se ele a entendesse por completo?"** Se a resposta for não, não use.

## Conclusão prematura e passos pós-conclusão

Passos futuros visíveis **puxam** o agente para concluir cedo: ele enxerga o fim do fluxo e começa a encerrar antes de cumprir o critério. Defesa **em ordem**:

```text
1. Afie o completion criterion PRIMEIRO. Dois eixos:
   - clarity — o critério resiste à conclusão prematura? "Toda skill modificada contabilizada"
     resiste; "revise as skills" não.
   - demand  — o critério FORÇA o trabalho? "Toda skill modificada contabilizada" exige
     verificar cada uma; "produza uma lista" aceita qualquer lista.
2. Só se afiar não bastar, esconda os passos futuros — e esconder só funciona através de
   uma fronteira REAL de contexto (subagent, handoff). "Esconder" inline (jogar para o fim
   do texto, dizer "ignore por enquanto") não limpa nada: o agente já leu.
```

## Scripts

Prefira script quando copiar comandos seria frágil ou o resultado puder ser verificado automaticamente. Um script deve:

- aceitar entradas explícitas e validar parâmetros;
- falhar com mensagem acionável;
- evitar efeitos destrutivos por default;
- funcionar a partir de caminhos documentados;
- ter ao menos uma fixture feliz e um erro representativo quando for crítico.

Teste o script executando-o. Apenas lê-lo não valida quoting, encoding, diferenças de plataforma ou códigos de saída.

## Micro-teste de wording

Antes de qualquer eval caro, valide o wording barato:

```text
1. 5+ amostras fresh-context POR VARIANTE de wording.
2. Sempre contra um CONTROLE sem guidance — sem controle, você não sabe se a skill mudou
   o comportamento ou se o modelo já faria aquilo sozinho.
3. Leia cada match MANUALMENTE: echo de template (o agente repete as palavras da skill sem
   mudar o comportamento) mascara um falso hit.
4. VARIÂNCIA é métrica de primeira classe: cinco interpretações diferentes em cinco reps
   = o wording NÃO é vinculante, por melhor que "a média" pareça.
5. PROIBIDO batching: feche o wording de uma skill antes de passar à próxima — em lote,
   você não sabe qual mudança causou qual efeito.
```

## Evals (quando a saída é verificável)

O micro-teste de wording (seção acima) vem primeiro; a eval é o passo caro. Evals são indicados quando existe saída objetivamente verificável ou uma fronteira de routing importante. Cada caso deve conter contexto mínimo e entrada, comportamento esperado, comportamento proibido relevante, critério objetivo de aprovação e o motivo pelo qual o caso protege uma regressão plausível.

Estrutura do arquivo que **você cria** dentro da skill, em evals/evals.json (nenhuma skill deste repositório usa esse formato hoje — as evals do harness são os cenários em Markdown descritos abaixo):

```json
{
  "skill_name": "nome-da-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "Tarefa do usuário",
      "expected_output": "Resultado esperado",
      "expectations": ["A saída inclui X", "A skill usou o script Y"],
      "files": []
    }
  ]
}
```

O campo `expectations` (afirmações objetivamente verificáveis) é o que o **grader** checa — é o que torna a eval "verificável". Adicione-o ao redigir as asserções. O esquema completo de `evals.json`/`grading.json` **não vive neste repositório**: ele vem do `skill-creator` da Anthropic, no arquivo references/schemas.md **do pacote daquela skill**. Confirme o nome exato do campo na versão que você tiver instalada, em vez de assumir o que está escrito aqui.

Quando o critério é de **roteamento** e não de saída literal, o harness usa cenários em Markdown dentro de `evals/` (ex.: `.claude/skills/pelizzai-router/evals/adaptive-user-control.md`, `.claude/skills/pelizzai-reasoning/evals/`). Mesma exigência: cada caso nomeia a rota esperada, a rota proibida e a regressão que protege.

Procedimento (quando há subagentes disponíveis):

```text
- Rode em paralelo: uma execução COM a skill e uma SEM (baseline).
- Enquanto rodam, redija asserções quantitativas; capture tokens e duração das notificações.
- Avalie cada execução com um subagente "grader" contra as asserções.
- Agregue em benchmark.json e mostre ao usuário (ex.: eval-viewer).
- Itere a partir do feedback, GENERALIZANDO (não sobreajuste aos casos de teste).
```

Em ambientes sem subagentes (ex.: claude.ai), rode os casos sequencialmente, sem baseline/benchmark, e apresente os resultados na conversa.

Evite transformar a redação exata da resposta em contrato, salvo quando o formato for uma API. Teste decisões e efeitos observáveis.

## Princípio da Ausência de Surpresas

Skills não devem conter malware, exploit ou conteúdo que comprometa a segurança. Não atenda pedidos para criar skills enganosas ou voltadas a acesso não autorizado, exfiltração ou atividade maliciosa. Uma skill não deve surpreender o usuário quanto à finalidade declarada. (Recursos legítimos como "atue como um XYZ" são aceitáveis.)

Uma skill também não deve introduzir silenciosamente rede, credenciais, instalação global, escrita fora do escopo, publicação ou destruição de dados. Declare dependências e efeitos. Use consentimento quando uma nova autoridade for necessária. Nunca inclua segredos em examples, logs ou fixtures.

## Critério de conclusão

Uma skill está pronta quando:

- seu gatilho distingue usos válidos de *near misses*;
- o corpo contém apenas instruções que mudam comportamento (teste no-op aplicado);
- o grau de liberdade e a forma da guidance combinam com a fragilidade da tarefa e o tipo de falha;
- links, frontmatter e scripts relevantes foram validados;
- o comportamento crítico passou no baseline e nos cenários de pressão versionados, quando houver;
- fonte, mirrors e documentação não contradizem o novo contrato.

## Empacotamento

Para distribuir uma skill como artefato, empacote a pasta da skill (ex.: `python -m scripts.package_skill <pasta>` no skill-creator de origem). No PelizzAI, skills vivem em `.claude/skills/` e são versionadas com o projeto; empacotar só é necessário quando o usuário realmente precisar distribuí-la fora do repositório. Dentro do PelizzAI, versionamento e sync são suficientes.
