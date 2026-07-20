# Pester tests for Guardian M8 Nexus98 Governed Communication Loop.
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
. (Join-Path $root 'core\Guardian_Loader.ps1')
Import-Guardian -Root $root

Describe 'Transport' {
    It 'creates a well-formed bridge message' {
        $m = New-GuardianBridgeMessage -Sender Guardian -Receiver Nexus98 -MessageType SYSTEM_HEALTH_REPORT -Content @{}
        $m.message_id | Should Match '^MSG_'
        $m.correlation_id | Should Match '^COR_'
        $m.status | Should Be 'CREATED'
    }
    It 'sends a message into the outbox' {
        Initialize-GuardianBridge | Out-Null
        $m = New-GuardianBridgeMessage -Sender Guardian -Receiver Nexus98 -MessageType SYSTEM_HEALTH_REPORT -Content @{}
        $r = Send-GuardianBridgeMessage -Message $m
        $r.accepted | Should Be $true
        $stored = Join-Path (Join-Path $root 'communication') (Join-Path 'outbox' ($m.message_id + '.json'))
        (Test-Path $stored) | Should Be $true
    }
    It 'receives a message into the inbox' {
        Initialize-GuardianBridge | Out-Null
        $m = New-GuardianBridgeMessage -Sender Nexus98 -Receiver Guardian -MessageType ANALYSIS_REQUEST -Content @{ analysisKind='storage' }
        $r = Receive-GuardianBridgeMessage -Message $m
        $r.accepted | Should Be $true
        $stored = Join-Path (Join-Path $root 'communication') (Join-Path 'inbox' ($m.message_id + '.json'))
        (Test-Path $stored) | Should Be $true
    }
}

Describe 'Validation' {
    It 'rejects a malformed (schema-violating) message' {
        $bad = [PSCustomObject]@{ message_id='x' }  # missing required fields
        $res = Test-GuardianBridgeSecurity -Message $bad
        $res.passed | Should Be $false
        $res.decision | Should Be 'BLOCKED'
    }
    It 'blocks an unknown sender' {
        $m = New-GuardianBridgeMessage -Sender 'Intruder' -Receiver Nexus98 -MessageType SYSTEM_HEALTH_REPORT -Content @{}
        $sec = Test-GuardianBridgeSecurity -Message $m
        $sec.passed | Should Be $false
    }
    It 'blocks a message requiring permission without authorization' {
        $m = New-GuardianBridgeMessage -Sender Nexus98 -Receiver Guardian -MessageType ANALYSIS_REQUEST `
            -Content @{} -RiskLevel 'critical' -PermissionRequired $true -AuthorizationStatus 'NONE'
        $sec = Test-GuardianBridgeSecurity -Message $m
        $sec.passed | Should Be $false
    }
    It 'accepts a permission-required message when granted' {
        $m = New-GuardianBridgeMessage -Sender Nexus98 -Receiver Guardian -MessageType ANALYSIS_REQUEST `
            -Content @{} -RiskLevel 'critical' -PermissionRequired $true -AuthorizationStatus 'GRANTED'
        (Test-GuardianBridgeSecurity -Message $m).passed | Should Be $true
    }
}

Describe 'Recovery' {
    It 'preserves failed messages in the failed folder' {
        Initialize-GuardianBridge | Out-Null
        $m = New-GuardianBridgeMessage -Sender 'Intruder' -Receiver Nexus98 -MessageType SYSTEM_HEALTH_REPORT -Content @{}
        Send-GuardianBridgeMessage -Message $m | Out-Null
        $failed = Join-Path (Join-Path $root 'communication') (Join-Path 'failed' ($m.message_id + '.json'))
        (Test-Path $failed) | Should Be $true
    }
    It 'retries failed messages via the recovery loop' {
        Initialize-GuardianBridge | Out-Null
        $m = New-GuardianBridgeMessage -Sender 'Intruder' -Receiver Nexus98 -MessageType SYSTEM_HEALTH_REPORT -Content @{}
        Send-GuardianBridgeMessage -Message $m | Out-Null
        $rep = Repair-GuardianBridgeFailures
        $rep.retried | Should BeGreaterThan 0
        $moved = Join-Path (Join-Path $root 'communication') (Join-Path 'outbox' ($m.message_id + '.json'))
        (Test-Path $moved) | Should Be $true
    }
}

