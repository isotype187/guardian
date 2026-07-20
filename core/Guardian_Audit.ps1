# Guardian Audit System.
# Every important Guardian action creates an append-only audit record.
# Records: who, what, why, when, previous state, new state, validation.

$GuardianAuditLog = Join-Path $GuardianEnv.Logs 'guardian_audit.jsonl'

function Write-GuardianAudit {
    param(
        [Parameter(Mandatory=$true)][string]$Action,
        [string]$Actor='guardian',
        [string]$Reason='',
        [object]$PreviousState=$null,
        [object]$NewState=$null,
        [string]$Validation='pending'
    )
    $record = @{
        action=$Action
        actor=$Actor
        reason=$Reason
        previousState=$PreviousState
        newState=$NewState
        validation=$Validation
        timestamp=(Get-Date).ToString('o')
    }
    $line = $record | ConvertTo-Json -Depth 10 -Compress
    Add-Content -Path $GuardianAuditLog -Value $line -Encoding UTF8
    return $record
}

function Get-GuardianAuditTrail {
    param([int]$Last=0)
    if (-not (Test-Path $GuardianAuditLog)) { return @() }
    $lines = Get-Content -Path $GuardianAuditLog -Encoding UTF8
    $records = $lines | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json }
    if ($Last -gt 0) { $records = $records | Select-Object -Last $Last }
    return $records
}

function Get-GuardianAuditSummary {
    $trail = Get-GuardianAuditTrail
    return @{
        total=$trail.Count
        byValidation=($trail | Group-Object validation | ForEach-Object { $_.Name=$_.Count } | ConvertTo-Json -Compress)
        lastTimestamp=if ($trail.Count -gt 0) { $trail[-1].timestamp } else { $null }
    }
}
