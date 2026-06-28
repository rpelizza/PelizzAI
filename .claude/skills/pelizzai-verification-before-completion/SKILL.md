---
name: pelizzai-verification-before-completion
description: Use SEMPRE que estiver prestes a afirmar que algo está pronto, corrigido, passando ou funcionando — antes de commitar, dar push ou abrir PR, e antes de passar para a próxima tarefa. Exige RODAR o comando de verificação e CONFIRMAR a saída (exit code, contagem de falhas) ANTES de qualquer alegação de sucesso. Evidência antes de afirmação, sempre. Acione antes da conclusão na `pelizzai-execution-plans` e antes do push/PR na `pelizzai-finish-task`; vale para qualquer expressão de sucesso ou satisfação.
---

# PelizzAI Verification Before Completion

## Objetivo

Afirmar que um trabalho está concluído sem verificar é desonestidade, não eficiência. Esta skill é o gate que exige **evidência fresca** antes de qualquer alegação de sucesso.

**Anuncie ao iniciar:** "Usando a skill Pelizzai Verification Before Completion para confirmar com evidência antes de declarar pronto." (apenas quando acionada explicitamente; como gate embutido de outra skill, o gate roda implícito a cada alegação de sucesso, sem anúncio.)

---

## Princípio central

> Evidência antes de afirmação, sempre. Violar a letra desta regra é violar o espírito dela.

---

## A Lei de Ferro

```text
NENHUMA ALEGAÇÃO DE CONCLUSÃO SEM EVIDÊNCIA FRESCA DE VERIFICAÇÃO.
```

Se você não rodou o comando de verificação **nesta mensagem**, você **não pode** afirmar que passa.

---

## O gate

```text
ANTES de afirmar qualquer status ou expressar satisfação:

1. IDENTIFIQUE: qual comando prova esta alegação? (em workspace, use os comandos do projeto-alvo — ver pelizzai/data/state.md, campo project:)
2. RODE: execute o comando COMPLETO (fresco, inteiro).
3. LEIA: a saída inteira — confira o exit code, conte as falhas.
4. VERIFIQUE: a saída confirma a alegação?
   - Se NÃO: declare o status REAL, com a evidência.
   - Se SIM: faça a alegação JUNTO com a evidência.
5. SÓ ENTÃO: faça a alegação.

Pular qualquer passo = mentir, não verificar.
```

---

## Falhas comuns

| Alegação                  | Exige                                   | Não basta                            |
| ------------------------- | --------------------------------------- | ------------------------------------ |
| Testes passam             | Saída do comando de teste: 0 falhas     | Execução anterior, "deveria passar"  |
| Linter limpo              | Saída do linter: 0 erros                | Check parcial, extrapolação          |
| Build funciona            | Comando de build: exit 0                | Linter passou, "os logs parecem ok"  |
| Bug corrigido             | Testar o sintoma original: passa        | Código mudou, presumido corrigido    |
| Teste de regressão válido | Ciclo red-green verificado              | O teste passa uma vez                |
| Subagente concluiu        | Diff do git mostra as mudanças          | O agente reportou "sucesso"          |
| Requisitos atendidos      | Checklist linha a linha contra o plano  | Os testes passam                     |

---

## Sinais de alerta — PARE

```text
- Usar "deveria", "provavelmente", "parece que".
- Expressar satisfação antes de verificar ("Ótimo!", "Perfeito!", "Pronto!").
- Prestes a commitar/push/PR sem verificação.
- Confiar no relatório de sucesso de um subagente.
- Apoiar-se em verificação parcial.
- Pensar "só desta vez".
- Cansaço e vontade de terminar.
- QUALQUER frase que implique sucesso sem ter rodado a verificação.
```

---

## Prevenção de racionalização

