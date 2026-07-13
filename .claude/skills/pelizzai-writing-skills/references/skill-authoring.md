# Autoria de skills — referência prática

Use esta referência ao criar ou alterar uma skill. O objetivo é mudar comportamento de forma
observável com o menor contexto necessário. Uma skill não fica melhor por ser mais longa,
incisiva ou ritualizada; fica melhor quando aciona no contexto certo e reduz uma falha real.

## Fluxo proporcional

1. Defina a capacidade, os gatilhos positivos, os *near misses* e a saída esperada.
2. Colete evidência suficiente: pedido do usuário, padrões do repositório, falhas observadas ou
   documentação oficial da ferramenta.
3. Escolha o grau de liberdade apropriado.
4. Escreva a menor orientação que fecha a lacuna.
5. Valide o comportamento no nível de risco adequado.
6. Remova duplicação, sincronize os mirrors aplicáveis e registre limitações reais.

Não repita uma decisão que o usuário já ratificou. Quando intenção, escopo ou formato ainda forem
decisões humanas, faça uma pergunta por vez com a melhor recomendação; não os preencha com defaults.
Não pesquise por reflexo quando o conhecimento necessário está no projeto. Para fatos externos que
podem ter mudado, prefira documentação oficial — ela fundamenta opções, não decide pelo usuário.

## Grau de liberdade

| Situação | Forma adequada |
| --- | --- |
| Múltiplas soluções válidas; julgamento contextual | princípios e critérios de decisão |
| Padrão preferido com variação aceitável | pseudocódigo, checklist curto ou exemplo parametrizado |
| Operação frágil, repetitiva ou com ordem exata | script determinístico e poucos parâmetros |

Não transforme heurística em invariante. Segurança, autoridade e integridade podem exigir regras
rígidas; estilo, decomposição, técnicas de reasoning e quantidade de testes normalmente exigem
seleção contextual.

## Evidência e validação comportamental

Trate a validação como uma escada, não como um ritual único:

| Mudança | Evidência mínima típica |
| --- | --- |
| typo, link ou formatação | parser/link/static check |
| script ou formato determinístico | fixture + resultado esperado + caso de erro |
| regra de segurança ou ciclo de vida | matriz de comandos/cenários permitidos e bloqueados |
| routing/description | positivos, *near misses* e casos ambíguos |
| disciplina sob pressão | cenário fresco antes/depois quando houver risco real de racionalização |
| orientação subjetiva | crítica por critérios e exemplos contrastantes |

Um baseline falho é valioso quando o comportamento ainda é desconhecido, a mudança é de alto
impacto ou o agente costuma racionalizar exceções. Evidência já observada no repositório, em uma
regressão ou no feedback do usuário também pode cumprir esse papel. Não fabrique uma falha nem
obrigue pressure tests versionados para cada edição de texto.

Para mudanças complexas, faça *forward testing*: dê a uma sessão fresca apenas o pedido e a skill
nova, sem revelar o diagnóstico desejado. Observe a rota escolhida e corrija a instrução, não a
resposta do teste. Versione cenários somente quando eles forem úteis como proteção de regressão.

## Frontmatter e acionamento

O `SKILL.md` usa somente:

```yaml
---
name: nome-kebab-case
description: O que a skill faz e os contextos observáveis em que deve ser usada.
---
```

- `name` corresponde ao nome do diretório.
- `description` descreve capacidade e gatilhos, não a sequência do workflow.
- Use termos que o usuário realmente diria, incluindo variações relevantes.
- Inclua *near misses*: palavras em comum não bastam se a intenção é outra.
- Seja preciso. Descrições agressivas causam sobre-acionamento e competem com skills melhores.
- Uma restrição curta pode ficar na descrição quando for essencial para o routing.

Monte um pequeno conjunto de queries positivas e negativas quando o acionamento for importante.
Expanda para uma suíte maior apenas se a fronteira estiver ambígua ou já tiver regredido.

## Divulgação progressiva

