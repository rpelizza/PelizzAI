# Proposal Stress (Premortem de escopo)

## Objetivo

Use Proposal Stress para **estressar um pedido novo antes de rotear**: expor as premissas, as lacunas
materiais, os riscos e as alternativas de que a solução dependeria, produzindo a **Análise da
proposta** que o `pelizzai-router` apresenta ao usuário. É a aplicação de
[Assumption Tracking](assumption-tracking.md) com uma lente de premortem de escopo — não uma técnica
nova, mas a rotina padronizada sobre a mesma máquina de premissas.

> A Análise da proposta é resultado apresentado, não pergunta; ela alimenta o gate de descoberta
> quando há lacuna material.

O ganho recuperado é comportamental: antes de agir, o harness volta a expor premissas/lacunas/riscos/
alternativas em vez de escolher em silêncio uma leitura de escopo/UX/arquitetura/segurança e
prosseguir.

## Quando usar

Produza a Análise da proposta quando o pedido tiver **efeito mutável não-trivial** com incerteza
material:

```text
- feature nova ou alterada;
- refactor com contrato/fronteira em jogo;
- mudança estrutural, de dados ou de segurança;
- qualquer pedido em que uma decisão de escopo/UX/arquitetura ainda está em aberto.
```

## Quando evitar

Não produza a análise (ela colapsa a zero) em:

```text
- tarefa read-only (explicar, analisar, revisar sem escrever);
- ajuste trivial de baixa incerteza (texto, label, rename mecânico, config óbvia).
```

Nesses casos a rota é anunciada sem parada — não transforme ativação de skill em preâmbulo maior que
a tarefa. **Risco alto não é gatilho de análise expandida**: um refactor de risco alto com escopo
claro colapsa a análise numa linha; risco eleva prova, gates e overlays, não cria incerteza
artificial. O gatilho da análise expandida e do gate de descoberta é a **lacuna material**, não o
risco isolado.

## Rotina

Dado um pedido:

1. **Listar as premissas** de que o plano dependeria para prosseguir (funcionais, de arquitetura, de
   dados, de segurança, de integração, de compatibilidade). Use os sinais de premissa oculta de
   [Assumption Tracking](assumption-tracking.md).
2. **Classificar cada premissa** por impacto × incerteza (a mesma matriz de criticidade).
3. **Marcar como MATERIAL** as premissas cuja leitura errada mudaria escopo, UX, arquitetura,
   segurança ou dados — as reversíveis e locais ficam como suposição declarada.
4. **Emitir a análise compacta** e apontar **quais lacunas materiais justificam PROPOR descoberta**
   (brainstorming compacto ou `pelizzai-interview-me` focal).

## Formato da análise (≤ 6 bullets, proporcional)

```text
Premissas assumidas (reversíveis, declaradas):
- <premissa> — sigo com esta leitura

Lacunas materiais (mudam escopo/UX/arquitetura/segurança/dados):
- <lacuna> — o que muda se a leitura for outra

Riscos concretos:
- <risco> — quando aparece

Alternativas materialmente diferentes (quando existirem):
- <alternativa> — trade-off central
```

Em bounded/ajuste com tudo claro, a passada colapsa em **uma linha**: `Sem lacunas materiais;
premissas assumidas: <lista curta>`. Não vira formulário nem cerimônia.

## Ligação com o roteamento

- **Sem lacuna material** → siga a rota (a análise é uma linha de premissas declaradas).
- **≥ 1 lacuna material** → o router propõe a descoberta num gate agrupado; a decisão de fazer ou
  pular é do usuário. A análise nunca bloqueia por si só, mas a decisão de escopo/UX/arquitetura
  também nunca atravessa a borda por suposição silenciosa: ou é declarada e aceita, ou vai ao gate.

## Carve-out de subagente

Sob briefing fechado (SUBAGENT-STOP), NÃO produza a análise sempre-ativa nem abra o gate de
descoberta: aplique o briefing e escale ao coordenador a decisão de escopo que ele deixou em aberto.

## Relação com outras técnicas

| Técnica                                        | Papel em relação a Proposal Stress                                        |
| ---------------------------------------------- | ------------------------------------------------------------------------- |
| [Assumption Tracking](assumption-tracking.md)  | Máquina de premissas (identificar, classificar, validar) que esta rotina aplica |
| [Constraint Satisfaction](constraint-satisfaction.md) | Separa o obrigatório do desejável entre as lacunas encontradas       |
| [Decision Making](decision-making.md)          | Compara as alternativas materialmente diferentes quando o gate abre       |
| [pelizzai-interview-me](../../pelizzai-interview-me/SKILL.md) | Skill irmã que resolve as lacunas materiais quando a descoberta é aceita |

## Anti-padrões

```text
- Rodar a análise em tarefa read-only ou ajuste trivial (cerimônia sem efeito).
- Escolher em silêncio uma leitura de escopo/UX/arquitetura e prosseguir sem declará-la.
- Tratar risco alto como incerteza e inflar a análise de um pedido de escopo claro.
- Transformar a análise numa pergunta em vez de resultado apresentado.
- Abrir o gate de descoberta sob briefing fechado (SUBAGENT-STOP).
```

Voltar ao [catálogo de técnicas](../SKILL.md).
