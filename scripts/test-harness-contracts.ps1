#!/usr/bin/env pwsh
#Requires -Version 7.0
# PelizzAI - harness contract suite.
#
# Two families of check, and only two: checks that EXECUTE a script, hook, or fixture and judge
# its exit code and output, and checks of STRUCTURAL integrity that compare files or sets (the
# manifest, the mirrors, the references). A regex that proves a sentence exists in prose is not a
# contract and does not belong here; size is reported by measure-hotpath.mjs, never enforced.
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

function Get-RelativeFiles([string]$Base) {
    $prefixLength = $Base.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar).Length + 1
    return @(Get-ChildItem -LiteralPath $Base -Recurse -File | ForEach-Object {
        $_.FullName.Substring($prefixLength).Replace('\', '/')
    } | Sort-Object)
}

# Same paths and same hashes between two trees; returns "paths=N hashes=M" for the detail.
function Compare-Trees([string]$Source, [string]$Mirror) {
    $srcFiles = Get-RelativeFiles $Source
    $dstFiles = if (Test-Path -LiteralPath $Mirror) { Get-RelativeFiles $Mirror } else { @() }
    $treeDiff = @(Compare-Object $srcFiles $dstFiles)
    $hashDiff = 0
    if ($treeDiff.Count -eq 0) {
        foreach ($rel in $srcFiles) {
            $a = Join-Path $Source $rel
            $b = Join-Path $Mirror $rel
            if ((Get-FileHash $a).Hash -ne (Get-FileHash $b).Hash) { $hashDiff++ }
        }
    }
    return @{ Ok = ($treeDiff.Count -eq 0 -and $hashDiff -eq 0); Detail = "paths=$($treeDiff.Count) hashes=$hashDiff" }
}

# Runs a hook the way the platform does: JSON on stdin, verdict in the exit code.
function Invoke-Hook([string]$Hook, [string]$Payload) {
    if ($Hook.EndsWith('.mjs')) {
        $null = $Payload | & node $Hook 2>$null
    } else {
        $null = $Payload | & pwsh -NoProfile -File $Hook 2>$null
    }
    return $LASTEXITCODE
}

# Same as Invoke-Hook, but keeps stdout: advisory hooks speak through `additionalContext`.
function Invoke-HookOutput([string]$Hook, [string]$Payload) {
    if ($Hook.EndsWith('.mjs')) {
        $out = @($Payload | & node $Hook 2>$null)
    } else {
        $out = @($Payload | & pwsh -NoProfile -File $Hook 2>$null)
    }
    return @{ Exit = $LASTEXITCODE; Out = (($out | ForEach-Object { [string]$_ }) -join "`n") }
}

# The `additionalContext` a hook emitted, or '' when it stayed silent or spoke no JSON.
function Get-AdditionalContext([string]$Stdout) {
    if (-not $Stdout.Trim()) { return '' }
    try { return [string](($Stdout | ConvertFrom-Json).hookSpecificOutput.additionalContext) } catch { return '' }
}

function Invoke-Guardrail([string]$Hook, [string]$Command) {
    $payload = @{ tool_input = @{ command = $Command } } | ConvertTo-Json -Compress
    return Invoke-Hook $Hook $payload
}

