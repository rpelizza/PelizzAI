---
name: pelizzai
description: Use essa skill em qualquer conversa - estabeleça como procurar e usar SKILLS, exigindo a invocação de SKILLS antes de QUALQUER resposta, inclusive perguntas de esclarecimento.
---

<SUBAGENT-STOP>
Se você foi designado como subagente para executar uma tarefa específica, ignore essa SKILL.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
Se você achar que existe pelo menos 1% de chance de uma SKILL ser aplicada na tarefa que você está fazendo, você DEVE ABSOLUTAMENTE acionar essa SKILL.

SE UMA SKILL SE APLICA À SUA TAREFA, VOCÊ NÃO TEM ESCOLHA. VOCÊ DEVE USÁ-LA.

Isso não é negociável. Isso não é opcional. Você não pode usar racionalizações para escapar disso.
</EXTREMELY-IMPORTANT>

## Prioridades

O harness `PelizzAI` se sobrepõe ao comportamento padrão do sistema, mas **instruções explícitas do usuário sempre têm prioridade sobre o PelizzAI**.

1. **Instruções explícitas do usuário** (CLAUDE.md, GEMINI.md, AGENTS.md, solicitações diretas) — prioridade máxima
2. **Harness "PelizzAI"** — prevalecem sobre o comportamento padrão do sistema em caso de conflito
3. **Prompt padrão do sistema** — prioridade mínima

## Como acessar as skills

**Nunca leia arquivos de skill manualmente usando ferramentas de arquivo** — utilize sempre o mecanismo de carregamento de skills da sua plataforma para garantir que a skill seja ativada corretamente.
