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
    Check-Match '.claude/skills/pelizzai-writing-plans/SKILL.md' 'combined[\s\S]*split' 'plano escolhe perfil de review'
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
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'worktree.*não isola agentes|um writer por vez' 'team não paraleliza writers na mesma working tree'
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
    Check-Match '.claude/skills/pelizzai-execution-plans/templates/state.md' 'discovery:[\s\S]*spec-approval:[\s\S]*domain-skills-decision:[\s\S]*plan-approval:' 'state.md registra aprovações greenfield'

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
    Check-Match '.claude/skills/pelizzai-execution-plans/templates/state.md' '~150 linhas' 'state.md: nudge de compactação em ~150 linhas'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'Higiene do progresso' 'execution-plans tem a seção Higiene do progresso'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'uma linha por tarefa' 'execution-plans: uma linha por tarefa no progresso'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' '~150 linhas' 'execution-plans: nudge de compactação em ~150 linhas'
    Check-Match '.claude/skills/pelizzai-execution-plans/SKILL.md' 'data/history/[\s\S]{0,40}VERSIONADO' 'execution-plans: migração de bloco íntegro para history/ versionado'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' '~150 linhas' 'finish-task: nudge de state volumoso (~150 linhas)'
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'data/history/' 'finish-task cita a migração para history/ na constatação de done'
    Check-Match '.claude/skills/pelizzai-audit/SKILL.md' '^data/reports/\s*$' 'audit: reports/ permanece ignorado (efêmero)'
    Check-NotMatch '.claude/skills/pelizzai-audit/SKILL.md' '^data/history/\s*$' 'audit: history/ NÃO é ignorado no template (registro durável versionado)'
    Check-Match '.claude/skills/pelizzai-audit/SKILL.md' 'history/\s+versionado' 'audit: history/ no Layout canônico marcado como versionado (durável, fora do ignore)'

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
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'cegueira assimétrica das duas lentes entra no' 'review: proporcionalidade — combined trivial, cegueira entra no split'
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
            Check-Match $wgRel 'discovery[\s\S]{0,80}spec-approval[\s\S]{0,80}domain-skills-decision[\s\S]{0,80}plan-approval' "writegate protege aprovações greenfield ($leaf)"
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

            Set-Content -LiteralPath (Join-Path $wgTemp 'pelizzai/data/state.md') -Value @"
- kickoff: ratificado 2026-07-12
- discovery: pending
- spec-approval: pending
- domain-skills-decision: pending
- plan-approval: pending
"@ -Encoding utf8
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 2) "writegate bloqueia produto com aprovação greenfield pendente ($leaf)"
            }

            Set-Content -LiteralPath (Join-Path $wgTemp 'pelizzai/data/state.md') -Value @"
- kickoff: ratificado 2026-07-12
- discovery: ratificada 2026-07-12
- spec-approval: ratificada 2026-07-12
- domain-skills-decision: ratificada 2026-07-12
- plan-approval: ratificado 2026-07-12
"@ -Encoding utf8
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 0) "writegate libera produto após aprovações greenfield ($leaf)"
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
