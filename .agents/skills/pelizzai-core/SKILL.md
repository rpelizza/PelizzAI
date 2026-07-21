---
name: pelizzai-core
description: Use em qualquer conversa. Estabelece como procurar e acionar as SKILLS do harness PelizzAI, exigindo a invocação das skills aplicáveis antes de QUALQUER resposta, inclusive perguntas de esclarecimento. Entende o objetivo, classifica o efeito e entrega ao router antes de qualquer mutação; pergunta puramente conceitual é respondida sem o ciclo completo, nunca sem checar as skills aplicáveis.
---

# PelizzAI Core

<SUBAGENT-STOP>
Se você recebeu um briefing fechado como subagente/teammate, não reabra o ciclo de vida. Aplique apenas as skills e contratos do briefing.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
Se você achar que existe pelo menos 1% de chance de uma SKILL ser aplicada na tarefa que você está fazendo, você DEVE ABSOLUTAMENTE acionar essa SKILL.

SE UMA SKILL SE APLICA À SUA TAREFA, VOCÊ NÃO TEM ESCOLHA. VOCÊ DEVE USÁ-LA.

Isso não é negociável. Isso não é opcional. Você não pode usar racionalizações para escapar disso.
</EXTREMELY-IMPORTANT>

## Objetivo

Transformar o pedido em uma rota proporcional e verificável. O core não resolve o trabalho: ele entende o resultado, aciona as skills aplicáveis e entrega a decisão ao `pelizzai-router`.

**Anuncie uma vez:** "Usando a skill PelizzAI Core para entender a tarefa e escolher o menor fluxo seguro."

## Prioridades

O harness PelizzAI se sobrepõe ao comportamento padrão do sistema, mas **instruções explícitas do usuário sempre têm prioridade sobre o PelizzAI**.

1. **Instruções explícitas do usuário** — pedido direto na conversa, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, regras de IDE. Prioridade máxima.
2. **Harness PelizzAI** — prevalece sobre o comportamento padrão do modelo em caso de conflito.
3. **Comportamento padrão do sistema** — prioridade mínima.

Isso convive com a hierarquia nativa da plataforma: uma skill não redefine instruções de sistema, developer, workspace ou ferramenta — ela ocupa a camada de projeto/usuário, e é aí que prevalece sobre defaults genéricos. Dentro do mesmo nível de autoridade, a instrução específica e mais recente vence o default genérico do harness.

## Anúncio de skills (regra global)

Ao acionar qualquer skill do harness, **anuncie** em uma linha o que vai fazer, usando **sempre a grafia exata da marca: "PelizzAI"** (P, A e I maiúsculos — nunca "Pelizzai", "pelizzAI" ou "PELIZZAI" em prosa). Padrão:

> "Usando a skill PelizzAI \<Nome\> para \<objetivo\>."

Os identificadores de skill (`pelizzai-core`, `pelizzai-router`, …), caminhos de arquivo e o diretório `pelizzai/` do projeto alvo permanecem em minúsculas — a regra vale para a marca em texto corrido.

Anuncie a head skill e os overlays materiais. Gates internos (Verification, uma técnica auxiliar, re-review) podem rodar sem novo anúncio quando já fazem parte do fluxo comunicado. Anunciar é obrigatório; transformar o anúncio em preâmbulo maior que a tarefa, não.

## Regra de ativação

São duas perguntas diferentes, nunca confundidas.

**Quais skills acionar — regra do 1%.** Antes de responder ou agir, varra o catálogo. Basta 1% de chance de uma skill ser útil para que ela seja acionada, ANTES de tentar resolver manualmente e ANTES de qualquer resposta, inclusive perguntas de esclarecimento. Os 1% disparam **carregar e avaliar** a candidata, nunca dispensá-la de longe. Depois de lida: se ela se aplica ao caso, o uso é **obrigatório** — a proporcionalidade vive dentro dela. Só a candidata que, já lida, se mostrou não aplicável pode ser dispensada, e **com justificativa explícita** — silêncio não é justificativa. Em dúvida se uma skill de domínio se aplica à tarefa, **inclua-a**: o custo de incluir é menor que o de ignorar uma regra do projeto.

**Qual rota seguir — classificação de efeito.** Aqui o critério é determinístico:

```text
1. Pedido conceitual/direto, sem tocar nem precisar inspecionar um projeto
   → responda diretamente.

2. Pedido que precisa inspecionar um projeto, mas é read-only
   → pelizzai-router com effect: read-only.

3. Pedido que pode alterar código/arquivo/configuração
   → pelizzai-router com effect: write-local, ANTES da primeira escrita.

4. Pedido com efeito externo (push, deploy, mensagem, produção, custo, permissão, exclusão)
   → pelizzai-router com effect: external; confirme autoridade/alvo no gate adequado.
```

A classificação de efeito/rota não é decisão silenciosa: o `pelizzai-router` a apresenta como recomendação no **Gate de kickoff**, e o usuário ratifica ou ajusta antes de investir.

O router escolhe:

