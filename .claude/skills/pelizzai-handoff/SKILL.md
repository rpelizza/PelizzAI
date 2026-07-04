---
name: pelizzai-handoff
description: Handoff bifurca; compact continua. Use ao passar o trabalho para uma SESSÃO NOVA — ao mudar de rumo ou abrir outra frente com a janela de contexto cheia, ou quando a janela se aproxima da zona segura ANTES de uma fase nova. Acione quando o usuário disser "faz um handoff", "continua em outra sessão", "passa isso para outra conversa". Para continuar o MESMO trabalho na mesma direção, compacte (regra geral de higiene de contexto na `pelizzai-core`) — não use esta skill.
---

# PelizzAI Handoff

## Objetivo

Bifurcar o trabalho para uma sessão nova sem herdar uma janela poluída: um doc de handoff curto, com ponteiros por PATH para os artefatos que já existem, dá à próxima sessão exatamente o que ela precisa — e nada além.

**Anuncie ao iniciar:** "Usando a skill PelizzAI Handoff para preparar a próxima sessão."

> **Princípio:** handoff bifurca; compact continua. A regra geral de higiene de contexto (zona segura ~120k, bordas de fase) mora na `pelizzai-core`. O `pelizzai/data/state.md` continua sendo a fonte de retomada — o handoff NÃO o substitui.

## Quando

- Mudar de rumo ou abrir OUTRA frente com a janela cheia.
- Passar o trabalho para uma sessão nova (outro dia, outro agente, outra frente).
- A janela se aproxima da zona segura ANTES de uma fase nova — bifurque na borda, não no meio.
- Trabalho multi-sessão: uma frente/"ticket" por sessão — cada handoff carrega UMA próxima missão clara.

## Processo

1. **Feche a borda:** nunca faça handoff no meio de uma fase (review ✅ + cursor + commit primeiro).
2. **Grave o doc no diretório temporário do SO** (`$TMPDIR`/`$env:TEMP`), NUNCA no workspace — handoff é efêmero, não artefato do repo.
3. **Conteúdo, nesta ordem:**
   - Objetivo da próxima sessão (aceite-o como argumento do pedido de handoff).
   - Estado atual: o que foi feito e o que foi decidido (fatos, não narrativa).
   - Ponteiros por PATH para specs/planos/ADRs/`pelizzai/data/state.md` — **não duplique** o conteúdo; artefato que tem path é referenciado, nunca colado.
   - Pendências: o que falta, riscos abertos, decisões pendentes de humano.
   - **Skills sugeridas** para a próxima sessão (as do harness e as de domínio aplicáveis).
4. **Redija segredos:** tokens, senhas e URLs internas sensíveis nunca entram no doc — substitua por `<redigido>` + onde obter.
5. Entregue o path do doc ao usuário; a sessão nova começa pelo doc e segue o fluxo normal (`pelizzai-core` → `pelizzai-router`).

## Red flags

```text
- Colar conteúdo de artefatos que já têm path (o handoff vira uma cópia que envelhece).
- Handoff no meio de uma fase — feche a borda primeiro.
- Segredos em texto claro no doc.
- Gravar o doc dentro do workspace/repo (vira lixo versionável).
- Usar handoff para continuar o MESMO trabalho na mesma direção — isso é compact.
```

## Integração

- `pelizzai-core` — dona da regra geral de higiene de contexto (zona segura, "handoff bifurca; compact continua").
- `pelizzai-execution-plans` — bordas de fase: o handoff acontece na borda (review ✅ + cursor + commit), nunca no meio.
- `pelizzai/data/state.md` — o cursor continua sendo a fonte de retomada; o handoff complementa (contexto), não substitui (estado).
