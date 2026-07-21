---
name: pelizzai-writing-plans
description: Transforma requisitos ratificados, spec, PRD ou design aprovado em plano de implementação durável, estressado e aprovado antes do código. Use para features bounded, standard, exploratory e todo produto/projeto greenfield, ou quando o usuário pedir plano/decomposição. Dimensiona detalhe, validação, overlays e review por risco sem decidir requisitos pelo usuário.
---

# PelizzAI Writing Plans

## Objetivo

Produzir o plano que um executor com **zero contexto** deste repositório executa sem precisar fazer
uma única pergunta: os arquivos de cada tarefa, os contratos a honrar, a prova do resultado e os
comandos exatos. Assuma um bom engenheiro que conhece pouco deste toolset, deste domínio e das
convenções da casa — o que faltar no plano ele preenche adivinhando.

Zero contexto é sobre **contexto completo**, não sobre transcrever o código futuro: o plano fixa
decisões, contratos e critérios (ver *Profundidade do plano*) e não antecipa a implementação inteira.

**Anuncie:** "Usando a skill PelizzAI Writing Plans para transformar os requisitos num plano executável."

Em consumidor, o plano é **sempre materializado** em `pelizzai/plans/AAAA-MM-DD-<feature>.md`
(salvo local diferente pedido explicitamente); é o artefato durável que a execução lê. Em source
mode, registre o plano no execution record nativo de forma **discoverable e verificável** (as
tarefas e o mapa requisito→tarefa ficam rastreáveis, não efêmeros) e **ofereça materializar** em
arquivo no path nativo do repo quando o usuário quiser durabilidade; nunca crie runtime `pelizzai/`
consumidor no repo-fonte. A task/planning branch já deve existir; state é obrigatório apenas no consumidor.

## Pré-condições

```text
- Objetivo e critério de aceite foram explicitados ou ratificados pelo usuário.
- A branch foi aberta por pelizzai-starting-branch antes da spec/plano.
- Source mode segue as regras do repo-fonte sem runtime `pelizzai/`; consumidor usa catálogo/profile.
- Fato de biblioteca/API que pode ter mudado foi verificado no Context7 para a versão observada;
  documentação oficial atual é fallback quando a ferramenta estiver indisponível.
- Greenfield/standard/exploratory possui spec aprovada, ou dispensa explícita registrada.
```

Se ainda não é possível formular a pergunta técnica com precisão, volte ao brainstorming. Se a
pergunta é precisa mas a resposta depende de evidência, crie uma tarefa curta de investigação ou
protótipo com saída e critério de parada.

## Profundidade do plano

Use a lane registrada pelo router:

| Lane | Forma do plano |
| --- | --- |
| `bounded` | 1–poucas tarefas compactas; paths, contrato, aceite, prova e comando. Não force entrevista quando o usuário já especificou a mudança. |
| `standard` | tarefas verticais, interfaces e dependências explícitas; detalhe onde um executor poderia escolher errado. |
| `exploratory` | riscos, decisões, migração/rollback e tarefas de descoberta delimitadas; não invente certeza nem implementação prematura. |

Inclua código/config completo somente quando ele próprio é o contrato frágil (schema, formato,
template, chamada pouco óbvia). Para implementação comum, nomes, interfaces, invariantes e exemplos
curtos são mais duráveis que copiar o código futuro para o plano.

Em greenfield, inclua uma fatia de documentação de uso/desenvolvimento (por exemplo README com
setup, execução, testes e limites do MVP) como recomendação padrão. O usuário pode ajustar ou
dispensar ao aprovar o plano; a LLM não remove documentação para acelerar a implementação.

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

## Decisões técnicas deste plano

Todo plano carrega a seção obrigatória `## Decisões técnicas deste plano`: a lista **numerada** das
decisões técnicas materiais que aparecem ao transformar a spec/design em plano — biblioteca ou padrão
escolhido, formato de dado, contrato de interface, estratégia de migração, trade-off de arquitetura
local. Cada item traz, em uma linha: **o quê** foi decidido, **onde foi ratificado**, a **alternativa
rejeitada** e o **porquê**.

**Uma decisão técnica material que o harness resolveu sozinho não entra na lista como fato consumado
— vira pergunta.** Enquanto monta o plano, separe:

- **Já ratificada** (fixada na spec, no design ou numa entrevista anterior): registre-a com a origem
  (`ratificada na spec` / `no design` / `na entrevista de <data>`) — e a origem tem de ser
  localizável no artefato citado, não um rótulo de conveniência. No gate ela é só recap — não se
  re-pergunta o que o usuário já decidiu.
