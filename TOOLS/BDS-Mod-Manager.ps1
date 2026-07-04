# BDS-Mod-Manager.ps1
# Tool to check existing mods, list them, determine recommended load order based on dependencies,
# and automatically reorder the world's pack JSONs.
# Forma principal de executar: via launcher or directly:
# powershell -ExecutionPolicy Bypass -File ".\TOOLS\BDS-Mod-Manager.ps1"

param(
    [ValidateSet("en","pt")]
    [string]$Lang = ""
)

$ErrorActionPreference = "Stop"

# Determine paths (script is in TOOLS)
$scriptDir = $PSScriptRoot
$root = Split-Path -Parent $scriptDir

if (-not (Test-Path (Join-Path $root "bedrock_server.exe"))) {
    Write-Host "Error: Could not find bedrock_server.exe. Run from the server root." -ForegroundColor Red
    exit 1
}

# Language selection
if (-not $Lang) {
    Clear-Host
    Write-Host "=== Escolha o idioma / Choose language ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🇺🇸  1. English"
    Write-Host "🇧🇷  2. Portugues (Brasil)"
    Write-Host ""
    $langChoice = Read-Host "Digite 1 ou 2 / Enter 1 or 2"
    if ($langChoice -eq "2") {
        $Lang = "pt"
    } else {
        $Lang = "en"
    }
}

