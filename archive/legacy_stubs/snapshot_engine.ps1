function New-Nexus98Snapshot {

param(
    [string]$Name="Emergency"
)


$Root="D:\Nexus98_Guardian"

$Time=Get-Date -Format "yyyyMMdd_HHmmss"

$Snapshot="$Root\snapshots\$Name`_$Time"


New-Item -ItemType Directory -Force -Path $Snapshot | Out-Null


Write-Host ""
Write-Host "================================="
Write-Host " Creating Nexus98 Recovery Point"
Write-Host "================================="


# -----------------------------
# 1. System Inventory
# -----------------------------

Write-Host "[1/7] System Inventory"


$System=@{
Computer=$env:COMPUTERNAME
User=$env:USERNAME
Date=(Get-Date)
OS=(Get-CimInstance Win32_OperatingSystem).Caption
CPU=(Get-CimInstance Win32_Processor).Name
RAM=(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
}


$System |
ConvertTo-Json |
Set-Content "$Snapshot\system.json"



# -----------------------------
# 2. Critical Paths Only
# -----------------------------

Write-Host "[2/7] Capturing Critical Files"


$Targets=@(
"D:\Nexus98_Toolkit",
"D:\AI_Model_Hub\config",
"D:\AI_Model_Hub\core",
"D:\AI_Model_Hub\scripts",
"$env:USERPROFILE\.continue",
"$env:USERPROFILE\.vscode"
)


$InventoryFile="$Snapshot\inventory.txt"

New-Item $InventoryFile -ItemType File -Force | Out-Null


$Count=0


foreach($Target in $Targets){

    if(Test-Path $Target){

        Write-Host "Scanning:"
        Write-Host $Target


        Get-ChildItem `
            -Path $Target `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue |
        ForEach-Object {

            $Hash=Get-FileHash $_.FullName -Algorithm SHA256


            "$($Hash.Hash)|$($_.Length)|$($_.FullName)" |
            Add-Content $InventoryFile


            $Count++


            if(($Count % 100) -eq 0){

                Write-Host "Files captured:" $Count

            }

        }

    }

}



# -----------------------------
# 3. Ollama
# -----------------------------

Write-Host "[3/7] Ollama State"


try{

ollama list |
Set-Content "$Snapshot\ollama.txt"

}
catch{

"Unavailable" |
Set-Content "$Snapshot\ollama.txt"

}



# -----------------------------
# 4. Python
# -----------------------------

Write-Host "[4/7] Python State"


try{

python --version |
Set-Content "$Snapshot\python.txt"


pip list |
Out-File "$Snapshot\python_packages.txt"

}
catch{

"Unavailable" |
Set-Content "$Snapshot\python.txt"

}



# -----------------------------
# 5. Git
# -----------------------------

Write-Host "[5/7] Git State"


try{

git status |
Set-Content "$Snapshot\git.txt"

}
catch{

"Unavailable" |
Set-Content "$Snapshot\git.txt"

}



# -----------------------------
# 6. Manifest
# -----------------------------

Write-Host "[6/7] Creating Manifest"


$Manifest=@{
Name=$Name
Created=(Get-Date)
Computer=$env:COMPUTERNAME
FilesCaptured=$Count
Inventory="inventory.txt"
}


$Manifest |
ConvertTo-Json |
Set-Content "$Snapshot\manifest.json"



# -----------------------------
# 7. Verification
# -----------------------------

Write-Host "[7/7] Verification"


$Checks=@(
"$Snapshot\system.json",
"$Snapshot\inventory.txt",
"$Snapshot\manifest.json",
"$Snapshot\ollama.txt",
"$Snapshot\python.txt"
)


$Passed=0


foreach($Check in $Checks){

    if(Test-Path $Check){

        Write-Host "[PASS]" $Check
        $Passed++

    }
    else{

        Write-Host "[FAIL]" $Check

    }

}



$Report=@{
Snapshot=$Snapshot
Checks="$Passed/$($Checks.Count)"
Files=$Count
Time=(Get-Date)
}


$Report |
ConvertTo-Json |
Set-Content "$Snapshot\verification.json"



Write-Host ""
Write-Host "Recovery Point Complete"
Write-Host $Snapshot


return $Snapshot

}
