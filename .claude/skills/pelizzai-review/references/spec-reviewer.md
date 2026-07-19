# Template do prompt de reviewer da lente spec — cega (Estágio 1)

Use ao despachar o reviewer de SPEC (primeiro estágio, por tarefa). É um veredito **puro** de conformidade — **NÃO rode testes nem preencha Verification** (isso é do Estágio 2). O reviewer recebe contexto fabricado, nunca o histórico da sessão.

Esta lente é **cega** por desenho: no perfil `split`, **O revisor da lente spec NÃO recebe o relatório do implementador — julga o código contra o contrato, sem a narrativa do autor.** Não cole o relatório neste briefing. (No `combined`, um único revisor incorpora esta rubrica e a de qualidade/evidência num só briefing, e o relatório entra pela rubrica de qualidade/evidência — nunca por aqui.)

````text
Você está revisando se uma implementação corresponde à sua especificação.

## O que foi pedido

{TEXTO_COMPLETO_DA_TAREFA}

## CRÍTICO: você NÃO recebe o relatório do implementador

Esta é a lente cega. Você não tem a narrativa do autor sobre o que ele alega ter feito — e isso é
intencional: julgue o código contra o CONTRATO (o que foi pedido acima), sem ser ancorado por
alegações otimistas. VERIFIQUE tudo de forma independente lendo o código de fato.

O implementador NÃO commitou — o código está na working tree (`git diff`, `git diff --staged`,
e arquivos novos via `git status`). Leia esse código e confira:

- Faltando: implementou tudo o que foi pedido? Pulou/esqueceu algum requisito?
- Extra/desnecessário: construiu o que não foi pedido? Super-engenharia? "Nice to haves" fora da spec?
- Scope creep (categoria de achado de primeira classe): há comportamento no diff que não foi pedido?
- Traceabilidade por linha (critério mecânico): toda linha alterada rastreia diretamente a um
  requisito do pedido? Linha sem rastro é um achado, não um detalhe.
- Mal-entendidos: interpretou diferente do pretendido? Resolveu o problema errado? Certo, mas do jeito errado?

Verifique LENDO O CÓDIGO contra o contrato.

## Veredito (só conformidade — sem rodar testes, sem Verification)

- ✅ Conforme a spec (tudo bate após inspeção do código), ou
- ❌ Problemas: [liste especificamente o que falta ou sobra, com arquivo:linha], ou
- ⚠️ Não verificável: [o que não deu para confirmar e por quê] — o coordenador avalia contra o plano.
````

**Placeholders:** `{TEXTO_COMPLETO_DA_TAREFA}` (colado do plano). O relatório do implementador **não** é placeholder desta lente — ele vai só para a lente qualidade/evidência (ver `code-reviewer.md`).
