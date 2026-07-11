---
name: pelizzai-audit
description: Mapeia um projeto para o harness PelizzAI em dois modos. Use `scan-only` para análises/reviews read-only sem criar arquivos; use `bootstrap-write` quando o usuário pedir bootstrap/remapeamento persistente ou autorizar preparar catálogo, profile e skills de domínio. Não execute bootstrap consumidor no repo-fonte do próprio PelizzAI.
---

# PelizzAI Audit

## Objetivo

Descobrir apenas o contexto que muda decisões do agente e, quando autorizado, materializá-lo num bootstrap pequeno, versionável e portátil.

**Anuncie:** "Usando a skill PelizzAI Audit em modo `<scan-only|bootstrap-write>` para mapear o projeto proporcionalmente."

## Escolher o modo

| Modo | Gatilho | Pode escrever? |
| --- | --- | --- |
| `scan-only` | analisar, explicar, revisar, diagnosticar; tarefa mutável ainda sem autorização de bootstrap | Não. Nem state, branch, profile, catálogo, ledger, hook ou skill. |
| `bootstrap-write` | usuário disse `bootstrap`/`reinicializar`, ou aprovou a proposta após scan | Sim, dentro da task branch criada antes da primeira escrita. |

Um pedido read-only nunca vira bootstrap mutável só porque `pelizzai/domain-skills.md` não existe.

## Source mode

Se existirem `.claude/skills/pelizzai-core/SKILL.md`, `scripts/pelizzai-core-skills.txt` e `scripts/sync-harness.ps1`, trate o projeto como repo-fonte PelizzAI. Não crie `pelizzai/` consumidor; faça apenas o scan necessário à tarefa.

## Profundidade proporcional

```text
projeto pequeno/stack simples
→ inspeção inline focada.

monorepo ou múltiplas frentes independentes
→ subagents/time read-only quando reduzirem latência ou aumentarem cobertura.

projeto novo/vazio
→ entender produto e stack pretendida; não inventar padrões ainda inexistentes.
```

Team não é default. Use-o somente quando as frentes são independentes e a síntese vale o custo.

## Scan-only

Responda às perguntas relevantes, sem transformar o scan em inventário universal:

```text
Estrutura: repo único, monorepo ou workspace de múltiplos repos?
Stack: manifests, lockfiles, frameworks, runtime, banco e versões-chave?
Execução: comandos reais de test/build/lint/dev e seus diretórios?
Convenções: instruções, linters, testes, commits, design system e padrões repetidos?
Git: branch atual, default real, remotos/provider, CI e working tree?
Skills: roots instalados, domain skills existentes e catálogo?
Ferramentas: MCPs/conectores que realmente mudam esta tarefa?
```

Separe fatos observados de inferências. Não escreva relatório genérico se o pedido exige apenas uma resposta localizada.

Ao terminar scan-only:

- entregue a análise solicitada;
- se uma tarefa mutável precisa de bootstrap, proponha o menor conjunto de artefatos/skills e peça consentimento uma vez;
- não crie placeholders para "preparar depois".

## Bootstrap-write

### 1. Isolar antes de escrever

Se houver Git, invoque `pelizzai-starting-branch` e crie uma task branch como
`chore/bootstrap-harness` antes de qualquer arquivo. Se não houver Git, ofereça `git init`; se o
usuário recusar, explique que não haverá histórico/rollback e prossiga somente com autorização.

O bootstrap é uma transação própria. Seus artefatos precisam estar commitados/integrados ou permanecer na mesma task branch antes de um worktree de feature depender deles.

### 2. Detectar skill roots

Registre no `pelizzai/profile.md` os roots realmente instalados:

```text
source-mode: false
skill-roots:
  - .claude/skills   # se existir/for usado
  - .agents/skills   # se existir/for usado
canonical-skill-root: <root ativo>
```

`pelizzai-writing-skills` escreve domain skills no root ativo; se ambos estiverem instalados, mantém cópias byte a byte e verifica paridade.

### 3. Selecionar o menor conjunto de domain skills

Crie uma candidata somente quando todos forem verdadeiros:

```text
- existe padrão/invariante recorrente e específico deste projeto;
- ele não está suficientemente coberto por instruções/skill existentes;
- carregá-lo mudaria uma decisão ou evitaria erro real do agente;
- há evidência no repo, design aprovado ou documentação oficial.
```

