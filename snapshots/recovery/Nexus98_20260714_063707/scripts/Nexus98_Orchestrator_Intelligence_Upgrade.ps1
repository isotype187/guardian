Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Orchestrator Intelligence Layer v0.4.0"
Write-Host "================================="

$Toolkit="D:\Nexus98_Toolkit"

$Core="$Toolkit\core"
$Config="$Toolkit\config"
$Reports="$Toolkit\reports"


foreach($Path in @($Core,$Config,$Reports)){

    New-Item -ItemType Directory -Force -Path $Path | Out-Null

}


Write-Host "[1/5] Creating Intelligence Engine"


$Engine="$Core\Nexus98_Intelligence_Engine.ps1"


$EngineContent = @(
'function Get-Nexus98ExecutionPlan {'
''
'param([string]$Task="System Operation")'
''
'return @{'
'    task=$Task'
'    phase="planning"'
'    modules=@("System_Check","Execution_Logger","Orchestrator_Core")'
'    created=(Get-Date)'
'}'
''
'}'
''
'function Invoke-Nexus98Decision {'
''
'param([string]$Status="READY")'
''
'return @{'
'    decision=$Status'
'    timestamp=(Get-Date)'
'}'
''
'}'
)


$EngineContent | Set-Content $Engine -Encoding UTF8



Write-Host "[2/5] Creating Intelligence State"


$StateFile="$Config\nexus98_intelligence_state.json"


@{
component="Orchestrator Intelligence"
version="0.4.0"
status="installed"
created=(Get-Date)
} | ConvertTo-Json | Set-Content $StateFile -Encoding UTF8



Write-Host "[3/5] Registering Intelligence Module"


$Registry="$Config\nexus98_modules.json"


if(Test-Path $Registry){

    $Modules=Get-Content $Registry -Raw | ConvertFrom-Json

}


if($null -eq $Modules.modules.core){

    $Modules.modules | Add-Member -MemberType NoteProperty -Name core -Value @()

}


if($Modules.modules.core -notcontains "Intelligence_Engine"){

    $Modules.modules.core += "Intelligence_Engine"

}


$Modules | ConvertTo-Json -Depth 10 | Set-Content $Registry -Encoding UTF8



Write-Host "[4/5] Validation"


$Checks=@(
    $Engine
    $StateFile
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


$Report="$Reports\Nexus98_Orchestrator_Intelligence_Report.txt"


@(
"Nexus98 Orchestrator Intelligence Layer"
"Version: 0.4.0"
"Status: $Status"
"Completed: $(Get-Date)"
""
"Verification:"
$Results
) | Set-Content $Report -Encoding UTF8



Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Intelligence Layer Complete"
Write-Host "================================="
Write-Host "Status: $Status"
Write-Host "Report:"
Write-Host $Report
