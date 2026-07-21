#!/usr/bin/env pwsh
#Requires -Version 7.0
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$root = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()
$passes = 0

function Check([bool]$Condition, [string]$Name, [string]$Detail = '') {
    if ($Condition) {
        $script:passes++
        Write-Host "PASS: $Name"
    } else {
        $suffix = if ($Detail) { " - $Detail" } else { '' }
        $script:failures.Add("$Name$suffix")
        Write-Host "FAIL: $Name$suffix"
    }
}

function Text([string]$RelativePath) {
    return Get-Content -LiteralPath (Join-Path $root $RelativePath) -Raw -Encoding utf8
}

function Check-Match([string]$RelativePath, [string]$Pattern, [string]$Name) {
    $value = Text $RelativePath
    Check ([regex]::IsMatch($value, $Pattern, 'IgnoreCase, Multiline')) $Name $RelativePath
}

function Check-NotMatch([string]$RelativePath, [string]$Pattern, [string]$Name) {
    $value = Text $RelativePath
    Check (-not [regex]::IsMatch($value, $Pattern, 'IgnoreCase, Multiline')) $Name $RelativePath
}

function Get-RelativeFiles([string]$Base) {
    $prefixLength = $Base.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar).Length + 1
    return @(Get-ChildItem -LiteralPath $Base -Recurse -File | ForEach-Object {
        $_.FullName.Substring($prefixLength).Replace('\', '/')
    } | Sort-Object)
}

function Invoke-Guardrail([string]$Hook, [string]$Command) {
    $payload = @{ tool_input = @{ command = $Command } } | ConvertTo-Json -Compress
    if ($Hook.EndsWith('.mjs')) {
        $null = $payload | & node $Hook 2>$null
    } else {
        $null = $payload | & pwsh -NoProfile -File $Hook 2>$null
    }
    return $LASTEXITCODE
}

function Invoke-Writegate([string]$Hook, [hashtable]$ToolInput, [string]$Cwd) {
    $payload = @{ tool_input = $ToolInput; cwd = $Cwd } | ConvertTo-Json -Compress
    if ($Hook.EndsWith('.mjs')) {
        $null = $payload | & node $Hook 2>$null
    } else {
        $null = $payload | & pwsh -NoProfile -File $Hook 2>$null
    }
    return $LASTEXITCODE
}

function Run-Native([scriptblock]$Command, [string]$Name) {
    try {
        & $Command
        Check ($LASTEXITCODE -eq 0) $Name "exit $LASTEXITCODE"
    } catch {
        Check $false $Name $_.Exception.Message
    }
}

