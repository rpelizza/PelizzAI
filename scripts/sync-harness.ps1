#!/usr/bin/env pwsh
#Requires -Version 7.0
# (PowerShell 7+ obrigatorio: sob Windows PowerShell 5.1 o encoding default ANSI
#  corrompe os arquivos UTF-8 — causa de mojibake "â€”" nos arquivos gerados.)
<#
.SYNOPSIS
  Regenera os alvos de distribuicao do harness PelizzAI a partir das fontes de verdade.

.DESCRIPTION
  Fontes de verdade (edite AQUI):
    - .claude/skills/   (as skills do harness)
    - CLAUDE.md         (as diretrizes + a ponte para o harness)
  Gerados (NAO edite a mao — sao sobrescritos):
    - .agents/skills/   (espelho 1:1 de .claude/skills; caminho interoperavel lido
                         nativamente por Codex, Gemini CLI (alias), Warp e demais
                         ferramentas que honram o padrao Agent Skills)
    - AGENTS.md         (CLAUDE.md + secao do harness; lido por Codex, Copilot e a
                         maioria dos agentes)
    - GEMINI.md         (copia de AGENTS.md; arquivo de contexto do Gemini CLI)

  Adaptador do Cursor (.cursor/rules/pelizzai.mdc) e mantido a mao: ele so aponta para
  os entrypoints e para AGENTS.md, nao lista skills, entao nao sofre drift e nao e gerado.

.PARAMETER Check
  Valida que os alvos estao em sincronia, sem escrever. Sai com codigo 1 em divergencia
  (para uso em pre-commit / CI).

.PARAMETER UpdateManifest
  Regenera o manifesto de core-skills (scripts/pelizzai-core-skills.txt) a partir de
  .claude/skills. Rode isso APENAS no repo-fonte do PelizzAI quando as skills do harness
  mudarem. Um sync normal nunca reescreve o manifesto, para que as skills de dominio de um
  projeto consumidor jamais poluam a lista de core.

.PARAMETER SourceMode
  Torna a validacao do manifesto estrita para este repo-fonte: o conjunto do manifesto
  deve ser exatamente igual ao conjunto de diretorios em .claude/skills. Use com -Check.

.EXAMPLE
  pwsh scripts/sync-harness.ps1                   # regenera .agents, AGENTS.md, GEMINI.md
  pwsh scripts/sync-harness.ps1 -Check            # valida apenas
  pwsh scripts/sync-harness.ps1 -Check -SourceMode # valida o contrato do repo-fonte
  pwsh scripts/sync-harness.ps1 -UpdateManifest   # atualiza o manifesto de core (so no repo-fonte)
#>
param([switch]$Check, [switch]$UpdateManifest, [switch]$SourceMode)

$ErrorActionPreference = 'Stop'
$root         = Split-Path -Parent $PSScriptRoot
$srcSkills    = Join-Path $root '.claude\skills'
$dstSkills    = Join-Path $root '.agents\skills'
$claudeMd     = Join-Path $root 'CLAUDE.md'
$agentsMd     = Join-Path $root 'AGENTS.md'
$geminiMd     = Join-Path $root 'GEMINI.md'
$coreManifest = Join-Path $root 'scripts\pelizzai-core-skills.txt'

if ($SourceMode -and -not $Check) {
    throw '-SourceMode so e valido junto de -Check.'
}

# Tokens `pelizzai-*` que NAO sao skills (nao devem contar como referencia quebrada).
# pelizzai-cadence, pelizzai-guardrails e pelizzai-session-start sao HOOKS (.claude/hooks/).
$refIgnore = @('pelizzai-cadence', 'pelizzai-core-skills', 'pelizzai-guardrails', 'pelizzai-session-start')

