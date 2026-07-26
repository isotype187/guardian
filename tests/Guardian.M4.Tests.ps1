# Pester tests for Guardian M4 Resource / Agents / Security.

BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
}

Describe 'Resource Management' {
    It 'captures a resource snapshot with cpu/memory' {
        $s = Get-GuardianResourceSnapshot
        $s.cpuLoadPct | Should -Not -BeNullOrEmpty
        $s.memoryUsedPct | Should -Not -BeNullOrEmpty
    }
    It 'returns a structured anomaly result' {
        $a = Get-GuardianResourceAnomalies
        $a.snapshot | Should -Not -BeNullOrEmpty
        ($a.anomalies -is [System.Array]) | Should -Be $true
        (@($a.anomalies).Count -ge 0) | Should -Be $true
    }
    It 'lists top process consumers' {
        $p = Get-GuardianProcessLoad
        $p.byCpu | Should -Not -BeNullOrEmpty
    }
    It 'saves a resource baseline' {
        Save-GuardianResourceBaseline | Out-Null
        Test-Path (Join-Path $GuardianEnv.Data 'resource_baseline.json') | Should -Be $true
    }
}

Describe 'Agent Coordination' {
    It 'registers an agent with required fields' {
        $a = Register-GuardianAgent -AgentId 'm4-agent' -Purpose 'test' -Capabilities @('x')
        $a.agent_id | Should -Be 'm4-agent'
        $a.health_state | Should -Be 'active'
        ($a.capabilities -contains 'x') | Should -Be $true
    }
    It 'retrieves a registered agent' {
        $a = Get-GuardianAgent -AgentId 'm4-agent'
        $a.agent_id | Should -Be 'm4-agent'
    }
    It 'updates agent health' {
        Update-GuardianAgentHealth -AgentId 'm4-agent' -HealthState 'active' -Activity 'tick' | Out-Null
        (Get-GuardianAgent -AgentId 'm4-agent').last_seen | Should -Not -BeNullOrEmpty
    }
    It 'supervises registered agents' {
        $s = Get-GuardianAgentSupervision
        $s.agents | Should -BeGreaterThan 0
    }
    It 'summarizes the registry' {
        (Get-GuardianAgentRegistrySummary).total | Should -BeGreaterThan 0
    }
}

Describe 'Security Layer' {
    It 'saves a security baseline' {
        Save-GuardianSecurityBaseline | Out-Null
        Test-Path (Join-Path $GuardianEnv.Data 'security_baseline.json') | Should -Be $true
    }
    It 'reports security posture with a score' {
        $p = Get-GuardianSecurityPosture
        $p.scorePct | Should -BeGreaterThan 0
        $p.baselineAvailable | Should -Be $true
    }
    It 'detects drift against baseline' {
        $d = Get-GuardianSecurityDrift
        $d.available | Should -Be $true
    }
}

Describe 'Integration - Import Check' {
    It 'all M4 modules loaded' {
        (Get-Command Get-GuardianResourceSnapshot -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Register-GuardianAgent -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Get-GuardianSecurityPosture -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }
}