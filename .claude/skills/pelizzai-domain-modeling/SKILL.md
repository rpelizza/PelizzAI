---
name: pelizzai-domain-modeling
description: Construir e afiar o modelo de domínio do projeto ativamente — fixar terminologia/linguagem ubíqua, registrar uma decisão de arquitetura (ADR), registrar uma rejeição durável (`pelizzai/out-of-scope/`), desafiar termos e estressar relações com cenários. Use quando o usuário quer pinar o vocabulário do domínio, registrar uma decisão arquitetural, registrar que algo NÃO será feito, ou quando outra skill (`pelizzai-brainstorming`, `pelizzai-writing-plans`) precisa manter o modelo de domínio. Apenas LER o glossário não é esta skill (é hábito de qualquer skill) — esta é para quando você está MUDANDO o modelo.
---

# PelizzAI Domain Modeling

Construa e afie o modelo de domínio enquanto projeta — a disciplina **ativa**: desafiar termos, inventar cenários de borda, e escrever o glossário e as decisões no momento em que se cristalizam.

**Anuncie ao iniciar (quando acionada explicitamente):** "Usando a skill PelizzAI Domain Modeling para afiar o modelo de domínio."

## Onde mora o modelo

Toda a documentação do harness vive em `pelizzai/` (ver `pelizzai-audit` → "Padrão de diretório `pelizzai/`"). O modelo de domínio fica em:

```text
- pelizzai/context.md — o GLOSSÁRIO do domínio (e só isso; sem detalhes de implementação, sem virar
  spec nem rascunho). Em multi-contexto, um pelizzai/context-map.md aponta para o glossário de cada
  contexto em pelizzai/context/<nome>.md (ex.: pelizzai/context/ordering.md, pelizzai/context/billing.md).
- pelizzai/adr/ — Architecture Decision Records (decisões de arquitetura), numerados.
- pelizzai/out-of-scope/ — decisões de NÃO fazer, um arquivo por conceito (ver seção abaixo).
Crie os arquivos de forma preguiçosa — só quando houver algo a escrever.
```

## Durante a sessão

```text
- Desafie contra o glossário: termo que conflita com o pelizzai/context.md → aponte na hora. "Seu glossário define
  'cancelamento' como X, mas você parece dizer Y — qual é?"
- Afie linguagem vaga: termo sobrecarregado → proponha o termo canônico preciso. "'conta' = Customer ou User?"
- Discuta cenários concretos: estresse as relações com cenários específicos que forçam precisão nas fronteiras.
- Cruze com o código: o que o usuário diz bate com o código? Contradição → traga à tona.
- Atualize o pelizzai/context.md inline: termo resolvido → escreva ali na hora, não acumule.
- Ofereça ADR com parcimônia: só quando os TRÊS forem verdade — (1) difícil de reverter, (2) surpreendente
  sem contexto, (3) resultado de um trade-off real. Faltando qualquer um, pule o ADR.
```

## `pelizzai/out-of-scope/` — a KB de rejeições

O ADR registra decisões arquiteturais TOMADAS; `pelizzai/out-of-scope/` registra o que foi deliberadamente REJEITADO — os nãos explícitos valem tanto quanto os sins. Criação preguiçosa: só quando uma rejeição durável acontecer.

```text
- Um arquivo por CONCEITO (kebab-case, ex.: pelizzai/out-of-scope/dark-mode.md), não por
  pedido — pedidos diferentes do mesmo conceito atualizam o MESMO arquivo.
- Razão obrigatoriamente DURÁVEL: registre o porquê que continuará válido ("conflita com o
  modelo de licenciamento", "dobra a superfície de suporte"). "Estamos ocupados" é DEFERRAL,
  não rejeição — não entra na KB.
- Anti-envenenamento: o que JÁ EXISTE implementado NUNCA entra na KB — aponte onde vive no
  código. Uma "rejeição" de algo que existe envenena o dedup com falsos nãos.
- Matching por SIMILARIDADE de conceito, não por keyword: "tema noturno" casa com
  dark-mode.md. Quem consulta compara conceitos, não strings.
```

Consultada por `pelizzai-router` (Passo 0 — sugestão que soa recorrente) e `pelizzai-brainstorming` (exploração de contexto), antes de re-litigar um não já decidido.

## Integração

**Usada por:** `pelizzai-brainstorming` (cristaliza o vocabulário do design; consulta out-of-scope/ antes de propor abordagens), `pelizzai-writing-plans` (as tarefas usam os termos canônicos), `pelizzai-router` (consulta out-of-scope/ diante de sugestão recorrente), `pelizzai-improving-architecture` (registra aqui — ADR ou out-of-scope/ — os candidatos rejeitados com razão durável).

**Combina com:** `pelizzai-interview-me` (a entrevista que expõe a ambiguidade dos termos), `pelizzai-codebase-design` (os módulos são nomeados pelo domínio), `pelizzai-reasoning` (Assumption Tracking / Constraint Satisfaction).
