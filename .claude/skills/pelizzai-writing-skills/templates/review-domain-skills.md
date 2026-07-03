# PelizzAI — Ledger de manutenção de skills de domínio

> Marca o ritmo da revisão das skills de domínio para não depender de memória humana.
> Lido por `pelizzai-writing-skills` (cadência) e pela `pelizzai-audit` (bootstrap).
> - Semeado por: `pelizzai-writing-skills` no bootstrap (orquestrado pela `pelizzai-audit`), com a **data do bootstrap** (o bootstrap é a 1ª revisão; semear com o 1º commit dispararia um nudge espúrio na primeira tarefa).
> - Atualizado por: `pelizzai-writing-skills` a cada criação/refresh de skill de domínio e após cada revisão.
> Mantenha a data AAAA-MM-DD na MESMA linha de cada rótulo — a checagem de cadência (skill e
> hooks) faz parsing ancorado nos rótulos `last-review:`/`last-full-scan:` e lê a primeira data
> após cada um; nunca deixe um rótulo com placeholder sem dígitos acima de outra data válida.

- **last-review:** <AAAA-MM-DD>
- **last-full-scan:** <AAAA-MM-DD>

## Skills de domínio

| Skill | Criada em | Última atualização | Último commit/ref revisado | Eixo da última mudança | Origem |
| ----- | --------- | ------------------ | -------------------------- | ---------------------- | ------ |
| <nome> | <AAAA-MM-DD> | <AAAA-MM-DD> | <sha curto> | bootstrap / version-driven / rework-driven | repo-scan / interview |

## Log

- <AAAA-MM-DD> — ledger inicializado pela `pelizzai-writing-skills` no bootstrap (orquestração: `pelizzai-audit`; baseline = data do bootstrap, pois as skills nascem do repo-scan do HEAD atual)
