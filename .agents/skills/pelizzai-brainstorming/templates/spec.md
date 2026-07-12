# Template de spec de design

Duas escalas no mesmo arquivo. Escolha pela lane já classificada — recomendação, não imposição:

- **Spec enxuta** — `bounded` (quando ofertada e aceita) e `standard` de aceite claro.
- **Spec completa** — `exploratory` e decisões sensíveis acopladas.

Preencha apenas as seções que agregam; não force campos vazios. A spec aponta para o ADR quando
existir (via `pelizzai-domain-modeling`) e não duplica a explicação inteira da decisão. Consumidor:
salve em `pelizzai/specs/AAAA-MM-DD-<topico>-design.md`. Source mode: registre o conteúdo no
execution record nativo, sem criar `pelizzai/`; materialize em arquivo só quando o usuário pedir
durabilidade.

---

## Spec enxuta

```markdown
# <Título> — design

## Objetivo
- Resultado e usuário/consumidor.

## Critérios de aceite
- Observáveis e verificáveis.

## Design curto
- Como a mudança se encaixa; contratos/padrões que preserva.

## Fora de escopo
- O que esta mudança não faz.

## Decisões
- Escolha — motivo — reversível ou difícil de reverter (aponte o ADR se houver).
```

---

## Spec completa

```markdown
# <Título> — design

## Objetivo
- Resultado e usuário/consumidor.

## Critérios de aceite
- Observáveis e verificáveis.

## Contexto e restrições
- Prior art, constraints, compatibilidade e rejeições registradas (`out-of-scope`) relevantes.

## Design e contratos
- Responsabilidades e fronteiras; interfaces/contratos e fluxo de dados; seams reais de teste.

## Estados, falhas e segurança
- Estados e tratamento de erro; autorização/segurança/dados quando o risco exigir.

## Compatibilidade, migração e rollback
- Estratégia quando aplicável.

## Testing & Validation Decisions
- Seams escolhidos e por quê; como o codebase já testa coisas parecidas; prova por efeito.

## Fora de escopo
- O que esta mudança não faz.

## Decisões difíceis de reverter
- Cada decisão que passa no critério triplo (difícil de reverter + surpreendente sem contexto +
  trade-off real) aponta para o ADR correspondente.
```
