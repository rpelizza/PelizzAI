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

    # SKILL.md: minimum frontmatter and consistent identity.
    $skillRoot = Join-Path $root '.claude/skills'
    $skillDirs = @(Get-ChildItem -LiteralPath $skillRoot -Directory | Sort-Object Name)
    foreach ($dir in $skillDirs) {
        $skillFile = Join-Path $dir.FullName 'SKILL.md'
        if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
            Check $false "frontmatter $($dir.Name)" 'SKILL.md missing'
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

    # Source repo: the manifest is an exact set, with no duplicates.
    $manifest = @(Get-Content scripts/pelizzai-core-skills.txt | ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and $_ -notmatch '^#' })
    $dirNames = @($skillDirs.Name)
    $missing = @($dirNames | Where-Object { $manifest -notcontains $_ })
    $dangling = @($manifest | Where-Object { $dirNames -notcontains $_ })
    $duplicates = @($manifest | Group-Object | Where-Object Count -gt 1)
    Check ($missing.Count -eq 0 -and $dangling.Count -eq 0 -and $duplicates.Count -eq 0) `
        'source repo manifest is exact' "missing=$($missing -join ',') dangling=$($dangling -join ',')"

    # Interoperable mirror: same paths and same hashes.
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
    Check ($treeDiff.Count -eq 0 -and $hashDiff -eq 0) '.agents mirrors .claude' "paths=$($treeDiff.Count) hashes=$hashDiff"

    # Core contracts: decision, effects, and composition.
    Check-Match '.claude/skills/pelizzai-core/SKILL.md' 'read-only' 'core recognizes the read-only effect'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'effect.*risk.*uncertainty.*surfaces' 'router classifies the envelope'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'one head skill|exactly one.*head' 'router chooses one head skill'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'bounded[\s\S]*standard[\s\S]*exploratory' 'router has adaptive lanes'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'before the first write|first-write' 'router protects the first write'
    Check-Match '.claude/skills/pelizzai-onboard/SKILL.md' 'scan-only' 'audit has a scan-only mode'
    # v3 slice 1b: the triage taxonomy left the description (trigger format) and lives in the body
    # table — the guarantee moved, it did not vanish; the assertion follows it.
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'direct cause[\s\S]*Uncertain deterministic[\s\S]*flaky[\s\S]*incident' 'debugging triages proportionally'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'Do not invent a hypothesis count|never.*fixed number' 'debugging does not fix a hypothesis count'
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' 'Test/validation strategy|Primary strategy' 'task-cycle picks proof by artifact'
    Check-Match '.claude/skills/pelizzai-plan/templates/plan.md' 'Cross-cutting harness skills' 'plan propagates overlays'
    # The combined→split order was the old default; what matters is the plan RECORDING the profile
    # with both values named (the default itself lives in the F6 block, below).
    # v3 slice 3: the profile choice is gone — one dispatch, both verdicts; the plan records DEPTH.
    Check-Match '.claude/skills/pelizzai-plan/SKILL.md' 'review shape is fixed, not planned[\s\S]{0,200}review DEPTH' 'plan records review depth, never a profile'
    Check-NotMatch '.claude/skills/pelizzai-plan/SKILL.md' 'interview-me[^\n]*(MANDATORY|mandatory)' 'bounded plan does not force an interview'
    Check-Match '.claude/skills/pelizzai-interface/SKILL.md' 'mandatory overlay' 'frontend is a mandatory overlay for UI'
    Check-Match '.claude/skills/pelizzai-interface/SKILL.md' 'existing brand or design system.*is.*the direction' 'frontend honors an existing brand/design system'
    Check-Match '.claude/skills/pelizzai-interface/SKILL.md' 'generic AI convergence' 'frontend names the anti-convergence failure mode'
    Check-Match '.claude/skills/pelizzai-security/SKILL.md' 'Software Supply Chain Failures[\s\S]*Mishandling of Exceptional Conditions' 'OWASP uses 2025 categories'
    Check-NotMatch '.claude/skills/pelizzai-security/SKILL.md' 'Offered by.*finish-task' 'security is not a late offer'
    Check-NotMatch '.claude/skills/pelizzai-docs/SKILL.md' 'Offered by.*finish-task' 'documentation is not a late offer'
    Check-Match '.claude/skills/pelizzai-verify/SKILL.md' 'validated-head' 'Verification seals validated content'
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' 'metadata-only' 'finish limits closeout to metadata'
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' 'Offer the destination[\s\S]{0,180}Keep local[^\n]*recommend' 'finish presents the destination with local recommended'
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' 'never auto-confirmed' 'finish requires an explicit decision even to keep local'
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' 'Source mode[\s\S]*not.*state|source mode[\s\S]*not.*state' 'finish creates no runtime in source mode'
    # v3 slice 1: these three patterns used the skill names WITHOUT the pelizzai- prefix, so the
    # anchored token rename could not reach them — re-anchored on the new prefixed names.
    Check-Match '.claude/skills/pelizzai-quick-fix/SKILL.md' 'Commit[\s\S]*pelizzai-verify[\s\S]*pelizzai-finish' 'quick-fix commits before the seal'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'Review[\s\S]*Consolidate[\s\S]*pelizzai-verify[\s\S]*pelizzai-finish' 'debugging reviews, commits, and seals in order'
    Check-Match '.claude/skills/pelizzai-onboard/SKILL.md' 'commit[\s\S]*pelizzai-verify[\s\S]*pelizzai-finish' 'bootstrap commits before the seal'
    Check-Match '.cursor/rules/pelizzai.mdc' 'pelizzai-core/SKILL.md' 'Cursor points to core'
    Check-Match '.cursor/rules/pelizzai.mdc' 'pelizzai-router/SKILL.md' 'Cursor points to router'
    Check-Match '.github/workflows/check-harness.yml' '-Check -SourceMode' 'CI validates source mode'
    Check-Match '.github/workflows/check-harness.yml' 'test-harness-contracts.ps1' 'CI runs the contracts'
    # Serialization is a harness rule, not a property of Git — what ratified isolation does allow
    # (parallel work on disjoint paths) is locked in the F5 block, below.
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'worktree.*not isolate agents|one writer at a time' 'team: worktree does not isolate agents from each other'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'codebase-wide.*pelizzai-architecture' 'router separates architectural review from code review'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'risk raises proof and gates, it does not create artificial uncertainty' 'router decouples risk from discovery'
    Check-Match '.claude/skills/pelizzai-architecture/SKILL.md' 'does not create branch, state, HTML, ADR, spec, out-of-scope, or any file' 'read-only architecture does not write'
    Check-NotMatch '.claude/skills/pelizzai-architecture/SKILL.md' 'record\s+automatically|Build an HTML' 'architecture does not persist by reflex'
    Check-Match '.claude/skills/pelizzai-discovery/SKILL.md' 'source mode:[^\n]*native plan/execution record[^\n]*without creating `pelizzai/`' 'brainstorming honors source mode'
    Check-Match '.claude/skills/pelizzai-quick-fix/SKILL.md' 'source mode[^\n]*without a closure file/commit' 'quick-fix respects source mode'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'source mode[\s\S]{0,180}manifests' 'debugging discovers commands in source mode'
    Check-Match '.claude/skills/pelizzai-tdd/SKILL.md' 'source mode: use the source repo''s rules/skills' 'TDD respects source mode'
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' 'no script or no persistent plan' 'task brief accepts a native plan'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'a single bounded task[\s\S]*tree SHA' 'review: bounded exception avoids provable duplication'
    Check-Match '.claude/skills/pelizzai-interface/SKILL.md' 'verified rendered, never from source reading alone' 'frontend verifies UI claims rendered'
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' 'delivery-status: partial[\s\S]*PR was not created' 'finish represents push without PR'
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' 'delivery-status: pr-open[^\n]*URL' 'finish records the open PR'
    Check-Match '.claude/skills/pelizzai-resume/SKILL.md' 'source mode:[^\n]*native execution record; do not create state' 'recovery respects source mode'
    Check-Match '.claude/skills/pelizzai-domain-modeling/SKILL.md' 'Source mode[\s\S]*never create `pelizzai/`' 'domain modeling respects source mode'
    Check-Match '.claude/skills/pelizzai-experiment/SKILL.md' 'Source mode never creates `pelizzai/` runtime' 'prototype respects source mode'
    Check-Match '.claude/skills/pelizzai-continuity/SKILL.md' 'Never create `pelizzai/` in the source repo' 'handoff respects source mode'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'Source mode:[\s\S]*Missing state is the contract' 'execution resumption respects source mode'

    # =====================================================================
    # Intelligence contracts under user authority.
    # The harness classifies, grounds, and recommends; human decisions are
    # ratified and discovery happens one question at a time.
    # =====================================================================

    # -- Kickoff gate (router): the route is a recommendation to ratify --
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' '## Kickoff gate' 'router has a Kickoff gate section'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'proposed route' 'kickoff presents the proposed route'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'recommendation to ratify' 'kickoff is a recommendation to ratify'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'Applying isolation, execution mode, or commit strategy without user ratification' 'router: anti-silence red flag (isolation/mode/commit)'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'Silently assuming a decision that changes scope/UX/architecture' 'router: red flag against silent assumptions'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'SUBAGENT-STOP / TEAM-MEMBER-STOP\), do not produce route analyses or open the kickoff gate' 'kickoff has a SUBAGENT-STOP carve-out'

    # -- Proposal analysis + discovery reconnected (router) --
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'Proposal analysis' 'router always stresses the proposal (Proposal analysis)'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'proposal-stress\.md' 'Proposal analysis is grounded in a documented technique'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'pelizzai-interview' 'interview-me reconnected to routing (>0 mentions)'

    # -- Sequential post-plan setup gate: three options, team, squash --
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' '## Sequential post-plan setup gate' 'execution-plans has the post-plan setup gate section'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'the three options always visible' 'post-plan gate: the three options always visible'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'team is never omitted' 'post-plan gate: team is never omitted'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'squash-final only on explicit user request' 'post-plan gate: squash-final only on explicit request'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'one at a time|one question per turn' 'post-plan gate ratifies one decision per turn'
    Check-NotMatch '.claude/skills/pelizzai-execute/SKILL.md' 'autonomy between tasks' 'execution-plans does not promise decisional autonomy'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'SUBAGENT-STOP / TEAM-MEMBER-STOP' 'post-plan gate has the SUBAGENT-STOP carve-out'

    # -- writing-plans forwards to the gate and exposes gaps (without forcing an interview in bounded) --
    Check-Match '.claude/skills/pelizzai-plan/SKILL.md' 'forward to the post-plan setup gate' 'writing-plans forwards to the post-plan setup gate'
    Check-Match '.claude/skills/pelizzai-plan/SKILL.md' 'expose the material gaps' 'writing-plans exposes the material gaps'
    Check-Match '.claude/skills/pelizzai-plan/SKILL.md' 'exploratory[\s\S]{0,120}(stress|independent review)' 'writing-plans expects stress for exploratory (positive, without forcing bounded)'

    # -- brainstorming/interview: one question at a time, recommendation, spec --
    Check-Match '.claude/skills/pelizzai-discovery/SKILL.md' 'one question at a time' 'brainstorming interviews sequentially'
    Check-Match '.claude/skills/pelizzai-discovery/SKILL.md' 'Recommendation:' 'brainstorming recommends before asking'
    Check-Match '.claude/skills/pelizzai-discovery/SKILL.md' 'Skipping the entire\s+discovery requires an explicit request' 'brainstorming: skipping discovery requires a user decision'
    Check-Match '.claude/skills/pelizzai-discovery/SKILL.md' 'SUBAGENT-STOP / TEAM-MEMBER-STOP\), do not produce route analyses or open gates' 'brainstorming has the SUBAGENT-STOP carve-out'
    Check-Match '.claude/skills/pelizzai-discovery/SKILL.md' 'Do not require stress[^\n]*twice' 'brainstorming keeps the duplicate-stress guard'

    # -- interview-me: numbered exposure of the gaps --
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' 'ends with the numbered list of gaps and how each one changes the solution' 'interview-me ends with a numbered list of gaps'
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' 'without the gaps section is incomplete' 'interview-me: a summary without the gaps section is incomplete'
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' 'exactly one question per turn' 'interview-me asks exactly one question per turn'
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' 'Recommended:' 'interview-me highlights the best option'

    # -- F5: interview-me is the canonical gap-closing mechanism (pre-2026-07-11 restoration) --
    # The skill is MANDATORY again at the three BASE points (pre-design, post-design, post-plan) and
    # gains a fourth: the gap that shows up mid-execution. The anti-ceremony clause ("what is NOT a
    # gap") exists so that mandatoriness does not degenerate into a questionnaire.
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' 'This skill is the \*\*canonical\s+gap-closing mechanism\*\*' 'interview-me: the body declares the canonical gap-closing mechanism'
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' 'description:[^\n]*canonical gap-closing mechanism' 'interview-me: the description triggers on the canonical mechanism'
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' 'default,\s+convention, Context7, or .reasonable inference. is a violation' 'interview-me: filling by default/convention/Context7/inference is a violation'
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' '## Where it is mandatory[\s\S]{0,400}not an offer' 'interview-me: mandatoriness restored (not an offer)'
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' 'Before design[\s\S]{0,900}After the plan, before execution' 'interview-me mandatory before design, post-design, and post-plan'
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' 'actually identified and\s+resolved' 'interview-me only closes early with the gaps resolved or accepted'
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' '## Gap mode' 'interview-me has gap mode (mid-execution stop)'
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' 'never waives item 4' 'interview-me: bounded waives the stress, never the gap stop'
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' 'NOT a gap' 'interview-me delimits what is NOT a gap (anti-ceremony)'
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' 'mechanical step inside a boundary already ratified' 'interview-me: a ratified mechanical step does not become a question'
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' 'SUBAGENT-STOP[\s\S]{0,400}NEEDS_CONTEXT' 'interview-me: under a closed briefing the executor returns NEEDS_CONTEXT'
    Check-NotMatch '.claude/skills/pelizzai-interview/SKILL.md' 'bounded. usually waives this skill' 'interview-me: bounded does not disable the whole skill, only the design/plan stress'

    # -- F5: autonomy between tasks restored (continuous execution, stop only for a gap) --
    # Counterpart of the Check-NotMatch 'autonomy between tasks' above: the autonomy is of EXECUTION
    # (not asking "should I continue?" after every task), never of DECISION.
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'AUTONOMY \(without asking at every step\)' 'execution-plans restores autonomy between the tasks'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'not ask .should I continue\?.' 'execution-plans does not ask should-I-continue after each task'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'Stop only for: a real BLOCKED[^\n]*MATERIAL GAP' 'execution-plans: stop only for BLOCKED, material gap, invalidation, or completion'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'autonomy is of execution, never of' 'execution-plans: autonomy is of execution, never of decision'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'MATERIAL GAP is not a vague stop' 'execution-plans: a material gap has a concrete path, not a vague pause'
    Check-NotMatch '.claude/skills/pelizzai-execute/SKILL.md' 'CONTROLLED EXECUTION' 'execution-plans does not reintroduce the per-task pause'
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' '## 0\. Autonomy between tasks and the material-gap stop' 'task-cycle opens with autonomy + the material-gap stop'
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' 'consolidating means grouping and ordering by\s+dependency, NEVER deciding' 'task-cycle: the coordinator consolidates gaps, never decides them'
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' 'DOMAIN SKILL gap[\s\S]{0,200}execution does \*\*not\*\* stop' 'task-cycle preserves: a domain skill gap does not stop execution'

    # -- F5: the member names the gap, the coordinator takes it to the human (consolidating is not deciding) --
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'do not decide product gaps' 'team: member names the gap, never decides it'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'consolidating is not deciding' 'team: coordinator consolidates the gaps but does not decide'
    Check-Match '.claude/skills/pelizzai-subagents/SKILL.md' 'do not decide product gaps' 'subagents: the subagent names the gap and does not decide it'
    Check-Match '.claude/skills/pelizzai-subagents/SKILL.md' 'A material gap is the other path, and that one halts the workstream' 'subagents separates material gap (halts) from domain-skill gap (does not halt)'

    # -- F5: parallel writes in a worktree on disjoint paths (reverts 44df87c) --
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'isolation: worktree[\s\S]{0,300}disjoint paths' 'team: worktree allows parallel writes on disjoint paths'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'Disjointness is the \*\*condition\*\*' 'team: path disjointness is a condition, not advice'
    Check-NotMatch '.claude/skills/pelizzai-team/SKILL.md' 'Keep one writer at a time' 'team does not reimpose a single writer under worktree isolation'
    Check-Match '.claude/skills/pelizzai-subagents/SKILL.md' 'DISJOINT PATHS' 'subagents: parallel writes in a worktree require disjoint paths'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'Never one worktree per agent' 'execution-plans: worktree is one per task, not one per agent'

    # -- F5: callers reconnected (mandatoriness does not live inside the skill alone) --
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' '## Material gap during execution' 'router has the Material gap during execution section'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'material gap stops the work and goes back\s+to the user through .pelizzai-interview' 'router: a post-kickoff gap stops work and returns via interview-me'
    Check-Match '.claude/skills/pelizzai-core/SKILL.md' 'closed with .pelizzai-interview' 'core: user-owned gaps are closed with interview-me'
    Check-Match '.claude/skills/pelizzai-discovery/SKILL.md' 'applies to ALL\s+projects, regardless of apparent simplicity' 'brainstorming: the design hard-gate applies to ALL projects'
    Check-Match '.claude/skills/pelizzai-discovery/SKILL.md' 'stress with .pelizzai-interview. is \*\*MANDATORY\*\*' 'brainstorming: design stress is mandatory in greenfield/full'
    Check-Match 'CLAUDE.md' 'The LLM never decides alone' 'CLAUDE.md pins the contract: the LLM never decides alone'
    Check-Match 'CLAUDE.md' 'closed with .pelizzai-interview' 'CLAUDE.md: every gap is closed with interview-me'
    Check-Match '.claude/skills/pelizzai-plan/templates/plan.md' 'execution interview' 'plan provides the execution interview origin (gap plugged mid-execution)'

    # -- audit: proactive domain skills gate at the edges (propose then confirm) --
    Check-Match '.claude/skills/pelizzai-onboard/SKILL.md' 'Proactive domain skills gate' 'audit has the Proactive domain skills gate'
    Check-Match '.claude/skills/pelizzai-onboard/SKILL.md' 'design.plan and plan.execution edges' 'audit: gate at the design->plan and plan->execution edges'
    Check-Match '.claude/skills/pelizzai-onboard/SKILL.md' 'recommendation to\s+ratify' 'audit preserves propose-then-confirm'
    Check-Match '.claude/skills/pelizzai-onboard/SKILL.md' 'The plan does not start until' 'domain skills are decided before the greenfield plan'

    # -- writing-skills: context7 mandatory on creation + the adoption-driven axis --
    Check-Match '.claude/skills/pelizzai-skill-lab/SKILL.md' 'grounded in context7 or current official documentation' 'writing-skills requires context7/official docs when creating a stack skill'
    Check-Match '.claude/skills/pelizzai-skill-lab/SKILL.md' 'Mandatory sync as part of the edit' 'writing-skills syncs automatically after an authorized edit'
    Check-Match '.claude/skills/pelizzai-skill-lab/SKILL.md' 'node scripts/sync-harness\.mjs[\s\S]*--check' 'writing-skills runs the portable sync and check'
    Check-Match '.claude/skills/pelizzai-skill-lab/references/domain-skill-maintenance.md' '[Aa]doption-driven' 'domain-skill-maintenance has the adoption-driven axis (creates the new-stack skill)'

    # -- finish-task: proactive destination (local by default, external per task) --
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' 'Ask a single question and wait' 'finish-task asks for the destination and waits'
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' 'never\s+applied from a\s+profile default' 'finish-task: push/PR/discard confirmed per task (destination not inherited)'

    # -- Entry doctrine (CLAUDE.md) --
    Check-Match 'CLAUDE.md' 'Recommend and ratify:' 'CLAUDE.md pins the recommend-and-ratify doctrine'
    Check-Match 'CLAUDE.md' 'reasoning belongs to the harness; deciding belongs to the user' 'CLAUDE.md separates reasoning from authority'
    Check-Match 'CLAUDE.md' 'greenfield product/project is never bounded' 'CLAUDE.md protects the greenfield flow'
    Check-Match 'CLAUDE.md' 'structural decisions[\s\S]{0,320}never (as a )?silent default' 'CLAUDE.md: structural decisions never use a silent default'

    # -- Machine-readable markers in state.md (writegate/resumption schema) --
    Check-Match '.claude/skills/pelizzai-execute/templates/state.md' 'kickoff: <pending \| ratified' 'state.md has the kickoff marker (pending|ratified)'
    Check-Match '.claude/skills/pelizzai-execute/templates/state.md' 'isolation: <pending[\s\S]*execution-mode: <pending[\s\S]*commit-strategy: <pending' 'state.md: isolation/execution-mode/commit-strategy are born <pending>'
    # Pre-2026-07-11 restoration (2026-07-21): the cursor is a CURSOR again. The eight greenfield
    # steps stay mandatory, but their ratifications are a historical record in the PLAN HEADER —
    # never a state field stamped/read by a hook. Anti-regression on both ends (out of the state,
    # into the plan) so the removal is not undone by mistake on the next round.
    Check-NotMatch '.claude/skills/pelizzai-execute/templates/state.md' '^\s*-?\s*(discovery|spec-approval|domain-skills-decision|plan-approval):' 'state.md does NOT reintroduce greenfield approval fields (cursor, not stamp)'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'eight steps[\s\S]{0,260}PLAN HEADER' 'execution-plans reads the eight greenfield steps in the plan header'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'eight\s+steps[\s\S]{0,260}plan header' 'router: greenfield ratifies in the plan header, not in a state field'
    Check-Match '.claude/skills/pelizzai-plan/templates/plan.md' '\*\*Approvals\*\*[\s\S]{0,300}Discovery:[\s\S]{0,200}Spec:[\s\S]{0,200}Domain skills:[\s\S]{0,200}Plan:' 'plan carries the Approvals block (historical record of the four ratifications)'
    Check-Match '.claude/skills/pelizzai-plan/templates/plan.md' 'silence does not become a date' 'plan: approval marker is never filled by inference'

    # -- Ratified execution defaults section in profile.md (decision memory) --
    Check-Match '.claude/skills/pelizzai-onboard/templates/profile.md' '## Ratified execution defaults' 'profile.md has the Ratified execution defaults section'
    Check-Match '.claude/skills/pelizzai-onboard/templates/profile.md' 'isolation-default[\s\S]*execution-mode-default[\s\S]*commit-strategy-default' 'profile.md lists the execution defaults'
    Check-Match '.claude/skills/pelizzai-onboard/templates/profile.md' 'destination is not persistable' 'profile.md: destination is never persistable (push/PR per task)'

    # -- Symmetric anti-regression: read-only and the local near miss stay proportional --
    # (the Check-NotMatch at :134 "bounded plan does not force an interview" stays intact above.)
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'never creates/edits state' 'router: read-only creates no state/artifacts'
    Check-Match 'CLAUDE.md' 'read-only task creates no state and no artifacts' 'CLAUDE.md: read-only leaves no state/artifacts'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'When it informs and proceeds:[^\n]*only `read-only`' 'router only proceeds without ratification in read-only'
    Check-Match '.claude/skills/pelizzai-router/evals/adaptive-user-control.md' 'G-01.*greenfield with the stack specified' 'eval preserves the historical greenfield regression'
    Check-Match '.claude/skills/pelizzai-router/evals/adaptive-user-control.md' 'G-02.*another platform' 'eval covers greenfield on another stack'
    Check-Match '.claude/skills/pelizzai-router/evals/adaptive-user-control.md' 'F-01.*feature in an existing project' 'eval covers a feature in an existing project'
    Check-Match '.claude/skills/pelizzai-router/evals/adaptive-user-control.md' 'V-01.*skill upgrade and maintenance' 'eval covers skill upgrade and refresh'
    Check-Match '.claude/skills/pelizzai-router/evals/adaptive-user-control.md' 'B-01.*local near miss' 'eval protects the local tweak against inflation'
    Check-NotMatch '.claude/skills/pelizzai-discovery/SKILL.md' 'React, Express, SQLite' 'normative brainstorming does not overfit the historical prompt'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'greenfield product/project[\s\S]{0,120}always `exploratory`' 'router classifies greenfield as exploratory'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'Context7/official documentation is read-only technical reconnaissance' 'router uses Context7 early without mutating effect'
    # v3 slice 9: pelizzai-reasoning dissolved — the Context7 doctrine's homes are CLAUDE.md,
    # core, and the router, asserted above and below.
    Check-Match 'CLAUDE.md' 'Context7 is the harness''s preferred technical source' 'CLAUDE pins Context7 as the cross-cutting technical weapon'

    # =====================================================================
    # "Field feedback" package (D3–D7). See the master plan in the scratchpad.
    # D3: delivered→done lifecycle + confirm. D4: hygiene of the state
    # history (1 line/task, reports/ ephemeral, history/ versioned, nudge
    # ~150). D5: anti-stamp plan. D6: two-lens review with asymmetric
    # blindness + specialists by area. D7: thread of the proactive domain
    # skills gate at the three capture points.
    # =====================================================================

    # -- D3: the delivered → done lifecycle is observed, never declared --
    Check-Match '.claude/skills/pelizzai-execute/templates/state.md' 'delivered \| done \| abandoned \| blocked' 'state.md: phase enum includes delivered, done, and abandoned'
    Check-Match '.claude/skills/pelizzai-execute/templates/state.md' '^-?\s*confirm:\s*<none' 'state.md: confirm field to establish done against git'
    Check-Match '.claude/skills/pelizzai-execute/templates/state.md' 'Delivery lifecycle' 'state.md documents the delivered→done lifecycle'
    Check-Match '.claude/skills/pelizzai-execute/templates/state.md' 'does NOT declare .done' 'state.md: finish-task does not declare done (observed later)'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'Reconciliation of the previous delivery' 'execution-plans reconciles the previous delivery (delivered→done)'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'phase: delivered[\s\S]{0,6}delivery sealed' 'execution-plans defines phase delivered'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'phase: delivered[\s\S]{0,120}Reconciliation of the previous delivery' 'router (D3): delivered triggers reconciliation before treating it as an active task'
    # v3 slice 3: the delivered-seal contract moved verbatim to references/delivery-seal.md.
    Check-Match '.claude/skills/pelizzai-execute/references/delivery-seal.md' 'migration boundary' 'execute (D4): defines the verifiable boundary of the intact block'
    Check-Match '.claude/skills/pelizzai-execute/references/delivery-seal.md' 'uses the SAME lossless migration' 'execute: abandoned uses the same lossless migration to history/'
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' 'phase: delivered' 'finish-task closes the task in delivered'
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' 'seal task as delivered' 'finish-task: closure commit seals as delivered'
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' 'Declaring .phase: done. here' 'finish-task: anti-pattern of declaring done inside finish itself'
    Check-NotMatch '.claude/skills/pelizzai-finish/SKILL.md' 'Set .slug:[\s\S]{0,20}phase: done' 'finish-task no longer closes straight to done'
    Check-Match '.claude/skills/pelizzai-verify/SKILL.md' 'closes out in .phase: delivered' 'verification: finish closes out in delivered, not done'
    Check-Match '.claude/skills/pelizzai-resume/SKILL.md' 'Delivery in .delivered. on resumption' 'recovery observes delivered→done on resumption, without moving WIP'
    Check-Match '.claude/skills/pelizzai-continuity/SKILL.md' 'phase: delivered, include confirm' 'handoff propagates confirm so the next session can observe done'

    # -- D4: state history hygiene — 1 line/task, reports/ ephemeral, history/ versioned --
    Check-Match '.claude/skills/pelizzai-execute/templates/state.md' 'One line per task' 'state.md: progress is one line per task'
    Check-Match '.claude/skills/pelizzai-execute/templates/state.md' 'data/reports/' 'state.md: long reports go to data/reports/ (ephemeral)'
    Check-Match '.claude/skills/pelizzai-execute/templates/state.md' 'data/history/[\s\S]{0,40}VERSIONED' 'state.md: history/ is the durable versioned record'
    Check-Match '.claude/skills/pelizzai-execute/templates/state.md' '~60 lines' 'state.md: compaction nudge at ~60 lines (deflated template)'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'Progress hygiene' 'execution-plans has the Progress hygiene section'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'one line per task' 'execution-plans: one line per task in progress'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' '~60 lines' 'execution-plans: compaction nudge at ~60 lines'
    Check-Match '.claude/skills/pelizzai-execute/references/delivery-seal.md' 'data/history/[\s\S]{0,40}VERSIONED' 'execute: intact-block migration to versioned history/'
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' '~60 lines' 'finish-task: bulky state nudge (~60 lines)'
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' 'data/history/' 'finish-task cites the history/ migration in the done observation'
    Check-Match '.claude/skills/pelizzai-onboard/SKILL.md' '^data/reports/\s*$' 'audit: reports/ stays ignored (ephemeral)'
    Check-NotMatch '.claude/skills/pelizzai-onboard/SKILL.md' '^data/history/\s*$' 'audit: history/ is NOT ignored in the template (durable versioned record)'
    Check-Match '.claude/skills/pelizzai-onboard/SKILL.md' 'history/\s+versioned' 'audit: history/ marked versioned in the Canonical layout (durable, outside the ignore)'

    # =====================================================================
    # Pre-2026-07-11 restoration (2026-07-21) — F4: the state is a CURSOR again.
    # The regression this section locks out: the data template was drifting into
    # a process manual (85 lines, 39 of them instructions), setup started costing
    # a metadata-only commit, and the cursor only deflated at the NEXT
    # opening. What gets locked here: template size, prose in the skill
    # (not in the data), migration at the `delivered` seal, and zero setup commits.
    # =====================================================================

    # -- The template is data, not a manual: size ceiling and a pointer to the doctrine --
    $stateTemplateLines = (Text '.claude/skills/pelizzai-execute/templates/state.md') -split "`r?`n"
    Check ($stateTemplateLines.Count -le 60) 'state.md: template fits in 60 lines (deflated cursor)' "lines=$($stateTemplateLines.Count)"
    Check-Match '.claude/skills/pelizzai-execute/templates/state.md' 'Reference, don''t duplicate' 'state.md points to the doctrine instead of duplicating it'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' '\*\*Who writes the cursor' 'execution-plans hosts cursor authorship (prose moved out of the template)'
    Check-Match '.claude/skills/pelizzai-continuity/SKILL.md' 'artifact that has a path is referenced, never pasted' 'handoff: reference-instead-of-paste rule (basis of deduplication)'

    # -- Setup pays no metadata commit: the cursor rides in the first content commit --
    Check-Match '.claude/skills/pelizzai-isolate/SKILL.md' 'create a metadata-only commit' 'starting-branch: setup writes the state and moves on, no metadata commit'
    Check-NotMatch '.claude/skills/pelizzai-isolate/SKILL.md' 'make\s+a setup metadata commit' 'starting-branch does NOT reintroduce the setup commit'
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' 'there is no metadata-only commit to start the task' 'task-cycle: Task 1 carries the setup state in the content commit'

    # -- The cursor deflates at CLOSEOUT (the delivered seal), not at the next opening --
    Check-Match '.claude/skills/pelizzai-execute/references/delivery-seal.md' 'Migration at the .delivered' 'execute: the history/ migration happens at the delivered seal'
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' 'Migrate the intact block and deflate the cursor' 'finish-task runs the migration when sealing delivered'
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' 'git add -- pelizzai/data/state\.md pelizzai/data/history/' 'finish-task stages state + history in the same closure'
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' ":\(exclude\)pelizzai/data/history/" 'finish-task: product guard excludes history/ metadata'
    Check-Match '.claude/skills/pelizzai-verify/SKILL.md' 'only harness metadata' 'verification: closure contains state + history, not just state'
    Check-Match '.claude/skills/pelizzai-resume/SKILL.md' 'already migrated to .pelizzai/data/history/' 'recovery: on resumption only stamps the outcome (the block already migrated)'

    # -- A plan executable by someone with zero context (BASE requirement restored) --
    Check-Match '.claude/skills/pelizzai-plan/SKILL.md' 'zero context\*\*[\s\S]{0,80}a single question' 'writing-plans: goal is the plan a zero-context executor runs without asking'
    Check-Match '.claude/skills/pelizzai-plan/templates/plan.md' 'without asking a single question' 'plan: quality gate requires an executor with no questions'
    Check-NotMatch '.claude/skills/pelizzai-plan/templates/plan.md' '\*\*Ratified lane:\*\*' 'plan does not duplicate the lane (the cursor belongs to state)'
    Check-NotMatch '.claude/skills/pelizzai-plan/templates/plan.md' '\*\*Status:\*\*' 'plan keeps no loose Status outside the Approvals block'

    # -- D5: anti-stamp plan — Technical decisions, non-stamp ratification, Deviations + the deviation test --
    Check-Match '.claude/skills/pelizzai-plan/SKILL.md' '## Technical decisions in this plan' 'writing-plans requires the Technical decisions in this plan section'
    Check-Match '.claude/skills/pelizzai-plan/SKILL.md' 'no material technical decision' 'writing-plans: absence of decisions is an explicit declaration, not an empty section'
    Check-Match '.claude/skills/pelizzai-plan/SKILL.md' 'is not approved[\s\S]{0,40}present it before implementing' 'writing-plans fixes the operational deviation test'
    Check-Match '.claude/skills/pelizzai-plan/templates/plan.md' '## Technical decisions in this plan' 'plan template carries the Technical decisions section'
    Check-NotMatch '.claude/skills/pelizzai-plan/templates/plan.md' 'ratifying the plan (is|means) ratifying these decis' 'template does not reintroduce the block rubber-stamp (D5 anti-stamp)'
    Check-Match '.claude/skills/pelizzai-plan/templates/plan.md' 'no ratification origin[\s\S]{0,40}question' 'template carries the gate recap+question pair (D5)'
    Check-Match '.claude/skills/pelizzai-plan/templates/plan.md' 'is not approved[\s\S]{0,40}present it before implementing' 'plan template fixes the operational deviation test'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'Technical decisions of the plan' 'gate item 0 re-presents the technical decisions of the plan'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'without ratification does not pass the gate[\s\S]{0,90}never a list item to rubber-stamp' 'gate item 0: an unratified decision becomes a question, never a rubber stamp (anchor D5)'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'already ratified[\s\S]{0,60}one-line recap' 'gate item 0: an already ratified decision is a recap, not a re-ask (anti-fatigue)'
    Check-Match '.claude/skills/pelizzai-plan/SKILL.md' 'settled on its own does not enter the list as a fait accompli[\s\S]{0,20}becomes a question' 'writing-plans: an open decision becomes a question, not a fait accompli'
    Check-Match '.claude/skills/pelizzai-plan/SKILL.md' 'real options[\s\S]{0,40}recommended' 'writing-plans: open decision presented with real options and a recommendation'
    Check-Match '.claude/skills/pelizzai-plan/SKILL.md' 'plan only closes when[\s\S]{0,40}ratified' 'writing-plans: plan only closes with every material decision ratified'
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' 'Deviations from plan:' 'task-cycle requires the Deviations from plan field in the report'
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' 'checks that field before accepting' 'task-cycle: the coordinator checks Deviations from plan before accepting DONE'
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' 'is not approved[\s\S]{0,40}present it before implementing' 'task-cycle pins the operational deviation test in the briefing'

    # -- D6: two-lens review with asymmetric blindness + separate coordinator + specialists by area --
    # v3 slice 3: the truly blind spec lens moved to the FINAL range; per task the spec verdict
    # is formed before the report is read, in one dispatch.
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'truly blind spec lens runs on the FINAL range' 'review: the blind spec lens lives on the final range'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'spec verdict[\s\S]{0,80}reading code against[\s\S]{0,20}contract first' 'review: the spec verdict is formed before the report'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'never[\s\S]{0,4}the blind lens' 'review: the coordinator is never the blind lens'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'rubric that receives the implementer''s report' 'review: the evidence rubric receives and verifies the implementer report'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'ONE independent reviewer in ONE dispatch' 'review: the task review is one independent dispatch'
    Check-Match '.claude/skills/pelizzai-review/references/spec-reviewer.md' 'spec lens reviewer does NOT receive the implementer''s report' 'spec-reviewer is the blind lens (does not receive the report)'
    Check-NotMatch '.claude/skills/pelizzai-review/references/spec-reviewer.md' '\{IMPLEMENTER_REPORT\}' 'spec-reviewer (blind lens) no longer injects the report placeholder'
    Check-Match '.claude/skills/pelizzai-review/references/code-reviewer.md' '\{IMPLEMENTER_REPORT\}' 'code-reviewer (evidence lens) receives the report placeholder'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'SPECIALISTS by area' 'team: implementation roles are specialists by area'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' '\*\*COMPLETE\*\* package of domain skills' 'team: pastes the COMPLETE domain-skill package for the role area'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'never[\s\S]{0,4}implements a front' 'team: the coordinator orchestrates, never implements a front'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'blind spec lens' 'team: per-task review uses the blind spec lens'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'coordinator dispatching itself as the blind spec lens' 'team: anti-pattern — coordinator never dispatches itself as the blind lens'
    Check-Match '.claude/skills/pelizzai-subagents/SKILL.md' 'assemble a SPECIALIST' 'subagents: builds the subagent as an area specialist'
    Check-Match '.claude/skills/pelizzai-subagents/SKILL.md' '\*\*COMPLETE\*\* domain-skill package' 'subagents: COMPLETE domain-skill package for the area'
    Check-Match '.claude/skills/pelizzai-subagents/SKILL.md' 'blind spec lens' 'subagents: review uses the blind spec lens; the coordinator is never it'

    # =====================================================================
    # Pre-2026-07-11 restoration (2026-07-21) — F6: the reviewer is blind
    # by DEFAULT again. In BASE there was no profile: every task went through
    # spec → quality in separate stages, and the review was mandatory
    # after EVERY task. `combined` (post-BASE) stays, but demoted to an
    # exception the user ratifies at step 4 of the gate — because in a single
    # dispatch blindness collapses into mere reading order. The other half of the
    # fix: the blind lens now receives the domain skills, since
    # blindness is not seeing the author's NARRATIVE, not going without the
    # project CONTRACT.
    # =====================================================================

    # -- The review is mandatory after EVERY task again (BASE anchors) --
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'Review early and often' 'review: BASE core principle restored'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'description:[^\n]*after EVERY task' 'review: the description triggers after EVERY task (BASE trigger)'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'After EVERY task during plan execution[\s\S]{0,60}no exception for' 'review mandatory after every task, no exception for "it is simple"'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'depth is proportional to risk, the existence of the review is not' 'review: proportional is the depth, never the existence of the review'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'Skipping the review because .it''s simple' 'review: BASE anti-pattern (skipping because "it is simple") restored'

    # -- split is the default; combined is a ratified exception (not the other way around) --
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'There is no profile to pick' 'review: there is no profile to pick per task'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'Proportionality regulates depth, never existence' 'review: proportionality regulates depth, never existence'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'review degraded: single-context' 'review: inline degradation is DECLARED, never silent'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'coordinator never grades its own delivery' 'review: the coordinator never grades its own delivery'
    Check-NotMatch '.claude/skills/pelizzai-review/SKILL.md' 'trivial/bounded task proceeds with .combined.' 'review does not send bounded tasks back to combined by default'

    # -- The blind lens receives the domain skills (blindness ≠ lack of project context) --
    Check-Match '.claude/skills/pelizzai-review/references/spec-reviewer.md' '\{DOMAIN_SKILLS\}' 'spec-reviewer (blind lens) receives the domain skills slot'
    Check-Match '.claude/skills/pelizzai-review/references/spec-reviewer.md' 'Blindness is \*\*not\*\* lack of project context' 'spec-reviewer: blindness means not seeing the narrative, not losing the contract'
    Check-Match '.claude/skills/pelizzai-review/references/spec-reviewer.md' 'Domain skills: does the change respect the rules' 'spec-reviewer: domain skills enter the blind lens checklist'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' '.\{DOMAIN_SKILLS\}. slot \*\*of both\s+templates\*\*' 'review: the briefing pastes the domain skills into BOTH templates'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'pelizzai/domain-skills\.md' 'review names the domain skills catalog (not just "the catalog")'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' '.\{DOMAIN_SKILLS\}. slot\s+empty' 'review: anti-pattern of dispatching a briefing with an empty domain skills slot'

    # -- Reuse exception for the final review: narrowed, not removed --
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'Reuse exception \(narrow, and never the default path\)' 'review: the reuse exception is declared narrow'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' '.read-only. or .write-local. effect, low risk' 'review: the exception requires local effect and low risk'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'not to waive the final validation' 'review: the exception does not waive the final validation'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'Narrow exception:[\s\S]{0,200}read-only.*write-local' 'execution-plans mirrors the limits of the reuse exception'

    # -- The default propagated: gate, plan, task-cycle, team, and subagents teach the SAME thing --
    # v3 slice 3: gate step 4 is now the executor tier (ratified 26/08); review shape is fixed.
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' '4. Executor tier' 'gate step 4 ratifies the executor tier'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'never switches models on its own' 'gate step 4: the harness never switches models on its own'
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' 'ONE independent reviewer in ONE dispatch' 'task-cycle §3: one independent reviewer, one dispatch'
    Check-NotMatch '.claude/skills/pelizzai-execute/references/task-cycle.md' 'trivial/bounded tasks proceed with \*\*combined\*\* review' 'task-cycle does not send bounded tasks back to combined'
    Check-Match '.claude/skills/pelizzai-plan/SKILL.md' 'ONE independent dispatch with both verdicts' 'plan: the per-task review shape is one dispatch, both verdicts'
    Check-NotMatch '.claude/skills/pelizzai-plan/SKILL.md' 'universal split review' 'writing-plans no longer treats universal split as a red flag'
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'one dispatch, both verdicts' 'team: the per-task review is one dispatch, both verdicts'
    Check-Match '.claude/skills/pelizzai-subagents/SKILL.md' 'ONE independent reviewer, ONE dispatch, both verdicts' 'subagents: the task review is one dispatch, both verdicts'

    # -- D7: thread of the proactive domain skills gate — three capture points + audit names who invokes it --
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'stack domain skills \(proposed at the design edge\)' 'router (D7.1): kickoff lists the stack domain skills in Artifacts'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'proactive[\s\S]{0,4}domain skills gate' 'router points to the proactive gate at the design→plan edge'
    Check-Match '.claude/skills/pelizzai-discovery/SKILL.md' '^\s*1\.\s+Design approved' 'brainstorming (D7.2): the proactive gate is a numbered step of the design closeout'
    Check-Match '.claude/skills/pelizzai-discovery/SKILL.md' 'Closing the design edge on a new project without presenting the domain skills proposal' 'brainstorming: red flag for closing design without proposing domain skills'
    Check-Match '.claude/skills/pelizzai-plan/SKILL.md' 'Domain skill coverage check' 'writing-plans (D7.3): domain skill coverage safety net'
    Check-Match '.claude/skills/pelizzai-plan/SKILL.md' 'BEFORE Task 1' 'writing-plans: domain skill coverage is decided before Task 1'
    Check-Match '.claude/skills/pelizzai-onboard/SKILL.md' 'Who invokes this gate' 'audit names who invokes the Proactive gate (brainstorming + writing-plans)'

    # -- F3: model sovereignty — the model belongs to the user; the harness never downgrades anything --
    # User decision (2026-07-22): the harness respects the model chosen on the platform (simple
    # plans included) and elevates the reasoning of ANY model via pelizzai-reasoning. What stays
    # forbidden is downgrading on your own: no role runs below the session model, effort stays at
    # the highest the platform offers, and the process is never lowered to compensate for a
    # smaller model. A capability upgrade is a ratifiable recommendation, never an automatic swap.
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'session''s model[\s\S]{0,120}highest effort the platform allows' 'final review uses the session model with the highest platform effort'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'step 1 of[\s\S]{0,40}final delivery validation' 'final review is step 1 of the final delivery validation'
    Check-Match '.claude/skills/pelizzai-review/SKILL.md' 'Downgrading model or effort below the session''s' 'review: anti-pattern names downgrading below the session model'
    Check-NotMatch '.claude/skills/pelizzai-review/SKILL.md' 'most capable model|maximum effort' 'review no longer imposes most capable model/maximum effort'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'session''s model[\s\S]{0,80}highest effort the platform' 'final delivery validation runs on the session model'
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'downgrading model/effort below what the\s+user chose' 'execution-plans: the anti-pattern is downgrading below what the user chose'
    Check-NotMatch '.claude/skills/pelizzai-execute/SKILL.md' 'most capable model available and maximum effort' 'execution-plans does not mandate maximum capability'
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' 'Model selection per role' 'task-cycle §8 remains model selection per role'
    # v3 slice 3: tier-by-role ratified 26/08 supersedes "never downgrade" — the coordinator and
    # every review stay on the session tier; executors run the tier ratified at the gate.
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' 'tier by role, ratified at the setup gate, never switched silently' 'task-cycle §8: tier by role, ratified, never silent'
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' 'coordinator never runs below the session''s tier' 'task-cycle §8: the coordinator never runs below the session tier'
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' 'elevates the reasoning of \*\*any\*\* model' 'task-cycle §8: reasoning elevates any model'
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' 'never lowered to\s+compensate for a smaller model' 'task-cycle §8: process stays intact even with a smaller model'
    Check-Match '.claude/skills/pelizzai-execute/references/task-cycle.md' 'recommend and ratify' 'task-cycle §8: a capability upgrade is a ratifiable recommendation'
    Check-NotMatch '.claude/skills/pelizzai-execute/references/task-cycle.md' 'most capable model available|effort/reasoning at the maximum level' 'task-cycle §8 does not impose maximum capability'
    Check-Match 'CLAUDE.md' 'tiered by role and ratified, never switched silently' 'CLAUDE.md: capability is tiered by role and ratified'
    Check-Match 'CLAUDE.md' 'process is never downgraded to compensate for a smaller model' 'CLAUDE.md: process does not compensate for a smaller model'
    Check-Match 'README.md' 'the model you chose — never a smaller one' 'README: final review respects the chosen model'

    # -- F7: debugging regrafts the signals and tactics lost in the pivot (pre-2026-07-11 restoration) --
    # The proportional pivot STAYS whole (4-class triage, Step 0 containment, selector by
    # effect, no hypothesis quota). What comes back from BASE are the pieces it dropped without
    # replacing: trigger phrases in the description, loop minimization, the cause in the commit
    # message, the named escalation of the three fixes, and the human-partner signals table.
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'description:[^\n]*stop guessing' 'debugging: the description cites the user trigger phrases again'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'description:[^\n]*test breaks in the middle of another task' 'debugging: the description triggers on a test breaking mid-task'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'cut ONE element at a time' 'debugging restores minimization (one element at a time)'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'Minimize the loop[^\n]*uncertain deterministic[^\n]*flaky' 'debugging: minimization is conditioned to the two uncertain classes'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'every remaining element is load-bearing' 'debugging defines the minimization stop criterion'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'For a direct cause this is waste' 'debugging: minimizing a direct cause is waste (proportionality preserved)'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'Step 0 containment comes before any cut' 'debugging: containment still precedes minimization'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'recorded in the COMMIT MESSAGE of the fix' 'debugging: the confirmed cause goes back into the commit message'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'Three failed definitive fixes stop the track' 'debugging: three failed fixes stop the track'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'Three fixes that do not solve it \*\*are\*\* a material gap' 'debugging ties the circuit breaker to the material-gap contract'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'Trigger .pelizzai-interview.[\s\S]{0,240}pelizzai-discovery' 'debugging names the interview-me -> brainstorming escalation'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'Without that\s+discussion there is no fix #4' 'debugging: no fix #4 without the user discussion'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'Attempting fix #4 after three failures' 'debugging: red flag makes the circuit breaker observable'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' '## Signals from the human partner' 'debugging has the human-partner signals table'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' '"Stop guessing"[^\n]*falsifiable prediction' 'debugging decodes "stop guessing" (hypothesis without prediction)'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' '"Are we stuck\?"[^\n]*thrashing' 'debugging decodes "are we stuck?" (thrashing)'
    Check-Match '.claude/skills/pelizzai-diagnose/SKILL.md' 'Uses conditionally:[^\n]*pelizzai-interview' 'debugging: interview-me is in the Integration wiring'
    # The pieces came back translated, not pasted: HEAD vocabulary (Step/oracle) and none of the
    # BASE absolutes riding back in with them.
    Check-NotMatch '.claude/skills/pelizzai-diagnose/SKILL.md' '\bphases?\s+[1-4]\b' 'debugging does not re-paste the dead BASE phase vocabulary'
    Check-NotMatch '.claude/skills/pelizzai-diagnose/SKILL.md' 'Generate 3.5 hypotheses' 'debugging does not reintroduce the 3-5 hypothesis quota'
    Check-NotMatch '.claude/skills/pelizzai-diagnose/SKILL.md' 'NO FIX WITHOUT ROOT CAUSE INVESTIGATION' 'debugging keeps the proportional invariant (containment may precede the cause)'
    Check-NotMatch '.claude/skills/pelizzai-diagnose/SKILL.md' 'question hypothesis/architecture before trying another' 'debugging does not return to the anonymous circuit breaker (no named destination)'

    # -- F7: the technique quota history — pelizzai-reasoning was dissolved in v3 slice 9; the
    # quota regression it guarded against cannot return through a skill that no longer exists.

    # =====================================================================
    # F8 — Leftovers from the pre-2026-07-11 restoration.
    # The pieces the pivot dropped without replacing and the contradictions it
    # left behind: workspace detection, proactive cadence of the architectural
    # review, the doc's own commit, the prototype definition, handoff
    # re-anchoring, and an honest description of the writegate.
    # =====================================================================

    # -- F8: a multi-project workspace is DETECTED again and the affected set CONFIRMED --
    # BASE detected the workspace and never closed the set on its own; the pivot deleted the whole
    # section. It comes back reconciled with the HEAD invariant (one task = one Git repository):
    # a monorepo gets single isolation, a multi-repo workspace opens one per repository.
    # v3 slice 1b: the workspace-detection guarantee left the description (trigger format) and now
    # opens the body's Principles — the assertion follows the guarantee to where it lives.
    Check-Match '.claude/skills/pelizzai-isolate/SKILL.md' 'workspace is detected, never assumed[\s\S]*ALWAYS confirmed with the user' 'starting-branch: workspace detection stays a body guarantee'
    Check-Match '.claude/skills/pelizzai-isolate/SKILL.md' '^##\s+2\.\s+Detect a multi-project workspace' 'starting-branch has the workspace-detection section'
    Check-Match '.claude/skills/pelizzai-isolate/SKILL.md' 'pnpm-workspace\.yaml[\s\S]{0,120}go\.work' 'starting-branch checks the BASE workspace markers'
    Check-Match '.claude/skills/pelizzai-isolate/SKILL.md' 'one level up' 'starting-branch also looks for markers one level up from cwd'
    Check-Match '.claude/skills/pelizzai-isolate/SKILL.md' 'ALWAYS confirm the affected set with the user' 'starting-branch: the affected set is ALWAYS confirmed (BASE literal anchor)'
    Check-Match '.claude/skills/pelizzai-isolate/SKILL.md' 'A guessed set is a material\s+gap[\s\S]{0,80}pelizzai-interview' 'starting-branch sends the guessed set to interview-me, not to a default'
    Check-Match '.claude/skills/pelizzai-isolate/SKILL.md' '`pelizzai/` is \*\*root-level of the workspace\*\*' 'starting-branch: pelizzai/ is root-level of the workspace, not one per package'
    Check-Match '.claude/skills/pelizzai-isolate/SKILL.md' 'Workspace is detected, never assumed' 'starting-branch elevates workspace detection to an invariant'
    Check-Match '.claude/skills/pelizzai-isolate/SKILL.md' 'Skipping workspace detection' 'starting-branch: skipping workspace detection is a red flag'
    # Reconciliation: the HEAD rule stands and the BASE "one branch per project" does NOT come back.
    Check-Match '.claude/skills/pelizzai-isolate/SKILL.md' 'One task = one Git repository' 'starting-branch keeps the HEAD rule (one task = one repository)'
    Check-Match '.claude/skills/pelizzai-isolate/SKILL.md' 'Monorepo \(one Git repository, multiple packages\)[\s\S]{0,80}isolation is single' 'starting-branch: a monorepo gets single isolation, not one branch per package'
    Check-NotMatch '.claude/skills/pelizzai-isolate/SKILL.md' 'One branch per affected project' 'starting-branch does not re-add the BASE mistake (branch per package inside a monorepo)'
    Check-NotMatch '.claude/skills/pelizzai-isolate/SKILL.md' 'Priority: develop > dev' 'starting-branch does not re-add the historical base preference along with the workspace'

    # -- F8: the architecture review is PROACTIVE again (cadence trigger) --
    # The HEAD read-only contract stays intact (locked above); what comes back is the periodic trigger.
    Check-Match '.claude/skills/pelizzai-architecture/SKILL.md' 'description:[^\n]*PROACTIVE' 'improving-architecture: the description declares the PROACTIVE review'
    Check-Match '.claude/skills/pelizzai-architecture/SKILL.md' 'description:[^\n]*periodically \(every few days' 'improving-architecture: the periodic cadence is back in the trigger'
    Check-Match '.claude/skills/pelizzai-architecture/SKILL.md' 'Architecture degrades silently' 'improving-architecture explains why the trigger is not only a user request'
    Check-Match '.claude/skills/pelizzai-architecture/SKILL.md' 'Offering is proactive; running and implementing\s+remain the user''s choice' 'improving-architecture: proactivity is an offer, not execution without approval'
    Check-NotMatch '.claude/skills/pelizzai-architecture/SKILL.md' 'periodic sweep without a request' 'improving-architecture does not keep the exclusion that contradicted its own cadence'

    # -- F8: the doc requires its own commit again (history hygiene, not preference) --
    Check-Match '.claude/skills/pelizzai-docs/SKILL.md' 'goes in \*\*its own commit\*\*[\s\S]{0,40}docs\(<feature>\)' 'documenting-features requires a dedicated doc commit'
    Check-Match '.claude/skills/pelizzai-docs/SKILL.md' 'history hygiene, not preference' 'documenting-features: the dedicated doc commit is a rule, not taste'
    Check-Match '.claude/skills/pelizzai-docs/SKILL.md' 'granular. it is the definitive commit of the doc[\s\S]{0,120}squash-final' 'documenting-features reconciles the dedicated doc commit with both strategies'
    Check-Match '.claude/skills/pelizzai-docs/SKILL.md' 'Leaving the doc without its own commit' 'documenting-features: doc without its own commit is a red flag'
    Check-NotMatch '.claude/skills/pelizzai-docs/SKILL.md' 'own commit is\s+optional' 'documenting-features does not keep the dedicated doc commit as optional'

    # -- F8: prototype definition and the handoff re-anchoring anchor --
    Check-Match '.claude/skills/pelizzai-experiment/SKILL.md' 'throwaway code that answers a question' 'prototype keeps the BASE definition (the question decides the format)'
    Check-Match '.claude/skills/pelizzai-experiment/SKILL.md' 'Without a "yes", do not write the experiment' 'prototype preserves the explicit user approval (does not regress with the definition)'
    Check-Match '.claude/skills/pelizzai-continuity/SKILL.md' '\*\*anchor, not address\*\*' 'handoff: path/line is anchor, not address'
    Check-Match '.claude/skills/pelizzai-continuity/SKILL.md' 're-anchors before acting' 'handoff tells the next session to re-anchor before acting'

    # -- F8: the metadata-only closure is not a privilege of granular mode --
    Check-Match '.claude/skills/pelizzai-execute/SKILL.md' 'metadata-only closure of pelizzai-finish in the\s+consumer[\s\S]{0,60}both commit strategies' 'execution-plans: the closure applies under both commit strategies'
    Check-NotMatch '.claude/skills/pelizzai-execute/SKILL.md' 'cursor closure commit of pelizzai-finish' 'execution-plans does not describe the closure as granular-only'

    # -- F8: writegate described by what the hook DOES (Rule A + Rule B), without inventing a gate --
    # The hook never read `isolation: <pending>`; and, by owner decision, it does NOT enforce the
    # greenfield approval steps — they stay mandatory, but they live in the skills.
    Check-Match '.claude/skills/pelizzai-onboard/SKILL.md' 'Rule A[\s\S]{0,200}kickoff: ratified[\s\S]{0,80}Rule B' 'audit describes the writegate by the real Rules A and B'
    Check-Match '.claude/skills/pelizzai-onboard/SKILL.md' 'does NOT enforce the greenfield approval steps' 'audit: the writegate is not the greenfield turnstile'
    Check-NotMatch '.claude/skills/pelizzai-onboard/SKILL.md' 'while the isolation gate remains' 'audit does not describe an isolation gate the hook never checked'
    Check-Match 'README.md' 'Rule A[\s\S]{0,160}kickoff: ratified[\s\S]{0,60}Rule B' 'README describes the writegate by the real Rules A and B'
    Check-Match 'README.md' 'does not enforce the\s+greenfield approval steps' 'README: the writegate is not the greenfield turnstile'
    Check-NotMatch 'README.md' 'while isolation is' 'README does not describe a block on pending isolation'

    # -- Hook safety envelope: cadence/session-start fail open, they never block --
    $failOpenMjs = @('.claude/hooks/pelizzai-cadence.mjs', '.claude/hooks/pelizzai-session-start.mjs')
    $failOpenPs1 = @('.claude/hooks/pelizzai-cadence.ps1', '.claude/hooks/pelizzai-session-start.ps1')
    foreach ($h in $failOpenMjs) {
        Check-Match $h 'process\.exit\(0\)' "hook fail-open exit 0: $(Split-Path -Leaf $h)"
        Check-NotMatch $h 'process\.exit\(2\)|\bexit\(2\)' "advisory hook never blocks (no exit 2): $(Split-Path -Leaf $h)"
    }
    foreach ($h in $failOpenPs1) {
        Check-Match $h 'exit 0' "hook fail-open exit 0: $(Split-Path -Leaf $h)"
        Check-NotMatch $h 'exit 2' "advisory hook never blocks (no exit 2): $(Split-Path -Leaf $h)"
    }
    Check-Match '.claude/hooks/pelizzai-cadence.mjs' 'existsSync\(ledgerPath\)' 'cadence is a no-op without the ledger (mjs)'
    Check-Match '.claude/hooks/pelizzai-cadence.ps1' 'Test-Path -LiteralPath \$ledger' 'cadence is a no-op without the ledger (ps1)'

    # -- C4: the path that ARMS the cadence keeps seeding the ledger/Stack baseline --
    Check-Match '.claude/skills/pelizzai-onboard/SKILL.md' 'Stack baseline' 'bootstrap records the Stack baseline (drift anchor)'
    Check-Match '.claude/skills/pelizzai-onboard/SKILL.md' 'seeds? the ledger|ledger seeded' 'bootstrap seeds the ledger (arms the C4 cadence)'
    Check-Match '.claude/skills/pelizzai-skill-lab/SKILL.md' '[Ss]eed the ledger' 'writing-skills seeds the ledger'

    # -- D1: Accelerated cadence — new thresholds locked on BOTH legs (strict parity) --
    # Field feedback swaps 20/30/14/21 for 10/10/15/10 (sampling / commits / review-days /
    # full-scan-days). The cadence changes BY DESIGN: the old "byte-identical to the baseline"
    # contract was retired. The cadence SAFETY envelope (fail-open exit 0, no exit 2, no-op without
    # a ledger) stays locked above — this block pins the NUMBERS and the parity, not immutability.
    foreach ($cad in @('.claude/hooks/pelizzai-cadence.mjs', '.claude/hooks/pelizzai-cadence.ps1')) {
        $leaf = Split-Path -Leaf $cad
        Check-Match $cad 'EVERY\s*=\s*10\b' "cadence D1: sampling every 10 interactions ($leaf)"
        Check-Match $cad 'COMMIT_THRESHOLD\s*=\s*10\b' "cadence D1: 10-commit threshold ($leaf)"
        Check-Match $cad 'DAY_THRESHOLD_REVIEW\s*=\s*10\b' "cadence D1: review due at 10 days ($leaf)"
        Check-Match $cad 'DAY_THRESHOLD_SCAN\s*=\s*15\b' "cadence D1: full-scan at 15 days ($leaf)"
        Check-NotMatch $cad 'EVERY\s*=\s*20\b' "cadence D1: old sampling (20) removed ($leaf)"
        Check-NotMatch $cad 'COMMIT_THRESHOLD\s*=\s*30\b' "cadence D1: old commit threshold (30) removed ($leaf)"
        Check-NotMatch $cad 'DAY_THRESHOLD_REVIEW\s*=\s*14\b' "cadence D1: old review threshold (14 days) removed ($leaf)"
        Check-NotMatch $cad 'DAY_THRESHOLD_SCAN\s*=\s*21\b' "cadence D1: old full-scan threshold (21 days) removed ($leaf)"
    }
    # D1 in the TEXTS that cite the cadence (the doctrine follows the hooks).
    Check-Match '.claude/skills/pelizzai-skill-lab/SKILL.md' '10 commits / 10 review days / 15 full-scan days' 'writing-skills cites the new thresholds (10/10/15)'
    Check-NotMatch '.claude/skills/pelizzai-skill-lab/SKILL.md' '30 commits / 14 days' 'writing-skills does not cite the old thresholds (30/14)'
    Check-Match '.claude/skills/pelizzai-skill-lab/references/domain-skill-maintenance.md' 'every 10 interactions' 'domain-skill-maintenance cites the new sampling (10 interactions)'
    Check-Match '.claude/skills/pelizzai-skill-lab/references/domain-skill-maintenance.md' 'count >= 10 commits OR > 10 days have passed' 'domain-skill-maintenance cites the new review threshold (10/10)'
    Check-NotMatch '.claude/skills/pelizzai-skill-lab/references/domain-skill-maintenance.md' 'every 20 interactions' 'domain-skill-maintenance does not cite the old sampling (20)'

    # -- Writegate: opt-in runtime enforcement (co-lands with the B1 hook package) --
    # EXISTENCE is already locked by the dangling-refs check below (pelizzai-onboard cites
    # pelizzai-writegate): the suite only goes green when both hook files exist.
    # Once present, we validate syntax and rule parity between the two .mjs/.ps1 legs.
    $wgMjs = Join-Path $root '.claude/hooks/pelizzai-writegate.mjs'
    $wgPs1 = Join-Path $root '.claude/hooks/pelizzai-writegate.ps1'
    if ((Test-Path -LiteralPath $wgMjs) -and (Test-Path -LiteralPath $wgPs1)) {
        Run-Native { node --check .claude/hooks/pelizzai-writegate.mjs } 'node parse writegate'
        foreach ($wgRel in @('.claude/hooks/pelizzai-writegate.mjs', '.claude/hooks/pelizzai-writegate.ps1')) {
            $leaf = Split-Path -Leaf $wgRel
            Check-Match $wgRel 'main[\s\S]{0,40}master[\s\S]{0,40}develop[\s\S]{0,40}dev' "writegate knows the protected branches ($leaf)"
            Check-Match $wgRel 'kickoff[\s\S]{0,20}rati(?:fied|ficado)' "writegate keys on the kickoff: ratified marker ($leaf)"
            # 2026-07-21 restoration: enforcement of the greenfield approvals LEFT the hook. The eight
            # steps stay mandatory through skill text; the hook locks a single marker (the kickoff),
            # because a file turnstile blocked legitimate work whenever the state fell one step
            # behind the conversation. Anti-regression: neither the constant, nor the documented scope.
            Check-NotMatch $wgRel 'spec-approval|domain-skills-decision|plan-approval' "writegate does NOT reintroduce greenfield approval enforcement ($leaf)"
            Check-Match $wgRel 'DELIBERATE SCOPE' "writegate documents why it locks only the kickoff ($leaf)"
            # D2: documented metadata carve-out + security note (parity across both legs).
            Check-Match $wgRel 'METADATA CARVE-OUT' "writegate documents the harness metadata carve-out ($leaf)"
            # 2026-08-26 hardening: a missing state.md in a repo that carries the harness BLOCKS
            # (the gate never ran); the fail-open + warn survives only with no harness footprint.
            # The trigger tests caught an agent editing product right through the old fail-open.
            Check-Match $wgRel 'HARNESS EVIDENCE' "writegate documents the missing-state.md hardening ($leaf)"
            Check-Match $wgRel 'FILE writes ONLY' "writegate: security note — the carve-out is file writes only, not commits ($leaf)"
            Check-Match $wgRel 'LIMIT \(symlink\)' "writegate: security note documents the carve-out's symlink limitation ($leaf)"
        }
        # D2: Rule A only blocks when there is PRODUCT — the carve-out is behavior, not just a comment.
        Check-Match '.claude/hooks/pelizzai-writegate.mjs' 'isProtected && products\.length > 0' 'writegate.mjs: Rule A conditions the block on product (metadata carve-out)'
        Check-Match '.claude/hooks/pelizzai-writegate.ps1' 'isProtected -and \$products\.Count -gt 0' 'writegate.ps1: Rule A conditions the block on product (metadata carve-out)'

        # Behavioral fixture: temporary git repo, scenario matrix across BOTH legs
        # (Rule A: isolation; Rule B: ratified kickoff; source mode: Rule B skipped).
        $wgTemp = Join-Path ([IO.Path]::GetTempPath()) ("pelizzai-writegate-{0}-{1}" -f $PID, [guid]::NewGuid().ToString('N'))
        $wgOutside = Join-Path ([IO.Path]::GetTempPath()) ("pelizzai-wg-out-{0}.txt" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $wgTemp | Out-Null
        try {
            git -C $wgTemp init -q
            git -C $wgTemp symbolic-ref HEAD refs/heads/main  # deterministic protected branch
            git -C $wgTemp config user.email 'contract@pelizzai.local'
            git -C $wgTemp config user.name 'PelizzAI Contract'
            Set-Content -LiteralPath (Join-Path $wgTemp 'seed.txt') -Value 'base' -Encoding utf8
            git -C $wgTemp add seed.txt
            git -C $wgTemp commit -q -m 'base'

            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                # Rule A: protected branch (main) + an in-root PRODUCT write blocks (exit 2).
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 2) "writegate blocks product on a protected branch ($leaf)"
                # D2 CARVE-OUT: harness metadata under pelizzai/** is ALLOWED even on a protected
                # branch (exit 0) — the system updating itself; the commit still requires a task branch.
                Check ((Invoke-Writegate $wg @{ file_path = 'pelizzai/data/state.md' } $wgTemp) -eq 0) "writegate: D2 carve-out allows pelizzai/ metadata on a protected branch ($leaf)"
                # Outside the repo root it allows (exit 0), even on a protected branch.
                Check ((Invoke-Writegate $wg @{ file_path = $wgOutside } $wgTemp) -eq 0) "writegate allows a write outside the root ($leaf)"

                # -- Bash matcher: false positives fixed (2026-07-21 restoration) --
                # Positive control first: a REAL redirect into the root still blocks. Without it,
                # the checks below would pass with a matcher that had turned into a no-op.
                Check ((Invoke-Writegate $wg @{ command = 'npm test > build.log' } $wgTemp) -eq 2) "writegate blocks a real redirect into the root ($leaf)"
                # Null sinks DISCARD output — they are not product writes. `> NUL` used to resolve as
                # a relative path inside the root and blocked a legitimate command.
                Check ((Invoke-Writegate $wg @{ command = 'node x.js > NUL' } $wgTemp) -eq 0) "writegate: the NUL null sink is not a product write ($leaf)"
                Check ((Invoke-Writegate $wg @{ command = 'node x.js 2> $null' } $wgTemp) -eq 0) "writegate: the `$null null sink is not a product write ($leaf)"
                Check ((Invoke-Writegate $wg @{ command = 'node x.js > /dev/null' } $wgTemp) -eq 0) "writegate: the /dev/null null sink is not a product write ($leaf)"
                # A target carrying an environment variable is EXPANDED before comparing against the
                # root: the file is born outside the repository, so it is not product.
                Check ((Invoke-Writegate $wg @{ command = 'npm test > $env:TEMP/build.log' } $wgTemp) -eq 0) "writegate expands `$env:VAR before deciding ($leaf)"
                Check ((Invoke-Writegate $wg @{ command = 'npm test > %TEMP%\build.log' } $wgTemp) -eq 0) "writegate expands %VAR% before deciding ($leaf)"
                # Unresolvable variable → undecidable target → fail open (the same honesty as the matcher).
                Check ((Invoke-Writegate $wg @{ command = 'npm test > $env:PELIZZAI_NAO_EXISTE_XYZ/f.log' } $wgTemp) -eq 0) "writegate does not block a target with an unresolvable variable ($leaf)"
                # Non-regression: `>` inside quotes is text, not a redirect.
                Check ((Invoke-Writegate $wg @{ command = 'git commit -m "a > b"' } $wgTemp) -eq 0) "writegate does not mistake quoted text for a redirect ($leaf)"
            }

            # -- Carve-out bypass regression (2026-08-26): `..` AFTER a directory link. --
            # `pelizzai/link/../srcreal/app.ts` collapses LEXICALLY to pelizzai/srcreal/app.ts
            # (metadata, allowed) while the OS resolves `link` first and lands the write on real
            # product at the repo root. The physical walk must classify it as product and block.
            New-Item -ItemType Directory -Path (Join-Path $wgTemp 'srcreal') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $wgTemp 'pelizzai') -Force | Out-Null
            $wgLink = Join-Path $wgTemp 'pelizzai/link'
            if ($env:OS -eq 'Windows_NT' -or $IsWindows) {
                try { $null = New-Item -ItemType Junction -Path $wgLink -Target (Join-Path $wgTemp 'srcreal') -ErrorAction Stop } catch {
                    try { $null = New-Item -ItemType SymbolicLink -Path $wgLink -Target (Join-Path $wgTemp 'srcreal') -ErrorAction Stop } catch {}
                }
            } else {
                # ln -s directly: on one CI platform New-Item reported success without a link on
                # disk, which turned this regression into a false FAIL and aborted the suite.
                & sh -c 'ln -s "$0" "$1"' (Join-Path $wgTemp 'srcreal') $wgLink 2>$null
            }
            # File-symlink twin of the same bypass: pelizzai/alias -> srcreal/app2.ts spells as
            # metadata while the OS writes product. Both legs must resolve it and block.
            Set-Content -LiteralPath (Join-Path $wgTemp 'srcreal/app2.ts') -Value 'x' -Encoding utf8
            $wgAlias = Join-Path $wgTemp 'pelizzai/alias'
            if ($env:OS -eq 'Windows_NT' -or $IsWindows) {
                try { $null = New-Item -ItemType SymbolicLink -Path $wgAlias -Target (Join-Path $wgTemp 'srcreal/app2.ts') -ErrorAction Stop } catch {}
            } else {
                & sh -c 'ln -s "$0" "$1"' (Join-Path $wgTemp 'srcreal/app2.ts') $wgAlias 2>$null
            }

            # VERIFIED existence, never inferred from an exception path. A silent SKIP on CI would
            # let the suite go green without ever proving the bypass is closed - on CI a missing
            # link capability is a FAILURE; the SKIP is for local machines without the privilege.
            $onCI = [bool]$env:CI
            if (Test-Path -LiteralPath $wgLink) {
                foreach ($wg in @($wgMjs, $wgPs1)) {
                    $leaf = Split-Path -Leaf $wg
                    Check -Condition ((Invoke-Writegate $wg @{ file_path = 'pelizzai/link/../srcreal/app.ts' } $wgTemp) -eq 2) -Name "writegate: '..' after a directory link cannot smuggle product into the metadata carve-out ($leaf)"
                }
            } elseif ($onCI) {
                Check -Condition $false -Name 'writegate: CI must be able to create the directory link for the ..-after-link regression'
            } else {
                Write-Host 'SKIP: this environment cannot create links; the ..-after-link regression runs where it can.'
            }
            if (Test-Path -LiteralPath $wgAlias) {
                foreach ($wg in @($wgMjs, $wgPs1)) {
                    $leaf = Split-Path -Leaf $wg
                    Check -Condition ((Invoke-Writegate $wg @{ file_path = 'pelizzai/alias' } $wgTemp) -eq 2) -Name "writegate: a file symlink under pelizzai/ pointing at product is classified as product ($leaf)"
                }
            } elseif ($onCI -and -not ($env:OS -eq 'Windows_NT' -or $IsWindows)) {
                # Windows CI may legitimately lack the file-symlink privilege; POSIX never does.
                Check -Condition $false -Name 'writegate: POSIX CI must be able to create the file symlink for the alias regression'
            } else {
                Write-Host 'SKIP: this environment cannot create file symlinks; the alias regression runs where it can.'
            }
            # Remove the reparse points/links ONLY - a recursive delete through a link follows it.
            foreach ($lnk in @($wgLink, $wgAlias)) {
                if (Test-Path -LiteralPath $lnk) {
                    if ($env:OS -eq 'Windows_NT' -or $IsWindows) { Remove-Item -LiteralPath $lnk -Force -ErrorAction SilentlyContinue }
                    else { & sh -c 'rm -- "$0"' $lnk 2>$null }
                }
            }
            Remove-Item -LiteralPath (Join-Path $wgTemp 'pelizzai') -Recurse -Force -ErrorAction SilentlyContinue

            git -C $wgTemp checkout -q -b feat/x  # task branch (not protected)

            # -- Rule B, missing-state.md matrix (2026-08-26 hardening) --
            # No harness footprint at all: still fail-open (an off-label install — e.g. the hook
            # registered in global settings — must never lock an unrelated repo out).
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 0) "writegate: no state.md and no harness footprint fails open ($leaf)"
            }
            # A regular FILE named `pelizzai` is NOT a footprint — an unrelated repo carrying one
            # must keep the fail-open, or Rule B would hard-block a project that never opted in.
            Set-Content -LiteralPath (Join-Path $wgTemp 'pelizzai') -Value 'not a harness' -Encoding utf8
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                Check -Condition ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 0) -Name "writegate: a regular file named pelizzai is not a harness footprint ($leaf)"
            }
            Remove-Item -LiteralPath (Join-Path $wgTemp 'pelizzai') -Force

            # A harness footprint (here: the pelizzai/ dir) with NO state.md means the kickoff gate
            # never ran — the product write BLOCKS instead of warning. This is the gap the trigger
            # tests exposed: an agent skipped the compact confirm and edited product right through
            # the old fail-open, because the fixture consumer had the harness but no state.md yet.
            New-Item -ItemType Directory -Path (Join-Path $wgTemp 'pelizzai') -Force | Out-Null
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 2) "writegate blocks product when the harness is present and state.md is missing ($leaf)"
                # Ratifying the gate is the way out: writing state.md itself stays allowed.
                Check ((Invoke-Writegate $wg @{ file_path = 'pelizzai/data/state.md' } $wgTemp) -eq 0) "writegate: recording the kickoff stays allowed with state.md missing ($leaf)"
            }

            New-Item -ItemType Directory -Path (Join-Path $wgTemp 'pelizzai/data') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $wgTemp 'pelizzai/data/state.md') -Value "- kickoff: <pending>`n" -Encoding utf8
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                # Rule B (consumer): product without a ratified kickoff blocks (exit 2).
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 2) "writegate blocks product without a ratified kickoff ($leaf)"
                # A setup artifact under pelizzai/ is always allowed (exit 0).
                Check ((Invoke-Writegate $wg @{ file_path = 'pelizzai/data/state.md' } $wgTemp) -eq 0) "writegate allows a setup artifact under pelizzai/ ($leaf)"
            }

            Set-Content -LiteralPath (Join-Path $wgTemp 'pelizzai/data/state.md') -Value "- kickoff: ratified 2026-07-12`n" -Encoding utf8
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                # With a ratified kickoff, product is allowed (exit 0).
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 0) "writegate allows product after a ratified kickoff ($leaf)"
            }

            # Legacy pt-BR marker: consumer states written before the English translation still say
            # `kickoff: ratificado`. The hook keys on `rati(?:fied|ficado)` so an installed consumer
            # is not blocked by a state it wrote under the old canon. This fails the day the
            # compatibility alternation is dropped from either leg of the hook.
            Set-Content -LiteralPath (Join-Path $wgTemp 'pelizzai/data/state.md') -Value "- kickoff: ratificado 2026-07-12`n" -Encoding utf8
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 0) "writegate accepts the legacy pt-BR marker kickoff: ratificado ($leaf)"
            }

            # INVERTED fixture (2026-07-21 restoration): a legacy state that still carries the four
            # approval fields at `pending` no longer blocks — the kickoff alone is what allows it.
            # It fails if per-field enforcement returns to the hook.
            Set-Content -LiteralPath (Join-Path $wgTemp 'pelizzai/data/state.md') -Value @"
