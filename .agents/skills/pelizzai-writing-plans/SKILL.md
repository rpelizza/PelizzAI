---
name: pelizzai-writing-plans
description: Transforma requisitos, spec, PRD ou design aprovado em um plano de implementação executável antes do código. Use para features bounded, standard ou exploratory que precisam de uma ou mais tarefas coordenadas, ou quando o usuário pedir plano/decomposição. Dimensiona detalhe, validação, overlays e review por risco; não força brainstorming ou entrevista quando o aceite já está claro.
---

# PelizzAI Writing Plans

## Objetivo

Produzir o menor plano que permite a um executor fresco implementar sem adivinhar contratos,
escopo ou prova. O plano descreve decisões e critérios; não antecipa a implementação inteira.

**Anuncie:** "Usando a skill PelizzAI Writing Plans para transformar os requisitos num plano executável."

Em consumidor, salve em `pelizzai/plans/AAAA-MM-DD-<topico>.md`, salvo preferência explícita. Em
source mode, use o plano nativo da plataforma e só crie arquivo se o usuário pedir um artefato
persistente. A task/planning branch já deve existir; state é obrigatório apenas no consumidor.

## Pré-condições

```text
- Objetivo e critério de aceite são claros o suficiente para planejar.
- A branch foi aberta por pelizzai-starting-branch antes da spec/plano.
- Source mode segue as regras do repo-fonte sem runtime `pelizzai/`; consumidor usa catálogo/profile.
- Fato de biblioteca/API que pode ter mudado foi verificado em documentação oficial disponível.
```

Se ainda não é possível formular a pergunta técnica com precisão, volte ao brainstorming. Se a
pergunta é precisa mas a resposta depende de evidência, crie uma tarefa curta de investigação ou
protótipo com saída e critério de parada.

## Profundidade do plano

Use a lane registrada pelo router:

| Lane | Forma do plano |
| --- | --- |
| `bounded` | 1–poucas tarefas compactas; paths, contrato, aceite, prova e comando. Não force brainstorming, entrevista ou snippets extensos. |
| `standard` | tarefas verticais, interfaces e dependências explícitas; detalhe onde um executor poderia escolher errado. |
| `exploratory` | riscos, decisões, migração/rollback e tarefas de descoberta delimitadas; não invente certeza nem implementação prematura. |

Inclua código/config completo somente quando ele próprio é o contrato frágil (schema, formato,
template, chamada pouco óbvia). Para implementação comum, nomes, interfaces, invariantes e exemplos
curtos são mais duráveis que copiar o código futuro para o plano.

## Decompor em fatias verticais

Cada tarefa entrega um resultado observável de ponta a ponta. Não separe “todos os testes” de
“toda a implementação”. Uma tarefa é uma unidade que pode ser aprovada ou rejeitada sem obrigar a
mesma decisão sobre a vizinha; um plano de uma tarefa é válido.

```text
- Siga a estrutura existente; não use o plano para reestruturar o repo sem requisito.
- Nomeie paths e interfaces que já são conhecidos; marque glob/pasta apenas quando a descoberta
  do arquivo correto fizer parte explícita da tarefa.
- Declare dependências entre tarefas e evite paralelismo falso em uma working tree compartilhada.
- Tarefa durável/assíncrona privilegia contrato e aceite; não congele número de linha perecível.
```

## Skills aplicáveis

Registre no cabeçalho e em cada tarefa:

- skills de domínio selecionadas do catálogo, ou `nenhuma`;
- **Skills transversais do harness**, ou `nenhuma`.

Overlays obrigatórios por superfície:

| Superfície | Overlay |
| --- | --- |
| página, componente, CSS, layout, estado visual, UX | `pelizzai-frontend` |
| auth, autorização, input não confiável, SQL, upload, segredo, dado sensível | `pelizzai-oswap` |
| documentação humana que faz parte da entrega | `pelizzai-documenting-features` |

Não liste skill por possibilidade remota. UI nunca troca `pelizzai-frontend` por Playwright,
browser ou screenshot; esses são apenas ferramentas do overlay.

