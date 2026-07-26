# Guardian Dependency Installation Module
# Separate from requirements.psd1 because .psd1 files can only contain data, not functions.

#requires -Version 7.4

<#
.SYNOPSIS
    Guardian Dependency Installation Module
.DESCRIPTION
    Provides functions to install and validate Guardian's pinned PowerShell module dependencies.
    Reads version pinning from requirements.psd1.
#>

$ErrorActionPreference = 'Stop'

function Install-GuardianDependencies {
    <#
    .SYNOPSIS
        Installs all Guardian required and optional modules with pinned versions.
    
    .PARAMETER IncludeOptional
        Also install optional modules (ThreadJob, PSReadLine).
    
    .PARAMETER Force
        Force reinstall even if module already present.
    
    .PARAMETER Scope
        Installation scope: CurrentUser or AllUsers.
    
    .EXAMPLE
        Install-GuardianDependencies
    
    .EXAMPLE
        Install-GuardianDependencies -IncludeOptional -Force
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeOptional,
        [switch]$Force,
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]$Scope = 'CurrentUser'
    )

    $requirementsPath = Join-Path $PSScriptRoot 'requirements.psd1'
    if (-not (Test-Path $requirementsPath)) {
        throw "Requirements file not found: $requirementsPath"
    }

    $data = Import-PowerShellDataFile -Path $requirementsPath

    $modules = $data.RequiredModules
    if ($IncludeOptional) {
        $modules += $data.OptionalModules
    }

    foreach ($module in $modules) {
        $params = @{
            Name               = $module.ModuleName
            RequiredVersion    = $module.RequiredVersion
            Repository         = $module.Repository
            Scope              = $Scope
            Force              = $Force
            ErrorAction        = 'Stop'
        }

        if ($module.MaximumVersion) {
            $params.MaximumVersion = $module.MaximumVersion
        }

        if ($data.CI.PinAllVersions -and -not $Force) {
            # In CI, only install exact version
            $params.RequiredVersion = $module.ModuleVersion
        }

        try {
            Write-Host "Installing $($module.ModuleName) $($module.RequiredVersion)..." -ForegroundColor Cyan
            Install-Module @params
            Write-Host "  ✓ $($module.ModuleName) installed" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install $($module.ModuleName): $($_.Exception.Message)"
            throw
        }
    }

    # Validate installation
    Validate-GuardianDependencies
}

function Validate-GuardianDependencies {
    <#
    .SYNOPSIS
        Validates that all required modules are installed at correct versions.
    
    .EXAMPLE
        Validate-GuardianDependencies
    #>

    $requirementsPath = Join-Path $PSScriptRoot 'requirements.psd1'
    $data = Import-PowerShellDataFile -Path $requirementsPath

    $allValid = $true

    foreach ($module in $data.RequiredModules) {
        $installed = Get-Module -ListAvailable -Name $module.ModuleName `
            | Where-Object { $_.Version -eq [version]$module.RequiredVersion }

        if (-not $installed) {
            Write-Error "REQUIRED MODULE MISSING: $($module.ModuleName) $($module.RequiredVersion)"
            $allValid = $false
        }
        else {
            Write-Host "  ✓ $($module.ModuleName) $($module.RequiredVersion)" -ForegroundColor Green
        }
    }

    if (-not $allValid) {
        throw "Dependency validation failed"
    }

    Write-Host "All required dependencies validated" -ForegroundColor Green
}

# Export functions for use in build scripts
Export-ModuleMember -Function Install-GuardianDependencies, Validate-GuardianDependencies