function Test-Nexus98System {

$Checks=@(
"D:\Nexus98_Guardian\config\assets.json",
"D:\Nexus98_Guardian\core\snapshot_engine.ps1",
"D:\Nexus98_Guardian\core\verification_engine.ps1"
)

$Results=@()

foreach($Check in $Checks){

if(Test-Path $Check){

$Results += "[PASS] $Check"

}
else{

$Results += "[FAIL] $Check"

}

}

return $Results

}
