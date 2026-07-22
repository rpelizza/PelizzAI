# Política de segurança

## Onde está a superfície de risco

O PelizzAI é majoritariamente markdown, mas **não é só markdown**. Três coisas neste repositório
executam na sua máquina, e é nelas que mora o risco real:

| O quê | Quando roda | O que faz |
| --- | --- | --- |
| `.claude/hooks/*.mjs` e `*.ps1` | a cada prompt ou antes de uma ferramenta, **se você instalar** | leem o comando/caminho pretendido e podem bloqueá-lo |
| `scripts/sync-harness.mjs` e wrappers | quando você roda o sync ou exporta para um projeto | escrevem arquivos no repositório de destino |
| `scripts/install-hooks.mjs` | quando você registra os hooks | edita o seu `.claude/settings.json` |

Os hooks são **opt-in**: são copiados na instalação, mas só passam a rodar depois de registrados —
seja com `--install-hooks`, seja respondendo "sim" à proposta da `pelizzai-audit`. Você pode ver o
que está registrado com `node scripts/install-hooks.mjs --check` e desfazer com `--remove`.

As skills em si não executam nada por conta própria: são texto que orienta um agente. Mas orientam um
agente que **tem** acesso ao seu shell e aos seus arquivos — então uma instrução maliciosa numa skill
é um vetor legítimo, e a tratamos como tal.

## Como reportar uma vulnerabilidade

Mande um e-mail para **rafael.pelizza@gmail.com**, de preferência com `[PelizzAI][security]` no
assunto para não se perder na caixa de entrada.

**Não abra issue pública** para algo explorável — uma issue com passos de reprodução é um exploit
publicado. Issue pública é o canal certo para bug comum, inclusive falso positivo de hook (veja
abaixo).

Ao reportar, inclua: versão/commit do harness, plataforma e versão do agente, os passos exatos de
reprodução, e o impacto que você conseguiu demonstrar. Prova de conceito mínima ajuda mais que
descrição longa.

Este é um projeto mantido por uma pessoa, sem SLA contratual. O compromisso é confirmar o
recebimento e responder com uma avaliação inicial assim que possível; correção de algo explorável
tem prioridade sobre qualquer outro trabalho em andamento.

## O que conta como vulnerabilidade aqui

**Conta:**

- instrução numa skill que leve o agente a exfiltrar segredo, executar comando destrutivo ou
  contornar a confirmação do usuário;
- bypass do `pelizzai-writegate` que permita escrever em branch protegida ou sem o kickoff
  ratificado;
- injeção de comando ou path traversal nos scripts de sync/export — especialmente algo que escreva
  **fora** do diretório de destino;
- `--export-consumer` levando a sentinela `scripts/pelizzai-source-repo.txt` para o destino (isso
  promove o consumidor a repo-fonte e desliga proteções);
- qualquer caminho em que um repositório ou prompt hostil consiga fazer o harness agir contra o
  usuário.

**Não conta** (mas mande mesmo assim, como issue normal):

- **Falso positivo do `guardrails`** — um comando legítimo sendo bloqueado. É bug de usabilidade,
  e levamos a sério, mas não é vulnerabilidade.
- **Falso negativo do `guardrails`** dentro do escopo declarado. As regras são deliberadamente
  estreitas: o hook mira o punhado de comandos que apagam trabalho de forma irrecuperável e **não**
  tenta cobrir todo Git perigoso. `git push --delete`, `git restore <arquivo>` e afins passam de
  propósito, e isso está documentado no cabeçalho do hook. Regra larga trava trabalho legítimo e
  ensina o agente a contornar a rede — o que piora a segurança real.
- **Fail-open em erro interno de hook.** Se o próprio hook quebra, ele sai com 0 e deixa a ação
  seguir. É decisão de projeto: o hook é rede de segurança de segundo nível, não gate primário, e um
  bug nele nunca pode sequestrar a ferramenta de quem usa. Os gates primários vivem nas skills, com
  o usuário.

## O modelo de confiança, dito na cara

Os hooks **reduzem** a chance de um agente fazer estrago; eles não a eliminam, e não foram desenhados
para conter um agente adversário. Um agente com acesso a shell tem muitos caminhos para contornar um
matcher de string, e o `guardrails` nunca pretendeu ser sandbox.

O que o harness realmente oferece é: gates explícitos onde a decisão é do usuário, isolamento antes
da primeira escrita, e evidência antes de qualquer alegação de conclusão. Se você precisa de garantia
forte contra ação hostil, isso vem da sandbox e das permissões do seu agente e do seu sistema — não
daqui.
