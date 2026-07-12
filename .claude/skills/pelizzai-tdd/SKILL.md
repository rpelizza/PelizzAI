---
name: pelizzai-tdd
description: Estratégia test-first para comportamento novo, alterado ou regressão de bug quando existe um oráculo automatizável útil. Use red→green→refactor em fatias verticais por contrato público. Não use como ritual universal para refatoração preservativa, CSS visual, documentação, configuração, IaC, migração ou código gerado; nesses casos selecione caracterização, validação nativa, dry-run, QA visual ou checagem estática.
---

# PelizzAI TDD

## Objetivo

Usar um teste comportamental como instrumento de design e prova quando a tarefa realmente altera comportamento observável.

**Anuncie ao iniciar:** "Usando a skill PelizzAI TDD para implementar este comportamento em red → green → refactor."

## Gate de adequação

Use TDD quando todas forem verdadeiras:

```text
[ ] Existe comportamento observável novo, alterado ou quebrado.
[ ] Há interface/seam adequado para exercitá-lo sem acoplar o teste à implementação.
[ ] O teste automatizado reduz risco de regressão e é mais estável que o detalhe testado.
```

Caso contrário, use a estratégia selecionada por `pelizzai-reasoning` e registrada no plano:

| Efeito | Estratégia correta |
| --- | --- |
| Refatoração sem mudança comportamental | cobertura/suíte de caracterização verde antes; refatorar no verde; mesma suíte depois |
| Configuração ou IaC | validator/plan/dry-run da ferramenta e checagem de compatibilidade/rollback |
| Migração | validação de schema, dry-run/ambiente descartável, forward/rollback conforme suporte |
| UI puramente visual | `pelizzai-frontend` + navegador/screenshot em viewports e estados relevantes |
| Documentação/copy | lint, links, exemplos, build/render ou inspeção estática proporcional |
| Código gerado/vendor | validar fonte/gerador e regeneração determinística; não testar o artefato como código autoral |

Combinações são normais: um formulário usa TDD para submissão/erros **e** `pelizzai-frontend` para aparência, acessibilidade e responsividade.

---

## Princípio de teste

Teste comportamento por interface pública, não detalhes internos. O teste deve sobreviver a uma refatoração que preserve o contrato.

Prefira integração fina ou tracer bullet que percorra o caminho real. Use mocks somente em fronteiras externas caras, lentas ou não determinísticas; não simule colaboradores internos para validar a forma do código. Consulte [tests.md](tests.md) e [mocking.md](mocking.md) quando precisar de exemplos.

## Preparação mínima

Antes do primeiro teste:

```text
1. Consumidor: leia `pelizzai/domain-skills.md`; source mode: use regras/skills do repo-fonte.
2. Obtenha o comando canônico em `pelizzai/profile.md`, quando existir, ou no manifest/script real.
3. Confirme contrato, comportamento e seam no pedido/aceite; use spec/plano quando existirem.
4. Para API externa incerta, consulte a documentação oficial atual disponível.
5. Pergunte apenas se restar ambiguidade material; não reabra decisões já aprovadas.
```

Se o seam necessário não existe, isso é sinal arquitetural. Não contorça o teste: registre a lacuna e use `pelizzai-improving-architecture` quando ela exigir mudança de design.

---

## Plano de teste na borda (antes do primeiro RED)

Quando a superfície é nova ou alterada de forma material, os comportamentos e seams a testar não
começam por suposição: apresente o plano de teste na borda e ratifique antes do primeiro RED. A
escolha de comportamentos/seams continua sua (o desenho é preservado); ela vira recomendação a
ratificar, não decisão aplicada em silêncio.

```text
Plano de teste proposto (responda "ok" ou ajuste):
- Comportamentos por fatia: <lista ordenada de comportamentos observáveis, um por fatia>
- Seams: <interface/fronteira que exercita cada um sem acoplar à implementação>
- Fora de escopo: <o que este ciclo não cobre>
```

Proporcional: fatia única de contrato óbvio, ou plano que já aprovou os comportamentos/seams da
tarefa, dispensam o gate — não reabra decisão já ratificada. O gate de adequação (acima) permanece:
se TDD não é a estratégia certa, ele decide isso antes.

Sob briefing fechado (SUBAGENT-STOP), não produza análises de rota nem abra gates: aplique o briefing e escale ao coordenador o que exigir decisão.

---

## Ciclo por fatia vertical

### 1. RED

Escreva **um** teste para **um** comportamento observável. Rode-o e confirme:

```text
- falha pelo motivo esperado;
- falha no código de produção, não por fixture/import/setup quebrado;
- passaria somente se o comportamento existisse.
```

Teste que já passa não provou a regressão nem guiou a implementação. Corrija o teste/seam antes de seguir.

### 2. GREEN

Implemente o mínimo coerente para satisfazer o comportamento. Rode o teste e leia exit code/contagem. Não antecipe casos futuros nem misture refator amplo.

### 3. Próxima fatia

Repita um comportamento por vez. Não escreva todos os testes primeiro para depois escrever toda a implementação; isso congela uma forma imaginada antes do aprendizado do ciclo anterior.

### 4. REFACTOR

Somente no verde:

```text
- remova duplicação;
- melhore nomes e fronteiras;
- aprofunde módulos quando simplificar a interface;
- rode a suíte relevante após cada passo.
```

Use [refactoring.md](refactoring.md) para candidatos. Refatoração pode acontecer dentro do ciclo, mas uma tarefa cujo único efeito é refatorar não precisa fabricar RED: ela começa e termina com caracterização verde.

---

## Checklist por ciclo

```text
[ ] O teste descreve o contrato observável.
[ ] Usa a interface/seam acordado, sem detalhe privado.
[ ] O RED foi observado pela razão esperada.
[ ] O GREEN foi observado com saída fresca.
[ ] O código adicionado é proporcional ao comportamento atual.
[ ] Nenhuma funcionalidade especulativa entrou.
```

Para bug de regressão, `pelizzai-verification-before-completion` pode exigir a prova reforçada: verde com o fix, falha ao remover/reverter somente o fix, verde após restaurá-lo.

## Quando um teste falha inesperadamente

Não invoque RCA por reflexo:

```text
- causa direta explícita → ReAct + Verification;
- bug determinístico com causa incerta → RCA leve;
- flaky/recorrente/distribuído → RCA + síntese de evidência;
- dano ativo → contenção reversível primeiro.
```

Siga a triagem de `pelizzai-debugging`.

## Integração no harness

- `pelizzai-writing-plans` registra TDD **por tarefa** somente quando o efeito é comportamental.
- `pelizzai-execution-plans` aplica a estratégia registrada; não injeta TDD universalmente.
- `pelizzai-debugging` usa regressão red→green quando há comportamento automatizável.
- `pelizzai-frontend` continua obrigatório para UI mesmo quando testes de componente passam.
- `pelizzai-verification-before-completion` valida o resultado completo antes de qualquer alegação.

> TDD é uma ferramenta forte para comportamento, não uma prova universal de qualidade.
