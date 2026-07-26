# Guardian M10 Tests - Continuous Operations Engine
# Tests scheduler functionality, heartbeat, Nexus98 bus consumer, acknowledgement,
# risk analysis, operational state, runtime config, and lifecycle management.

BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
}

Describe 'M10 Scheduler Engine' {
    BeforeEach {
        Remove-Item (Join-Path $GuardianEnv.Data 'ops') -Recurse -Force -ErrorAction SilentlyContinue
        Initialize-GuardianOperations | Out-Null
    }

    It 'initializes default jobs' {
        $jobs = Get-GuardianJob
        $jobs.Count | Should -Be 5
        $jobs | Where-Object { $_.name -eq 'HEALTH_SCAN' } | Should -Not -BeNullOrEmpty
        $jobs | Where-Object { $_.name -eq 'STORAGE_SCAN' } | Should -Not -BeNullOrEmpty
        $jobs | Where-Object { $_.name -eq 'EVENT_REVIEW' } | Should -Not -BeNullOrEmpty
        $jobs | Where-Object { $_.name -eq 'MEMORY_MAINTENANCE' } | Should -Not -BeNullOrEmpty
        $jobs | Where-Object { $_.name -eq 'CHECKPOINT_VALIDATION' } | Should -Not -BeNullOrEmpty
    }

    It 'registers a custom job' {
        $job = Register-GuardianJob -Name 'TEST_JOB' -IntervalSeconds 30 -Enabled $true -Description 'Test job'
        $job.name | Should -Be 'TEST_JOB'
        $job.intervalSeconds | Should -Be 30
        $job.enabled | Should -Be $true
        $job.description | Should -Be 'Test job'
    }

    It 'retrieves jobs by name' {
        Register-GuardianJob -Name 'SPECIFIC_JOB' -IntervalSeconds 45
        $job = Get-GuardianJob -Name 'SPECIFIC_JOB'
        $job.Count | Should -Be 1
        $job.name | Should -Be 'SPECIFIC_JOB'
        $job.intervalSeconds | Should -Be 45
    }

    It 'executes a default job' {
        $result = Invoke-GuardianJob -Name 'HEALTH_SCAN'
        $result.name | Should -Be 'HEALTH_SCAN'
        $result.status | Should -Be 'ok'
        $result.result | Should -Not -BeNullOrEmpty
        $result.result.healthOverall | Should -Not -BeNullOrEmpty
    }

    It 'handles job not found' {
        $result = Invoke-GuardianJob -Name 'NON_EXISTENT'
        $result.name | Should -Be 'NON_EXISTENT'
        $result.status | Should -Be 'not_found'
    }

    It 'runs scheduler cycle' {
        # Force jobs to be due by setting lastRun to null
        $jobs = Get-GuardianJob
        $result = Invoke-GuardianSchedulerCycle
        $result.cycleSummary.jobsRun | Should -BeGreaterThan 0
        $result.cycleResult | Should -BeIn @('ok', 'degraded')
        $result.lastCycle | Should -Not -BeNullOrEmpty
    }

    It 'updates job status after execution' {
        Invoke-GuardianJob -Name 'HEALTH_SCAN'
        $job = Get-GuardianJob -Name 'HEALTH_SCAN'
        $job.lastStatus | Should -Be 'ok'
        $job.lastRun | Should -Not -BeNullOrEmpty
    }
}

Describe 'M10 Heartbeat System' {
    BeforeEach {
        Remove-Item (Join-Path $GuardianEnv.Data 'ops') -Recurse -Force -ErrorAction SilentlyContinue
        Initialize-GuardianOperations | Out-Null
    }

    It 'generates heartbeat record' {
        $heartbeat = Invoke-GuardianHeartbeat
        $heartbeat.status | Should -Be 'ALIVE'
        $heartbeat.timestamp | Should -Not -BeNullOrEmpty
        $heartbeat.health | Should -Not -BeNullOrEmpty
        $heartbeat.active_jobs | Should -BeGreaterOrEqual 0
    }

    It 'persists heartbeat to log' {
        Invoke-GuardianHeartbeat
        $heartbeatLog = Join-Path $GuardianEnv.Data 'ops\heartbeat.jsonl'
        Test-Path $heartbeatLog | Should -Be $true
        $content = Get-Content $heartbeatLog -Raw
        $content | Should -Match 'ALIVE'
    }

    It 'retrieves last heartbeat status' {
        Invoke-GuardianHeartbeat
        $status = Get-GuardianHeartbeatStatus
        $status | Should -Not -BeNullOrEmpty
        $status.status | Should -Be 'ALIVE'
    }

    It 'includes warnings in heartbeat' {
        # Create a low health scenario by testing with missing checkpoints
        $heartbeat = Invoke-GuardianHeartbeat
        $warnings = $heartbeat.warnings
        $warnings.GetType().Name | Should -Be 'Object[]'
        # Warnings array may be empty if system is healthy
    }
}

