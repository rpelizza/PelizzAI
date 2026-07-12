---
name: pelizzai-domain-modeling
description: Overlay para tornar explícito e consistente o modelo de domínio durante design ou documentação autorizada. Use quando a tarefa realmente muda terminologia, relações, invariantes, bounded contexts, ADRs ou uma rejeição durável. Apenas ler o glossário não aciona esta skill. Respeita source mode e nunca cria documentação consumer por reflexo.
---

# PelizzAI Domain Modeling

## Objetivo

Fazer código, especificação e linguagem do produto expressarem o mesmo modelo, usando cenários
concretos para revelar ambiguidade — sem transformar cada substantivo em cerimônia de DDD.

**Anuncie quando material:** "Usando PelizzAI Domain Modeling para resolver a mudança de modelo."

## Gate de efeito e persistência

Ler termos/ADRs existentes é investigação normal. Esta skill entra quando o modelo será **mudado**;
a task branch já deve existir antes de editar documentação.

| Modo | Onde ler/escrever |
| --- | --- |
| Consumidor | glossário em `pelizzai/context.md` ou `pelizzai/context/`; ADRs em `pelizzai/adr/`; rejeições em `pelizzai/out-of-scope/`, criados somente quando necessários |
| Source mode | documentação nativa já adotada pelo repo ou plano/execution record; nunca crie `pelizzai/`. Se não houver path nativo e um arquivo não foi pedido, mantenha a decisão no artefato de design nativo |

Registro de ADR/rejeição segue o gate, nunca o reflexo:

- **Decisão já ratificada num gate de design/plano**, dentro de um fluxo de escrita autorizado (task
  branch aberta): REGISTRE o ADR automaticamente quando os três critérios do §3 forem verdade e
  anuncie em uma linha ("Registrei ADR-000N: <título> — avise se quiser ajustar ou remover"). O
  harness apenas memoriza uma decisão que o usuário já tomou; não decide nada novo.
- **Decisão arquitetural emergente** — surgida na execução, numa lane sem gate de design, ou numa
  causa-raiz de debugging: não grave em silêncio. Apresente-a ao usuário na borda de
  validação/conclusão (que já é gate) antes de gravar o ADR.
- A criação do ADR é ação do **coordenador**; um membro de time apenas sinaliza a decisão no
  relatório, sem gravar.
- **Nunca** grave ADR depois de `candidate-head`/`validated-head`: doc escrito após o seal invalida
  o candidato. Fixe a escrita ao ciclo da tarefa onde a decisão é tomada (pré-seal).
- Em análise read-only, apenas **proponha** o registro; a escrita volta ao gate de primeira escrita.

Sob briefing fechado (SUBAGENT-STOP), não produza análises de rota nem abra gates: aplique o briefing
e escale ao coordenador o que exigir decisão.

## Processo

### 1. Localize o vocabulário real

Leia glossário/ADRs/specs existentes e procure os termos no código, schemas, APIs e UI. Separe:

- nome oficial;
- sinônimo legítimo por contexto;
- colisão/sobrecarga;
- divergência entre documentação e comportamento.

### 2. Force precisão com cenários

Use poucos exemplos que mudam a resposta:

```text
- identidade: duas entidades podem existir separadamente?
- ciclo de vida: qual transição é válida, proibida ou reversível?
- ownership: quem pode criar, alterar, cancelar ou observar?
- tempo: o que acontece antes/depois, expira ou é historizado?
- fronteira: este termo significa a mesma coisa em todos os contextos?
```

Pergunte somente quando a evidência não resolve uma decisão pertencente ao usuário. Não invente
termos novos se o vocabulário atual já é preciso.

### 3. Atualize o menor artefato durável

- Glossário: definição, contexto e distinção necessária; sem detalhes de implementação.
- ADR: quando a decisão é difícil de reverter, surpreendente sem contexto **e** fruto de trade-off
  real (os três juntos). Use `templates/adr.md` — arquivo numerado (ADR-000N) com contexto, decisão,
  alternativas rejeitadas e consequências, sem frontmatter. No consumidor grave em `pelizzai/adr/`;
  em source mode, registre no execution record/artefato de design nativo e **ofereça** materializar
  como arquivo no path de ADR nativo do repo quando o usuário quiser durabilidade (default: manter no
  registro), sem criar `pelizzai/`.
- Out-of-scope: apenas rejeição durável; adiamento/capacidade momentânea não é rejeição.

Um conceito atualiza o registro existente; não crie arquivo por conversa. Algo já implementado não
vira out-of-scope. Mudança de vocabulário precisa propagar aos artefatos em escopo ou deixar uma
migração explícita — não renomeie silenciosamente metade do sistema.

### 4. Verifique

Procure contradições nos consumidores relevantes e valide render/lint/links quando aplicável.
Registre no plano/briefing os termos e invariantes que a implementação/review devem preservar.

## Integração

`pelizzai-brainstorming` usa este overlay somente quando o modelo muda; `pelizzai-writing-plans`
propaga os invariantes; `pelizzai-codebase-design` traduz as fronteiras para módulos; reasoning útil
é Constraint Satisfaction + Assumption Tracking.

Pontos de registro de ADR (todos filtrados pelo critério triplo, todos ação do coordenador):
`pelizzai-brainstorming` ao salvar a spec de um design ratificado (auto + anúncio de 1 linha);
`pelizzai-execution-plans` ao consolidar uma decisão arquitetural durável — já ratificada no gate de
design (auto, pré-seal) ou emergente (apresenta ao usuário antes de gravar); `pelizzai-debugging` numa
causa-raiz durável (emergente → apresenta); `pelizzai-improving-architecture` apenas **oferece**, por
ser read-only.

## Red flags

```text
- Criar `pelizzai/context.md` ou ADR no repo-fonte.
- ADR para decisão fácil/reversível ou sem trade-off.
- Registrar rejeição/ADR durante read-only sem autorização.
- Usar DDD como renomeação cosmética.
- Duplicar a spec inteira no glossário.
- Termos diferentes para o mesmo conceito sem contexto explícito.
```

## Definition of Done

```text
[ ] termos e invariantes estão inequívocos nos contextos afetados;
[ ] artefatos duráveis são mínimos e estão no path correto do modo;
[ ] ADR/rejeição atende ao critério e pertence ao escopo autorizado;
[ ] plano/implementação/review receberam o vocabulário atualizado.
```