function Invoke-Writegate([string]$Hook, [hashtable]$ToolInput, [string]$Cwd) {
    $payload = @{ tool_input = $ToolInput; cwd = $Cwd } | ConvertTo-Json -Compress
    return Invoke-Hook $Hook $payload
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

    # =====================================================================
    # Structure: sets and mirrors, compared, never grepped.
    # =====================================================================

    $skillRoot = Join-Path $root '.claude/skills'
    $skillDirs = @(Get-ChildItem -LiteralPath $skillRoot -Directory | Sort-Object Name)
    $dirNames = @($skillDirs.Name)

    # The manifest is an exact set of the skill directories, with no duplicates.
    $manifest = @(Get-Content scripts/pelizzai-core-skills.txt | ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and $_ -notmatch '^#' })
    $missing = @($dirNames | Where-Object { $manifest -notcontains $_ })
    $dangling = @($manifest | Where-Object { $dirNames -notcontains $_ })
    $duplicates = @($manifest | Group-Object | Where-Object Count -gt 1)
    Check ($missing.Count -eq 0 -and $dangling.Count -eq 0 -and $duplicates.Count -eq 0) `
        'source repo manifest is exact' "missing=$($missing -join ',') dangling=$($dangling -join ',') duplicates=$($duplicates.Count)"

    # Interoperable mirror: same paths and same hashes.
    $agentsMirror = Compare-Trees $skillRoot (Join-Path $root '.agents/skills')
    Check $agentsMirror.Ok '.agents mirrors .claude' $agentsMirror.Detail

    # The sync's own structural check (mirrors, managed blocks, refs, manifest), and both wrappers.
    Run-Native { node scripts/sync-harness.mjs --check --source-mode } 'sync --check --source-mode passes'
    Run-Native { pwsh -NoProfile -File scripts/sync-harness.ps1 -Check -SourceMode } 'PowerShell wrapper delegates --check --source-mode'

    # Source mode hinges on one file: every tool reads it, no consumer may carry it.
    Check (Test-Path (Join-Path $root 'scripts/pelizzai-source-repo.txt')) 'source repo sentinel exists in the source'

    # Dangling references: every pelizzai-* token cited by the skills and the entry files resolves
    # to a skill, a hook, or a known script.
    $hookNames = @(Get-ChildItem -LiteralPath (Join-Path $root '.claude/hooks') -File |
        ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_.Name) } | Sort-Object -Unique)
    $knownTokens = @($dirNames) + $hookNames + @('pelizzai-core-skills', 'pelizzai-source-repo')
    $referenceDocs = @(Get-ChildItem -LiteralPath $skillRoot -Recurse -File -Filter '*.md') +
        @(Get-Item -LiteralPath (Join-Path $root 'CLAUDE.md')) +
        @(Get-Item -LiteralPath (Join-Path $root '.cursor/rules/pelizzai.mdc'))
    $danglingRefs = [System.Collections.Generic.List[string]]::new()
    foreach ($doc in $referenceDocs) {
        $content = Get-Content -LiteralPath $doc.FullName -Raw -Encoding utf8
        foreach ($m in [regex]::Matches($content, 'pelizzai-[a-z][a-z0-9-]*')) {
            if ($knownTokens -notcontains $m.Value) { $danglingRefs.Add("$($doc.Name): $($m.Value)") }
        }
    }
    $danglingRefs = @($danglingRefs | Sort-Object -Unique)
    Check ($danglingRefs.Count -eq 0) 'skills and entry files cite no nonexistent pelizzai-*' ($danglingRefs -join '; ')

    # Core and router agree on the head-skills catalog: the set core announces is the set the
    # router routes. The floor on the count guards the extraction itself - an empty set would
    # pass vacuously.
    $coreText = Text '.claude/skills/pelizzai-core/SKILL.md'
    $routerText = Text '.claude/skills/pelizzai-router/SKILL.md'
    $coreHeadsSection = [regex]::Match($coreText, '(?s)### Head skills.*?### Overlays').Value
    $coreHeads = @([regex]::Matches($coreHeadsSection, 'pelizzai-[a-z][a-z0-9-]*') |
        ForEach-Object { $_.Value } | Sort-Object -Unique)
    $headsMissingInRouter = @($coreHeads | Where-Object { $routerText -notmatch [regex]::Escape($_) })
    Check ($coreHeads.Count -ge 8 -and $headsMissingInRouter.Count -eq 0) `
        'router routes every head skill announced by core' "heads=$($coreHeads.Count) missing=$($headsMissingInRouter -join ',')"

    # The CI workflow still runs every instrument: the set of `run:` commands (inline and block
    # scalars) must contain the five, each in the form the workflow invokes it.
    $wfLines = (Text '.github/workflows/check-harness.yml') -split "`r?`n"
    $wfRuns = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $wfLines.Count; $i++) {
        if ($wfLines[$i] -match '^(\s*)run:\s*[|>][-+]?\s*$') {
            $runIndent = $Matches[1].Length
            for ($j = $i + 1; $j -lt $wfLines.Count; $j++) {
                if ($wfLines[$j].Trim() -eq '') { continue }
                if (($wfLines[$j] -replace '^(\s*).*$', '$1').Length -le $runIndent) { break }
                $wfRuns.Add($wfLines[$j].Trim())
            }
        } elseif ($wfLines[$i] -match '^\s*run:\s*(\S.*?)\s*$') {
            $wfRuns.Add($Matches[1])
        }
    }
    $wfRequired = @(
        'pwsh scripts/test-harness-contracts.ps1',
        'node scripts/sync-harness.mjs --check --source-mode',
        'pwsh scripts/sync-harness.ps1 -Check -SourceMode',
        'bash scripts/sync-harness.sh --check --source-mode',
        'node scripts/sync-harness.mjs --build-dist',
        'git diff --cached --exit-code -- dist',
        'node scripts/validate-skills.mjs',
        'node scripts/measure-hotpath.mjs',
        'node tests/mutation/run.mjs'
    )
    $wfMissing = @($wfRequired | Where-Object { $wfRuns -notcontains $_ })
    Check ($wfRuns.Count -ge $wfRequired.Count -and $wfMissing.Count -eq 0) 'CI workflow runs every instrument' "parsed=$($wfRuns.Count) missing=$($wfMissing -join ' | ')"

    # =====================================================================
    # Executed: scripts parse, hooks decide, fixtures run.
    # =====================================================================

    Run-Native { node --check scripts/sync-harness.mjs } 'node parse portable sync'
    Run-Native { node --check scripts/install-hooks.mjs } 'node parse hook installer'
    Run-Native { node --check .claude/hooks/pelizzai-guardrails.mjs } 'node parse guardrails'
    Run-Native { node --check .claude/hooks/pelizzai-writegate.mjs } 'node parse writegate'
    Run-Native { node --check .claude/hooks/pelizzai-cadence.mjs } 'node parse cadence'
    Run-Native { node --check .claude/hooks/pelizzai-session-start.mjs } 'node parse session-start'
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
        Run-Native { bash scripts/sync-harness.sh --check --source-mode } 'Unix wrapper delegates --check --source-mode'
    }
    $help = & pwsh -NoProfile -File .claude/skills/pelizzai-discovery/scripts/start-server.ps1 -Help 2>&1
    Check ($LASTEXITCODE -eq 0 -and ($help -join "`n") -match 'IdleTimeoutMinutes') 'PowerShell visual launcher exposes help'

    # -- Advisory hooks fail open: run them where no harness exists and on garbage input. --
    # Cadence and SessionStart may only ever inform; a non-zero exit here would block the
    # user's prompt or session in a project that never opted in.
    $bareTemp = Join-Path ([IO.Path]::GetTempPath()) ("pelizzai-bare-{0}" -f [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $bareTemp | Out-Null
    try {
        $barePayload = @{ cwd = $bareTemp } | ConvertTo-Json -Compress
        foreach ($advisory in @('pelizzai-cadence.mjs', 'pelizzai-cadence.ps1', 'pelizzai-session-start.mjs', 'pelizzai-session-start.ps1')) {
            $hookPath = Join-Path $root ".claude/hooks/$advisory"
            Check ((Invoke-Hook $hookPath $barePayload) -eq 0) "advisory hook exits 0 with no harness footprint ($advisory)"
            Check ((Invoke-Hook $hookPath 'not json at all') -eq 0) "advisory hook exits 0 on malformed input ($advisory)"
        }
        # Without the ledger the cadence is a no-op: it must not even create its counter file.
        Check (-not (Test-Path (Join-Path $bareTemp 'pelizzai'))) 'cadence writes nothing where the ledger is absent'
    } finally {
        if (Test-Path -LiteralPath $bareTemp) { Remove-Item -LiteralPath $bareTemp -Recurse -Force }
    }

    # -- SessionStart: the catalog nudge fires in a consumer without a catalog, never in the source repo. --
    # Source mode is the dedicated sentinel; a manifest plus a sync script is a consumer, not the source.
    $ssSource = Join-Path ([IO.Path]::GetTempPath()) ("pelizzai-ss-source-{0}" -f [guid]::NewGuid().ToString('N'))
    $ssConsumer = Join-Path ([IO.Path]::GetTempPath()) ("pelizzai-ss-consumer-{0}" -f [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType Directory -Path (Join-Path $ssSource 'scripts') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $ssSource 'scripts/pelizzai-source-repo.txt') -Value 'x' -Encoding utf8
        New-Item -ItemType Directory -Path (Join-Path $ssConsumer 'scripts') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $ssConsumer 'scripts/pelizzai-core-skills.txt') -Value 'pelizzai-core' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $ssConsumer 'scripts/sync-harness.mjs') -Value '// stub' -Encoding utf8
        $nudge = 'no domain-skill catalog'
        foreach ($ss in @('pelizzai-session-start.mjs', 'pelizzai-session-start.ps1')) {
            $ssHook = Join-Path $root ".claude/hooks/$ss"
            $inSource = Invoke-HookOutput $ssHook (@{ cwd = $ssSource } | ConvertTo-Json -Compress)
            $inConsumer = Invoke-HookOutput $ssHook (@{ cwd = $ssConsumer } | ConvertTo-Json -Compress)
            $sourceCtx = Get-AdditionalContext $inSource.Out
            $consumerCtx = Get-AdditionalContext $inConsumer.Out
            Check ($inSource.Exit -eq 0 -and $sourceCtx -match 'pelizzai-core' -and $sourceCtx -notmatch $nudge) "session-start: source repo (sentinel) gets the reminder without the catalog nudge ($ss)" "exit=$($inSource.Exit)"
            Check ($inConsumer.Exit -eq 0 -and $consumerCtx -match $nudge) "session-start: consumer (manifest+sync, no sentinel, no catalog) gets the catalog nudge ($ss)" "exit=$($inConsumer.Exit)"
        }
    } finally {
        foreach ($d in @($ssSource, $ssConsumer)) { if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force } }
    }

    # -- Cadence: the nudge fires at the Nth interaction once a threshold is crossed, and only then. --
    # State shape read from the hooks: pelizzai/data/.cadence-state.json = { count, snoozeUntil };
    # the ledger pelizzai/data/review-domain-skills.md carries `last-review:` / `last-full-scan:`.
    # Fixture 1 crosses the COMMIT axis for real (10 commits since a review dated today);
    # fixture 2 crosses the DAY axes by backdating the ledger 30 days in a one-commit repo.
    function New-CadenceRepo([int]$Commits, [string]$LastReview, [string]$LastScan) {
        $dir = Join-Path ([IO.Path]::GetTempPath()) ("pelizzai-cadence-{0}" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $dir 'pelizzai/data') -Force | Out-Null
        git -C $dir init -q
        git -C $dir config user.email 'contract@pelizzai.local'
        git -C $dir config user.name 'PelizzAI Contract'
        for ($c = 1; $c -le $Commits; $c++) {
            Set-Content -LiteralPath (Join-Path $dir 'work.txt') -Value "commit $c" -Encoding utf8
            git -C $dir add work.txt
            git -C $dir commit -q -m "feat: change $c"
        }
        Set-Content -LiteralPath (Join-Path $dir 'pelizzai/data/review-domain-skills.md') -Value "# Ledger`n- last-review: $LastReview`n- last-full-scan: $LastScan`n" -Encoding utf8
        return $dir
    }
    function Set-CadenceState([string]$Dir, [int]$Count, [long]$SnoozeUntil) {
        Set-Content -LiteralPath (Join-Path $Dir 'pelizzai/data/.cadence-state.json') -Value ("{""count"":$Count,""snoozeUntil"":$SnoozeUntil}") -Encoding utf8 -NoNewline
    }
    function Get-CadenceState([string]$Dir) {
        return Get-Content -LiteralPath (Join-Path $Dir 'pelizzai/data/.cadence-state.json') -Raw | ConvertFrom-Json
    }
    $today = (Get-Date).ToString('yyyy-MM-dd')
    $thirtyDaysAgo = (Get-Date).AddDays(-30).ToString('yyyy-MM-dd')
    $cadCommits = New-CadenceRepo 10 $today $today
    $cadDays = New-CadenceRepo 1 $thirtyDaysAgo $thirtyDaysAgo
    try {
        $cadNudges = @{}
        foreach ($cad in @('pelizzai-cadence.mjs', 'pelizzai-cadence.ps1')) {
            $cadHook = Join-Path $root ".claude/hooks/$cad"
            $payload = @{ cwd = $cadCommits } | ConvertTo-Json -Compress

            # (b) N-1: the counter advances, nothing is said.
            Set-CadenceState $cadCommits 8 0
            $r = Invoke-HookOutput $cadHook $payload
            Check ($r.Exit -eq 0 -and (Get-AdditionalContext $r.Out) -eq '' -and (Get-CadenceState $cadCommits).count -eq 9) "cadence: interaction N-1 counts and stays silent ($cad)" "exit=$($r.Exit) out=$($r.Out)"

            # (a) N: 10 commits since a review dated today crosses COMMIT_THRESHOLD -> nudge.
            $r = Invoke-HookOutput $cadHook $payload
            $ctx = Get-AdditionalContext $r.Out
            $cadNudges[$cad] = $ctx
            Check ($r.Exit -eq 0 -and $ctx -match 'PelizzAI \(cadence\)' -and $ctx -match '10 commit\(s\)' -and $ctx -match 'pelizzai-skill-lab') "cadence: interaction N with the commit threshold crossed emits the nudge ($cad)" "out=$($r.Out)"

            # (d) The nudge arms the snooze; the next window stays silent while it lasts.
            $after = Get-CadenceState $cadCommits
            $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
            Check ($after.count -eq 10 -and [long]$after.snoozeUntil -gt $nowMs) "cadence: the nudge persists a future snoozeUntil ($cad)" "state=$($after | ConvertTo-Json -Compress)"
            Set-CadenceState $cadCommits 19 ([long]$after.snoozeUntil)
            $r = Invoke-HookOutput $cadHook $payload
            Check ($r.Exit -eq 0 -and (Get-AdditionalContext $r.Out) -eq '' -and (Get-CadenceState $cadCommits).count -eq 20) "cadence: the next window is suppressed by the snooze ($cad)" "out=$($r.Out)"
            # An expired snooze no longer suppresses: same window, snoozeUntil in the past -> nudge again.
            Set-CadenceState $cadCommits 29 ($nowMs - 1000)
            $r = Invoke-HookOutput $cadHook $payload
            Check ($r.Exit -eq 0 -and (Get-AdditionalContext $r.Out) -match '10 commit\(s\)') "cadence: an expired snooze lets the nudge fire again ($cad)" "out=$($r.Out)"

            # Day axes: one commit, ledger backdated 30 days -> review due by days AND full scan due.
            Set-CadenceState $cadDays 9 0
            $r = Invoke-HookOutput $cadHook (@{ cwd = $cadDays } | ConvertTo-Json -Compress)
            $ctx = Get-AdditionalContext $r.Out
            Check ($r.Exit -eq 0 -and $ctx -match '1 commit\(s\) and (29|30|31) day\(s\) since the last domain-skill review' -and $ctx -match '(29|30|31) day\(s\) since the last full repo-scan') "cadence: backdated ledger crosses the review-day and full-scan-day thresholds ($cad)" "out=$($r.Out)"
        }
        # (c) Both legs say the same thing for the same state.
        Check ($cadNudges['pelizzai-cadence.mjs'] -ne '' -and $cadNudges['pelizzai-cadence.mjs'] -eq $cadNudges['pelizzai-cadence.ps1']) 'cadence: both legs emit an identical nudge' "mjs=$($cadNudges['pelizzai-cadence.mjs'])"
    } finally {
        foreach ($d in @($cadCommits, $cadDays)) { if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force } }
    }

    # -- Writegate: scenario matrix across BOTH legs in a temporary git repository --
    # (Rule A: protected branch + product write; Rule B: ratified kickoff; source mode: Rule B skipped).
    $wgMjs = Join-Path $root '.claude/hooks/pelizzai-writegate.mjs'
    $wgPs1 = Join-Path $root '.claude/hooks/pelizzai-writegate.ps1'
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
            # Metadata carve-out: harness metadata under pelizzai/** is ALLOWED even on a protected
            # branch (exit 0) - the system updating itself; the commit still requires a task branch.
            Check ((Invoke-Writegate $wg @{ file_path = 'pelizzai/data/state.md' } $wgTemp) -eq 0) "writegate: carve-out allows pelizzai/ metadata on a protected branch ($leaf)"
            # Outside the repo root it allows (exit 0), even on a protected branch.
            Check ((Invoke-Writegate $wg @{ file_path = $wgOutside } $wgTemp) -eq 0) "writegate allows a write outside the root ($leaf)"

            # -- Bash matcher: false positives fixed (2026-07-21 restoration) --
            # Positive control first: a REAL redirect into the root still blocks. Without it,
            # the checks below would pass with a matcher that had turned into a no-op.
            Check ((Invoke-Writegate $wg @{ command = 'npm test > build.log' } $wgTemp) -eq 2) "writegate blocks a real redirect into the root ($leaf)"
            # Null sinks DISCARD output - they are not product writes. `> NUL` used to resolve as
            # a relative path inside the root and blocked a legitimate command.
            Check ((Invoke-Writegate $wg @{ command = 'node x.js > NUL' } $wgTemp) -eq 0) "writegate: the NUL null sink is not a product write ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'node x.js 2> $null' } $wgTemp) -eq 0) "writegate: the `$null null sink is not a product write ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'node x.js > /dev/null' } $wgTemp) -eq 0) "writegate: the /dev/null null sink is not a product write ($leaf)"
            # A target carrying an environment variable is EXPANDED before comparing against the
            # root: the file is born outside the repository, so it is not product.
            Check ((Invoke-Writegate $wg @{ command = 'npm test > $env:TEMP/build.log' } $wgTemp) -eq 0) "writegate expands `$env:VAR before deciding ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'npm test > %TEMP%\build.log' } $wgTemp) -eq 0) "writegate expands %VAR% before deciding ($leaf)"
            # Unresolvable variable -> undecidable target -> fail open (the same honesty as the matcher).
            Check ((Invoke-Writegate $wg @{ command = 'npm test > $env:PELIZZAI_NAO_EXISTE_XYZ/f.log' } $wgTemp) -eq 0) "writegate does not block a target with an unresolvable variable ($leaf)"
            # Non-regression: `>` inside quotes is text, not a redirect.
            Check ((Invoke-Writegate $wg @{ command = 'git commit -m "a > b"' } $wgTemp) -eq 0) "writegate does not mistake quoted text for a redirect ($leaf)"

            # -- Quote-aware SEGMENTATION (issue #74): a `|` inside quotes is text, not a pipe. --
            # The raw split broke `sed -i 's|a|b|' pelizzai/...` mid-expression, elected a wrong
            # target, and blocked the very carve-out the hook's message promises. Matrix from the
            # issue: A must pass, B stays passing, C/D stay blocking, E (real pipe) stays passing.
            Check ((Invoke-Writegate $wg @{ command = "sed -i -e 's|^- phase: exec|- phase: done|' pelizzai/data/state.md" } $wgTemp) -eq 0) "writegate: sed with pipe delimiter targeting pelizzai/ is allowed on a protected branch ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = "sed -i -e 's#^- phase: exec#- phase: done#' pelizzai/data/state.md" } $wgTemp) -eq 0) "writegate: sed with hash delimiter targeting pelizzai/ is allowed on a protected branch ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = "sed -i -e 's|seed|x|' seed.txt" } $wgTemp) -eq 2) "writegate: sed with pipe delimiter targeting product still blocks ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = "sed -i -e 's#seed#x#' seed.txt" } $wgTemp) -eq 2) "writegate: sed with hash delimiter targeting product still blocks ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'grep x seed.txt | tee pelizzai/data/state.md' } $wgTemp) -eq 0) "writegate: a real pipe into tee targeting pelizzai/ stays allowed ($leaf)"
            # Same hole beyond sed: any literal `|` in quotes (grep alternation, awk -F'|').
            Check ((Invoke-Writegate $wg @{ command = "grep 'a|b' seed.txt > pelizzai/data/x" } $wgTemp) -eq 0) "writegate: quoted pipe in grep does not corrupt a pelizzai/ redirect target ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = "grep 'a|b' seed.txt > produto.txt" } $wgTemp) -eq 2) "writegate: quoted pipe in grep does not hide a product redirect ($leaf)"
            # FULL separator x quote matrix (CodeRabbit PR #82 r1+r2): every separator the
            # splitter recognizes (&&, ||, ;, |, LF, CRLF), quoted with BOTH quote forms,
            # must neither corrupt a pelizzai/ target (false positive) nor hide a product
            # redirect (false negative).
            foreach ($wgQuote in @("'", '"')) {
                $wgQuoteName = if ($wgQuote -eq "'") { 'single-quoted' } else { 'double-quoted' }
                foreach ($wgSep in @('&&', '||', ';', '|', "`n", "`r`n")) {
                    $wgSepName = switch ($wgSep) { "`n" { 'newline' } "`r`n" { 'crlf' } default { $wgSep } }
                    Check ((Invoke-Writegate $wg @{ command = "echo ${wgQuote}a${wgSep}b${wgQuote} > pelizzai/data/x" } $wgTemp) -eq 0) "writegate: $wgQuoteName '$wgSepName' does not corrupt a pelizzai/ redirect target ($leaf)"
                    Check ((Invoke-Writegate $wg @{ command = "echo ${wgQuote}a${wgSep}b${wgQuote} > produto.txt" } $wgTemp) -eq 2) "writegate: $wgQuoteName '$wgSepName' does not hide a product redirect ($leaf)"
                }
            }
            # Escapes (CodeRabbit PR #82 r3): \" must not close a double-quoted string, so the
            # quoted ; stays text and the REAL redirect after the closing quote is still seen.
            Check ((Invoke-Writegate $wg @{ command = 'printf "a\";b" > produto.txt' } $wgTemp) -eq 2) "writegate: escaped double quote does not hide a product redirect ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'printf "a\";b" > pelizzai/data/x' } $wgTemp) -eq 0) "writegate: escaped double quote does not corrupt a pelizzai/ redirect target ($leaf)"
            # Single quotes are POSIX-literal: backslash does not escape and the quote closes.
            Check ((Invoke-Writegate $wg @{ command = "grep 'a\' seed.txt > produto.txt" } $wgTemp) -eq 2) "writegate: backslash inside single quotes stays literal, product redirect still seen ($leaf)"
            # Line continuation: backslash-newline joins the physical lines into one segment.
            Check ((Invoke-Writegate $wg @{ command = "npm test \`n > produto.txt" } $wgTemp) -eq 2) "writegate: a line continuation does not hide a product redirect ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = "npm test \`n > pelizzai/data/x" } $wgTemp) -eq 0) "writegate: a line continuation keeps a pelizzai/ target allowed ($leaf)"
            # Windows-path guard: a backslash before an ordinary character is a path separator,
            # never an escape - the quoted-and-redirected path must still resolve as spelled.
            Check ((Invoke-Writegate $wg @{ command = 'echo x > "sub\produto.txt"' } $wgTemp) -eq 2) "writegate: backslash path separators survive escape handling ($leaf)"
            # Escaped space (CodeRabbit PR #82 r4): `> pelizzai\ x` writes the PRODUCT file
            # "pelizzai x" at the root - the target must not be cut at the space and then
            # collapse into the pelizzai/ carve-out.
            Check ((Invoke-Writegate $wg @{ command = 'printf x > pelizzai\ x' } $wgTemp) -eq 2) "writegate: escaped space cannot smuggle product into the pelizzai/ carve-out ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'printf x > pelizzai/data/my\ notes.md' } $wgTemp) -eq 0) "writegate: escaped space inside a real pelizzai/ path stays allowed ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = "printf x > pelizzai\`tx" } $wgTemp) -eq 2) "writegate: escaped tab cannot smuggle product into the pelizzai/ carve-out ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = "printf x > pelizzai/data/my\`tnotes.md" } $wgTemp) -eq 0) "writegate: escaped tab inside a real pelizzai/ path stays allowed ($leaf)"
            # Escaped operators (CodeRabbit PR #82 r5): \> is a literal argument, never a
            # redirect; \; and \| stay literal too - and the tee behind a literal pipe still
            # elects its own target, so the conservative block on product is preserved.
            Check ((Invoke-Writegate $wg @{ command = 'echo \> produto.txt' } $wgTemp) -eq 0) "writegate: escaped > is text, not a redirect ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'printf x \| tee produto.txt' } $wgTemp) -eq 2) "writegate: tee behind a literal pipe still blocks the product target ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'echo a\;b > pelizzai/data/x' } $wgTemp) -eq 0) "writegate: escaped semicolon does not corrupt a pelizzai/ redirect target ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'echo a\;b > produto.txt' } $wgTemp) -eq 2) "writegate: escaped semicolon does not hide a product redirect ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'echo a\&\&b > pelizzai/data/x' } $wgTemp) -eq 0) "writegate: escaped ampersands do not corrupt a pelizzai/ redirect target ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'echo a\&\&b > produto.txt' } $wgTemp) -eq 2) "writegate: escaped ampersands do not hide a product redirect ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'echo \" > pelizzai/data/x' } $wgTemp) -eq 0) "writegate: escaped double quote outside quotes keeps a pelizzai/ redirect allowed ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'echo \" > produto.txt' } $wgTemp) -eq 2) "writegate: escaped double quote outside quotes does not hide a product redirect ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = "echo \' > pelizzai/data/x" } $wgTemp) -eq 0) "writegate: escaped single quote outside quotes keeps a pelizzai/ redirect allowed ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = "echo \' > produto.txt" } $wgTemp) -eq 2) "writegate: escaped single quote outside quotes does not hide a product redirect ($leaf)"
            # Command substitution (CodeRabbit PR #82 r6): bash RUNS $() and backticks even
            # inside double quotes - a redirect hidden there is a real write.
            Check ((Invoke-Writegate $wg @{ command = 'echo "$(printf x > produto.txt)"' } $wgTemp) -eq 2) "writegate: a redirect inside a quoted \$() cannot hide a product write ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'echo "$(printf x > pelizzai/data/x)"' } $wgTemp) -eq 0) "writegate: a redirect inside a quoted \$() targeting pelizzai/ stays allowed ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'echo `printf x > produto.txt`' } $wgTemp) -eq 2) "writegate: a redirect inside backticks still blocks the product target ($leaf)"
            Check ((Invoke-Writegate $wg @{ command = 'echo ''$(printf x > produto.txt)''' } $wgTemp) -eq 0) "writegate: single quotes keep a \$() literal - no substitution, no write ($leaf)"
            # Backslash semantics are per-OS (r6): a path separator on Windows, a literal
            # filename character on POSIX - `pelizzai\x` is metadata there vs. product here.
            if ($env:OS -eq 'Windows_NT' -or $IsWindows) {
                Check ((Invoke-Writegate $wg @{ command = 'printf x > pelizzai\x' } $wgTemp) -eq 0) "writegate: backslash is a path separator on Windows, pelizzai\x is metadata ($leaf)"
            } else {
                Check ((Invoke-Writegate $wg @{ command = 'printf x > pelizzai\x' } $wgTemp) -eq 2) "writegate: backslash is literal on POSIX, pelizzai\x is a product filename ($leaf)"
            }
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
        # DANGLING link: Test-Path follows links, so pelizzai/dangling -> ghost.ts (target not
        # on disk) used to look "nonexistent", classify as metadata, and let the write CREATE
        # product through it. The walk must resolve the link itself.
        $wgDangling = Join-Path $wgTemp 'pelizzai/dangling'
        if ($env:OS -eq 'Windows_NT' -or $IsWindows) {
            try { $null = New-Item -ItemType SymbolicLink -Path $wgDangling -Target (Join-Path $wgTemp 'ghost.ts') -ErrorAction Stop } catch {}
        } else {
            & sh -c 'ln -s "$0" "$1"' (Join-Path $wgTemp 'ghost.ts') $wgDangling 2>$null
        }
        $wgDanglingOk = if ($env:OS -eq 'Windows_NT' -or $IsWindows) { [bool](Get-Item -LiteralPath $wgDangling -Force -ErrorAction SilentlyContinue) } else { (& sh -c 'test -L "$0"' $wgDangling 2>$null); $LASTEXITCODE -eq 0 }
        if ($wgDanglingOk) {
            foreach ($wg in @($wgMjs, $wgPs1)) {
                $leaf = Split-Path -Leaf $wg
                Check -Condition ((Invoke-Writegate $wg @{ file_path = 'pelizzai/dangling' } $wgTemp) -eq 2) -Name "writegate: a dangling link under pelizzai/ aiming at product still classifies as product ($leaf)"
            }
        } elseif ($onCI -and -not ($env:OS -eq 'Windows_NT' -or $IsWindows)) {
            Check -Condition $false -Name 'writegate: POSIX CI must be able to create the dangling symlink for the regression'
        } else {
            Write-Host 'SKIP: this environment cannot create dangling links; the regression runs where it can.'
        }

        # Remove the reparse points/links ONLY - a recursive delete through a link follows it.
        foreach ($lnk in @($wgLink, $wgAlias, $wgDangling)) {
            if (Test-Path -LiteralPath $lnk) {
                if ($env:OS -eq 'Windows_NT' -or $IsWindows) { Remove-Item -LiteralPath $lnk -Force -ErrorAction SilentlyContinue }
                else { & sh -c 'rm -- "$0"' $lnk 2>$null }
            }
        }
        Remove-Item -LiteralPath (Join-Path $wgTemp 'pelizzai') -Recurse -Force -ErrorAction SilentlyContinue

        git -C $wgTemp checkout -q -b feat/x  # task branch (not protected)

        # -- Rule B, missing-state.md matrix (2026-08-26 hardening) --
        # No harness footprint at all: still fail-open (an off-label install - e.g. the hook
        # registered in global settings - must never lock an unrelated repo out).
        foreach ($wg in @($wgMjs, $wgPs1)) {
            $leaf = Split-Path -Leaf $wg
            Check ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 0) "writegate: no state.md and no harness footprint fails open ($leaf)"
        }
        # A regular FILE named `pelizzai` is NOT a footprint - an unrelated repo carrying one
        # must keep the fail-open, or Rule B would hard-block a project that never opted in.
        Set-Content -LiteralPath (Join-Path $wgTemp 'pelizzai') -Value 'not a harness' -Encoding utf8
        foreach ($wg in @($wgMjs, $wgPs1)) {
            $leaf = Split-Path -Leaf $wg
            Check -Condition ((Invoke-Writegate $wg @{ file_path = 'src/app.ts' } $wgTemp) -eq 0) -Name "writegate: a regular file named pelizzai is not a harness footprint ($leaf)"
        }
        Remove-Item -LiteralPath (Join-Path $wgTemp 'pelizzai') -Force

        # A harness footprint (here: the pelizzai/ dir) with NO state.md means the kickoff gate
        # never ran - the product write BLOCKS instead of warning. This is the gap the trigger
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
        # approval fields at `pending` no longer blocks - the kickoff alone is what allows it.
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
        # source mode (regression of manual-copy distribution) - Rule B still holds.
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

    # -- Guardrails: they only classify strings; no Git command is executed. --
    $hooks = @(
        (Join-Path $root '.claude/hooks/pelizzai-guardrails.mjs'),
        (Join-Path $root '.claude/hooks/pelizzai-guardrails.ps1')
    )
    $safe = @('git status', 'Git push --force-with-lease origin topic', 'git restore --staged .', 'git restore -S file.txt', 'git branch -d merged', 'git branch -m old new')
    # Outside the hook's NARROW scope - these pass ON PURPOSE. The hook targets the handful of
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
    # SAME destruction already blocked, written another way - allowing them would leave a trivial
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

    # -- Real consumer export: Cursor adapter included; sentinel and contract suite excluded. --
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
        $exportSkills = Compare-Trees $skillRoot (Join-Path $exportTemp '.claude/skills')
        Check $exportSkills.Ok 'export carries the core skills byte-for-byte' $exportSkills.Detail
        Check (Test-Path (Join-Path $exportTemp '.claude/hooks/pelizzai-writegate.mjs')) 'export carries the hooks (without registering them)'
        Check (Test-Path (Join-Path $exportTemp 'AGENTS.md')) 'export generates AGENTS.md in the consumer'
        Check (Test-Path (Join-Path $exportTemp 'GEMINI.md')) 'export generates GEMINI.md in the consumer'
        $exportClaude = Get-Content -LiteralPath (Join-Path $exportTemp 'CLAUDE.md') -Raw -Encoding utf8
        Check ($exportClaude -match 'This repository consumes PelizzAI') 'consumer CLAUDE.md is the bridge, not the source repo version'
        # The exported consumer passes its own sync check: the export is a valid installation.
        Push-Location $exportTemp
        try { Run-Native { node scripts/sync-harness.mjs --check } 'exported consumer passes sync --check' } finally { Pop-Location }
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

    # -- dist/: install by copy - committed in the source repo, no sentinel, skills in sync. --
    # The real build runs first: the checks below validate the FRESH result of the regeneration
    # (idempotent over the committed dist), not just the content that was already in the repo.
    Run-Native { node scripts/sync-harness.mjs --build-dist } 'real build-dist completes without error'
    Check (Test-Path (Join-Path $root 'dist/.cursor/rules/pelizzai.mdc')) 'dist contains the Cursor adapter'
    Check (Test-Path (Join-Path $root 'dist/AGENTS.md')) 'dist contains the generated AGENTS.md'
    Check (-not (Test-Path (Join-Path $root 'dist/scripts/pelizzai-source-repo.txt'))) 'dist does not contain the source-mode sentinel'
    Check (-not (Test-Path (Join-Path $root 'dist/scripts/test-harness-contracts.ps1'))) 'dist does not contain the contract suite'
    $distClaudePath = Join-Path $root 'dist/CLAUDE.md'
    Check (Test-Path $distClaudePath) 'dist contains CLAUDE.md'
    if (Test-Path $distClaudePath) {
        $distClaude = Get-Content -LiteralPath $distClaudePath -Raw -Encoding utf8
        Check ($distClaude -match 'This repository consumes PelizzAI') 'dist CLAUDE.md is the consumer bridge'
    }
    $distSkills = Compare-Trees $skillRoot (Join-Path $root 'dist/.claude/skills')
    Check $distSkills.Ok 'dist/.claude/skills mirrors the source (same paths and hashes)' $distSkills.Detail
    # A committed dist that the regeneration just rewrote differently is a dist out of sync.
    $distDrift = @(git -C $root status --porcelain -- dist)
    Check ($distDrift.Count -eq 0) 'committed dist/ is byte-identical to a fresh build' ($distDrift -join '; ')

    # -- Hook installer: idempotent merge and surgical removal. --
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

        # 2026-07-21 restoration: a hook is OPT-IN, one at a time and with confirmation - never
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

    # -- Handoff/review helpers, in an isolated temporary repo. --
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

Write-Host "`nResult: $passes PASS; $($failures.Count) FAIL."
if ($failures.Count -gt 0) {
    foreach ($failure in $failures) { Write-Host " - $failure" }
    exit 1
}
exit 0
