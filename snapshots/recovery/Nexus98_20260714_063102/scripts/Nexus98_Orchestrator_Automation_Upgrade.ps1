Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Orchestrator Automation Layer v0.5.0"
Write-Host "================================="

$Toolkit="D:\Nexus98_Toolkit"

$Core="$Toolkit\core"
$Config="$Toolkit\config"
$Reports="$Toolkit\reports"

foreach($Path in @($Core,$Config,$Reports)){

    New-Item -ItemType Directory -Force -Path $Path | Out-Null

}


Write-Host "[1/5] Creating Automation Engine"


$Automation="$Core\Nexus98_Automation_Engine.ps1"


$AutomationContent=@(
'function New-Nexus98Task {'
''
'param('
'[string]$TaskName="System Task",'
'[string[]]$Modules=@("System_Check")'
')'
''
'return @{'
'name=$TaskName'
'modules=$Modules'
'status="queued"'
'created=(Get-Date)'
'}'
''
'}'
''
''
'function Invoke-Nexus98Automation {'
''
'param($Task)'
''
'return @{'
'task=$Task.name'
'status="ready"'
'executed=(Get-Date)'
'}'
''
'}'
)


$AutomationContent | Set-Content $Automation -Encoding UTF8



Write-Host "[2/5] Creating Automation State"


@{
component="Orchestrator Automation"
version="0.5.0"
status="installed"
queue="ready"
created=(Get-Date)
} | ConvertTo-Json | Set-Content "$Config\nexus98_automation_state.json" -Encoding UTF8



Write-Host "[3/5] Registering Automation Module"


$Registry="$Config\nexus98_modules.json"


if(Test-Path $Registry){

    $Modules=Get-Content $Registry -Raw | ConvertFrom-Json

}


if($null -eq $Modules.modules.core){

    $Modules.modules | Add-Member -MemberType NoteProperty -Name core -Value @()

}


if($Modules.modules.core -notcontains "Automation_Engine"){

    $Modules.modules.core += "Automation_Engine"

}


$Modules | ConvertTo-Json -Depth 10 | Set-Content $Registry -Encoding UTF8



Write-Host "[4/5] Validation"


$Checks=@(
$Automation
"$Config\nexus98_automation_state.json"
$Registry
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


$Report="$Reports\Nexus98_Orchestrator_Automation_Report.txt"


@(
"Nexus98 Orchestrator Automation Layer"
"Version: 0.5.0"
"Status: $Status"
"Completed: $(Get-Date)"
""
"Verification:"
$Results
) | Set-Content $Report -Encoding UTF8



Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Automation Layer Complete"
Write-Host "================================="
Write-Host "Status: $Status"
Write-Host "Report:"
Write-Host $Report
