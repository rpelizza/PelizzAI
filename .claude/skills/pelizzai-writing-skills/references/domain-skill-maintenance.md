# Manutenção de skills de domínio — mecânica detalhada

Como o PelizzAI mantém as skills de domínio vivas conforme o projeto evolui, com hook opt-in
somente quando o projeto o autorizou. Este documento descreve a manutenção **proativa**: a detecção
e a proposta. Uma edição pedida explicitamente pelo usuário dispensa a proposta de cadência, mas
**não** dispensa a trava anti-sobrescrita — ler a skill atual, mudar só o necessário e mostrar o
diff antes de gravar vale nos dois casos.

## Os três eixos de manutenção

Dois eixos **atualizam** skills que já existem; um eixo **cria** a primeira skill de uma stack recém-adotada.

| Eixo                | Disparo                                                              | Ação                                                              |
| ------------------- | ------------------------------------------------------------------- | ---------------------------------------------------------------- |
| **Version-driven**  | A versão maior de um item do Stack baseline mudou nos manifests      | Reler a doc da versão atual (`context7`) e **atualizar** a skill existente (refresh) |
| **Rework-driven**   | O mesmo ajuste foi feito à mão várias vezes no histórico do git      | O padrão repetido vira uma **regra** dentro da skill existente    |
| **Adoption-driven** | A tarefa adotou dependência/serviço significativo AINDA NÃO coberto por skill do catálogo (top-level novo nos manifests/lockfiles, ausente do Stack baseline de `pelizzai/profile.md` E do catálogo) | **PROPOR CRIAR** a primeira skill dessa stack, fundamentada em context7 ou documentação oficial atual da versão travada — não apenas atualizar |

Os três são **opt-in**: o harness detecta, **propõe**, o usuário decide. Nunca rodam sozinhos.

### Version-driven (refresh)

```text
1. Detecte o drift: compare as versões atuais (manifests, lockfiles) com as registradas no ledger/skill e com o **Stack baseline** de `pelizzai/profile.md` (gravado no bootstrap pela `pelizzai-audit`).
2. Releia a doc da versão atual via `context7` (sem ele, documentação oficial atual — nunca memória).
3. Atualize a skill afetada em modo refresh (ver "Refresh nunca sobrescreve às cegas").
4. Registre no ledger (eixo = version-driven, novo commit/ref, data).
```

### Adoption-driven (criar do manifest)

Version-driven e rework-driven só **atualizam** o que já existe. Adoption-driven é o único eixo que **cria** fora do bootstrap: ele acompanha a evolução real da stack entre um repo-scan e outro, criando a primeira skill de uma tecnologia que entrou depois. Só dispara quando uma stack nova, significativa e não coberta entra no projeto.

```text
1. Detecte a adoção: o diff dos manifests/lockfiles desde `last-review` mostra um top-level novo,
   ausente do **Stack baseline** de `pelizzai/profile.md` E do catálogo `pelizzai/domain-skills.md`.
2. Filtre por alavancagem: só proponha para tecnologia externa significativa (framework, ORM/dados,
   auth, pagamentos, fila/infra sensível). Utilitário trivial não vira skill — o filtro aqui é
   alavancagem real, não escassez.
3. No FECHAMENTO da tarefa (nudge read-only da `pelizzai-finish-task`), apresente UMA proposta
   agrupada — nunca um gate por tarefa: "A tarefa adotou <lib@versão do lockfile>, sem domain skill
   cobrindo. Criar uma agora, fundamentada em context7 ou documentação oficial atual?
   [criar · adiar · não criar]". Recomendado: "criar" para libs de alta alavancagem; "adiar" para utilitário.
4. Só após "sim": crie UMA skill (mini bootstrap-write de uma skill) reutilizando o motor de autoria,
   fundamentada em context7 ou documentação oficial atual da versão travada — sem doc atual disponível,
   adie (nunca invente de memória). Catalogue e registre no ledger com eixo = adoption-driven.
```