- kickoff: ratified 2026-07-12
- discovery: pending
- spec-approval: pending
- domain-skills-decision: pending
- plan-approval: pending
"@ -Encoding utf8
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 0) "writegate ignores greenfield approval fields in the state ($leaf)"
            }

            # A consumer installed via -ExportConsumer has manifest+sync+core skills: that is NOT
            # source mode (regression of manual-copy distribution) — Rule B still holds.
            New-Item -ItemType Directory -Path (Join-Path $wgTemp '.claude/skills/pelizzai-core') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $wgTemp 'scripts') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $wgTemp '.claude/skills/pelizzai-core/SKILL.md') -Value 'x' -Encoding utf8
            Set-Content -LiteralPath (Join-Path $wgTemp 'scripts/pelizzai-core-skills.txt') -Value 'x' -Encoding utf8
            Set-Content -LiteralPath (Join-Path $wgTemp 'scripts/sync-harness.ps1') -Value 'x' -Encoding utf8
            Set-Content -LiteralPath (Join-Path $wgTemp 'pelizzai/data/state.md') -Value "- kickoff: <pending>`n" -Encoding utf8
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 2) "writegate: manifest+sync in a consumer do NOT make it source mode ($leaf)"
            }

            # Source mode (dedicated sentinel scripts/pelizzai-source-repo.txt): Rule B is skipped.
            Set-Content -LiteralPath (Join-Path $wgTemp 'scripts/pelizzai-source-repo.txt') -Value 'x' -Encoding utf8
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 0) "writegate in source mode (sentinel) skips Rule B ($leaf)"
            }
        } finally {
            if (Test-Path -LiteralPath $wgTemp) { Remove-Item -LiteralPath $wgTemp -Recurse -Force }
            if (Test-Path -LiteralPath $wgOutside) { Remove-Item -LiteralPath $wgOutside -Force }
        }
    } else {
        Write-Host "SKIP: pelizzai-writegate missing (co-lands with the B1 hook package; existence locked by the dangling-refs check). Behavioral fixtures: pending co-authorship with the hook."
    }

    # -- Dedicated source-mode sentinel + safe consumer distribution --
    Check (Test-Path (Join-Path $root 'scripts/pelizzai-source-repo.txt')) 'source repo sentinel exists in the source'
    Check-Match 'scripts/pelizzai-source-repo.txt' 'NEVER copy' 'sentinel documents the copy prohibition'
    foreach ($sf in @('.claude/hooks/pelizzai-writegate.mjs', '.claude/hooks/pelizzai-writegate.ps1', '.claude/hooks/pelizzai-session-start.mjs', '.claude/hooks/pelizzai-session-start.ps1', '.claude/skills/pelizzai-onboard/SKILL.md', '.claude/skills/pelizzai-router/SKILL.md', 'CLAUDE.md')) {
        Check-Match $sf 'pelizzai-source-repo\.txt' "source mode detected by the dedicated sentinel ($sf)"
    }
    foreach ($sf in @('.claude/hooks/pelizzai-writegate.mjs', '.claude/hooks/pelizzai-writegate.ps1', '.claude/hooks/pelizzai-session-start.mjs', '.claude/hooks/pelizzai-session-start.ps1')) {
        Check-NotMatch $sf 'pelizzai-core-skills' "hook does not use the manifest as the source-mode sentinel ($sf)"
    }
    Check (Test-Path (Join-Path $root 'scripts/sync-harness.mjs')) 'portable Node sync exists'
    Check (Test-Path (Join-Path $root 'scripts/sync-harness.ps1')) 'PowerShell wrapper exists'
    Check (Test-Path (Join-Path $root 'scripts/sync-harness.sh')) 'macOS/Linux wrapper exists'
    Check-Match 'scripts/sync-harness.mjs' 'exportConsumer' 'portable sync has consumer distribution'
    Check-Match 'scripts/sync-harness.mjs' "rmSync\(join\(targetScripts, 'pelizzai-source-repo\.txt'\)" 'portable export removes the sentinel from the consumer'
    Check-Match 'scripts/sync-harness.ps1' 'sync-harness\.mjs' 'PowerShell wrapper delegates to the portable core'
    Check-Match 'scripts/sync-harness.sh' 'sync-harness\.mjs' 'Unix wrapper delegates to the portable core'
    Run-Native { node --check scripts/sync-harness.mjs } 'node parse portable sync'
    Run-Native { node --check scripts/install-hooks.mjs } 'node parse hook installer'

    # Real consumer export: Cursor adapter included; sentinel and contract suite excluded.
    Check-Match 'scripts/sync-harness.mjs' "join\(root, '\.cursor', 'rules', 'pelizzai\.mdc'\)" 'portable export copies the Cursor adapter'
    Check-Match 'README.md' 'the `--export-consumer`\s+copies it' 'README: Cursor adapter is distributed by the export'
    $exportTemp = Join-Path ([IO.Path]::GetTempPath()) ("pelizzai-export-test-" + [guid]::NewGuid().ToString('N'))
    try {
        # Pre-populated target: a sentinel and a suite left behind by an old manual copy
        # must be REMOVED by the export, not merely left uncopied.
        New-Item -ItemType Directory -Path (Join-Path $exportTemp 'scripts') -Force | Out-Null
        'stale' | Set-Content -LiteralPath (Join-Path $exportTemp 'scripts/pelizzai-source-repo.txt') -Encoding utf8
        'stale' | Set-Content -LiteralPath (Join-Path $exportTemp 'scripts/test-harness-contracts.ps1') -Encoding utf8
        Run-Native { node scripts/sync-harness.mjs --export-consumer $exportTemp } 'real consumer export completes without error'
        Check (Test-Path (Join-Path $exportTemp '.cursor/rules/pelizzai.mdc')) 'export carries the Cursor adapter to the consumer'
        Check (-not (Test-Path (Join-Path $exportTemp 'scripts/pelizzai-source-repo.txt'))) 'export removes a pre-existing source-mode sentinel from the target'
        Check (-not (Test-Path (Join-Path $exportTemp 'scripts/test-harness-contracts.ps1'))) 'export removes a pre-existing contract suite from the target'
        Check (Test-Path (Join-Path $exportTemp '.claude/skills/pelizzai-core/SKILL.md')) 'export carries the core skills'
        Check (Test-Path (Join-Path $exportTemp '.claude/hooks/pelizzai-writegate.mjs')) 'export carries the hooks (without registering them)'
        Check (Test-Path (Join-Path $exportTemp 'AGENTS.md')) 'export generates AGENTS.md in the consumer'
        Check (Test-Path (Join-Path $exportTemp 'GEMINI.md')) 'export generates GEMINI.md in the consumer'
        $exportClaude = Get-Content -LiteralPath (Join-Path $exportTemp 'CLAUDE.md') -Raw -Encoding utf8
        Check ($exportClaude -match 'This repository consumes PelizzAI') 'consumer CLAUDE.md is the bridge, not the source repo version'
    } finally {
        if (Test-Path -LiteralPath $exportTemp) { Remove-Item -LiteralPath $exportTemp -Recurse -Force }
    }

    # A target nested in the source repo is rejected before any write (only dist/ is a legitimate internal one).
    $nestedTarget = Join-Path $root '.tmp-export-nested'
    try {
        New-Item -ItemType Directory -Path $nestedTarget -Force | Out-Null
        node scripts/sync-harness.mjs --export-consumer $nestedTarget 2>$null | Out-Null
        Check ($LASTEXITCODE -ne 0) 'export rejects a target nested in the source repo'
        Check (-not (Test-Path (Join-Path $nestedTarget 'CLAUDE.md'))) 'the nested target received no payload'
    } finally {
        if (Test-Path -LiteralPath $nestedTarget) { Remove-Item -LiteralPath $nestedTarget -Recurse -Force }
    }

    # dist/: install by copy — committed in the source repo, no sentinel, skills in sync.
    # The real build runs first: the checks below validate the FRESH result of the regeneration
    # (idempotent over the committed dist), not just the content that was already in the repo.
    Run-Native { node scripts/sync-harness.mjs --build-dist } 'real build-dist completes without error'
    Check-Match 'scripts/sync-harness.mjs' 'buildDist' 'portable sync builds the dist'
    Check-Match 'scripts/sync-harness.ps1' 'BuildDist' 'PowerShell wrapper exposes -BuildDist'
    Check-Match 'README.md' 'No command line: copy `dist/`' 'README instructs install by copying dist'
    Check-Match '.github/workflows/check-harness.yml' 'build-dist' 'CI validates the committed dist stays in sync'
    Check (Test-Path (Join-Path $root 'dist/.cursor/rules/pelizzai.mdc')) 'dist contains the Cursor adapter'
    Check (Test-Path (Join-Path $root 'dist/.claude/skills/pelizzai-core/SKILL.md')) 'dist contains the core skills'
    Check (Test-Path (Join-Path $root 'dist/AGENTS.md')) 'dist contains the generated AGENTS.md'
    Check (-not (Test-Path (Join-Path $root 'dist/scripts/pelizzai-source-repo.txt'))) 'dist does not contain the source-mode sentinel'
    Check (-not (Test-Path (Join-Path $root 'dist/scripts/test-harness-contracts.ps1'))) 'dist does not contain the contract suite'
    $distClaudePath = Join-Path $root 'dist/CLAUDE.md'
    Check (Test-Path $distClaudePath) 'dist contains CLAUDE.md'
    if (Test-Path $distClaudePath) {
        $distClaude = Get-Content -LiteralPath $distClaudePath -Raw -Encoding utf8
        Check ($distClaude -match 'This repository consumes PelizzAI') 'dist CLAUDE.md is the consumer bridge'
    }
    if (Test-Path (Join-Path $root 'dist/.claude/skills')) {
        $srcSkillFiles = Get-RelativeFiles (Join-Path $root '.claude/skills')
        $distSkillFiles = Get-RelativeFiles (Join-Path $root 'dist/.claude/skills')
        Check ((Compare-Object $srcSkillFiles $distSkillFiles | Measure-Object).Count -eq 0) 'dist/.claude/skills mirrors the source (same file list)'
    } else {
        Check $false 'dist/.claude/skills mirrors the source (same file list)' 'dist/.claude/skills missing'
    }

    # Hook installer: idempotent merge and surgical removal.
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
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp } 'installer registers hooks while preserving settings'
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp } 'hook installer is idempotent'
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp --check } 'check confirms the hooks are registered'
        $installedSettings = Get-Content -LiteralPath $settingsPath -Raw -Encoding utf8
        Check ([regex]::Matches($installedSettings, 'pelizzai-(?:guardrails|writegate|cadence|session-start)\.mjs').Count -eq 5) 'installer does not duplicate PelizzAI handlers'
        Check ($installedSettings -match 'echo custom') 'installer preserves an existing hook'
        Check ($installedSettings -match 'Bash\(rm -rf:\*\)') 'installer preserves existing permissions'
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp --remove } 'installer removes only PelizzAI hooks'
        $removedSettings = Get-Content -LiteralPath $settingsPath -Raw -Encoding utf8
        Check ($removedSettings -notmatch 'pelizzai-(?:guardrails|writegate|cadence|session-start)\.mjs') 'removal eliminates the PelizzAI handlers'
        Check ($removedSettings -match 'echo custom' -and $removedSettings -match 'Bash\(rm -rf:\*\)') 'removal preserves settings owned by others'

        # 2026-07-21 restoration: a hook is OPT-IN, one at a time and with confirmation — never
        # imposed as a block. `--only` makes the doctrine operable and `--check` becomes an
        # INVENTORY: a partial install is a legitimate user choice, not a defect. Without this net,
        # the installer goes back to treating "a hook is missing" as a failure and bootstrap goes
        # back to pushing all four at once.
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp --only cadence } 'installer --only registers just the requested hook'
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp --check } 'check tolerates a deliberate partial install (opt-in is not a failure)'
        $null = & node scripts/install-hooks.mjs --project $hooksTemp --check --only writegate 2>&1
        Check ($LASTEXITCODE -eq 1) 'check --only fails a hook explicitly requested and missing'
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp --only guardrails,writegate } 'installer --only is additive (it does not drop an already accepted hook)'
        $partialSettings = Get-Content -LiteralPath $settingsPath -Raw -Encoding utf8
        Check ($partialSettings -match 'pelizzai-cadence\.mjs' -and $partialSettings -match 'pelizzai-guardrails\.mjs' -and [regex]::Matches($partialSettings, 'pelizzai-writegate\.mjs').Count -eq 2) 'installer --only preserves the previous hook and registers both writegate matchers'
        Check ($partialSettings -notmatch 'pelizzai-session-start\.mjs') 'installer --only does not install a hook outside the list'
        $null = & node scripts/install-hooks.mjs --project $hooksTemp --only nonexistent 2>&1
        Check ($LASTEXITCODE -eq 1) 'installer rejects an unknown id in --only'
        Run-Native { node scripts/install-hooks.mjs --project $hooksTemp --remove } 'installer cleans up the partial state at the end'
    } finally {
        if (Test-Path -LiteralPath $hooksTemp) { Remove-Item -LiteralPath $hooksTemp -Recurse -Force }
    }

    # -- Multi-surface parity: the non-negotiables reach the generated AGENTS.md AND Cursor --
    Check-Match 'AGENTS.md' 'Ratification gate' 'generated AGENTS.md receives the ratification gate'
    Check-Match 'GEMINI.md' 'Ratification gate' 'generated GEMINI.md receives the ratification gate'
    Check-Match 'AGENTS.md' 'team[^\n]{0,30}visible' 'AGENTS.md: team always visible in the mode'
    Check-Match 'AGENTS.md' 'squash-final[^\n]{0,30}only on explicit request' 'AGENTS.md: squash-final only on explicit request'
    $parityAnchors = @(
        @{ Name = 'branch protection'; Pattern = 'master[\s\S]{0,30}develop' },
        @{ Name = 'first-write gate'; Pattern = 'first[\s-]?write' },
        @{ Name = 'ratification gate (team visible)'; Pattern = 'team[^\n]{0,30}always visible' }
    )
    $agentsText = Text 'AGENTS.md'
    $cursorText = Text '.cursor/rules/pelizzai.mdc'
    foreach ($a in $parityAnchors) {
        $inAgents = [regex]::IsMatch($agentsText, $a.Pattern, 'IgnoreCase, Multiline')
        $inCursor = [regex]::IsMatch($cursorText, $a.Pattern, 'IgnoreCase, Multiline')
        Check ($inAgents -and $inCursor) "non-negotiable in AGENTS.md and Cursor: $($a.Name)" "agents=$inAgents cursor=$inCursor"
    }

    # Dangling references: every pelizzai-* token cited in the skills actually exists.
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
    Check ($danglingRefs.Count -eq 0) 'skills cite no nonexistent pelizzai-*' ($danglingRefs -join '; ')

    # Core and router agree on the head skills catalog.
    $coreText = Text '.claude/skills/pelizzai-core/SKILL.md'
    $routerText = Text '.claude/skills/pelizzai-router/SKILL.md'
    $coreHeadsSection = [regex]::Match($coreText, '(?s)### Head skills.*?### Overlays').Value
    $coreHeads = @([regex]::Matches($coreHeadsSection, 'pelizzai-[a-z][a-z0-9-]*') |
        ForEach-Object { $_.Value } | Sort-Object -Unique)
    $headsMissingInRouter = @($coreHeads | Where-Object { $routerText -notmatch [regex]::Escape($_) })
    Check ($coreHeads.Count -ge 8 -and $headsMissingInRouter.Count -eq 0) `
        'router routes every head skill announced by core' "missing=$($headsMissingInRouter -join ',')"

    # Effect→proof matrix: the distributed copies agree on the essential anchors.
    $proofMatrixFiles = @(
        '.claude/skills/pelizzai-tdd/SKILL.md',
        '.claude/skills/pelizzai-execute/references/task-cycle.md',
        '.claude/skills/pelizzai-plan/SKILL.md',
        '.claude/skills/pelizzai-quick-fix/SKILL.md',
        '.claude/skills/pelizzai-verify/SKILL.md',
        '.claude/skills/pelizzai-preferences/SKILL.md'
    )
    $proofAnchors = @(
        @{ Name = 'refactor->characterization'; Effect = 'refator|refactor'; Proof = 'caracteriza|characterization' },
        @{ Name = 'config/IaC->validate/dry-run'; Effect = 'IaC|migra|config'; Proof = 'validate|dry-run|\bplan\b' },
        @{ Name = 'UI->pelizzai-interface'; Effect = 'UI|visual|frontend'; Proof = 'pelizzai-interface' },
        @{ Name = 'docs->static proof'; Effect = 'doc'; Proof = 'lint|render|est[áa]tic|static|inspeç' }
    )
    foreach ($file in $proofMatrixFiles) {
        $skillName = ($file -split '/')[2]
        $matrixLines = (Text $file) -split "`r?`n"
        foreach ($anchor in $proofAnchors) {
            $hit = @($matrixLines | Where-Object { $_ -match $anchor.Effect -and $_ -match $anchor.Proof })
            Check ($hit.Count -ge 1) "effect→proof matrix ($($anchor.Name)) in $skillName" $file
        }
    }

    # The 1% rule restored by user decision (2026-07-21): the session hook reaffirms it at startup,
    # in both variants, together with the EXTREMELY-IMPORTANT block of pelizzai-core.
    foreach ($sh in @('.claude/hooks/pelizzai-session-start.mjs', '.claude/hooks/pelizzai-session-start.ps1')) {
        Check-Match $sh 'the 1% rule' "session hook reaffirms the 1% rule ($(Split-Path -Leaf $sh))"
    }

    # Equivalent guardrails: they only classify strings; no Git command is executed.
    $hooks = @(
        (Join-Path $root '.claude/hooks/pelizzai-guardrails.mjs'),
        (Join-Path $root '.claude/hooks/pelizzai-guardrails.ps1')
    )
    $safe = @('git status', 'Git push --force-with-lease origin topic', 'git restore --staged .', 'git restore -S file.txt', 'git branch -d merged', 'git branch -m old new')
    # Outside the hook's NARROW scope — these pass ON PURPOSE. The hook targets the handful of
    # commands that erase work irrecoverably; a broad rule blocks legitimate work and teaches the
    # agent to route around the safety net. These fixtures exist so the narrowing stays deliberate
    # and visible: if anyone widens the matcher again, they break and the decision goes back to the user.
    $safeByDesign = @(
        'git push origin +HEAD:main', 'git push origin +main', 'git push origin --delete topic',
        'git push origin :topic', 'git checkout -- file.txt', 'git branch -M main',
        'git restore file.txt', 'git restore -SW file.txt',
        'git commit -m "fix: restore layout"', 'git add src/restore.ts', 'git log --grep=restore'
    )
    # Guards against false positives in the checkout/branch rules: creating is not destroying.
    $safeByDesign += @(
        'git checkout -b feature/new', 'git checkout feature/foo', 'git checkout main',
        'git branch --delete merged', 'git branch --list'
    )
    $blocked = @(
        'git push -f origin topic', 'Git reset --hard', 'git switch -C topic',
        'git clean -fd', 'git restore .', 'git checkout .', 'git checkout -- .',
        'git branch -D topic', 'git worktree remove --force ../topic'
    )
    # Ratified by the user on 2026-07-21: these three spellings are NOT "narrow scope", they are the
    # SAME destruction already blocked, written another way — allowing them would leave a trivial
    # bypass in the hook. `checkout -f` == `checkout .`; `checkout -B` == `switch -C`; `branch --delete --force`
    # == `branch -D`. The other commands above stay allowed, as in the pre-2026-07-11 state.
    $blocked += @(
        'git checkout -f topic', 'git checkout --force', 'git checkout -B topic main',
        'git branch --delete --force topic', 'git branch --force --delete topic',
        'git branch --delete -f topic'
    )
    foreach ($hook in $hooks) {
        $label = Split-Path -Leaf $hook
        foreach ($command in ($safe + $safeByDesign)) {
            $exit = Invoke-Guardrail $hook $command
            Check ($exit -eq 0) "$label allows: $command" "exit $exit"
        }
        foreach ($command in $blocked) {
            $exit = Invoke-Guardrail $hook $command
            Check ($exit -eq 2) "$label blocks: $command" "exit $exit"
        }
    }

    # Parity is more than exit codes: the agent READS the denial, so the two legs must say the
    # same thing. Compare the full stderr of one blocked command, normalized only for EOL.
    function Get-GuardrailStderr([string]$Hook, [string]$Command) {
        $payload = @{ tool_input = @{ command = $Command } } | ConvertTo-Json -Compress
        $errFile = Join-Path ([IO.Path]::GetTempPath()) ("pelizzai-stderr-{0}.txt" -f [guid]::NewGuid().ToString('N'))
        try {
            if ($Hook.EndsWith('.mjs')) { $null = $payload | & node $Hook 2>$errFile }
            else { $null = $payload | & pwsh -NoProfile -File $Hook 2>$errFile }
            return ((Get-Content -LiteralPath $errFile -Raw -ErrorAction SilentlyContinue) ?? '') -replace "`r`n", "`n"
        } finally {
            Remove-Item -LiteralPath $errFile -Force -ErrorAction SilentlyContinue
        }
    }
    $mjsDenial = Get-GuardrailStderr $hooks[0] 'git reset --hard'
    $ps1Denial = Get-GuardrailStderr $hooks[1] 'git reset --hard'
    Check -Condition ($mjsDenial -ne '' -and $mjsDenial -eq $ps1Denial) -Name 'guardrails: both legs emit an identical denial message' -Detail "mjs=$(($mjsDenial -split "`n")[0])"

    # Syntax and interface of the visual scripts.
    Run-Native { node --check .claude/hooks/pelizzai-guardrails.mjs } 'node parse guardrails'
    Run-Native { node --check .claude/skills/pelizzai-discovery/scripts/server.cjs } 'node parse visual server'
    $bash = Get-Command bash -ErrorAction SilentlyContinue
    $bashUsable = $false
    if ($bash -and $bash.Source -notmatch '(?i)[\\/]Windows[\\/]System32[\\/]bash\.exe$') {
        $null = & bash --version 2>$null
        $bashUsable = ($LASTEXITCODE -eq 0)
    }
    if ($bashUsable) {
        Run-Native { bash -n .claude/skills/pelizzai-discovery/scripts/start-server.sh } 'bash parse visual launcher'
        Run-Native { bash -n scripts/review-package.sh } 'bash parse review package'
    }
    $help = & pwsh -NoProfile -File .claude/skills/pelizzai-discovery/scripts/start-server.ps1 -Help 2>&1
    Check ($LASTEXITCODE -eq 0 -and ($help -join "`n") -match 'IdleTimeoutMinutes') 'PowerShell visual launcher exposes help'

    # Fixtures for the handoff/review helpers, in an isolated temporary repo.
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
# Fixture plan

