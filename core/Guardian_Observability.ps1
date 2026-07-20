# Guardian Observability Engine (M3 P4).
# Combines events, memory, health, storage, checkpoints into one model.

function Get-GuardianObservability {
    $health = Get-GuardianHealthScore
    $storage = Get-GuardianStorageHealth
    $mem = Get-GuardianMemorySummary
    $evts = @(Get-GuardianEvents)
    $sevCounts = $evts | Group-Object severity | ForEach-Object { @{ severity=$_.Name; count=$_.Count } }
    $rollbacks = @(Get-GuardianCheckpoints -Tier rolling).Count
    $milestones = @(Get-GuardianCheckpoints -Tier milestones).Count

    $model = @{
        timestamp=(Get-Date).ToString('o')
        health=@{
            runtimePct=$health.runtimePct
            architecturePct=$health.architecturePct
            storageHygienePct=$health.storageHygienePct
            overallPct=$health.overallPct
            source='Guardian_Health'
            confidence=0.9
            explanation='Composite of subsystem coverage and storage hygiene.'
        }
        storage=@{
            overallPct=$storage.overallPct
            directoryStructurePct=$storage.directoryStructurePct
            artifactHygienePct=$storage.artifactHygienePct
            growthControlPct=$storage.growthControlPct
            duplicateRiskPct=$storage.duplicateRiskPct
            source='Guardian_StorageIntelligence'
            confidence=0.85
            explanation='Driven by snapshot accumulation and directory structure.'
        }
        memory=@{
            total=$mem.total
            avgConfidence=$mem.avgConfidence
            source='Guardian_Memory'
            confidence=if($mem.total -gt 0){0.7}else{0.3}
            explanation=if($mem.total -gt 0){'Operational memory populated.'}else{'No memory entries yet.'}
        }
        checkpoints=@{
            rolling=$rollbacks
            milestones=$milestones
            source='Guardian_Checkpoint'
            confidence=1.0
            explanation='Recovery capability available.'
        }
        events=@{
            total=$evts.Count
            bySeverity=$sevCounts
            source='Guardian_Events'
            explanation='Structured event history.'
        }
    }
    $model['overallPct'] = [math]::Round(($model.health.overallPct*0.4)+($model.storage.overallPct*0.4)+($model.memory.avgConfidence*100*0.2),1)
    return $model
}

function Get-GuardianHealthReport {
    $m = Get-GuardianObservability
    return [PSCustomObject]@{
        runtime=$m.health.runtimePct
        memory=$m.memory.avgConfidence*100
        storage=$m.storage.overallPct
        recovery=if($m.checkpoints.milestones -gt 0){100}else{0}
        overall=$m.overallPct
    }
}
