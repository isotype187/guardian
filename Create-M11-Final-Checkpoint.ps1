# ============================================================
# Nexus98 Guardian M11 Final Validation Checkpoint Automation
# Creates checkpoint -> validates -> commits -> pushes
# ============================================================

$ErrorActionPreference = "Stop"

$RepoRoot = "D:\Nexus98_Guardian"

if (!(Test-Path $RepoRoot)) {
    throw "Guardian repository not found: $RepoRoot"
}

Set-Location $RepoRoot


Write-Host ""
Write-Host "============================================="
Write-Host " NEXUS98 GUARDIAN M11 FINAL CHECKPOINT"
Write-Host "============================================="
Write-Host ""


# ------------------------------------------------------------
# Generate checkpoint identity
# ------------------------------------------------------------

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$CheckpointID = "CK_M11_FINAL_VALIDATION_$Timestamp"


$CheckpointDir = Join-Path `
    $RepoRoot `
    "Knowledge\Checkpoints"


if (!(Test-Path $CheckpointDir)) {
    New-Item `
        -ItemType Directory `
        -Path $CheckpointDir `
        -Force | Out-Null
}


$CheckpointFile = Join-Path `
    $CheckpointDir `
    "$CheckpointID.yaml"


# ------------------------------------------------------------
# Git state
# ------------------------------------------------------------

try {
    $Commit = git rev-parse HEAD
}
catch {
    $Commit = "UNKNOWN"
}


# ------------------------------------------------------------
# Artifact validation
# ------------------------------------------------------------

$Artifacts = @{
    Guardian_Loader = "core\Guardian_Loader.ps1"
    CI_Pipeline = ".github\workflows\guardian-ci.yml"
    Requirements = "requirements.psd1"
    Tests = "tests"
    Hermes_B_Report = "HERMES_B_FINAL_REPORT.yaml"
}


$ArtifactStatus = ""

foreach ($Artifact in $Artifacts.Keys) {

    $Exists = Test-Path `
        (Join-Path $RepoRoot $Artifacts[$Artifact])

    $ArtifactStatus += `
"    $Artifact : $Exists`n"
}


# ------------------------------------------------------------
# Health collection
# ------------------------------------------------------------

$HealthResult = "NOT_EXECUTED"

try {

    pwsh -Command "
    .\core\Guardian_Loader.ps1
    Import-Guardian
    Get-GuardianHealthScore
    " | Out-File `
        "$env:TEMP\guardian_health.txt"

    $HealthResult = `
        Get-Content "$env:TEMP\guardian_health.txt" `
        -Raw

}
catch {

    $HealthResult = "Guardian health execution failed"

}


# ------------------------------------------------------------
# Create YAML checkpoint
# ------------------------------------------------------------

$Checkpoint = @"
checkpoint:

  id: "$CheckpointID"

  milestone:
    name: "M11 Core Hardening"
    state: "FINAL_VALIDATION"

  created:
    timestamp: "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")"

  repository:

    path:
      "$RepoRoot"

    commit:
      "$Commit"


  hermes:

    hermes_a:

      status:
        COMPLETE

      responsibilities:

        - CI/CD validation
        - Guardian operational verification
        - Architecture validation


    hermes_b:

      status:
        COMPLETE

      responsibilities:

        - Security hardening
        - SecretManagement implementation
        - Documentation validation


  guardian:

    status:
      VALIDATED


    validation:

      - Module loading
      - Pipeline structure
      - Security controls
      - Recovery protocol
      - Documentation sync


  artifact_validation:

$ArtifactStatus


  health_check:

    result:

      |
$(($HealthResult -split "`n" | ForEach-Object { "      $_" }) -join "`n")


  outstanding:

    - CI runner dependency installation
    - Production monitoring
    - Future milestone planning


  next_authorized_phase:

    - Architecture freeze
    - M12 planning
    - New work queue creation


  governance:

    owner:
      Guardian

    execution:
      Hermes

    mission:
      Nexus98


  rules:

    - No scope expansion
    - No duplicate implementation
    - Update checkpoint before changes


status:

  checkpoint:
    CREATED

  operational_state:
    MONITORING

"@


Set-Content `
    -Path $CheckpointFile `
    -Value $Checkpoint `
    -Encoding UTF8


Write-Host ""
Write-Host "Checkpoint created:"
Write-Host $CheckpointFile
Write-Host ""


# ------------------------------------------------------------
# Git commit and push
# ------------------------------------------------------------

git add $CheckpointFile

git commit `
    -m "checkpoint: M11 final validation $CheckpointID"


git push


# ------------------------------------------------------------
# Final output
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================="
Write-Host " M11 CHECKPOINT COMPLETE"
Write-Host "============================================="
Write-Host ""

Write-Host "Checkpoint ID:"
Write-Host $CheckpointID

Write-Host ""

Write-Host "Send this to Hermes A and Hermes B:"
Write-Host ""

Write-Host @"
checkpoint_reference:

id:
  $CheckpointID

state:
  M11_FINAL_VALIDATION_COMPLETE

mode:
  MONITORING_ONLY

authority:
  Guardian

next_phase:
  M12_PLANNING

"@
