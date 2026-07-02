---
name: pelizzai-resolving-merge-conflicts
description: Use quando houver um conflito de merge/rebase do git em andamento para resolver. Entende a intenção de cada lado, resolve cada hunk preservando os dois intuitos quando possível, roda os checks do projeto (typecheck → testes → format) e conclui o merge/rebase. Nunca usa `--abort` por conta própria para fugir do conflito — resolve; se a intenção original não puder ser preservada com segurança, PARA e escala ao usuário (que pode decidir abortar e recomeçar com mais contexto). Acione quando o usuário disser "resolver conflito", "deu merge conflict", "conflito de rebase".
---

# PelizzAI Resolving Merge Conflicts

**Anuncie ao iniciar:** "Usando a skill PelizzAI Resolving Merge Conflicts para resolver os conflitos."

## Processo

```text
1. Veja o estado atual do merge/rebase. Cheque o histórico do git e os arquivos em conflito
   (git status, git diff, git log das duas pontas).

2. Ache a fonte primária de cada conflito. Entenda FUNDO por que cada mudança foi feita e qual era a
   intenção original — leia as mensagens de commit, os PRs, as issues/tickets de origem.

3. Resolva cada hunk. Preserve OS DOIS intuitos quando possível. Onde forem incompatíveis, escolha o que
   bate com o objetivo declarado do merge e anote o trade-off. NÃO invente comportamento novo.
   Sempre tente resolver. Se a intenção original NÃO puder ser preservada com segurança (lados
   fundamentalmente incompatíveis, contexto insuficiente), NÃO invente e NÃO force: PARE e escale
   ao usuário com as opções — incluindo abortar (`--abort`) e recomeçar com mais contexto.
   O abort é decisão do usuário, nunca sua saída autônoma para fugir do conflito.

4. Descubra os checks automatizados do projeto e rode-os — tipicamente typecheck → testes → format.
   Conserte o que o merge quebrou (use pelizzai-verification-before-completion: evidência fresca).

5. Conclua o merge/rebase. Faça stage de tudo e commite. Se for rebase, continue até todos os commits
   serem rebaseados.
```

## Red flags

```text
Nunca: dar `git merge --abort`/`git rebase --abort` por conta própria para fugir do conflito (abortar é
       decisão do usuário, após você escalar com as opções); inventar comportamento que não estava em
       nenhum dos lados; resolver sem entender a intenção original; concluir sem rodar os checks.
```

## Integração

**Combina com:** `pelizzai-starting-branch` (a base de onde o conflito surge), `pelizzai-finish-task` (integração/PR onde o conflito aparece), `pelizzai-verification-before-completion` (rodar os checks após resolver), `pelizzai-reasoning` (Evidence Synthesis para conciliar intenções conflitantes).