# Get-Text for i18n (moved up for early use)
function Get-Text {
    param([string]$Key, [object[]]$FormatArgs = @())
    if ($Lang -eq "pt") {
        $base = switch ($Key) {
            "HeaderTitle" { "=== Gerenciador de Mods Bedrock ===" }
            "Server" { "Servidor: {0}" }
            "ListInstalled" { "Listar Mods Instalados" }
            "CheckOrder" { "Verificar Ordem Atual" }
            "AutoOrder" { "Auto-ordenar baseado em dependencias" }
            "ManualOrder" { "Reordenar manualmente" }
            "CheckProblems" { "Verificar Problemas" }
            "ToggleClassification" { "Alternar modo de classificacao (atual: {0})" }
            "ClassByFolder" { "Por pasta (recomendado)" }
            "ClassByManifest" { "Por manifesto (antigo)" }
            "ClassificationMode" { "Classificacao: {0}" }
            "ModeChanged" { "Modo alterado para: {0}" }
            "SelectWorld" { "=== Selecionar Mundo ===" }
            "NoWorlds" { "Nenhum mundo encontrado." }
            "InstalledPacks" { "Packs instalados (BP e RP):" }
            "RegisteredInWorld" { "Registrados no mundo:" }
            "CurrentOrder" { "Ordem atual de carregamento:" }
            "RecommendedOrder" { "Ordem recomendada:" }
            "ApplyOrder" { "Aplicar nova ordem? (s/n)" }
            "OrderApplied" { "Ordem aplicada com sucesso." }
            "NoManifest" { "Nenhum manifest.json encontrado em {0}" }
            "DepMissing" { "Dependencia faltando: {0} para {1}" }
            "CheckingWorld" { "Verificando mundo: {0}" }
            "ParseWarning" { "Aviso: Nao foi possivel analisar {0}" }
            "ForSelectedWorld" { "Para o mundo selecionado: {0}" }
            "RegBehavior" { "Behavior Registrados:" }
            "RegResource" { "Resource Registrados:" }
            "NoPacksRegistered" { "Nenhum pack registrado neste mundo." }
            "WorldLabel" { "Mundo: {0}" }
            "RegisteredButMissing" { "Registrado mas pasta ausente: {0} [{1}]" }
            "InstalledButNotRegistered" { "Instalado mas nao registrado no mundo: {0}" }
            "NoWorldSelected" { "Nenhum mundo selecionado para verificacao detalhada." }
            "TipAutoOrder" { "Dica: Use Auto-ordenar (opcao 3) para corrigir a ordem de carregamento para seus mods como AG2." }
            "NoProblemsFound" { "Nao encontrei nenhum erro na sua configuracao." }
            "ChangeClassPrompt" { "Mudar modo de classificacao? (s/n) ou Enter para continuar" }
            "Footer" { "Use setas ou numeros. Ctrl+C para sair." }
            "Back" { "0. Voltar" }
            "Choose" { "Escolha" }
            "invalidMsg" { "Opcao invalida." }
            default { $Key }
        }
    } else {
        $base = switch ($Key) {
            "HeaderTitle" { "=== Bedrock Mod Manager ===" }
            "Server" { "Server: {0}" }
            "ListInstalled" { "List Installed Mods" }
            "CheckOrder" { "View Current Order" }
            "AutoOrder" { "Auto-order based on dependencies" }
            "ManualOrder" { "Manual Reorder" }
            "CheckProblems" { "Check Problems" }
            "ToggleClassification" { "Toggle classification mode (current: {0})" }
            "ClassByFolder" { "By folder (recommended)" }
            "ClassByManifest" { "By manifest (old behavior)" }
            "ClassificationMode" { "Classification: {0}" }
            "ModeChanged" { "Mode changed to: {0}" }
            "SelectWorld" { "=== Select World ===" }
            "NoWorlds" { "No worlds found." }
            "InstalledPacks" { "Installed Packs (BP and RP):" }
            "RegisteredInWorld" { "Registered in world:" }
            "CurrentOrder" { "Current load order:" }
            "RecommendedOrder" { "Recommended order:" }
            "ApplyOrder" { "Apply new order? (y/n)" }
            "OrderApplied" { "Order applied successfully." }
            "NoManifest" { "No manifest.json found in {0}" }
            "DepMissing" { "Missing dependency: {0} for {1}" }
            "CheckingWorld" { "Checking world: {0}" }
            "ParseWarning" { "Warning: Could not parse {0}" }
            "ForSelectedWorld" { "For selected world: {0}" }
            "RegBehavior" { "Registered Behavior:" }
            "RegResource" { "Registered Resource:" }
            "NoPacksRegistered" { "No packs registered in this world." }
            "WorldLabel" { "World: {0}" }
            "RegisteredButMissing" { "Registered but folder missing: {0} [{1}]" }
            "InstalledButNotRegistered" { "Installed but not registered in world: {0}" }
            "NoWorldSelected" { "No world selected for detailed check." }
            "TipAutoOrder" { "Tip: Use Auto-order (option 3) to fix load order for your mods like AG2." }
            "NoProblemsFound" { "I didn't find any errors in your setup." }
            "ChangeClassPrompt" { "Change classification method? (s/n) or Enter to continue" }
            "Footer" { "Use arrows or numbers. Ctrl+C to exit." }
            "Back" { "0. Back" }
            "Choose" { "Choose" }
            default { $Key }
        }
    }
    if ($FormatArgs.Count -gt 0) {
        try {
            return ($base -f $FormatArgs)
        } catch {
            return $base
        }
    }
    return $base
}

