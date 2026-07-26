. (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))

# Run M10 tests with a long timeout
Invoke-Pester -Path .\Guardian.M10.Tests.ps1 -Output Detailed