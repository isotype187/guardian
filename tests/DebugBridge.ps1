BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
}

Describe 'Debug Bridge State' {
    It 'checks bridge enabled state' {
        $enabled = $script:GuardianBridgeEnabled
        Write-Host "GuardianBridgeEnabled = $enabled"
        $enabled | Should -Be $true
    }
    It 'checks bridge root' {
        $root = $GuardianBridgeRoot
        Write-Host "GuardianBridgeRoot = $root"
        $root | Should -Not -BeNullOrEmpty
    }
    It 'tests security on valid message' {
        $m = New-GuardianBridgeMessage -Sender 'Guardian' -Receiver 'Nexus98' -MessageType 'SYSTEM_HEALTH_REPORT' -Content @{}
        $sec = Test-GuardianBridgeSecurity -Message $m
        Write-Host "Security passed: $($sec.passed)"
        Write-Host "Security reasons: $($sec.reasons -join ', ')"
        $sec.passed | Should -Be $true
    }
    It 'sends message and shows full result' {
        Initialize-GuardianBridge -Force | Out-Null
        $m = New-GuardianBridgeMessage -Sender 'Guardian' -Receiver 'Nexus98' -MessageType 'SYSTEM_HEALTH_REPORT' -Content @{}
        $r = Send-GuardianBridgeMessage -Message $m
        Write-Host "Send result: accepted=$($r.accepted), reason=$($r.reason), message_id=$($r.message_id)"
        $r | Should -Not -BeNullOrEmpty
    }
}