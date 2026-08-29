#!/usr/bin/env pwsh
# PelizzAI - writegate hook (PreToolUse), PowerShell variant. OPT-IN.
# Fail-CLOSED on the invariant, fail-OPEN on error. Requires PowerShell 7+ (pwsh).
#
# Equivalent to pelizzai-writegate.mjs (identical behavior), for fleets without Node.
# Safety net that moves the TWO irreversible autonomies of the redesign from model
# obedience to executable enforcement: writing product without isolation and writing code
# before the gate is ratified. It does NOT decide the route - it hands control back to the
# human gate. Mirrors the spirit and safety envelope of pelizzai-guardrails.ps1.
#
# Fires BEFORE the write, on two sibling matchers that share this same file:
#  - Write | Edit | MultiEdit | NotebookEdit  -> reads tool_input.file_path / .notebook_path;
#  - Bash                                     -> detects write redirection in
#    tool_input.command (>, >>, &>, tee, sed -i, Set-Content/Add-Content/Out-File) to
#    paths INSIDE the project root. Same rule on both sides. Null sinks (NUL, $null,
#    /dev/null) and targets that resolve OUTSIDE the root (incl. $env:TEMP, %TEMP%,
#    absolutes) are never product writes and never block.
#
# RULE A (invariant, both modes) - isolation before the first write:
#   writing a PRODUCT path (outside pelizzai/) inside the root while on a protected branch
#   (main/master/develop/dev, plus origin/HEAD's default) or on a detached HEAD -> BLOCKS.
#   CARVE-OUT: metadata writes in pelizzai/** are allowed even here (the system updating itself;
#   it is file writes only - the commit still follows the task-branch flow).
#
# RULE B (consumer only: pelizzai/ exists and this is NOT the source repo) - no code before the gate:
#   writing a PRODUCT path (outside pelizzai/) while pelizzai/data/state.md does NOT
#   contain "kickoff: ratified" -> BLOCKS. Writes in pelizzai/ are always allowed
#   (they are the artifacts that record the gate itself).
#   DELIBERATE SCOPE: the hook locks ONE marker - the kickoff. The greenfield stages
#   (discovery -> spec -> stress -> approval -> plan -> stress -> approval) remain
#   mandatory, but they live in the skills, NOT in runtime enforcement: turning them into
#   a file turnstile locked out legitimate work whenever the state fell one step behind
#   the conversation. Doctrine in the skills; in the hook, only the invariant.
#   In SOURCE MODE (PelizzAI source repo: sentinel pelizzai-source-repo.txt) Rule B is
#   SKIPPED - there the marker lives in the native execution record.
#
# Block: exit 2 + reason and safe path on stderr. Errors in the hook ITSELF and cases it
# cannot decide safely: exit 0 (fail-open - a bug or false positive never locks the user
# out). A missing state.md is NOT such a case when the repo carries the harness (pelizzai/
# or the pelizzai-core skill): there the gate never ran and the write BLOCKS - ratifying
# the gate writes the marker and creates the file. Only a repo with no harness footprint
# at all fails open, warning at most once per window.
#
# Install (opt-in, recommended by pelizzai-onboard at bootstrap, merged without overwriting
# existing hooks/permissions), in .claude/settings.json - BOTH matchers are required:
#   { "hooks": { "PreToolUse": [
#       { "matcher": "Write|Edit|MultiEdit|NotebookEdit", "hooks": [
#           { "type": "command",
#             "command": "pwsh -NoProfile -File \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-writegate.ps1\"" } ] },
#       { "matcher": "Bash", "hooks": [
#           { "type": "command",
#             "command": "pwsh -NoProfile -File \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-writegate.ps1\"" } ] } ] } }
#
# Manual test (in a PowerShell shell):
#   '{"tool_input":{"file_path":"src/app.ts"},"cwd":"/path/to/repo"}' | pwsh -NoProfile -File pelizzai-writegate.ps1; echo $LASTEXITCODE
#   -> on a protected branch or without "kickoff: ratified": reason on stderr and exit 2;
#      otherwise (task branch with the kickoff ratified, or outside the repo): exit 0.
#
# The user can disable the hook in .claude/settings.json - it is never an inescapable block.

$ErrorActionPreference = 'SilentlyContinue'

