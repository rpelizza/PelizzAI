# Autoria de skills — regras detalhadas

Adaptação, para o harness PelizzAI, das regras de criação de skills da Anthropic (skill-creator) e das lições testadas em campo dos harnesses de origem do benchmark (obra/superpowers e mattpocock/skills). Leia antes de redigir uma skill.

## Sumário

| Seção | O que cobre |
| --- | --- |
| Fluxo de autoria | As etapas, da intenção ao empacotamento |
| TDD de skills (RED-GREEN-REFACTOR) | A Lei de Ferro: baseline falho observado antes de escrever |
| Pressure tests versionados | Cenários de regressão comportamental junto da skill |
| Meta-testing do fracasso | O agente que violou diagnostica a própria skill |
| Frontmatter | A `description` como gatilho — e nunca como resumo do workflow |
| Leading words e o teste no-op | Âncoras de pretraining; poda por sentença |
| Divulgação progressiva / Anatomia | Estrutura física da skill |
| Padrões de escrita | Imperativo, porquê, exemplos |
| Match the Form to the Failure | A forma da guidance casa com o tipo de falha |
| Persuasão calibrada | Authority/Commitment/Scarcity/Social Proof sim; Liking/Reciprocity proibidos |
| Conclusão prematura e passos pós-conclusão | Completion criterion; fronteiras reais de contexto |
| Micro-teste de wording / Evals | Validação barata antes da cara |
| Ausência de Surpresas / Empacotamento | Segurança e distribuição |

## Fluxo de autoria

