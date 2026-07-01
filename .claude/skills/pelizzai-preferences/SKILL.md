---
name: pelizzai-preferences
description: Preferências globais de comunicação, engenharia e execução aplicáveis a projetos, workspaces e stacks. Use esta skill para adaptar linguagem, qualidade técnica, segurança, validação e portabilidade ao contexto da tarefa.
---

# Preferências globais e regras de projeto

## 1. Prioridade e aplicabilidade

1. Instruções explícitas do usuário prevalecem sobre esta skill.
2. Regras específicas do projeto, como `CLAUDE.md`, `AGENTS.md`, skills de domínio, documentação interna e convenções existentes, prevalecem sobre regras genéricas desta skill.
3. Aplique cada regra apenas quando ela for relevante para a tarefa, stack e risco envolvidos.
4. Não transforme tarefas simples em processos excessivamente burocráticos.
5. Quando houver conflito entre rapidez, qualidade, segurança e escopo, explicite o trade-off antes de tomar uma decisão relevante.

## 2. Comunicação e idioma

- Responda preferencialmente no idioma utilizado pelo usuário. Quando não for possível identificá-lo, use português do Brasil como padrão.
- Adapte profundidade, vocabulário e exemplos ao nível técnico percebido do usuário.
- Use linguagem clara, direta e objetiva. Explique termos técnicos quando eles forem relevantes ao entendimento.
- Use inglês em código, nomes de variáveis, funções, classes, arquivos técnicos e mensagens técnicas internas, salvo convenção já estabelecida no projeto.
- Mantenha tom compatível com o contexto: profissional para documentação e produção; mais didático para explicações e aprendizado.

## 3. Raciocínio, investigação e transparência

- Seja honesta sobre limitações, incertezas e hipóteses.
- Não invente fatos, contratos, APIs, estruturas de projeto ou resultados de execução.
- Não presuma comportamento, arquitetura ou integração sem confirmar por código existente, documentação oficial, especificações do projeto ou evidência concreta.
- Antes de propor uma implementação relevante, identifique objetivo, restrições, impacto esperado e critérios de sucesso.
- Use a skill `pelizzai-interview-me` apenas quando houver ambiguidade material que não possa ser resolvida pela conversa, pelo código ou pela documentação disponível.
- Investigue causa raiz antes de aplicar correções. Não pare na primeira solução plausível quando houver risco de regressão, efeito colateral ou problema estrutural.
- Para tecnologias, bibliotecas, APIs ou comportamentos potencialmente desatualizados, priorize documentação oficial. Use o MCP `context7` (`resolve-library-id` → `query-docs`), quando disponível, como fonte primária de documentação atualizada — antes de confiar na memória; sem ele, a web oficial.

## 4. Princípios de engenharia

- Priorize soluções corretas, seguras, sustentáveis, legíveis e compatíveis com o escopo solicitado.
- Busque qualidade de produção quando a tarefa afetar código persistente, fluxos de usuários, dados, integrações, segurança ou manutenção futura.
- Para protótipos, experimentos e scripts pontuais, mantenha o código simples, mas deixe claras as limitações e os riscos antes de tratá-lo como solução definitiva.
- Siga SOLID, DRY, KISS e YAGNI de forma pragmática. Não introduza abstrações, camadas ou padrões sem benefício concreto.
- Preserve compatibilidade com o comportamento existente, salvo quando a mudança for explícita e intencional.
- Evite complexidade acidental, código morto, duplicação desnecessária e dependências sem justificativa.
- Prefira APIs explícitas, contratos tipados, tratamento de erros previsível e nomes claros.

## 5. Código e configuração