- **Ainda aberta** (emergiu agora, ao decompor): **não escreva a escolha como decidida.** Antes de
  fechar o plano, leve-a ao usuário por `pelizzai-interview-me`, uma pergunta por vez, com **2–3
  opções reais + a recomendada marcada e o porquê em uma linha** (a inteligência está em construir as
  opções boas e fundamentar com evidência do repo/Context7; a decisão é do usuário). Só depois de
  ratificada ela entra na lista, com a origem `ratificada na entrevista do plano`.

O plano só fecha quando **toda** decisão material está ratificada — nenhuma escolha técnica de peso
viaja escondida no meio de um plano de N tarefas para ser carimbada junto.

Quando o plano é puramente mecânico e não introduz nenhuma decisão técnica material, escreva de
forma explícita `nenhuma decisão técnica material — plano puramente mecânico`. Nunca deixe a seção
vazia nem a omita: a ausência de decisões é ela própria uma afirmação a ratificar.

É essa lista que o Gate de setup pós-plano apresenta — as ratificadas como recap, e qualquer uma sem
origem de ratificação como pergunta com opções ali mesmo, antes do "ok". Decisão que não cabe numa
linha clara é sinal de que falta decisão humana (volte ao design ou a `pelizzai-interview-me`), não
de que a linha deva crescer.

Na execução vale o **teste operacional de desvio**:
se a decisão não está escrita no plano nem na spec, ela não está aprovada — apresente antes de implementar.
Decisão técnica emergente interrompe a tarefa e volta ao usuário **como pergunta com 2–3 opções e a
recomendada** (com o porquê em uma linha); nunca é preenchida em silêncio nem devolvida como pergunta
aberta sem opções. Concordar com a recomendação custa uma palavra.

## Skills aplicáveis

- No cabeçalho: as skills de domínio do catálogo que valem para o plano inteiro, ou `nenhuma`.
- Em cada tarefa: as skills de domínio daquela fatia e as **Skills transversais do harness** que ela
  exige, ou `nenhuma`. É esse bloco por tarefa que chega ao executor no briefing — o overlay não
  fica só no cabeçalho.

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

Registre também **Perfil de review**. O default é `split`, inclusive em bounded:

- `split` (default): o caso normal; obrigatório em risco médio/alto, superfície sensível, contrato
  público, dados, migração ou múltiplas partes;
- `combined`: exceção para bounded, risco baixo e escopo coeso, sem segurança/dados/migração/
  contrato público — e só depois de o usuário ratificar o rebaixamento no passo 4 do Gate de setup.

Ambos cobrem spec e qualidade; muda a quantidade de despachos, não o critério de aprovação. Só o
`split` torna a lente spec cega de fato, então o plano nunca recomenda `combined` por conta própria.

## Documento

Use [templates/plan.md](templates/plan.md) e mantenha apenas campos aplicáveis. O cabeçalho carrega o
bloco **Aprovações** — descoberta, spec, domain skills e o próprio plano, uma linha cada com a data de
ratificação: é o registro histórico da decisão humana, e o `state.md` guarda só o cursor da tarefa.
Nenhum marcador é preenchido por inferência. Cada tarefa contém:

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
fonte atual, placeholders, tarefa horizontal, prova que não observa o efeito ou requisito criado
pela LLM sem ratificação.

## Verificar o plano

Antes do handoff:

1. Mapeie cada requisito para uma tarefa e cada tarefa para um requisito.
2. Confirme interfaces/nomenclatura entre tarefas e dependências.
3. Confirme overlays e estratégia de prova por artefato.
4. Procure placeholders e comandos chutados.
5. Releia o plano como quem nunca viu este repositório: sobrou pergunta que o artefato não responde?
6. Confirme que a lane não recebeu cerimônia maior que seu risco.
7. **Estresse e exponha as lacunas materiais** do plano: caça ativa por casos não tratados, validação
   ausente, estado/erro indefinido, autorização faltante e contradições spec↔plano↔tarefa.

Liste premissas residuais **novas do plano**, sem re-litigar o design aprovado. Cada lacuna material
sai da borda resolvida, aceita pelo usuário ou convertida em investigação. Quando exigir decisão
humana, use `pelizzai-interview-me` e faça uma pergunta por vez, com recomendação. `bounded` usa
stress compacto; `standard` usa stress focal; `exploratory`/greenfield exige uma passada completa
de stress. Context7 pode confirmar API e versão, mas não fechar requisito, UX, regra de negócio ou
aceite. Não reabra design aprovado sem evidência nova.

