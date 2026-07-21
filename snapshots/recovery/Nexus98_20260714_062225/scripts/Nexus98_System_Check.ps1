
# ============================================================
# Nexus98 Python Resolver
# ============================================================

$PythonConfig = "D:\Nexus98_Toolkit\config\python_config.yaml"


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
# Nexus98 System Health Check v1.0
# Rollback Validation + Environment Audit
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

$Root = "D:\AI_Model_Hub"
$ReportDir = "$Root\reports"

New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

$Timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$Report = "$ReportDir\Nexus98_Check_$Timestamp.txt"

function Header($Text)
{
    Add-Content $Report ""
    Add-Content $Report "================================================"
    Add-Content $Report $Text
    Add-Content $Report "================================================"
}

function Check($Name,$Result)
{
    if($Result)
    {
        Add-Content $Report "[OK]   $Name"
        Write-Host "[OK]   $Name" -ForegroundColor Green
    }
    else
    {
        Add-Content $Report "[FAIL] $Name"
        Write-Host "[FAIL] $Name" -ForegroundColor Red
    }
}

Header "Nexus98 System Check"

Add-Content $Report "Date: $(Get-Date)"
Add-Content $Report "Computer: $env:COMPUTERNAME"


# Hardware

Header "Hardware"

Get-CimInstance Win32_VideoController |
Select-Object Name |
Out-String |
Add-Content $Report

$RAM = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB

Add-Content $Report "RAM GB: $([math]::Round($RAM,2))"



# Storage

Header "Storage"

Get-PSDrive |
Where-Object {$_.Provider -like "*FileSystem*"} |
Out-String |
Add-Content $Report



# Windows

Header "Windows"

Get-ComputerInfo |
Select-Object WindowsProductName,
              WindowsVersion,
              OsBuildNumber |
Out-String |
Add-Content $Report



# Python

Header "Python"

& $NexusPython --version |
Out-String |
Add-Content $Report

Check "Python Installed" ($LASTEXITCODE -eq 0)

Check "Virtual Environment Exists" `
(Test-Path "$Root\.venv")



# Git

Header "Git"

if(Test-Path "$Root\.git")
{
    Check "Git Repository Exists" $true

    Push-Location $Root

    git status |
    Out-String |
    Add-Content $Report

    git branch |
    Out-String |
    Add-Content $Report

    Pop-Location
}
else
{
    Check "Git Repository Exists" $false
}



# Ollama

Header "Ollama"

$Ollama = Get-Process ollama

Check "Ollama Running" ($null -ne $Ollama)

try
{
    $response = Invoke-WebRequest `
    http://localhost:11434/api/tags `
    -UseBasicParsing

    Check "Ollama API Responding" ($response.StatusCode -eq 200)

    ollama list |
    Out-String |
    Add-Content $Report
}
catch
{
    Check "Ollama API Responding" $false
}



# Continue

Header "Continue"

$ContinuePath = "$env:USERPROFILE\.continue"

Check "Continue Folder Exists" `
(Test-Path $ContinuePath)

if(Test-Path "$ContinuePath\config.yaml")
{
    Check "Continue Config Exists" $true

    Get-Content "$ContinuePath\config.yaml" |
    Add-Content $Report
}
else
{
    Check "Continue Config Exists" $false
}



# VS Code

Header "VS Code"

code --version |
Out-String |
Add-Content $Report

Check "VS Code Installed" ($LASTEXITCODE -eq 0)



# SSH

Header "SSH"

Get-Service ssh-agent |
Out-String |
Add-Content $Report

Get-Service sshd |
Out-String |
Add-Content $Report



# Tailscale

Header "Tailscale"

tailscale status |
Out-String |
Add-Content $Report

Check "Tailscale Installed" ($LASTEXITCODE -eq 0)



# Project Structure

Header "Project Structure"

$Paths = @(
"D:\AI_Model_Hub",
"D:\AI_Model_Hub\config",
"D:\AI_Model_Hub\tools",
"D:\AI\Models"
)

foreach($Path in $Paths)
{
    Check "Exists $Path" (Test-Path $Path)
}



# Python Packages

Header "Python Packages"

& $NexusPython -m pip list |
Out-String |
Add-Content $Report



# Environment

Header "Environment Variables"

Get-ChildItem Env: |
Out-String |
Add-Content $Report



# Finished

Header "COMPLETE"

Add-Content $Report "Audit completed."
Add-Content $Report "Review FAIL entries."

Write-Host ""
Write-Host "====================================="
Write-Host " Nexus98 Audit Complete"
Write-Host " Report:"
Write-Host $Report
Write-Host "====================================="


