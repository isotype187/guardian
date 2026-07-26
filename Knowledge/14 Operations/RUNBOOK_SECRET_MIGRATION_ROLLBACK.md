# Secret Migration Rollback Runbook

**Version:** 1.0.0  
**Status:** Active  
**Owner:** Guardian Operations  
**Review Date:** 2026-10-26  
**Classification:** Internal — Operations

---

## 1. Purpose

Procedure to rollback secret migration from plaintext config files to Vault-backed references. Ensures recovery within 5-minute SLA if migration causes system instability.

---

## 2. Migration Overview

### 2.1 Migration Flow

```
Plaintext Config (Before)
         │
         ▼
Feature Flag: GUARDIAN_USE_VAULT=true
         │
         ▼
Vault-Backed Config (After)
         │
         ▼
Rollback: GUARDIAN_USE_VAULT=false
```

### 2.2 Config Changes

**Before (Plaintext):**
```json
{
  "communication": {
    "bridgeToken": "sk_live_abc123...",
    "apiKey": "ghp_xyz789..."
  },
  "database": {
    "connectionString": "Server=...;Password=plaintext..."
  }
}
```

**After (Vault References):**
```json
{
  "communication": {
    "bridgeToken": "vault:secret/bridge/token_001",
    "apiKey": "vault:secret/api/github_001"
  },
  "database": {
    "connectionString": "vault:database/creds/guardian_ro"
  }
}
```

### 2.3 Feature Flag

```powershell
# In Guardian runtime config
$GuardianRuntimeConfig = @{
    ...
    "features" = @{
        "useVaultSecrets" = $true  # Rollback: set to $false
    }
}
```

---

## 3. Rollback Triggers

| Trigger | Detection | Action |
|---------|-----------|--------|
| Secret read failure rate > 10% | Health check alert | Auto-rollback |
| Vault latency > 5s (p99) | Metric alert | Manual decision |
| Config validation fails | Startup check | Auto-rollback |
| Critical secret missing | `Test-GuardianSecretHealth` | Manual decision |
| Deployment health check fails | CI/CD gate | Auto-rollback |

---

## 4. Rollback Procedures

### 4.1 Automated Rollback (Preferred)

```powershell
# Triggered by health check failure
function Invoke-SecretMigrationRollback {
    param(
        [string]$Reason = "Health check failure"
    )
    
    Write-Host "INITIATING SECRET MIGRATION ROLLBACK: $Reason" -ForegroundColor Red
    
    # 1. Create emergency checkpoint
    $ck = New-GuardianCheckpoint -Tier emergency -Reason "Pre-rollback: $Reason"
    
    # 2. Disable Vault feature flag
    $config = Get-GuardianRuntimeConfig
    $config.features.useVaultSecrets = $false
    Set-GuardianRuntimeConfigValidated -Config $config
    
    # 3. Restore plaintext config from backup
    $backupPath = "config\backup\guardian_runtime_config.plaintext.json"
    if (Test-Path $backupPath) {
        Copy-Item $backupPath "config\guardian_runtime_config.json" -Force
    }
    
    # 4. Sync scheduler
    Sync-GuardianSchedulerFromConfig | Out-Null
    
    # 5. Validate recovery
    $health = Get-GuardianHealthScore
    if ($health.runtimePct -ge 90) {
        Write-Host "ROLLBACK SUCCESSFUL: Runtime health $($health.runtimePct)%" -ForegroundColor Green
        
        # Audit
        Write-GuardianAudit -Action 'SECRET_MIGRATION_ROLLBACK' -Reason $Reason `
            -Metadata @{ checkpoint=$ck.id; featureFlag='useVaultSecrets=false' }
        
        return $true
    }
    else {
        Write-Error "ROLLBACK FAILED: Runtime health $($health.runtimePct)%"
        return $false
    }
}
```

### 4.2 Manual Rollback (If Automated Fails)

```powershell
# Run as Administrator on Guardian host
# 1. Stop Guardian operations
Stop-GuardianOperations -Force

# 2. Disable feature flag directly in config file
$configPath = "D:\Nexus98_Guardian\config\guardian_runtime_config.json"
$config = Get-Content $configPath | ConvertFrom-Json
$config.features.useVaultSecrets = $false
$config | ConvertTo-Json -Depth 10 | Set-Content $configPath

# 3. Restore plaintext config
Copy-Item "config\backup\guardian_runtime_config.plaintext.json" `
    "config\guardian_runtime_config.json" -Force

# 4. Start Guardian
Start-GuardianOperations -MaxCycles 1

# 5. Verify
Get-GuardianHealthScore | Select-Object runtimePct, overallPct
```

### 4.3 Complete Vault Disconnection (Nuclear Option)

```powershell
# If Vault is compromised or completely unavailable
# 1. Disable bridge
Disable-GuardianBridge -Reason "Vault compromise"

# 2. Disable all Vault-dependent features
$config = Get-GuardianRuntimeConfig
$config.features.useVaultSecrets = $false
$config.features.vaultCommunication = $false
Set-GuardianRuntimeConfigValidated -Config $config

# 3. Use only local/plaintext secrets
# 4. Create incident ticket for Vault team
```

---

## 5. Pre-Migration Backup