**Global Constraints:**
- global-contract-sentinel
```text
### Task 99: header inside a fence
```

---

### Task 1: first

- task-one-sentinel
```text
### Task 2: also inside a fence
```

### Task 2: second

- task-two-sentinel
'@ | Set-Content -LiteralPath 'pelizzai/plans/fixture.md' -Encoding utf8

        $briefOut = @(& pwsh -NoProfile -File (Join-Path $root 'scripts/task-brief.ps1') 'pelizzai/plans/fixture.md' 1)
        $briefPath = $briefOut[-1]
        $handoffCleanup = Split-Path -Parent $briefPath
        $brief = Get-Content -LiteralPath $briefPath -Raw
        Check ($brief -match 'global-contract-sentinel' -and $brief -match 'task-one-sentinel' -and $brief -notmatch 'task-two-sentinel') `
            'task-brief preserves constraints and fence boundaries'
        Check (-not (Test-Path -LiteralPath 'pelizzai/data/handoffs')) 'helper without bootstrap uses temp, not the project runtime'

        Set-Content -LiteralPath 'seed.txt' -Value 'unstaged-review-sentinel' -Encoding utf8
        Set-Content -LiteralPath 'staged.txt' -Value 'staged-review-sentinel' -Encoding utf8
        git add staged.txt
        Set-Content -LiteralPath 'untracked.txt' -Value 'untracked-review-sentinel' -Encoding utf8
        Set-Content -LiteralPath 'credentials.json' -Value 'sensitive-review-sentinel' -Encoding utf8

        $workingOut1 = @(& pwsh -NoProfile -File (Join-Path $root 'scripts/review-package.ps1') '--working-tree')
        $workingPath1 = $workingOut1[-1]
        $working = Get-Content -LiteralPath $workingPath1 -Raw
        Check ($working -match 'unstaged-review-sentinel' -and $working -match 'staged-review-sentinel' -and $working -match 'untracked-review-sentinel') `
            'review working-tree includes unstaged, staged, and untracked'
        Check ($working -match 'credentials\.json' -and $working -match 'potentially sensitive' -and $working -notmatch 'sensitive-review-sentinel') `
            'review package does not read sensitive untracked files'

        $workingOut2 = @(& pwsh -NoProfile -File (Join-Path $root 'scripts/review-package.ps1') '--working-tree')
        Check ($workingOut2[-1] -ne $workingPath1) 'review packages have unique names'

        git add seed.txt staged.txt untracked.txt
        git commit -q -m 'feat: contract sentinels'
        $headSha = (git rev-parse HEAD).Trim()
        $rangeOut = @(& pwsh -NoProfile -File (Join-Path $root 'scripts/review-package.ps1') $baseSha $headSha)
        $range = Get-Content -LiteralPath $rangeOut[-1] -Raw
        Check ($range -match 'unstaged-review-sentinel' -and $range -match 'staged-review-sentinel' -and $range -match 'untracked-review-sentinel') `
            'final review covers base-sha..HEAD'

        New-Item -ItemType Directory -Path 'pelizzai' -Force | Out-Null
        Set-Content -LiteralPath 'pelizzai/.gitignore' -Value "data/handoffs/`n" -Encoding utf8
        $consumerOut = @(& pwsh -NoProfile -File (Join-Path $root 'scripts/review-package.ps1') '--working-tree')
        # macOS: Get-Location stays on the LOGICAL spelling (/var/...) while the helper's
        # git-derived path is PHYSICAL (/private/var/...). Compare both at the physical spelling.
        function Get-PhysicalDir([string]$p) {
            if ($env:OS -eq 'Windows_NT' -or $IsWindows -or -not (Test-Path -LiteralPath $p)) { return $p }
            $o = & sh -c 'cd "$0" && pwd -P' $p 2>$null
            if ($LASTEXITCODE -eq 0 -and $o) { return ([string]($o | Select-Object -Last 1)).Trim() }
            return $p
        }
        $actualHandoffDir = Get-PhysicalDir (Split-Path -Parent $consumerOut[-1])
        $expectedConsumer = Get-PhysicalDir (Join-Path (Get-Location).Path 'pelizzai/data/handoffs')
        Check ($actualHandoffDir -eq $expectedConsumer) 'consumer helper uses the gitignored handoff'
    } finally {
        Pop-Location
    }
} catch {
    Check $false 'suite execution' $_.Exception.Message
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
            ($handoffLeaf -like 'pelizzai-continuitys*' -or $handoffParentLeaf -eq 'pelizzai-continuitys')) {
            Remove-Item -LiteralPath $resolvedHandoff -Recurse -Force
        }
    }
}