As lacunas de cobertura sinalizadas durante o consumo (execução inline/subagents/time que toca uma stack sem skill cobrindo) alimentam este eixo: são coletadas e viram UMA proposta agrupada no fechamento, jamais uma criação no meio da tarefa. A detecção do drift/adoção é automática (a inteligência permanece); a escrita da skill exige "sim" e nunca sobrescreve às cegas — o mesmo `propor → confirmar → aplicar → registrar` dos outros eixos.

### Rework-driven (aprender com o histórico)

O histórico do git é evidência do que o harness fez bem e do que exigiu retrabalho manual.

```text
1. Delimite a janela: do `last-review` do ledger até HEAD (git log --since="<last-review>").
2. Procure padrões: o mesmo tipo de correção feito à mão repetidas vezes; convenções que o time
   aplicou consistentemente; erros que se repetem.
3. Para cada padrão recorrente, proponha transformá-lo em regra dentro da skill de domínio relevante.
4. Confirme com o usuário, aplique (refresh) e registre no ledger.
```

## Refresh nunca sobrescreve às cegas

Regra inegociável ao atualizar uma skill **existente**:

```text
- LEIA a skill atual antes de qualquer mudança.
- Mude SÓ o que a nova versão/padrão exige.
- PRESERVE as customizações que o projeto adicionou (não recrie do zero por cima).
- MOSTRE o diff ao usuário ANTES de gravar.
- Aprovação é POR skill — nunca em lote, nunca herdada do "sim" dado a outra skill.
  Sem confirmação, não grava.
```

Recriar uma skill do zero por cima de uma existente apaga customizações e é proibido. O fluxo é
sempre **propor → confirmar → aplicar → registrar**. Não existe modo "mãos livres" (foi tentado no
harness anterior e reprovou em campo). Numa edição que o usuário já pediu, a proposta É o diff:
mostre-o antes de gravar, no escopo pedido, sem reabrir a autorização que ele acabou de dar.

## Cadência (gatilhos)

Modelo **híbrido**: núcleo portável na skill + hook de reforço no Claude Code.

### Núcleo portável (ao fechar a tarefa)

Vale nos roots de skill ativos (`.claude`/`.agents`); Cursor é apenas adaptador. Este bloco é o
**disparo primário** da cadência: a `pelizzai-finish-task` o consome no nudge read-only do
fechamento (§5), um marco natural que não interrompe o fluxo nem bloqueia a entrega. O hook
(Claude Code) é apenas rede de segurança, a cada 10 interações. Ao concluir uma tarefa que mexeu
em código:

```bash
# datas do ledger — parsing ANCORADO no rótulo (robusto à ordem das linhas; lê as DUAS datas)
last_review=$(grep -oE 'last-review:[^0-9]*[0-9]{4}-[0-9]{2}-[0-9]{2}' pelizzai/data/review-domain-skills.md | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
last_full_scan=$(grep -oE 'last-full-scan:[^0-9]*[0-9]{4}-[0-9]{2}-[0-9]{2}' pelizzai/data/review-domain-skills.md | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
# commits desde a última revisão
count=$(git rev-list --count --since="$last_review 00:00" HEAD 2>/dev/null || echo 0)
```

> Comandos em sh/Bash; em frota sem POSIX (ex.: só PowerShell), use o equivalente — o hook `.ps1` já implementa a mesma leitura por rótulo.

```text
- Limiar de revisão: count >= 10 commits OU passaram-se > 10 dias desde last_review.
  O eixo de DIAS é a âncora (cadência curta e previsível); os commits só ANTECIPAM
  o nudge quando há um burst real de trabalho. Cadência deliberadamente curta: o feedback
  de campo mostrou que limiares longos deixavam as skills de domínio envelhecerem sem aviso —
  melhor lembrar cedo (advisory, uma vez, com snooze) do que tarde demais.
- Cruzou o limiar → proponha UMA vez:
  "Acumulamos <count> commits / <dias> dias desde a última revisão de skills de domínio.
   Posso rodar a manutenção (pelizzai-writing-skills) agora? Seguir agora ou deixar para depois?"
- Abaixo do limiar → não diga nada e finalize.
- "Avisa uma vez, nunca bloqueia." Se o usuário adiar, não repita na mesma sessão nem
  nos próximos ~7 dias (o hook persiste essa janela de supressão; ver abaixo).
```

