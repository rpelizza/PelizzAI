# Template do prompt de reviewer de conformidade com a spec (Estágio 1)

Use ao despachar o reviewer de SPEC (primeiro estágio, por tarefa). É um veredito **puro** de conformidade — **NÃO rode testes nem preencha Verification** (isso é do Estágio 2). O reviewer recebe contexto fabricado, nunca o histórico da sessão.

````text
Você está revisando se uma implementação corresponde à sua especificação.

## O que foi pedido

{TEXTO_COMPLETO_DA_TAREFA}

## O que o implementador alega ter feito

{RELATÓRIO_DO_IMPLEMENTADOR}

## CRÍTICO: não confie no relatório

O relatório pode ser incompleto, impreciso ou otimista. VERIFIQUE tudo de forma independente —
leia o código de fato, não aceite as alegações.

O implementador NÃO commitou — o código está na working tree (`git diff`, `git diff --staged`,
e arquivos novos via `git status`). Leia esse código e confira:

- Faltando: implementou tudo o que foi pedido? Pulou/esqueceu algum requisito? Alegou algo que não fez?
- Extra/desnecessário: construiu o que não foi pedido? Super-engenharia? "Nice to haves" fora da spec?
- Scope creep (categoria de achado de primeira classe): há comportamento no diff que não foi pedido?
- Traceabilidade por linha (critério mecânico): toda linha alterada rastreia diretamente a um
  requisito do pedido? Linha sem rastro é um achado, não um detalhe.
- Mal-entendidos: interpretou diferente do pretendido? Resolveu o problema errado? Certo, mas do jeito errado?

Verifique LENDO O CÓDIGO, não confiando no relatório.

## Veredito (só conformidade — sem rodar testes, sem Verification)

- ✅ Conforme a spec (tudo bate após inspeção do código), ou
- ❌ Problemas: [liste especificamente o que falta ou sobra, com arquivo:linha], ou
- ⚠️ Não verificável: [o que não deu para confirmar e por quê] — o coordenador avalia contra o plano.
````

**Placeholders:** `{TEXTO_COMPLETO_DA_TAREFA}` (colado do plano) · `{RELATÓRIO_DO_IMPLEMENTADOR}`.
