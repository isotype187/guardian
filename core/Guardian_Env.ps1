# Guardian environment contract.
# Single source of truth for Guardian root paths and configuration.
# Every Guardian module must dot-source this before touching the filesystem.

$GuardianRoot = if ($PSScriptRoot) { (Resolve-Path (Join-Path $PSScriptRoot '..')).Path } else { $PWD.Path }
if (-not (Test-Path $GuardianRoot)) { $GuardianRoot = 'D:\Nexus98_Guardian' }

$GuardianEnv = @{
    Root        = $GuardianRoot
    Core        = Join-Path $GuardianRoot 'core'
    Config      = Join-Path $GuardianRoot 'config'
    Data        = Join-Path $GuardianRoot 'data'
    Logs        = Join-Path $GuardianRoot 'logs'
    Reports     = Join-Path $GuardianRoot 'reports'
    Tests       = Join-Path $GuardianRoot 'tests'
    Plugins     = Join-Path $GuardianRoot 'plugins'
    Checkpoints = Join-Path $GuardianRoot 'data\checkpoints'
    Rolling     = Join-Path $GuardianRoot 'data\checkpoints\rolling'
    Milestones  = Join-Path $GuardianRoot 'data\checkpoints\milestones'
    Emergency   = Join-Path $GuardianRoot 'data\checkpoints\emergency'
    Archive     = Join-Path $GuardianRoot 'data\checkpoints\archive'
    Snapshots   = Join-Path $GuardianRoot 'snapshots'
    Reference   = 'D:\Nexus98'
    Version     = '0.1.0'
}

function Initialize-GuardianEnvironment {
    $dirs = @($GuardianEnv.Config, $GuardianEnv.Data, $GuardianEnv.Logs,
              $GuardianEnv.Reports, $GuardianEnv.Tests, $GuardianEnv.Plugins,
              $GuardianEnv.Rolling, $GuardianEnv.Milestones,
              $GuardianEnv.Emergency, $GuardianEnv.Archive)
    foreach ($d in $dirs) {
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
    }
    return $GuardianEnv
}
