# Pester tests for Guardian M2 Event + Storage Intelligence.
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
. (Join-Path $root 'core\Guardian_Loader.ps1')
Import-Guardian -Root $root

Describe 'Event Intelligence - Event Model' {
    $e = $null
    It 'creates a structured event with required fields' {
        $e = New-GuardianEvent -Source 'test' -Category SYSTEM -Severity INFO -Description 'startup'
        $e.event_id | Should Match '^EV_'
        $e.category | Should Be 'SYSTEM'
        $e.severity | Should Be 'INFO'
        $e.resolution_status | Should Be 'open'
    }
    It 'validates category enum' {
        { New-GuardianEvent -Source 'x' -Category BOGUS -Severity INFO -Description 'y' } | Should Throw
    }
    It 'validates severity enum' {
        { New-GuardianEvent -Source 'x' -Category SYSTEM -Severity BOGUS -Description 'y' } | Should Throw
    }
}

Describe 'Event Intelligence - Storage and Retrieval' {
    It 'persists an event and reads it back' {
        $before = @(Get-GuardianEvents).Count
        $ev = New-GuardianEvent -Source 'test' -Category GOVERNANCE -Severity WARNING -Description 'blocked action'
        Write-GuardianEvent -Event $ev
        @(Get-GuardianEvents).Count | Should BeGreaterThan $before
    }
    It 'filters by category' {
        $ev = New-GuardianEvent -Source 'test' -Category SECURITY -Severity ERROR -Description 'perm change'
        Write-GuardianEvent -Event $ev
        @(Get-GuardianEvents -Category SECURITY).Count | Should BeGreaterThan 0
    }
    It 'filters by severity' {
        @(Get-GuardianEvents -Severity ERROR).Count | Should BeGreaterThan 0
    }
}

Describe 'Event Intelligence - Rotation and De-duplication' {
    It 'detects duplicate events within window' {
        $d1 = New-GuardianEvent -Source 'dupsrc' -Category SYSTEM -Severity INFO -Description 'repeated signal'
        $d2 = New-GuardianEvent -Source 'dupsrc' -Category SYSTEM -Severity INFO -Description 'repeated signal'
        Write-GuardianEvent -Event $d1
        Write-GuardianEvent -Event $d2
        $d = Get-GuardianEventDuplicates -WindowMinutes 60
        @($d).Count | Should BeGreaterThan 0
    }
    It 'rotates old events into archive' {
        $r = Invoke-GuardianEventRotation -KeepDays 0
        $r | Should Not BeNullOrEmpty
    }
}

Describe 'Storage Intelligence - Classification' {
    It 'classifies managed paths' {
        (Get-GuardianArtifactClass (Join-Path $GuardianEnv.Root 'core\x.ps1')) | Should Be 'ACTIVE'
        (Get-GuardianArtifactClass (Join-Path $GuardianEnv.Root 'logs\x.log')) | Should Be 'OBSOLETE'
        (Get-GuardianArtifactClass (Join-Path $GuardianEnv.Root 'archive\x')) | Should Be 'ARCHIVE'
    }
    It 'classifies unmanaged path as UNKNOWN' {
        (Get-GuardianArtifactClass (Join-Path $GuardianEnv.Root 'mystery\y.bin')) | Should Be 'UNKNOWN'
    }
}

Describe 'Storage Intelligence - Health Score' {
    It 'computes storage health with components' {
        $h = Get-GuardianStorageHealth
        $h.overallPct | Should BeGreaterThan 0
        $h.directoryStructurePct | Should Not BeNullOrEmpty
        $h.duplicateRiskPct | Should Not BeNullOrEmpty
        $h.growthControlPct | Should Not BeNullOrEmpty
        $h.artifactHygienePct | Should Not BeNullOrEmpty
    }
}

Describe 'Storage Intelligence - Scanning' {
    It 'detects nested folder drift' {
        $n = Get-GuardianNestedDrift -DepthThreshold 6
        $n | Should Not BeNullOrEmpty
    }
    It 'detects duplicate content groups' {
        $tmp = Join-Path $env:TEMP ("dupscan_" + [guid]::NewGuid().ToString('N').Substring(0,8))
        New-Item -ItemType Directory -Force -Path $tmp | Out-Null
        "identical-content" | Set-Content (Join-Path $tmp 'a.txt') -Encoding UTF8
        "identical-content" | Set-Content (Join-Path $tmp 'b.txt') -Encoding UTF8
        $g = Get-GuardianDuplicateGroups -Path $tmp
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        @($g).Count | Should BeGreaterThan 0
    }
}

Describe 'Storage Intelligence - Growth Analysis' {
    It 'captures and compares a baseline' {
        Save-GuardianStorageBaseline | Out-Null
        $g = Get-GuardianStorageGrowth
        $g.available | Should Be $true
        $g.deltaMB | Should Not BeNullOrEmpty
    }
}

Describe 'Integration - Import Check' {
    It 'all M2 modules loaded' {
        (Get-Command New-GuardianEvent -ErrorAction SilentlyContinue) | Should Not BeNullOrEmpty
        (Get-Command Get-GuardianStorageHealth -ErrorAction SilentlyContinue) | Should Not BeNullOrEmpty
        (Get-Command Get-GuardianNestedDrift -ErrorAction SilentlyContinue) | Should Not BeNullOrEmpty
    }
}

