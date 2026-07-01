# Manutenção de skills de domínio — mecânica detalhada

Como o PelizzAI mantém as skills de domínio vivas conforme o projeto evolui. Inspirado no harness anterior (validado em campo), com a automação por hook que o projeto autorizou.

## Os dois eixos de atualização

| Eixo               | Disparo                                                              | Ação                                                              |
| ------------------ | ------------------------------------------------------------------- | ---------------------------------------------------------------- |
| **Version-driven** | A stack mudou de versão maior, ou ganhou dependência significativa   | Reler a doc da versão atual (context7) e **atualizar** a skill afetada (refresh) |
| **Rework-driven**  | O mesmo ajuste foi feito à mão várias vezes no histórico do git      | O padrão repetido vira uma **regra** dentro da skill              |

Os dois são **opt-in**: o harness detecta, **propõe**, o usuário decide. Nunca rodam sozinhos.

### Version-driven (refresh)

```text
1. Detecte o drift: compare as versões registradas no ledger/skill com as versões atuais (manifests, lockfiles).
2. Releia a doc da versão atual via context7.
3. Atualize a skill afetada em modo refresh (ver "Refresh nunca sobrescreve às cegas").
4. Registre no ledger (eixo = version-driven, novo commit/ref, data).
```

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
- Aprovação é POR skill. Sem confirmação, não grava.
```

Recriar uma skill do zero por cima de uma existente apaga customizações e é proibido. O fluxo é sempre **propor → confirmar → aplicar → registrar**. Não existe modo "mãos livres" (foi tentado no harness anterior e reprovou em campo).

## Cadência (gatilhos)

Modelo **híbrido**: núcleo portável na skill + hook de reforço no Claude Code.

### Núcleo portável (ao fechar a tarefa)

Vale em `.claude`, `.agents`, `.cursor` — é texto de skill, não depende de hook. Este bloco **é embutido pela `pelizzai-finish-task` (Passo 5 — nudge de revisão de skills)**, que dispara no encerramento de cada tarefa; o hook (no Claude Code) é apenas reforço a cada 10 interações. Ao concluir uma tarefa que mexeu em código:

```bash
# datas do ledger — parsing ANCORADO no rótulo (robusto à ordem das linhas; lê as DUAS datas)
last_review=$(grep -oE 'last-review:[^0-9]*[0-9]{4}-[0-9]{2}-[0-9]{2}' pelizzai/data/review-domain-skills.md | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
last_full_scan=$(grep -oE 'last-full-scan:[^0-9]*[0-9]{4}-[0-9]{2}-[0-9]{2}' pelizzai/data/review-domain-skills.md | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
# commits desde a última revisão
count=$(git rev-list --count --since="$last_review 00:00" HEAD 2>/dev/null || echo 0)
```

> Comandos em sh/Bash; em frota sem POSIX (ex.: só PowerShell), use o equivalente — o hook `.ps1` já implementa a mesma leitura por rótulo.

```text
- Se count >= 10 OU passaram-se > 10 dias desde last_review → proponha UMA vez:
  "Acumulamos <count> commits / <dias> dias desde a última revisão de skills de domínio.
   Posso rodar a manutenção (pelizzai-writing-skills) agora? Seguir agora ou deixar para depois?"
- Abaixo do limiar → não diga nada e finalize.
- "Avisa uma vez, nunca bloqueia." Se o usuário adiar, não repita na mesma sessão.
```

Repo-scan completo: se passaram > 10 dias desde `last-full-scan`, proponha um re-scan amplo (reusando a `pelizzai-audit`) e atualize as skills impactadas.

### Hook de reforço (a cada 10 interações — só Claude Code)

O hook `.claude/hooks/pelizzai-cadence.mjs` é um `UserPromptSubmit` que conta interações e, a cada 10, checa o delta do git; se o limiar for cruzado, injeta um lembrete curto. Características de segurança:

```text
- No-op silencioso se não houver ledger (harness ainda não inicializado neste projeto).
- Só faz a checagem cara (git) a cada 10ª interação; nas demais, só incrementa o contador.
- SEMPRE termina com exit 0 (nunca bloqueia o prompt do usuário).
- Engole qualquer erro (git ausente, etc.) sem ruído.
- Emite no máximo um lembrete por janela de 10 interações.
```

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
- Semeie `last-review` e `last-full-scan` com a data do 1º commit do repo
  (git log --reverse --format=%cd --date=short | head -1). Evita o bug "count=0 para sempre".
- A cada criação/refresh de skill de domínio, atualize a linha da skill no ledger
  (data, último commit/ref, eixo) e o `## Log`.
- Após uma revisão de manutenção, atualize `last-review` para a data da revisão.
```

Formato do ledger e do catálogo: ver `templates/review-domain-skills.md` e `templates/domain-skills.md`.
