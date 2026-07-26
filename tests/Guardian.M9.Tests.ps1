# Pester tests for Guardian M9 Storage Entropy Remediation.

BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))

    function New-TestEntropyTree {
        $p = Join-Path $env:TEMP ("m9_test_" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Force -Path $p | Out-Null
        $b1 = Join-Path $p 'backup_1';            New-Item -ItemType Directory -Force -Path $b1 | Out-Null
        Set-Content -Path (Join-Path $b1 'a.txt') -Value 'x'
        $deep = Join-Path $p (Join-Path 'sub' (Join-Path 'deep' (Join-Path 'deeper' 'deepest')))
        New-Item -ItemType Directory -Force -Path $deep | Out-Null
        Set-Content -Path (Join-Path $deep 'b.txt') -Value 'y'
        $temp = Join-Path $p 'temp_copy';        New-Item -ItemType Directory -Force -Path $temp | Out-Null
        Set-Content -Path (Join-Path $temp 'c.txt') -Value 'z'
        return $p
    }
    function Remove-TestTree($p) { if ($p -and (Test-Path $p)) { Remove-Item -Recurse -Force $p } }
    function Clear-RemediationData {
        $d = Join-Path $GuardianEnv.Data 'remediation'
        if (Test-Path $d) { Remove-Item -Recurse -Force $d }
    }
}

Describe 'Entropy Analysis' {
    It 'detects entropy in a synthetic tree' {
        $p = New-TestEntropyTree
        try {
            $e = Get-GuardianStorageEntropy -Path $p -SampleCap 500
            $e.entropyCount | Should -BeGreaterThan 0
            $e.byClass | Should -Not -BeNullOrEmpty
        } finally { Remove-TestTree $p }
    }
    It 'classifies naming-entropy and nested copies' {
        $p = New-TestEntropyTree
        try {
            $e = Get-GuardianStorageEntropy -Path $p -SampleCap 500
            $classes = @($e.entropy | ForEach-Object { $_.class })
            ($classes -contains 'NAMING_ENTROPY_DIRECTORY') | Should -Be $true
            ($classes -contains 'NESTED_COPY') | Should -Be $true
        } finally { Remove-TestTree $p }
    }
}

Describe 'Remediation Plan' {
    It 'builds a move-only plan from detected entropy' {
        $p = New-TestEntropyTree
        try {
            Clear-RemediationData
            $plan = New-GuardianRemediationPlan -Path $p -SampleCap 500
            $plan.actionCount | Should -BeGreaterThan 0
            $plan.deletion | Should -Be $false
            $plan.governanceRequired | Should -Be $true
            $plan.checkpointRequired | Should -Be $true
            (@($plan.actions | Where-Object { $_.operation -ne 'MOVE' }).Count) | Should -Be 0
        } finally { Remove-TestTree $p }
    }
}

Describe 'Governed Execution' {
    It 'dry-run previews without changing the filesystem' {
        $p = New-TestEntropyTree
        try {
            Clear-RemediationData
            $plan = New-GuardianRemediationPlan -Path $p -SampleCap 500
            $res = Invoke-GuardianRemediationPlan -Plan $plan -DryRun $true
            $res.decision | Should -Be 'DRYRUN_OK'
            $res.executed | Should -Be $false
            $res.manifest.Count | Should -Be $plan.actionCount
            (Test-Path (Join-Path (Join-Path $p 'backup_1') 'a.txt')) | Should -Be $true
        } finally { Remove-TestTree $p }
    }
    It 'blocks real execution without a checkpoint + governance gate' {
        $p = New-TestEntropyTree
        try {
            Clear-RemediationData
            $plan = New-GuardianRemediationPlan -Path $p -SampleCap 500
            $res = Invoke-GuardianRemediationPlan -Plan $plan -DryRun $false -CheckpointId ''
            $res.decision | Should -Be 'BLOCKED'
            $res.moved | Should -Be 0
        } finally { Remove-TestTree $p }
    }
    It 'executes move-only remediation under a checkpoint' {
        $p = New-TestEntropyTree
        try {
            Clear-RemediationData
            $plan = New-GuardianRemediationPlan -Path $p -SampleCap 500
            $ck = New-GuardianSelfModificationCheckpoint -Reason 'm9 test'
            $res = Invoke-GuardianRemediationPlan -Plan $plan -DryRun $false -CheckpointId $ck.id
            $res.decision | Should -Be 'EXECUTED'
            $res.moved | Should -BeGreaterThan 0
            (Test-Path (Join-Path (Join-Path $p 'backup_1') 'a.txt')) | Should -Be $false
        } finally { Remove-TestTree $p }
    }
    It 'writes a rollback manifest during execution' {
        $p = New-TestEntropyTree
        try {
            Clear-RemediationData
            $plan = New-GuardianRemediationPlan -Path $p -SampleCap 500
            $ck = New-GuardianSelfModificationCheckpoint -Reason 'm9 test'
            Invoke-GuardianRemediationPlan -Plan $plan -DryRun $false -CheckpointId $ck.id | Out-Null
            $manifest = Join-Path $GuardianEnv.Data (Join-Path 'remediation' 'rollback_manifest.jsonl')
            (Test-Path $manifest) | Should -Be $true
        } finally { Remove-TestTree $p }
    }
}

Describe 'Rollback' {
    It 'reverts moved items via the manifest' {
        $p = New-TestEntropyTree
        try {
            Clear-RemediationData
            $plan = New-GuardianRemediationPlan -Path $p -SampleCap 500
            $ck = New-GuardianSelfModificationCheckpoint -Reason 'm9 test'
            $res = Invoke-GuardianRemediationPlan -Plan $plan -DryRun $false -CheckpointId $ck.id
            $undo = Undo-GuardianRemediation
            $undo.reverted | Should -Be $res.moved
        } finally { Remove-TestTree $p }
    }
}

Describe 'Observability' {
    It 'reports remediation metrics' {
        Clear-RemediationData
        $m = Get-GuardianRemediationMetrics
        $m | Should -Not -BeNullOrEmpty
        ($m.reductionPct -ge 0) | Should -Be $true
    }
}

Describe 'Integration - M9 module loaded' {
    It 'all M9 functions present' {
        (Get-Command Get-GuardianStorageEntropy -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command New-GuardianRemediationPlan -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Invoke-GuardianRemediationPlan -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Undo-GuardianRemediation -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }
}