. (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))

Invoke-Pester -Path .\Guardian.Foundation.Tests.ps1 -Output Detailed