function Build-AgentsMd {
    $skills = (Get-ChildItem $srcSkills -Directory | Sort-Object Name).Name
    $header = @'
<!-- GERADO por scripts/sync-harness.ps1 a partir de CLAUDE.md — NAO edite a mao. -->
<!-- Para mudar as diretrizes, edite CLAUDE.md e rode: pwsh scripts/sync-harness.ps1 -->

'@
    $body = (Get-Content $claudeMd -Raw -Encoding utf8).TrimEnd()
    $harnessTpl = @'


---

## Harness de skills (PelizzAI)

Este projeto usa o harness de skills **PelizzAI**. As skills (instrucoes de processo) vivem em `.agents/skills/<nome>/SKILL.md` — um espelho de `.claude/skills/` (a fonte de verdade). Leia e siga a skill relevante ANTES de agir.

**Entrada:** comece por `pelizzai-core` e `pelizzai-router`. O router classifica `effect`, risco, incerteza e superficies afetadas; escolhe exatamente uma head skill e adiciona overlays transversais quando necessarios. Operacoes somente leitura nao inicializam estado nem alteram o projeto. Antes da primeira escrita, o first-write gate confirma isolamento e branch. No repo-fonte PelizzAI, use plano/execution record nativo e nao crie runtime `pelizzai/`; em consumidor, state/specs/planos seguem o lifecycle.

**Grafia da marca:** ao anunciar uma skill, use sempre "PelizzAI" (P, A e I maiusculos). Identificadores (`pelizzai-*`) e o diretorio de estado `pelizzai/` ficam em minusculas.

**Protecao de branch (inegociavel):** nunca commite em `main`/`master`/`develop`/`dev` (nem em HEAD destacado). Antes de qualquer commit, rode `git branch --show-current`; se protegida, isole via `pelizzai-starting-branch`.

**Fundamentacao:** para fatos externos instaveis, use a ferramenta de documentacao oficial disponivel na plataforma; nao trate memoria como fonte atual.

Skills disponiveis ({{COUNT}}): {{SKILLS}}.
'@
    $harness = $harnessTpl.Replace('{{COUNT}}', [string]$skills.Count).Replace('{{SKILLS}}', ($skills -join ', '))
    # Set-Content -NoNewline (modo de geracao) nao adiciona terminador; emitimos a
    # newline final aqui para conformidade Markdown (MD047 single-trailing-newline).
    # CRLF casa com o working-tree; o git normaliza para LF no blob (autocrlf).
    return ($header + $body + $harness + "`r`n")
}