# -- Fixes from the PR #4 review (CodeRabbit, 2026-07-21) --
# Each assertion locks a real contradiction found in the review. They are additions: no
# earlier assertion was weakened to accommodate them.
#
# The block has its OWN handler because it runs outside the main try/catch (which already
# closed above, together with the temporary directory cleanup). Without it, a missing file or an
# invalid regex would abort the script without recording a FAIL or printing the summary — the
# suite would end in silence, the most dangerous failure mode for a safety net.
try {
    # The 1% rule: the 1% triggers LOADING and evaluating; only a candidate already read and not
    # applicable may be dismissed. The old wording allowed ignoring an "applicable" skill.
    Check-Match '.claude/skills/pelizzai-core/SKILL.md' 'load and evaluate' 'core: the 1% triggers load and evaluate, not dismissal from afar'
    Check-NotMatch '.claude/skills/pelizzai-core/SKILL.md' 'applicable skill does not fit that case, you may ignore it' 'core: there is no route to ignore an applicable skill'

    # Parallel writes in a worktree: the condition is disjoint paths, not a flat ban.
    Check-NotMatch '.claude/skills/pelizzai-execute/SKILL.md' 'multiple concurrent writers in the same' 'execution-plans does not reimpose a single writer under worktree isolation'
    Check-Match '.claude/skills/pelizzai-preferences/SKILL.md' 'disjoint paths' 'preferences: the floor does not deny parallel writes on disjoint paths'
    Check-Match '.claude/skills/pelizzai-preferences/SKILL.md' 'never one worktree per agent' 'preferences: the floor repeats the one-worktree-per-agent ban'

    # The closure is TWO metadata files: state.md + the block migrated to history/.
    Check-Match '.claude/skills/pelizzai-finish/SKILL.md' 'the two closure metadata files' 'finish-task: pre-destination guard requires state + history, not just state'

    # A plan gap goes to the interview; guessing stopped being expected behavior.
    Check-Match '.claude/skills/pelizzai-plan/SKILL.md' 'whatever the plan lacks[\s\S]{0,140}pelizzai-interview' 'writing-plans: a plan gap goes to interview-me, never to guessing'
    Check-NotMatch '.claude/skills/pelizzai-plan/SKILL.md' 'fill[^\n]{0,20}by guessing' 'writing-plans does not describe guessing as executor behavior'

    # The ratification is read in both modes (consumer and source).
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' 'consumer state or native execution record' 'interview-me reads the ratification in both modes'

    # Pasted output only counts from whoever ran the check — never from the author.
    Check-Match '.claude/skills/pelizzai-team/SKILL.md' 'whoever ran the check' 'team: pasted output only counts from whoever ran the check, never the author'
    Check-NotMatch '.claude/skills/pelizzai-team/SKILL.md' 'or require the pasted output \+ exit code' 'team: a member paste does not replace verification'

    # The SessionStart recap triggers on any raw value, not on a closed enum.
    Check-Match '.claude/skills/pelizzai-onboard/templates/profile.md' 'ANY raw value outside' 'profile.md describes the recap trigger as any raw value'

    # The Cursor adapter is manual: calling it a generated mirror makes the author never update it.
    Check-NotMatch '.claude/skills/pelizzai-skill-lab/references/skill-authoring.md' '`\.cursor/` as generated mirrors' 'skill-authoring does not call the Cursor adapter a generated mirror'

    # README: the closeout flow described is the consumer one; source mode carries a caveat.
    Check-Match 'README.md' 'PelizzAI source repo[\s\S]{0,260}does not create\s*\r?\na metadata-only commit' 'README: closeout carries the source mode caveat'

    # CLAUDE.md: model/effort are never downgraded below the session ones — stated without zeugma.
    Check-Match 'CLAUDE.md' 'implementation subagents may run a mid tier when the user ratifies it' 'CLAUDE.md: the executor tier is a user-ratified choice'
} catch {
    Check $false 'PR #4 review fixes' $_.Exception.Message
}