```text
1. Capturar a intenção   — o que a skill deve permitir; quando deve acionar; formato de saída; precisa de evals?
2. Pesquisar             — context7 (preferido) ou web para fundamentar na doc real da versão correta.
3. Baseline falho (RED)  — rodar o cenário SEM a skill e capturar as racionalizações verbatim
                           (ver "TDD de skills" abaixo).
4. Escrever o SKILL.md   — a skill MÍNIMA contra as falhas observadas (GREEN), seguindo os padrões abaixo.
5. Fechar loopholes      — re-rodar sob pressão, fechar cada brecha (REFACTOR) e versionar os cenários
                           como `test-pressure-<n>.md` no diretório da skill.
6. Evals (se aplicável)  — casos de teste para saídas verificáveis (micro-teste de wording ANTES do eval caro).
7. Iterar                — rascunho → olhar renovado → melhorar; generalizar a partir do feedback.
8. Otimizar a descrição  — para melhorar o acionamento (condições de disparo; nunca o resumo do processo).
9. Empacotar (se for distribuir).
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

Verifique os MCPs disponíveis. Se úteis (consultar doc, achar skills semelhantes, conferir boas práticas), pesquise em paralelo com a `pelizzai-team` (que cobre também a delegação a um único subagente) ou inline. **Prefira o MCP `context7`** para fundamentar na documentação real; sem ele, use a web. Traga contexto pronto para reduzir a carga do usuário.

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

Por que a lei é dura: no superpowers, a skill de TDD precisou de **6 iterações** e de **mais de 10 racionalizações únicas** capturadas e bloqueadas uma a uma até atingir **100% de compliance** sob pressão. Sem o baseline RED, cada uma dessas racionalizações teria sobrevivido invisível — a skill "parecia boa" no texto e falhava em campo.

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

## Meta-testing: quando o agente viola com a skill carregada

Falhou COM a skill no contexto? Não adivinhe o conserto: **pergunte ao próprio agente** como a skill deveria ter sido escrita para que ele não tivesse violado. Três diagnósticos:

| O agente responde | Diagnóstico | Correção |
| --- | --- | --- |
| "eu sabia da regra, mas achei que aqui não valia" | ignorou sabendo | falta um **princípio fundacional** — o porquê que fecha a negociação |
| "a skill deveria dizer X" | lacuna literal | adicione **X verbatim** |
| "não vi a seção Y" | problema de organização | **reorganize** — promova a seção, encurte o que vem antes dela |

Uma skill de disciplina está **bulletproof** quando o agente: (1) escolhe a opção correta sob pressão máxima; (2) **cita as seções da skill** ao justificar a escolha; (3) **admite a tentação** ("a opção B era atraente porque…") — sinal de que processou o conflito em vez de não tê-lo visto.

## Frontmatter

Apenas dois campos obrigatórios:

- **name** — identificador da skill (kebab-case).
- **description** — **o gatilho**. É o mecanismo principal de acionamento. Inclua **o que a skill faz E os contextos específicos de uso**. Toda informação de "quando usar" vai aqui, não no corpo.

> Observação: o harness tende a **acionar de menos**. Torne as descrições "incisivas". Em vez de "Cria um dashboard de dados internos", escreva "Cria um dashboard de dados internos. Use sempre que o usuário mencionar dashboards, visualização de dados ou métricas, ou quiser exibir qualquer dado da empresa — mesmo sem pedir explicitamente um 'dashboard'."

**Otimizar o acionamento (método verificável):** monte ~20 queries realistas — metade que **deve** acionar a skill (frasais variados, casual/formal, sem citar a skill pelo nome) e metade *near-miss* que **não** deve (compartilha palavras-chave, mas precisa de outra coisa). Meça a taxa de acionamento e prefira a descrição que melhor **generaliza**, evitando sobreajuste às queries de treino.

(`compatibility` é opcional e raramente necessário.)

### A `description` nunca resume o workflow

Descoberta contra-intuitiva, testada em campo (superpowers): quando a `description` resume o processo, o agente **segue a description e pula o corpo**. Caso real: uma skill com "code review between tasks" na description levou o agente a fazer **um** review em vez dos **dois** que o corpo do fluxo exigia — o resumo virou substituto do fluxo.

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
- Faça referências explícitas aos arquivos a partir do `SKILL.md`.
- Para arquivos de referência longos (>300 linhas), inclua um sumário no topo.

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

## Match the Form to the Failure

A forma da guidance tem que casar com o **tipo de falha** que ela corrige — errar a forma torna a skill inócua ou contraproducente:

| Tipo de falha | Forma correta da guidance |
| --- | --- |
| Viola a disciplina sob pressão | **Proibição explícita** + tabela de racionalizações (cada desculpa capturada, com a resposta) |
| Output com a forma errada | **RECEITA POSITIVA** do que o output É (modelo, exemplo, esqueleto) |
| Elemento omitido | Slot **REQUIRED** no template — a ausência fica sintaticamente visível |
| Comportamento condicional errado | Condicional sobre **predicado observável** ("se o arquivo existir", não "se fizer sentido") |

Por que receita positiva para forma de output — evidência A/B do superpowers: o braço com proibições ("don't X") produziu **MAIS** conteúdo indesejado que o controle **sem guidance nenhuma**. A proibição chama atenção exatamente para o padrão que quer suprimir. Para shaping de output, descreva o que o output **é**; nunca liste o que ele não é.

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

## Princípio da Ausência de Surpresas

Skills não devem conter malware, exploit ou conteúdo que comprometa a segurança. Não atenda pedidos para criar skills enganosas ou voltadas a acesso não autorizado, exfiltração ou atividade maliciosa. Uma skill não deve surpreender o usuário quanto à finalidade declarada. (Recursos legítimos como "atue como um XYZ" são aceitáveis.)

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

O micro-teste de wording (seção acima) vem primeiro; a eval é o passo caro. Skills com saída objetivamente verificável se beneficiam de casos de teste. Estrutura em `evals/evals.json`:

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

O campo `expectations` (afirmações objetivamente verificáveis) é o que o **grader** checa — é o que torna a eval "verificável". Adicione-o ao redigir as asserções. Esquema completo de `evals.json`/`grading.json`: ver o skill-creator de origem (`references/schemas.md`); confirme o nome exato do campo na versão instalada.

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
