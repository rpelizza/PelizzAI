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
# out). No state.md in a consumer: allows and warns at most once per window.
#
# Install (opt-in, recommended by pelizzai-audit at bootstrap, merged without overwriting
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
function Flush-Token([ref]$Cur, $Tokens, $Redirects, [ref]$Expect, [bool]$DueToRedirect = $false) {
  if ($Cur.Value -eq '') { return }
  if ($Expect.Value) {
    if (-not $Cur.Value.StartsWith('&')) { [void]$Redirects.Add($Cur.Value) }
    $Expect.Value = $false
  } elseif ($DueToRedirect -and [regex]::IsMatch($Cur.Value, '^[0-9]+$|^&$')) {
    # drop the fd prefix ONLY when a '>' actually follows (the "2" in "2>"); a bare numeric
    # token elsewhere is a real argument - `nice -n 10 mv ...` must keep the 10.
  } else {
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
    # POSIX: inside DOUBLE quotes, a backslash escapes only " \ $ and `. Without this, an odd
    # number of \" before a '>' desynchronized the quote state and a '>' INSIDE the string was
    # read as a real redirection (parity with the .mjs fix).
    if ($quote -eq '"' -and $ch -eq '\' -and ($i + 1) -lt $seg.Length -and $seg.Substring($i + 1, 1) -match '^["\\$`]$') {
      $cur += $seg.Substring($i + 1, 1)
      $i++
      continue
    }
    if ($null -ne $quote) {
      if ($ch -eq $quote) { $quote = $null } else { $cur += $ch }
      continue
    }
    if ($ch -eq '"' -or $ch -eq "'") { $quote = $ch; continue }
    if ($ch -eq '>') {
      Flush-Token ([ref]$cur) $tokens $redirects ([ref]$expectTarget) $true
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

# True for POSIX absolutes (/x, \x) and Windows drive paths (C:\x, C:/x) on any host platform.
function Test-AbsoluteLike([string]$p) {
  return ($p -match '^[\\/]') -or ($p -match '^[A-Za-z]:[\\/]')
}

# Index of the segment's actual COMMAND: skips wrapper prefixes, VAR=value assignments, and
# their flags. The copy/download verbs are only recognized AT this index - `install` appearing
# as an argument (`npm install express`, `pip install requests`) is a package manager's
# subcommand, not a file write, and used to be misread as one. Parity with the .mjs.
$COMMAND_PREFIXES = @('sudo', 'doas', 'env', 'time', 'nohup', 'nice', 'command', 'exec', 'xargs')
# Prefix options that CONSUME a value argument: without this table, `sudo -u build cp ...` would
# stop the scan at `build` and miss the real command (false negative on Rules A/B). Parity .mjs.
$PREFIX_VALUE_FLAGS = @{
  sudo  = @('-u', '-g', '-p', '-h', '-U', '-R', '-T', '-C', '-D', '--user', '--group', '--host', '--prompt', '--chdir', '--chroot')
  doas  = @('-u')
  nice  = @('-n', '--adjustment')
  env   = @('-u', '-S', '-P', '-C', '--unset', '--split-string', '--chdir')
  time  = @('-f', '-o', '--format', '--output')
  xargs = @('-a', '-d', '-E', '-e', '-I', '-i', '-L', '-l', '-n', '-P', '-s')
}
function Get-CommandIndex($tokens) {
  $i = 0
  $activePrefix = $null
  while ($i -lt $tokens.Count) {
    $raw = $tokens[$i]
    $t = $raw.ToLowerInvariant()
    if ($COMMAND_PREFIXES -contains $t) { $activePrefix = $t; $i++; continue }
    if ($raw -cmatch '^[A-Za-z_][A-Za-z0-9_]*=') { $i++; continue }
    if ($i -gt 0 -and $raw.StartsWith('-')) {
      $bare = if ($raw.Contains('=')) { $raw.Substring(0, $raw.IndexOf('=')) } else { $raw }
      $valueFlags = if ($activePrefix -and $PREFIX_VALUE_FLAGS.ContainsKey($activePrefix)) { $PREFIX_VALUE_FLAGS[$activePrefix] } else { $null }
      if ($valueFlags -and ($valueFlags -ccontains $bare) -and (-not $raw.Contains('=')) -and (($i + 1) -lt $tokens.Count)) { $i += 2 }
      else { $i += 1 }
      continue
    }
    break
  }
  return $i
}

# Write targets of a shell command (Bash sibling matcher). Best-effort and honest:
# covers the common cases; what it cannot parse safely does not block. Besides redirection,
# tee, Set-Content/Add-Content/Out-File, and sed -i, it recognizes the common copy/download
# verbs (cp, mv, install, curl -o/-O, wget -O, dd of=, ln) and git apply/am — reducing, not
# closing, the Bash surface (deliberate fail-open posture; see the header).
function Get-ShellTargets([string]$command) {
  $targets = [System.Collections.Generic.List[string]]::new()
  # Segment-local `cd` tracking: in `cd .claude && printf x > ../src/a.py` the target must be
  # resolved against the directory the shell is actually in, not the initial cwd. `prefix`
  # accumulates the cd chain ('' = initial cwd); a cd that cannot be resolved safely (variable,
  # `cd -`, popd) makes later RELATIVE targets undecidable -> they are dropped (the same
  # fail-open honesty as the rest of the matcher; absolutes still count).
  $prefix = ''
  $prefixUnknown = $false
  $push = {
    param($raw)
    if (-not $raw) { return }
    if ($raw.StartsWith('-')) { return }
    if (Test-NullSink $raw) { return }
    $expanded = Expand-ShellVars $raw
    if (-not $expanded) { return }
    if (Test-NullSink $expanded) { return }
    if (Test-AbsoluteLike $expanded) { [void]$targets.Add($expanded); return }
    if ($prefixUnknown) { return }
    if ($prefix) { [void]$targets.Add([System.IO.Path]::Combine($prefix, $expanded)) }
    else { [void]$targets.Add($expanded) }
  }
  foreach ($seg in ($command -split '&&|\|\||;|\||\r?\n')) {
    $parsed = Get-ParsedSegment $seg
    $tokens = $parsed.Tokens
    foreach ($r in $parsed.Redirects) { & $push $r }
    $cmdIdx = Get-CommandIndex $tokens
    for ($i = 0; $i -lt $tokens.Count; $i++) {
      $t = $tokens[$i].ToLowerInvariant()
      # tee [-flags] file...  /  Tee-Object -FilePath file
      if ($t -eq 'tee' -or $t -eq 'tee-object') {
        for ($j = $i + 1; $j -lt $tokens.Count; $j++) {
          $a = $tokens[$j]
          if ([regex]::IsMatch($a, '^-(?:literal)?(?:file)?path$', 'IgnoreCase') -and ($j + 1) -lt $tokens.Count) {
            & $push $tokens[$j + 1]; $j++; continue
          }
          if (-not $a.StartsWith('-')) { & $push $a }
        }
      }
      # Set-Content / Add-Content / Out-File: -Path/-LiteralPath or first positional.
      if ($t -eq 'set-content' -or $t -eq 'add-content' -or $t -eq 'out-file') {
        $took = $false
        for ($j = $i + 1; ($j -lt $tokens.Count) -and (-not $took); $j++) {
          $a = $tokens[$j]
          if ([regex]::IsMatch($a, '^-(?:literal)?(?:file)?path$', 'IgnoreCase') -and ($j + 1) -lt $tokens.Count) {
            & $push $tokens[$j + 1]; $took = $true
          } elseif (-not $a.StartsWith('-')) {
            & $push $a; $took = $true
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
            if (-not $tokens[$j].StartsWith('-')) { & $push $tokens[$j]; break }
          }
        }
      }
      # cp / mv / install / ln - only as the segment's COMMAND (see Get-CommandIndex): the
      # write lands on the LAST non-flag operand (destination/link).
      if (($t -eq 'cp' -or $t -eq 'mv' -or $t -eq 'install' -or $t -eq 'ln') -and $i -eq $cmdIdx) {
        for ($j = $tokens.Count - 1; $j -gt $i; $j--) {
          if (-not $tokens[$j].StartsWith('-')) { & $push $tokens[$j]; break }
        }
      }
      # curl -o/--output <file>; -O/--remote-name writes the URL's basename into the current dir.
      if ($t -eq 'curl' -and $i -eq $cmdIdx) {
        for ($j = $i + 1; $j -lt $tokens.Count; $j++) {
          $a = $tokens[$j]
          if (($a -ceq '-o' -or $a -eq '--output') -and ($j + 1) -lt $tokens.Count) {
            & $push $tokens[$j + 1]; $j++
          } elseif ($a -ceq '-O' -or $a -eq '--remote-name') {
            $url = $null
            for ($k = $i + 1; $k -lt $tokens.Count; $k++) {
              if ([regex]::IsMatch($tokens[$k], '^[a-z][a-z0-9+.-]*://', 'IgnoreCase')) { $url = $tokens[$k]; break }
            }
            if ($url) {
              $base = (($url -split '[?#]')[0] -split '/')[-1]
              if ($base) { & $push $base }
            }
          }
        }
      }
      # wget -O <file> / --output-document=<file>
      if ($t -eq 'wget' -and $i -eq $cmdIdx) {
        for ($j = $i + 1; $j -lt $tokens.Count; $j++) {
          $a = $tokens[$j]
          if ($a -ceq '-O' -and ($j + 1) -lt $tokens.Count) {
            & $push $tokens[$j + 1]; $j++
          } elseif ($a.StartsWith('--output-document=')) {
            & $push $a.Substring('--output-document='.Length)
          }
        }
      }
      # dd of=<file>
      if ($t -eq 'dd' -and $i -eq $cmdIdx) {
        for ($j = $i + 1; $j -lt $tokens.Count; $j++) {
          if ([regex]::IsMatch($tokens[$j], '^of=', 'IgnoreCase')) { & $push $tokens[$j].Substring(3) }
        }
      }
      # git apply / git am rewrite tracked files; the patch decides which, so the conservative
      # target is the current directory itself. Dry-run/metadata forms are excluded.
      if ($t -eq 'git' -and $i -eq $cmdIdx -and ($i + 1) -lt $tokens.Count) {
        $sub = $tokens[$i + 1].ToLowerInvariant()
        if ($sub -eq 'apply' -or $sub -eq 'am') {
          $dry = $false
          for ($k = $i + 2; $k -lt $tokens.Count; $k++) {
            if ($tokens[$k] -cmatch '^--(check|stat|numstat|summary|abort|quit|show-current-patch)$') { $dry = $true; break }
          }
          if (-not $dry) { & $push '.' }
        }
      }
    }
    # `cd`-like first token updates the prefix for the NEXT segments (redirections of this very
    # segment open before the cd takes effect, so they were pushed with the previous prefix).
    $head = if ($tokens.Count) { $tokens[0].ToLowerInvariant() } else { '' }
    if ($head -in @('cd', 'chdir', 'set-location', 'pushd')) {
      $arg = if ($tokens.Count -gt 1) { $tokens[1] } else { $null }
      $expanded = if ($arg -and -not $arg.StartsWith('-')) { Expand-ShellVars $arg } else { $null }
      if (-not $expanded) {
        $prefixUnknown = $true  # `cd` alone, `cd -`, or an unresolvable variable
      } elseif (Test-AbsoluteLike $expanded) {
        $prefix = $expanded
        $prefixUnknown = $false
      } elseif (-not $prefixUnknown) {
        $prefix = if ($prefix) { [System.IO.Path]::Combine($prefix, $expanded) } else { $expanded }
      }
    } elseif ($head -eq 'popd') {
      $prefixUnknown = $true  # no directory stack tracking - undecidable from here on
    }
  }
  return @($targets)
}

# Resolves symlinks/junctions in the already-materialized part of the path (the non-existing
# tail is re-appended), segment by segment so intermediate links are seen too. Closes the
# carve-out bypass `pelizzai/link -> ../src`: the metadata-vs-product classification sees the
# REAL destination, not the lexical path. Fail-open: any error returns the lexical path.
function Resolve-RealPath([string]$p) {
  try {
    $base = $p
    $tail = [System.Collections.Generic.List[string]]::new()
    while (-not (Test-Path -LiteralPath $base)) {
      $parent = [System.IO.Path]::GetDirectoryName($base)
      if (-not $parent -or $parent -eq $base) { return $p } # nothing materialized
      $tail.Insert(0, [System.IO.Path]::GetFileName($base))
      $base = $parent
    }
    $full = [System.IO.Path]::GetFullPath($base)
    $rootPart = [System.IO.Path]::GetPathRoot($full)
    $rest = @($full.Substring($rootPart.Length) -split '[\\/]' | Where-Object { $_ })
    $resolved = $rootPart
    foreach ($seg in $rest) {
      $resolved = Join-Path $resolved $seg
      # The guard protects against link CYCLES per component, never against path depth —
      # shared across components it silently stopped resolving deep paths (.mjs parity:
      # realpathSync has no depth limit).
      $guard = 0
      while ($guard -lt 64) {
        $guard++
        $item = $null
        try { $item = Get-Item -LiteralPath $resolved -Force -ErrorAction Stop } catch { break }
        $final = $null
        try { $final = $item.ResolveLinkTarget($true) } catch {}
        if ($final) { $resolved = $final.FullName } else { break }
      }
    }
    foreach ($t in $tail) { $resolved = Join-Path $resolved $t }
    return $resolved
  } catch { return $p }
}

# Blocks: reason + safe path on stderr and exit 2.
function Invoke-Block([string]$reason) {
  [Console]::Error.WriteLine("PelizzAI writegate: write blocked - $reason")
  [Console]::Error.WriteLine('(Opt-in fail-closed isolation/kickoff hook. If the write is legitimate outside the flow, isolate via pelizzai-starting-branch, ratify the gate, or disable the hook in .claude/settings.json.)')
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

  # Only targets INSIDE the root matter; scratchpad/temp outside the root never blocks.
  # Resolve-RealPath on BOTH sides: a symlinked temp dir (macOS /tmp) compares correctly, and a
  # symlink inside the repo is classified by its real destination.
  $realRoot = Resolve-RealPath ([System.IO.Path]::GetFullPath($gitRoot))
  $inRoot = [System.Collections.Generic.List[string]]::new()
  foreach ($t in $targets) {
    $abs = if ([System.IO.Path]::IsPathRooted($t)) { $t } else { Join-Path $cwd $t }
    try { $abs = [System.IO.Path]::GetFullPath($abs) } catch { continue }
    $abs = Resolve-RealPath $abs
    if (Test-Inside $abs $realRoot) { [void]$inRoot.Add($abs) }
  }
  if ($inRoot.Count -eq 0) { exit 0 }

  # Harness metadata (pelizzai/**) vs. PRODUCT (outside pelizzai/). Both Rule A's carve-out
  # and Rule B rest on this separation.
  $pelizzaiDir = Join-Path $realRoot 'pelizzai'
  $products = @($inRoot | Where-Object { -not (Test-Inside $_ $pelizzaiDir) })

  # -- Rule A (both modes): protected/detached branch blocks in-root PRODUCT writes.
  # METADATA CARVE-OUT: writing inside pelizzai/** is ALLOWED even on a protected branch or a
  # detached HEAD - it is harness metadata (state/plan/spec/reports), the system updating itself,
  # never product. This unblocks state reconciliation on the very protected branch the dev returns
  # to after the PR merge. SECURITY NOTE: the carve-out is for FILE writes ONLY and opens no
  # product or commit loophole - product (outside pelizzai/) stays blocked by this same Rule A;
  # the metadata is only COMMITTED in the first commit of the new task branch (the flow never
  # requires a commit on a protected branch); and pelizzai-guardrails keeps blocking destructive
  # git. LIMIT (symlink): the classification resolves symlinks in the already-materialized part
  # of the path (Resolve-RealPath), so `pelizzai/link -> ../src` is read as PRODUCT, not
  # metadata. Residual limit (TOCTOU): a link created between this check and the write - e.g.
  # by the same command - is not seen; the compensating controls remain: pelizzai-guardrails
  # blocks destructive git and human review sees the real target.
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
    Invoke-Block "protected/detached branch ($b). Isolate via pelizzai-starting-branch before writing product - isolation before the first write is an invariant (metadata writes in pelizzai/ are allowed even here)."
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
    # Consumer without state.md: cannot read the kickoff safely -> fail-open + warn once.
    Invoke-WarnOnce $gitRoot 'no pelizzai/data/state.md to check the kickoff; allowing the write. If this project uses the harness, run the kickoff gate and record "kickoff: ratified" before writing product.'
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