Zero domain skills é resultado válido. Em muitos projetos, 1–3 bastam. Não crie uma skill por pasta, ferramenta ou responsabilidade genérica.

Apresente as candidatas (nome + erro que evitam) e aguarde confirmação antes de redigi-las. Para stack/lib externa, fundamente na documentação oficial atual; `context7` é preferencial quando disponível, não um bloqueio para regras internas observadas no repo.

### 4. Criar os artefatos

O bootstrap persistente deixa:

- `pelizzai/domain-skills.md` — catálogo, inclusive `_nenhuma por enquanto_` quando aplicável;
- `pelizzai/data/review-domain-skills.md` — ledger semeado com a data/HEAD atuais;
- `pelizzai/profile.md` — comandos reais, package manager, stack baseline e skill roots;
- `pelizzai/.gitignore` — proteção scoped dos efêmeros.

Conteúdo obrigatório de `pelizzai/.gitignore`:

```gitignore
data/.cadence-state.json
data/handoffs/
data/mockups/
data/reports/
```

Verifique com `git check-ignore` usando arquivos de prova temporários; remova as provas depois.

Crie sob demanda, não no bootstrap: `context.md`, `adr/`, `out-of-scope/`, `specs/`, `plans/` e diretórios efêmeros.

### 5. Projeto novo

Sem código/padrões, use `pelizzai-brainstorming` no modo proporcional para aprovar o design. Depois crie apenas domain skills justificadas pelo design; não escreva plano de implementação automaticamente se o usuário pediu apenas bootstrap.

### 6. Hooks e integrações

Hooks Claude são opt-in e separados:

- cadence: lembrete não bloqueante;
- guardrails: rede de segurança Git;
- SessionStart: entrada + tarefa ativa.

Explique o efeito de cada um e só edite settings após confirmação. Recomende provider/MCP apenas quando agregar ao projeto; não pesquise catálogo de ferramentas por rotina.

### 7. Validar e fechar

Antes de declarar bootstrap pronto:

```text
[ ] catálogo existe e corresponde às skills reais;
[ ] ledger/profile não têm placeholders;
[ ] comandos vieram de manifests/scripts reais;
[ ] skill roots e paridade foram verificados;
[ ] efêmeros passam em git check-ignore;
[ ] diff contém somente artefatos aprovados;
```

Revise o diff inteiro em perfil `combined` (ou `split` se hooks/settings/segurança elevarem o risco),
commite os artefatos aprovados com paths exatos e só então rode
`pelizzai-verification-before-completion` contra esse HEAD. Após gravar `validated-head`, feche a
transação via `pelizzai-finish-task`. Não deixe bootstrap não commitado nem tente fazer a
finish-task consolidá-lo.

## Estado parcial

- catálogo existe, ledger ausente → proponha/repare somente o ledger em modo write;
- skill existe fora do catálogo → catalogue após confirmar origem/conteúdo;
- profile desatualizado → atualize apenas os campos afetados;
- read-only → apenas reporte a inconsistência.

## Layout canônico

```text
pelizzai/
├── .gitignore
├── domain-skills.md
├── profile.md
├── context.md | context/           sob demanda
├── adr/ | out-of-scope/            sob demanda
├── specs/ | plans/                 sob demanda
└── data/
    ├── state.md                    versionado
    ├── review-domain-skills.md     versionado
    ├── .cadence-state.json         ignorado
    ├── handoffs/                   ignorado
    ├── mockups/                    ignorado
    └── reports/                    ignorado
```

Em workspace com múltiplos repositórios, não finja que um state escalar cobre todos: faça bootstrap por repo ou declare explicitamente a raiz dona dos artefatos.

## Anti-padrões

```text
- Mudar arquivos em scan-only.
- Reexecutar bootstrap em toda nova sessão.
- Criar o "máximo" de domain skills.
- Usar team num repo que uma inspeção focada resolve.
- Criar profile com comandos chutados.
- Gravar skill apenas em .claude quando a plataforma ativa usa .agents (ou vice-versa).
- Declarar diretório gitignored sem provar no projeto consumidor.
- Deixar o bootstrap solto em main ou invisível ao worktree seguinte.
```

## Integração

Usa `pelizzai-starting-branch` e `pelizzai-finish-task` somente em `bootstrap-write`; `pelizzai-writing-skills` cria o conjunto mínimo de domain skills; `pelizzai-brainstorming` entra apenas no ramo de projeto novo/incerto.
