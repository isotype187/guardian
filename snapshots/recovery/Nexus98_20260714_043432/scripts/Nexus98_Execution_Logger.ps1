# ============================================================
# Nexus98 Execution Logger v1.0
# ============================================================

param(
    [string]$CommandName,
    [string]$ScriptName,
    [string]$Output,
    [int]$ExitCode
)


$LogDir = "D:\Nexus98_Toolkit\logs"

New-Item `
-ItemType Directory `
-Force `
-Path $LogDir | Out-Null


$LogFile = "$LogDir\execution_history.log"


$Result = if($ExitCode -eq 0)
{
    "SUCCESS"
}
else
{
    "FAILED"
}


@"

================================================
Nexus98 Execution Record
================================================

Time:
$(Get-Date)

Command:
$CommandName

Script:
$ScriptName

Result:
$Result

Exit Code:
$ExitCode

Output:
$Output

================================================

"@ | Add-Content $LogFile


Write-Host "Execution logged."

