# Pester tests for Guardian M7 Self-Development Guard & Drift Gate.

BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
}

function New-TestRoot {
    $p = Join-Path $env:TEMP ("guardian_m7_" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $p | Out-Null
    return $p
}
function Remove-TestRoot($p) { if ($p -and (Test-Path $p)) { Remove-Item -Recurse -Force $p } }
function Jp($a,$b,$c) { if ($c) { return Join-Path (Join-Path $a $b) $c } else { return Join-Path $a $b } }

Describe 'Architecture Baseline' {
    It 'creates a baseline with all required sections' {
        $tr = New-TestRoot
        try {
            New-Item -ItemType Directory -Force -Path (Jp $tr 'core') | Out-Null
            New-Item -ItemType Directory -Force -Path (Jp $tr 'config') | Out-Null
            New-Item -ItemType Directory -Force -Path (Jp $tr 'data' 'checkpoints') | Out-Null
            Set-Content -Path (Jp $tr 'core' 'Guardian_X.ps1') -Value '# x'
            Set-Content -Path (Jp $tr 'config' 'guardian_test.json') -Value '{}'
            Set-Content -Path (Jp $tr 'README.md') -Value 'x'
            $b = New-GuardianArchitectureBaseline -Root $tr
            $b.approvedDirectories        | Should -Not -BeNullOrEmpty
            $b.approvedModules            | Should -Not -BeNullOrEmpty
            $b.approvedDataLocations      | Should -Not -BeNullOrEmpty
            $b.approvedConfigFiles        | Should -Not -BeNullOrEmpty
            $b.approvedGeneratedArtifacts | Should -Not -BeNullOrEmpty
            $b.approvedTopLevelFiles      | Should -Not -BeNullOrEmpty
            $b.protectedSurfaces          | Should -Not -BeNullOrEmpty
        } finally { Remove-TestRoot $tr }
    }
    It 'persists the baseline to config' {
        Save-GuardianArchitectureBaseline | Out-Null
        (Get-GuardianArchitectureBaseline) | Should -Not -BeNullOrEmpty
    }
}

Describe 'Allowed Changes' {
    It 'reports stable (no drift) when the tree matches its baseline' {
        $tr = New-TestRoot
        try {
            New-Item -ItemType Directory -Force -Path (Jp $tr 'core') | Out-Null
            New-Item -ItemType Directory -Force -Path (Jp $tr 'config') | Out-Null
            Set-Content -Path (Jp $tr 'core' 'Guardian_TestStub.ps1') -Value '# stub'
            Set-Content -Path (Jp $tr 'README.md') -Value 'x'
            $base = New-GuardianArchitectureBaseline -Root $tr
            $drift = @(Get-GuardianDrift -Root $tr -Baseline $base)
            $drift.Count | Should -Be 0
        } finally { Remove-TestRoot $tr }
    }
}

Describe 'Unauthorized Changes / Drift Detection' {
    It 'detects a new unapproved directory' {
        $tr = New-TestRoot
        try {
            New-Item -ItemType Directory -Force -Path (Jp $tr 'core') | Out-Null
            New-Item -ItemType Directory -Force -Path (Jp $tr 'config') | Out-Null
            Set-Content -Path (Jp $tr 'README.md') -Value 'x'
            $base = New-GuardianArchitectureBaseline -Root $tr
            New-Item -ItemType Directory -Force -Path (Jp $tr 'rogue') | Out-Null
            $drift = @(Get-GuardianDrift -Root $tr -Baseline $base)
            ($drift.type -contains 'NEW_UNAPPROVED_DIRECTORY') | Should -Be $true
        } finally { Remove-TestRoot $tr }
    }
    It 'detects a new unapproved module' {
        $tr = New-TestRoot
        try {
            New-Item -ItemType Directory -Force -Path (Jp $tr 'core') | Out-Null
            New-Item -ItemType Directory -Force -Path (Jp $tr 'config') | Out-Null
            Set-Content -Path (Jp $tr 'core' 'Guardian_A.ps1') -Value '# a'
            Set-Content -Path (Jp $tr 'README.md') -Value 'x'
            $base = New-GuardianArchitectureBaseline -Root $tr
            Set-Content -Path (Jp $tr 'core' 'Guardian_B.ps1') -Value '# b'
            $drift = @(Get-GuardianDrift -Root $tr -Baseline $base)
            ($drift.type -contains 'NEW_UNAPPROVED_MODULE') | Should -Be $true
        } finally { Remove-TestRoot $tr }
    }
    It 'detects configuration drift' {
        $tr = New-TestRoot
        try {
            New-Item -ItemType Directory -Force -Path (Jp $tr 'core') | Out-Null
            New-Item -ItemType Directory -Force -Path (Jp $tr 'config') | Out-Null
            Set-Content -Path (Jp $tr 'README.md') -Value 'x'
            $base = New-GuardianArchitectureBaseline -Root $tr
            Set-Content -Path (Jp $tr 'config' 'newconfig.json') -Value '{}'
            $drift = @(Get-GuardianDrift -Root $tr -Baseline $base)
            ($drift.type -contains 'CONFIGURATION_DRIFT') | Should -Be $true
        } finally { Remove-TestRoot $tr }
    }
    It 'detects an uncontrolled top-level artifact' {
        $tr = New-TestRoot
        try {
            New-Item -ItemType Directory -Force -Path (Jp $tr 'core') | Out-Null
            New-Item -ItemType Directory -Force -Path (Jp $tr 'config') | Out-Null
            Set-Content -Path (Jp $tr 'README.md') -Value 'x'
            $base = New-GuardianArchitectureBaseline -Root $tr
            Set-Content -Path (Jp $tr 'untracked.txt') -Value 'x'
            $drift = @(Get-GuardianDrift -Root $tr -Baseline $base)
            ($drift.type -contains 'UNCONTROLLED_ARTIFACT') | Should -Be $true
        } finally { Remove-TestRoot $tr }
    }
}

Describe 'Change Governance' {
    It 'blocks a change request missing the governance chain' {
        $r = New-GuardianChangeRequest -Description 'edit module' -RiskLevel 'high'
        $g = Test-GuardianChangeGovernance -Request $r
        $g.decision | Should -Be 'BLOCK'
    }
    It 'allows once checkpoint/plan/validation/comparison are satisfied' {
        $r = New-GuardianChangeRequest -Description 'edit module' -RiskLevel 'high'
        New-GuardianCheckpoint -Tier rolling -Reason 'm7 test' | Out-Null
        Set-GuardianChangeStage -Request $r -Stage CHECKPOINT_CREATED -Value $true | Out-Null
        Set-GuardianChangeStage -Request $r -Stage TEST_PLAN_CREATED -Value $true | Out-Null
        Set-GuardianChangeStage -Request $r -Stage VALIDATION_COMPLETED -Value $true | Out-Null
        Set-GuardianChangeStage -Request $r -Stage COMPARISON_COMPLETED -Value $true | Out-Null
        (Test-GuardianChangeGovernance -Request $r).decision | Should -Be 'ALLOW'
    }
}

Describe 'Self-Modification Guard' {
    It 'blocks self-modification lacking all safeguards' {
        $r = New-GuardianChangeRequest -Description 'modify core' -RiskLevel 'critical' -SelfModification
        $g = Test-GuardianSelfModification -Request $r -Surface 'Guardian Core'
        $g.decision | Should -Be 'BLOCK'
    }
    It 'allows self-modification when all six safeguards hold' {
        $r = New-GuardianChangeRequest -Description 'modify core' -RiskLevel 'critical' -SelfModification
        $g = Test-GuardianSelfModification -Request $r -Surface 'Guardian Core' `
            -EmergencyCheckpoint $true -ChangeProposal $true -ImpactAnalysis $true `
            -AutomatedTests $true -HealthComparison $true -RollbackAvailable $true
        $g.decision | Should -Be 'ALLOW_WITH_MONITORING'
    }
    It 'blocks an unrecognized protected surface' {
        $r = New-GuardianChangeRequest -Description 'x' -SelfModification
        (Test-GuardianSelfModification -Request $r -Surface 'DoesNotExist' -EmergencyCheckpoint $true).decision | Should -Be 'BLOCK'
    }
}

Describe 'Rollback / Checkpoint Enforcement' {
    It 'creates an emergency checkpoint for self-modification' {
        $ck = New-GuardianSelfModificationCheckpoint -Reason 'm7 test'
        $ck.id | Should -Match '^CK_'
        (Get-GuardianCheckpoints -Tier emergency | Where-Object { $_.id -eq $ck.id }) | Should -Not -BeNullOrEmpty
    }
}

Describe 'Storage Governance' {
    It 'detects uncontrolled snapshots in the live tree' {
        $findings = @(Get-GuardianStorageGovernance)
        ($findings.rule -contains 'UNCONTROLLED_SNAPSHOTS') | Should -Be $true
    }
    It 'attaches a lifecycle (owner/category/retention/cleanup) to each finding' {
        $findings = @(Get-GuardianStorageGovernance)
        $ok = $true
        foreach ($f in $findings) {
            if (-not ($f.lifecycle.owner -and $f.lifecycle.category -and $f.lifecycle.retentionPolicy -and $f.lifecycle.cleanupStatus)) { $ok = $false }
        }
        $ok | Should -Be $true
    }
}

Describe 'Integration - Drift Guard Orchestrator' {
    It 'runs the guard and returns a verdict' {
        $r = Invoke-GuardianDriftGuard
        $r.verdict | Should -Not -BeNullOrEmpty
        ($r.driftCount -ge 0) | Should -Be $true
    }
    It 'all M7 modules loaded' {
        (Get-Command Save-GuardianArchitectureBaseline -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Get-GuardianDrift -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Test-GuardianSelfModification -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Invoke-GuardianDriftGuard -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }
}