# Default protected branches (Rule A). origin/HEAD enriches the list at runtime.
$PROTECTED = @('main', 'master', 'develop', 'dev')
# Machine-readable markers for the sequential gates in state.md (kickoff/post-plan ratified
# by the user: content + isolation + mode + commit). Writegate and resumption depend on it.
# Also accepts "ratificado": legacy pt-BR states written before the English harness.
$KICKOFF_RATIFIED = 'kickoff:\s*rati(fied|ficado)'
# DEDICATED sentinel of the PelizzAI source repo (source mode): when present, Rule B is skipped.
# Single unambiguous criterion: the manifest and sync-harness also exist in consumers
# installed via -ExportConsumer and do NOT indicate source mode.
$SOURCE_SENTINELS = @('scripts/pelizzai-source-repo.txt')
# "Could not decide" fail-open: warns at most once per window (per repo) to avoid spam.
$script:WARN_SNOOZE_MS = 86400000L  # 24h
# Windows and macOS compare paths case-insensitively; Linux is case-sensitive.
$script:CI = $IsWindows -or $IsMacOS

# git with the stdin cwd; '' on ANY failure (git missing, outside a repo, nonexistent ref).
function Invoke-Git([string]$Cwd, [string[]]$GitArgs) {
  try {
    $out = & git -C $Cwd @GitArgs 2>$null
    if ($LASTEXITCODE -ne 0) { return '' }
    return ($out | Out-String).Trim()
  } catch { return '' }
}

# Forward slashes and no trailing slash, for prefix comparison robust to \ and /.
function Get-Norm([string]$p) {
  return (($p -replace '\\', '/') -replace '/+$', '')
}

# child is the root itself or is INSIDE it (case per the OS).
function Test-Inside([string]$child, [string]$root) {
  $c = Get-Norm $child
  $r = Get-Norm $root
  if ($script:CI) { $c = $c.ToLowerInvariant(); $r = $r.ToLowerInvariant() }
  return ($c -eq $r) -or $c.StartsWith($r + '/')
}

# Closes the current token: redirection target (ignores fd dup >&N) or regular token
# (drops a stray fd prefix, the "2" in "2>"). Mutations via [ref] (by-reference parameter).
function Flush-Token([ref]$Cur, $Tokens, $Redirects, [ref]$Expect) {
  if ($Cur.Value -eq '') { return }
  if ($Expect.Value) {
    if (-not $Cur.Value.StartsWith('&')) { [void]$Redirects.Add($Cur.Value) }
    $Expect.Value = $false
  } elseif (-not [regex]::IsMatch($Cur.Value, '^[0-9]+$|^&$')) {
    [void]$Tokens.Add($Cur.Value)
  }
  $Cur.Value = ''
}

# Parser for ONE shell segment, quote-aware: splits tokens and redirection TARGETS.
# Quote-aware so it does not mistake a '>' inside a string (e.g. git commit -m "a > b")
# for a real redirection.
function Get-ParsedSegment([string]$seg) {
  $tokens = [System.Collections.Generic.List[string]]::new()
  $redirects = [System.Collections.Generic.List[string]]::new()
  $cur = ''
  $quote = $null
  $expectTarget = $false
  for ($i = 0; $i -lt $seg.Length; $i++) {
    $ch = $seg.Substring($i, 1)
    if ($null -ne $quote) {
      if ($ch -eq $quote) { $quote = $null } else { $cur += $ch }
      continue
    }
    if ($ch -eq '"' -or $ch -eq "'") { $quote = $ch; continue }
    if ($ch -eq '>') {
      Flush-Token ([ref]$cur) $tokens $redirects ([ref]$expectTarget)
      if (($i + 1) -lt $seg.Length -and $seg.Substring($i + 1, 1) -eq '>') { $i++ } # '>>'
      $expectTarget = $true
      continue
    }
    if ($ch -eq ' ' -or $ch -eq "`t") {
      Flush-Token ([ref]$cur) $tokens $redirects ([ref]$expectTarget)
      continue
    }
    $cur += $ch
  }
  Flush-Token ([ref]$cur) $tokens $redirects ([ref]$expectTarget)
  return @{ Tokens = $tokens; Redirects = $redirects }
}

