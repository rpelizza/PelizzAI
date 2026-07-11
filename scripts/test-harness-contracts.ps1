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
    Check-Match '.claude/skills/pelizzai-finish-task/SKILL.md' 'manter local[^\n]*default|mantenha local' 'finish mantém local sem menu inútil'
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

    # Referências penduradas: todo token pelizzai-* citado nas skills existe de fato.
    $hookNames = @(Get-ChildItem -LiteralPath (Join-Path $root '.claude/hooks') -File |
        ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_.Name) } | Sort-Object -Unique)
    $knownTokens = @($dirNames) + $hookNames + @('pelizzai-core-skills')
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

    $sessionHooks = (Text '.claude/hooks/pelizzai-session-start.mjs') + (Text '.claude/hooks/pelizzai-session-start.ps1')
    Check (-not [regex]::IsMatch($sessionHooks, 'regra do 1%')) 'hook de sessão não reintroduz regra do 1%'

    # Guardrails equivalentes: somente classificam strings, nenhum comando Git é executado.
    $hooks = @(
        (Join-Path $root '.claude/hooks/pelizzai-guardrails.mjs'),
        (Join-Path $root '.claude/hooks/pelizzai-guardrails.ps1')
    )
    $safe = @('git status', 'Git push --force-with-lease origin topic', 'git restore --staged .', 'git restore -S file.txt', 'git branch -d merged', 'git branch -m old new')
    $blocked = @(
        'git push -f origin topic', 'Git reset --hard', 'git push origin +HEAD:main',
        'git push origin +main', 'git push origin --delete topic', 'git push origin :topic',
        'git checkout -f topic', 'git checkout -B topic main', 'git checkout -- file.txt',
        'git switch -C topic', 'git branch --delete --force topic', 'git branch -M old new',
        'git clean -fd', 'git restore .', 'git restore file.txt', 'git restore -SW file.txt',
        'git worktree remove --force ../topic'
    )
    foreach ($hook in $hooks) {
        $label = Split-Path -Leaf $hook
        foreach ($command in $safe) {
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