## Estratégia por tarefa

Preencha **Estratégia de implementação e validação**:

| Efeito | Estratégia primária | Evidência |
| --- | --- | --- |
| comportamento/regressão automatizável | TDD red→green pelo contrato público | RED observado, GREEN, teste focal |
| refactor preservativo/legado | characterization | mesma prova verde antes/depois |
| config, IaC, schema, migração, script | validate | parser, fixture, plan/dry-run e rollback aplicável |
| UI visual/interação | visual + funcional | app rodando, estados/viewports, acessibilidade |
| docs, prompt, policy, artefato estático | static/scenario | lint, render, link/schema/grep ou consumo real |

Tarefas mistas combinam estratégias. Não fabrique RED para CSS, Markdown ou configuração só para
uniformizar o plano.

Registre também **Perfil de review**:

- `combined`: bounded, risco baixo, escopo coeso, sem segurança/dados/migração/contrato público;
- `split`: risco médio/alto, superfície sensível, contrato público, dados, migração ou múltiplas partes.

Ambos cobrem spec e qualidade; muda a quantidade de despachos, não o critério de aprovação.

## Documento

Use [templates/plan.md](templates/plan.md) e mantenha apenas campos aplicáveis. Cada tarefa contém:

```text
resultado + fora de escopo
files/interfaces
skills de domínio + overlays
dependências/constraints
estratégia de implementação e validação
perfil de review
passos e comandos suficientes
critério observável de conclusão e rollback quando aplicável
```

São defeitos: `TBD`, “tratar edge cases” sem nomeá-los, comandos inexistentes, API lembrada sem
fonte atual, placeholders, tarefa horizontal ou prova que não observa o efeito.

## Verificar o plano

Antes do handoff:

1. Mapeie cada requisito para uma tarefa e cada tarefa para um requisito.
2. Confirme interfaces/nomenclatura entre tarefas e dependências.
3. Confirme overlays e estratégia de prova por artefato.
4. Procure placeholders e comandos chutados.
5. Confirme que a lane não recebeu cerimônia maior que seu risco.

Use revisão independente ou `pelizzai-interview-me` somente quando incerteza, risco ou decisões
reais justificarem. Para `bounded`, a autoavaliação acima normalmente basta. Para `standard`, use
stress focal se restarem trade-offs. Para `exploratory`, stress/review independente é esperado.
Não reabra design aprovado sem evidência nova.

## Handoff

No consumidor, atualize o campo `plan:` no state. Em source mode, entregue o plano nativo/execution
record a `pelizzai-execution-plans`. A branch/base já estão definidas; o gate pós-plano resolve
apenas decisões pendentes com defaults proporcionais:

```text
isolation: branch por default; worktree apenas se pedido/justificado
execution-mode: inline por default; subagents/team por independência ou coordenação real
commit-strategy: granular por default; squash-final só com trade-off/pedido
```

Não mostre todas as opções quando o default é seguro e reversível. Se o usuário pediu **apenas o
plano**, não execute código: valide o artefato, consolide/sele a entrega de planejamento e mantenha
local salvo pedido externo.

## Red flags

```text
- Escrever plano antes da task branch.
- Forçar brainstorming/interview/reviewer independente em lane bounded clara.
- Duplicar no plano todo o código que a execução deve escrever.
- Omitir overlay frontend/security detectável.
- TDD universal ou review split universal.
- Team/worktree por preferência do harness, sem ganho concreto.
- Plano gigante cobrindo subsistemas que deveriam ser tarefas/projetos separados.
```

## Integração

Combina com `pelizzai-brainstorming` quando houve design, `pelizzai-reasoning` para decomposição,
`pelizzai-frontend`/`pelizzai-oswap` como overlays e `pelizzai-execution-plans` para execução.

## Instrução final

Planeje o contrato, a prova e as fronteiras na profundidade da lane. Deixe a implementação para a
execução e não transforme clareza em cerimônia.
