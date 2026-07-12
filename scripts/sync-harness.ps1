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

.PARAMETER ExportConsumer
  Caminho de um projeto CONSUMIDOR. Instala/atualiza o harness la: copia as skills CORE
  (somente as do manifesto), os hooks pelizzai-* e os scripts uteis (manifesto, sync,
  contratos); gera o CLAUDE.md consumidor (ponte consumidora + diretrizes do fonte) e
  regenera/valida os espelhos do destino. NUNCA copia a sentinela
  scripts/pelizzai-source-repo.txt (e a REMOVE do destino se veio de copia manual).
  Skills de dominio, runtime pelizzai/ e settings do destino nao sao tocados.
  So roda no repo-fonte (sentinela presente). E o caminho OFICIAL de distribuicao —
  copia manual do repositorio inteiro levaria a sentinela junto e promoveria o
  consumidor a repo-fonte por engano.

.EXAMPLE
  pwsh scripts/sync-harness.ps1                   # regenera .agents, AGENTS.md, GEMINI.md
  pwsh scripts/sync-harness.ps1 -Check            # valida apenas
  pwsh scripts/sync-harness.ps1 -Check -SourceMode # valida o contrato do repo-fonte
  pwsh scripts/sync-harness.ps1 -UpdateManifest   # atualiza o manifesto de core (so no repo-fonte)
  pwsh scripts/sync-harness.ps1 -ExportConsumer C:\projetos\meu-app  # distribui ao consumidor
#>
param([switch]$Check, [switch]$UpdateManifest, [switch]$SourceMode, [string]$ExportConsumer)

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
# pelizzai-cadence, pelizzai-guardrails, pelizzai-session-start e pelizzai-writegate sao HOOKS (.claude/hooks/).
$refIgnore = @('pelizzai-cadence', 'pelizzai-core-skills', 'pelizzai-guardrails', 'pelizzai-session-start', 'pelizzai-writegate', 'pelizzai-source-repo')

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

**Gate de ratificacao (inegociavel):** decisoes estruturais — isolamento, modo de execucao (com `team` sempre visivel) e estrategia de commit — sao apresentadas como recomendacao e ratificadas pelo usuario num unico gate por borda (kickoff ou setup pos-plano), nunca aplicadas em silencio; `squash-final` so a pedido explicito. A politica ratificada vive em `pelizzai/profile.md` e reaparece como recap de uma linha; push/PR/publicacao sao confirmados por tarefa.

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