1. `name` + `description` ficam sempre disponíveis ao roteador.
2. O corpo de `SKILL.md` é carregado quando a skill é selecionada.
3. `references/`, `scripts/` e `assets/` são lidos ou executados sob demanda.

Mantenha o corpo focado no workflow e nos critérios de decisão. Mova tabelas extensas, detalhes
de fornecedor e exemplos volumosos para referências com links explícitos que digam **quando**
carregá-las. Não crie uma cadeia profunda de referências.

Estrutura típica:

```text
nome-da-skill/
├── SKILL.md
├── scripts/       # operações determinísticas ou repetitivas
├── references/    # conhecimento consultado sob demanda
└── assets/        # templates e recursos usados na saída
```

Nem toda skill precisa desses diretórios. Não crie README, changelog ou arquivos auxiliares sem
função operacional.

## Fonte e roots de skills

No repo-fonte do PelizzAI:

- edite `.claude/skills/<nome>/`;
- trate `.agents/skills/` como mirror gerado;
- depois de uma edição autorizada, rode automaticamente `node scripts/sync-harness.mjs` e valide
  com `node scripts/sync-harness.mjs --check --source-mode`; `.ps1` e `.sh` são wrappers.

Num projeto consumidor, detecte o root ativo antes de escrever. Use `.claude/skills/` **ou**
`.agents/skills/`, conforme a plataforma e as convenções existentes; não duplique a edição nos
dois roots por conta própria. Se o projeto declarar um processo de geração, edite a fonte e rode
esse processo automaticamente como parte da edição já autorizada.

## Como escrever

- Use verbos no imperativo e critérios observáveis.
- Explique o porquê apenas quando ele fecha uma racionalização provável.
- Dê formato exato para saídas que precisam ser consistentes.
- Use exemplos curtos quando reduzirem ambiguidade.
- Prefira uma regra central a repetições espalhadas.
- Nomeie limites e caminhos de fallback.
- Diga quando **não** usar a skill.

Faça o teste de *no-op* por parágrafo: sem ele, o agente faria algo materialmente diferente? Se
não, remova. Sedimento, duplicação e detalhes históricos diluem regras importantes.

## Scripts

Prefira script quando copiar comandos seria frágil ou o resultado puder ser verificado
automaticamente. Um script deve:

- aceitar entradas explícitas e validar parâmetros;
- falhar com mensagem acionável;
- evitar efeitos destrutivos por default;
- funcionar a partir de caminhos documentados;
- ter ao menos uma fixture feliz e um erro representativo quando for crítico.

Teste o script executando-o. Apenas lê-lo não valida quoting, encoding, diferenças de plataforma
ou códigos de saída.

## Evals úteis

Evals são indicados quando existe saída verificável ou uma fronteira de routing importante.
Cada caso deve conter:

- contexto mínimo e entrada;
- comportamento esperado;
- comportamento proibido relevante;
- critério objetivo de aprovação;
- motivo pelo qual o caso protege uma regressão plausível.

Evite transformar a redação exata da resposta em contrato, salvo quando o formato for uma API.
Teste decisões e efeitos observáveis.

## Ausência de surpresas

Uma skill não deve introduzir silenciosamente rede, credenciais, instalação global, escrita fora
do escopo, publicação ou destruição de dados. Declare dependências e efeitos. Use consentimento
quando uma nova autoridade for necessária. Nunca inclua segredos em examples, logs ou fixtures.

## Critério de conclusão

Uma skill está pronta quando:

- seu gatilho distingue usos válidos de *near misses*;
- o corpo contém apenas instruções que mudam comportamento;
- o grau de liberdade combina com a fragilidade da tarefa;
- links, frontmatter e scripts relevantes foram validados;
- o comportamento crítico passou em cenário proporcional;
- fonte, mirrors e documentação não contradizem o novo contrato.

Empacote a pasta somente quando o usuário realmente precisar distribuí-la como artefato fora do
repositório. Dentro do PelizzAI, versionamento e sync são suficientes.