Apresente o plano e o resultado do stress na borda — `bounded`: resumo das tarefas;
`standard`/`exploratory`: mapa requisito→tarefa. Faça **uma pergunta de aprovação do conteúdo do
plano** e aguarde. Somente depois avance ao setup; aprovação do QUÊ e decisões de COMO não são
comprimidas numa resposta única.

Sob briefing fechado (SUBAGENT-STOP), não produza análises de rota nem abra gates: aplique o
briefing e escale ao coordenador o que exigir decisão.

## Handoff

**Checagem de cobertura de domain skills (rede de segurança).** Antes de encaminhar ao Gate de
setup, verifique: a stack do plano tem cobertura no catálogo `pelizzai/domain-skills.md`? Se não —
ou se o catálogo está ausente —, acione o **Gate proativo de domain skills** da `pelizzai-audit`
para propor o conjunto da stack decidida (fundamentado em Context7); a decisão é do usuário e ocorre
**ANTES da Tarefa 1**. Isso captura fluxos que chegaram ao plano sem passar pela
`pelizzai-brainstorming`. Em source mode não há catálogo consumidor: a checagem recai sobre as
skills de domínio do repo-fonte e nunca cria runtime `pelizzai/`. Sob briefing fechado
(SUBAGENT-STOP), não abra esse gate: sinalize a lacuna de cobertura ao coordenador.

No consumidor, atualize o campo `plan:` no state e confirme o caminho materializado
(`pelizzai/plans/AAAA-MM-DD-<feature>.md`); a aprovação do conteúdo é registrada no cabeçalho do
próprio plano (`Plano: aprovado em AAAA-MM-DD`), não no state. Em source mode, entregue o plano
nativo/execution record a `pelizzai-execution-plans` de forma discoverable. A branch/base já estão
definidas;
**encaminhe ao Gate de setup pós-plano** da `pelizzai-execution-plans` somente após aprovação do
conteúdo. O gate ratifica o **como** em decisões sequenciais — isolamento, branch, modo (as três
opções sempre visíveis), commits e review. A `pelizzai-writing-plans` leva recomendações, não
decisões:

```text
isolation: branch recomendado; worktree apenas se pedido/justificado — levado ao gate
execution-mode: inline recomendado; subagents/team por independência ou coordenação real — levado ao gate
commit-strategy: granular recomendado; squash-final só com trade-off/pedido — levado ao gate
```

Não aplique isolamento, modo ou commit como decisão sem ratificação do usuário no gate sequencial;
o plano informa e o gate ratifica antes da Tarefa 1. Se o usuário pediu **apenas o plano**, não
execute código: valide o artefato, consolide/sele a entrega de planejamento e mantenha local salvo
pedido externo.

## Red flags

```text
- Escrever plano antes da task branch.
- Forçar brainstorming/interview em lane bounded clara.
- Planejar greenfield sem spec aprovada ou dispensa explícita.
- Pular stress e aprovação do plano para começar a implementar.
- Duplicar no plano todo o código que a execução deve escrever.
- Omitir overlay frontend/security detectável.
- TDD universal — ou registrar `combined` como perfil sem o usuário ter ratificado o rebaixamento.
- Team/worktree por preferência do harness, sem ganho concreto.
- Usar Context7 para decidir requisitos ou critérios de aceite.
- Plano gigante cobrindo subsistemas que deveriam ser tarefas/projetos separados.
- Omitir a seção `## Decisões técnicas deste plano` ou deixá-la vazia em vez de declarar
  `nenhuma decisão técnica material — plano puramente mecânico`.
- Encaminhar ao Gate de setup com a stack sem cobertura no catálogo, sem acionar o Gate proativo de
  domain skills da `pelizzai-audit`.
```

## Integração

Combina com `pelizzai-brainstorming` quando houve design, `pelizzai-reasoning` para decomposição,
`pelizzai-interview-me` para stress focal de premissa residual material, `pelizzai-frontend`/
`pelizzai-oswap` como overlays e `pelizzai-execution-plans` para execução.

## Instrução final

Planeje o contrato, a prova e as fronteiras na profundidade da lane. Deixe a implementação para a
execução e não transforme clareza em cerimônia.
