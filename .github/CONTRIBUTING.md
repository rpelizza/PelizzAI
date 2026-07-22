# Como contribuir com o PelizzAI

Obrigado pelo interesse. Este documento explica o que é peculiar neste repositório — porque
contribuir aqui não se parece com contribuir num projeto de software comum.

## O que você está editando

O "produto" deste repositório é **prosa instrucional em markdown**: as skills. Elas são lidas por um
agente de código em tempo de execução e mudam o comportamento dele. Não há aplicação rodando, não há
build.

A consequência prática: **uma regressão aqui é uma instrução ambígua, contraditória ou perdida** —
não um stack trace. O defeito mais comum e mais caro é uma seção que contradiz outra seção do mesmo
arquivo. O revisor lê procurando isso.

## A regra de ouro

**Não edite os arquivos gerados.** Estes caminhos são produzidos por `scripts/sync-harness.mjs` e
qualquer mudança feita neles é perdida no próximo sync:

- `.agents/skills/`
- `AGENTS.md`
- `GEMINI.md`
- `scripts/pelizzai-core-skills.txt` (manifesto)
- `dist/` (inteira — o payload consumidor pronto para copiar)

A fonte do comportamento é `.claude/` (skills e hooks). Também são autorais — e editáveis —
`CLAUDE.md`, `README.md`, `scripts/` e `.github/`. `.cursor/rules/pelizzai.mdc` é adaptador
**manual**: o sync o distribui, mas não o gera, e ele precisa ser atualizado à mão quando os
entrypoints mudarem.

## O fluxo

```bash
# 1. edite .claude/skills/... ou .claude/hooks/...

# 2. regenere os espelhos (sempre, antes de commitar)
node scripts/sync-harness.mjs

# 3. valide a sincronia e os contratos
node scripts/sync-harness.mjs --check
pwsh scripts/test-harness-contracts.ps1     # precisa fechar com 0 FAIL

# 4. commit e PR
```

O passo 2 não é opcional. Um commit que muda a fonte sem regenerar o espelho quebra o job
`sync-check` da CI.

**Requisitos:** Node.js 18+ para o núcleo; PowerShell 7+ para a suíte de contratos e os wrappers
`.ps1`.

## Contratos: comportamento novo exige asserção nova

`scripts/test-harness-contracts.ps1` é o que impede o harness de regredir em silêncio. Cada
comportamento relevante tem uma asserção que o trava.

Se o seu PR muda comportamento, ele precisa mexer nos contratos:

- **comportamento novo** → asserção nova que falharia sem a sua mudança;
- **comportamento removido de propósito** → remova a asserção e explique no corpo do commit por que
  aquilo deixou de valer;
- **comportamento que mudou de arquivo** → reaponte a asserção.

Um antipadrão específico, que será recusado no review: **enfraquecer uma asserção até ela passar**.
Regex que casa quase tudo, ou `Check-NotMatch` que virou no-op, é pior que asserção nenhuma — porque
simula cobertura que não existe. Se uma asserção está no seu caminho, ou o comportamento dela ainda
vale (e a sua mudança está errada), ou ele deixou de valer (e ela deve ser removida com
justificativa). Não existe terceira via.

## Escrevendo uma skill

Cada skill vive em `.claude/skills/<nome>/SKILL.md` e segue estas regras:

- **Frontmatter só no `SKILL.md`.** Precisa de `name` e `description`, e o `name` tem que ser igual
  ao nome do diretório. Arquivos em `references/`, `templates/`, `evals/` e `techniques/` **não**
  levam frontmatter.
- **A `description` é o mecanismo de descoberta.** É por ela que o agente encontra a skill. Escreva
  os gatilhos reais de uso, incluindo as frases coloquiais que uma pessoa usaria ("não funciona",
  "deu erro"). Um resumo elegante e genérico faz a skill nunca ser acionada.
- **Todo ponteiro precisa existir.** `references/...`, `templates/...` e todo nome `pelizzai-*`
  citado em prosa são verificados; ponteiro morto quebra o sync.
- **Referência cruzada se qualifica.** Ao citar um arquivo que vive em outra skill, escreva
  `pelizzai-execution-plans` → `references/task-cycle.md`, nunca `references/task-cycle.md` solto —
  senão quem lê procura no diretório errado.

Há uma skill dedicada a isso: `pelizzai-writing-skills`, com
`references/skill-authoring.md`. Vale ler antes de escrever a primeira.

## Mexendo nos hooks

Os hooks em `.claude/hooks/` são a parte mais sensível do repositório, porque **rodam na máquina de
quem instalou o harness**.

- **Paridade obrigatória.** Cada hook existe em `.mjs` (Node) e `.ps1` (PowerShell). Divergência
  entre as duas pernas é bug, mesmo que cada uma esteja correta isoladamente.
- **Falso positivo é o pior defeito possível.** Um bloqueio indevido trava o trabalho de um
  desconhecido, ensina o agente a contornar a rede de segurança e faz a proteção inteira perder
  valor. As regras do `guardrails` são **deliberadamente estreitas**: elas miram o punhado de
  comandos que apagam trabalho de forma irrecuperável, e não tentam cobrir todo Git perigoso. Ao
  mexer, prefira falso negativo a falso positivo.
- **Teste os dois lados, executando.** A suíte tem fixtures de comandos que devem bloquear e de
  comandos que devem passar. Acrescente às duas listas — um hook que você não executou não está
  verificado.
- **Fail-open em erro interno.** Se o próprio hook quebrar, ele sai com 0. Um bug na rede de
  segurança nunca pode sequestrar a ferramenta de quem usa.

## Idioma e estilo

O repositório é inteiro em **português do Brasil**, com acentuação correta. Isso vale para skills,
comentários de código, mensagens de commit e descrição de PR.

A marca se escreve exatamente **PelizzAI** em prosa — nunca "Pelizzai", "pelizzAI" ou "PELIZZAI".

Escreva instrução, não redação: frase curta, voz ativa, o critério antes do exemplo. A skill
`pelizzai-writing-clearly-and-concisely` é o guia de estilo do projeto.

## Abrindo um PR

- Descreva **o que muda no comportamento do agente**, não só quais arquivos você tocou.
- Diga como verificou. "Rodei a suíte" é o mínimo; se mexeu em hook, cole a saída dos casos testados.
- PRs pequenos e temáticos são revisados mais rápido. Uma mudança de doutrina que atravessa 15 skills
  provavelmente deveria ser uma discussão antes de ser um PR.
- Para mudanças grandes ou que alteram um invariante (autoridade do usuário, isolamento antes da
  primeira escrita, evidência antes de conclusão), **abra uma issue primeiro**. Esses pontos são
  deliberados e mudá-los exige conversa, não só código.

## Um princípio que atravessa tudo

O harness classifica, raciocina, investiga e recomenda; **quem decide o produto é o usuário**. Ao
propor uma mudança, verifique se ela não autoriza o agente a decidir sozinho escopo, UX, arquitetura,
dados, risco aceito ou critério de aceite. Lacuna material encontrada durante o trabalho deve levar
à `pelizzai-interview-me` — nunca a um default silencioso.

Contribuição que fura esse princípio será recusada mesmo que o código esteja impecável.