Describe 'M10 Acknowledgement System' {
    BeforeEach {
        Remove-Item (Join-Path $GuardianEnv.Data 'ops') -Recurse -Force -ErrorAction SilentlyContinue
        Initialize-GuardianOperations | Out-Null
    }

    It 'adds acknowledgement record' {
        $ack = Add-GuardianAck -MessageId 'TEST_MSG_001' -Stage 'processed' -Note 'test processing'
        $ack.message_id | Should -Be 'TEST_MSG_001'
        $ack.stage | Should -Be 'processed'
        $ack.note | Should -Be 'test processing'
        $ack.timestamp | Should -Not -BeNullOrEmpty
    }

    It 'retrieves acknowledgements by message ID' {
        Add-GuardianAck -MessageId 'MSG_001' -Stage 'received'
        Add-GuardianAck -MessageId 'MSG_001' -Stage 'processed'
        Add-GuardianAck -MessageId 'MSG_002' -Stage 'completed'
        
        $acks = Get-GuardianAcks -MessageId 'MSG_001'
        $acks.Count | Should -Be 2
        $acks[0].message_id | Should -Be 'MSG_001'
        $acks[1].message_id | Should -Be 'MSG_001'
    }

    It 'retrieves recent acknowledgements' {
        Add-GuardianAck -MessageId 'MSG_A' -Stage 'received'
        Add-GuardianAck -MessageId 'MSG_B' -Stage 'processed'
        Add-GuardianAck -MessageId 'MSG_C' -Stage 'completed'
        
        $recent = Get-GuardianAcks -Last 2
        $recent.Count | Should -Be 2
    }
}

Describe 'M10 Risk Analysis' {
    BeforeEach {
        Remove-Item (Join-Path $GuardianEnv.Data 'ops') -Recurse -Force -ErrorAction SilentlyContinue
        Initialize-GuardianOperations | Out-Null
    }

    It 'performs risk analysis' {
        $risk = Invoke-GuardianRiskAnalysis
        $risk.timestamp | Should -Not -BeNullOrEmpty
        $risk.riskScore | Should -BeGreaterOrEqual 0
        $risk.riskScore | Should -BeLessOrEqual 100
        $risk.riskLevel | Should -BeIn @('low', 'medium', 'high')
        $factors = $risk.factors
        $factors.GetType().Name | Should -Be 'Object[]'
        $risk.recommendation | Should -Not -BeNullOrEmpty
    }

    It 'saves risk analysis to file' {
        Invoke-GuardianRiskAnalysis
        $riskFile = Join-Path $GuardianEnv.Data 'ops\risk_latest.json'
        Test-Path $riskFile | Should -Be $true
        $content = Get-Content $riskFile -Raw | ConvertFrom-Json
        $content.riskScore | Should -Not -BeNullOrEmpty
    }
}

Describe 'M10 Operational State' {
    BeforeEach {
        Remove-Item (Join-Path $GuardianEnv.Data 'ops') -Recurse -Force -ErrorAction SilentlyContinue
        Initialize-GuardianOperations | Out-Null
    }

    It 'generates operational state summary' {
        $state = Get-GuardianOperationalState
        $state.timestamp | Should -Not -BeNullOrEmpty
        $state.guardianHealth | Should -Not -BeNullOrEmpty
        $state.guardianHealth.overallPct | Should -Not -BeNullOrEmpty
        $state.nexus98Connection | Should -Not -BeNullOrEmpty
        $state.storageHealth | Should -Not -BeNullOrEmpty
        $state.memoryHealth | Should -Not -BeNullOrEmpty
        $state.eventStatus | Should -Not -BeNullOrEmpty
        $state.checkpointStatus | Should -Not -BeNullOrEmpty
        $state.schedulerStatus | Should -Not -BeNullOrEmpty
    }

    It 'persists operational state to file' {
        Get-GuardianOperationalState | Out-Null
        $stateFile = Join-Path $GuardianEnv.Data 'ops\operational_state.json'
        Test-Path $stateFile | Should -Be $true
        $content = Get-Content $stateFile -Raw | ConvertFrom-Json
        $content.guardianHealth | Should -Not -BeNullOrEmpty
    }
}

