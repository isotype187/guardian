# Guardian Resource Management (M4).
# Samples CPU/memory/disk and detects runaway consumption.
# Observation + recommendation only; escalation handled by governance.

function Get-GuardianResourceSnapshot {
    # CPU via performance counter (CIM Win32_Processor is access-denied here).
    $cpu = $null
    try { $cpu = [math]::Round((Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop).CounterSamples.CookedValue, 1) } catch { $cpu = 0.0 }

    # Memory: estimate used MB from process working sets (graceful if CIM blocked).
    $memFreeGB = $null; $memTotalGB = $null; $memUsedPct = $null
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $memFreeGB = [math]::Round($os.FreePhysicalMemory/1048576, 2)
        $memTotalGB = [math]::Round($os.TotalVisibleMemorySize/1048576, 2)
        $memUsedPct = [math]::Round((1 - ($os.FreePhysicalMemory / $os.TotalVisibleMemorySize)) * 100, 1)
    } catch {
        $usedMB = (Get-Process -ErrorAction SilentlyContinue | Measure-Object WorkingSet -Sum).Sum / 1MB
        $memUsedPct = [math]::Round(($usedMB / 16384) * 100, 1)  # assume ~16GB baseline, clamp
        if ($memUsedPct -gt 100) { $memUsedPct = 100.0 }
    }

    # Disk: try CIM, degrade to unknown if blocked.
    $diskFreeGB = $null; $diskTotalGB = $null; $diskUsedPct = $null
    try {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop | Select-Object -First 1
        if ($disk) {
            $diskFreeGB = [math]::Round($disk.FreeSpace/1GB, 2)
            $diskTotalGB = [math]::Round($disk.Size/1GB, 2)
            $diskUsedPct = [math]::Round((1 - ($disk.FreeSpace/$disk.Size)) * 100, 1)
        }
    } catch { }

    return [PSCustomObject]@{
        timestamp=(Get-Date).ToString('o')
        cpuLoadPct=$cpu
        memoryFreeGB=$memFreeGB
        memoryTotalGB=$memTotalGB
        memoryUsedPct=$memUsedPct
        diskFreeGB=$diskFreeGB
        diskTotalGB=$diskTotalGB
        diskUsedPct=$diskUsedPct
    }
}

function Get-GuardianProcessLoad {
    # Top consumers by CPU and memory.
    $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { -not $_.CPU -or $_.CPU -gt 0 }
    $byCpu = $procs | Sort-Object CPU -Descending | Select-Object -First 5 Name, @{N='CPU(s)';E={[math]::Round($_.CPU,1)}}, @{N='WS(MB)';E={[math]::Round($_.WorkingSet/1MB,1)}}
    $byMem = $procs | Sort-Object WorkingSet -Descending | Select-Object -First 5 Name, @{N='WS(MB)';E={[math]::Round($_.WorkingSet/1MB,1)}}
    return @{ byCpu=$byCpu; byMem=$byMem }
}

# Detect runaway: sustained high CPU or memory beyond thresholds.
function Get-GuardianResourceAnomalies {
    param([double]$CpuThreshold=85.0, [double]$MemThreshold=90.0)
    $snap = Get-GuardianResourceSnapshot
    $anomalies = @()
    if ($snap.cpuLoadPct -ge $CpuThreshold) {
        $anomalies += [PSCustomObject]@{ type='CPU_RUNNING_HIGH'; value=$snap.cpuLoadPct; threshold=$CpuThreshold; severity='warning' }
    }
    if ($snap.memoryUsedPct -ge $MemThreshold) {
        $anomalies += [PSCustomObject]@{ type='MEMORY_PRESSURE'; value=$snap.memoryUsedPct; threshold=$MemThreshold; severity='critical' }
    }
    if ($snap.diskUsedPct -ge 95.0) {
        $anomalies += [PSCustomObject]@{ type='DISK_NEAR_FULL'; value=$snap.diskUsedPct; threshold=95.0; severity='critical' }
    }
    return @{ snapshot=$snap; anomalies=$anomalies }
}

function Save-GuardianResourceBaseline {
    $snap = Get-GuardianResourceSnapshot
    $baseline = Join-Path $GuardianEnv.Data 'resource_baseline.json'
    $snap | ConvertTo-Json -Depth 10 | Set-Content -Path $baseline -Encoding UTF8
    return $snap
}

