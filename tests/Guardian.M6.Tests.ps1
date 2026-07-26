# Pester tests for Guardian M6 Communication Layer.

BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
}

Describe 'Communication Layer - Outbound' {
    It 'sends a health report to Nexus98' {
        $m = Send-GuardianHealthReportToNexus98
        $m.type | Should -Be 'GUARDIAN_HEALTH_REPORT'
        $m.target | Should -Be 'Nexus98'
    }
    It 'sends a warning' {
        $m = Send-GuardianWarningToNexus98 -Warning 'x' -RiskLevel 'high'
        $m.type | Should -Be 'GUARDIAN_WARNING'
    }
    It 'sends an explanation' {
        $e = Get-GuardianStorageExplanation
        $m = Send-GuardianExplanationToNexus98 -Explanation $e
        $m.type | Should -Be 'GUARDIAN_EXPLANATION'
    }
    It 'sends a recommendation' {
        $m = Send-GuardianRecommendationToNexus98 -Recommendation 'review'
        $m.type | Should -Be 'GUARDIAN_RECOMMENDATION'
    }
    It 'persists messages to the outbox' {
        @(Get-GuardianOutbox).Count | Should -BeGreaterThan 0
    }
}

Describe 'Communication Layer - Inbound' {
    It 'receives a Nexus98 task context' {
        $m = Receive-Nexus98TaskContext -TaskDescription 'analyze' -RequestedAnalysis @('storage')
        $m.type | Should -Be 'NEXUS98_TASK_CONTEXT'
        @(Get-GuardianInbox).Count | Should -BeGreaterThan 0
    }
    It 'receives an operation status' {
        $m = Receive-Nexus98OperationStatus -Component 'x' -Status 'healthy'
        $m.type | Should -Be 'NEXUS98_OPERATION_STATUS'
    }
    It 'receives an analysis request' {
        $m = Receive-Nexus98AnalysisRequest -AnalysisKind 'storage'
        $m.type | Should -Be 'NEXUS98_ANALYSIS_REQUEST'
    }
}

Describe 'Communication Layer - Modulation' {
    It 'modulates an inbound task into a governance response' {
        $tc = Receive-Nexus98TaskContext -TaskDescription 'refactor' -RequestedAnalysis @('storage')
        $r = Invoke-GuardianModulation -InboundMessage $tc
        $r.type | Should -Be 'GUARDIAN_RESPONSE'
        $r.decision | Should -Not -BeNullOrEmpty
    }
    It 'escalates risk for destructive inbound status' {
        $tc = New-Nexus98ToGuardianTaskContext -TaskDescription 'delete' -OperationStatus 'destructive'
        $r = Invoke-GuardianModulation -InboundMessage $tc
        Write-Host ('[DIAG] decision=[' + $r.decision + '] type=' + $r.decision.GetType().FullName)
        ($r.decision -in @('DELAYED','REQUIRE_CHECKPOINT','REQUIRE_REVIEW','BLOCK')) | Should -Be $true
    }
}

Describe 'Integration - Import Check' {
    It 'all M6 modules loaded' {
        (Get-Command Send-GuardianHealthReportToNexus98 -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Invoke-GuardianModulation -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }
}