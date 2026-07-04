# Loops de feedback — menu de táticas

Como construir o comando de reprodução que a Fase 1 (Observar) da `pelizzai-debugging` exige. O menu é **ordenado**: tente as táticas de cima primeiro — produzem loops mais tight (rápidos, determinísticos, executáveis pelo agente); desça só quando a de cima não se aplicar ao bug em mãos.

## Os quatro atributos do loop

| Atributo           | O que significa                                                                 | Teste rápido                                    |
| ------------------ | ------------------------------------------------------------------------------- | ----------------------------------------------- |
| **red-capable**    | o comando ASSERE o sintoma exato reportado — falha enquanto o bug existe, passa quando some | "ele ficaria vermelho agora, com o bug vivo?"   |
| **determinístico** | mesmo resultado a cada execução                                                  | rode 3× seguidas antes de confiar               |
| **rápido**         | segundos, não minutos                                                            | um loop de 2s permite dezenas de iterações por hipótese |
| **agent-runnable** | você roda sozinho, sem depender de um humano clicar                              | "eu consigo executar isso agora, deste terminal?" |

## O menu (em ordem de preferência)

1. **Failing test** — um teste automatizado no framework do projeto que assere o sintoma. O melhor loop possível: já nasce no formato que a Fase 4 vai promover a teste de regressão. Use quando o bug é alcançável pela suíte existente.

2. **Script curl** — para bugs de API/HTTP: uma chamada com payload fixo + assert no status/corpo (`curl -sf … | grep …`). Não exige subir o front nem clicar em nada.

3. **CLI com fixture** — invoque o binário/entrypoint do projeto com um arquivo de entrada mínimo versionável (fixture) que dispara o bug. Bom para parsers, geradores, pipelines de dados.

4. **Browser headless** — quando o sintoma só existe no navegador: um script Playwright/Puppeteer que navega, age e assere o sintoma (texto de erro, elemento ausente, console). Mais lento — mantenha o cenário mínimo.

5. **Replay de trace capturado** — grave UMA ocorrência real (HAR, dump de request, log estruturado, gravação de sessão) e construa um replayer que a reinjeta. Transforma "aconteceu em produção" em comando local.

6. **Throwaway harness** — um script descartável que importa só o módulo suspeito e o chama com os dados do caso. Corta o resto do sistema do caminho; é deletado no post-mortem, nunca commitado.

7. **Property/fuzz com ~1000 inputs** — quando o input exato que quebra é desconhecido: gere ~1000 inputs (aleatórios com seed logada, ou property-based) e assere a invariante violada. O primeiro input que falhar vira a fixture da tática 3.

8. **Bisection harness (`git bisect run`)** — quando o bug é uma REGRESSÃO e você tem um comando red-capable de qualquer tática acima: `git bisect run <comando>` encontra o commit culpado sozinho. O `<comando>` precisa ser **idempotente e sem efeitos colaterais persistentes** — o bisect o roda dezenas de vezes em commits diferentes; um comando que muta estado (grava no banco, altera arquivos versionados, publica algo) corrompe a busca e gera falsos culpados. O commit achado alimenta a Fase 2 (o diff é a lista de suspeitos).

9. **Differential loop** — rode a versão que funcionava e a que quebra (versão velha vs nova, lib A vs B, prod vs local) com o MESMO input e faça diff da saída. O ponto onde as saídas divergem localiza a quebra sem entender o sistema inteiro.

10. **Script HITL (human-in-the-loop)** — último recurso, quando só um humano pode operar (app mobile físico, SSO corporativo, hardware). NÃO converse em prosa: gere um script estruturado que **dirige** o humano com helpers `step` (instrução do que fazer) e `capture` (o que observar), devolvendo `KEY=VALUE` parseável a você. O humano vira um atuador estruturado, não um interlocutor de prosa:

    ```bash
    step    "1. Abra /checkout no celular e toque em 'Pagar'"
    capture "BANNER_STATUS"  "código exibido no banner de erro"
    capture "SPINNER_TRAVOU" "sim/nao — o spinner passou de 10s?"
    # retorno esperado: BANNER_STATUS=502  SPINNER_TRAVOU=sim
    ```

    Cada rodada do script é uma iteração do loop; os `KEY=VALUE` são a saída que você assere.

## Bugs não-determinísticos: taxa de reprodução

Com bug flaky, o objetivo é **aumentar a TAXA de reprodução**, não perseguir a repro perfeita. Um bug que reproduz 50% das vezes é debugável; 1% não é.

```text
- Rode o loop 100× e conte as falhas — a taxa é o seu baseline mensurável
  (ex.: for i in $(seq 100); do <loop>; done | grep -c FAIL). O comando N× É o loop:
  red-capable = taxa acima do limiar que você fixou.
- Paralelize: N processos concorrentes rodando o loop — race conditions reproduzem
  mais sob contenção.
- Aplique stress: CPU/IO carregados, timeouts encurtados, delays injetados nas fronteiras
  suspeitas (com o prefixo da sessão), ordem aleatória de testes com seed LOGADA.
- Cada mudança que SOBE a taxa é informação sobre a causa: subiu com paralelismo →
  suspeite de estado compartilhado; subiu com timeout curto → suspeite de corrida com I/O.
- Depois do fix, o critério de verde também é estatístico: as mesmas 100 rodadas, zero falhas.
```