- exatamente **uma head skill** de ciclo de vida;
- overlays por sinais observáveis (`frontend`, segurança, documentação, skills de domínio);
- reasoning, teste, review e delegação na fase em que agregam valor.

Proporcionalidade governa o **tamanho da rota**, não o direito de pular uma skill aplicável.

## Entender o objetivo

Antes de rotear, determine de forma compacta:

```text
Resultado: o que precisa existir, mudar, ser entendido ou decidido?
Entregável: resposta, análise, diff, plano, documento ou ação?
Contexto: quais arquivos, regras e evidências já estão disponíveis?
Restrições: escopo, compatibilidade, segurança, prazo e preferências?
Sucesso: qual observação prova que terminou?
Ambiguidade: falta algo que mudaria materialmente o resultado?
```

Use contexto, código e documentação antes de perguntar para eliminar dúvidas factuais. Não use essa
evidência para decidir intenção de produto. Pergunte quando a resposta muda requisito, escopo, UX,
arquitetura, dados, segurança, custo, autoridade, aceite ou solução — o instrumento dessa pergunta é
a `pelizzai-interview-me`. Faça **uma pergunta por vez**, na ordem de dependência; ofereça 2–3 opções
reais quando isso ajudar e marque a melhor recomendação com motivo curto. Não adote uma suposição de
produto para “destravar” o trabalho. Uma escolha reversível só pode ser aplicada mecanicamente quando
já está contida em spec/plano ratificado ou foi explicitamente delegada pelo usuário. A linha
`Ambiguidade` acima alimenta a análise do router.

Quando o usuário parecer não-técnico, ou a intenção admitir ≥2 leituras materialmente diferentes,
**sinalize** isso ao router (`audience` e leituras em aberto). O router reapresenta o entendimento no
Gate de kickoff; depois, a descoberta resolve cada decisão dependente uma por vez.

## Limite de autoridade

```text
O harness decide:
- classificação, técnica de reasoning, ordem de investigação, evidência e recomendação.

O usuário decide:
- o que o produto deve fazer e para quem;
- requisitos, escopo, UX, arquitetura, dados, segurança, custo e risco aceito;
- critérios de aceite e dispensas de spec/plano/documentação;
- isolamento, modo de execução, commits e efeitos externos.

O executor decide sozinho apenas:
- passos mecânicos, locais e reversíveis já cobertos por uma decisão ratificada.
```

Lacuna que cai no bloco do usuário é **tampada com a `pelizzai-interview-me`** — no design, no plano
e também no meio da execução, quando o trabalho revela uma decisão que a spec ou o plano não cobre.
Preenchê-la por default, convenção, Context7 ou “inferência razoável” é violação, mesmo quando a
escolha parece óbvia e reversível.

Context7 é a fonte técnica preferencial quando biblioteca, framework, API, serviço, ferramenta,
versão ou capacidade externa influencia a tarefa. Inspecione primeiro manifests, lockfiles,
configuração e código para descobrir a versão real; consulte Context7 cedo o bastante para eliminar
dúvidas factuais e melhorar a rota, as opções e as perguntas. Em greenfield, ele pode informar a
análise técnica inicial antes do kickoff; em projeto existente, deve ser combinado com o
comportamento observado no repo. Se não estiver disponível, use documentação oficial atual e
declare a limitação. Evidência técnica fundamenta a recomendação; nunca ratifica decisão em nome do
usuário.

## Camada global de preferências

Use `pelizzai-preferences` como camada global quando a tarefa envolver comunicação, engenharia, código, validação, segurança, documentação, portabilidade ou decisões de execução. Ela não substitui skills específicas; ela define o **piso de comportamento**. Regras do usuário, `CLAUDE.md`/`AGENTS.md`, skills de domínio e instruções de uma skill especializada continuam tendo prioridade.

Não acione `pelizzai-preferences` para tarefas triviais que possam ser respondidas diretamente sem risco ou contexto de projeto. Para qualquer tarefa não trivial, considere-a junto do roteamento principal — ela acompanha o fluxo até a validação final.

## Camadas do harness

```text
core
→ router: effect + intenção + risco + incerteza + superfícies
→ uma head skill
→ overlays necessários
→ execução e quality gates proporcionais
→ Verification sela o resultado
→ Finish integra sem alterá-lo

em qualquer ponto, lacuna material → pelizzai-interview-me (uma pergunta por vez) → retoma a fase
```

### Head skills

| Intenção | Head skill |
| --- | --- |
| Bootstrap/remapeamento autorizado | `pelizzai-audit` |
| Produto/projeto greenfield ou feature/refactor/infra com decisão de design | `pelizzai-brainstorming` |
| Plano/design já claro | `pelizzai-writing-plans` ou `pelizzai-execution-plans` |
| Bug/comportamento inesperado | `pelizzai-debugging` |
| Ajuste local sem nova regra/contrato | `pelizzai-quick-fix` |
| Review de diff/branch/PR | `pelizzai-review` |
| Revisão arquitetural codebase-wide | `pelizzai-improving-architecture` |
| Conflito Git | `pelizzai-resolving-merge-conflicts` |
| Divergência state × Git | `pelizzai-recovery` |

