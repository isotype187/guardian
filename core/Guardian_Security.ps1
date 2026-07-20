# Guardian Security Layer (M4).
# Monitors configuration/permission integrity and emits SECURITY events.
# Detection + audit only; enforcement is a later (gated) capability.

$GuardianSecurityBaseline = Join-Path $GuardianEnv.Data 'security_baseline.json'

function Save-GuardianSecurityBaseline {
    param([string[]]$Paths=@((Join-Path $GuardianEnv.Root 'core'), (Join-Path $GuardianEnv.Root 'config')))
    $hashes = @{}
    foreach ($p in $Paths) {
        if (-not (Test-Path $p)) { continue }
        Get-ChildItem -Path $p -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            try { $hashes[$_.FullName] = (Get-FileHash $_.FullName -Algorithm SHA256).Hash }
            catch { }
        }
    }
    $payload = @{ captured=(Get-Date).ToString('o'); paths=$Paths; hashes=$hashes }
    $payload | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianSecurityBaseline -Encoding UTF8
    return $payload
}

function Get-GuardianSecurityDrift {
    param([string[]]$Paths=@((Join-Path $GuardianEnv.Root 'core'), (Join-Path $GuardianEnv.Root 'config')))
    if (-not (Test-Path $GuardianSecurityBaseline)) { return @{ available=$false; note='no baseline' } }
    $base = Get-Content -Path $GuardianSecurityBaseline -Encoding UTF8 | ConvertFrom-Json
    $baseHashes = @{}
    $base.paths | ForEach-Object { } # paths kept for reference
    # Rebuild hash table from JSON (keys may deserialize as PSCustomObject).
    $baseHashes = @{}
    $base.hashes.PSObject.Properties | ForEach-Object { $baseHashes[$_.Name] = $_.Value }

    $current = @{}
    foreach ($p in $Paths) {
        if (-not (Test-Path $p)) { continue }
        Get-ChildItem -Path $p -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            try { $current[$_.FullName] = (Get-FileHash $_.FullName -Algorithm SHA256).Hash }
            catch { }
        }
    }

    $modified = @(); $added = @(); $removed = @()
    foreach ($k in $baseHashes.Keys) {
        if (-not $current.ContainsKey($k)) { $removed += $k }
        elseif ($current[$k] -ne $baseHashes[$k]) { $modified += $k }
    }
    foreach ($k in $current.Keys) { if (-not $baseHashes.ContainsKey($k)) { $added += $k } }

    $events = @()
    foreach ($m in $modified) { $events += New-GuardianEvent -Source 'security' -Category SECURITY -Severity WARNING -Description "UNEXPECTED_MODIFICATION: $m" -AffectedComponent $m }
    foreach ($a in $added) { $events += New-GuardianEvent -Source 'security' -Category SECURITY -Severity INFO -Description "NEW_ARTIFACT: $a" -AffectedComponent $a }
    foreach ($r in $removed) { $events += New-GuardianEvent -Source 'security' -Category SECURITY -Severity WARNING -Description "REMOVED_ARTIFACT: $r" -AffectedComponent $r }

    return @{ available=$true; modified=$modified; added=$added; removed=$removed; events=$events }
}

function Get-GuardianSecurityPosture {
    $drift = Get-GuardianSecurityDrift
    $integrity = Get-GuardianIntegrityEvents
    $score = if ($drift.available -and $drift.modified.Count -eq 0 -and $drift.removed.Count -eq 0) { 100.0 } else { 70.0 }
    return @{
        scorePct=$score
        baselineAvailable=$drift.available
        modifiedCount=$(if($drift.available){$drift.modified.Count}else{0})
        integrityEvents=$integrity.Count
        timestamp=(Get-Date).ToString('o')
    }
}