Describe 'M10 Runtime Configuration' {
    BeforeEach {
        Remove-Item (Join-Path $GuardianEnv.Data 'ops') -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $GuardianEnv.Config 'guardian_runtime_config.json') -Force -ErrorAction SilentlyContinue
        Initialize-GuardianOperations | Out-Null
    }

    It 'creates default runtime config' {
        $config = New-GuardianRuntimeConfig
        $config.version | Should -Be '1.0.0'
        $config.schedulerIntervals | Should -Not -BeNullOrEmpty
        $config.schedulerIntervals.HEALTH_SCAN | Should -Be 60
        $config.monitoringLevel | Should -Be 'standard'
        $config.retentionRules | Should -Not -BeNullOrEmpty
        $config.communication | Should -Not -BeNullOrEmpty
        $config.logging | Should -Not -BeNullOrEmpty
    }

    It 'validates runtime config' {
        $config = New-GuardianRuntimeConfig
        $result = Test-GuardianRuntimeConfig -Config $config
        $result.valid | Should -Be $true
        $result.errors.Count | Should -Be 0
    }

    It 'rejects invalid config' {
        $config = [PSCustomObject]@{
            schedulerIntervals = [PSCustomObject]@{ HEALTH_SCAN = -5 }  # Invalid negative interval
        }
        $result = Test-GuardianRuntimeConfig -Config $config
        $result.valid | Should -Be $false
        $result.errors.Count | Should -BeGreaterThan 0
    }

    It 'sets validated runtime config' {
        $config = New-GuardianRuntimeConfig
        $config.schedulerIntervals.HEALTH_SCAN = 45
        $result = Set-GuardianRuntimeConfigValidated -Config $config
        $result.updated | Should -Be $true
        $result.rejected | Should -Be $false
        
        $saved = Get-GuardianRuntimeConfig
        $saved.schedulerIntervals.HEALTH_SCAN | Should -Be 45
    }

    It 'syncs scheduler from config' {
        $config = New-GuardianRuntimeConfig
        $config.schedulerIntervals.HEALTH_SCAN = 90
        Set-GuardianRuntimeConfigValidated -Config $config | Out-Null
        
        Sync-GuardianSchedulerFromConfig | Should -Be $true
        $job = Get-GuardianJob -Name 'HEALTH_SCAN'
        $job.intervalSeconds | Should -Be 90
    }
}

Describe 'M10 Lifecycle Management' {
    BeforeEach {
        Remove-Item (Join-Path $GuardianEnv.Data 'ops') -Recurse -Force -ErrorAction SilentlyContinue
        Initialize-GuardianOperations | Out-Null
    }

    It 'starts operations' {
        $result = Start-GuardianOperations -MaxCycles 1
        $result.status | Should -Be 'running'
        $result.cyclesRun | Should -Be 1
    }

    It 'stops operations' {
        Start-GuardianOperations -MaxCycles 1 | Out-Null
        $result = Stop-GuardianOperations
        $result.status | Should -Be 'stopped'
        $result.stopped | Should -Not -BeNullOrEmpty
    }

    It 'gets operations status' {
        Start-GuardianOperations -MaxCycles 1 | Out-Null
        $status = Get-GuardianOperationsStatus
        $status.status | Should -Be 'running'
        $status.started | Should -Not -BeNullOrEmpty
    }

    It 'repairs operations state' {
        # Remove state files to simulate corruption
        Remove-Item (Join-Path $GuardianEnv.Data 'ops\scheduler_state.json') -Force -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $GuardianEnv.Data 'ops\runtime_state.json') -Force -ErrorAction SilentlyContinue
        
        $result = Repair-GuardianOperationsState
        $result.repaired.Count | Should -BeGreaterThan 0
        'scheduler_state_recreated' | Should -BeIn $result.repaired
        'runtime_state_recreated' | Should -BeIn $result.repaired
    }
}

