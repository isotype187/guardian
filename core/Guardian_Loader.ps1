# Guardian Core Loader.
# Dot-source this file to load the full Guardian foundation into scope.
#   . ".\core\Guardian_Loader.ps1"
# Functions defined here land in the caller scope, so they persist.

$GuardianLoaderModules = @(
    'Guardian_Env.ps1',
    'Guardian_Contracts.ps1',
    'Guardian_Governance.ps1',
    'Guardian_Audit.ps1',
    'Guardian_Health.ps1',
    'Guardian_Checkpoint.ps1',
    'Guardian_Integrity.ps1',
    'Guardian_Recovery.ps1',
    'Guardian_Events.ps1',
    'Guardian_StorageIntelligence.ps1',
    'Guardian_Memory.ps1',
    'Guardian_Patterns.ps1',
    'Guardian_Observability.ps1',
    'Guardian_Explanation.ps1',
    'Guardian_Resource.ps1',
    'Guardian_Agents.ps1',
    'Guardian_Security.ps1',
    'Guardian_ActionPlanning.ps1',
    'Guardian_Remediation.ps1',
    'Guardian_GovernanceIntegration.ps1',
    'Guardian_Comms.ps1',
    'Guardian_DriftGuard.ps1',
    'Guardian_StorageRules.ps1',
    'Guardian_Bridge.ps1',
    'Guardian_EntropyRemediation.ps1',
    'Guardian_Operations.ps1'
)
function Import-Guardian {
    param([string]$Root)
    if (-not $Root) {
        $Root = if ($PSScriptRoot) {
            (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        } else {
            (Resolve-Path (Join-Path $PWD '..')).Path
        }
    }
    $core = Join-Path $Root 'core'
    foreach ($m in $GuardianLoaderModules) {
        $p = Join-Path $core $m
        if (Test-Path $p) { . $p }
    }
    if (Get-Command Initialize-GuardianEnvironment -ErrorAction SilentlyContinue) {
        Initialize-GuardianEnvironment | Out-Null
    }
}

function Get-GuardianStatus {
    $health = Get-GuardianHealthScore
    return New-GuardianHealthMessage -Component 'guardian_core' -Status 'healthy' -Warnings @()
}

# Auto-load when the loader itself is dot-sourced.
if ($MyInvocation.InvocationName -eq '.') {
    $GuardianLoaderRoot = if ($PSScriptRoot) {
        (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    } else {
        (Resolve-Path (Join-Path $PWD '..')).Path
    }
    foreach ($m in $GuardianLoaderModules) {
        $p = Join-Path $PSScriptRoot $m
        if (Test-Path $p) { . $p }
    }
    Initialize-GuardianEnvironment | Out-Null
}