$previous = Get-Location
$temp = $null
$handoffCleanup = $null
try {
    Set-Location $root

    # SKILL.md: frontmatter mínimo e identidade consistente.
    $skillRoot = Join-Path $root '.claude/skills'
    $skillDirs = @(Get-ChildItem -LiteralPath $skillRoot -Directory | Sort-Object Name)
    foreach ($dir in $skillDirs) {
        $skillFile = Join-Path $dir.FullName 'SKILL.md'
        if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
            Check $false "frontmatter $($dir.Name)" 'SKILL.md ausente'
            continue
        }
        $lines = @(Get-Content -LiteralPath $skillFile -Encoding utf8)
        $end = -1
        for ($i = 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -eq '---') { $end = $i; break }
        }
        $keys = if ($end -gt 1) {
            @($lines[1..($end - 1)] | ForEach-Object {
                if ($_ -match '^([A-Za-z][A-Za-z0-9_-]*):') { $Matches[1] }
            })
        } else { @() }
        $nameLine = @($lines | Where-Object { $_ -match '^name:\s*' } | Select-Object -First 1)
        $declared = if ($nameLine.Count) { ($nameLine[0] -replace '^name:\s*', '').Trim() } else { '' }
        $valid = $lines.Count -gt 3 -and $lines[0] -eq '---' -and $end -gt 1 -and
            $declared -eq $dir.Name -and
            (@($keys | Where-Object { $_ -notin @('name', 'description') }).Count -eq 0) -and
            ($keys -contains 'name') -and ($keys -contains 'description')
        Check $valid "frontmatter $($dir.Name)"
    }

    # Repo-fonte: manifesto é conjunto exato, sem duplicatas.
    $manifest = @(Get-Content scripts/pelizzai-core-skills.txt | ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and $_ -notmatch '^#' })
    $dirNames = @($skillDirs.Name)
    $missing = @($dirNames | Where-Object { $manifest -notcontains $_ })
    $dangling = @($manifest | Where-Object { $dirNames -notcontains $_ })
    $duplicates = @($manifest | Group-Object | Where-Object Count -gt 1)
    Check ($missing.Count -eq 0 -and $dangling.Count -eq 0 -and $duplicates.Count -eq 0) `
        'manifesto do repo-fonte é exato' "missing=$($missing -join ',') dangling=$($dangling -join ',')"

    # Mirror interoperável: mesmos paths e hashes.
    $agentRoot = Join-Path $root '.agents/skills'
    $srcFiles = Get-RelativeFiles $skillRoot
    $dstFiles = if (Test-Path $agentRoot) { Get-RelativeFiles $agentRoot } else { @() }
    $treeDiff = @(Compare-Object $srcFiles $dstFiles)
    $hashDiff = 0
    if ($treeDiff.Count -eq 0) {
        foreach ($rel in $srcFiles) {
            $a = Join-Path $skillRoot $rel
            $b = Join-Path $agentRoot $rel
            if ((Get-FileHash $a).Hash -ne (Get-FileHash $b).Hash) { $hashDiff++ }
        }
    }
    Check ($treeDiff.Count -eq 0 -and $hashDiff -eq 0) '.agents espelha .claude' "paths=$($treeDiff.Count) hashes=$hashDiff"

    # Contratos centrais: decisão, efeitos e composição.
    Check-Match '.claude/skills/pelizzai-core/SKILL.md' 'read-only|somente leitura' 'core reconhece efeito read-only'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'effect.*risk.*uncertainty.*surfaces|efeito.*risco.*incerteza.*superf' 'router classifica envelope'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'uma head skill|exatamente uma.*head' 'router escolhe uma head skill'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'bounded[\s\S]*standard[\s\S]*exploratory' 'router possui lanes adaptativas'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'antes da primeira escrita|first-write' 'router protege primeira escrita'
    Check-Match '.claude/skills/pelizzai-audit/SKILL.md' 'scan-only' 'audit possui modo scan-only'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'causa direta.*determinístico incerto.*flaky.*incidente' 'debugging faz triagem proporcional'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'Não invente um número de hipóteses|não.*quantidade fixa' 'debugging não fixa hipóteses'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'Estratégia de teste/validação|Estratégia primária' 'task-cycle escolhe prova por artefato'
    Check-Match '.claude/skills/pelizzai-writing-plans/templates/plan.md' 'Skills transversais do harness' 'plano propaga overlays'
    # A ordem combined→split era o default antigo; o que importa é o plano REGISTRAR o perfil com
    # os dois valores nomeados (o default vive no bloco F6, abaixo).
    Check-Match '.claude/skills/pelizzai-writing-plans/SKILL.md' 'Perfil de review[\s\S]{0,400}split[\s\S]{0,400}combined' 'plano registra o perfil de review com os dois valores'
    Check-NotMatch '.claude/skills/pelizzai-writing-plans/SKILL.md' 'interview-me[^\n]*(OBRIGATÓRIO|obrigatório)' 'plano bounded não força entrevista'
    Check-Match '.claude/skills/pelizzai-frontend/SKILL.md' 'overlay obrigatório' 'frontend é overlay obrigatório para UI'
    Check-Match '.claude/skills/pelizzai-frontend/SKILL.md' 'spec/Figma aprovado.*design system' 'frontend respeita especificação e design system'
    Check-Match '.claude/skills/pelizzai-frontend/SKILL.md' 'AI slop' 'frontend explicita anti-slop'
    Check-Match '.claude/skills/pelizzai-oswap/SKILL.md' 'Software Supply Chain Failures[\s\S]*Mishandling of Exceptional Conditions' 'OWASP usa categorias 2025'
    Check-NotMatch '.claude/skills/pelizzai-oswap/SKILL.md' 'Oferecida pela.*finish-task' 'segurança não é oferta tardia'
    Check-NotMatch '.claude/skills/pelizzai-documenting-features/SKILL.md' 'Oferecida pela.*finish-task' 'documentação não é oferta tardia'
    Check-Match '.claude/skills/pelizzai-verification-before-completion/SKILL.md' 'validated-head' 'Verification sela conteúdo validado'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'metadata-only' 'finish limita fechamento a metadata'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'ofereça o destino[\s\S]{0,180}Manter local[^\n]*recomend' 'finish apresenta destino com local recomendado'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'nunca é auto-confirmado' 'finish exige decisão explícita até para manter local'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'Source mode[\s\S]*não.*state|source mode[\s\S]*não.*state' 'finish não cria runtime no source mode'
    Check-Match '.claude/skills/pelizzai-quick-fix/SKILL.md' 'Commit[\s\S]*verification-before-completion[\s\S]*finish-task' 'quick-fix commita antes do seal'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'Revise[\s\S]*Consolide[\s\S]*verification-before-completion[\s\S]*finish-task' 'debugging revisa, commita e sela em ordem'
    Check-Match '.claude/skills/pelizzai-audit/SKILL.md' 'commite[\s\S]*verification-before-completion[\s\S]*finish-task' 'bootstrap commita antes do seal'
    Check-Match '.cursor/rules/pelizzai.mdc' 'pelizzai-core/SKILL.md' 'Cursor aponta para core'
    Check-Match '.cursor/rules/pelizzai.mdc' 'pelizzai-router/SKILL.md' 'Cursor aponta para router'
    Check-Match '.github/workflows/check-harness.yml' '-Check -SourceMode' 'CI valida source mode'
    Check-Match '.github/workflows/check-harness.yml' 'test-harness-contracts.ps1' 'CI executa contratos'
    # A serialização é regra do harness, não propriedade do Git — o que o isolamento ratificado
    # libera (paralelo em caminhos disjuntos) é travado no bloco F5, abaixo.
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'worktree.*não isola agentes|um writer por vez' 'team: worktree não isola agentes entre si'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'codebase-wide.*pelizzai-improving-architecture' 'router separa review arquitetural de code review'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'risco eleva prova e gates, não cria incerteza artificial' 'router desacopla risco de discovery'
    Check-Match '.claude/skills/pelizzai-improving-architecture/SKILL.md' 'não cria branch, state, HTML, ADR, spec, out-of-scope ou qualquer arquivo' 'arquitetura read-only não escreve'
    Check-NotMatch '.claude/skills/pelizzai-improving-architecture/SKILL.md' 'registre\s+automaticamente|Monte um HTML' 'arquitetura não persiste por reflexo'
    Check-Match '.claude/skills/pelizzai-brainstorming/SKILL.md' 'source mode:[^\n]*execution record nativo[^\n]*sem criar `pelizzai/`' 'brainstorming respeita source mode'
    Check-Match '.claude/skills/pelizzai-quick-fix/SKILL.md' 'source mode[^\n]*sem arquivo/commit de closure' 'quick-fix respeita source mode'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'source mode[\s\S]{0,180}manifests' 'debugging descobre comandos no source mode'
    Check-Match '.claude/skills/pelizzai-tdd/SKILL.md' 'source mode: use regras/skills do repo-fonte' 'TDD respeita source mode'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'sem script ou sem plano persistente' 'task brief aceita plano nativo'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'uma única tarefa bounded[\s\S]*tree SHA' 'review bounded evita duplicação comprovável'
    Check-Match '.claude/skills/pelizzai-frontend/SKILL.md' 'Copy, label, token[\s\S]*viewport de maior risco' 'frontend usa QA visual proporcional'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'delivery-status: partial[\s\S]*PR não foi criado' 'finish representa push sem PR'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'delivery-status: pr-open[^\n]*URL' 'finish registra PR aberto'
    Check-Match '.claude/skills/pelizzai-recovery/SKILL.md' 'source mode:[^\n]*execution record nativo; não crie state' 'recovery respeita source mode'
    Check-Match '.claude/skills/pelizzai-domain-modeling/SKILL.md' 'Source mode[\s\S]*nunca crie `pelizzai/`' 'domain modeling respeita source mode'
    Check-Match '.claude/skills/pelizzai-prototype/SKILL.md' 'Source mode nunca cria runtime `pelizzai/`' 'prototype respeita source mode'
    Check-Match '.claude/skills/pelizzai-handoff/SKILL.md' 'Nunca crie `pelizzai/` no repo-fonte' 'handoff respeita source mode'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'Source mode:[\s\S]*State ausente é o contrato' 'retomada execution respeita source mode'

    # =====================================================================
    # Contratos de inteligência com autoridade do usuário.
    # O harness classifica, fundamenta e recomenda; decisões humanas são
    # ratificadas e discovery ocorre uma pergunta por vez.
    # =====================================================================

    # -- Gate de kickoff (router): rota como recomendação a ratificar --
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' '## Gate de kickoff' 'router tem seção Gate de kickoff'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'rota proposta' 'kickoff apresenta a rota proposta'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'recomendação a ratificar' 'kickoff é recomendação a ratificar'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'Aplicar isolamento, modo de execução ou estratégia de commit sem ratificação do usuário' 'router: red flag anti-silêncio (isolamento/modo/commit)'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'Assumir em silêncio decisão que muda escopo/UX/arquitetura' 'router: red flag anti-suposição silenciosa'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'SUBAGENT-STOP\), não produza análises de rota nem abra o Gate de kickoff' 'kickoff tem carve-out SUBAGENT-STOP'

    # -- Análise da proposta + descoberta reconectada (router) --
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'Análise da proposta' 'router sempre stressa a proposta (Análise da proposta)'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'assumption-tracking' 'Análise da proposta é fundamentada em técnica documentada'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'pelizzai-interview-me' 'interview-me reconectada ao roteamento (>0 menções)'

    # -- Gate de setup pós-plano sequencial: três opções, team, squash --
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' '## Gate de setup pós-plano' 'execution-plans tem seção Gate de setup pós-plano'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'as três opções sempre visíveis' 'gate pós-plano: as três opções sempre visíveis'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'team nunca é omitido' 'gate pós-plano: team nunca é omitido'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'squash-final somente com pedido explícito' 'gate pós-plano: squash-final só com pedido explícito'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'uma por vez|uma pergunta por turno' 'gate pós-plano ratifica uma decisão por turno'
    Check-NotMatch '.claude/skills/pelizzai-execution-plans/SKILL.md' 'autonomia entre tarefas' 'execution-plans não promete autonomia decisória'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'SUBAGENT-STOP / MEMBRO-DO-TIME-STOP' 'gate pós-plano tem carve-out SUBAGENT-STOP'

    # -- writing-plans encaminha ao gate e expõe lacunas (sem forçar entrevista em bounded) --
    Check-Match '.claude/skills/pelizzai-writing-plans/SKILL.md' 'encaminhe ao Gate de setup pós-plano' 'writing-plans encaminha ao Gate de setup pós-plano'
    Check-Match '.claude/skills/pelizzai-writing-plans/SKILL.md' 'Exponha as lacunas materiais' 'writing-plans expõe as lacunas materiais'
    Check-Match '.claude/skills/pelizzai-writing-plans/SKILL.md' 'exploratory[\s\S]{0,120}(stress|review independente)' 'writing-plans espera stress para exploratory (positivo, sem forçar bounded)'

    # -- brainstorming/interview: uma pergunta por vez, recomendação, spec --
    Check-Match '.claude/skills/pelizzai-brainstorming/SKILL.md' 'uma pergunta por vez' 'brainstorming entrevista sequencialmente'
    Check-Match '.claude/skills/pelizzai-brainstorming/SKILL.md' 'Recomendação:' 'brainstorming recomenda antes de perguntar'
    Check-Match '.claude/skills/pelizzai-brainstorming/SKILL.md' 'Pular a\s+descoberta inteira exige pedido explícito' 'brainstorming: pular descoberta exige decisão do usuário'
    Check-Match '.claude/skills/pelizzai-brainstorming/SKILL.md' 'SUBAGENT-STOP\), não produza análises de rota nem abra gates' 'brainstorming tem carve-out SUBAGENT-STOP'
    Check-Match '.claude/skills/pelizzai-brainstorming/SKILL.md' 'Não exija stress[^\n]*duas vezes' 'brainstorming preserva a guarda anti-stress duplicado'

    # -- interview-me: exposição numerada de lacunas --
    Check-Match '.claude/skills/pelizzai-interview-me/SKILL.md' 'termina com a lista numerada de lacunas e como cada uma muda a solução' 'interview-me termina com lista numerada de lacunas'
    Check-Match '.claude/skills/pelizzai-interview-me/SKILL.md' 'sem a seção de lacunas está incompleto' 'interview-me: resumo sem seção de lacunas é incompleto'
    Check-Match '.claude/skills/pelizzai-interview-me/SKILL.md' 'exatamente uma pergunta por turno' 'interview-me faz exatamente uma pergunta por turno'
    Check-Match '.claude/skills/pelizzai-interview-me/SKILL.md' 'Recomendado:' 'interview-me destaca a melhor opção'

    # -- F5: interview-me é o mecanismo canônico de tampar lacunas (restauração pré-11/07/2026) --
    # A skill volta a ser OBRIGATÓRIA nos três pontos do BASE (pré-design, pós-design, pós-plano) e
    # ganha o quarto: a lacuna que aparece no meio da execução. O anti-cerimônia ("o que NÃO é
    # lacuna") existe para que a obrigatoriedade não degenere em questionário.
    Check-Match '.claude/skills/pelizzai-interview-me/SKILL.md' 'Esta skill é o \*\*mecanismo canônico de tampar\s+lacunas\*\*' 'interview-me: o corpo declara o mecanismo canônico de tampar lacunas'
    Check-Match '.claude/skills/pelizzai-interview-me/SKILL.md' 'description:[^\n]*mecanismo canônico de tampar lacunas' 'interview-me: a description aciona pelo mecanismo canônico (gatilho)'
    Check-Match '.claude/skills/pelizzai-interview-me/SKILL.md' 'default,\s+convenção, Context7 ou .inferência razoável. é violação' 'interview-me: preencher por default/convenção/Context7/inferência é violação'
    Check-Match '.claude/skills/pelizzai-interview-me/SKILL.md' '## Onde é obrigatória[\s\S]{0,400}não é oferta' 'interview-me: obrigatoriedade restaurada (não é oferta)'
    Check-Match '.claude/skills/pelizzai-interview-me/SKILL.md' 'Antes do design[\s\S]{0,900}Depois do plano, antes da execução' 'interview-me obrigatória antes do design, pós-design e pós-plano'
    Check-Match '.claude/skills/pelizzai-interview-me/SKILL.md' 'realmente identificadas e\s+resolvidas' 'interview-me só encerra cedo com as lacunas resolvidas ou aceitas'
    Check-Match '.claude/skills/pelizzai-interview-me/SKILL.md' '## Modo lacuna' 'interview-me tem o modo lacuna (parada durante a execução)'
    Check-Match '.claude/skills/pelizzai-interview-me/SKILL.md' 'nunca dispensa o item 4' 'interview-me: bounded dispensa o stress, nunca a parada por lacuna'
    Check-Match '.claude/skills/pelizzai-interview-me/SKILL.md' 'NÃO é lacuna' 'interview-me delimita o que NÃO é lacuna (anti-cerimônia)'
    Check-Match '.claude/skills/pelizzai-interview-me/SKILL.md' 'passo mecânico dentro de fronteira já ratificada' 'interview-me: passo mecânico ratificado não vira pergunta'
    Check-Match '.claude/skills/pelizzai-interview-me/SKILL.md' 'SUBAGENT-STOP[\s\S]{0,400}NEEDS_CONTEXT' 'interview-me: sob briefing fechado o executor devolve NEEDS_CONTEXT'
    Check-NotMatch '.claude/skills/pelizzai-interview-me/SKILL.md' 'bounded. costuma dispensar esta skill' 'interview-me: bounded não desliga a skill inteira, só o stress de design/plano'

    # -- F5: autonomia entre as tarefas restaurada (execução contínua, parada só por lacuna) --
    # Contraparte do Check-NotMatch 'autonomia entre tarefas' acima: a autonomia é de EXECUÇÃO
    # (não perguntar "sigo?" a cada tarefa), nunca de DECISÃO.
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'AUTONOMIA \(sem perguntar a cada passo\)' 'execution-plans restaura a autonomia entre as tarefas'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'não pergunte .sigo\?.' 'execution-plans não pergunta "sigo?" ao fim de cada tarefa'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'Pare apenas por: BLOCKED real[^\n]*LACUNA MATERIAL' 'execution-plans: parada por BLOCKED, lacuna material, invalidação ou fim'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'autonomia é de execução, nunca de' 'execution-plans: autonomia é de execução, nunca de decisão'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'LACUNA MATERIAL não é uma parada vaga' 'execution-plans: lacuna material tem caminho concreto, não pausa vaga'
    Check-NotMatch '.claude/skills/pelizzai-execution-plans/SKILL.md' 'EXECUÇÃO CONTROLADA' 'execution-plans não reintroduz a pausa a cada tarefa'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' '## 0\. Autonomia entre as tarefas e a parada por lacuna material' 'task-cycle abre com autonomia + parada por lacuna material'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'consolidar é agrupar e ordenar por\s+dependência, NUNCA decidir' 'task-cycle: coordenador consolida as lacunas, não as decide'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'Lacuna de DOMAIN SKILL[\s\S]{0,200}a execução \*\*não\*\* para' 'task-cycle preserva: lacuna de domain skill não para a execução'

    # -- F5: membro nomeia a lacuna, coordenador leva ao humano (consolidar não é decidir) --
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'não decide lacuna de produto' 'team: membro nomeia a lacuna e não a decide'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'consolidar não é decidir' 'team: coordenador consolida as lacunas mas não decide por si'
    Check-Match '.claude/skills/pelizzai-subagents/SKILL.md' 'não decide lacuna de produto' 'subagents: o subagente nomeia a lacuna e não a decide'
    Check-Match '.claude/skills/pelizzai-subagents/SKILL.md' 'Lacuna material é a outra via, e essa para a frente' 'subagents separa lacuna material (para) de domain skill (não para)'

    # -- F5: escrita paralela em worktree com caminhos disjuntos (reverte 44df87c) --
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'isolation: worktree[\s\S]{0,300}caminhos disjuntos' 'team: worktree permite escrita paralela em caminhos disjuntos'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'A disjunção é a \*\*condição\*\*' 'team: a disjunção de caminhos é condição, não conselho'
    Check-NotMatch '.claude/skills/pelizzai-team/SKILL.md' 'Mantenha um writer por vez' 'team não reimpõe writer único quando o isolamento é worktree'
    Check-Match '.claude/skills/pelizzai-subagents/SKILL.md' 'CAMINHOS DISJUNTOS' 'subagents: escrita paralela em worktree exige caminhos disjuntos'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'Nunca um worktree por agente' 'execution-plans: worktree é um por tarefa, não um por agente'

    # -- F5: callers reconectados (a obrigatoriedade não vive só dentro da skill) --
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' '## Lacuna material durante a execução' 'router tem a seção Lacuna material durante a execução'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'lacuna material interrompe o trabalho e volta\s+ao usuário pela .pelizzai-interview-me' 'router: lacuna pós-kickoff interrompe e volta pela interview-me'
    Check-Match '.claude/skills/pelizzai-core/SKILL.md' 'tampada com a .pelizzai-interview-me' 'core: lacuna do usuário é tampada com a interview-me'
    Check-Match '.claude/skills/pelizzai-brainstorming/SKILL.md' 'aplica a TODOS os\s+projetos, independentemente da simplicidade aparente' 'brainstorming: o hard-gate de design vale para TODOS os projetos'
    Check-Match '.claude/skills/pelizzai-brainstorming/SKILL.md' 'stress com .pelizzai-interview-me. é \*\*OBRIGATÓRIO\*\*' 'brainstorming: stress do design é obrigatório em greenfield/completo'
    Check-Match 'CLAUDE.md' 'A LLM não decide nada sozinha' 'CLAUDE.md fixa o contrato: a LLM não decide nada sozinha'
    Check-Match 'CLAUDE.md' 'tampada com a .pelizzai-interview-me' 'CLAUDE.md: toda lacuna é tampada com a interview-me'
    Check-Match '.claude/skills/pelizzai-writing-plans/templates/plan.md' 'entrevista de execução' 'plano prevê a origem entrevista de execução (lacuna tampada na execução)'

    # -- audit: gate proativo de domain skills nas bordas (propor-confirmar) --
    Check-Match '.claude/skills/pelizzai-audit/SKILL.md' 'Gate proativo de domain skills' 'audit tem Gate proativo de domain skills'
    Check-Match '.claude/skills/pelizzai-audit/SKILL.md' 'bordas design.plano e plano.execução' 'audit: gate nas bordas design->plano e plano->execução'
    Check-Match '.claude/skills/pelizzai-audit/SKILL.md' 'recomendação a\s+ratificar' 'audit preserva propor-confirmar'
    Check-Match '.claude/skills/pelizzai-audit/SKILL.md' 'O plano não começa enquanto' 'domain skills são decididas antes do plano greenfield'

    # -- writing-skills: context7 obrigatório na criação + eixo adoption-driven --
    Check-Match '.claude/skills/pelizzai-writing-skills/SKILL.md' 'fundamentada em context7 ou documentação oficial atual' 'writing-skills exige context7/doc oficial ao criar skill de stack'
    Check-Match '.claude/skills/pelizzai-writing-skills/SKILL.md' 'Sync obrigatório como parte da edição' 'writing-skills sincroniza automaticamente após edição autorizada'
    Check-Match '.claude/skills/pelizzai-writing-skills/SKILL.md' 'node scripts/sync-harness\.mjs[\s\S]*--check' 'writing-skills executa sync e check portáteis'
    Check-Match '.claude/skills/pelizzai-writing-skills/references/domain-skill-maintenance.md' '[Aa]doption-driven' 'domain-skill-maintenance tem o eixo adoption-driven (cria skill de stack nova)'

    # -- finish-task: destino proativo (local default, externo por tarefa) --
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'Faça uma única pergunta e aguarde' 'finish-task pergunta o destino e aguarda'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'nunca (?:são )?aplicados a partir de um\s+default de profile' 'finish-task: push/PR/descarte confirmados por tarefa (destino não herdado)'

    # -- Doutrina de entrada (CLAUDE.md) --
    Check-Match 'CLAUDE.md' 'Recomende e ratifique:' 'CLAUDE.md fixa a doutrina recomendar-e-ratificar'
    Check-Match 'CLAUDE.md' 'raciocinar é do harness; decidir é do usuário' 'CLAUDE.md separa reasoning de autoridade'
    Check-Match 'CLAUDE.md' 'Produto/projeto greenfield nunca é bounded' 'CLAUDE.md protege o fluxo greenfield'
    Check-Match 'CLAUDE.md' 'decisões estruturais[\s\S]{0,180}nunca (em )?default silencioso' 'CLAUDE.md: decisões estruturais nunca usam default silencioso'

    # -- Marcadores máquina-legíveis do state.md (schema do writegate/retomada) --
    Check-Match '.claude/skills/pelizzai-execution-plans/templates/state.md' 'kickoff: <pendente \| ratificado' 'state.md tem marcador kickoff (pendente|ratificado)'
    Check-Match '.claude/skills/pelizzai-execution-plans/templates/state.md' 'isolation: <pending[\s\S]*execution-mode: <pending[\s\S]*commit-strategy: <pending' 'state.md: isolation/execution-mode/commit-strategy nascem <pending>'
    # Restauração pré-11/07 (2026-07-21): o cursor voltou a ser CURSOR. As oito etapas de greenfield
    # continuam obrigatórias, mas suas ratificações são registro histórico no CABEÇALHO DO PLANO —
    # nunca campo do state carimbado/lido por hook. Anti-regressão nas duas pontas (sai do state,
    # entra no plano) para que a remoção não seja desfeita por engano na próxima rodada.
    Check-NotMatch '.claude/skills/pelizzai-execution-plans/templates/state.md' '^\s*-?\s*(discovery|spec-approval|domain-skills-decision|plan-approval):' 'state.md NÃO reintroduz campo de aprovação greenfield (cursor, não carimbo)'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'oito etapas[\s\S]{0,260}CABEÇALHO DO PLANO' 'execution-plans lê as oito etapas greenfield no cabeçalho do plano'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'oito\s+etapas[\s\S]{0,260}cabeçalho do plano' 'router: greenfield ratifica no cabeçalho do plano, não em campo do state'
    Check-Match '.claude/skills/pelizzai-writing-plans/templates/plan.md' '\*\*Aprovações\*\*[\s\S]{0,300}Descoberta:[\s\S]{0,200}Spec:[\s\S]{0,200}Domain skills:[\s\S]{0,200}Plano:' 'plano carrega o bloco Aprovações (registro histórico das quatro ratificações)'
    Check-Match '.claude/skills/pelizzai-writing-plans/templates/plan.md' 'silêncio não vira data' 'plano: marcador de aprovação nunca é preenchido por inferência'

    # -- Seção Defaults de execução ratificados no profile.md (memória de decisão) --
    Check-Match '.claude/skills/pelizzai-audit/templates/profile.md' '## Defaults de execução ratificados' 'profile.md tem seção Defaults de execução ratificados'
    Check-Match '.claude/skills/pelizzai-audit/templates/profile.md' 'isolation-default[\s\S]*execution-mode-default[\s\S]*commit-strategy-default' 'profile.md lista os defaults de execução'
    Check-Match '.claude/skills/pelizzai-audit/templates/profile.md' 'destination não é persistível' 'profile.md: destination nunca persistível (push/PR por tarefa)'

    # -- Anti-regressão simétrica: read-only e near miss local continuam proporcionais --
    # (o Check-NotMatch de :134 "plano bounded não força entrevista" permanece intacto acima.)
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'nunca cria/edita state' 'router: read-only não cria estado/artefato'
    Check-Match 'CLAUDE.md' 'read-only não cria estado nem artefatos' 'CLAUDE.md: read-only sem estado/artefato'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'Quando informa e segue:[^\n]*somente `read-only`' 'router só segue sem ratificação em read-only'
    Check-Match '.claude/skills/pelizzai-router/evals/adaptive-user-control.md' 'G-01.*greenfield com stack informada' 'eval preserva a regressão greenfield histórica'
    Check-Match '.claude/skills/pelizzai-router/evals/adaptive-user-control.md' 'G-02.*outra plataforma' 'eval cobre greenfield em outra stack'
    Check-Match '.claude/skills/pelizzai-router/evals/adaptive-user-control.md' 'F-01.*feature em projeto existente' 'eval cobre feature em projeto existente'
    Check-Match '.claude/skills/pelizzai-router/evals/adaptive-user-control.md' 'V-01.*upgrade e manutenção de skill' 'eval cobre upgrade e refresh de skill'
    Check-Match '.claude/skills/pelizzai-router/evals/adaptive-user-control.md' 'B-01.*near miss local' 'eval protege ajuste local contra inflação'
    Check-NotMatch '.claude/skills/pelizzai-brainstorming/SKILL.md' 'React, Express, SQLite' 'brainstorming normativo não sobreajusta ao prompt histórico'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'produto/projeto greenfield[\s\S]{0,120}sempre `exploratory`' 'router classifica greenfield como exploratory'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'Context7/documentação oficial é reconhecimento técnico read-only' 'router usa Context7 cedo sem efeito mutável'
    Check-Match '.claude/skills/pelizzai-reasoning/SKILL.md' 'Use Context7 desde o reconhecimento inicial' 'reasoning torna Context7 transversal'
    Check-Match '.claude/skills/pelizzai-reasoning/SKILL.md' 'Context7 pode confirmar[\s\S]{0,180}nunca escolhe requisito' 'reasoning impede Context7 de decidir produto'
    Check-Match 'CLAUDE.md' 'Context7 é a fonte técnica preferencial do harness' 'CLAUDE fixa Context7 como arma técnica transversal'

    # =====================================================================
    # Pacote "feedback de campo" (D3–D7). Ver o plano-mestre no scratchpad.
    # D3: lifecycle delivered→done + confirmar. D4: higiene do histórico do
    # state (1 linha/tarefa, reports/ efêmero, history/ versionado, nudge
    # ~150). D5: plano anti-carimbo. D6: review de duas lentes com cegueira
    # assimétrica + especialistas por área. D7: fio do gate proativo de
    # domain skills nos três pontos de captura.
    # =====================================================================

    # -- D3: lifecycle delivered → done é constatado, nunca declarado --
    Check-Match '.claude/skills/pelizzai-execution-plans/templates/state.md' 'delivered \| done \| abandoned \| blocked' 'state.md: enum de phase inclui delivered, done e abandoned'
    Check-Match '.claude/skills/pelizzai-execution-plans/templates/state.md' '^-?\s*confirmar:\s*<none' 'state.md: campo confirmar para constatar done contra o git'
    Check-Match '.claude/skills/pelizzai-execution-plans/templates/state.md' 'Ciclo de vida da entrega' 'state.md documenta o ciclo delivered→done'
    Check-Match '.claude/skills/pelizzai-execution-plans/templates/state.md' 'NÃO declara .done' 'state.md: finish-task não declara done (constatação posterior)'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'Reconciliação da entrega anterior' 'execution-plans reconcilia a entrega anterior (delivered→done)'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'phase: delivered[\s\S]{0,6}entrega selada' 'execution-plans define phase delivered'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'phase: delivered[\s\S]{0,120}Reconciliação da entrega anterior' 'router (D3): delivered dispara reconciliação antes de tratar como tarefa ativa'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'fronteira da migração' 'execution-plans (D4): define a fronteira verificável do bloco íntegro'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'usa a MESMA migração sem perda' 'execution-plans: abandoned usa a mesma migração sem perda para history/'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'phase: delivered' 'finish-task encerra a tarefa em delivered'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'sela tarefa em delivered' 'finish-task: commit de closure sela em delivered'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'Declarar .phase: done. aqui' 'finish-task: anti-padrão declarar done na própria finish'
    Check-NotMatch '.claude/skills/pelizzai-finish-task/SKILL.md' 'Defina .slug:[\s\S]{0,20}phase: done' 'finish-task não fecha mais direto em done'
    Check-Match '.claude/skills/pelizzai-verification-before-completion/SKILL.md' 'encerra em .phase: delivered' 'verification: finish encerra em delivered, não em done'
    Check-Match '.claude/skills/pelizzai-recovery/SKILL.md' 'Entrega em .delivered. na retomada' 'recovery constata delivered→done na retomada, sem mover WIP'
    Check-Match '.claude/skills/pelizzai-handoff/SKILL.md' 'phase: delivered, inclua confirmar' 'handoff propaga confirmar para a próxima sessão constatar done'

    # -- D4: higiene do histórico do state — 1 linha/tarefa, reports/ efêmero, history/ versionado --
    Check-Match '.claude/skills/pelizzai-execution-plans/templates/state.md' 'Uma linha por tarefa' 'state.md: progresso é uma linha por tarefa'
    Check-Match '.claude/skills/pelizzai-execution-plans/templates/state.md' 'data/reports/' 'state.md: relatório longo vai para data/reports/ (efêmero)'
    Check-Match '.claude/skills/pelizzai-execution-plans/templates/state.md' 'data/history/[\s\S]{0,40}VERSIONADO' 'state.md: history/ é o registro durável versionado'
    Check-Match '.claude/skills/pelizzai-execution-plans/templates/state.md' '~60 linhas' 'state.md: nudge de compactação em ~60 linhas (template desinflado)'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'Higiene do progresso' 'execution-plans tem a seção Higiene do progresso'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'uma linha por tarefa' 'execution-plans: uma linha por tarefa no progresso'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' '~60 linhas' 'execution-plans: nudge de compactação em ~60 linhas'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'data/history/[\s\S]{0,40}VERSIONADO' 'execution-plans: migração de bloco íntegro para history/ versionado'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' '~60 linhas' 'finish-task: nudge de state volumoso (~60 linhas)'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'data/history/' 'finish-task cita a migração para history/ na constatação de done'
    Check-Match '.claude/skills/pelizzai-audit/SKILL.md' '^data/reports/\s*$' 'audit: reports/ permanece ignorado (efêmero)'
    Check-NotMatch '.claude/skills/pelizzai-audit/SKILL.md' '^data/history/\s*$' 'audit: history/ NÃO é ignorado no template (registro durável versionado)'
    Check-Match '.claude/skills/pelizzai-audit/SKILL.md' 'history/\s+versionado' 'audit: history/ no Layout canônico marcado como versionado (durável, fora do ignore)'

    # =====================================================================
    # Restauração pré-11/07 (2026-07-21) — F4: o state volta a ser CURSOR.
    # A regressão que esta seção trava: o template de dados foi virando
    # manual de processo (85 linhas, 39 delas de instrução), o setup passou
    # a custar um commit só de metadata e o cursor só desinchava na abertura
    # SEGUINTE. O que fica travado aqui: tamanho do template, prosa na skill
    # (não no dado), migração no selo `delivered` e zero commit de setup.
    # =====================================================================

    # -- Template é dado, não manual: teto de tamanho e ponteiro para a doutrina --
    $stateTemplateLines = (Text '.claude/skills/pelizzai-execution-plans/templates/state.md') -split "`r?`n"
    Check ($stateTemplateLines.Count -le 60) 'state.md: template cabe em 60 linhas (cursor desinflado)' "linhas=$($stateTemplateLines.Count)"
    Check-Match '.claude/skills/pelizzai-execution-plans/templates/state.md' 'Referencie, não duplique' 'state.md aponta para a doutrina em vez de duplicá-la'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' '\*\*Quem escreve o cursor' 'execution-plans hospeda a autoria do cursor (prosa saiu do template)'
    Check-Match '.claude/skills/pelizzai-handoff/SKILL.md' 'artefato que tem path é referenciado, nunca colado' 'handoff: regra de referenciar em vez de colar (fundamento da desduplicação)'

    # -- Setup não paga commit de metadata: o cursor viaja no primeiro commit de conteúdo --
    Check-Match '.claude/skills/pelizzai-starting-branch/SKILL.md' 'crie commit só de metadata' 'starting-branch: setup grava o state e segue, sem commit de metadata'
    Check-NotMatch '.claude/skills/pelizzai-starting-branch/SKILL.md' 'faça\s+um commit metadata de setup' 'starting-branch NÃO reintroduz o commit de setup'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'não existe commit só de metadata para iniciar a tarefa' 'task-cycle: Tarefa 1 leva o state do setup no commit de conteúdo'

    # -- O cursor desincha no FECHAMENTO (selo delivered), não na abertura seguinte --
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'Migração no selo .delivered' 'execution-plans: a migração para history/ acontece no selo delivered'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'Migre o bloco íntegro e desinfle o cursor' 'finish-task executa a migração ao selar delivered'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'git add -- pelizzai/data/state\.md pelizzai/data/history/' 'finish-task estagia state + history no mesmo closure'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' ":\(exclude\)pelizzai/data/history/" 'finish-task: guarda de produto exclui a metadata de history/'
    Check-Match '.claude/skills/pelizzai-verification-before-completion/SKILL.md' 'somente metadata do harness' 'verification: closure contém state + history, não só state'
    Check-Match '.claude/skills/pelizzai-recovery/SKILL.md' 'já migrou para .pelizzai/data/history/' 'recovery: na retomada só carimba o desfecho (o bloco já migrou)'

    # -- Plano executável por quem tem zero contexto (exigência do BASE restaurada) --
    Check-Match '.claude/skills/pelizzai-writing-plans/SKILL.md' 'zero contexto\*\*[\s\S]{0,80}uma única pergunta' 'writing-plans: objetivo é o plano que um executor com zero contexto executa sem perguntar'
    Check-Match '.claude/skills/pelizzai-writing-plans/templates/plan.md' 'sem fazer uma única pergunta' 'plano: gate de qualidade exige executor sem perguntas'
    Check-NotMatch '.claude/skills/pelizzai-writing-plans/templates/plan.md' '\*\*Lane ratificada:\*\*' 'plano não duplica a lane (cursor é do state)'
    Check-NotMatch '.claude/skills/pelizzai-writing-plans/templates/plan.md' '\*\*Status:\*\*' 'plano não mantém Status solto além do bloco Aprovações'

    # -- D5: plano anti-carimbo — Decisões técnicas, ratificação não-carimbo, Desvios + teste de desvio --
    Check-Match '.claude/skills/pelizzai-writing-plans/SKILL.md' '## Decisões técnicas deste plano' 'writing-plans exige a seção Decisões técnicas deste plano'
    Check-Match '.claude/skills/pelizzai-writing-plans/SKILL.md' 'nenhuma decisão técnica material' 'writing-plans: ausência de decisões é declaração explícita, não seção vazia'
    Check-Match '.claude/skills/pelizzai-writing-plans/SKILL.md' 'não está aprovada[\s\S]{0,40}apresente antes de implementar' 'writing-plans fixa o teste operacional de desvio'
    Check-Match '.claude/skills/pelizzai-writing-plans/templates/plan.md' '## Decisões técnicas deste plano' 'template de plano carrega a seção Decisões técnicas'
    Check-NotMatch '.claude/skills/pelizzai-writing-plans/templates/plan.md' 'ratificar o plano é ratificar estas decis' 'template não reintroduz o carimbo em bloco (D5 anti-carimbo)'
    Check-Match '.claude/skills/pelizzai-writing-plans/templates/plan.md' 'sem origem de ratificação[\s\S]{0,40}pergunta' 'template carrega o par recap+pergunta do gate (D5)'
    Check-Match '.claude/skills/pelizzai-writing-plans/templates/plan.md' 'não está aprovada[\s\S]{0,40}apresente antes de implementar' 'template de plano fixa o teste operacional de desvio'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'Decisões técnicas do plano' 'gate item 0 reapresenta as decisões técnicas do plano'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'sem ratificação não passa pelo gate[\s\S]{0,90}nunca item de lista para carimbar' 'gate item 0: decisão sem ratificação vira pergunta, nunca carimbo (âncora D5)'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'já ratificadas[\s\S]{0,60}recap de uma linha' 'gate item 0: decisão já ratificada é recap, não re-pergunta (anti-fadiga)'
    Check-Match '.claude/skills/pelizzai-writing-plans/SKILL.md' 'resolveu sozinho não entra na lista como fato consumado[\s\S]{0,20}vira pergunta' 'writing-plans: decisão aberta vira pergunta, não fato consumado'
    Check-Match '.claude/skills/pelizzai-writing-plans/SKILL.md' 'opções reais[\s\S]{0,40}recomendada' 'writing-plans: decisão aberta apresentada com opções reais e recomendação'
    Check-Match '.claude/skills/pelizzai-writing-plans/SKILL.md' 'plano só fecha quando[\s\S]{0,40}ratificada' 'writing-plans: plano só fecha com toda decisão material ratificada'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'Desvios do plano:' 'task-cycle exige o campo Desvios do plano no relatório'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'confere esse campo antes de aceitar' 'task-cycle: coordenador confere Desvios do plano antes de aceitar DONE'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'não está aprovada[\s\S]{0,40}apresente antes de implementar' 'task-cycle fixa o teste operacional de desvio no briefing'

    # -- D6: review de duas lentes com cegueira assimétrica + coordenador separado + especialistas por área --
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'lente spec NÃO recebe o relatório do implementador[\s\S]{0,60}julga o código contra o contrato' 'review: a lente spec é cega (âncora literal D6)'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'cegueira assimétrica' 'review nomeia a cegueira assimétrica das duas lentes'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'nunca[\s\S]{0,4}é a lente cega' 'review: o coordenador nunca é a lente cega'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'lente que recebe o relatório' 'review: a lente evidência recebe e verifica o relatório do autor'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'cegueira assimétrica das duas lentes entra no' 'review: a cegueira assimétrica das duas lentes vive no split'
    Check-Match '.claude/skills/pelizzai-review/references/spec-reviewer.md' 'lente spec NÃO recebe o relatório do implementador' 'spec-reviewer é a lente cega (não recebe o relatório)'
    Check-NotMatch '.claude/skills/pelizzai-review/references/spec-reviewer.md' '\{RELATÓRIO_DO_IMPLEMENTADOR\}' 'spec-reviewer (lente cega) não injeta mais o placeholder do relatório'
    Check-Match '.claude/skills/pelizzai-review/references/code-reviewer.md' '\{RELATÓRIO_DO_IMPLEMENTADOR\}' 'code-reviewer (lente evidência) recebe o placeholder do relatório'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'ESPECIALISTAS por área' 'team: papéis de implementação são especialistas por área'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' '\*\*COMPLETO\*\* de skills' 'team: cola o pacote COMPLETO de domain skills da área do papel'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'Nunca[\s\S]{0,4}implementa uma frente' 'team: o coordenador orquestra, nunca implementa a frente'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'lente spec cega' 'team: review por tarefa usa a lente spec cega'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'coordenador se despachar como a lente spec cega' 'team: anti-padrão — coordenador não se despacha como a lente cega'
    Check-Match '.claude/skills/pelizzai-subagents/SKILL.md' 'monte um ESPECIALISTA' 'subagents: monta o subagente como especialista da área'
    Check-Match '.claude/skills/pelizzai-subagents/SKILL.md' '\*\*COMPLETO\*\* de skills' 'subagents: pacote COMPLETO de domain skills da área'
    Check-Match '.claude/skills/pelizzai-subagents/SKILL.md' 'lente spec cega' 'subagents: review usa a lente spec cega; coordenador nunca é ela'

    # =====================================================================
    # Restauração pré-11/07 (2026-07-21) — F6: o revisor volta a ser cego
    # por PADRÃO. No BASE não existia perfil: toda tarefa passava por
    # spec → qualidade em estágios separados, e o review era obrigatório
    # após CADA tarefa. O `combined` (pós-BASE) fica, mas rebaixado a
    # exceção que o usuário ratifica no passo 4 do gate — porque num único
    # despacho a cegueira vira mera ordem de leitura. A outra metade da
    # correção: a lente cega passa a receber as domain skills, já que
    # cegueira é não ver a NARRATIVA do autor, não ficar sem o CONTRATO
    # do projeto.
    # =====================================================================

    # -- O review volta a ser obrigatório após CADA tarefa (âncoras do BASE) --
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'Revise cedo e sempre' 'review: princípio central do BASE restaurado'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'description:[^\n]*após CADA tarefa' 'review: a description dispara após CADA tarefa (gatilho do BASE)'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'Após CADA tarefa na execução de um plano[\s\S]{0,60}sem exceção por' 'review obrigatório após cada tarefa, sem exceção por "é simples"'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'profundidade é proporcional ao risco, a existência do review não' 'review: proporcional é a profundidade, nunca a existência do review'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'Pular o review porque .é simples' 'review: anti-padrão do BASE (pular porque "é simples") restaurado'

    # -- split é o default; combined é exceção ratificada (e não o contrário) --
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'padrão recomendado[\s\S]{0,20}é .split.' 'review: split é o perfil recomendado por padrão'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' '.combined. é[\s\S]{0,20}\*\*exceção\*\*' 'review: combined é exceção, não o caso normal'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'rebaixar para .combined. sempre exige' 'review: rebaixar para combined exige escolha explícita do usuário'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'Usar .combined. por conta própria' 'review: anti-padrão de assumir combined sem ratificação'
    Check-NotMatch '.claude/skills/pelizzai-review/SKILL.md' 'tarefa trivial/bounded segue com .combined.' 'review não volta a mandar tarefa bounded para combined por default'

    # -- A lente cega recebe as domain skills (cegueira ≠ falta de contexto do projeto) --
    Check-Match '.claude/skills/pelizzai-review/references/spec-reviewer.md' '\{SKILLS_DE_DOMÍNIO\}' 'spec-reviewer (lente cega) recebe o slot de domain skills'
    Check-Match '.claude/skills/pelizzai-review/references/spec-reviewer.md' 'Cegueira \*\*não\*\* é falta de contexto do projeto' 'spec-reviewer: cegueira é não ver a narrativa, não ficar sem o contrato'
    Check-Match '.claude/skills/pelizzai-review/references/spec-reviewer.md' 'Skills de domínio: a mudança respeita as regras' 'spec-reviewer: domain skill entra na checklist da lente cega'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'slot .\{SKILLS_DE_DOMÍNIO\}. \*\*dos dois\s+templates\*\*' 'review: o briefing cola as domain skills nos DOIS templates'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'pelizzai/domain-skills\.md' 'review nomeia o catálogo de domain skills (não só "o catálogo")'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'slot .\{SKILLS_DE_DOMÍNIO\}.\s+vazio' 'review: anti-padrão de despachar briefing com o slot de domain skills vazio'

    # -- Exceção de reutilização do review final: restringida, não removida --
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'Exceção de reutilização \(estreita, e nunca o caminho padrão\)' 'review: a exceção de reutilização é declarada estreita'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'efeito .read-only. ou .write-local., risco baixo' 'review: a exceção exige efeito local e risco baixo'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'não para dispensar a validação final' 'review: a exceção não dispensa a validação final'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'Exceção estreita:[\s\S]{0,200}read-only.*write-local' 'execution-plans espelha os limites da exceção de reutilização'

    # -- O default propagado: gate, plano, task-cycle, team e subagents ensinam o MESMO --
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'Recomendado: split — é o default' 'gate passo 4 recomenda split por padrão'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'Rebaixar para combined exige[\s\S]{0,80}sua escolha' 'gate passo 4: combined exige a escolha explícita do usuário'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' '\| .split. \(default\)' 'task-cycle: a tabela de perfis abre com split (default)'
    Check-NotMatch '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'tarefas triviais/bounded seguem com review \*\*combinado\*\*' 'task-cycle não volta a mandar tarefa bounded para combined'
    Check-Match '.claude/skills/pelizzai-writing-plans/SKILL.md' 'O default é .split., inclusive em bounded' 'writing-plans registra split como default do perfil de review'
    Check-NotMatch '.claude/skills/pelizzai-writing-plans/SKILL.md' 'review split universal' 'writing-plans não trata mais o split universal como red flag'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'perfil cego/duplo \(.split.\) é o default' 'team: split é o default do review por tarefa'
    Check-Match '.claude/skills/pelizzai-subagents/SKILL.md' '.split. por padrão' 'subagents: o perfil registrado é split por padrão'

    # -- D7: fio do gate proativo de domain skills — três pontos de captura + a audit nomeia quem invoca --
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'domain skills da stack \(proposta na borda do design\)' 'router (D7.1): kickoff lista domain skills da stack nos Artefatos'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'Gate proativo de[\s\S]{0,4}domain skills' 'router aponta ao Gate proativo na borda design→plano'
    Check-Match '.claude/skills/pelizzai-brainstorming/SKILL.md' '^\s*1\.\s+Design aprovado' 'brainstorming (D7.2): o Gate proativo é passo numerado do fechamento do design'
    Check-Match '.claude/skills/pelizzai-brainstorming/SKILL.md' 'Fechar a borda de design em projeto novo sem apresentar a proposta de domain skills' 'brainstorming: red flag de fechar o design sem propor domain skills'
    Check-Match '.claude/skills/pelizzai-writing-plans/SKILL.md' 'Checagem de cobertura de domain skills' 'writing-plans (D7.3): rede de segurança de cobertura de domain skills'
    Check-Match '.claude/skills/pelizzai-writing-plans/SKILL.md' 'ANTES da Tarefa 1' 'writing-plans: a cobertura de domain skills é decidida antes da Tarefa 1'
    Check-Match '.claude/skills/pelizzai-audit/SKILL.md' 'Quem invoca este gate' 'audit nomeia quem invoca o Gate proativo (brainstorming + writing-plans)'

    # -- F3: capacidade máxima — modelo/effort são invariantes, nunca variável de economia --
    # Restauração do estado pré-11/07 (decisão do usuário, 2026-07-21): proporcionalidade governa a
    # profundidade do PROCESSO (entrevista, TDD, perfil de review, overlays), jamais a capacidade do
    # modelo. Arquitetura, as duas lentes, o review final e a validação final da entrega são o topo.
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'modelo mais capaz[\s\S]{0,60}effort máximo' 'review final exige modelo mais capaz e effort máximo'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'passo 1 da[\s\S]{0,40}validação final da entrega' 'review final é o passo 1 da validação final da entrega'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'Rebaixar modelo ou effort num review' 'review: anti-padrão nomeia o rebaixamento de modelo/effort'
    Check-NotMatch '.claude/skills/pelizzai-review/SKILL.md' 'não force effort máximo|capacidade/effort proporcionais' 'review não reintroduz capacidade proporcional'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'modelo mais capaz disponível e effort máximo' 'validação final da entrega roda no topo de capacidade'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'rebaixar modelo/effort para economizar' 'execution-plans: o anti-padrão é rebaixar, não maximizar'
    Check-NotMatch '.claude/skills/pelizzai-execution-plans/SKILL.md' 'forçar effort máximo numa tarefa mecânica|capacidade proporcional ao risco' 'execution-plans não trata effort máximo como excesso'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'Seleção de modelo por papel' 'task-cycle §8 é seleção de modelo por papel (não capacidade por risco)'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'modelo mais capaz disponível[\s\S]{0,60}effort/reasoning no nível máximo' 'task-cycle §8 fixa modelo e effort no topo'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'nunca rebaixe modelo nem effort' 'task-cycle §8 proíbe rebaixar modelo ou effort'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'Arquitetura, os reviews[\s\S]{0,120}inegociavelmente o topo' 'task-cycle §8: arquitetura, reviews e validação final são o topo'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'nunca em capacidade do modelo' 'task-cycle §8: proporcionalidade é de processo, não de capacidade'
    Check-Match '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'o modelo já é o topo' 'task-cycle: escalada do BLOCKED não passa por subir modelo'
    Check-NotMatch '.claude/skills/pelizzai-execution-plans/references/task-cycle.md' 'Capacidade por risco e papel|capacidade e effort \*\*proporcionais\*\*|aumente capacidade' 'task-cycle §8 não volta a ser capacidade proporcional'
    Check-Match 'CLAUDE.md' 'modelo e effort não' 'CLAUDE.md: modelo e effort não variam com risco'
    Check-Match 'README.md' 'modelo mais capaz disponível e effort máximo' 'README: review final no topo de capacidade'

    # -- F7: debugging reenxerta os sinais e táticas perdidos no pivô (restauração pré-11/07/2026) --
    # O pivô proporcional FICA inteiro (triagem em 4 classes, Passo 0 de contenção, seletor por
    # efeito, sem cota de hipóteses). O que volta do BASE são as peças que ele derrubou sem
    # substituir: frases-gatilho na description, minimização do loop, causa na mensagem de commit,
    # escalada nomeada dos três fixes e a tabela de sinais do parceiro humano.
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'description:[^\n]*para de chutar' 'debugging: a description volta a citar as frases-gatilho do usuário'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'description:[^\n]*teste quebrar no meio de outra tarefa' 'debugging: a description aciona com teste quebrado no meio de outra tarefa'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'corte UM elemento por vez' 'debugging restaura a minimização (um elemento por vez)'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'Minimize o loop[^\n]*determinístico incerto[^\n]*flaky' 'debugging: a minimização é condicionada às duas classes incertas'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'todo elemento restante é load-bearing' 'debugging define o critério de parada da minimização'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'Numa causa direta isso é desperdício' 'debugging: minimizar causa direta é desperdício (proporcionalidade preservada)'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'contenção do Passo 0 vem antes de qualquer corte' 'debugging: a contenção continua precedendo a minimização'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'registrada na MENSAGEM DE COMMIT do fix' 'debugging: a causa confirmada volta para a mensagem de commit'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'Três fixes definitivos falhos param o track' 'debugging: três fixes falhos param o track'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'Três fixes que não resolvem \*\*são\*\* uma lacuna material' 'debugging liga o circuit breaker ao contrato da lacuna material'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'Acione .pelizzai-interview-me.[\s\S]{0,240}pelizzai-brainstorming' 'debugging nomeia a escalada interview-me -> brainstorming'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'Sem essa\s+discussão não existe fix nº 4' 'debugging: não há fix nº 4 sem a discussão com o usuário'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'Tentar o fix nº 4 depois de três falhas' 'debugging: red flag torna o circuit breaker observável'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' '## Sinais do parceiro humano' 'debugging tem a tabela de sinais do parceiro humano'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' '"Para de chutar"[^\n]*predição falsificável' 'debugging decodifica "para de chutar" (hipótese sem predição)'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' '"A gente tá travado\?"[^\n]*thrashing' 'debugging decodifica "a gente tá travado?" (thrashing)'
    Check-Match '.claude/skills/pelizzai-debugging/SKILL.md' 'Usa condicionalmente:[^\n]*pelizzai-interview-me' 'debugging: interview-me está no wiring da Integração'
    # As peças voltaram traduzidas, não coladas: vocabulário do HEAD (Passo/oráculo) e nenhuma das
    # absolutizações do BASE de volta junto com elas.
    Check-NotMatch '.claude/skills/pelizzai-debugging/SKILL.md' '\bfases?\s+[1-4]\b' 'debugging não recola o vocabulário morto de fases do BASE'
    Check-NotMatch '.claude/skills/pelizzai-debugging/SKILL.md' 'Gere 3.5 hipóteses' 'debugging não reintroduz a cota de 3-5 hipóteses'
    Check-NotMatch '.claude/skills/pelizzai-debugging/SKILL.md' 'NENHUM FIX SEM INVESTIGAÇÃO DA CAUSA RAIZ' 'debugging mantém o invariante proporcional (contenção pode preceder a causa)'
    Check-NotMatch '.claude/skills/pelizzai-debugging/SKILL.md' 'questione hipótese/arquitetura antes de tentar outro' 'debugging não volta ao circuit breaker anônimo (sem destino nomeado)'

    # -- F7: a quota de técnicas sai também dos carriers do reasoning --
    # `Não há quota fixa` (Carregamento progressivo) tinha dois contraditores órfãos: o teto por fase
    # nas Composições e a auxiliar numerada/justificada por impacto no eval R-14.
    Check-Match '.claude/skills/pelizzai-reasoning/SKILL.md' 'Não há teto numérico' 'reasoning: composições carregam por fase, sem teto numérico'
    Check-NotMatch '.claude/skills/pelizzai-reasoning/SKILL.md' 'teto de carregamento por fase' 'reasoning não mantém o teto órfão que contradizia "não há quota fixa"'
    Check-Match '.claude/skills/pelizzai-reasoning/evals/routing.md' 'entra por fechar essa lacuna, nunca por a\s+decisão ser de alto impacto' 'routing: técnica auxiliar entra por lacuna, não por impacto'
    Check-NotMatch '.claude/skills/pelizzai-reasoning/evals/routing.md' '\d. auxiliar OPCIONAL' 'routing não numera as auxiliares (resíduo de quota)'

    # -- Envelope de segurança dos hooks: cadence/session-start fail-open, nunca bloqueiam --
    $failOpenMjs = @('.claude/hooks/pelizzai-cadence.mjs', '.claude/hooks/pelizzai-session-start.mjs')
    $failOpenPs1 = @('.claude/hooks/pelizzai-cadence.ps1', '.claude/hooks/pelizzai-session-start.ps1')
    foreach ($h in $failOpenMjs) {
        Check-Match $h 'process\.exit\(0\)' "hook fail-open exit 0: $(Split-Path -Leaf $h)"
        Check-NotMatch $h 'process\.exit\(2\)|\bexit\(2\)' "hook advisory nunca bloqueia (sem exit 2): $(Split-Path -Leaf $h)"
    }
    foreach ($h in $failOpenPs1) {
        Check-Match $h 'exit 0' "hook fail-open exit 0: $(Split-Path -Leaf $h)"
        Check-NotMatch $h 'exit 2' "hook advisory nunca bloqueia (sem exit 2): $(Split-Path -Leaf $h)"
    }
    Check-Match '.claude/hooks/pelizzai-cadence.mjs' 'existsSync\(ledgerPath\)' 'cadence é no-op sem ledger (mjs)'
    Check-Match '.claude/hooks/pelizzai-cadence.ps1' 'Test-Path -LiteralPath \$ledger' 'cadence é no-op sem ledger (ps1)'

    # -- C4: o caminho que ARMA a cadência continua semeando o ledger/Stack baseline --
    Check-Match '.claude/skills/pelizzai-audit/SKILL.md' 'Stack baseline' 'bootstrap grava Stack baseline (âncora de drift)'
    Check-Match '.claude/skills/pelizzai-audit/SKILL.md' 'semear ledger|ledger semeado' 'bootstrap semeia o ledger (arma a cadência C4)'
    Check-Match '.claude/skills/pelizzai-writing-skills/SKILL.md' '[Ss]emeie o ledger' 'writing-skills semeia o ledger'

    # -- D1: Cadência acelerada — limiares novos travados nas DUAS pernas (paridade rigorosa) --
    # O feedback de campo troca 20/30/14/21 por 10/10/15/10 (amostragem / commits / dias-de-revisão /
    # dias-de-full-scan). A cadência muda POR DESIGN: o antigo contrato "byte-idêntico ao baseline"
    # foi aposentado. O envelope de SEGURANÇA da cadence (fail-open exit 0, sem exit 2, no-op sem
    # ledger) permanece travado acima — este bloco fixa os NÚMEROS e a paridade, não a imutabilidade.
    foreach ($cad in @('.claude/hooks/pelizzai-cadence.mjs', '.claude/hooks/pelizzai-cadence.ps1')) {
        $leaf = Split-Path -Leaf $cad
        Check-Match $cad 'EVERY\s*=\s*10\b' "cadence D1: amostragem a cada 10 interações ($leaf)"
        Check-Match $cad 'COMMIT_THRESHOLD\s*=\s*10\b' "cadence D1: limiar de 10 commits ($leaf)"
        Check-Match $cad 'DAY_THRESHOLD_REVIEW\s*=\s*10\b' "cadence D1: revisão devida em 10 dias ($leaf)"
        Check-Match $cad 'DAY_THRESHOLD_SCAN\s*=\s*15\b' "cadence D1: full-scan em 15 dias ($leaf)"
        Check-NotMatch $cad 'EVERY\s*=\s*20\b' "cadence D1: amostragem antiga (20) removida ($leaf)"
        Check-NotMatch $cad 'COMMIT_THRESHOLD\s*=\s*30\b' "cadence D1: limiar antigo de commits (30) removido ($leaf)"
        Check-NotMatch $cad 'DAY_THRESHOLD_REVIEW\s*=\s*14\b' "cadence D1: revisão antiga (14 dias) removida ($leaf)"
        Check-NotMatch $cad 'DAY_THRESHOLD_SCAN\s*=\s*21\b' "cadence D1: full-scan antigo (21 dias) removido ($leaf)"
    }
    # D1 nos TEXTOS que citam a cadência (a doutrina acompanha os hooks).
    Check-Match '.claude/skills/pelizzai-writing-skills/SKILL.md' '10 commits / 10 dias de revisão / 15 dias de full-scan' 'writing-skills cita os limiares novos (10/10/15)'
    Check-NotMatch '.claude/skills/pelizzai-writing-skills/SKILL.md' '30 commits / 14 dias' 'writing-skills não cita os limiares antigos (30/14)'
    Check-Match '.claude/skills/pelizzai-writing-skills/references/domain-skill-maintenance.md' 'a cada 10 interações' 'domain-skill-maintenance cita amostragem nova (10 interações)'
    Check-Match '.claude/skills/pelizzai-writing-skills/references/domain-skill-maintenance.md' 'count >= 10 commits OU passaram-se > 10 dias' 'domain-skill-maintenance cita o limiar de revisão novo (10/10)'
    Check-NotMatch '.claude/skills/pelizzai-writing-skills/references/domain-skill-maintenance.md' 'a cada 20 interações' 'domain-skill-maintenance não cita amostragem antiga (20)'

    # -- Writegate: enforcement de runtime opt-in (co-land com o pacote de hooks B1) --
    # A EXISTÊNCIA já é travada pelo check de refs penduradas abaixo (pelizzai-audit cita
    # pelizzai-writegate): a suíte só fica verde quando os dois arquivos do hook existem.
    # Presentes, validamos sintaxe e paridade de regras entre as duas pernas .mjs/.ps1.
    $wgMjs = Join-Path $root '.claude/hooks/pelizzai-writegate.mjs'
    $wgPs1 = Join-Path $root '.claude/hooks/pelizzai-writegate.ps1'
    if ((Test-Path -LiteralPath $wgMjs) -and (Test-Path -LiteralPath $wgPs1)) {
        Run-Native { node --check .claude/hooks/pelizzai-writegate.mjs } 'node parse writegate'
        foreach ($wgRel in @('.claude/hooks/pelizzai-writegate.mjs', '.claude/hooks/pelizzai-writegate.ps1')) {
            $leaf = Split-Path -Leaf $wgRel
            Check-Match $wgRel 'main[\s\S]{0,40}master[\s\S]{0,40}develop[\s\S]{0,40}dev' "writegate conhece as branches protegidas ($leaf)"
            Check-Match $wgRel 'kickoff[\s\S]{0,20}ratificado' "writegate chaveia no marcador kickoff: ratificado ($leaf)"
            # Restauração 2026-07-21: o enforcement das aprovações greenfield SAIU do hook. As oito
            # etapas continuam obrigatórias por texto de skill; o hook trava um único marcador (o
            # kickoff), porque catraca de arquivo travava trabalho legítimo sempre que o state ficava
            # um passo atrás da conversa. Anti-regressão: nem a constante, nem o escopo documentado.
            Check-NotMatch $wgRel 'spec-approval|domain-skills-decision|plan-approval' "writegate NÃO reintroduz enforcement das aprovações greenfield ($leaf)"
            Check-Match $wgRel 'ESCOPO DELIBERADO' "writegate documenta por que trava só o kickoff ($leaf)"
            # D2: carve-out de metadata documentado + nota de segurança (paridade das duas pernas).
            Check-Match $wgRel 'CARVE-OUT DE METADATA' "writegate documenta o carve-out de metadata do harness ($leaf)"
            Check-Match $wgRel 'de escrita de ARQUIVO' "writegate: nota de segurança — carve-out é só de escrita de arquivo, não de commit ($leaf)"
            Check-Match $wgRel 'LIMITE \(symlink\)' "writegate: nota de segurança documenta a limitação de symlink do carve-out ($leaf)"
        }
        # D2: a Regra A só bloqueia quando há PRODUTO — o carve-out é comportamento, não só comentário.
        Check-Match '.claude/hooks/pelizzai-writegate.mjs' 'isProtected && products\.length > 0' 'writegate.mjs: Regra A condiciona o bloqueio a produto (carve-out de metadata)'
        Check-Match '.claude/hooks/pelizzai-writegate.ps1' 'isProtected -and \$products\.Count -gt 0' 'writegate.ps1: Regra A condiciona o bloqueio a produto (carve-out de metadata)'

        # Fixture comportamental: repo git temporário, matriz de cenários nas DUAS pernas
        # (Regra A: isolamento; Regra B: kickoff ratificado; source mode: Regra B pulada).
        $wgTemp = Join-Path ([IO.Path]::GetTempPath()) ("pelizzai-writegate-{0}-{1}" -f $PID, [guid]::NewGuid().ToString('N'))
        $wgOutside = Join-Path ([IO.Path]::GetTempPath()) ("pelizzai-wg-out-{0}.txt" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $wgTemp | Out-Null
        try {
            git -C $wgTemp init -q
            git -C $wgTemp symbolic-ref HEAD refs/heads/main  # branch protegida deterministica
            git -C $wgTemp config user.email 'contract@pelizzai.local'
            git -C $wgTemp config user.name 'PelizzAI Contract'
            Set-Content -LiteralPath (Join-Path $wgTemp 'seed.txt') -Value 'base' -Encoding utf8
            git -C $wgTemp add seed.txt
            git -C $wgTemp commit -q -m 'base'

            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                # Regra A: branch protegida (main) + escrita de PRODUTO in-root bloqueia (exit 2).
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 2) "writegate bloqueia produto em branch protegida ($leaf)"
                # D2 CARVE-OUT: metadata do harness em pelizzai/** é LIBERADA mesmo em branch protegida
                # (exit 0) — o sistema se atualizando; o commit continua exigindo branch de tarefa.
                Check ((Invoke-Writegate $wg @{ file_path = 'pelizzai/data/state.md' } $wgTemp) -eq 0) "writegate: carve-out D2 libera metadata pelizzai/ em branch protegida ($leaf)"
                # Fora da raiz do repo permite (exit 0), mesmo em branch protegida.
                Check ((Invoke-Writegate $wg @{ file_path = $wgOutside } $wgTemp) -eq 0) "writegate permite escrita fora da raiz ($leaf)"

                # -- Matcher Bash: falsos positivos corrigidos (restauração 2026-07-21) --
                # Controle positivo primeiro: redirecionamento REAL para dentro da raiz continua
                # bloqueando. Sem ele, os checks abaixo passariam com um matcher que virou no-op.
                Check ((Invoke-Writegate $wg @{ command = 'npm test > build.log' } $wgTemp) -eq 2) "writegate bloqueia redirecionamento real para dentro da raiz ($leaf)"
                # Sinks nulos DESCARTAM saída — não são escrita de produto. `> NUL` resolvia como
                # caminho relativo dentro da raiz e travava comando legítimo.
                Check ((Invoke-Writegate $wg @{ command = 'node x.js > NUL' } $wgTemp) -eq 0) "writegate: sink nulo NUL não é escrita de produto ($leaf)"
                Check ((Invoke-Writegate $wg @{ command = 'node x.js 2> $null' } $wgTemp) -eq 0) "writegate: sink nulo `$null não é escrita de produto ($leaf)"
                Check ((Invoke-Writegate $wg @{ command = 'node x.js > /dev/null' } $wgTemp) -eq 0) "writegate: sink nulo /dev/null não é escrita de produto ($leaf)"
                # Alvo com variável de ambiente é EXPANDIDO antes de comparar com a raiz: o arquivo
                # nasce fora do repositório, logo não é produto.
                Check ((Invoke-Writegate $wg @{ command = 'npm test > $env:TEMP/build.log' } $wgTemp) -eq 0) "writegate expande `$env:VAR antes de decidir ($leaf)"
                Check ((Invoke-Writegate $wg @{ command = 'npm test > %TEMP%\build.log' } $wgTemp) -eq 0) "writegate expande %VAR% antes de decidir ($leaf)"
                # Variável irresolvível → alvo indecidível → fail-open (mesma honestidade do matcher).
                Check ((Invoke-Writegate $wg @{ command = 'npm test > $env:PELIZZAI_NAO_EXISTE_XYZ/f.log' } $wgTemp) -eq 0) "writegate não bloqueia alvo com variável irresolvível ($leaf)"
                # Não-regressão: `>` dentro de aspas é texto, não redirecionamento.
                Check ((Invoke-Writegate $wg @{ command = 'git commit -m "a > b"' } $wgTemp) -eq 0) "writegate não confunde texto entre aspas com redirecionamento ($leaf)"
            }

            git -C $wgTemp checkout -q -b feat/x  # branch de tarefa (nao protegida)
            New-Item -ItemType Directory -Path (Join-Path $wgTemp 'pelizzai/data') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $wgTemp 'pelizzai/data/state.md') -Value "- kickoff: <pendente>`n" -Encoding utf8
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                # Regra B (consumidor): produto sem kickoff ratificado bloqueia (exit 2).
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 2) "writegate bloqueia produto sem kickoff ratificado ($leaf)"
                # Artefato de setup em pelizzai/ sempre liberado (exit 0).
                Check ((Invoke-Writegate $wg @{ file_path = 'pelizzai/data/state.md' } $wgTemp) -eq 0) "writegate libera artefato de setup em pelizzai/ ($leaf)"
            }

            Set-Content -LiteralPath (Join-Path $wgTemp 'pelizzai/data/state.md') -Value "- kickoff: ratificado 2026-07-12`n" -Encoding utf8
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                # Com kickoff ratificado, o produto é liberado (exit 0).
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 0) "writegate libera produto após kickoff ratificado ($leaf)"
            }

            # Fixture INVERTIDA (restauração 2026-07-21): um state legado que ainda traga os quatro
            # campos de aprovação em `pending` NÃO bloqueia mais — quem libera é o kickoff sozinho.
            # Ela reprova se o enforcement por campo voltar ao hook.
            Set-Content -LiteralPath (Join-Path $wgTemp 'pelizzai/data/state.md') -Value @"