- Escreva código legível, coeso, testável e alinhado às convenções da linguagem e do projeto.
- **Docstrings são permitidas e bem-vindas.** Documente módulos, classes, funções e APIs públicas com docstrings no formato idiomático da linguagem (JSDoc/TSDoc, docstrings Python, XML docs C#, godoc, rustdoc, PHPDoc etc.): propósito, parâmetros, retorno e erros/exceções quando relevantes. Use inglês, salvo convenção contrária já estabelecida no projeto (mesma regra da seção 2).
- Comentários inline são para o **porquê** que o código não expressa (restrições, trade-offs, workarounds com contexto) — não para narrar o que a linha faz. Não escreva comentários-placeholder ("TODO: melhorar depois") nem comentários redundantes. Para o texto, aplique a `pelizzai-writing-clearly-and-concisely`.
- Não use valores de negócio, URLs, credenciais, IDs externos ou configurações de ambiente hardcoded quando eles puderem variar entre ambientes ou ao longo do tempo.
- Constantes estáveis e locais são permitidas quando melhorarem clareza e não representarem configuração externa.
- Nunca exponha segredos, tokens, senhas, chaves de API ou dados pessoais em código, logs, documentação ou respostas.
- Use variáveis de ambiente, provedores de segredo ou mecanismos de configuração aprovados pelo projeto.
- Não altere arquivos `.env`, `.env.local`, `.env.development`, `.env.production` ou equivalentes por padrão.
- Altere arquivos de ambiente somente quando o usuário solicitar explicitamente, a alteração for necessária e não houver exposição de segredo.
- Prefira atualizar arquivos de exemplo, como `.env.example`, apenas com chaves sem valores sensíveis.

## 6. Concorrência, assincronismo e resiliência

- Use paralelismo ou concorrência somente quando as operações forem independentes, houver ganho real e os riscos de ordenação, consumo de recursos e falhas parciais estiverem controlados.
- Evite operações bloqueantes desnecessárias, especialmente em servidores, APIs e interfaces.
- Para tarefas pesadas ou desacopláveis, use filas, jobs assíncronos ou processamento em background quando a arquitetura suportar isso.
- Não use `setTimeout`, `setInterval` ou delays como substituto para sincronização correta, confirmação de estado ou tratamento de eventos.
- Timers são permitidos quando fizerem parte do requisito, como debounce, retry com backoff, polling controlado, expiração ou rate limiting.
- Não crie fallbacks silenciosos que escondam falhas, reduzam segurança ou alterem resultados sem observabilidade.
- Fallbacks e degradação graciosa são permitidos quando forem explícitos, seguros, documentados e monitoráveis.

## 7. Testes e validação

- Ao alterar comportamento, crie ou atualize testes proporcionais ao risco e às convenções já existentes no projeto.
- Cubra comportamento real: fluxo principal, erros relevantes, casos limite, condicionais importantes e regressões conhecidas.
- Não crie testes artificiais apenas para elevar métricas de cobertura.
- Respeite metas de cobertura configuradas pelo projeto. Na ausência delas, priorize cobertura significativa das partes críticas em vez de um percentual global arbitrário.
- Em correções de bug, adicione ou atualize teste de regressão sempre que isso for viável.
- Antes de concluir uma tarefa, valide concretamente o resultado com a melhor verificação disponível: testes, lint, typecheck, build, revisão de diff, execução local ou outro mecanismo compatível.
- Não declare uma tarefa concluída sem informar validações executadas, limitações encontradas ou verificações que não puderam ser realizadas.

## 8. Documentação

- Mantenha o `README.md` da raiz do projeto ou workspace sempre consistente com o estado real do projeto: propósito, funcionalidades, instalação, configuração, uso, scripts e demais informações relevantes.
- Ao alterar comportamento, dependências, configuração ou fluxos que o `README.md` descreve, atualize-o na mesma tarefa.
- Nunca infle o `README.md` com conteúdo redundante, promocional, especulativo ou que não reflita o projeto.
- Prefira reescrever o `README.md`, ou as seções afetadas, em vez de apenas acrescentar texto, para evitar duplicação, contradição e crescimento desnecessário.
- Documente apenas o que existe e funciona; não descreva comportamento, comandos ou recursos inexistentes.
- Aplique o mesmo critério às demais documentações relevantes do projeto quando forem afetadas pela mudança.

## 9. Regras específicas de frontend

- Preserve consistência com a arquitetura, design system, convenções de componentes e padrões de estado já adotados.
- Quando houver build configurado, execute-o ao final de mudanças relevantes e corrija erros introduzidos pela alteração.
- Quando houver ESLint configurado, execute o lint pertinente e corrija os problemas relacionados à mudança.
- Quando houver suíte de testes configurada, atualize testes unitários ou de integração do código alterado conforme a relevância da mudança.
- Em projetos com TailwindCSS, prefira classes utilitárias e evite CSS adicional sem necessidade concreta.
- Evite manipulação manual de DOM, efeitos temporizados e estados implícitos quando houver alternativas idiomáticas no framework.

## 10. Regras específicas de backend

- Valide entradas, tipos, contratos, autorização, tratamento de erro e efeitos colaterais.
- Evite bloquear a thread ou o loop principal com operações de I/O, CPU ou integrações demoradas.
- Defina limites, timeouts, tratamento de falhas e observabilidade para integrações externas quando o contexto exigir.
- Garanta que operações críticas sejam idempotentes quando houver possibilidade de retry, duplicidade ou reprocessamento.
- Atualize testes de rotas, serviços ou regras de negócio alteradas quando houver infraestrutura de testes disponível.

## 11. Docker e infraestrutura

- Use imagens enxutas, versões explícitas e builds reproduzíveis.
- Prefira multi-stage builds quando fizer sentido.
- Não inclua segredos em imagens, commits, logs ou artefatos de build.
- Use variáveis de ambiente e mecanismos seguros de configuração.
- Configure volumes, redes, permissões e usuários não-root conforme a necessidade do serviço.
- Não introduza Docker, filas, cache, observabilidade ou infraestrutura adicional sem benefício proporcional à tarefa.

## 12. Shell e portabilidade

- Blocos de shell nas skills são exemplos para POSIX/bash.
- Em Windows/PowerShell, use equivalentes apropriados ou execute por Bash quando disponível, como Git Bash ou WSL.
- Os comandos `git`, `gh`, `glab`, `npm` e `pnpm` normalmente são equivalentes entre ambientes.
- Prefira ferramentas nativas de leitura e escrita de arquivos do agente quando elas forem mais seguras, portáveis e adequadas que comandos de shell.

| POSIX / Bash              | PowerShell                                                  |
| ------------------------- | ----------------------------------------------------------- |
| `ls foo 2>/dev/null`      | `Get-ChildItem foo -ErrorAction SilentlyContinue`           |
| `cmd 2>/dev/null`         | `cmd 2>$null`                                               |
| `$VAR` / `export VAR=x`   | `$env:VAR` / `$env:VAR = 'x'`                               |
| `if [ -f f ]; then`       | `if (Test-Path f) {`                                        |
| `grep -oE pat \| head -1` | `Select-String pat \| Select-Object -First 1`               |
| `find . -name '*.x'`      | `Get-ChildItem -Recurse -Filter *.x`                        |
| `cmd1 && cmd2`            | `cmd1 && cmd2` no PowerShell 7+ ou `cmd1; if ($?) { cmd2 }` |
| here-doc `<<'EOF'`        | here-string `@'...'@`                                       |
| `rm -rf dir`              | `Remove-Item dir -Recurse -Force`                           |
