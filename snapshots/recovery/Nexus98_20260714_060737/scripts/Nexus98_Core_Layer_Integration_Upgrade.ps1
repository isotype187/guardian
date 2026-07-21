Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Core Layer Integration Upgrade v0.2.0"
Write-Host "================================="

$Toolkit="D:\Nexus98_Toolkit"

$Scripts="$Toolkit\scripts"
$Core="$Toolkit\core"
$Config="$Toolkit\config"
$Reports="$Toolkit\reports"

$Modules="$Config\nexus98_modules.json"
$State="$Config\nexus98_state.json"

New-Item -ItemType Directory -Force -Path $Reports | Out-Null


Write-Host ""
Write-Host "[1/6] Creating recovery checkpoint"

$Checkpoint="$Scripts\Nexus98_Checkpoint_Manager.ps1"

if(Test-Path $Checkpoint){
    powershell -ExecutionPolicy Bypass -File $Checkpoint
}
else{
    Write-Host "[WARN] Checkpoint manager missing"
}


Write-Host ""
Write-Host "[2/6] Validating Core Layer"

$coreFiles=@(
"Nexus98_Core.ps1",
"Nexus98_Logger.ps1",
"Nexus98_State.ps1",
"Nexus98_Report.ps1",
"Nexus98_Telemetry.ps1"
)

$coreStatus="VERIFIED"

foreach($file in $coreFiles){

    if(Test-Path "$Core\$file"){
        Write-Host "[OK] $file"
    }
    else{
        Write-Host "[FAIL] Missing $file"
        $coreStatus="FAILED"
    }
}


Write-Host ""
Write-Host "[3/6] Registering Core Layer"


if(Test-Path $Modules){

    $Registry=Get-Content $Modules -Raw | ConvertFrom-Json

    if($null -eq $Registry.core){
        $Registry | Add-Member -MemberType NoteProperty -Name core -Value @()
    }

    $NewModules=@(
        "Nexus98_Core",
        "Nexus98_Logger",
        "Nexus98_State",
        "Nexus98_Report",
        "Nexus98_Telemetry"
    )

    foreach($module in $NewModules){

        if($Registry.core -notcontains $module){

            $Registry.core += $module
            Write-Host "[REGISTERED] $module"

        }
        else{

            Write-Host "[EXISTS] $module"

        }
    }

    $Registry | ConvertTo-Json -Depth 10 |
    Set-Content $Modules -Encoding UTF8

}
else{

    Write-Host "[FAIL] Module registry missing"
    $coreStatus="FAILED"

}



Write-Host ""
Write-Host "[4/6] Updating Nexus98 State"


$StateData=@{
    toolkit="Nexus98 Toolkit"
    core_layer="0.2.0"
    core_status=$coreStatus
    updated=(Get-Date)
}

$StateData |
ConvertTo-Json -Depth 5 |
Set-Content $State -Encoding UTF8



Write-Host ""
Write-Host "[5/6] Generating Report"


$Report=@(
"================================="
"Nexus98 Core Layer Integration"
"================================="
""
"Version: 0.2.0"
"Status: $coreStatus"
""
"Registered Components:"
"Nexus98_Core"
"Nexus98_Logger"
"Nexus98_State"
"Nexus98_Report"
"Nexus98_Telemetry"
""
"Completed:"
(Get-Date)
)

$ReportPath="$Reports\Nexus98_Core_Layer_Integration_Report.txt"

$Report |
Set-Content $ReportPath -Encoding UTF8



Write-Host ""
Write-Host "[6/6] Final Verification"

if(
(Test-Path $Modules) -and
(Test-Path $ReportPath)
){

    $Final="VERIFIED"

}
else{

    $Final="FAILED"

}


Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Core Layer Integration Complete"
Write-Host "================================="

Write-Host ""
Write-Host "Status:"
Write-Host $Final

Write-Host ""
Write-Host "Report:"
Write-Host $ReportPath

Write-Host ""
Write-Host "================================="

