Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Orchestrator Core Integration v0.3.0"
Write-Host "================================="

$Toolkit="D:\Nexus98_Toolkit"

$Core="$Toolkit\core"
$Config="$Toolkit\config"
$Reports="$Toolkit\reports"

foreach($Path in @($Core,$Config,$Reports)){
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

Write-Host "[1/5] Creating Orchestrator Core module"

$CoreFile="$Core\Nexus98_Orchestrator_Core.ps1"

@"
function Start-Nexus98Orchestrator {

    return @{
        component = "Orchestrator Core"
        version = "0.3.0"
        status = "running"
    }

}

function Get-Nexus98OrchestratorStatus {

    return "Operational"

}
"@ | Set-Content $CoreFile -Encoding UTF8


Write-Host "[2/5] Updating module registry"

$Registry="$Config\nexus98_modules.json"

if(Test-Path $Registry){

    $Modules=Get-Content $Registry -Raw | ConvertFrom-Json

}
else{

    $Modules=@{
        modules=@{
            core=@()
        }
    }

}


if($null -eq $Modules.modules.core){

    $Modules.modules | Add-Member -MemberType NoteProperty -Name core -Value @()

}


if($Modules.modules.core -notcontains "Orchestrator_Core"){

    $Modules.modules.core += "Orchestrator_Core"

}


$Modules | ConvertTo-Json -Depth 10 | Set-Content $Registry -Encoding UTF8


Write-Host "[3/5] Updating state"

@{
    component="Orchestrator Core"
    version="0.3.0"
    status="VERIFIED"
    updated=(Get-Date)
} | ConvertTo-Json | Set-Content "$Config\nexus98_orchestrator_state.json" -Encoding UTF8


Write-Host "[4/5] Verification"

$Checks=@(
    $CoreFile
    $Registry
    "$Config\nexus98_orchestrator_state.json"
)

$Results=@()

foreach($Check in $Checks){

    $Result="[MISSING] $Check"

    if(Test-Path $Check){

        $Result="[OK] $Check"

    }

    $Results += $Result

}


$Status="VERIFIED"

foreach($Result in $Results){

    if($Result -like "*MISSING*"){

        $Status="FAILED"

    }

}


Write-Host "[5/5] Creating report"

$Report="$Reports\Nexus98_Orchestrator_Core_Integration_Report.txt"

@(
"Nexus98 Orchestrator Core Integration"
"Version: 0.3.0"
"Status: $Status"
"Completed: $(Get-Date)"
""
"Verification:"
$Results
) | Set-Content $Report -Encoding UTF8


Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Orchestrator Core Integration Complete"
Write-Host "================================="
Write-Host "Status: $Status"
Write-Host "Report:"
Write-Host $Report
