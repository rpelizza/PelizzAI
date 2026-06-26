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

**No Claude Code**: Use a ferramenta `Skill`. Ao invocar uma skill, o conteúdo dela é carregado e apresentado a você — siga-o diretamente.

**No Codex**: As skills são carregadas nativamente. Siga as instruções apresentadas quando uma skill for ativada.

**No Copilot CLI**: Use a ferramenta `skill`. As habilidades são detectadas automaticamente a partir dos plugins instalados.

**No Gemini CLI**: As habilidades são ativadas por meio da ferramenta `activate_skill`. O Gemini carrega os metadados das skills no início da sessão e ativa o conteúdo completo sob demanda.

**Em outros ambientes**: Consulte a documentação da sua plataforma para saber como ativar e usar skills.

## Entender o objetivo do usuário

Seu principal objetivo é entender o que o usuário deseja alcançar e ajudá-lo a atingir esse objetivo. Para isso, você deve:

1. **Identificar o objetivo do usuário**: Pergunte ou deduza o que o usuário quer alcançar.
2. **Determinar se uma skill é necessária**: Avalie se o objetivo do usuário pode ser melhor atendido com a ajuda de uma skill.
3. **Invocar a skill apropriada**: Se uma skill for necessária, invoque a skill correta antes de fornecer qualquer resposta ou solução.
4. **Fornecer a resposta ou solução**: Após invocar a skill, siga suas instruções para fornecer a resposta ou solução ao usuário.
5. **Evitar respostas diretas sem skill**: Nunca forneça uma resposta direta ao usuário sem primeiro considerar se uma skill é aplicável.
