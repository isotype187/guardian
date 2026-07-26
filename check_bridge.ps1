$root = 'D:\Nexus98_Guardian'
. (Join-Path $root 'core\Guardian_Loader.ps1')
Import-Guardian -Root $root

# Check if Guardian_Bridge functions are loaded
Get-Command *GuardianBridge* -ErrorAction SilentlyContinue