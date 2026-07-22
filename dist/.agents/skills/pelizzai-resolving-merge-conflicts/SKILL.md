---
name: pelizzai-resolving-merge-conflicts
description: Use quando houver um conflito de merge/rebase do git em andamento para resolver — o objetivo é preservar a intenção dos DOIS lados. Nunca usa `--abort` por conta própria para fugir do conflito; se a intenção original não puder ser preservada com segurança, PARA e escala ao usuário. Acione quando o usuário disser "resolver conflito", "deu merge conflict", "conflito de rebase".
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

4. Reaplique skills de domínio e overlays da mudança (frontend/security/docs quando a resolução
   tocar essas superfícies). Rode a prova adequada ao artefato: teste focal/completo, typecheck,
   parser, dry-run, render ou QA visual. Não execute formatter/checks irrelevantes por ritual.

5. Estagie somente os paths resolvidos, confira `git diff --cached` e confirme que
   `git diff --name-only --diff-filter=U` está vazio. Continue o merge/rebase pelo comando indicado
   em `git status`; a cada novo conflito, volte ao passo 1. Nunca use `git add -A`.

6. Ao concluir, rode Verification contra o estado integrado. Se este conflito pertence a uma
   tarefa ativa, devolva o controle ao lifecycle; não crie um fechamento paralelo.
```

## Red flags

```text
Nunca: dar `git merge --abort`/`git rebase --abort` por conta própria para fugir do conflito (abortar é
       decisão do usuário, após você escalar com as opções); inventar comportamento que não estava em
       nenhum dos lados; resolver sem entender a intenção original; `git add -A`; concluir sem
       prova proporcional ou sem conferir conflitos não resolvidos.
```

## Integração

**Combina com:** `pelizzai-starting-branch` (a base de onde o conflito surge), `pelizzai-finish-task` (integração/PR onde o conflito aparece), `pelizzai-verification-before-completion` (rodar os checks após resolver), `pelizzai-reasoning` (Evidence Synthesis para conciliar intenções conflitantes).
