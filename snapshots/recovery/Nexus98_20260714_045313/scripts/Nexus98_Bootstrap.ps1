
# ============================================================
# Nexus98 Python Resolver
# ============================================================

$PythonConfig = "D:\Nexus98_Toolkit\config\python_config.json"


if(Test-Path $PythonConfig)
{
    $PythonData = Get-Content `
    $PythonConfig `
    -Raw |
    ConvertFrom-Json

    $NexusPython = $PythonData.python_path
}
else
{
    $NexusPython = "D:\AI_Model_Hub\.venv\Scripts\python.exe"
}


if(!(Test-Path $NexusPython))
{
    Write-Host "Nexus98 Python environment missing:" -ForegroundColor Red
    Write-Host $NexusPython
}
else
{
    Write-Host "Nexus Python:"
    Write-Host $NexusPython -ForegroundColor Green
}

# ============================================================
# Nexus98 Bootstrap Engine v1.0
# Environment Initialization Check
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

$Toolkit = "D:\Nexus98_Toolkit"
$Project = "D:\AI_Model_Hub"

$ReportDir = "$Toolkit\reports"
$LogDir = "$Toolkit\logs"

New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$Time = Get-Date -Format "yyyy-MM-dd_HHmmss"

$Report = "$ReportDir\Bootstrap_$Time.txt"


function Write-Check($Name,$State)
{
    if($State)
    {
        Write-Host "[OK]   $Name" -ForegroundColor Green
        Add-Content $Report "[OK]   $Name"
    }
    else
    {
        Write-Host "[FAIL] $Name" -ForegroundColor Red
        Add-Content $Report "[FAIL] $Name"
    }
}


function Section($Name)
{
    Add-Content $Report ""
    Add-Content $Report "=============================="
    Add-Content $Report $Name
    Add-Content $Report "=============================="
}



Add-Content $Report "Nexus98 Bootstrap"
Add-Content $Report "Date: $(Get-Date)"
Add-Content $Report "Computer: $env:COMPUTERNAME"



# ------------------------------------------------------------
Section "Project"

Write-Check `
"AI_Model_Hub Exists" `
(Test-Path $Project)



# ------------------------------------------------------------
Section "Python"

& $NexusPython --version |
Out-String |
Add-Content $Report

Write-Check `
"Python Available" `
($LASTEXITCODE -eq 0)


Write-Check `
"Virtual Environment Exists" `
(Test-Path "$Project\.venv")



# ------------------------------------------------------------
Section "Ollama"

$Ollama = Get-Process ollama

Write-Check `
"Ollama Running" `
($null -ne $Ollama)


try
{
    $Api = Invoke-WebRequest `
    http://localhost:11434/api/tags `
    -UseBasicParsing

    Write-Check `
    "Ollama API Online" `
    ($Api.StatusCode -eq 200)

    ollama list |
    Out-String |
    Add-Content $Report

}
catch
{
    Write-Check `
    "Ollama API Online" `
    $false
}



# ------------------------------------------------------------
Section "VS Code"

code --version |
Out-String |
Add-Content $Report

Write-Check `
"VS Code Installed" `
($LASTEXITCODE -eq 0)



# ------------------------------------------------------------
Section "Continue"

$Continue =
"$env:USERPROFILE\.continue"

Write-Check `
"Continue Folder Exists" `
(Test-Path $Continue)

Write-Check `
"Continue Config Exists" `
(Test-Path "$Continue\config.json")



# ------------------------------------------------------------
Section "SSH"

$SSH = Get-Service sshd

Write-Check `
"SSH Server Installed" `
($null -ne $SSH)



# ------------------------------------------------------------
Section "Tailscale"

tailscale status |
Out-String |
Add-Content $Report

Write-Check `
"Tailscale Available" `
($LASTEXITCODE -eq 0)



# ------------------------------------------------------------
Section "Models"

Write-Check `
"Model Directory Exists" `
(Test-Path "D:\AI\Models")



# ------------------------------------------------------------
Section "Toolkit"

Write-Check `
"Toolkit Exists" `
(Test-Path $Toolkit)



# ------------------------------------------------------------
Finish

Add-Content $Report ""
Add-Content $Report "Bootstrap complete."

Write-Host ""
Write-Host "======================================"
Write-Host " Nexus98 Bootstrap Finished"
Write-Host " Report:"
Write-Host $Report
Write-Host "======================================"


