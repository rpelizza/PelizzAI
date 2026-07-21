---
name: pelizzai-documenting-features
description: Overlay de documentação HUMANA do contrato estável de uma feature, como rotas, comandos, APIs e telas. Use quando docs fazem parte do escopo, o diff cria uma superfície estável que precisa ser explicada ou o usuário pede documentação de uso. Entra antes do review final e de validated-head; a finish-task não a executa (só sinaliza a lacuna como rede de segurança) e ela não se aplica a specs/planos/ADRs do harness.
---

# PelizzAI Documenting Features

## Objetivo

Explicar para humanos o contrato observável e durável da entrega, sem narrar detalhes internos que
envelhecem no próximo refactor.

**Anuncie:** "Usando a skill PelizzAI Documenting Features para documentar o contrato da feature."

## Onde

Siga a estrutura de docs existente, seu índice e gerador. Sem convenção, use
`docs/<area>/<feature>.md`. Docs humanas não vivem em `pelizzai/`; specs, planos e ADRs são
artefatos de processo.

## Conteúdo proporcional

Inclua somente se aplicável:

```markdown
# <Feature>

## Propósito
Problema e público.

## Uso
Rotas, comandos, APIs ou fluxo de tela com exemplo real.

## Contrato
Inputs, outputs, estados, permissões e compatibilidade.

## Limites e diagnóstico
Pré-condições, erros relevantes e como observar/corrigir.
```

- Documente comportamento público, não funções/arquivos internos.
- Use nomes, exemplos e saídas reais; não invente placeholder/dado de produto.
- Atualize índice/README somente quando a convenção exigir.
- Não crie um documento separado se comentário, schema ou página existente é o local canônico.

## Validação e lifecycle

Valide links, exemplos, snippets e build/render aplicáveis. A doc é conteúdo da entrega: consolide
pela commit-strategy da head skill **antes** do review final e de `validated-head`. Qualquer
correção reabre as provas afetadas.

A doc entra em **commit próprio** — `docs(<feature>): <descrição>` —, nunca misturada ao commit de
código: separar doc de código é higiene de histórico, não preferência. Em `commit-strategy:
granular` é o commit definitivo da doc; em `squash-final` é o WIP `docs(...)` que a head skill
consolida junto aos demais **antes** do review final. Vale o gate de branch protegida de
`pelizzai-starting-branch`: nunca commite em `main`/`master`/`develop`/`dev` nem no default real
descoberto.

Finish-task nunca gera nem corrige documentação: depois do seal é tarde para escrever ali. O que ela
faz é a checagem-rede — se uma superfície documentável passou sem esta skill, ela oferece **uma vez**
devolver a entrega ao ciclo (o seal cai e a doc volta a ser conteúdo validado, com review final
refeito). Recusa informada entrega sem doc; a rede não bloqueia, e também não substitui o caminho
normal, que é rodar aqui antes do review final.

## Red flags

```text
- Documentar implementação volátil em vez do contrato.
- Criar docs humanas dentro de pelizzai/.
- Exemplo que não foi validado.
- Duplicar documentação canônica já existente.
- Deixar a doc sem commit próprio: dangling na working tree, ou diluída no commit de código.
- Criá-la depois do seal.
```

## Integração

Router/plano registram este overlay; execution-plans o executa antes do review final. Combine com
skills de domínio e `pelizzai-writing-clearly-and-concisely` quando isso mudar a redação.
