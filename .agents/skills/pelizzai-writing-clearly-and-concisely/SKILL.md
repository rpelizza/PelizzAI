---
name: pelizzai-writing-clearly-and-concisely
description: Uma skill que aplica os princípios de escrita atemporais de William Strunk Jr. para produzir uma prosa mais clara, vigorosa e profissional, evitando, ao mesmo tempo, os padrões comuns de escrita de IA.
---

# Escrevendo de Forma Clara e Concisa

## Visão Geral

Escreva com clareza e força. Esta skill abrange o que fazer (Strunk) e o que não fazer (padrões de IA).

## Quando Usar Esta Skill

Use esta skill sempre que escrever textos para humanos:

- Documentação, arquivos README, explicações técnicas
- Mensagens de commit, descrições de pull requests
- Mensagens de erro, textos de interface (UI), textos de ajuda, comentários
- Relatórios, resumos ou qualquer tipo de explicação
- Edição para melhorar a clareza

**Se você está escrevendo frases para serem lidas por um humano, use esta skill.**

## Estratégia para Contexto Limitado

Quando o contexto for restrito:

1. Escreva seu rascunho usando seu próprio julgamento
2. Acione um subagente com seu rascunho e o arquivo da seção relevante
3. Peça ao subagente para revisar o texto e devolver a versão corrigida

Carregar uma única seção (de ~1.350 a ~11.800 tokens, conforme a seção; o arquivo `03` é o maior) em vez de tudo economiza uma quantidade significativa de contexto.

## Elementos de Estilo

A obra _The Elements of Style_ (1918), de William Strunk Jr., ensina a escrever com clareza e a cortar o supérfluo sem piedade.

### Regras

**Regras Elementares de Uso (Gramática/Pontuação)**:

1. Forme o possessivo com a preposição _de_ (a regra original do _'s_ é específica do inglês e não se aplica ao português)
2. Em enumerações, separe os termos por vírgula, mas **não** use vírgula antes do _e/ou_ final (a vírgula serial do inglês é incorreta em pt-BR)
3. Isole expressões explicativas ou incidentais entre vírgulas
4. Use vírgula antes da conjunção que introduz uma oração coordenada
5. Não una orações independentes apenas com vírgula
6. Não divida frases em duas partes separadas
7. Uma oração reduzida (gerúndio/particípio) no início deve referir-se ao sujeito gramatical

**Princípios Elementares de Composição**:

8. Um parágrafo por tópico
9. Comece o parágrafo com a frase que apresenta o tópico principal
10. **Use a voz ativa**
11. **Expresse afirmações na forma positiva**
12. **Use linguagem definida, específica e concreta**
13. **Omita palavras desnecessárias**
14. Evite uma sequência de frases soltas (sem conexão clara)
15. Expresse ideias coordenadas de forma semelhante
16. **Mantenha palavras relacionadas próximas umas das outras**
17. Mantenha o mesmo tempo verbal em resumos
18. **Coloque palavras enfáticas no final da frase**

### Arquivos de Referência

As regras acima são um resumo do texto original de Strunk. Para explicações completas com exemplos:

| Seção | Arquivo | ~Tokens |
| --- | --- | --- |
| Gramática, pontuação, uso da vírgula | `02-elementary-rules-of-usage.md` | ~3.900 |
| Parágrafos, voz ativa, concisão | `03-elementary-principles-of-composition.md` | ~11.800 |
| Títulos, citações, formatação | `04-a-few-matters-of-form.md` | ~1.350 |
| Escolha de palavras (vícios e parônimos do pt-BR) | `05-words-and-expressions-commonly-misused.md` | ~1.800 |

**A maioria das tarefas exige apenas o arquivo `03-elementary-principles-of-composition.md`** — ele aborda voz ativa, forma afirmativa, linguagem concreta e a eliminação de palavras desnecessárias.

## Padrões de Escrita de IA a Evitar

LLMs tendem a convergir para médias estatísticas, produzindo uma prosa genérica e inflada. Evite:

- **Termos inflados:** fundamental, crucial, vital, testemunho, legado duradouro
- **Frases vazias com gerúndio (-ing):** garantindo confiabilidade, demonstrando recursos, destacando capacidades
- **Adjetivos promocionais:** revolucionário, fluido/integrado, robusto, de ponta
- **Vocabulário de IA em excesso:** aprofundar-se (_delve_), alavancar (_leverage_), multifacetado, fomentar, esfera/âmbito (_realm_), tapeçaria (_tapestry_)
- **Excesso de formatação:** listas com marcadores em excesso, decoração com emojis, negrito mecânico em termos-chave repetidos

Seja específico, não grandioso. Diga o que realmente faz.

Para uma pesquisa detalhada sobre por que esses padrões ocorrem, consulte `signs-of-ai-writing.md`. Editores da Wikipédia desenvolveram esse guia para detectar envios gerados por IA — seus padrões são bem documentados e testados na prática.

## Resumo

Escrevendo para humanos? Carregue a seção relevante de `elements-of-style/` e aplique as regras. Para a maioria das tarefas, o arquivo `03-elementary-principles-of-composition.md` cobre os aspectos mais importantes.