### 5.1 Automated Backup (Runs Before Migration)

```powershell
function Backup-PlaintextConfig {
    $backupDir = "config\backup"
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    
    # Backup runtime config
    Copy-Item "config\guardian_runtime_config.json" `
        "$backupDir\guardian_runtime_config.plaintext.$timestamp.json" -Force
    
    # Backup any other config files with secrets
    Get-ChildItem "config\*.json" | Where-Object { 
        (Get-Content $_.FullName -Raw) -match '(password|secret|key|token)\s*:' 
    } | ForEach-Object {
        Copy-Item $_.FullName "$backupDir\$($_.BaseName).plaintext.$timestamp.json" -Force
    }
    
    # Verify backup integrity
    $original = Get-FileHash "config\guardian_runtime_config.json" -Algorithm SHA256
    $backup = Get-FileHash "$backupDir\guardian_runtime_config.plaintext.$timestamp.json" -Algorithm SHA256
    
    if ($original.Hash -ne $backup.Hash) {
        throw "Backup verification failed: hash mismatch"
    }
    
    Write-Host "Backup verified: $($backup.Hash)" -ForegroundColor Green
}
```

### 5.2 Backup Retention

| Backup Type | Retention | Location |
|-------------|-----------|----------|
| Pre-migration | 90 days | `config/backup/` |
| Daily (auto) | 30 days | `config/backup/` |
| Manual (admin) | 1 year | `config/backup/manual/` |

---

## 6. Validation Checklist

### 6.1 Pre-Migration

- [ ] Vault connectivity verified (`Test-SecretVaultConnection`)
- [ ] All required secrets exist in Vault
- [ ] Feature flag default is `false`
- [ ] Backup completed and verified
- [ ] Rollback procedure tested in staging
- [ ] Monitoring alerts configured

### 6.2 Post-Migration (5-min window)

- [ ] `Get-GuardianHealthScore` > 95%
- [ ] `Test-GuardianSecretHealth` all PASS
- [ ] Bridge communication operational
- [ ] Scheduler running jobs
- [ ] No error spikes in audit log

### 6.3 Post-Migration (1-hour window)

- [ ] All scheduled jobs executed successfully
- [ ] Secret rotation (if due) completed
- [ ] No stale cache warnings
- [ ] Performance metrics baseline

---

## 7. Rollback Decision Matrix

| Condition | Auto-Rollback | Manual Decision |
|-----------|---------------|-----------------|
| Health score < 90% | ✅ | — |
| Secret read failures > 10% | ✅ | — |
| Vault latency p99 > 5s | — | ✅ |
| Single secret missing | — | ✅ |
| Config validation error | ✅ | — |
| Deployment gate fail | ✅ | — |
| Security incident | — | ✅ |

---

## 8. Communication Plan

| Event | Channel | Audience | Template |
|-------|---------|----------|----------|
| Migration started | Slack #guardian-ops | Engineers | "Guardian secret migration STARTED at {time}" |
| Migration complete | Slack #guardian-ops | Engineers | "Guardian secret migration COMPLETE at {time}. Health: {score}%" |
| Auto-rollback triggered | Slack #guardian-alerts + PagerDuty | On-call | "AUTO-ROLLBACK: Guardian secret migration rolled back. Reason: {reason}" |
| Manual rollback initiated | Slack #guardian-ops + PagerDuty | On-call + Lead | "MANUAL ROLLBACK initiated by {user}. Reason: {reason}" |
| Rollback complete | Slack #guardian-ops | Engineers | "Rollback COMPLETE. Guardian running on plaintext config." |
| Post-incident review | Confluence | All | Link to incident doc |

---

## 9. Rollback Verification

```powershell
function Test-RollbackComplete {
    $checks = @(
        @{ Name="RuntimeHealth"; Script={ (Get-GuardianHealthScore).runtimePct -ge 90 } }
        @{ Name="BridgeStatus";  Script={ (Get-GuardianBridgeStatus).enabled -eq $true } }
        @{ Name="SchedulerActive"; Script={ (Get-GuardianOperationsStatus).status -eq 'running' } }
        @{ Name="SecretAccess";  Script={ (Test-GuardianSecretHealth).AllPassed } }
        @{ Name="ConfigLoaded";  Script={ $null -ne (Get-GuardianRuntimeConfig) } }
        @{ Name="FeatureFlag";   Script={ -not (Get-GuardianRuntimeConfig).features.useVaultSecrets } }
    )
    
    $results = @()
    foreach ($c in $checks) {
        try {
            $result = & $c.Script
            $results += @{ Check=$c.Name; Passed=$result }
        }
        catch {
            $results += @{ Check=$c.Name; Passed=$false; Error=$_.Exception.Message }
        }
    }
    
    $failed = $results | Where-Object { -not $_.Passed }
    if ($failed.Count -gt 0) {
        Write-Error "Rollback verification FAILED: $($failed | ForEach-Object { $_.Check })"
        return $false
    }
    
    Write-Host "Rollback verification PASSED: all $($results.Count) checks OK" -ForegroundColor Green
    return $true
}
```

---

## 10. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Guardian Operations | Initial release for WQ-002 |

---

*This runbook is executed by Guardian Operations on-call. All rollback actions are audited.*