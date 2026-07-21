
# ============================================================
# Nexus98 Command Center v4
# Execution Logging Enabled
# ============================================================

param(
    [string]$Command = "check"
)


$Toolkit = "D:\Nexus98_Toolkit"

$Scripts = "$Toolkit\scripts"

$Logger = "$Scripts\Nexus98_Execution_Logger.ps1"

$StateManager = "$Scripts\Nexus98_State_Manager.ps1"



function Write-State
{
    param(
        [string]$Action
    )

    if(Test-Path $StateManager)
    {
        powershell `
        -ExecutionPolicy Bypass `
        -File $StateManager `
        $Action | Out-Null
    }
}



function Run-NexusScript
{
    param(
        [string]$Script
    )


    $Path = "$Scripts\$Script"


    if(!(Test-Path $Path))
    {
        Write-Host ""
        Write-Host "Missing:"
        Write-Host $Path -ForegroundColor Red
        return $false
    }


    Write-Host ""
    Write-Host "Running:"
    Write-Host $Script -ForegroundColor Cyan


    $Start = Get-Date


    $Output = powershell `
    -ExecutionPolicy Bypass `
    -File $Path `
    2>&1 |
    Tee-Object -Variable LiveOutput |
    ForEach-Object {
        Write-Host $_
    }

    $Output = $LiveOutput | Out-String


    $ExitCode = $LASTEXITCODE


    $Duration = (Get-Date) - $Start


    if(Test-Path $Logger)
    {
        powershell `
        -ExecutionPolicy Bypass `
        -File $Logger `
        -CommandName $Command `
        -ScriptName $Script `
        -Output $Output `
        -ExitCode $ExitCode | Out-Null
    }


    Write-Host ""
    Write-Host "Duration:"
    Write-Host $Duration.TotalSeconds "seconds"


    if($ExitCode -eq 0)
    {
        return $true
    }

    return $false
}



Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Command Center v4"
Write-Host " Command: $Command"
Write-Host "================================="



switch($Command)
{

"check"
{
    if(Run-NexusScript "Nexus98_System_Check.ps1")
    {
        Write-State "check"
    }

    break
}


"bootstrap"
{
    if(Run-NexusScript "Nexus98_Bootstrap.ps1")
    {
        Write-State "check"
    }

    break
}


"repair"
{
    if(Run-NexusScript "Nexus98_Repair_Engine.ps1")
    {
        Write-State "repair"
    }

    break
}


"snapshot"
{
    if(Run-NexusScript "Nexus98_Recovery_Manager.ps1")
    {
        Write-State "snapshot"
    }

    break
}


"status"
{
    powershell `
    -ExecutionPolicy Bypass `
    -File $StateManager `
    status

    break
}


default
{
    Write-Host ""
    Write-Host "Commands:"
    Write-Host " check"
    Write-Host " bootstrap"
    Write-Host " repair"
    Write-Host " snapshot"
    Write-Host " status"
}

}


Write-Host ""
Write-Host "Nexus98 operation complete."

