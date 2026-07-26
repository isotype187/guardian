# Pester tests for Guardian M8 Governed Communication Bridge.

BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
    # Ensure bridge state is initialized in test scope (Pester 6 scope isolation)
    Set-GuardianBridgeEnabled -Enabled $true | Out-Null
    $script:GuardianBridgeProcessed = @{}  # Initialize dedup hashtable
}

Describe 'Transport' {
    It 'sends a message into the outbox' {
        Initialize-GuardianBridge -Force | Out-Null
        $m = New-GuardianBridgeMessage -Sender 'Guardian' -Receiver 'Nexus98' -MessageType 'SYSTEM_HEALTH_REPORT' -Content @{}
        $r = Send-GuardianBridgeMessage -Message $m
        $r.accepted | Should -Be $true
    }
    It 'receives a message into the inbox' {
        $m = New-GuardianBridgeMessage -Sender 'Nexus98' -Receiver 'Guardian' -MessageType 'ANALYSIS_REQUEST' -Content @{analysisKind='storage'} -RiskLevel 'low'
        $r = Receive-GuardianBridgeMessage -Message $m
        $r.accepted | Should -Be $true
    }
    It 'dispatches queued outbound messages' {
        $m = New-GuardianBridgeMessage -Sender 'Guardian' -Receiver 'Nexus98' -MessageType 'SYSTEM_HEALTH_REPORT' -Content @{}
        Send-GuardianBridgeMessage -Message $m | Out-Null
        $d = Invoke-GuardianBridgeDispatch
        $d.processed | Should -BeGreaterThan 0
    }
}

Describe 'Security' {
    It 'blocks an unknown sender at send time' {
        $m = New-GuardianBridgeMessage -Sender 'RogueAI' -Receiver 'Nexus98' -MessageType 'SYSTEM_HEALTH_REPORT' -Content @{}
        $r = Send-GuardianBridgeMessage -Message $m
        $r.accepted | Should -Be $false
    }
    It 'blocks an unauthorized action' {
        $m = New-GuardianBridgeMessage -Sender 'Nexus98' -Receiver 'Guardian' -MessageType 'ANALYSIS_REQUEST' -Content @{} -RiskLevel 'high' -PermissionRequired $true -AuthorizationStatus 'NONE'
        $r = Receive-GuardianBridgeMessage -Message $m
        $r.accepted | Should -Be $false
    }
    It 'passes schema validation for valid messages' {
        $m = New-GuardianBridgeMessage -Sender 'Guardian' -Receiver 'Nexus98' -MessageType 'SYSTEM_HEALTH_REPORT' -Content @{}
        $sec = Test-GuardianBridgeSecurity -Message $m
        $sec.passed | Should -Be $true
    }
}

Describe 'Recovery' {
    It 'preserves failed messages in the failed folder' {
        Initialize-GuardianBridge -Force | Out-Null
        $m = New-GuardianBridgeMessage -Sender 'Guardian' -Receiver 'Nexus98' -MessageType 'SYSTEM_HEALTH_REPORT' -Content @{} -RiskLevel 'critical' -PermissionRequired $true -AuthorizationStatus 'NONE'
        Send-GuardianBridgeMessage -Message $m | Out-Null
        $failed = Join-Path (Join-Path $GuardianBridgeRoot 'failed') ($m.message_id + '.json')
        (Test-Path $failed) | Should -Be $true
    }
    It 'retries failed messages via the recovery loop' {
        Initialize-GuardianBridge -Force | Out-Null
        $m = New-GuardianBridgeMessage -Sender 'Guardian' -Receiver 'Nexus98' -MessageType 'SYSTEM_HEALTH_REPORT' -Content @{} -RiskLevel 'critical' -PermissionRequired $true -AuthorizationStatus 'NONE'
        Send-GuardianBridgeMessage -Message $m | Out-Null
        $rep = Repair-GuardianBridgeFailures
        $rep.retried | Should -BeGreaterThan 0
    }
}

Describe 'Integration' {
    It 'Guardian sends a health report to Nexus98' {
        Initialize-GuardianBridge -Force | Out-Null
        $m = Send-GuardianHealthReportToNexus98Bridge
        $m.message_type | Should -Be 'SYSTEM_HEALTH_REPORT'
        $m.receiver | Should -Be 'Nexus98'
    }
    It 'Nexus98 analysis request reaches the Guardian inbox' {
        Initialize-GuardianBridge -Force | Out-Null
        $m = Receive-Nexus98AnalysisRequestBridge -AnalysisKind 'storage' -RiskLevel 'low'
        $m.message_type | Should -Be 'ANALYSIS_REQUEST'
        $m.sender | Should -Be 'Nexus98'
        $inbox = Join-Path (Join-Path $GuardianBridgeRoot 'inbox') ($m.message_id + '.json')
        (Test-Path $inbox) | Should -Be $true
    }
    It 'dispatcher completes a queued outbound message' {
        Initialize-GuardianBridge -Force | Out-Null
        Send-GuardianHealthReportToNexus98Bridge | Out-Null
        $d = Invoke-GuardianBridgeDispatch
        $d.processed | Should -BeGreaterThan 0
        $completed = Join-Path $GuardianBridgeRoot 'completed'
        (@(Get-ChildItem -Path $completed -File -ErrorAction SilentlyContinue).Count) | Should -BeGreaterThan 0
    }
    It 'governance produces a decision for an inbound Nexus98 request' {
        Initialize-GuardianBridge -Force | Out-Null
        $m = Receive-Nexus98AnalysisRequestBridge -AnalysisKind 'storage' -RiskLevel 'low'
        $g = Invoke-GuardianBridgeGovernance -Message $m
        $g.decision | Should -Not -BeNullOrEmpty
        @('ALLOW','ALLOW_WITH_MONITORING','REQUIRE_CHECKPOINT','REQUIRE_REVIEW','BLOCK') -contains $g.decision | Should -Be $true
    }
}

Describe 'Observability' {
    It 'computes a communication health score' {
        $h = Get-GuardianCommunicationHealth
        ($h.healthScore -ge 0) | Should -Be $true
        ($h.healthScore -le 100) | Should -Be $true
        $h.enabled | Should -Be $true
    }
}

Describe 'Bridge Disable Safety' {
    It 'refuses to send when the bridge is disabled' {
        Set-GuardianBridgeEnabled -Enabled $false | Out-Null
        $m = New-GuardianBridgeMessage -Sender 'Guardian' -Receiver 'Nexus98' -MessageType 'SYSTEM_HEALTH_REPORT' -Content @{}
        $r = Send-GuardianBridgeMessage -Message $m
        $r.accepted | Should -Be $false
        Set-GuardianBridgeEnabled -Enabled $true | Out-Null
    }
}

Describe 'Integration - Import Check' {
    It 'all M8 modules loaded' {
        (Get-Command Send-GuardianBridgeMessage -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Invoke-GuardianBridgeDispatch -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Test-GuardianBridgeSecurity -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Get-GuardianCommunicationHealth -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }
}