Describe 'M10 Communication Bridge Integration' {
    BeforeEach {
        Remove-Item (Join-Path $GuardianEnv.Data 'ops') -Recurse -Force -ErrorAction SilentlyContinue
        Initialize-GuardianOperations | Out-Null
    }

    It 'sends risk report to Nexus98' {
        $result = Send-GuardianRiskReportToNexus98Bridge -RiskLevel 'medium' -Reason 'test risk scenario'
        $result.sent | Should -Be $true
        $result.message_id | Should -Match '^RISK_'
        $result.kind | Should -Be 'risk'
    }

    It 'sends checkpoint notice to Nexus98' {
        $result = Send-GuardianCheckpointNoticeToNexus98Bridge -CheckpointId 'TEST_CK_001' -Tier 'rolling' -Reason 'test checkpoint'
        $result.sent | Should -Be $true
        $result.message_id | Should -Match '^CKPT_'
        $result.kind | Should -Be 'checkpoint'
        $result.checkpointId | Should -Be 'TEST_CK_001'
    }

    It 'sends rollback notice to Nexus98' {
        $result = Send-GuardianRollbackNoticeToNexus98Bridge -CheckpointId 'TEST_CK_001' -Reason 'test rollback'
        $result.sent | Should -Be $true
        $result.message_id | Should -Match '^RBAC_'
        $result.kind | Should -Be 'rollback'
        $result.checkpointId | Should -Be 'TEST_CK_001'
    }
}

Describe 'M10 Health Explanation' {
    BeforeEach {
        Remove-Item (Join-Path $GuardianEnv.Data 'ops') -Recurse -Force -ErrorAction SilentlyContinue
        Initialize-GuardianOperations | Out-Null
    }

    It 'provides health explanation' {
        $explanation = Get-GuardianHealthExplanation
        $explanation.overallPct | Should -Not -BeNullOrEmpty
        $explanation.status | Should -BeIn @('healthy', 'degraded', 'critical')
        $explanation.reasons | Should -Not -BeNullOrEmpty
        $explanation.reasons.Count | Should -BeGreaterThan 0
    }
}

Describe 'M10 Storage Governance Integration' {
    BeforeEach {
        Remove-Item (Join-Path $GuardianEnv.Data 'ops') -Recurse -Force -ErrorAction SilentlyContinue
        Initialize-GuardianOperations | Out-Null
    }

    It 'performs storage governance review' {
        $result = Invoke-GuardianStorageGovernanceReview
        $result.findingsCount | Should -BeGreaterOrEqual 0
        $result.byCategory | Should -Not -BeNullOrEmpty
        $recommendations = $result.recommendations
        $recommendations.GetType().Name | Should -Be 'Object[]'
        $result.policy | Should -Not -BeNullOrEmpty
        $result.timestamp | Should -Not -BeNullOrEmpty
    }
}

Describe 'M10 Checkpoint Lifecycle Management' {
    BeforeEach {
        Remove-Item (Join-Path $GuardianEnv.Data 'ops') -Recurse -Force -ErrorAction SilentlyContinue
        Initialize-GuardianOperations | Out-Null
        # Create some test checkpoints
        New-GuardianCheckpoint -Tier rolling | Out-Null
        New-GuardianCheckpoint -Tier rolling | Out-Null
    }

    It 'manages checkpoint lifecycle' {
        $result = Invoke-GuardianCheckpointLifecycle -KeepRolling 1
        $result.rollingTotal | Should -BeGreaterOrEqual 1
        $result.keepRolling | Should -Be 1
        $result.recoveryReadiness | Should -Be 'ready'
        $result.timestamp | Should -Not -BeNullOrEmpty
    }

    It 'archives excess checkpoints when requested' {
        # Create more checkpoints than we want to keep
        New-GuardianCheckpoint -Tier rolling | Out-Null
        New-GuardianCheckpoint -Tier rolling | Out-Null
        
        $result = Invoke-GuardianCheckpointLifecycle -KeepRolling 1 -ArchiveExcess
        $result.rotated | Should -BeGreaterThan 0
    }
}