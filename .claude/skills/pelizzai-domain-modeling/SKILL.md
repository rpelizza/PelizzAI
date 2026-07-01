---
name: pelizzai-domain-modeling
description: Construir e afiar o modelo de domínio do projeto ativamente — fixar terminologia/linguagem ubíqua, registrar uma decisão de arquitetura (ADR), desafiar termos e estressar relações com cenários. Use quando o usuário quer pinar o vocabulário do domínio, registrar uma decisão arquitetural, ou quando outra skill (`pelizzai-brainstorming`, `pelizzai-writing-plans`) precisa manter o modelo de domínio. Apenas LER o glossário não é esta skill (é hábito de qualquer skill) — esta é para quando você está MUDANDO o modelo.
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

## Integração

**Usada por:** `pelizzai-brainstorming` (cristaliza o vocabulário do design), `pelizzai-writing-plans` (as tarefas usam os termos canônicos).

**Combina com:** `pelizzai-interview-me` (a entrevista que expõe a ambiguidade dos termos), `pelizzai-codebase-design` (os módulos são nomeados pelo domínio), `pelizzai-reasoning` (Assumption Tracking / Constraint Satisfaction).
