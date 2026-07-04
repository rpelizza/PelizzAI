# Perfil de execução — <projeto>

> Detectado pela `pelizzai-audit` no bootstrap, lendo os scripts REAIS do projeto
> (package.json `scripts`, Makefile/Justfile, pyproject, …) — nunca chutado.
> Vive em `pelizzai/profile.md`. Consumido por: `pelizzai-tdd` (comando de teste),
> `pelizzai-execution-plans` (validação final), `pelizzai-finish-task` (verificação),
> `pelizzai-debugging` (loop de feedback) e `pelizzai-writing-skills` (stack baseline
> → eixo version-driven). Atualize quando os scripts/manifests mudarem; em workspace,
> repita as seções por projeto.

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

_Âncora do eixo version-driven da `pelizzai-writing-skills`: drift = manifests atuais ≠ baseline._

## MCPs disponíveis (opcional)

- `<ex.: context7 — documentação atual de libs/frameworks>`
