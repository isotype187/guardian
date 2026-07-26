# Nexus98 Scribe Core - Observation Engine
# Part of Nexus98 External Scribe Framework
# Version: 1.0.0

# System State Observer
function Get-Nexus98SystemState {
    param(
        [hashtable]$Config,
        [string]$RootPath
    )

    $state = @{
        timestamp = (Get-Date).ToString('o')
        version   = "1.0.0"
        root      = $RootPath
    }

    # Core modules
    if (Test-Path (Join-Path $RootPath "core")) {
        $state.modules = @(Get-ChildItem (Join-Path $RootPath "core") -Filter "*.ps1" | ForEach-Object {
            @{
                name     = $_.BaseName
                path     = $_.FullName
                size     = $_.Length
                modified = $_.LastWriteTime.ToString('o')
            }
        })
    }

    # Tests
    if (Test-Path (Join-Path $RootPath "tests")) {
        $state.tests = @(Get-ChildItem (Join-Path $RootPath "tests") -Filter "*.ps1" | ForEach-Object {
            @{
                name     = $_.BaseName
                path     = $_.FullName
                size     = $_.Length
                modified = $_.LastWriteTime.ToString('o')
            }
        })
    }

    # Configuration
    if (Test-Path (Join-Path $RootPath "config")) {
        $state.config = @(Get-ChildItem (Join-Path $RootPath "config") -Filter "*.json" | ForEach-Object {
            @{
                name     = $_.BaseName
                path     = $_.FullName
                size     = $_.Length
                modified = $_.LastWriteTime.ToString('o')
            }
        })
    }

    # Knowledge base
    if (Test-Path (Join-Path $RootPath "Knowledge")) {
        $state.knowledge = @{
            index    = Test-Path (Join-Path $RootPath "Knowledge\INDEX.md")
            sessions = @(Get-ChildItem (Join-Path $RootPath "Knowledge\Sessions") -Filter "*.md" -ErrorAction SilentlyContinue | ForEach-Object {
                @{
                    name     = $_.BaseName
                    path     = $_.FullName
                    modified = $_.LastWriteTime.ToString('o')
                }
            })
        }
    }

    # Git state
    $state.git = Get-Nexus98GitState -RootPath $RootPath

    # Guardian state
    $state.guardian = Get-Nexus98GuardianState -RootPath $RootPath

    return $state
}

function Get-Nexus98GitState {
    param([string]$RootPath)

    $vcsPath = Join-Path $RootPath "vcs\.git"
    $gitState = @{
        available = Test-Path $vcsPath
        branch    = $null
        commit    = $null
        status    = @()
    }

    if ($gitState.available) {
        try {
            $gitState.branch = git -C $vcsPath branch --show-current 2>$null
            $gitState.commit = git -C $vcsPath log --oneline -1 2>$null
            $gitState.status = git -C $vcsPath status --short 2>$null
        } catch {
            $gitState.error = $_.Exception.Message
        }
    }

    return $gitState
}

function Get-Nexus98GuardianState {
    param([string]$RootPath)

    $guardianState = @{
        healthScore = $null
        checkpoints = @()
        operations  = $null
    }

    # Try to load Guardian and get health
    try {
        $guardianLoader = Join-Path $RootPath "core\Guardian_Loader.ps1"
        if (Test-Path $guardianLoader) {
            . $guardianLoader
            if (Get-Command Get-GuardianHealthScore -ErrorAction SilentlyContinue) {
                $health = Get-GuardianHealthScore
                $guardianState.healthScore = $health.overallPct
            }
            if (Get-Command Get-GuardianCheckpoints -ErrorAction SilentlyContinue) {
                $guardianState.checkpoints = @(Get-GuardianCheckpoints | Select-Object -First 10 | ForEach-Object {
                    @{ id = $_.id; tier = $_.tier; created = $_.created; reason = $_.reason }
                })
            }
            if (Get-Command Get-GuardianOperationalState -ErrorAction SilentlyContinue) {
                $guardianState.operations = Get-GuardianOperationalState
            }
        }
    } catch {
        $guardianState.error = $_.Exception.Message
    }

    return $guardianState
}

# Configuration Observer
function Get-Nexus98ConfigState {
    param([string]$RootPath)

    $configPath = Join-Path $RootPath "config"
    $configs = @{}

    if (Test-Path $configPath) {
        Get-ChildItem $configPath -Filter "*.json" | ForEach-Object {
            try {
                $content = Get-Content $_.FullName -Raw -Encoding UTF8
                $configs[$_.BaseName] = $content | ConvertFrom-Json
            } catch {
                $configs[$_.BaseName] = @{ error = $_.Exception.Message }
            }
        }
    }

    return $configs
}

