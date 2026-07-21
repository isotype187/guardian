# ============================================================
# Nexus98 Recovery Manager v1.0
# Snapshot and Recovery System
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

$Toolkit = "D:\Nexus98_Toolkit"
$Project = "D:\AI_Model_Hub"

$SnapshotRoot = "$Toolkit\snapshots"

$Folders = @(
"$SnapshotRoot",
"$SnapshotRoot\permanent",
"$SnapshotRoot\recovery",
"$SnapshotRoot\temp",
"$Toolkit\logs"
)

foreach($Folder in $Folders)
{
    New-Item `
    -ItemType Directory `
    -Force `
    -Path $Folder | Out-Null
}


$Time = Get-Date -Format "yyyy-MM-dd_HHmmss"

$Snapshot = "$SnapshotRoot\recovery\Snapshot_$Time"

New-Item `
-ItemType Directory `
-Force `
-Path $Snapshot | Out-Null


$Log = "$Toolkit\logs\Recovery_Manager.log"


function Capture($Name,$Command)
{
    $Path = "$Snapshot\$Name.txt"

    Invoke-Expression $Command |
    Out-String |
    Set-Content $Path
}


# ------------------------------------------------------------
# System Capture
# ------------------------------------------------------------

Capture `
"System_Info" `
"Get-ComputerInfo | Select WindowsProductName,WindowsVersion,OsBuildNumber"


Capture `
"Hardware" `
"Get-CimInstance Win32_VideoController | Select Name"


Capture `
"Disk_Info" `
"Get-PSDrive"



# ------------------------------------------------------------
# Project Capture
# ------------------------------------------------------------

if(Test-Path $Project)
{
    Copy-Item `
    $Project `
    "$Snapshot\AI_Model_Hub" `
    -Recurse `
    -Force
}



# ------------------------------------------------------------
# Continue
# ------------------------------------------------------------

if(Test-Path "$env:USERPROFILE\.continue")
{
    Copy-Item `
    "$env:USERPROFILE\.continue" `
    "$Snapshot\Continue" `
    -Recurse `
    -Force
}



# ------------------------------------------------------------
# Ollama
# ------------------------------------------------------------

Capture `
"Ollama_Models" `
"ollama list"



# ------------------------------------------------------------
# Python
# ------------------------------------------------------------

Capture `
"Python_Packages" `
"python -m pip list"



# ------------------------------------------------------------
# Git
# ------------------------------------------------------------

if(Test-Path "$Project\.git")
{
    Push-Location $Project

    git status |
    Out-File "$Snapshot\Git_Status.txt"

    git branch |
    Out-File "$Snapshot\Git_Branches.txt"

    Pop-Location
}



# ------------------------------------------------------------
# Log
# ------------------------------------------------------------

@"
================================================
Nexus98 Recovery Snapshot Created

Date:
$(Get-Date)

Location:
$Snapshot

================================================
"@ | Add-Content $Log



Write-Host ""
Write-Host "Recovery snapshot created:"
Write-Host $Snapshot -ForegroundColor Green