Repo-scan completo: se passaram > 15 dias desde `last-full-scan`, proponha um re-scan amplo (reusando a `pelizzai-audit`) e atualize as skills impactadas.

### Hook de reforço (a cada 10 interações — só Claude Code)

O hook `.claude/hooks/pelizzai-cadence.mjs` é um `UserPromptSubmit` que conta interações e, a cada 10, checa o delta do git; se o limiar for cruzado, injeta um lembrete curto. Os limiares são os mesmos do núcleo portável (10 commits / 10 dias de revisão / 15 dias de full-scan). Características de segurança:

```text
- No-op silencioso se não houver ledger (harness ainda não inicializado neste projeto).
- Só faz a checagem cara (git) a cada 10ª interação; nas demais, só incrementa o contador.
- SEMPRE termina com exit 0 (nunca bloqueia o prompt do usuário).
- Engole qualquer erro (git ausente, etc.) sem ruído.
- Supressão: após emitir um lembrete, silencia por 7 dias (grava `snoozeUntil` no
  .cadence-state.json) — não repete a cada janela enquanto o limiar continua cruzado.
- O estado é retrocompatível: um `.cadence-state.json` antigo (só `{count}`) continua válido.
```

> **Amostragem ≠ frequência do nudge.** `EVERY=10` decide de quanto em quanto o hook OLHA; quem decide se o nudge APARECE são os limiares (10 commits / 10 dias) + a supressão de 7 dias. Não suba `EVERY` a valores altos (ex.: 100): isso cega o hook em sessões curtas, sem reduzir a frequência real do aviso (que já é governada pelos limiares e pelo snooze).

Entrada no `settings.json` (instalada no bootstrap, com confirmação — opt-in):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "node \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-cadence.mjs\"" }
        ]
      }
    ]
  }
}
```

**Quem instala (opt-in):** no bootstrap, a `pelizzai-writing-skills` **propõe** a instalação; se o usuário aceitar, ela **mescla** a entrada em `.claude/settings.json` preservando hooks e permissões já existentes (fazer merge, **nunca** sobrescrever o arquivo). No Claude Code, a skill `update-config` pode realizar essa edição. Acrescente também `pelizzai/data/.cadence-state.json` ao `.gitignore` — é estado mutável (muda a cada interação) e não deve ser versionado.

**Variante sem Node:** em frota sem Node, use o hook PowerShell `.claude/hooks/pelizzai-cadence.ps1` (requer pwsh 7+), com o command `pwsh -NoProfile -File "${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-cadence.ps1"`.

**Pressuposto:** o hook localiza o ledger pelo `cwd` e assume `pelizzai/` na raiz do projeto (convenção do harness; em monorepo/workspace, o `pelizzai/` é root-level).

> Por que opt-in, e não ligado por padrão: um hook `UserPromptSubmit` ruidoso já "quebrou o fluxo" em harness anterior. O **núcleo portável** (na skill) é a fonte de verdade; o hook é só reforço no Claude Code.

## Seeding e atualização do ledger

```text
- Semeie `last-review` e `last-full-scan` com a DATA DO BOOTSTRAP (hoje) — NÃO com a do 1º commit.
  O bootstrap acabou de criar as skills de domínio a partir do repo-scan do HEAD atual: elas são
  a "primeira revisão", então a última revisão é agora. Semear com o 1º commit de um repo maduro
  faz `daysReview`/`commits` já nascerem estourados → um nudge espúrio na primeira tarefa, sobre
  skills recém-criadas. `count=0` no dia do bootstrap é o correto (sobe conforme novos commits).
  (Em repo novo sem commits, a data de hoje já era o valor usado — agora vale para os dois casos.)
- A cada criação/refresh de skill de domínio, atualize a linha da skill no ledger
  (data, último commit/ref, eixo) e o `## Log`.
- Após uma revisão de manutenção, atualize `last-review` para a data da revisão.
```

Formato do ledger e do catálogo: ver `templates/review-domain-skills.md` e `templates/domain-skills.md`.