# Module Observer
function Get-Nexus98ModuleState {
    param([string]$RootPath)

    $corePath = Join-Path $RootPath "core"
    $modules = @{}

    if (Test-Path $corePath) {
        Get-ChildItem $corePath -Filter "*.ps1" | ForEach-Object {
            try {
                $content = Get-Content $_.FullName -Raw
                $functions = [regex]::Matches($content, 'function\s+(\w+)') | ForEach-Object { $_.Groups[1].Value }
                $modules[$_.BaseName] = @{
                    path        = $_.FullName
                    size        = $_.Length
                    modified    = $_.LastWriteTime.ToString('o')
                    functions   = $functions
                    functionCount = $functions.Count
                }
            } catch {
                $modules[$_.BaseName] = @{ error = $_.Exception.Message }
            }
        }
    }

    return $modules
}

# Test Observer
function Get-Nexus98TestState {
    param(
        [string]$RootPath,
        [hashtable]$Config
    )

    $testPath = Join-Path $RootPath "tests"
    $testState = @{
        available = Test-Path $testPath
        files     = @()
        lastRun   = $null
    }

    if ($testState.available) {
        $testState.files = @(Get-ChildItem $testPath -Filter "*.ps1" | ForEach-Object {
            @{
                name     = $_.BaseName
                path     = $_.FullName
                size     = $_.Length
                modified = $_.LastWriteTime.ToString('o')
            }
        })

        # Try to run quick test
        if ($Config.runTests) {
            try {
                $runner = Join-Path $testPath "run_foundation_tests.ps1"
                if (Test-Path $runner) {
                    $output = & powershell -ExecutionPolicy Bypass -File $runner 2>&1
                    $testState.lastRun = @{
                        timestamp = (Get-Date).ToString('o')
                        output    = $output
                        passed    = $output -match "Tests Passed:"
                    }
                }
            } catch {
                $testState.lastRun = @{ error = $_.Exception.Message }
            }
        }
    }

    return $testState
}

# Documentation Observer
function Get-Nexus98DocState {
    param([string]$RootPath)

    $docPath = Join-Path $RootPath "docs"
    $docState = @{
        available = Test-Path $docPath
        files     = @()
    }

    if ($docState.available) {
        $docState.files = @(Get-ChildItem $docPath -Filter "*.md" -Recurse | ForEach-Object {
            $relPath = $_.FullName.Substring($RootPath.Length + 1)
            @{
                name     = $_.BaseName
                path     = $relPath
                fullPath = $_.FullName
                size     = $_.Length
                modified = $_.LastWriteTime.ToString('o')
            }
        })
    }

    return $docState
}

# Knowledge Base Observer
function Get-Nexus98KnowledgeState {
    param([string]$RootPath)

    $kbPath = Join-Path $RootPath "Knowledge"
    $kbState = @{
        available = Test-Path $kbPath
        index     = $null
        sessions  = @()
        milestones = @()
        decisions  = @()
    }

    if ($kbState.available) {
        $indexPath = Join-Path $kbPath "INDEX.md"
        if (Test-Path $indexPath) {
            $kbState.index = Get-Content $indexPath -Raw
        }

        $kbState.sessions = @(Get-ChildItem (Join-Path $kbPath "Sessions") -Filter "*.md" -ErrorAction SilentlyContinue | ForEach-Object {
            @{
                name     = $_.BaseName
                path     = $_.FullName
                modified = $_.LastWriteTime.ToString('o')
                preview  = (Get-Content $_.FullName -Raw).Split("`n")[0..19] -join "`n"
            }
        })

        $kbState.milestones = @(Get-ChildItem (Join-Path $kbPath "Milestones") -Filter "*.md" -ErrorAction SilentlyContinue | ForEach-Object {
            @{ name = $_.BaseName; path = $_.FullName; modified = $_.LastWriteTime.ToString('o') }
        })

        $kbState.decisions = @(Get-ChildItem (Join-Path $kbPath "Decisions") -Filter "*.md" -ErrorAction SilentlyContinue | ForEach-Object {
            @{ name = $_.BaseName; path = $_.FullName; modified = $_.LastWriteTime.ToString('o') }
        })
    }

    return $kbState
}

# Combined State Snapshot
function Get-Nexus98FullSnapshot {
    param(
        [string]$RootPath = (Resolve-Path ".").Path,
        [hashtable]$Config
    )

    if (-not $Config) { $Config = @{} }

    $snapshot = @{
        timestamp   = (Get-Date).ToString('o')
        version     = "1.0.0"
        rootPath    = $RootPath
        system      = Get-Nexus98SystemState -Config $Config -RootPath $RootPath
        config      = Get-Nexus98ConfigState -RootPath $RootPath
        modules     = Get-Nexus98ModuleState -RootPath $RootPath
        tests       = Get-Nexus98TestState -RootPath $RootPath -Config $Config
        docs        = Get-Nexus98DocState -RootPath $RootPath
        knowledge   = Get-Nexus98KnowledgeState -RootPath $RootPath
    }

    return $snapshot
}