---
name: pelizzai-verification-before-completion
description: Gate de evidência antes de afirmar conclusão, correção ou prontidão e antes de integrar/publicar. Escolhe prova proporcional ao efeito, invalida evidência após mutação relevante, exige frontend visual quando aplicável e sela o SHA exato do conteúdo validado em validated-head. Não repete checks por mudança de mensagem nem transforma toda ação intermediária em validação final.
---

# PelizzAI Verification Before Completion

## Objetivo

Fazer a força da afirmação corresponder à evidência. Verification é um gate de causalidade: a prova
precisa observar o efeito alegado **depois da última mutação que poderia alterá-lo**.

**Anuncie** somente quando for uma fase explícita; como gate embutido, rode sem novo preâmbulo.

## Contrato

```text
1. Defina a alegação exata e seu escopo.
2. Escolha o menor oráculo que realmente a observa.
3. Rode/inspecione a prova após a última mutação relevante.
4. Leia saída, exit code, delta e limitações.
5. Se não cobre a alegação, reduza a alegação ou obtenha evidência adicional.
6. Em entrega Git, sele o mesmo HEAD que será integrado.
```

“Fresh” não significa “na mesma mensagem”. Significa que a evidência:

- foi produzida nesta execução ou é um artefato verificável identificado;
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

## TDD e regressão

Se o ciclo RED→GREEN já foi observado e registrado antes do fix, não reverta o conteúdo final para
encenar outro RED. Reexecute GREEN e checks de regressão afetados. Quando não existe evidência de
que o teste detecta o defeito, obtenha prova negativa somente por meio seguro (mutation controlada,
branch/patch temporário ou reprodução anterior preservada) e restaure/verifique o estado. Não use
reversão destrutiva nem deixe working tree ambígua.

## Delegação e review

Relatório de agente não é prova por si só. Confira o artefato/diff e execute a evidência cuja
responsabilidade é do coordenador. No review por tarefa, o bloco Verification cobre a lente de
qualidade; no candidato final, o coordenador revalida o range/HEAD consolidado conforme risco.

`UNVERIFIED` é um estado válido e honesto. Diga o que não pôde rodar e limite a conclusão; não
converta ausência de ferramenta em aprovação.

## Frontend

Qualquer mudança de página, componente, CSS, layout, estado visual ou UX aplica
`pelizzai-frontend` como overlay. Spec/Figma/design system aprovados prevalecem sobre heurísticas;
anti-AI-slop, estados, responsividade, acessibilidade e QA visual continuam parte da prova.

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
`validated-head..closure-head` contém somente `pelizzai/data/state.md`. Esse commit não muda o
conteúdo validado.

Em source mode, finish-task recebe `validated-head` do execution record, exige HEAD igual e working
tree limpa e **não** cria state/closure commit.

Qualquer mutação de produto após o seal invalida `validated-head`: volte aos overlays/review/provas,
commite o novo candidato e sele novamente. Nunca “corrija só mais uma coisa” na finish-task.

## Quando aplicar

- antes de afirmar que a tarefa/bug/feature está concluída ou funcionando;
- antes de selar uma entrega Git;
- antes de push, PR, integração ou efeito externo cuja segurança depende do resultado;
- no gate de tarefa/fase quando a head skill o exige.

Não acione uma validação final para cada tool call, pergunta intermediária ou delegação. Evidência
local pode orientar a próxima ação sem alegação de conclusão.

## Red flags

```text
- “deveria passar”, confiança ou relatório de subagente como prova.
- Reexecutar checks só porque mudou a mensagem, sem mutação relevante.
- Usar uma prova parcial para uma alegação ampla.
- Forçar TDD/mutation test em artefato sem comportamento automatizável.
- Declarar UI pronta sem overlay frontend e limite visual explícito.
- Gravar validated-head antes de squash/overlays/fixes/review final.
- Entregar HEAD diferente do conteúdo validado.
```

## Integração

Combina com `pelizzai-review`, `pelizzai-tdd`, `pelizzai-frontend`,
`pelizzai-execution-plans` e `pelizzai-finish-task`. A head skill decide quando o gate entra; esta
skill decide se a evidência sustenta a conclusão.

## Instrução final

Prove o efeito, não o ritual. Reuse evidência ainda válida, invalide-a quando o produto mudar e
sele exatamente o conteúdo que será entregue.