- kickoff: ratificado 2026-07-12
- discovery: pending
- spec-approval: pending
- domain-skills-decision: pending
- plan-approval: pending
"@ -Encoding utf8
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 0) "writegate ignora campos de aprovação greenfield no state ($leaf)"
            }

            # Consumidor instalado via -ExportConsumer tem manifesto+sync+skills core: isso NÃO é
            # source mode (regressão da distribuição por cópia manual) — a Regra B continua valendo.
            New-Item -ItemType Directory -Path (Join-Path $wgTemp '.claude/skills/pelizzai-core') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $wgTemp 'scripts') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $wgTemp '.claude/skills/pelizzai-core/SKILL.md') -Value 'x' -Encoding utf8
            Set-Content -LiteralPath (Join-Path $wgTemp 'scripts/pelizzai-core-skills.txt') -Value 'x' -Encoding utf8
            Set-Content -LiteralPath (Join-Path $wgTemp 'scripts/sync-harness.ps1') -Value 'x' -Encoding utf8
            Set-Content -LiteralPath (Join-Path $wgTemp 'pelizzai/data/state.md') -Value "- kickoff: <pendente>`n" -Encoding utf8
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 2) "writegate: manifesto+sync no consumidor NÃO viram source mode ($leaf)"
            }

            # Source mode (sentinela dedicada scripts/pelizzai-source-repo.txt): Regra B é pulada.
            Set-Content -LiteralPath (Join-Path $wgTemp 'scripts/pelizzai-source-repo.txt') -Value 'x' -Encoding utf8
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 0) "writegate em source mode (sentinela) pula a Regra B ($leaf)"
            }
        } finally {
            if (Test-Path -LiteralPath $wgTemp) { Remove-Item -LiteralPath $wgTemp -Recurse -Force }
            if (Test-Path -LiteralPath $wgOutside) { Remove-Item -LiteralPath $wgOutside -Force }
        }
    } else {
        Write-Host "SKIP: pelizzai-writegate ausente (co-land com o pacote de hooks B1; existência travada pelo check de refs penduradas). Fixtures comportamentais: pendência para co-autoria com o hook."
    }

    # -- Sentinela dedicada de source mode + distribuição consumidor segura --
    Check (Test-Path (Join-Path $root 'scripts/pelizzai-source-repo.txt')) 'sentinela de repo-fonte existe no fonte'
    Check-Match 'scripts/pelizzai-source-repo.txt' 'NUNCA copie' 'sentinela documenta a proibição de cópia'
    foreach ($sf in @('.claude/hooks/pelizzai-writegate.mjs', '.claude/hooks/pelizzai-writegate.ps1', '.claude/hooks/pelizzai-session-start.mjs', '.claude/hooks/pelizzai-session-start.ps1', '.claude/skills/pelizzai-audit/SKILL.md', '.claude/skills/pelizzai-router/SKILL.md', 'CLAUDE.md')) {
        Check-Match $sf 'pelizzai-source-repo\.txt' "source mode detectado pela sentinela dedicada ($sf)"
    }
    foreach ($sf in @('.claude/hooks/pelizzai-writegate.mjs', '.claude/hooks/pelizzai-writegate.ps1', '.claude/hooks/pelizzai-session-start.mjs', '.claude/hooks/pelizzai-session-start.ps1')) {
        Check-NotMatch $sf 'pelizzai-core-skills' "hook não usa o manifesto como sentinela de source mode ($sf)"
    }
    Check (Test-Path (Join-Path $root 'scripts/sync-harness.mjs')) 'sync portátil Node existe'
    Check (Test-Path (Join-Path $root 'scripts/sync-harness.ps1')) 'wrapper PowerShell existe'
    Check (Test-Path (Join-Path $root 'scripts/sync-harness.sh')) 'wrapper macOS/Linux existe'
    Check-Match 'scripts/sync-harness.mjs' 'exportConsumer' 'sync portátil tem distribuição de consumidor'
    Check-Match 'scripts/sync-harness.mjs' "rmSync\(join\(targetScripts, 'pelizzai-source-repo\.txt'\)" 'export portátil remove sentinela do consumidor'
    Check-Match 'scripts/sync-harness.ps1' 'sync-harness\.mjs' 'wrapper PowerShell delega ao núcleo portátil'
    Check-Match 'scripts/sync-harness.sh' 'sync-harness\.mjs' 'wrapper Unix delega ao núcleo portátil'
    Run-Native { node --check scripts/sync-harness.mjs } 'node parse sync portátil'
    Run-Native { node --check scripts/install-hooks.mjs } 'node parse instalador de hooks'

    # Instalador de hooks: merge idempotente e remoção cirúrgica.
    $hooksTemp = Join-Path ([IO.Path]::GetTempPath()) ("pelizzai-hooks-test-" + [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType Directory -Path (Join-Path $hooksTemp '.claude/hooks') -Force | Out-Null
        Copy-Item -Path (Join-Path $root '.claude/hooks/*') -Destination (Join-Path $hooksTemp '.claude/hooks') -Force
        $settingsPath = Join-Path $hooksTemp '.claude/settings.json'
        @'
{
  "permissions": { "deny": ["Bash(rm -rf:*)"] },
  "hooks": { "PreToolUse": [ { "matcher": "Read", "hooks": [ { "type": "command", "command": "echo custom" } ] } ] }
}
'@ | Set-Content -LiteralPath $settingsPath -Encoding utf8 -NoNewline
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp } 'instalador registra hooks preservando settings'
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp } 'instalador de hooks é idempotente'
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp --check } 'check confirma hooks registrados'
        $installedSettings = Get-Content -LiteralPath $settingsPath -Raw -Encoding utf8
        Check ([regex]::Matches($installedSettings, 'pelizzai-(?:guardrails|writegate|cadence|session-start)\.mjs').Count -eq 5) 'instalador não duplica handlers PelizzAI'
        Check ($installedSettings -match 'echo custom') 'instalador preserva hook existente'
        Check ($installedSettings -match 'Bash\(rm -rf:\*\)') 'instalador preserva permissões existentes'
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp --remove } 'instalador remove somente hooks PelizzAI'
        $removedSettings = Get-Content -LiteralPath $settingsPath -Raw -Encoding utf8
        Check ($removedSettings -notmatch 'pelizzai-(?:guardrails|writegate|cadence|session-start)\.mjs') 'remoção elimina handlers PelizzAI'
        Check ($removedSettings -match 'echo custom' -and $removedSettings -match 'Bash\(rm -rf:\*\)') 'remoção preserva configurações alheias'

        # Restauração 2026-07-21: hook é OPT-IN, um a um e com confirmação — nunca imposto em bloco.
        # `--only` torna a doutrina operável e `--check` vira INVENTÁRIO: instalação parcial é
        # escolha legítima do usuário, não defeito. Sem esta rede, o instalador volta a tratar
        # "faltou hook" como falha e o bootstrap volta a empurrar os quatro de uma vez.
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp --only cadence } 'instalador --only registra apenas o hook pedido'
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp --check } 'check tolera instalação parcial deliberada (opt-in não é falha)'
        $null = & node scripts/install-hooks.mjs --project $hooksTemp --check --only writegate 2>&1
        Check ($LASTEXITCODE -eq 1) 'check --only reprova hook explicitamente pedido e ausente'
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp --only guardrails,writegate } 'instalador --only é aditivo (não derruba hook já aceito)'
        $partialSettings = Get-Content -LiteralPath $settingsPath -Raw -Encoding utf8
        Check ($partialSettings -match 'pelizzai-cadence\.mjs' -and $partialSettings -match 'pelizzai-guardrails\.mjs' -and [regex]::Matches($partialSettings, 'pelizzai-writegate\.mjs').Count -eq 2) 'instalador --only preserva o hook anterior e registra os dois matchers do writegate'
        Check ($partialSettings -notmatch 'pelizzai-session-start\.mjs') 'instalador --only não instala hook fora da lista'
        $null = & node scripts/install-hooks.mjs --project $hooksTemp --only inexistente 2>&1
        Check ($LASTEXITCODE -eq 1) 'instalador rejeita id desconhecido em --only'
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp --remove } 'instalador limpa o estado parcial ao final'
    } finally {
        if (Test-Path -LiteralPath $hooksTemp) { Remove-Item -LiteralPath $hooksTemp -Recurse -Force }
    }

    # -- Paridade multi-superfície: não-negociáveis chegam ao AGENTS.md gerado E ao Cursor --
    Check-Match 'AGENTS.md' 'Gate de ratificação' 'AGENTS.md gerado recebe o gate de ratificação'
    Check-Match 'GEMINI.md' 'Gate de ratificação' 'GEMINI.md gerado recebe o gate de ratificação'
    Check-Match 'AGENTS.md' 'team[^\n]{0,30}visível' 'AGENTS.md: team sempre visível no modo'
    Check-Match 'AGENTS.md' 'squash-final[^\n]{0,30}só a pedido explícito' 'AGENTS.md: squash-final só a pedido explícito'
    $parityAnchors = @(
        @{ Name = 'proteção de branch'; Pattern = 'master[\s\S]{0,30}develop' },
        @{ Name = 'gate de primeira escrita'; Pattern = 'primeira escrita' },
        @{ Name = 'gate de ratificação (team visível)'; Pattern = 'team[^\n]{0,30}sempre vis[íi]vel' }
    )
    $agentsText = Text 'AGENTS.md'
    $cursorText = Text '.cursor/rules/pelizzai.mdc'
    foreach ($a in $parityAnchors) {
        $inAgents = [regex]::IsMatch($agentsText, $a.Pattern, 'IgnoreCase, Multiline')
        $inCursor = [regex]::IsMatch($cursorText, $a.Pattern, 'IgnoreCase, Multiline')
        Check ($inAgents -and $inCursor) "não-negociável em AGENTS.md e Cursor: $($a.Name)" "agents=$inAgents cursor=$inCursor"
    }

    # Referências penduradas: todo token pelizzai-* citado nas skills existe de fato.
    $hookNames = @(Get-ChildItem -LiteralPath (Join-Path $root '.claude/hooks') -File |
        ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_.Name) } | Sort-Object -Unique)
    $knownTokens = @($dirNames) + $hookNames + @('pelizzai-core-skills', 'pelizzai-source-repo')
    $danglingRefs = [System.Collections.Generic.List[string]]::new()
    foreach ($doc in @(Get-ChildItem -LiteralPath $skillRoot -Recurse -File -Filter '*.md')) {
        $content = Get-Content -LiteralPath $doc.FullName -Raw -Encoding utf8
        foreach ($m in [regex]::Matches($content, 'pelizzai-[a-z][a-z0-9-]*')) {
            if ($knownTokens -notcontains $m.Value) { $danglingRefs.Add("$($doc.Name): $($m.Value)") }
        }
    }
    $danglingRefs = @($danglingRefs | Sort-Object -Unique)
    Check ($danglingRefs.Count -eq 0) 'skills não citam pelizzai-* inexistente' ($danglingRefs -join '; ')

    # Core e router concordam sobre o catálogo de head skills.
    $coreText = Text '.claude/skills/pelizzai-core/SKILL.md'
    $routerText = Text '.claude/skills/pelizzai-router/SKILL.md'
    $coreHeadsSection = [regex]::Match($coreText, '(?s)### Head skills.*?### Overlays').Value
    $coreHeads = @([regex]::Matches($coreHeadsSection, 'pelizzai-[a-z][a-z0-9-]*') |
        ForEach-Object { $_.Value } | Sort-Object -Unique)
    $headsMissingInRouter = @($coreHeads | Where-Object { $routerText -notmatch [regex]::Escape($_) })
    Check ($coreHeads.Count -ge 8 -and $headsMissingInRouter.Count -eq 0) `
        'router roteia toda head skill anunciada pelo core' "faltando=$($headsMissingInRouter -join ',')"

    # Matriz efeito→prova: as cópias distribuídas concordam nas âncoras essenciais.
    $proofMatrixFiles = @(
        '.claude/skills/pelizzai-reasoning/SKILL.md',
        '.claude/skills/pelizzai-tdd/SKILL.md',
        '.claude/skills/pelizzai-execution-plans/references/task-cycle.md',
        '.claude/skills/pelizzai-writing-plans/SKILL.md',
        '.claude/skills/pelizzai-quick-fix/SKILL.md',
        '.claude/skills/pelizzai-verification-before-completion/SKILL.md',
        '.claude/skills/pelizzai-preferences/SKILL.md'
    )
    $proofAnchors = @(
        @{ Name = 'refactor->characterization'; Effect = 'refator|refactor'; Proof = 'caracteriza|characterization' },
        @{ Name = 'config/IaC->validate/dry-run'; Effect = 'IaC|migra|config'; Proof = 'validate|dry-run|\bplan\b' },
        @{ Name = 'UI->pelizzai-frontend'; Effect = 'UI|visual|frontend'; Proof = 'pelizzai-frontend' },
        @{ Name = 'docs->prova estática'; Effect = 'doc'; Proof = 'lint|render|est[áa]tic|static|inspeç' }
    )
    foreach ($file in $proofMatrixFiles) {
        $skillName = ($file -split '/')[2]
        $matrixLines = (Text $file) -split "`r?`n"
        foreach ($anchor in $proofAnchors) {
            $hit = @($matrixLines | Where-Object { $_ -match $anchor.Effect -and $_ -match $anchor.Proof })
            Check ($hit.Count -ge 1) "matriz efeito→prova ($($anchor.Name)) em $skillName" $file
        }
    }

    # Regra do 1% restaurada por decisão do usuário (2026-07-21): o hook de sessão a reafirma no
    # startup, nas duas variantes, junto com o bloco EXTREMELY-IMPORTANT da pelizzai-core.
    foreach ($sh in @('.claude/hooks/pelizzai-session-start.mjs', '.claude/hooks/pelizzai-session-start.ps1')) {
        Check-Match $sh 'regra do 1%' "hook de sessão reafirma a regra do 1% ($(Split-Path -Leaf $sh))"
    }

    # Guardrails equivalentes: somente classificam strings, nenhum comando Git é executado.
    $hooks = @(
        (Join-Path $root '.claude/hooks/pelizzai-guardrails.mjs'),
        (Join-Path $root '.claude/hooks/pelizzai-guardrails.ps1')
    )
    $safe = @('git status', 'Git push --force-with-lease origin topic', 'git restore --staged .', 'git restore -S file.txt', 'git branch -d merged', 'git branch -m old new')
    # Fora do escopo ESTREITO do hook — passam DE PROPÓSITO. O hook mira o punhado de comandos que
    # apagam trabalho de forma irrecuperável; regra larga trava trabalho legítimo e ensina o agente a
    # contornar a rede de segurança. Estas fixtures existem para que o estreitamento seja deliberado
    # e visível: se alguém voltar a alargar o matcher, elas quebram e a decisão volta ao usuário.
    $safeByDesign = @(
        'git push origin +HEAD:main', 'git push origin +main', 'git push origin --delete topic',
        'git push origin :topic', 'git checkout -f topic', 'git checkout -B topic main',
        'git checkout -- file.txt', 'git branch --delete --force topic', 'git branch -M main',
        'git restore file.txt', 'git restore -SW file.txt',
        'git commit -m "fix: restore layout"', 'git add src/restore.ts', 'git log --grep=restore'
    )
    $blocked = @(
        'git push -f origin topic', 'Git reset --hard', 'git switch -C topic',
        'git clean -fd', 'git restore .', 'git checkout .', 'git checkout -- .',
        'git branch -D topic', 'git worktree remove --force ../topic'
    )
    foreach ($hook in $hooks) {
        $label = Split-Path -Leaf $hook
        foreach ($command in ($safe + $safeByDesign)) {
            $exit = Invoke-Guardrail $hook $command
            Check ($exit -eq 0) "$label permite: $command" "exit $exit"
        }
        foreach ($command in $blocked) {
            $exit = Invoke-Guardrail $hook $command
            Check ($exit -eq 2) "$label bloqueia: $command" "exit $exit"
        }
    }

    # Sintaxe e interface dos scripts visuais.
    Run-Native { node --check .claude/hooks/pelizzai-guardrails.mjs } 'node parse guardrails'
    Run-Native { node --check .claude/skills/pelizzai-brainstorming/scripts/server.cjs } 'node parse visual server'
    $bash = Get-Command bash -ErrorAction SilentlyContinue
    $bashUsable = $false
    if ($bash -and $bash.Source -notmatch '(?i)[\\/]Windows[\\/]System32[\\/]bash\.exe$') {
        $null = & bash --version 2>$null
        $bashUsable = ($LASTEXITCODE -eq 0)
    }
    if ($bashUsable) {
        Run-Native { bash -n .claude/skills/pelizzai-brainstorming/scripts/start-server.sh } 'bash parse visual launcher'
        Run-Native { bash -n scripts/review-package.sh } 'bash parse review package'
    }
    $help = & pwsh -NoProfile -File .claude/skills/pelizzai-brainstorming/scripts/start-server.ps1 -Help 2>&1
    Check ($LASTEXITCODE -eq 0 -and ($help -join "`n") -match 'IdleTimeoutMinutes') 'PowerShell visual launcher expõe help'

    # Fixtures dos helpers de handoff/review, em repo temporário isolado.
    $temp = Join-Path ([IO.Path]::GetTempPath()) ("pelizzai-contract-{0}-{1}" -f $PID, [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $temp | Out-Null
    git -C $temp init -q
    git -C $temp config user.email 'contract@pelizzai.local'
    git -C $temp config user.name 'PelizzAI Contract'
    Set-Content -LiteralPath (Join-Path $temp 'seed.txt') -Value 'base' -Encoding utf8
    git -C $temp add seed.txt
    git -C $temp commit -q -m 'test: base'
    $baseSha = (git -C $temp rev-parse HEAD).Trim()

    Push-Location $temp
    try {
        New-Item -ItemType Directory -Path 'pelizzai/plans' -Force | Out-Null
        @'
# Plano fixture

**Global Constraints:**
- global-contract-sentinel
```text
### Tarefa 99: header dentro de fence
```

---

### Tarefa 1: primeira

- task-one-sentinel
```text
### Tarefa 2: também dentro de fence
```

### Tarefa 2: segunda

- task-two-sentinel
'@ | Set-Content -LiteralPath 'pelizzai/plans/fixture.md' -Encoding utf8

        $briefOut = @(& pwsh -NoProfile -File (Join-Path $root 'scripts/task-brief.ps1') 'pelizzai/plans/fixture.md' 1)
        $briefPath = $briefOut[-1]
        $handoffCleanup = Split-Path -Parent $briefPath
        $brief = Get-Content -LiteralPath $briefPath -Raw
        Check ($brief -match 'global-contract-sentinel' -and $brief -match 'task-one-sentinel' -and $brief -notmatch 'task-two-sentinel') `
            'task-brief preserva constraints e limites de fence'
        Check (-not (Test-Path -LiteralPath 'pelizzai/data/handoffs')) 'helper sem bootstrap usa temp, não runtime do projeto'

        Set-Content -LiteralPath 'seed.txt' -Value 'unstaged-review-sentinel' -Encoding utf8
        Set-Content -LiteralPath 'staged.txt' -Value 'staged-review-sentinel' -Encoding utf8
        git add staged.txt
        Set-Content -LiteralPath 'untracked.txt' -Value 'untracked-review-sentinel' -Encoding utf8
        Set-Content -LiteralPath 'credentials.json' -Value 'sensitive-review-sentinel' -Encoding utf8

        $workingOut1 = @(& pwsh -NoProfile -File (Join-Path $root 'scripts/review-package.ps1') '--working-tree')
        $workingPath1 = $workingOut1[-1]
        $working = Get-Content -LiteralPath $workingPath1 -Raw
        Check ($working -match 'unstaged-review-sentinel' -and $working -match 'staged-review-sentinel' -and $working -match 'untracked-review-sentinel') `
            'review working-tree inclui unstaged, staged e untracked'
        Check ($working -match 'credentials\.json' -and $working -match 'potencialmente sensível' -and $working -notmatch 'sensitive-review-sentinel') `
            'review package não lê untracked sensível'

        $workingOut2 = @(& pwsh -NoProfile -File (Join-Path $root 'scripts/review-package.ps1') '--working-tree')
        Check ($workingOut2[-1] -ne $workingPath1) 'review packages têm nomes únicos'

        git add seed.txt staged.txt untracked.txt
        git commit -q -m 'feat: contract sentinels'
        $headSha = (git rev-parse HEAD).Trim()
        $rangeOut = @(& pwsh -NoProfile -File (Join-Path $root 'scripts/review-package.ps1') $baseSha $headSha)
        $range = Get-Content -LiteralPath $rangeOut[-1] -Raw
        Check ($range -match 'unstaged-review-sentinel' -and $range -match 'staged-review-sentinel' -and $range -match 'untracked-review-sentinel') `
            'review final cobre base-sha..HEAD'

        New-Item -ItemType Directory -Path 'pelizzai' -Force | Out-Null
        Set-Content -LiteralPath 'pelizzai/.gitignore' -Value "data/handoffs/`n" -Encoding utf8
        $consumerOut = @(& pwsh -NoProfile -File (Join-Path $root 'scripts/review-package.ps1') '--working-tree')
        $expectedConsumer = Join-Path (Get-Location).Path 'pelizzai/data/handoffs'
        Check ((Split-Path -Parent $consumerOut[-1]) -eq $expectedConsumer) 'helper consumidor usa handoff gitignored'
    } finally {
        Pop-Location
    }
} catch {
    Check $false 'execução da suíte' $_.Exception.Message
} finally {
    Set-Location $previous
    if ($temp -and (Test-Path -LiteralPath $temp) -and (Split-Path -Leaf $temp) -like 'pelizzai-contract-*') {
        Remove-Item -LiteralPath $temp -Recurse -Force
    }
    if ($handoffCleanup -and (Test-Path -LiteralPath $handoffCleanup)) {
        $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
        $resolvedHandoff = [IO.Path]::GetFullPath($handoffCleanup)
        $handoffLeaf = Split-Path -Leaf $resolvedHandoff
        $handoffParentLeaf = Split-Path -Leaf (Split-Path -Parent $resolvedHandoff)
        if ($resolvedHandoff.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and
            ($handoffLeaf -like 'pelizzai-handoffs*' -or $handoffParentLeaf -eq 'pelizzai-handoffs')) {
            Remove-Item -LiteralPath $resolvedHandoff -Recurse -Force
        }
    }
}

Write-Host "`nResultado: $passes PASS; $($failures.Count) FAIL."
if ($failures.Count -gt 0) {
    foreach ($failure in $failures) { Write-Host " - $failure" }
    exit 1
}
exit 0