| Desculpa                                  | Realidade                |
| ----------------------------------------- | ------------------------ |
| "Agora deve funcionar"                    | RODE a verificação       |
| "Estou confiante"                         | Confiança ≠ evidência    |
| "Só desta vez"                            | Sem exceções             |
| "O linter passou"                         | Linter ≠ compilador      |
| "O subagente disse que deu certo"         | Verifique você mesmo     |
| "Estou cansado"                           | Exaustão ≠ desculpa      |
| "Um check parcial basta"                  | Parcial não prova nada   |
| "Palavras diferentes, a regra não vale"   | Espírito acima da letra  |

---

## Padrões-chave

```text
Testes:
✅ [rode o comando] [veja: 34/34 passam] "Todos os testes passam"
❌ "Agora deve passar" / "Parece correto"

Teste de regressão (TDD red-green):
✅ Escreva → Rode (passa) → Reverta o fix → Rode (DEVE FALHAR) → Restaure → Rode (passa)
❌ "Escrevi um teste de regressão" (sem o ciclo red-green)

Build:
✅ [rode o build] [veja: exit 0] "Build passa"
❌ "O linter passou" (linter não verifica compilação)

Requisitos:
✅ Releia o plano → crie um checklist → verifique cada item → reporte lacunas ou conclusão
❌ "Os testes passam, fase concluída"

Delegação a subagente:
✅ Subagente reporta sucesso → confira o diff do git → verifique as mudanças → reporte o estado REAL
❌ Confiar no relatório do subagente
```

---

## Quando aplicar

```text
SEMPRE antes de:
- Qualquer variação de alegação de sucesso/conclusão.
- Qualquer expressão de satisfação.
- Qualquer afirmação positiva sobre o estado do trabalho.
- Commitar, abrir PR, concluir a tarefa.
- Passar para a próxima tarefa.
- Delegar a subagentes.

A regra vale para: frases exatas, paráfrases e sinônimos, implicações de sucesso —
qualquer comunicação que sugira conclusão ou correção.
```

---

## Trabalho de frontend

Para mudanças que afetam a UI, testes verdes e build ok **não** provam que a página renderiza certo. Antes de declarar pronta uma mudança de frontend, valide a UI **rodando** — via `pelizzai-frontend` (verificação visual em navegador/screenshot, mobile e desktop) e/ou abrindo no Playwright MCP, se configurado.

---

## Por que isso importa

Alegar conclusão sem evidência quebra a confiança e gera retrabalho: função indefinida que vai quebrar em produção, requisito faltando entregue como pronto, tempo perdido em conclusão falsa → redirecionamento → retrabalho. O custo real aparece quando o parceiro humano deixa de acreditar na sua palavra ("não acredito em você") — confiança quebrada não se recupera com mais uma alegação, e sim com evidência. Honestidade é valor central do harness — declare o que você **provou**, não o que você espera.

---

## Integração

**Combina com:**

- `pelizzai-execution-plans` — gate antes de declarar a tarefa/plano concluído (review final → verificação → `pelizzai-finish-task`).
- `pelizzai-finish-task` — verifica os testes antes de consolidar e antes de qualquer push/PR.
- `pelizzai-review` — o bloco `Verification` do reviewer é esta mesma disciplina (evidência fresca; UNVERIFIED nunca ✅), aplicada por-tarefa e no review final na `pelizzai-review`; esta skill é o gate de conclusão da branch inteira.
- `pelizzai-tdd` — o red-green produz o teste; a PROVA de regressão (reverter o fix → DEVE FALHAR → restaurar) é exigida aqui.
- `pelizzai-frontend` — executa a verificação visual da UI rodando (navegador/screenshot, mobile e desktop) que esta skill exige para mudanças de interface.

---

## Instrução final para o agente

```text
Sem atalhos para a verificação.

Rode o comando. Leia a saída. SÓ ENTÃO afirme o resultado.

Prefira:
- evidência fresca a "deveria funcionar";
- exit code e contagem de falhas a "parece ok";
- estado real a relatório de subagente;
- checklist contra o plano a "os testes passam".

Isto não é negociável.
```