function ShowHeader {
    Clear-Host
    Write-Host (Get-Text "HeaderTitle") -ForegroundColor Cyan
    Write-Host (Get-Text "Server" $root) -ForegroundColor Gray
    if ($selectedWorld) {
        Write-Host (Get-Text "WorldLabel" $selectedWorld.Name) -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
}

function ShowFooter {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host (Get-Text "Footer") -ForegroundColor DarkGray
}

function Get-Worlds {
    $worldsDir = Join-Path $root "worlds"
    if (-not (Test-Path $worldsDir)) { return @() }
    return Get-ChildItem $worldsDir -Directory
}

function Select-World {
    $worlds = Get-Worlds
    if ($worlds.Count -eq 0) {
        Write-Host (Get-Text "NoWorlds") -ForegroundColor Red
        return $null
    }
    Write-Host (Get-Text "SelectWorld") -ForegroundColor Cyan
    for ($i = 0; $i -lt $worlds.Count; $i++) {
        Write-Host "$($i+1). $($worlds[$i].Name)"
    }
    Write-Host (Get-Text "Back")
    $sel = Read-Host (Get-Text "Choose")
    if ($sel -eq "0" -or -not $sel) { return $null }
    $idx = [int]$sel - 1
    if ($idx -lt 0 -or $idx -ge $worlds.Count) { return $null }
    return $worlds[$idx]
}

# Get all installed packs by scanning folders
function GetInstalledPacks {
    $packs = @()
    $bpDir = Join-Path $root "behavior_packs"
    $rpDir = Join-Path $root "resource_packs"
    $excluded = @('vanilla*', 'chemistry*', 'editor*', 'server_*', 'experimental_*', 'pack.name*', 'resourcepack.*', 'resourcePack.*')

    foreach ($dir in @($bpDir, $rpDir)) {
        if (-not (Test-Path $dir)) { continue }
        Get-ChildItem $dir -Directory | ForEach-Object {
            $folder = $_.Name
            if ($excluded | Where-Object { $folder -like $_ }) { return }
            $packPath = $_.FullName
            $man = Get-ChildItem -LiteralPath $packPath -Recurse -Filter "manifest.json" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($man) {
                try {
                    $content = [System.IO.File]::ReadAllText($man.FullName, [System.Text.Encoding]::UTF8)
                    $data = $content | ConvertFrom-Json
                    $pname = $data.header.name
                    if ($excluded | Where-Object { $pname -like $_ }) { return }

                    $isBehaviorDir = ($dir -eq $bpDir)
                    if ($useFolderBasedClassification) {
                        # Trust the folder we found it in (correct for our install tools)
                        $type = if ($isBehaviorDir) { "behavior" } else { "resource" }
                    } else {
                        # Old behavior: guess from manifest (first module only)
                        $type = if ($data.modules -and $data.modules[0].type -eq "data") { "behavior" } else { "resource" }
                    }

                    $deps = @()
                    if ($data.dependencies) {
                        $deps = $data.dependencies | ForEach-Object { if ($_.uuid) { $_.uuid } }
                    }
                    $packs += [pscustomobject]@{
                        Name = $pname
                        Uuid = $data.header.uuid
                        Version = $data.header.version
                        Type = $type
                        Folder = $folder
                        FullPath = $packPath
                        Dependencies = $deps
                    }
                } catch {
                    # silent, don't spam for vanilla/chemistry folders
                }
            }
        }
    }
    return $packs
}

# Helper for option 4: check if a pack UUID exists on disk by looking for matching manifest.uuid
# This bypasses the name exclusion filters (e.g. "pack.name") so real packs with placeholder names
# are still considered present if the folder+UUID exists. Used only for "registered but missing" detection.
function Test-PackUuidExists($uuid) {
    if (-not $uuid) { return $false }
    $bpDir = Join-Path $root "behavior_packs"
    $rpDir = Join-Path $root "resource_packs"

    foreach ($baseDir in @($bpDir, $rpDir)) {
        if (-not (Test-Path $baseDir)) { continue }
        $folders = Get-ChildItem $baseDir -Directory
        foreach ($folder in $folders) {
            $packPath = $folder.FullName
            $man = Get-ChildItem -LiteralPath $packPath -Recurse -Filter "manifest.json" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($man) {
                try {
                    $content = [System.IO.File]::ReadAllText($man.FullName, [System.Text.Encoding]::UTF8)
                    $data = $content | ConvertFrom-Json
                    if ($data.header.uuid -eq $uuid) {
                        return $true
                    }
                } catch {
                    # ignore bad manifests
                }
            }
        }
    }
    return $false
}

# Helper to read world_*.json while tolerating old // comment lines (from previous bad writes)
# Also repairs legacy files that are missing commas between objects after stripping comments.
function Get-JsonContent($path) {
    if (-not (Test-Path $path)) { return @() }
    $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    # Strip UTF8 BOM if present
    $content = $content.TrimStart([char]0xFEFF)
    # Remove // comments (to end of line). These legacy files use them for names.
    $content = $content -replace '//[^\r\n]*', ''
    # Remove blank lines / excessive whitespace
    $lines = ($content -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    $jsonText = $lines -join "`n"
    if (-not $jsonText.Trim()) { return @() }
    # Legacy bad format (after removing //) often has no commas between } and next {. Fix it.
    $jsonText = $jsonText -replace '}\s*{', '},{'
    # Also fix possible missing commas after ] or before [ in some variants, but mainly objects
    try {
        $raw = $jsonText | ConvertFrom-Json
        if ($null -eq $raw) { return @() }
        if ($raw -isnot [array]) { $raw = @($raw) }
        return $raw
    } catch {
        Write-Host (Get-Text "ParseWarning" (Split-Path $path -Leaf)) -ForegroundColor Yellow
        return @()
    }
}

# Get registered packs for a world (from json)
function GetWorldRegisteredPacks($worldDir, $isBehavior) {
    $jsonFile = if ($isBehavior) { "world_behavior_packs.json" } else { "world_resource_packs.json" }
    $path = Join-Path $worldDir $jsonFile
    $raw = Get-JsonContent $path
    if (-not $raw) { return @() }

    return $raw | ForEach-Object {
        $uuid = $_.pack_id
        if ($uuid) {
            [pscustomobject]@{
                Uuid    = $uuid
                Version = $_.version
                Name    = if ($_.name) { $_.name } else { "Unknown" }
            }
        }
    }
}

# Write packs back to world json - clean valid JSON (no comments, matches other tools)
function WriteWorldPacks($worldDir, $isBehavior, $packs) {
    $jsonFile = if ($isBehavior) { "world_behavior_packs.json" } else { "world_resource_packs.json" }
    $path = Join-Path $worldDir $jsonFile

    $out = @()
    foreach ($p in $packs) {
        if ($p.Uuid) {
            $out += [pscustomobject]@{
                pack_id = $p.Uuid
                version = $p.Version
                name    = if ($p.Name -and $p.Name -ne "Unknown") { $p.Name } else { "" }
            }
        }
    }

    if (-not $out -or $out.Count -eq 0) {
        "[]" | Set-Content $path -Encoding UTF8
        return
    }

    $out | ConvertTo-Json -Depth 5 | Set-Content $path -Encoding UTF8
}

# Simple topo sort for load order (dependencies first)
function GetRecommendedOrder($registeredPacks, $allPacks) {
    # registeredPacks: array of {Uuid, Name, ...}
    # Build map uuid -> pack
    $packMap = @{}
    $allPacks | ForEach-Object { $packMap[$_.Uuid] = $_ }

    # Build graph: key = uuid, value = list of uuids that must load BEFORE it (deps)
    $graph = @{}
    $inDegree = @{}
    foreach ($p in $registeredPacks) {
        if ($p.Uuid) {
            $graph[$p.Uuid] = @()
            $inDegree[$p.Uuid] = 0
        }
    }

    foreach ($p in $registeredPacks) {
        if ($p.Uuid -and $packMap.ContainsKey($p.Uuid)) {
            $deps = $packMap[$p.Uuid].Dependencies
            foreach ($depUuid in $deps) {
                if ($depUuid -and $graph.ContainsKey($depUuid)) {
                    $graph[$depUuid] += $p.Uuid
                    $inDegree[$p.Uuid] += 1
                }
            }
        }
    }

    # Kahn's algorithm
    $queue = New-Object System.Collections.Queue
    $inDegree.GetEnumerator() | Where-Object { $_.Value -eq 0 } | ForEach-Object { $queue.Enqueue($_.Key) }

    $result = @()
    while ($queue.Count -gt 0) {
        $u = $queue.Dequeue()
        $result += $u
        foreach ($v in $graph[$u]) {
            $inDegree[$v] -= 1
            if ($inDegree[$v] -eq 0) {
                $queue.Enqueue($v)
            }
        }
    }

    if ($result.Count -ne $registeredPacks.Count) {
        Write-Host "Warning: Dependency cycle detected or missing deps. Using partial order." -ForegroundColor Yellow
        # Fall back to original order for missing
        $remaining = $registeredPacks | Where-Object { $_.Uuid -and ($_.Uuid -notin $result) } | ForEach-Object { $_.Uuid }
        $result += $remaining
    }

    # Map back to full objects preserving other info
    $uuidToPack = @{}
    $registeredPacks | Where-Object { $_.Uuid } | ForEach-Object { $uuidToPack[$_.Uuid] = $_ }
    return $result | ForEach-Object { $uuidToPack[$_] }
}



# Ask for world selection on first screen (before main menu)
$selectedWorld = $null
Clear-Host
$selectedWorld = Select-World
if (-not $selectedWorld) {
    # User chose Back (0) from world select -> return to launcher
    return
}

# Classification mode: by default we trust the folder (behavior_packs / resource_packs)
# because our install tools put them in the correct place.
# User can toggle to the old manifest-based guessing.
$useFolderBasedClassification = $true

# Main action loop
while ($true) {
    ShowHeader
    Write-Host "1. $(Get-Text "ListInstalled")"
    Write-Host "2. $(Get-Text "CheckOrder")"
    Write-Host "3. $(Get-Text "AutoOrder")"
    Write-Host "4. $(Get-Text "CheckProblems")"
    Write-Host (Get-Text "Back")
    ShowFooter

    $choice = Read-Host (Get-Text "Choose")

    switch ($choice) {
        "1" {
            Clear-Host
            Write-Host (Get-Text "InstalledPacks") -ForegroundColor Cyan
            $classMode = if ($useFolderBasedClassification) { Get-Text "ClassByFolder" } else { Get-Text "ClassByManifest" }
            Write-Host (Get-Text "ClassificationMode" $classMode) -ForegroundColor DarkGray
            $packs = GetInstalledPacks
            if ($packs.Count -eq 0) {
                Write-Host "No packs found." -ForegroundColor Yellow
            } else {
                $packs | Group-Object Type | ForEach-Object {
                    Write-Host "--- $($_.Name.ToUpper()) ---" -ForegroundColor Yellow
                    $_.Group | Sort-Object Name | ForEach-Object {
                        Write-Host "  $($_.Name) v$($_.Version -join '.') [$($_.Uuid)]"
                    }
                }
            }
            if ($selectedWorld) {
                Write-Host ""
                Write-Host (Get-Text "ForSelectedWorld" $selectedWorld.Name) -ForegroundColor Cyan
                $bpReg = GetWorldRegisteredPacks $selectedWorld.FullName $true
                $rpReg = GetWorldRegisteredPacks $selectedWorld.FullName $false
                Write-Host (Get-Text "RegBehavior") ($bpReg.Name -join ", ")
                Write-Host (Get-Text "RegResource") ($rpReg.Name -join ", ")
            }
            ShowFooter
            Read-Host "Press Enter to continue"
        }
        "2" {
            $world = $selectedWorld
            if (-not $world) { $world = Select-World }
            if (-not $world) { continue }
            $wName = $world.Name
            Clear-Host
            Write-Host (Get-Text "WorldLabel" $wName) -ForegroundColor Cyan
            $bpReg = GetWorldRegisteredPacks $world.FullName $true
            $rpReg = GetWorldRegisteredPacks $world.FullName $false
            Write-Host (Get-Text "RegisteredInWorld") -ForegroundColor Yellow
            Write-Host "Behavior Packs (load order top to bottom):"
            if ($bpReg.Count -eq 0) { Write-Host "  (none)" } else { $bpReg | ForEach-Object { Write-Host "  $($_.Name)" } }
            Write-Host "Resource Packs (load order top to bottom):"
            if ($rpReg.Count -eq 0) { Write-Host "  (none)" } else { $rpReg | ForEach-Object { Write-Host "  $($_.Name)" } }
            ShowFooter
            Read-Host "Press Enter to continue"
        }
        "3" {
            Clear-Host
            $world = $selectedWorld
            if (-not $world) { $world = Select-World }
            if (-not $world) { continue }
            $wName = $world.Name
            Write-Host "World: $wName" -ForegroundColor Cyan
            $allPacks = GetInstalledPacks
            $bpReg = GetWorldRegisteredPacks $world.FullName $true
            $rpReg = GetWorldRegisteredPacks $world.FullName $false

            if ($bpReg.Count -eq 0 -and $rpReg.Count -eq 0) {
                Write-Host (Get-Text "NoPacksRegistered") -ForegroundColor Yellow
                Read-Host "Press Enter"
                continue
            }

            $newBp = GetRecommendedOrder $bpReg $allPacks
            $newRp = GetRecommendedOrder $rpReg $allPacks

            Write-Host (Get-Text "RecommendedOrder") -ForegroundColor Green
            Write-Host "Behavior Packs order (first loaded first):"
            $newBp | ForEach-Object { Write-Host "  $($_.Name)" }
            Write-Host "Resource Packs order:"
            $newRp | ForEach-Object { Write-Host "  $($_.Name)" }

            $ans = Read-Host (Get-Text "ApplyOrder")
            if ($ans -match '^[sy]') {
                WriteWorldPacks $world.FullName $true $newBp
                WriteWorldPacks $world.FullName $false $newRp
                Write-Host (Get-Text "OrderApplied") -ForegroundColor Green
                Write-Host "This should help with load order issues (e.g. AG2 after base mods)." -ForegroundColor Yellow
            }
            Read-Host "Press Enter to continue"
        }
        "4" {
            $world = $selectedWorld
            if (-not $world) {
                $world = Select-World
            }
            if (-not $world) {
                Write-Host (Get-Text "NoWorldSelected")
                ShowFooter
                Read-Host "Press Enter to continue"
                continue
            }
            while ($true) {
                Clear-Host
                Write-Host (Get-Text "CheckProblems") -ForegroundColor Cyan
                Write-Host (Get-Text "CheckingWorld" $world.Name) -ForegroundColor Yellow

                $allPacks = GetInstalledPacks
                $bpReg = GetWorldRegisteredPacks $world.FullName $true
                $rpReg = GetWorldRegisteredPacks $world.FullName $false

                $foundIssues = $false

                # Registered but not installed
                # Use direct UUID lookup (Test-PackUuidExists) so packs with placeholder names like "pack.name"
                # are still detected if the folder actually exists with matching UUID.
                # This avoids false "missing" reports for working mods.
                ($bpReg + $rpReg) | Where-Object { $_.Uuid } | ForEach-Object {
                    if (-not (Test-PackUuidExists $_.Uuid)) {
                        Write-Host (Get-Text "RegisteredButMissing" @($_.Name, $_.Uuid)) -ForegroundColor Yellow
                        $foundIssues = $true
                    }
                }

                # Installed custom but not registered in this world (still uses filtered list to avoid vanilla spam)
                $regUuids = ($bpReg + $rpReg) | Where-Object { $_.Uuid } | ForEach-Object { $_.Uuid }
                $allPacks | Where-Object { $_.Uuid -and ($_.Uuid -notin $regUuids) } | ForEach-Object {
                    if ($_.Folder -notmatch '^(vanilla|chemistry|editor|server_|experimental)') {
                        Write-Host (Get-Text "InstalledButNotRegistered" $_.Name) -ForegroundColor Yellow
                        $foundIssues = $true
                    }
                }

                if (-not $foundIssues) {
                    Write-Host (Get-Text "NoProblemsFound") -ForegroundColor Green
                }

                Write-Host (Get-Text "TipAutoOrder")

                # Classification method toggle is now inside the Check Problems section
                Write-Host ""
                $classMode = if ($useFolderBasedClassification) { Get-Text "ClassByFolder" } else { Get-Text "ClassByManifest" }
                Write-Host (Get-Text "ClassificationMode" $classMode) -ForegroundColor DarkGray
                $resp = Read-Host (Get-Text "ChangeClassPrompt")
                if ($resp -match '^[sy]') {
                    $useFolderBasedClassification = -not $useFolderBasedClassification
                    # re-run the check with the new mode
                    continue
                } else {
                    ShowFooter
                    Read-Host "Press Enter to continue"
                    break
                }
            }
        }
        "0" {
            return
        }
        default {
            Write-Host (Get-Text "invalidMsg") -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