function Get-TreeDiffCount($a, $b) {
    if (-not (Test-Path $b)) { return (Get-ChildItem -Recurse -File $a).Count }
    $diff = 0
    foreach ($f in Get-ChildItem -Recurse -File $a) {
        $rel = $f.FullName.Substring($a.Length)
        $bf = Join-Path $b $rel.TrimStart('\')
        if (-not (Test-Path $bf) -or (Get-FileHash $f.FullName).Hash -ne (Get-FileHash $bf).Hash) { $diff++ }
    }
    # arquivos que so existem no destino (sobras)
    foreach ($f in Get-ChildItem -Recurse -File $b) {
        $rel = $f.FullName.Substring($b.Length)
        $af = Join-Path $a $rel.TrimStart('\')
        if (-not (Test-Path $af)) { $diff++ }
    }
    return $diff
}

function Build-CoreManifest {
    $skills = (Get-ChildItem $srcSkills -Directory | Sort-Object Name).Name
    $header = @'
# skills core do PelizzAI — GERADO por `scripts/sync-harness.ps1 -UpdateManifest`.
# Sao as skills que acompanham o harness. O pelizzai-router usa esta lista para
# distinguir skills de core das skills de dominio/stack do proprio projeto
# (dominio presente = diretorios de skill - esta lista de core).
# Regenere APENAS no repo-fonte do PelizzAI (-UpdateManifest) quando o core mudar.
'@
    return ($header + "`n" + ($skills -join "`n") + "`n")
}

function Read-CoreManifest {
    if (-not (Test-Path $coreManifest)) { return $null }
    return @(Get-Content $coreManifest |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and ($_ -notmatch '^#') })
}

function Test-Refs {
    $dirs = (Get-ChildItem $srcSkills -Directory).Name
    $refs = Select-String -Path "$srcSkills\*\*.md", "$srcSkills\*\*\*.md", $claudeMd -Pattern 'pelizzai-[a-z][a-z0-9-]*' -AllMatches |
        ForEach-Object { $_.Matches } | ForEach-Object { $_.Value } | Sort-Object -Unique
    $broken = @($refs | Where-Object { ($dirs -notcontains $_) -and ($refIgnore -notcontains $_) })
    return [pscustomobject]@{ BrokenRefs = $broken }
}

if ($Check) {
    $problems = 0
    $diff = Get-TreeDiffCount $srcSkills $dstSkills
    if ($diff -gt 0) { Write-Host "FAIL: .agents/skills fora de sincronia ($diff arquivo(s)). Rode: pwsh scripts/sync-harness.ps1"; $problems++ }

    $expected = Build-AgentsMd
    $currentAgents = if (Test-Path $agentsMd) { (Get-Content $agentsMd -Raw -Encoding utf8) } else { '' }
    # Comparacao EXATA (sem TrimEnd): pega tambem regressao da newline final (MD047) e
    # trailing whitespace. $current e $expected derivam do mesmo working-tree (mesmo EOL),
    # entao um arquivo em sincronia bate byte a byte — sem falso-positivo de CRLF/LF.
    if ($currentAgents -ne $expected) { Write-Host "FAIL: AGENTS.md fora de sincronia com CLAUDE.md. Rode: pwsh scripts/sync-harness.ps1"; $problems++ }
    $currentGemini = if (Test-Path $geminiMd) { (Get-Content $geminiMd -Raw -Encoding utf8) } else { '' }
    if ($currentGemini -ne $expected) { Write-Host "FAIL: GEMINI.md fora de sincronia com CLAUDE.md. Rode: pwsh scripts/sync-harness.ps1"; $problems++ }

    $r = Test-Refs
    if ($r.BrokenRefs.Count -gt 0) { Write-Host "FAIL: referencias pelizzai-* quebradas: $($r.BrokenRefs -join ', ')"; $problems++ }

    $core = Read-CoreManifest
    if ($null -eq $core) {
        Write-Host "FAIL: scripts/pelizzai-core-skills.txt ausente. Rode: pwsh scripts/sync-harness.ps1 -UpdateManifest (no repo-fonte do PelizzAI)."; $problems++
    } else {
        $dirs = @((Get-ChildItem $srcSkills -Directory | Sort-Object Name).Name)
        $dangling = @($core | Where-Object { $dirs -notcontains $_ })
        if ($dangling.Count -gt 0) { Write-Host "FAIL: manifesto lista skill(s) inexistente(s): $($dangling -join ', '). Rode: -UpdateManifest"; $problems++ }
        $domain = @($dirs | Where-Object { $core -notcontains $_ })
        $duplicates = @($core | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
        if ($duplicates.Count -gt 0) { Write-Host "FAIL: manifesto contem duplicata(s): $($duplicates -join ', '). Rode: -UpdateManifest"; $problems++ }
        if ($SourceMode -and $domain.Count -gt 0) {
            Write-Host "FAIL: repo-fonte tem skill(s) ausente(s) do manifesto: $($domain -join ', '). Rode: pwsh scripts/sync-harness.ps1 -UpdateManifest"
            $problems++
        } elseif ($domain.Count -gt 0) {
            Write-Host "INFO: $($domain.Count) skill(s) de dominio presente(s) (nao core): $($domain -join ', ')"
        }
    }

    if ($problems -eq 0) {
        $mode = if ($SourceMode) { 'repo-fonte' } else { 'consumidor' }
        Write-Host "OK: harness em sincronia (.agents, AGENTS.md, GEMINI.md, refs, manifesto; modo $mode)."
        exit 0
    }
    exit 1
}

# --- Modo geracao ---
if (Test-Path $dstSkills) { Remove-Item $dstSkills -Recurse -Force }
$dstParent = Split-Path -Parent $dstSkills
if (-not (Test-Path $dstParent)) { New-Item -ItemType Directory -Force $dstParent | Out-Null }
Copy-Item $srcSkills $dstSkills -Recurse

$agentsContent = Build-AgentsMd
$agentsContent | Set-Content -Path $agentsMd -Encoding utf8 -NoNewline
$agentsContent | Set-Content -Path $geminiMd -Encoding utf8 -NoNewline

# Manifesto de core: reescrito APENAS com -UpdateManifest (repo-fonte), para que as skills
# de dominio de um projeto consumidor nunca vazem para a lista de core num sync normal.
if ($UpdateManifest) {
    Build-CoreManifest | Set-Content -Path $coreManifest -Encoding utf8 -NoNewline
    Write-Host "Manifesto de core atualizado ($((Read-CoreManifest).Count) skills de core)."
} elseif (-not (Test-Path $coreManifest)) {
    Write-Host 'NOTA: scripts/pelizzai-core-skills.txt ausente — rode com -UpdateManifest (repo-fonte) para cria-lo.'
}

$diff = Get-TreeDiffCount $srcSkills $dstSkills
$r = Test-Refs
$skillCount = (Get-ChildItem $srcSkills -Directory).Count
Write-Host ".agents/skills espelhado (divergencias: $diff)."
Write-Host "AGENTS.md e GEMINI.md gerados ($skillCount skills)."
Write-Host "referencias pelizzai-* quebradas: $($r.BrokenRefs.Count)"
$core = Read-CoreManifest
if ($core) {
    $domain = @((Get-ChildItem $srcSkills -Directory).Name | Where-Object { $core -notcontains $_ })
    if ($domain.Count -gt 0) { Write-Host "skills de dominio presentes (nao core): $($domain -join ', ')" }
}
if ($diff -ne 0 -or $r.BrokenRefs.Count -ne 0) { Write-Host 'ATENCAO: verifique os problemas acima.'; exit 1 }
Write-Host 'Sync concluido com sucesso.'