# Sinks that are NOT repository files: the null devices of Windows (NUL, NUL:), of
# PowerShell ($null) and of POSIX (/dev/null and the rest of /dev/). Redirecting to them
# DISCARDS output, it does not write product - `node x.js > NUL` used to resolve to a
# relative path inside the root and block wrongly.
$NULL_SINKS = @('nul', 'nul:', '$null', 'con', 'con:', '/dev/null')
function Test-NullSink([string]$target) {
  $t = ((([string]$target).Trim()) -replace '\\', '/').ToLowerInvariant()
  return ($NULL_SINKS -contains $t) -or $t.StartsWith('/dev/')
}

# Expands environment variable references in the target: $env:NAME (PowerShell), %NAME% (cmd),
# ${NAME} and $NAME (POSIX). Without this, `> $env:TEMP/build.log` was read as a RELATIVE path
# inside the root and blocked - when the file is not even born in the repository.
# A reference that does not resolve -> undecidable target -> returns $null and the hook does
# not block (fail-open, the same honesty as the rest of the matcher: what cannot be parsed
# safely does not become an invariant). The expanded value is not re-expanded (no infinite loop).
function Expand-ShellVars([string]$target) {
  $patterns = @(
    '\$env:([A-Za-z_][A-Za-z0-9_]*)',
    '%([A-Za-z_][A-Za-z0-9_]*)%',
    '\$\{([A-Za-z_][A-Za-z0-9_]*)\}',
    '\$([A-Za-z_][A-Za-z0-9_]*)'
  )
  $out = $target
  foreach ($pattern in $patterns) {
    $rx = [regex]::new($pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $startAt = 0
    while ($startAt -le $out.Length) {
      $m = $rx.Match($out, $startAt)
      if (-not $m.Success) { break }
      $value = [System.Environment]::GetEnvironmentVariable($m.Groups[1].Value)
      if ([string]::IsNullOrEmpty($value)) { return $null }
      $out = $out.Substring(0, $m.Index) + $value + $out.Substring($m.Index + $m.Length)
      $startAt = $m.Index + $value.Length
    }
  }
  return $out
}

# Splits a command into segments at &&, ||, ;, | and newlines - ONLY when the separator
# sits OUTSIDE quotes (same quote model as Get-ParsedSegment: plain '/" toggling). The raw
# regex split was quote-blind: `sed -i 's|a|b|' pelizzai/...` broke mid-expression, the
# wrong "last operand" became the target and the hook blocked the very pelizzai/ carve-out
# its message promises (issue #74) - while `grep 'a|b' x > product` hid a REAL product
# redirect inside the mangled quote and failed open. Quote chars stay in the output;
# Get-ParsedSegment strips them.
function Split-ShellSegments([string]$command) {
  $segments = [System.Collections.Generic.List[string]]::new()
  $cur = ''
  $quote = $null
  for ($i = 0; $i -lt $command.Length; $i++) {
    $ch = $command.Substring($i, 1)
    if ($null -ne $quote) {
      if ($ch -eq $quote) { $quote = $null }
      $cur += $ch
      continue
    }
    if ($ch -eq '"' -or $ch -eq "'") { $quote = $ch; $cur += $ch; continue }
    if ($ch -eq '&' -and ($i + 1) -lt $command.Length -and $command.Substring($i + 1, 1) -eq '&') {
      [void]$segments.Add($cur); $cur = ''; $i++
      continue
    }
    if ($ch -eq '|') {
      if (($i + 1) -lt $command.Length -and $command.Substring($i + 1, 1) -eq '|') { $i++ }
      [void]$segments.Add($cur); $cur = ''
      continue
    }
    if ($ch -eq ';' -or $ch -eq "`n") {
      [void]$segments.Add($cur); $cur = ''
      continue
    }
    if ($ch -eq "`r" -and ($i + 1) -lt $command.Length -and $command.Substring($i + 1, 1) -eq "`n") {
      [void]$segments.Add($cur); $cur = ''; $i++
      continue
    }
    $cur += $ch
  }
  [void]$segments.Add($cur)
  return @($segments)
}

# Write targets of a shell command (Bash sibling matcher). Best-effort and honest:
# covers the common cases; what it cannot parse safely does not block.
function Get-ShellTargets([string]$command) {
  $targets = [System.Collections.Generic.List[string]]::new()
  foreach ($seg in (Split-ShellSegments $command)) {
    $parsed = Get-ParsedSegment $seg
    $tokens = $parsed.Tokens
    foreach ($r in $parsed.Redirects) { [void]$targets.Add($r) }
    for ($i = 0; $i -lt $tokens.Count; $i++) {
      $t = $tokens[$i].ToLowerInvariant()
      # tee [-flags] file...  /  Tee-Object -FilePath file
      if ($t -eq 'tee' -or $t -eq 'tee-object') {
        for ($j = $i + 1; $j -lt $tokens.Count; $j++) {
          $a = $tokens[$j]
          if ([regex]::IsMatch($a, '^-(?:literal)?(?:file)?path$', 'IgnoreCase') -and ($j + 1) -lt $tokens.Count) {
            [void]$targets.Add($tokens[$j + 1]); $j++; continue
          }
          if (-not $a.StartsWith('-')) { [void]$targets.Add($a) }
        }
      }
      # Set-Content / Add-Content / Out-File: -Path/-LiteralPath or first positional.
      if ($t -eq 'set-content' -or $t -eq 'add-content' -or $t -eq 'out-file') {
        $took = $false
        for ($j = $i + 1; ($j -lt $tokens.Count) -and (-not $took); $j++) {
          $a = $tokens[$j]
          if ([regex]::IsMatch($a, '^-(?:literal)?(?:file)?path$', 'IgnoreCase') -and ($j + 1) -lt $tokens.Count) {
            [void]$targets.Add($tokens[$j + 1]); $took = $true
          } elseif (-not $a.StartsWith('-')) {
            [void]$targets.Add($a); $took = $true
          }
        }
      }
      # sed -i / --in-place <file> (last non-flag operand of the segment).
      if ($t -eq 'sed') {
        $inPlace = $false
        for ($k = $i + 1; $k -lt $tokens.Count; $k++) {
          $x = $tokens[$k]
          if ([regex]::IsMatch($x, '^-i(?:\..*)?$') -or ($x -eq '--in-place') -or [regex]::IsMatch($x, '^-[a-z]*i[a-z]*$', 'IgnoreCase')) { $inPlace = $true; break }
        }
        if ($inPlace) {
          for ($j = $tokens.Count - 1; $j -gt $i; $j--) {
            if (-not $tokens[$j].StartsWith('-')) { [void]$targets.Add($tokens[$j]); break }
          }
        }
      }
    }
  }
  # Drops flags, null sinks, and targets with an unresolvable variable; expands the rest so
  # that the comparison against the repo root sees the REAL path, not the shell literal.
  $clean = [System.Collections.Generic.List[string]]::new()
  foreach ($t in $targets) {
    if (-not $t) { continue }
    if ($t.StartsWith('-')) { continue }
    if (Test-NullSink $t) { continue }
    $expanded = Expand-ShellVars $t
    if (-not $expanded) { continue }
    if (Test-NullSink $expanded) { continue }
    [void]$clean.Add($expanded)
  }
  return @($clean)
}

# Blocks: reason + safe path on stderr and exit 2.
function Invoke-Block([string]$reason) {
  [Console]::Error.WriteLine("PelizzAI writegate: write redirected - $reason")
  [Console]::Error.WriteLine('(Opt-in fail-closed isolation/kickoff hook. If the write is legitimate outside the flow, isolate via pelizzai-isolate, ratify the gate, or disable the hook in .claude/settings.json.)')
  exit 2
}

# Best-effort warning, at most once per window and per repo - never affects the exit code.
function Invoke-WarnOnce([string]$gitRoot, [string]$message) {
  try {
    $key = ((Get-Norm $gitRoot).ToLowerInvariant() -replace '[^a-z0-9]', '_')
    if ($key.Length -gt 60) { $key = $key.Substring($key.Length - 60) }
    $statePath = Join-Path ([System.IO.Path]::GetTempPath()) "pelizzai-writegate-$key.json"
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $warnUntil = 0L
    if (Test-Path -LiteralPath $statePath) {
      try { $warnUntil = [long]((Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json).warnUntil) } catch {}
    }
    if ($now -lt $warnUntil) { return }
    [Console]::Error.WriteLine("PelizzAI writegate (warning): $message")
    try { (@{ warnUntil = ($now + $script:WARN_SNOOZE_MS) } | ConvertTo-Json -Compress) | Set-Content -LiteralPath $statePath -Encoding utf8 } catch {}
  } catch {}
}

try {
  $raw = [Console]::In.ReadToEnd()
  if (-not $raw) { exit 0 }
  $data = $null
  try { $data = $raw | ConvertFrom-Json } catch { exit 0 } # unreadable payload -> no lock-up

  $cwd = (Get-Location).Path
  if (($data.cwd -is [string]) -and $data.cwd) { $cwd = $data.cwd }
  $ti = $data.tool_input

  # Targets: file_path (Write/Edit/MultiEdit), notebook_path (NotebookEdit), shell (Bash).
  $targets = [System.Collections.Generic.List[string]]::new()
  if (($ti.file_path -is [string]) -and $ti.file_path) { [void]$targets.Add($ti.file_path) }
  if (($ti.notebook_path -is [string]) -and $ti.notebook_path) { [void]$targets.Add($ti.notebook_path) }
  if (($ti.command -is [string]) -and $ti.command) { foreach ($x in (Get-ShellTargets $ti.command)) { [void]$targets.Add($x) } }
  if ($targets.Count -eq 0) { exit 0 } # nothing to guard (e.g. read-only Bash)

  $gitRoot = Invoke-Git $cwd @('rev-parse', '--show-toplevel')
  if (-not $gitRoot) { exit 0 } # outside a git repo (scratchpad/external) or git missing -> allow
  # macOS pitfall the CI caught: the temp tree lives behind a symlink (/var -> /private/var), so
  # git reports the PHYSICAL root while the payload's cwd - and every relative target joined to
  # it - stays LOGICAL. All in-root writes then looked outside the root and the hook failed OPEN.
  # Canonicalize via `pwd -P` on POSIX (Windows has no such split and stays untouched); anything
  # that cannot be resolved keeps its raw spelling (fail-open, as everywhere else in this file).
  # Physical resolution with `..` applied AFTER the link resolution, never before: a lexical
  # normalize collapses `pelizzai/link/../src` to `pelizzai/src` (metadata, allowed) while the OS
  # resolves `link` first and lands the write on real product OUTSIDE pelizzai/ - a clean bypass
  # of Rules A and B through the carve-out. Each component resolves against the PHYSICAL prefix
  # built so far ($IsWindows is absent on Windows PowerShell 5.1 - the env check covers it);
  # anything unresolvable keeps its raw spelling - fail-open, as everywhere else in this file.
  function Get-PhysicalPath([string]$p, [int]$Depth = 0) {
    if (-not $p) { return $p }
    try {
      $isWin = ($env:OS -eq 'Windows_NT' -or $IsWindows)
      $qualifier = [System.IO.Path]::GetPathRoot($p)
      if (-not $qualifier) { return $p } # relative input never reaches here; the caller joins cwd first
      $rest = @($p.Substring($qualifier.Length) -split '[\\/]' | Where-Object { $_ -and $_ -ne '.' })
      $cur = $qualifier
      foreach ($seg in $rest) {
        if ($seg -eq '..') {
          $parent = Split-Path -Parent $cur
          if ($parent) { $cur = $parent }
          continue
        }
        $next = Join-Path $cur $seg
        if (-not (Test-Path -LiteralPath $next)) {
          # Test-Path FOLLOWS links, so a DANGLING link looks "not on disk" — yet a write through
          # it lands on the target. See the link itself and resolve its target physically.
          $linkTarget = $null
          if ($Depth -lt 8) {
            if ($isWin) {
              $li = Get-Item -LiteralPath $next -Force -ErrorAction SilentlyContinue
              if ($li -and $li.LinkType -and $li.Target) { $linkTarget = [string]($li.Target | Select-Object -First 1) }
            } else {
              & sh -c 'test -L "$0"' $next 2>$null
              if ($LASTEXITCODE -eq 0) {
                $t = & sh -c 'readlink -- "$0"' $next 2>$null
                if ($LASTEXITCODE -eq 0 -and $t) { $linkTarget = ([string]($t | Select-Object -Last 1)).Trim() }
              }
            }
          }
          if ($linkTarget) {
            if (-not [System.IO.Path]::IsPathRooted($linkTarget)) { $linkTarget = Join-Path $cur $linkTarget }
            $cur = Get-PhysicalPath $linkTarget ($Depth + 1)
          } else {
            $cur = $next # genuinely not on disk yet
          }
          continue
        }
        if ($isWin) {
          $item = Get-Item -LiteralPath $next -Force -ErrorAction SilentlyContinue
          while ($item -and $item.LinkType) {
            $t = $item.ResolveLinkTarget($true) # .NET 6+; a miss falls to the catch below
            if (-not $t) { break }
            $item = $t
          }
          $cur = if ($item) { $item.FullName } else { $next }
        } elseif (Test-Path -LiteralPath $next -PathType Container) {
          $out = & sh -c 'cd -P -- "$0" && pwd -P' $next 2>$null
          $cur = if ($LASTEXITCODE -eq 0 -and $out) { ([string]($out | Select-Object -Last 1)).Trim() } else { $next }
        } else {
          # POSIX file component: resolve a symlink CHAIN with plain readlink (readlink -f is not
          # portable to older macOS), physicalizing each hop's parent via cd -P. Without this,
          # `pelizzai/alias -> src/app.ts` stayed spelled as metadata while the OS writes product
          # - the file-symlink twin of the ..-after-link bypass. A plain file walks zero hops.
          # ONE line on purpose: this .ps1 checks out with CRLF, and a multi-line sh script would
          # carry a \r into every dash token and silently fall back to the logical path.
          $out = & sh -c 'p="$0"; i=0; while [ -L "$p" ] && [ "$i" -lt 40 ]; do t=$(readlink -- "$p") || break; case "$t" in /*) p="$t";; *) p="$(dirname -- "$p")/$t";; esac; d=$(cd -P -- "$(dirname -- "$p")" 2>/dev/null && pwd -P) || break; p="$d/$(basename -- "$p")"; i=$((i+1)); done; printf "%s\n" "$p"' $next 2>$null
          $cur = if ($LASTEXITCODE -eq 0 -and $out) { ([string]($out | Select-Object -Last 1)).Trim() } else { $next }
        }
      }
      return $cur
    } catch { return $p }
  }
  $gitRoot = Get-PhysicalPath $gitRoot
  $cwd = Get-PhysicalPath $cwd # physical cwd, so relative targets land on the same spelling as gitRoot

  # Only targets INSIDE the root matter; scratchpad/temp outside the root never blocks.
  $inRoot = [System.Collections.Generic.List[string]]::new()
  foreach ($t in $targets) {
    # No GetFullPath here: it would collapse `..` lexically BEFORE the link walk - the exact
    # bypass Get-PhysicalPath exists to close. The walk owns the whole normalization.
    $abs = if ([System.IO.Path]::IsPathRooted($t)) { $t } else { Join-Path $cwd $t }
    $abs = Get-PhysicalPath $abs
    if (Test-Inside $abs $gitRoot) { [void]$inRoot.Add($abs) }
  }
  if ($inRoot.Count -eq 0) { exit 0 }

  # Harness metadata (pelizzai/**) vs. PRODUCT (outside pelizzai/). Both Rule A's carve-out
  # and Rule B rest on this separation.
  $pelizzaiDir = Join-Path $gitRoot 'pelizzai'
  $products = @($inRoot | Where-Object { -not (Test-Inside $_ $pelizzaiDir) })

  # -- Rule A (both modes): protected/detached branch blocks in-root PRODUCT writes.
  # METADATA CARVE-OUT: writing inside pelizzai/** is ALLOWED even on a protected branch or a
  # detached HEAD - it is harness metadata (state/plan/spec/reports), the system updating itself,
  # never product. This unblocks state reconciliation on the very protected branch the dev returns
  # to after the PR merge. SECURITY NOTE: the carve-out is for FILE writes ONLY and opens no
  # product or commit loophole - product (outside pelizzai/) stays blocked by this same Rule A;
  # the metadata is only COMMITTED in the first commit of the new task branch (the flow never
  # requires a commit on a protected branch); and pelizzai-guardrails keeps blocking destructive
  # git. LIMIT (symlink): the classification is by PHYSICAL path - Get-PhysicalPath follows
  # directory links component-by-component and applies `..` on the RESOLVED parent, so both
  # `pelizzai/../src` and `pelizzai/link/../src` (link -> product) correctly count as product.
  # Residual limit: a link created BETWEEN this check and the write (TOCTOU) is not seen; the
  # compensating controls remain - pelizzai-guardrails blocks destructive git and human review
  # sees the real target.
  $branch = Invoke-Git $cwd @('branch', '--show-current') # '' = detached HEAD (or no branch)
  $isProtected = ($branch -eq '') -or ($PROTECTED -contains $branch)
  if (-not $isProtected) {
    # Enrichment via the remote's default; on failure, degrades to the static list
    # (NOT to fail-open - Rule A must stay armed without origin/HEAD).
    $originHead = Invoke-Git $cwd @('symbolic-ref', '--short', 'refs/remotes/origin/HEAD')
    if ($originHead) {
      $tail = ($originHead -split '/')[-1]
      if ($tail -and ($tail -eq $branch)) { $isProtected = $true }
    }
  }
  if ($isProtected -and $products.Count -gt 0) {
    $b = if ($branch) { $branch } else { 'detached HEAD' }
    Invoke-Block "protected/detached branch ($b). Isolate via pelizzai-isolate before writing product - isolation before the first write is an invariant (metadata writes in pelizzai/ are allowed even here)."
  }

  # Source mode (PelizzAI source repo): the marker lives in the execution record -> Rule B skipped.
  $sourceMode = $true
  foreach ($rel in $SOURCE_SENTINELS) {
    if (-not (Test-Path -LiteralPath (Join-Path $gitRoot $rel))) { $sourceMode = $false; break }
  }
  if ($sourceMode) { exit 0 }

  # -- Rule B (consumer only): a PRODUCT write requires a ratified kickoff in state.md.
  if ($products.Count -eq 0) { exit 0 } # only setup artifacts in pelizzai/ -> allowed

  $statePath = Join-Path $gitRoot 'pelizzai/data/state.md'
  if (-not (Test-Path -LiteralPath $statePath)) {
    # HARNESS EVIDENCE (2026-08-26 hardening): a missing state.md used to fail-open for every
    # consumer, making Rule B unenforceable in the exact window it exists for - a consumer that
    # carries the harness but whose kickoff gate never ran. The head skills write the marker
    # BEFORE the first product write and writing pelizzai/data/state.md is always allowed, so
    # blocking here locks out no legitimate flow: ratifying the gate creates the file. The
    # fail-open + warn survives ONLY where it is honest - a repo with no trace of the harness.
    # DIRECTORIES only: a repo carrying a regular FILE named `pelizzai` is not a harness
    # footprint, and reading it as one would hard-block an unrelated project.
    $harnessPresent = (Test-Path -LiteralPath (Join-Path $gitRoot 'pelizzai') -PathType Container) -or
      (Test-Path -LiteralPath (Join-Path $gitRoot '.claude/skills/pelizzai-core') -PathType Container) -or
      (Test-Path -LiteralPath (Join-Path $gitRoot '.agents/skills/pelizzai-core') -PathType Container)
    if ($harnessPresent) {
      Invoke-Block 'this consumer carries the harness but pelizzai/data/state.md does not exist - the kickoff gate never ran. Run the kickoff/post-plan gate WITH the user - isolation, execution mode, and commit strategy -, record "kickoff: ratified" in pelizzai/data/state.md (writes under pelizzai/ are always allowed and create the file), and then write the product.'
    }
    # No trace of the harness in this repo: cannot decide safely -> fail-open + warn once.
    Invoke-WarnOnce $gitRoot 'no pelizzai/data/state.md and no harness footprint to check the kickoff; allowing the write. If this project uses the harness, run the kickoff gate and record "kickoff: ratified" before writing product.'
    exit 0
  }
  $state = ''
  try { $state = Get-Content -LiteralPath $statePath -Raw } catch { exit 0 } # could not read the marker -> fail-open
  if ([regex]::IsMatch($state, $KICKOFF_RATIFIED, 'IgnoreCase')) { exit 0 }

  Invoke-Block 'the kickoff has not been ratified yet ("kickoff: ratified" is missing from pelizzai/data/state.md). Run the kickoff/post-plan gate WITH the user - isolation, execution mode, and commit strategy -, record "kickoff: ratified" in pelizzai/data/state.md, and then write the code.'
} catch {
  # fail-open: an error in the hook itself never locks the user out
}
exit 0