# ---------------------------------------------------------------------------
# Reasoning technique merge (2026-07-22): Tree of Thoughts becomes the search
# mode with pruning/backtracking inside Decision Making; Self-Consistency becomes the
# cross-check via independent runs inside Verification (reserved for
# multi-agent). Lean ReAct preserves the anti-fabrication discipline. The canonical
# name of the premortem routine is Proposal Stress (Assumption Tracking applied).
# ---------------------------------------------------------------------------
try {
    # v3 slice 9: the whole skill dissolved. The invocation layer is gone; the vocabulary stays
    # where each head skill uses it. Proposal Stress moved to the router's references, OODA to
    # the loop's. The merged-technique residue scan below still guards the historical merge.
    Check (-not (Test-Path (Join-Path $root '.claude/skills/pelizzai-reasoning'))) 'pelizzai-reasoning no longer exists as a skill'
    $reasoningRefs = Get-ChildItem -LiteralPath (Join-Path $root '.claude/skills') -Recurse -File -Filter '*.md' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw -Encoding utf8) -match 'pelizzai-reasoning' }
    Check (@($reasoningRefs).Count -eq 0) 'no skill still references pelizzai-reasoning' (@($reasoningRefs | ForEach-Object { $_.FullName }) -join '; ')
    Check-Match '.claude/skills/pelizzai-router/references/proposal-stress.md' 'Proposal Stress' 'proposal-stress lives in the router references'
    Check-Match '.claude/skills/pelizzai-loop/references/ooda.md' 'OODA' 'ooda lives in the loop references'
    Check-Match '.claude/skills/pelizzai-router/SKILL.md' 'Proposal Stress' 'router uses the canonical name Proposal Stress'
    Check-Match '.claude/skills/pelizzai-interview/SKILL.md' 'proposal-stress\.md' 'interview points at the router-owned Proposal Stress routine'
    Check-NotMatch '.claude/skills/pelizzai-team/SKILL.md' 'Self-Consistency|Tree of Thoughts' 'team migrated to cross-check (Verification) and Decision Making'
    Check-NotMatch '.claude/skills/pelizzai-module-design/SKILL.md' 'Tree of Thoughts|(?-i:\bToT\b)' 'codebase-design migrated to Decision Making (search with pruning)'
    Check-NotMatch '.claude/skills/pelizzai-execute/SKILL.md' 'comparison/ToT' 'execution-plans no longer cites ToT'
    $reasoningResidue = Get-ChildItem -LiteralPath (Join-Path $root '.claude/skills') -Recurse -File -Filter '*.md' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw -Encoding utf8) -cmatch '(?i:tree.of.thoughts|self.consistency)|\bToT\b' }
    Check (@($reasoningResidue).Count -eq 0) 'no skill references the merged techniques' (@($reasoningResidue | ForEach-Object { $_.FullName }) -join '; ')
} catch {
    Check $false 'reasoning technique merge' $_.Exception.Message
}

Write-Host "`nResult: $passes PASS; $($failures.Count) FAIL."
if ($failures.Count -gt 0) {
    foreach ($failure in $failures) { Write-Host " - $failure" }
    exit 1
}
exit 0
