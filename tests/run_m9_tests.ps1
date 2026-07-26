. (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))

Invoke-Pester -Path .\Guardian.M9.Tests.ps1 -Output Detailed