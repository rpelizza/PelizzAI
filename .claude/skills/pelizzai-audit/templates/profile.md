# Perfil de execução — <projeto>

> Detectado pela `pelizzai-audit` no bootstrap, lendo os scripts REAIS do projeto
> (package.json `scripts`, Makefile/Justfile, pyproject, …) — nunca chutado. A exceção é
> a seção *Defaults de execução ratificados*, que NÃO é detectada: nasce `<unset>` e só o
> usuário a preenche ao ratificar a política no gate pós-plano.
> Vive em `pelizzai/profile.md`. Consumido por: `pelizzai-tdd` (comando de teste),
> `pelizzai-execution-plans` (gate pós-plano + validação final), `pelizzai-finish-task`
> (verificação e destino), `pelizzai-router` (recomendação dos defaults de execução),
> `pelizzai-debugging` (loop de feedback) e `pelizzai-writing-skills` (Stack baseline
> → eixos version/adoption-driven). Atualize quando os scripts/manifests mudarem; em
> workspace, repita as seções por projeto.

## Harness e skill roots

- Source mode: `<true | false>`
- Canonical skill root: `<.claude/skills | .agents/skills | outro root nativo>`
- Installed mirrors: `<nenhum | lista de roots que devem permanecer byte a byte>`

_Detecte pelos arquivos realmente instalados. Domain skills são gravadas no root canônico e,
quando houver mirrors, sincronizadas e verificadas; nunca assuma `.claude/skills` em toda IDE._

## Defaults de execução ratificados

> Política de PROJETO explicitamente ratificada pelo usuário — NÃO é herança da tarefa anterior.
> O gate pós-plano usa estes valores como recomendações nas perguntas sequenciais. Eles não
> auto-confirmam uma tarefa nova, salvo quando o usuário delegar explicitamente aplicar a política.
> No bootstrap nascem todos `<unset>`.

- isolation-default: <branch|worktree|unset>
- execution-mode-default: <inline|subagents|team|unset>
- commit-strategy-default: <granular|squash-final|unset>
- review-policy-default: <combinado|split|unset>
- Ratificado em: <AAAA-MM-DD> | Overrides desde então: <n>
<!-- destination não é persistível: push/PR/publicação exigem confirmação por tarefa -->

## Comandos

| Ação   | Comando exato        | Diretório           |
| ------ | -------------------- | ------------------- |
| test   | `<ex.: pnpm test>`   | `<raiz \| apps/x>`  |
| build  | `<…>`                | `<…>`               |
| lint   | `<…>`                | `<…>`               |
| format | `<…>`                | `<…>`               |
| dev    | `<…>`                | `<…>`               |

_Só liste o que o projeto realmente tem; ação sem script real = linha removida (não invente)._

## Package manager

- Gerenciador: `<npm | pnpm | yarn | bun | pip | poetry | uv | cargo | …>` — determinado pelo LOCKFILE (`<package-lock.json | pnpm-lock.yaml | …>`).
- Instalação: `<comando exato, ex.: pnpm install>`. Nunca use outro gerenciador — instalar com npm num projeto pnpm corrompe o lock.

## Stack baseline

_Data do snapshot: AAAA-MM-DD (bootstrap ou último refresh)._

| Tecnologia        | Versão (manifest) |
| ----------------- | ----------------- |
| `<ex.: Node>`     | `<20.x>`          |
| `<framework>`     | `<x.y.z>`         |
| `<lib-chave>`     | `<x.y.z>`         |

_Âncora dos eixos version-driven e adoption-driven da `pelizzai-writing-skills`:
version-driven = a versão de um item deste baseline mudou nos manifests (drift de versão);
adoption-driven = há top-level novo nos manifests, ausente deste baseline E do catálogo
`pelizzai/domain-skills.md` → proposta de CRIAR skill da stack nova._

## MCPs disponíveis (opcional)

- `<ex.: context7 — documentação atual de libs/frameworks>`
