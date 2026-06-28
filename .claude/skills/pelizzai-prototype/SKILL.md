---
name: pelizzai-prototype
description: Construir um protótipo descartável para amadurecer um design — um app de terminal interativo para perguntas de estado/lógica de negócio, ou várias variações radicalmente diferentes de UI numa única rota, alternáveis. Use quando o usuário quer explorar "esse modelo de estado/lógica faz sentido?" ou "como isso deveria parecer?" antes de comprometer-se com a implementação real.
---

# PelizzAI Prototype

Um protótipo é **código descartável que responde a uma pergunta**. A pergunta decide o formato.

**Anuncie ao iniciar:** "Usando a skill Pelizzai Prototype para um protótipo descartável que responde a uma pergunta de design."

## Escolha o ramo

Identifique qual pergunta está sendo respondida (pelo pedido, pelo código ao redor, ou perguntando ao usuário):

```text
- "Esse modelo de estado/lógica faz sentido?" → app de terminal pequeno e interativo que empurra a máquina
  de estados por casos difíceis de raciocinar no papel.
- "Como isso deveria parecer?" → várias variações radicalmente diferentes de UI numa ÚNICA rota, alternáveis
  por um search param na URL e uma barra flutuante (valide a UI rodando via pelizzai-frontend).
```

Os dois ramos produzem artefatos bem diferentes — errar o ramo desperdiça o protótipo. Se ambíguo e o usuário indisponível, escolha pelo código ao redor (módulo de backend → lógica; página/componente → UI) e declare a suposição no topo.

## Regras (valem para os dois ramos)

```text
1. Descartável desde o dia 1, e marcado como tal. Coloque perto de onde será usado, mas nomeie de forma que
   qualquer um veja que é protótipo, não produção.
2. Um comando para rodar (o task runner que o projeto já usa).
3. Sem persistência por padrão — estado em memória. Persistência é o que o protótipo CHECA, não algo de que depende.
4. Sem polish — sem testes, sem tratamento de erro além do necessário para rodar, sem abstrações.
5. Exponha o estado — depois de cada ação (lógica) ou em cada troca de variante (UI), mostre o estado relevante.
6. Apague ou absorva quando terminar — delete, ou dobre a decisão validada no código real; não deixe apodrecer no repo.
```

## Quando terminar

A **resposta** é a única coisa que vale guardar de um protótipo. Capture-a em algo durável **dentro de `pelizzai/`** — um ADR em `pelizzai/adr/` (via `pelizzai-domain-modeling`) ou na mensagem de commit — junto com a pergunta que ela responde. Depois, apague ou absorva o protótipo (o código descartável em si pode ter um `NOTES.md` ao lado até ser deletado).

## Integração

**Combina com:** `pelizzai-brainstorming` (explorar antes de comprometer o design), `pelizzai-frontend` (validar as variações de UI rodando), `pelizzai-reasoning` (Tree of Thoughts para explorar caminhos), `pelizzai-domain-modeling` (registrar a resposta como ADR).
