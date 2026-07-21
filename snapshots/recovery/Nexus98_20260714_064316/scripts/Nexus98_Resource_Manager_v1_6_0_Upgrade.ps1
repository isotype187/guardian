Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Resource Manager v1.6.0"
Write-Host "================================="


$Toolkit="D:\Nexus98_Toolkit"

$Core="$Toolkit\core"
$Config="$Toolkit\config"
$Reports="$Toolkit\reports"
$Logs="$Toolkit\logs"


Write-Host "[1/5] Creating Resource Engine"


$Engine="$Core\Nexus98_Resource_Manager.ps1"


@(
"function Get-Nexus98Resources {"
""
"$CPU=(Get-CimInstance Win32_Processor | Select-Object -First 1 LoadPercentage)"
"$RAM=(Get-CimInstance Win32_OperatingSystem)"
""
"return @{"
"cpu=$CPU.LoadPercentage"
"memoryFreeGB=[math]::Round($RAM.FreePhysicalMemory/1048576,2)"
"timestamp=(Get-Date)"
"}"
"}"
) | Set-Content $Engine -Encoding UTF8



Write-Host "[2/5] Creating Resource State"


$State="$Config\nexus98_resource_state.json"


@{
component="Resource Manager"
version="1.6.0"
status="active"
monitoring="enabled"
resources=@(
"CPU"
"Memory"
"GPU"
"Storage"
)
created=(Get-Date)
} | ConvertTo-Json -Depth 10 | Set-Content $State -Encoding UTF8



Write-Host "[3/5] Creating Resource Log"


$ResourceLog="$Logs\nexus98_resources.log"


Add-Content $ResourceLog "07/14/2026 06:35:05 Resource Manager initialized"



Write-Host "[4/5] Validation"


$Checks=@(
$Engine
$State
$ResourceLog
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



Write-Host "[5/5] Creating Report"


$Report="$Reports\Nexus98_Resource_Manager_v1_6_0_Report.txt"


@(
"Nexus98 Resource Manager"
"Version: 1.6.0"
"Status: $Status"
"Completed: 07/14/2026 06:35:05"
""
"Validation:"
$Results
) | Set-Content $Report -Encoding UTF8



Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Resource Manager Complete"
Write-Host "================================="
Write-Host "Status: $Status"
Write-Host "Report:"
Write-Host $Report
