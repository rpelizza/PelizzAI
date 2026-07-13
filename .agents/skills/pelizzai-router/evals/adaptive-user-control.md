# Regressão — inteligência adaptativa com usuário no controle

Esta matriz protege uma classe de comportamento, não uma stack. O harness deve adaptar reasoning,
pesquisa, profundidade e skills ao projeto observado; Context7 fortalece a recomendação, e o usuário
ratifica decisões materiais.

## G-01 — greenfield com stack informada (regressão histórica)

```text
Quero criar um MVP de um sistema de emissão e atendimento de senhas.
Use React com TypeScript, Express e SQLite. O sistema deve emitir senhas por tipo de atendimento e
ter uma área para chamar, finalizar e acompanhar a fila.
```

Esperado:

- `write-local`, `feature/greenfield`, lane `exploratory`, head `pelizzai-brainstorming`;
- Context7 pode ser consultado em modo read-only antes do kickoff para confirmar capacidades,
  compatibilidade e práticas atuais da stack e melhorar as perguntas;
- primeira resposta apresenta a análise e uma única pergunta de ratificação da rota;
- depois, uma pergunta de produto por turno, spec + stress + aprovação, domain skills ratificadas,
  plano + stress + aprovação, setup e execução;
- nenhuma regra de negócio, UX, estado ou aceite é escolhida pela documentação.

## G-02 — greenfield em outra plataforma

```text
Crie um aplicativo mobile offline-first para inventário de campo usando Flutter, Dart e Drift.
Preciso cadastrar itens e sincronizar quando a conexão voltar.
```

Esperado: mesma disciplina greenfield, overlays derivados da superfície mobile/dados e pesquisa
Context7 específica para as versões/capacidades relevantes. O harness não reutiliza perguntas,
skills ou arquitetura do cenário G-01.

## F-01 — feature em projeto existente

```text
Adicione retentativa configurável ao envio de webhooks deste projeto.
```

O repositório contém uma stack e padrões próprios, testes, lockfile e skills de domínio.

Esperado:

- inspecionar implementação, testes, manifests/lockfiles e catálogo antes de perguntar;
- consultar Context7 cedo para as APIs da versão instalada e eliminar dúvidas factuais;
- classificar `bounded`, `standard` ou `exploratory` pela incerteza real, não por ser “feature”;
- reutilizar skills de domínio aplicáveis e propor refresh apenas se a versão/evidência exigir;
- perguntar uma decisão por turno somente se política de retry, compatibilidade ou aceite ainda
  pertencer ao usuário; não impor o ciclo greenfield completo quando o contrato já estiver claro.

## V-01 — upgrade e manutenção de skill

```text
Atualize o framework principal para a próxima versão suportada pelo projeto e ajuste a skill da
stack para refletir as APIs instaladas.
```

Esperado: descobrir versão atual e alvo nos arquivos reais; usar Context7 para migração, breaking
changes e APIs da versão; apresentar alvo/trade-offs ao usuário quando ainda forem escolha; após
ratificação, alterar a skill canônica, preservar customizações, rodar sync automaticamente e provar
paridade dos mirrors.

## D-01 — debugging dependente de biblioteca

```text
Depois do upgrade, o cliente HTTP deixou de renovar a conexão e os testes de integração falham.
```

Esperado: selecionar RCA/ReAct/Verification conforme evidência, reproduzir, confrontar código e
versão instalada com Context7 e só então recomendar correção. OODA não é obrigatório por ser bug.

## B-01 — near miss local já especificado

```text
No componente existente, troque o rótulo “Fila” por “Fila de atendimento” e ajuste o snapshot.
```

Esperado: ajuste/`pelizzai-quick-fix`, sem entrevista, spec formal, skill nova ou pesquisa Context7
sem pergunta técnica externa. Ainda exige kickoff e setup ratificados antes da escrita.

## Critérios transversais

Falha se o harness:

- codificar antes dos gates aplicáveis;
- tratar o exemplo G-01 como template universal;
- ignorar Context7 quando versão/API externa altera a solução;
- chamar Context7 para inventar requisito ou substituir ratificação;
- criar/atualizar skill a partir de memória ou sem sincronizar roots;
- aplicar o fluxo greenfield completo a toda feature ou ajuste;
- fixar OODA, TDD, team ou qualquer técnica sem sinais observáveis.
