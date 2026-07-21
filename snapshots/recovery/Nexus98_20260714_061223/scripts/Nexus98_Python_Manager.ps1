# ============================================================
# Nexus98 Python Manager v1.0
# Controlled Python Resolver
# ============================================================

$ErrorActionPreference = "Continue"


$ConfigFile = "D:\Nexus98_Toolkit\config\python_config.json"


$Candidates = @(
    @{
        Name = "AI_Model_Hub Virtual Environment"
        Path = "D:\AI_Model_Hub\.venv\Scripts\python.exe"
    },

    @{
        Name = "System Python"
        Path = "C:\Python314\python.exe"
    },

    @{
        Name = "PATH Python"
        Path = (Get-Command python -ErrorAction SilentlyContinue).Source
    }
)



$Selected = $null


foreach($Candidate in $Candidates)
{
    if($Candidate.Path -and (Test-Path $Candidate.Path))
    {
        $Selected = $Candidate
        break
    }
}



if($null -eq $Selected)
{
    Write-Host ""
    Write-Host "No valid Python installation found." -ForegroundColor Red
    exit 1
}



$Python = $Selected.Path


$Version = & $Python --version 2>&1


$PipCheck = & $Python -m pip --version 2>&1


$State = @{
    selected = $Selected.Name
    python_path = $Python
    version = "$Version"
    pip_status = "$PipCheck"
    checked = "$(Get-Date)"
}



$State |
ConvertTo-Json -Depth 5 |
Set-Content `
-Encoding UTF8 `
$ConfigFile



Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Python Manager"
Write-Host "================================="

Write-Host ""
Write-Host "Selected:"
Write-Host $Selected.Name -ForegroundColor Green

Write-Host ""
Write-Host "Python:"
Write-Host $Python

Write-Host ""
Write-Host "Version:"
Write-Host $Version

Write-Host ""
Write-Host "Pip:"
Write-Host $PipCheck

Write-Host ""
Write-Host "Saved:"
Write-Host $ConfigFile

