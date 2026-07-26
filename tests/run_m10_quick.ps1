. (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))

# Run M10 tests excluding the long-running lifecycle tests
Invoke-Pester -Path .\Guardian.M10.Tests.ps1 -Output Detailed -ExcludeTag 'Lifecycle'