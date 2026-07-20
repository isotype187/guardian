# Pester tests for Guardian foundation modules (Milestone 0-2).
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
. (Join-Path $root 'core\Guardian_Loader.ps1')

Describe 'Guardian Environment Contract' {
    It 'resolves the Guardian root' {
        $GuardianEnv.Root | Should Not BeNullOrEmpty
    }
    It 'initializes required directories' {
        $env = Initialize-GuardianEnvironment
        Test-Path $env.Rolling | Should Be $true
        Test-Path $env.Milestones | Should Be $true
        Test-Path $env.Emergency | Should Be $true
    }
}

Describe 'Guardian Communication Contracts' {
    It 'builds a health message' {
        $m = New-GuardianHealthMessage -Component 'test' -Status 'healthy'
        $m.type | Should Be 'HEALTH_MESSAGE'
        $m.component | Should Be 'test'
    }
    It 'builds a guardian response' {
        $r = New-GuardianResponse -Decision 'ALLOW' -Reason 'ok'
        $r.type | Should Be 'GUARDIAN_RESPONSE'
        $r.decision | Should Be 'ALLOW'
    }
    It 'serializes a message' {
        $j = Export-GuardianMessage -Message (New-GuardianSystemEvent -Component 'x' -Event 'y')
        $j | Should Match 'SYSTEM_EVENT'
    }
}

Describe 'Governance Policy Engine' {
    It 'allows low-risk with checkpoint' {
        (Test-GuardianPolicy -ActionDescription 'read' -RiskLevel low -CheckpointAvailable $true).decision | Should Be 'ALLOW'
    }
    It 'delays high-risk without checkpoint' {
        (Test-GuardianPolicy -ActionDescription 'delete' -RiskLevel high -CheckpointAvailable $false).decision | Should Be 'DELAYED'
    }
    It 'requires review for critical' {
        (Test-GuardianPolicy -ActionDescription 'self-modify' -RiskLevel critical -CheckpointAvailable $true).decision | Should Be 'REQUIRE_REVIEW'
    }
    It 'blocks critical when safeguards gone' {
        (Test-GuardianPolicy -ActionDescription 'disable safety' -RiskLevel critical -SafeguardsIntact $false).decision | Should Be 'BLOCK'
    }
}

Describe 'Rolling Checkpoint System' {
    $ck = $null
    It 'creates a rolling checkpoint' {
        $ck = New-GuardianCheckpoint -Tier rolling -Reason 'test'
        $ck.id | Should Match '^CK_'
        Test-Path (Join-Path $GuardianEnv.Rolling $ck.id) | Should Be $true
    }
    It 'retrieves the checkpoint by id' {
        $found = Get-GuardianCheckpoint -Id $ck.id
        $found.id | Should Be $ck.id
    }
}

Describe 'Audit System' {
    It 'appends audit records' {
        $before = (Get-GuardianAuditTrail).Count
        Write-GuardianAudit -Action 'test_action' -Reason 'unit-test'
        (Get-GuardianAuditTrail).Count | Should BeGreaterThan $before
    }
}

Describe 'Integrity Monitor' {
    It 'produces integrity events' {
        $events = Get-GuardianIntegrityEvents
        $events | Should Not BeNullOrEmpty
    }
}

Describe 'Health Score' {
    It 'computes a numeric overall score' {
        $h = Get-GuardianHealthScore
        $h.overallPct | Should BeGreaterThan 0
        $h.subsystemsTotal | Should Be 15
    }
}
