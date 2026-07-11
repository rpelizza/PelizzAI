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

Não registre ADR/rejeição automaticamente fora do escopo autorizado. Quando a decisão emerge numa
análise read-only, proponha o registro; escrita volta ao router/primeira-write gate.

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
- ADR: apenas se a decisão for difícil de reverter, surpreendente sem contexto **e** fruto de
  trade-off real. Registre decisão, alternativa rejeitada e consequência em formato curto.
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
