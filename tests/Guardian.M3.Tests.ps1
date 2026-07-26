# Pester tests for Guardian M3 Memory, Observability, Explanation.

BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
}

Describe 'Memory Intelligence - Creation' {
    It 'creates a memory entry with required fields' {
        $m = New-GuardianMemory -Source 'test' -Category long_term -Importance 'high' -Confidence 0.9 -Description 'milestone recovery'
        $m.memory_id | Should -Match '^MEM_'
        $m.category | Should -Be 'long_term'
        $m.importance | Should -Be 'high'
        $m.retention_class | Should -Be 'ACTIVE'
    }
    It 'validates category enum' {
        { New-GuardianMemory -Source 'x' -Category BOGUS -Importance 'low' -Description 'y' } | Should -Throw
    }
    It 'persists memory and retrieves it' {
        $before = @(Get-GuardianMemory).Count
        $m = New-GuardianMemory -Source 'test' -Category short_term -Importance 'medium' -Description 'active warning'
        Write-GuardianMemory -Memory $m
        @(Get-GuardianMemory).Count | Should -BeGreaterThan $before
    }
}

Describe 'Memory Intelligence - Retrieval and Classification' {
    It 'filters by category' {
        $m = New-GuardianMemory -Source 'test' -Category pattern -Importance 'low' -Description 'recurring pattern'
        Write-GuardianMemory -Memory $m
        @(Get-GuardianMemory -Category pattern).Count | Should -BeGreaterThan 0
    }
    It 'searches by query' {
        $m = New-GuardianMemory -Source 'searchtest' -Category long_term -Importance 'low' -Description 'recovery note for search'
        Write-GuardianMemory -Memory $m
        @(Search-GuardianMemory -Query 'recovery').Count | Should -BeGreaterThan 0
    }
    It 'summarizes memory' {
        $s = Get-GuardianMemorySummary
        $s.total | Should -BeGreaterThan 0
        $s.byCategory | Should -Not -BeNullOrEmpty
    }
}

Describe 'Memory Intelligence - Lifecycle and Cleanup' {
    It 'runs lifecycle with expiration' {
        $r = Invoke-GuardianMemoryLifecycle -MinImportance 0.0 -ShortTermMaxDays 0
        $r | Should -Not -BeNullOrEmpty
    }
    It 'compresses duplicate memories' {
        $merged = Compress-GuardianMemory
        $merged | Should -Not -BeNullOrEmpty
    }
}

Describe 'Pattern Recognition' {
    It 'detects recurring events as patterns' {
        $p = Get-GuardianPatterns -MinOccurrences 1
        @($p).Count | Should -BeGreaterThan 0
    }
    It 'emits recommendation text' {
        $p = Get-GuardianPatterns -MinOccurrences 1
        ($p | Select-Object -First 1).recommendation | Should -Not -BeNullOrEmpty
    }
}

Describe 'Observability and Health' {
    It 'builds combined observability model' {
        $o = Get-GuardianObservability
        $o.health | Should -Not -BeNullOrEmpty
        $o.storage | Should -Not -BeNullOrEmpty
        $o.memory | Should -Not -BeNullOrEmpty
        $o.checkpoints | Should -Not -BeNullOrEmpty
        $o.events | Should -Not -BeNullOrEmpty
        $o.overallPct | Should -BeGreaterThan 0
    }
    It 'produces a health report with components' {
        $h = Get-GuardianHealthReport
        $h.runtime | Should -Not -BeNullOrEmpty
        $h.memory | Should -Not -BeNullOrEmpty
        $h.storage | Should -Not -BeNullOrEmpty
        $h.recovery | Should -Not -BeNullOrEmpty
        $h.overall | Should -BeGreaterThan 0
    }
}

Describe 'Explanation Engine' {
    It 'produces structured WHAT/WHY/EVIDENCE/IMPACT/REC' {
        $e = Get-GuardianStorageExplanation
        $e.what | Should -Not -BeNullOrEmpty
        $e.why | Should -Not -BeNullOrEmpty
        $e.evidence | Should -Not -BeNullOrEmpty
        $e.impact | Should -Not -BeNullOrEmpty
        $e.recommendation | Should -Not -BeNullOrEmpty
    }
    It 'explains a governance decision' {
        $pr = Test-GuardianPolicy -ActionDescription 'x' -RiskLevel critical -CheckpointAvailable $true
        $d = Get-GuardianDecisionExplanation -PolicyResponse $pr
        $d.what | Should -Match 'decision'
    }
    It 'serializes an explanation' {
        $e = Get-GuardianStorageExplanation
        (Export-GuardianExplanation -Explanation $e).Length | Should -BeGreaterThan 0
    }
}

Describe 'Event-to-Memory and Storage-to-Memory Flows' {
    It 'event can seed a memory entry' {
        $ev = New-GuardianEvent -Source 'flow' -Category SECURITY -Severity ERROR -Description 'perm change for flow'
        Write-GuardianEvent -Event $ev
        $mem = New-GuardianMemory -Source 'event_flow' -Category short_term -Importance 'medium' -Description 'perm change for flow' -RelatedEvents @($ev.event_id)
        Write-GuardianMemory -Memory $mem
        @(Get-GuardianMemory -Source event_flow).Count | Should -BeGreaterThan 0
    }
    It 'storage health can seed a memory entry' {
        $sh = Get-GuardianStorageHealth
        $mem = New-GuardianMemory -Source 'storage_flow' -Category long_term -Importance 'high' -Description "storage overall $($sh.overallPct)%"
        Write-GuardianMemory -Memory $mem
        @(Get-GuardianMemory -Source storage_flow).Count | Should -BeGreaterThan 0
    }
}

Describe 'Nexus98 Communication Contracts (M3)' {
    It 'builds Guardian->Nexus98 health report' {
        $o = Get-GuardianObservability
        $r = New-GuardianToNexus98HealthReport -ObservabilityModel $o
        $r.type | Should -Be 'GUARDIAN_HEALTH_REPORT'
        $r.target | Should -Be 'Nexus98'
    }
    It 'builds Guardian->Nexus98 explanation' {
        $e = Get-GuardianStorageExplanation
        $r = New-GuardianToNexus98Explanation -Explanation $e
        $r.type | Should -Be 'GUARDIAN_EXPLANATION'
    }
    It 'builds Nexus98->Guardian task context' {
        $r = New-Nexus98ToGuardianTaskContext -TaskDescription 'analyze' -RequestedAnalysis @('storage')
        $r.type | Should -Be 'NEXUS98_TASK_CONTEXT'
    }
}

Describe 'Integration - Import Check' {
    It 'all M3 modules loaded' {
        (Get-Command New-GuardianMemory -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Get-GuardianObservability -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command New-GuardianExplanation -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Get-GuardianPatterns -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }
}


