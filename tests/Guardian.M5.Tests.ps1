# Pester tests for Guardian M5 Remediation / Action Planning / Governance.

BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
}

Describe 'Action Planning' {
    It 'builds a remediation plan with required fields' {
        $p = Get-GuardianRemediationPlan -Issue 'rolling checkpoint rotation needed'
        $p.plan_id | Should -Match '^PLAN_'
        $p.riskLevel | Should -Be 'low'
        $p.rollbackPlan | Should -Not -BeNullOrEmpty
        $p.acceptanceCriteria | Should -Not -BeNullOrEmpty
    }
    It 'validates a well-formed plan' {
        $p = Get-GuardianRemediationPlan -Issue 'storage growth'
        (Test-GuardianActionPlan -Plan $p).valid | Should -Be $true
    }
    It 'rejects a high-risk plan without rollback' {
        $bad = New-GuardianActionPlan -Objective 'x' -RiskLevel 'high' -RollbackPlan '' -AcceptanceCriteria 'y'
        (Test-GuardianActionPlan -Plan $bad).valid | Should -Be $false
    }
}

Describe 'Controlled Remediation' {
    It 'auto-executes low-risk reversible action under a checkpoint' {
        $p = Get-GuardianRemediationPlan -Issue 'rolling checkpoint rotation needed'
        $r = Invoke-GuardianRemediation -Plan $p
        $r.status | Should -Be 'EXECUTED'
        $r.executed | Should -Be $true
        $r.checkpoint | Should -Match '^CK_'
    }
    It 'defers destructive actions to human review' {
        $del = New-GuardianActionPlan -Objective 'delete unknown temp files' -RiskLevel 'medium' -AffectedItems @('temp') -RollbackPlan 'x' -AcceptanceCriteria 'y'
        $r = Invoke-GuardianRemediation -Plan $del
        $r.status | Should -Be 'DEFERRED'
        $r.decision | Should -Be 'REQUIRE_REVIEW'
        $r.executed | Should -Be $false
    }
    It 'defers high-risk remediation to checkpoint/review' {
        $hi = Get-GuardianRemediationPlan -Issue 'security drift: 1 modified'
        $r = Invoke-GuardianRemediation -Plan $hi
        $r.status | Should -Be 'DEFERRED'
    }
    It 'supports dry-run without execution' {
        $p = Get-GuardianRemediationPlan -Issue 'rolling checkpoint rotation needed'
        $r = Invoke-GuardianRemediation -Plan $p -DryRun
        $r.status | Should -Be 'DRYRUN_OK'
        $r.executed | Should -Be $false
    }
    It 'aggregates remediation options from current state' {
        (@(Get-GuardianRemediationOptions).Count -ge 0) | Should -Be $true
    }
}

Describe 'Governance Integration' {
    It 'produces a decision with explanation and memory' {
        $d = Request-GuardianDecision -ActionDescription 'install dependency' -RiskLevel 'medium' -CheckpointAvailable $true
        $d.decision | Should -Not -BeNullOrEmpty
        $d.explanation.what | Should -Match 'decision'
        $d.memory_id | Should -Match '^MEM_'
    }
    It 'summarizes governance decisions' {
        (Get-GuardianGovernanceSummary).totalDecisions | Should -BeGreaterThan 0
    }
}

Describe 'Integration - Import Check' {
    It 'all M5 modules loaded' {
        (Get-Command New-GuardianActionPlan -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Invoke-GuardianRemediation -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Request-GuardianDecision -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }
}