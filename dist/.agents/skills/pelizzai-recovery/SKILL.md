---
name: pelizzai-recovery
description: Reconcilia com segurança divergências entre o registro da tarefa e Git após interrupção, crash, worktree órfão ou retomada no diretório errado. Usa state no consumidor e execution record no source mode. Começa read-only, distingue falso alarme de risco real e preserva WIP antes de qualquer operação que possa movê-lo ou descartá-lo. Nunca faz stash/reset/delete/abort automaticamente.
---

# PelizzAI Recovery

## Objetivo

Reconstruir a realidade sem perder trabalho nem transformar toda divergência em um menu Git.

**Anuncie:** "Usando a skill PelizzAI Recovery para reconciliar o registro com o Git sem perder WIP."

## 1. Diagnóstico read-only

Não escreva nem mova WIP até classificar a divergência:

```bash
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git worktree list --porcelain
git log --oneline -10
git stash list
```

Leia `project`, `branch`, `base-ref`, `base-sha`, `validated-head`, `confirmar`, `isolation`,
`worktree-path`, `phase`, o progresso e `next` do `state.md` consumidor ou execution record nativo.
State ausente em source mode é normal. Separe:

| Classe | Exemplo | Conduta |
| --- | --- | --- |
| diretório errado | registro aponta worktree válido, mas comando rodou no repo principal | mude para o path correto; zero escrita |
| cursor atrasado | Git/commits são coerentes e registro perdeu progresso | reconciliar apenas o registro, com evidência |
| WIP recuperável | working tree suja na branch correta | preservar e retomar; não stash por reflexo |
| identidade divergente | branch/path/base não correspondem e origem do WIP é incerta | decisão humana após inventário |
| risco de perda/histórico reescrito | commits sumiram, refs mudaram, worktree órfão sujo | preserve refs/WIP e escale |

Se for falso alarme de diretório, corrija o contexto e retorne ao router sem tocar o registro.

**Entrega em `delivered` na retomada.** Se o state trouxer `phase: delivered`, a tarefa foi selada e
seu destino executado, faltando só constatar `done` — isto **não** é divergência de WIP. Aplique a
mesma reconciliação da `pelizzai-execution-plans` (§Reconciliação da entrega anterior): verifique
`confirmar:` contra o git (read-only) — `base-ref` contém `validated-head`? PR mergeado? branch
integrada? (entrega local: o usuário aceita?). Constatada → carimbe a linha de índice do
`## Histórico` com `done <AAAA-MM-DD>` + evidência de 1 linha e grave `phase: done` — o bloco íntegro
já migrou para `pelizzai/data/history/<AAAA-MM-DD>-<slug>.md` no selo `delivered`, então aqui não há
bloco a mover; a escrita de metadata em `pelizzai/` vale em qualquer branch, mas o commit espera a task
branch nova (nunca em protegida). Falhou (PR fechado sem merge) → não grave `done`; informe e proponha
retomar a branch ou arquivar como `abandoned`. Nenhum arquivo de trabalho é movido nesta constatação.
Source mode: a mesma constatação vale no execution record nativo, sem criar `pelizzai/` nem
`history/`.

## 2. Inventariar o WIP

Antes de propor qualquer mutação, mostre:

```text
tracked staged/unstaged
untracked (nomes, sem ler segredos)
commits exclusivos da branch
stashes relevantes
worktrees/refs que ainda apontam para o conteúdo
```

Não trate arquivos desconhecidos como pertencentes à tarefa. Descubra origem/escopo antes de
incluí-los em commit ou stash.

## 3. Escolher a menor recuperação

Use default seguro quando inequívoco:

- cursor comprovadamente atrasado e sem conflito de identidade → atualize apenas os campos
  evidenciados;
- registro ativo aponta para worktree válido → execute de lá;
- WIP coerente **fora** de retomada mid-plan (ajuste/bug avulso na branch certa) → retome no lugar.

**Retomada mid-plan com WIP sempre abre o gate de recuperação.** Reabrir um plano no meio com working
tree suja é decisão estrutural: não retome in-place em silêncio só porque o WIP parece coerente.
Apresente o ponto de retorno e as opções, com a recomendada pré-selecionada:

```text
Gate de recuperação — plano "<nome>" retomado no meio (responda "ok" ou escolha outra opção):
Ponto de retorno: <ref/branch de resgate proposta | "dispensável: retomar in-place não move o WIP">
1. [recomendado] Retomar in-place — segue de onde parou; não move o WIP.
2. Voltar ao último estado selado (validated-head <sha>) — descarta/revisa o WIP com confirmação.
3. Revisar o diff antes de decidir — inventário completo do WIP (§2) e então reescolha.
4. Descartar o WIP — destrutivo; exige confirmação explícita e ponto de retorno antes (§4).
```

Fora da retomada mid-plan, pergunte somente quando há caminhos materialmente diferentes; não mostre
opções inaplicáveis. Descarte, stash, abort, reset, deleção ou remoção de worktree nunca são
escolhidos autonomamente.

Sob briefing fechado (SUBAGENT-STOP), não produza análises de rota nem abra gates: aplique o briefing e escale ao coordenador o que exigir decisão.

## 4. Ponto de retorno antes de risco

Se a rota selecionada mover, esconder, reescrever ou descartar WIP:

1. obtenha confirmação explícita da operação e do escopo;
2. prefira uma branch/ref de resgate quando os commits já existem;
3. para working tree arbitrária, use stash **nomeado** somente após listar staged/unstaged/untracked
   e confirmar que não capturará arquivos alheios/sensíveis;
4. registre nome/SHA e comando de restauração antes de continuar.

Nunca use `reset --hard`, branch `-D`, worktree `--force` ou `git clean -f`. Se o usuário realmente
quiser uma operação bloqueada pelos guardrails, entregue diagnóstico e instrução manual; não burle
o hook.

## 5. Reconciliar o registro

Atualize somente campos comprovados. Antes do commit:

- esteja numa branch segura e não protegida; se necessário, use `pelizzai-starting-branch` sem
  perder a ref de resgate;
- consumidor: estagie apenas `pelizzai/data/state.md` quando a recuperação é só cursor;
- source mode: atualize apenas o execution record nativo; não crie state nem commit de cursor;
- se WIP legítimo também será consolidado, devolva ao lifecycle normal para review/prova/commit;
  não misture conteúdo não revisado num “commit de recovery”.

No consumidor, adicione ao Histórico divergência, evidência e recuperação. Em source mode, registre
o mesmo resumo no mecanismo nativo. Valide novamente contra Git. Se não puder persistir com
segurança, preserve o ponto de retorno e escale; não invente commit em branch protegida.

## 6. Retomar

Retorne ao router com:

```text
realidade confirmada
ponto de retorno (se houve)
registro reconciliado ou razão para não alterá-lo
próximo passo exato
limitações/decisão pendente
```

Se a tarefa estava selada e qualquer conteúdo mudou, invalide `validated-head` e volte a review +
Verification. Recovery nunca chama finish-task com um seal antigo.

## Red flags

```text
- Stash automático apenas porque a working tree está suja.
- Menu completo para simples execução no diretório errado.
- Misturar arquivo alheio no checkpoint/commit.
- Reconciliar state/execution record por memória sem Git.
- Operação destrutiva sem confirmação e ponto de retorno.
- Preservar validated-head depois que o conteúdo mudou.
```

## Integração

É chamada por router/starting-branch/execution-plans quando o registro e Git divergem. Usa
`pelizzai-starting-branch` para resgate seguro e devolve o trabalho ao lifecycle; finish-task só
entra depois de novo conteúdo consolidado e selado.
