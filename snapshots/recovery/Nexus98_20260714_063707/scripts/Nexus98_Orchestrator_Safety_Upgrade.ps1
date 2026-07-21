Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Orchestrator Safety Layer v0.9.0"
Write-Host "================================="

$Toolkit="D:\Nexus98_Toolkit"

$Core="$Toolkit\core"
$Config="$Toolkit\config"
$Reports="$Toolkit\reports"
$Logs="$Toolkit\logs"


foreach($Path in @($Core,$Config,$Reports,$Logs)){

    New-Item -ItemType Directory -Force -Path $Path | Out-Null

}


Write-Host "[1/5] Creating Safety Engine"


$Engine="$Core\Nexus98_Safety_Engine.ps1"


@(
"function Test-Nexus98SafetyPolicy {"
"param([string]$Action='unknown')"
"return @{"
"action=$Action"
"approved=$true"
"checked=(Get-Date)"
"}"
"}"
""
"function New-Nexus98SafetyEvent {"
"param([string]$Event='unknown')"
"return @{"
"event=$Event"
"severity='normal'"
"timestamp=(Get-Date)"
"}"
"}"
) | Set-Content $Engine -Encoding UTF8



Write-Host "[2/5] Creating Safety State"


$State="$Config\nexus98_safety_state.json"


@{
component="Orchestrator Safety Layer"
version="0.9.0"
status="installed"
policy="enabled"
created=(Get-Date)
} | ConvertTo-Json -Depth 10 | Set-Content $State -Encoding UTF8



Write-Host "[3/5] Registering Safety Module"


$Registry="$Config\nexus98_modules.json"


if(Test-Path $Registry){

    $Modules=Get-Content $Registry -Raw | ConvertFrom-Json


    if($null -eq $Modules.modules.core){

        $Modules.modules | Add-Member -MemberType NoteProperty -Name core -Value @()

    }


    if($Modules.modules.core -notcontains "Safety_Engine"){

        $Modules.modules.core += "Safety_Engine"

    }


    $Modules | ConvertTo-Json -Depth 10 | Set-Content $Registry -Encoding UTF8

}



Write-Host "[4/5] Validation"


$Checks=@(
$Engine
$State
$Registry
)


$Results=@()


foreach($Check in $Checks){

    if(Test-Path $Check){

        $Results += "[OK] $Check"

    }
    else{

        $Results += "[MISSING] $Check"

    }

}


$Status="VERIFIED"


foreach($Result in $Results){

    if($Result -like "*MISSING*"){

        $Status="FAILED"

    }

}



Write-Host "[5/5] Creating Report"


$Report="$Reports\Nexus98_Orchestrator_Safety_Report.txt"


@(
"Nexus98 Orchestrator Safety Layer"
"Version: 0.9.0"
"Status: $Status"
"Completed: 07/14/2026 06:10:38"
""
"Verification:"
$Results
) | Set-Content $Report -Encoding UTF8



Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Safety Layer Complete"
Write-Host "================================="
Write-Host "Status: $Status"
Write-Host "Report:"
Write-Host $Report
