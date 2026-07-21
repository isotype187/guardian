Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Orchestrator Memory Layer v0.6.0"
Write-Host "================================="

$Toolkit="D:\Nexus98_Toolkit"

$Core="$Toolkit\core"
$Config="$Toolkit\config"
$Reports="$Toolkit\reports"
$Logs="$Toolkit\logs"


foreach($Path in @($Core,$Config,$Reports,$Logs)){

    New-Item -ItemType Directory -Force -Path $Path | Out-Null

}


Write-Host "[1/5] Creating Memory Engine"


$Memory="$Core\Nexus98_Memory_Engine.ps1"


$MemoryContent=@(
'function Add-Nexus98MemoryRecord {'
''
'param('
'[string]$Event="System Event",'
'[string]$Status="UNKNOWN"'
')'
''
'$Record=@{'
'event=$Event'
'status=$Status'
'timestamp=(Get-Date)'
'}'
''
'$File="D:\Nexus98_Toolkit\logs\nexus98_memory_history.json"'
''
'$Existing=@()'
''
'if(Test-Path $File){'
'    $Existing=Get-Content $File -Raw | ConvertFrom-Json'
'}'
''
'$Existing += $Record'
''
'$Existing | ConvertTo-Json -Depth 10 | Set-Content $File -Encoding UTF8'
''
'return $Record'
''
'}'
''
''
'function Get-Nexus98MemoryHistory {'
''
'$File="D:\Nexus98_Toolkit\logs\nexus98_memory_history.json"'
''
'if(Test-Path $File){'
'    return Get-Content $File -Raw | ConvertFrom-Json'
'}'
''
'return @()'
''
'}'
)


$MemoryContent | Set-Content $Memory -Encoding UTF8



Write-Host "[2/5] Creating Memory State"


$State="$Config\nexus98_memory_state.json"


@{
component="Orchestrator Memory"
version="0.6.0"
status="installed"
history="enabled"
created=(Get-Date)
} | ConvertTo-Json | Set-Content $State -Encoding UTF8



Write-Host "[3/5] Registering Memory Module"


$Registry="$Config\nexus98_modules.json"


if(Test-Path $Registry){

    $Modules=Get-Content $Registry -Raw | ConvertFrom-Json

}


if($null -eq $Modules.modules.core){

    $Modules.modules | Add-Member -MemberType NoteProperty -Name core -Value @()

}


if($Modules.modules.core -notcontains "Memory_Engine"){

    $Modules.modules.core += "Memory_Engine"

}


$Modules | ConvertTo-Json -Depth 10 | Set-Content $Registry -Encoding UTF8



Write-Host "[4/5] Validation"


$Checks=@(
$Memory
$State
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


$Report="$Reports\Nexus98_Orchestrator_Memory_Report.txt"


@(
"Nexus98 Orchestrator Memory Layer"
"Version: 0.6.0"
"Status: $Status"
"Completed: $(Get-Date)"
""
"Verification:"
$Results
) | Set-Content $Report -Encoding UTF8



Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Memory Layer Complete"
Write-Host "================================="
Write-Host "Status: $Status"
Write-Host "Report:"
Write-Host $Report