Describe 'Integration' {
    It 'Guardian sends a health report to Nexus98' {
        Initialize-GuardianBridge | Out-Null
        $m = Send-GuardianHealthReportToNexus98Bridge
        $m.message_type | Should Be 'SYSTEM_HEALTH_REPORT'
        $m.receiver | Should Be 'Nexus98'
    }
    It 'Nexus98 analysis request reaches the Guardian inbox' {
        Initialize-GuardianBridge | Out-Null
        $m = Receive-Nexus98AnalysisRequestBridge -AnalysisKind 'storage' -RiskLevel 'low'
        $m.message_type | Should Be 'ANALYSIS_REQUEST'
        $m.sender | Should Be 'Nexus98'
        $inbox = Join-Path (Join-Path $root 'communication') (Join-Path 'inbox' ($m.message_id + '.json'))
        (Test-Path $inbox) | Should Be $true
    }
    It 'dispatcher completes a queued outbound message' {
        Initialize-GuardianBridge | Out-Null
        Send-GuardianHealthReportToNexus98Bridge | Out-Null
        $d = Invoke-GuardianBridgeDispatch
        $d.processed | Should BeGreaterThan 0
        $completed = Join-Path (Join-Path $root 'communication') 'completed'
        (@(Get-ChildItem -Path $completed -File -ErrorAction SilentlyContinue).Count) | Should BeGreaterThan 0
    }
    It 'governance produces a decision for an inbound Nexus98 request' {
        Initialize-GuardianBridge | Out-Null
        $m = Receive-Nexus98AnalysisRequestBridge -AnalysisKind 'storage' -RiskLevel 'low'
        $g = Invoke-GuardianBridgeGovernance -Message $m
        $g.decision | Should Not BeNullOrEmpty
        @('ALLOW','ALLOW_WITH_MONITORING','REQUIRE_CHECKPOINT','REQUIRE_REVIEW','BLOCK') -contains $g.decision | Should Be $true
    }
}

Describe 'Security' {
    It 'blocks an unknown sender at send time' {
        $m = New-GuardianBridgeMessage -Sender 'RogueAI' -Receiver Nexus98 -MessageType SYSTEM_HEALTH_REPORT -Content @{}
        $r = Send-GuardianBridgeMessage -Message $m
        $r.accepted | Should Be $false
    }
    It 'blocks an unauthorized action' {
        $m = New-GuardianBridgeMessage -Sender Nexus98 -Receiver Guardian -MessageType ANALYSIS_REQUEST `
            -Content @{} -RiskLevel 'high' -PermissionRequired $true -AuthorizationStatus 'NONE'
        $r = Receive-GuardianBridgeMessage -Message $m
        $r.accepted | Should Be $false
    }
}

Describe 'Observability' {
    It 'computes a communication health score' {
        $h = Get-GuardianCommunicationHealth
        ($h.healthScore -ge 0) | Should Be $true
        ($h.healthScore -le 100) | Should Be $true
        $h.enabled | Should Be $true
    }
}

Describe 'Bridge Disable Safety' {
    It 'refuses to send when the bridge is disabled' {
        Set-GuardianBridgeEnabled -Enabled $false | Out-Null
        $m = New-GuardianBridgeMessage -Sender Guardian -Receiver Nexus98 -MessageType SYSTEM_HEALTH_REPORT -Content @{}
        $r = Send-GuardianBridgeMessage -Message $m
        $r.accepted | Should Be $false
        Set-GuardianBridgeEnabled -Enabled $true | Out-Null
    }
}

Describe 'Integration - Import Check' {
    It 'all M8 modules loaded' {
        (Get-Command Send-GuardianBridgeMessage -ErrorAction SilentlyContinue) | Should Not BeNullOrEmpty
        (Get-Command Invoke-GuardianBridgeDispatch -ErrorAction SilentlyContinue) | Should Not BeNullOrEmpty
        (Get-Command Test-GuardianBridgeSecurity -ErrorAction SilentlyContinue) | Should Not BeNullOrEmpty
        (Get-Command Get-GuardianCommunicationHealth -ErrorAction SilentlyContinue) | Should Not BeNullOrEmpty
    }
}