### Overlays

Overlays não substituem a head skill:

- UI/UX/CSS/componente/tela → `pelizzai-frontend`;
- auth/input/SQL/upload/segredo/dependência/superfície sensível → `pelizzai-oswap` no review;
- padrões do projeto → skills de domínio do catálogo (em dúvida se uma skill de domínio se aplica à tarefa, inclua-a: o custo de incluir é menor que o de ignorar uma regra do projeto);
- documentação humana nova → `pelizzai-documenting-features` quando fizer parte do escopo.

`pelizzai-preferences` não é overlay opcional: é o piso de comportamento descrito acima e acompanha toda tarefa não trivial. `pelizzai-reasoning` seleciona heurísticas proporcionais, não adiciona cerimônia por si só.

## Mapa de fluxos do harness

A entrada é sempre esta skill (`pelizzai-core`); depois de entender o objetivo, o `pelizzai-router` orquestra. Na primeira interação de um projeto consumidor (ou ao digitar **"bootstrap"**), a `pelizzai-audit` mapeia o projeto e cria as skills de domínio antes de qualquer tarefa. Pergunta **puramente conceitual** não dispara o bootstrap — a `pelizzai-audit` só entra quando a resposta exigir tocar ou entender o projeto. No repo-fonte (sentinela `scripts/pelizzai-source-repo.txt`) não existe catálogo consumidor: o ramo de bootstrap não se aplica.

```mermaid
flowchart TD
    U(["Mensagem do usuario"]) --> P["pelizzai-core: exigir skill antes de responder"]
    P --> G["Entender o objetivo e classificar o efeito"]
    G --> CONC{"Pergunta puramente<br/>conceitual?"}
    CONC -- "Sim" --> ANSC["Responder direto<br/>sem bootstrap"]
    CONC -- "Nao" --> RT["pelizzai-router: effect, intencao, risco,<br/>incerteza e superficies"]
    RT --> BOOT{"Harness inicializado?<br/>pelizzai/domain-skills.md existe?"}
    BOOT -- "Nao / 1a interacao / 'bootstrap'" --> AUD["pelizzai-audit: mapeia projeto/workspace,<br/>MCPs, git/host, cria skills de dominio + docs"]
    AUD --> CLS
    BOOT -- "Sim" --> CLS{"Classificar a intencao e a lane"}
    CLS --> KICK["Gate de kickoff: rota como recomendacao a ratificar"]
    KICK --> HEAD["Uma head skill + overlays obrigatorios"]
    HEAD --> GAP{"Lacuna material<br/>em qualquer fase?"}
    GAP -- "Sim" --> IV["pelizzai-interview-me:<br/>uma pergunta por vez, com recomendacao"]
    IV --> HEAD
    GAP -- "Nao" --> GO["Passo mecanico dentro<br/>do que ja foi ratificado"]
```

O detalhe de cada track (lanes, gates e encadeamentos) mora na `pelizzai-router`.

## Higiene de contexto

A janela de contexto é um recurso da tarefa — administre-a de forma deliberada:

- **Zona segura: ~120k tokens.** Acima disso a qualidade degrada; planeje as fronteiras antes de chegar lá.
- Use contexto contínuo para design → plano; execução recebe briefing fresco por tarefa.
- Handoff bifurca; compact continua o mesmo trabalho — e nunca compacte no meio de uma mutação ou antes de registrar estado verificável.
- Após compaction, valide contra Git o state consumidor ou execution record nativo; não confie na memória.
- Carregue somente as referências/técnicas necessárias à fase atual.

## Como carregar skills

Use o mecanismo nativo da plataforma. Sem carregamento nativo, leia `.agents/skills/<nome>/SKILL.md` (ou o root ativo registrado no projeto) e siga-o — a leitura manual é o mecanismo correto nesses ambientes, nunca uma desculpa para pular a skill. Não leia todo o catálogo preventivamente.

## Anti-padrões

```text
- Resolver manualmente algo que uma skill do harness já cobre.
- Pular uma skill que, já carregada, se aplica ao caso — ou dispensar uma candidata sem justificar a decisão.
- Várias head skills competindo pela mesma tarefa.
- Bootstrap mutável para responder uma análise read-only.
- Perguntar antes de consultar evidência já disponível.
- Tampar lacuna do usuário com Context7, convenção, default ou “inferência razoável” em vez de parar
  na `pelizzai-interview-me`.
- Tratar stack informada como requisitos/aceite suficientes para um projeto greenfield.
- Confundir heurística (OODA/TDD/team) com invariante universal.
- Começar a escrever antes do router e do gate de primeira escrita.
```

## Instrução final

Acione as skills aplicáveis, entenda o objetivo, classifique o efeito e entregue ao router. Use a menor combinação de skills que preserve os invariantes e produza evidência suficiente — menor nunca significa nenhuma.
