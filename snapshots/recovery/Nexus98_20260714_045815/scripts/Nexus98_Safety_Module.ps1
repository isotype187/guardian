# ============================================================
# Nexus98 Safety Module
# Shared Safe Command Runner
# ============================================================

$NexusLogFolder = "D:\Nexus98_Toolkit\logs"

New-Item `
-ItemType Directory `
-Force `
-Path $NexusLogFolder | Out-Null


$NexusLog = "$NexusLogFolder\Safety_$(Get-Date -Format yyyy-MM-dd).log"



function Write-NexusLog($Message)
{
    Add-Content `
    -Path $NexusLog `
    -Value "$(Get-Date) : $Message"
}



function Invoke-SafeCommand
{
    param(
        [string]$Name,
        [string]$Command,
        [int]$TimeoutSeconds = 15
    )


    Write-NexusLog "Starting: $Name"


    try
    {

        $Job = Start-Job -ScriptBlock {

            param($Command)

            Invoke-Expression $Command

        } -ArgumentList $Command



        $Finished = Wait-Job `
        $Job `
        -Timeout $TimeoutSeconds



        if($Finished)
        {
            $Result = Receive-Job $Job

            Remove-Job $Job -Force

            Write-NexusLog "Completed: $Name"

            return $Result
        }
        else
        {
            Stop-Job $Job
            Remove-Job $Job -Force

            Write-NexusLog "TIMEOUT: $Name"

            return "[TIMEOUT]"
        }

    }
    catch
    {
        Write-NexusLog "FAILED: $Name"

        return "[FAILED]"
    }
}



function Test-NexusPath
{
    param(
        [string]$Name,
        [string]$Path
    )


    if(Test-Path $Path)
    {
        Write-NexusLog "FOUND: $Name"
        return $true
    }
    else
    {
        Write-NexusLog "MISSING: $Name"
        return $false
    }
}



Write-NexusLog "Safety Module Loaded"

