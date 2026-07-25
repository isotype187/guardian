. .\core\Guardian_Loader.ps1
Import-Guardian -Root (Resolve-Path .)
$m = New-GuardianHealthMessage -Component 'test' -Status 'healthy'
Write-Host $m.type