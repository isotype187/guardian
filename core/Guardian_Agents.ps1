# Guardian Agent Coordination (M4).
# Maintains an agent registry and supervises health. Coordination only;
# no autonomous pausing/isolation is executed here (governance gates that).

$GuardianAgentStore = Join-Path $GuardianEnv.Data 'agents'

function Register-GuardianAgent {
    param(
        [Parameter(Mandatory=$true)][string]$AgentId,
        [string]$Purpose='',
        [string[]]$Capabilities=@(),
        [string[]]$Limitations=@(),
        [string[]]$Permissions=@(),
        [string]$HealthState='active'
    )
    New-Item -ItemType Directory -Force -Path $GuardianAgentStore | Out-Null
    $file = Join-Path $GuardianAgentStore "$AgentId.json"
    $agent = @{
        agent_id=$AgentId
        purpose=$Purpose
        capabilities=$Capabilities
        limitations=$Limitations
        permissions=$Permissions
        health_state=$HealthState
        registered=(Get-Date).ToString('o')
        last_seen=(Get-Date).ToString('o')
        activity=@()
    }
    $agent | ConvertTo-Json -Depth 10 | Set-Content -Path $file -Encoding UTF8
    return $agent
}

function Get-GuardianAgent {
    param([string]$AgentId)
    if ($AgentId) {
        $f = Join-Path $GuardianAgentStore "$AgentId.json"
        if (Test-Path $f) { return Get-Content -Path $f -Encoding UTF8 | ConvertFrom-Json }
        return $null
    }
    if (-not (Test-Path $GuardianAgentStore)) { return @() }
    return Get-ChildItem -Path $GuardianAgentStore -File -Filter *.json | ForEach-Object { Get-Content -Path $_.FullName -Encoding UTF8 | ConvertFrom-Json }
}

function Update-GuardianAgentHealth {
    param([Parameter(Mandatory=$true)][string]$AgentId, [string]$HealthState='active', [string]$Activity='')
    $a = Get-GuardianAgent -AgentId $AgentId
    if (-not $a) { return $null }
    $a.health_state = $HealthState
    $a.last_seen = (Get-Date).ToString('o')
    if ($Activity) { $a.activity += @{ time=(Get-Date).ToString('o'); note=$Activity } }
    $file = Join-Path $GuardianAgentStore "$AgentId.json"
    $a | ConvertTo-Json -Depth 10 | Set-Content -Path $file -Encoding UTF8
    return $a
}

# Supervision: flag inactive / failed / conflicting agents (no action taken).
function Get-GuardianAgentSupervision {
    $agents = @(Get-GuardianAgent)
    $flags = @()
    foreach ($a in $agents) {
        $last = [datetime]::Parse($a.last_seen)
        $idle = ((Get-Date) - $last).TotalMinutes
        if ($a.health_state -eq 'failed') {
            $flags += [PSCustomObject]@{ agent_id=$a.agent_id; issue='AGENT_FAILED'; severity='error' }
        } elseif ($idle -gt 30) {
            $flags += [PSCustomObject]@{ agent_id=$a.agent_id; issue='AGENT_INACTIVE'; idleMinutes=[math]::Round($idle,0); severity='warning' }
        }
    }
    return @{ agents=$agents.Count; flags=$flags }
}

function Get-GuardianAgentRegistrySummary {
    $agents = @(Get-GuardianAgent)
    return @{
        total=$agents.Count
        active=($agents | Where-Object { $_.health_state -eq 'active' }).Count
        failed=($agents | Where-Object { $_.health_state -eq 'failed' }).Count
        timestamp=(Get-Date).ToString('o')
    }
}
