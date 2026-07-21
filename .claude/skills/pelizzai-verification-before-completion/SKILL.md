---
name: pelizzai-verification-before-completion
description: Use SEMPRE que estiver prestes a afirmar que algo está pronto, corrigido, passando ou funcionando — antes de commitar, integrar, dar push ou abrir PR, e antes de passar para a próxima tarefa. Exige RODAR a prova e LER a saída (exit code, contagem de falhas) ANTES de qualquer alegação de sucesso: evidência antes de afirmação, sempre. Escolhe prova proporcional ao efeito, invalida evidência após mutação relevante, exige verificação visual quando há frontend e sela o SHA exato do conteúdo validado em validated-head. Não repete checks por mudança de mensagem nem transforma toda ação intermediária em validação final.
---

# PelizzAI Verification Before Completion

## Objetivo

Afirmar que um trabalho está concluído sem verificar é desonestidade, não eficiência. Esta skill é o
gate que exige **evidência fresca** antes de qualquer alegação de sucesso e faz a força da afirmação
corresponder à evidência. Verification é um gate de causalidade: a prova precisa observar o efeito
alegado **depois da última mutação que poderia alterá-lo**.

**Anuncie** somente quando for uma fase explícita ("Usando a skill PelizzAI Verification Before
Completion para confirmar com evidência antes de declarar pronto."); como gate embutido de outra
skill, rode sem novo preâmbulo.

## Princípio central

> Evidência antes de afirmação, sempre. Violar a letra desta regra é violar o espírito dela.

## A Lei de Ferro

```text
NENHUMA ALEGAÇÃO DE CONCLUSÃO SEM EVIDÊNCIA FRESCA DE VERIFICAÇÃO.
```

Se você não tem a saída de uma prova **desta rodada de mudanças**, você **não pode** afirmar que
passa.

## O gate

```text
ANTES de afirmar qualquer status ou expressar satisfação:

1. IDENTIFIQUE: qual é a alegação exata, e qual é o menor oráculo que realmente a observa?
   (em consumidor, use os comandos do projeto-alvo — pelizzai/data/state.md, campo project:, e
   pelizzai/profile.md; em source mode, o manifest/script real.)
2. RODE: execute a prova COMPLETA e fresca, depois da última mutação que poderia alterar o resultado.
3. LEIA: a saída inteira — confira o exit code, conte as falhas, olhe o delta e as limitações.
4. VERIFIQUE: a saída confirma a alegação?
   - Se NÃO: declare o status REAL com a evidência, ou reduza a alegação ao que foi provado.
   - Se SIM: faça a alegação JUNTO com a evidência.
5. SÓ ENTÃO: faça a alegação. Em entrega Git, sele o mesmo HEAD que será integrado.

Pular qualquer passo = mentir, não verificar.
```

“Fresh” não significa “na mesma mensagem”: não re-rode a suíte inteira a cada frase. Significa que a
evidência:

- foi produzida nesta rodada de mudanças ou é um artefato verificável identificado;
- é posterior ao último código/config/doc/overlay/fix que afeta o resultado;
- corresponde ao mesmo ambiente, inputs e HEAD relevantes;
- não foi invalidada por commit, amend, merge, rebase, codegen, formatter ou teste que escreve.

Mudança apenas de conversa não invalida prova. Mudança do produto invalida.

## Prova por efeito

| Alegação/efeito | Evidência adequada | Não basta |
| --- | --- | --- |
| bug corrigido | oráculo do sintoma agora verde + regressão relevante | diff “parece certo” |
| comportamento novo/alterado | teste do contrato; RED observado quando TDD foi a estratégia | teste tautológico ou só snapshot |
| refactor preservativo | characterization/suíte equivalente antes e depois | teste novo inventado no verde |
| build/type/lint | comando canônico correspondente + exit code | extrapolar um check para outro |
| config/schema/migração/IaC | parser/validate/plan/dry-run, delta e rollback aplicável | teste unitário sem observar o artefato |
| integração | fixture/sandbox/contrato real na fronteira | mock que remove a fronteira |
| UI | `pelizzai-frontend`: app rodando, estados, viewports, acessibilidade/visual | build verde ou screenshot única sem fluxo |
| docs/prompt/policy | lint/render/links/schema/grep ou cenário de consumo | fabricar teste unitário |
| requisitos do plano | traceabilidade requisito → tarefa/diff/prova | “os testes passam” |

Combine linhas em tarefas mistas. Rode suíte completa quando risco, perfil ou mudança transversal
justificarem; use teste focal para iteração local. Não rode checks sem relação apenas para aumentar
volume de saída.

## Falhas comuns

A matriz acima escolhe a prova. Esta tabela lista as alegações em que a mentira acontece com mais
frequência:

| Alegação                  | Exige                                   | Não basta                            |
| ------------------------- | --------------------------------------- | ------------------------------------ |
| Testes passam             | Saída do comando de teste: 0 falhas     | Execução anterior, "deveria passar"  |
| Linter limpo              | Saída do linter: 0 erros                | Check parcial, extrapolação          |
| Build funciona            | Comando de build: exit 0                | Linter passou, "os logs parecem ok"  |
| Bug corrigido             | Testar o sintoma original: passa        | Código mudou, presumido corrigido    |
| Teste de regressão válido | Ciclo red-green verificado              | O teste passa uma vez                |
| Subagente concluiu        | Diff do git mostra as mudanças          | O agente reportou "sucesso"          |
| Requisitos atendidos      | Checklist linha a linha contra o plano  | Os testes passam                     |

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

## TDD e regressão

Se o ciclo RED→GREEN já foi observado e registrado nesta rodada, antes do fix, ele já é a prova: não
reverta o conteúdo final para encenar outro RED — reexecute GREEN e os checks de regressão afetados.
Quando não existe evidência de que o teste detecta o defeito, o ciclo acima é obrigatório e deve ser
obtido por meio seguro (reverter o fix no editor, mutation controlada, branch/patch temporário ou
reprodução anterior preservada), sempre restaurando e reverificando o estado. Não use reversão
destrutiva nem deixe a working tree ambígua.

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

```text
- Usar uma prova parcial para uma alegação ampla.
- Forçar TDD/mutation test em artefato sem comportamento automatizável.
- Declarar UI pronta sem overlay frontend e limite visual explícito.
- Gravar validated-head antes de squash/overlays/fixes/review final.
- Entregar HEAD diferente do conteúdo validado.
- Reexecutar checks só porque mudou a mensagem, sem mutação relevante.
```

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

## Delegação e review

Relatório de agente não é prova por si só. Confira o artefato/diff e execute a evidência cuja
responsabilidade é do coordenador. No review por tarefa, o bloco Verification cobre a lente de
qualidade; no candidato final, o coordenador revalida o range/HEAD consolidado conforme risco.

`UNVERIFIED` é um estado válido e honesto. Diga o que não pôde rodar e limite a conclusão; não
converta ausência de ferramenta em aprovação.

## Frontend

Qualquer mudança de página, componente, CSS, layout, estado visual ou UX aplica
`pelizzai-frontend` como overlay: testes verdes e build ok **não** provam que a página renderiza
certo. Spec/Figma/design system aprovados prevalecem sobre heurísticas; anti-AI-slop, estados,
responsividade, acessibilidade e QA visual continuam parte da prova.

Playwright, browser e screenshot são ferramentas, não substitutos do contrato frontend. Se a UI
não puder rodar, faça a revisão estática prevista e declare que a validação visual ficou pendente.

## Selagem do conteúdo Git

Depois de todas as mutações de produto e da estratégia de commits final:

```text
1. Confirme working tree limpa e validated-head: <none>.
2. Capture candidate-head = git rev-parse HEAD.
3. Confirme a evidência dos overlays já concluídos e rode review final, checks/checklist e esta
   Verification contra candidate-head; qualquer fix ou overlay reaberto reinicia o candidato.
4. Confirme que HEAD ainda é candidate-head.
5. Consumidor: grave candidate-head completo em state como validated-head, sem commit.
   Source mode: grave-o no execution record e mantenha a working tree limpa.
6. Entregue a pelizzai-finish-task.
```

A finish-task encerra em `phase: delivered` (conteúdo selado + destino executado), nunca em `done`;
`done` é constatação posterior contra `confirmar:`, na próxima abertura/retomada. Verification sela o
conteúdo, não declara `done`.

Ao gravar `validated-head`, confirme que o state/execution record carrega `kickoff: ratificado`: o
conteúdo selado nasceu de uma rota estrutural ratificada, não de defaults silenciosos. Se o marcador
está `pendente` numa entrega planejada, a rota não foi ratificada — resolva no gate certo antes de
selar. É uma âncora de uma linha, não um checklist novo; read-only/trivial não sela e não a exige.

Na entrada da finish-task em consumidor:

- `git rev-parse HEAD == validated-head`;
- a única sujeira é `pelizzai/data/state.md` com o seal pendente;
- nenhuma evidência é anterior ao último fix/overlay.

A finish-task cria exatamente um closure commit metadata-only. Antes de push/PR, ela prova que
`validated-head..closure-head` contém somente metadata do harness: `pelizzai/data/state.md` e o
arquivo `pelizzai/data/history/<AAAA-MM-DD>-<slug>.md` gerado pela migração do selo. Esse commit não
muda o conteúdo validado.

Em source mode, finish-task recebe `validated-head` do execution record, exige HEAD igual e working
tree limpa e **não** cria state/closure commit.

Qualquer mutação de produto após o seal invalida `validated-head`: volte aos overlays/review/provas,
commite o novo candidato e sele novamente. Nunca “corrija só mais uma coisa” na finish-task.

## Quando aplicar

```text
SEMPRE antes de:
- Qualquer variação de alegação de sucesso/conclusão ou de que algo está funcionando.
- Qualquer expressão de satisfação.
- Qualquer afirmação positiva sobre o estado do trabalho.
- Commitar, selar uma entrega Git, dar push, abrir PR, integrar ou concluir a tarefa.
- Qualquer efeito externo cuja segurança dependa do resultado.
- Incorporar como pronto o trabalho devolvido por um subagente/membro.
- Passar para a próxima tarefa, e no gate de tarefa/fase quando a head skill o exige.

A regra vale para: frases exatas, paráfrases e sinônimos, implicações de sucesso —
qualquer comunicação que sugira conclusão ou correção.
```

Não acione uma validação final para cada tool call, pergunta intermediária ou despacho de
delegação. Evidência local pode orientar a próxima ação sem alegação de conclusão.

## Por que isso importa

Alegar conclusão sem evidência quebra a confiança e gera retrabalho: função indefinida que vai
quebrar em produção, requisito faltando entregue como pronto, tempo perdido em conclusão falsa →
redirecionamento → retrabalho. O custo real aparece quando o parceiro humano deixa de acreditar na
sua palavra ("não acredito em você") — confiança quebrada não se recupera com mais uma alegação, e
sim com evidência. Honestidade é valor central do harness: declare o que você **provou**, não o que
você espera.

## Integração

- `pelizzai-execution-plans` — gate antes de declarar a tarefa/plano concluído (review final →
  verificação → `pelizzai-finish-task`).
- `pelizzai-finish-task` — verifica antes de consolidar e antes de qualquer push/PR; recebe o
  conteúdo já selado.
- `pelizzai-review` — o bloco `Verification` do reviewer é esta mesma disciplina (evidência fresca;
  UNVERIFIED nunca ✅), por tarefa e no review final; esta skill é o gate da entrega inteira.
- `pelizzai-tdd` — o red-green produz o teste; a PROVA de regressão (reverter o fix → DEVE FALHAR →
  restaurar) é exigida aqui.
- `pelizzai-frontend` — executa a verificação visual da UI rodando (navegador/screenshot, mobile e
  desktop) que esta skill exige para mudanças de interface.

A head skill decide quando o gate entra; esta skill decide se a evidência sustenta a conclusão.

## Instrução final

```text
Sem atalhos para a verificação.

Rode a prova. Leia a saída. SÓ ENTÃO afirme o resultado.

Prefira:
- evidência fresca a "deveria funcionar";
- exit code e contagem de falhas a "parece ok";
- estado real a relatório de subagente;
- checklist contra o plano a "os testes passam";
- prova do efeito a ritual, e o conteúdo selado ao conteúdo entregue por engano.

Isto não é negociável.
```

Prove o efeito, não o ritual: reuse evidência ainda válida, invalide-a quando o produto mudar e sele
exatamente o conteúdo que será entregue.