# Distribuicao oficial para um projeto consumidor. Ver .PARAMETER ExportConsumer.
function Export-Consumer([string]$dst) {
    $sentinel = Join-Path $root 'scripts\pelizzai-source-repo.txt'
    if (-not (Test-Path $sentinel)) {
        throw '-ExportConsumer so roda no repo-fonte do PelizzAI (sentinela scripts/pelizzai-source-repo.txt ausente).'
    }
    if (-not (Test-Path $dst)) { throw "Destino nao existe: $dst" }
    $dst = (Resolve-Path -LiteralPath $dst).Path
    if (($dst.TrimEnd('\', '/')) -ieq ($root.TrimEnd('\', '/'))) { throw 'Destino nao pode ser o proprio repo-fonte.' }

    $core = Read-CoreManifest
    if (-not $core) { throw 'Manifesto scripts/pelizzai-core-skills.txt ausente; rode -UpdateManifest primeiro.' }

    # 1) Skills CORE (somente as do manifesto): substituicao exata por skill.
    #    Skills de dominio do destino (fora do manifesto) NUNCA sao tocadas.
    $dstSkillsRoot = Join-Path $dst '.claude\skills'
    New-Item -ItemType Directory -Force $dstSkillsRoot | Out-Null
    foreach ($name in $core) {
        $s = Join-Path $srcSkills $name
        if (-not (Test-Path $s)) { throw "Skill core ausente na fonte: $name (rode -UpdateManifest)." }
        $d = Join-Path $dstSkillsRoot $name
        if (Test-Path $d) { Remove-Item -LiteralPath $d -Recurse -Force }
        Copy-Item -LiteralPath $s -Destination $d -Recurse
    }
    $orphans = @(Get-ChildItem $dstSkillsRoot -Directory |
        Where-Object { $_.Name -like 'pelizzai-*' -and ($core -notcontains $_.Name) }).Name
    if ($orphans.Count -gt 0) {
        Write-Host "AVISO: skill(s) pelizzai-* no destino fora do core atual (avalie remover manualmente): $($orphans -join ', ')"
    }

    # 2) Hooks (pares .mjs/.ps1). O registro em settings continua opt-in — settings intocado.
    $dstHooks = Join-Path $dst '.claude\hooks'
    New-Item -ItemType Directory -Force $dstHooks | Out-Null
    Get-ChildItem (Join-Path $root '.claude\hooks') -File -Filter 'pelizzai-*' |
        ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $dstHooks $_.Name) -Force }

    # 3) Scripts uteis no consumidor: manifesto (o router separa core de dominio por ele) e o
    #    proprio sync (regenera espelhos do consumidor quando skills mudam). A suite de contratos
    #    (test-harness-contracts.ps1) e do REPO-FONTE e nao vai junto — no consumidor ela geraria
    #    FAILs falsos. A SENTINELA NUNCA vai junto (e sai, se veio de copia manual).
    $dstScripts = Join-Path $dst 'scripts'
    New-Item -ItemType Directory -Force $dstScripts | Out-Null
    foreach ($f in @('pelizzai-core-skills.txt', 'sync-harness.ps1')) {
        Copy-Item -LiteralPath (Join-Path $root "scripts\$f") -Destination (Join-Path $dstScripts $f) -Force
    }
    $dstSentinel = Join-Path $dstScripts 'pelizzai-source-repo.txt'
    if (Test-Path $dstSentinel) {
        Remove-Item -LiteralPath $dstSentinel -Force
        Write-Host 'AVISO: sentinela de repo-fonte encontrada no consumidor (copia manual anterior) — removida.'
    }

    # 4) CLAUDE.md consumidor: ponte consumidora + diretrizes do fonte (a partir do marcador).
    $marker = '## Diretrizes comportamentais'
    $srcClaude = Get-Content $claudeMd -Raw -Encoding utf8
    $idx = $srcClaude.IndexOf($marker)
    if ($idx -lt 0) { throw "CLAUDE.md do fonte sem a secao '$marker'." }
    $bridge = @'
# CLAUDE.md

## Harness PelizzAI (entrada obrigatória)

Este repositório **consome** o harness PelizzAI (instalado/atualizado via `sync-harness.ps1 -ExportConsumer`). Para pedidos que inspecionem ou alterem o projeto, entre por `pelizzai-core` → `pelizzai-router`; perguntas conceituais sem contexto de projeto podem ser respondidas diretamente. O router escolhe uma head skill e overlays por sinais observáveis — não por uma regra probabilística. Em processo (efeito, isolamento, review, validação e fechamento), siga os contratos canônicos das skills. Ao anunciar, use a grafia **"PelizzAI"**.

Este é um projeto CONSUMIDOR — não há a sentinela `scripts/pelizzai-source-repo.txt` (critério
único de source mode). Bootstrap, skills de domínio e o runtime `pelizzai/` (state/specs/plans/
profile) seguem o lifecycle consumidor das skills. O manifesto `scripts/pelizzai-core-skills.txt`
separa as skills core do harness das skills de domínio deste projeto; as skills de domínio são
do projeto — a atualização do harness nunca as sobrescreve.

'@
    $consumer = $bridge + $srcClaude.Substring($idx)
    Set-Content -LiteralPath (Join-Path $dst 'CLAUDE.md') -Value $consumer -Encoding utf8 -NoNewline

    # 5) Regenera espelhos/entry points DO DESTINO (inclui as skills de dominio de la) e valida.
    #    Processo pwsh separado: o script filho usa exit e nao pode derrubar este.
    & pwsh -NoProfile -File (Join-Path $dstScripts 'sync-harness.ps1')
    if ($LASTEXITCODE -ne 0) { throw "Sync no destino falhou: $dst" }
    & pwsh -NoProfile -File (Join-Path $dstScripts 'sync-harness.ps1') -Check
    if ($LASTEXITCODE -ne 0) { throw "Check no destino falhou: $dst" }

    Write-Host "Export consumidor concluido: $dst ($($core.Count) skills core copiadas; skills de dominio e pelizzai/ preservados; sentinela ausente no destino)."
}

if ($ExportConsumer) {
    if ($Check -or $UpdateManifest -or $SourceMode) { throw '-ExportConsumer nao combina com -Check/-UpdateManifest/-SourceMode.' }
    Export-Consumer $ExportConsumer
    exit 0
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
