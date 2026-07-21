$Toolkit="D:\Nexus98_Toolkit"

$Config="$Toolkit\config"
$Scripts="$Toolkit\scripts"

$Registry="$Config\nexus98_modules.json"
$Report="$Toolkit\reports\Nexus98_Dispatcher_Report.txt"

Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Orchestrator Dispatcher v1.1"
Write-Host "================================="
Write-Host ""

$Output=@()

$Output += "Nexus98 Dispatcher v1.1"
$Output += "Generated: $(Get-Date)"
$Output += ""

if(!(Test-Path $Registry))
{
    Write-Host "[FAIL] Registry missing"
    exit 1
}

$Modules=Get-Content $Registry -Raw | ConvertFrom-Json

Write-Host "[OK] Registry loaded"
$Output += "[OK] Registry loaded"

$Output += ""
$Output += "Dispatch Routes:"
Write-Host ""
Write-Host "Dispatch Routes:"
Write-Host ""

foreach($Category in $Modules.modules.PSObject.Properties)
{
    Write-Host "CATEGORY: $($Category.Name)"

    $Output += ""
    $Output += "CATEGORY: $($Category.Name)"

    foreach($Module in $Category.Value)
    {
        $Script="$Scripts\Nexus98_$Module.ps1"

        if(Test-Path $Script)
        {
            Write-Host "[READY] $Module"
            $Output += "[READY] $Module"
        }
        else
        {
            Write-Host "[MISSING] $Module"
            $Output += "[MISSING] $Module"
        }
    }
}

Write-Host ""
Write-Host "================================="
Write-Host " Dispatcher Validation Complete"
Write-Host "================================="

$Output += ""
$Output += "Status: READY"

$Output | Set-Content -Encoding UTF8 $Report

Write-Host ""
Write-Host "Report:"
Write-Host $Report
