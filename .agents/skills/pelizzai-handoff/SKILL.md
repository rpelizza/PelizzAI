---
name: pelizzai-handoff
description: Prepara uma nova sessão ou frente com contexto mínimo, verificável e seguro. Use quando o usuário pedir handoff/continuação em outra conversa ou quando mudar de rumo numa borda de fase. Para continuar o mesmo trabalho na mesma sessão, use compaction nativa. Respeita state consumidor e execution record source sem criar runtime indevido.
---

# PelizzAI Handoff

## Objetivo

Dar à próxima sessão tudo que ela precisa para retomar, sem copiar uma narrativa inteira nem
inventar estado que Git pode provar.

**Anuncie:** "Usando PelizzAI Handoff para preparar a próxima sessão."

## Handoff ou compaction?

```text
mesma missão + mesma direção → compaction/continuação nativa
nova sessão, nova frente ou mudança de direção → handoff
```

Não use limiar fixo de tokens como gatilho. Use sinais da plataforma, perda de legibilidade do
contexto e bordas reais de fase. Nunca interrompa uma mutação/review pela metade só para handoff;
primeiro deixe Git + registro em estado verificável, ou marque explicitamente WIP/BLOCKED.

## Onde entregar

Prefira o recurso nativo de handoff/task da plataforma. Se for necessário um arquivo:

- consumidor com runtime configurado: `pelizzai/data/handoffs/handoff-<timestamp>-<slug>.md`
  somente se o path estiver ignorado;
- source mode ou consumidor sem runtime seguro: diretório temporário do sistema;
- arquivo versionado: somente por pedido explícito, via router + branch antes da escrita.

Nunca crie `pelizzai/` no repo-fonte para armazenar handoff.

## Conteúdo mínimo

```text
Objetivo/aceite da próxima sessão
Modo e efeito autorizados; ações externas ainda não autorizadas
Rota/política ratificada a honrar: lane, isolamento, modo de execução e estratégia de commit (a próxima sessão segue sem re-perguntar; destino externo não é default — confirma-se por tarefa)
Estado confirmado: branch, base-sha, HEAD, phase, isolation/worktree e working tree (se phase: delivered, inclua confirmar: para a próxima sessão constatar done)
Progresso: linha por tarefa (T<n>), próximo, pendente/bloqueado
Decisões duráveis e fora de escopo
Plano/spec/ADR relevantes por path ou conteúdo nativo
Skills locais + overlays que realmente se aplicam
Evidência já válida e o que foi invalidado pela última mutação
Próximo comando/ação segura
```

No consumidor, `state.md` continua sendo a fonte do cursor; em source mode, o execution record +
Git. O handoff aponta para eles, não os substitui. Sem arquivo de plano persistente, inclua a tarefa
pendente do plano nativo — não invente path.

## Regras de qualidade

- Fatos vêm de Git/artefatos, não da memória da conversa.
- Redija tokens, senhas, dados pessoais e URLs internas sensíveis; diga onde obtê-los.
- Use paths estáveis apenas quando existem. Linhas de código podem ser incluídas como evidência
  atual, marcadas como potencialmente voláteis; não esconda achado acionável por medo de drift.
- Não replique specs/ADRs inteiros quando a próxima sessão consegue acessá-los.
- Um handoff carrega uma missão; frentes independentes recebem handoffs separados.

## Definition of Done

```text
[ ] Git e registro concordam ou a divergência está explícita;
[ ] nenhuma autoridade externa foi ampliada;
[ ] próxima sessão sabe o próximo passo e como provar sucesso;
[ ] nenhum segredo foi copiado;
[ ] source mode não ganhou runtime consumidor.
```
