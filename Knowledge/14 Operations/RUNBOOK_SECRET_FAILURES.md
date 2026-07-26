# Secret Failure Runbook

**Version:** 1.0.0  
**Status:** Active  
**Owner:** Guardian Operations  
**Review Date:** 2026-10-26  
**Classification:** Internal — Operations

---

## 1. Purpose

Procedures for detecting, diagnosing, and recovering from secret management failures. Covers Vault outages, authentication failures, secret corruption, and emergency scenarios.

---

## 2. Failure Categories & Response Priorities

| Priority | Category | SLA | Escalation |
|----------|----------|-----|------------|
| **P0** | Vault sealed / unreachable | 15 min | Page on-call + security |
| **P0** | Emergency access used | 5 min | Page admin + security |
| **P1** | Auth failures (burst) | 30 min | Page on-call |
| **P1** | Secret rotation failed | 1 hour | Ticket + page engineer |
| **P2** | Single secret read failure | 4 hours | Ticket engineer |
| **P2** | Audit chain break | 30 min | Page admin + security |
| **P3** | Performance degradation | 24 hours | Ticket engineer |

---

## 3. Common Failure Scenarios

### 3.1 Vault Sealed or Unreachable

**Symptoms:**
- `Test-SecretVaultConnection` returns `Connected: False`
- All secret operations fail with connection timeout
- Health endpoint returns 503

**Immediate Actions:**
```powershell
# 1. Verify Vault status
Invoke-RestMethod -Uri "https://vault.example.com:8200/v1/sys/health" -Method GET

# 2. Check seal status
Invoke-RestMethod -Uri "https://vault.example.com:8200/v1/sys/seal-status" -Method GET

# 3. If sealed: Unseal (requires threshold keys)
# Run on Vault server:
# vault operator unseal <key1>
# vault operator unseal <key2>
# vault operator unseal <key3>

# 4. If unreachable: Check network, firewall, DNS
Test-NetConnection -ComputerName vault.example.com -Port 8200
```

**Fallback:**
- Guardian serves cached secrets (max 5 min staleness)
- Circuit breaker opens after 3 consecutive failures
- Alert: `vault_sealed` or `vault_unreachable`

**Recovery Validation:**
```powershell
Test-SecretVaultConnection -Vault GuardianVault
# Should return Connected: True, LatencyMs < 100
```

---

### 3.2 Authentication Failure (AppRole / OIDC)

**Symptoms:**
- `Get-GuardianSecret` throws `PermissionDeniedException`
- Audit shows `VAULT_AUTH_FAILED` events
- Token TTL expired, renewal failed

**Diagnosis:**
```powershell
# Check token status
$tokenInfo = Invoke-RestMethod -Headers @{"X-Vault-Token"=$env:VAULT_TOKEN} `
    -Uri "https://vault.example.com:8200/v1/auth/token/lookup-self"

# Verify AppRole credentials
$roleId = Get-Secret -Name "guardian-system-role-id"
$secretId = Get-Secret -Name "guardian-system-secret-id"
$login = Invoke-RestMethod -Method POST -Uri "https://vault.example.com:8200/v1/auth/approle/login" `
    -Body @{ role_id=$roleId; secret_id=$secretId } | ConvertTo-Json
```

**Remediation:**
| Cause | Action |
|-------|--------|
| Token expired | Auto-renewal should handle; if not, re-login |
| Secret ID rotated | Generate new Secret ID, update CI/CD |
| Role ID changed | Update role_id secret, re-login |
| CIDR binding failed | Verify client IP in allowed CIDR |
| Policy removed | Admin restores policy |

**CI/CD Recovery:**
```yaml
# GitHub Actions: Re-authenticate step
- name: Re-authenticate to Vault
  run: |
    $token = Get-VaultTokenViaOIDC
    echo "VAULT_TOKEN=$token" >> $env:GITHUB_ENV
```

---

### 3.3 Secret Not Found / Corrupted

**Symptoms:**
- `Get-GuardianSecret` throws `SecretNotFoundException`
- Secret exists in Vault but version missing
- Value hash mismatch on read

**Diagnosis:**
```powershell
# Check secret metadata
$meta = Invoke-RestMethod -Headers @{"X-Vault-Token"=$token} `
    -Uri "https://vault.example.com:8200/v1/secret/metadata/bridge/token_001"

# List versions
$versions = Invoke-RestMethod -Headers @{"X-Vault-Token"=$token} `
    -Uri "https://vault.example.com:8200/v1/secret/metadata/bridge/token_001?list=true"

# Check specific version
$v5 = Invoke-RestMethod -Headers @{"X-Vault-Token"=$token} `
    -Uri "https://vault.example.com:8200/v1/secret/data/bridge/token_001?version=5"
```

**Remediation:**
| Issue | Action |
|-------|--------|
| Accidentally deleted | Restore from version history (if not destroyed) |
| All versions destroyed | Re-create secret (requires rotation) |
| Hash mismatch | Investigate tampering; rotate immediately |
| Wrong path | Verify path in config vs Vault |

---

### 3.4 Secret Rotation Failure

**Symptoms:**
- `Invoke-SecretRotation` returns failure
- Rotation scheduled but not executed
- New secret not accessible

**Diagnosis:**
```powershell
# Check rotation status
$rotation = Get-GuardianSecretRotationStatus -Name "bridge/token_001"

# Check Vault lease
$lease = Invoke-RestMethod -Headers @{"X-Vault-Token"=$token} `
    -Uri "https://vault.example.com:8200/v1/sys/leases/lookup/database/creds/guardian-readonly/..."
```

**Remediation:**
| Failure Point | Action |
|---------------|--------|
| Vault write failed | Retry with backoff; check Vault logs |
| Checkpoint creation failed | Manual checkpoint, then retry rotation |
| New secret not readable | Verify policy allows read; check path |
| Dependent service not updated | Coordinate with consumer; rollback if needed |

**Emergency Manual Rotation:**
```powershell
# 1. Generate new secret
$newSecret = [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))

# 2. Write to Vault
Set-GuardianSecret -Name "bridge/token_001" -Value $newSecret -RequireCheckpoint

# 3. Update dependent configs
# 4. Verify consumers can read
Get-GuardianSecret -Name "bridge/token_001"
```

---

### 3.5 Audit Chain Break

**Symptoms:**
- `Verify-AuditChain` throws mismatch error
- Guardian alerts `audit_chain_break`

**Immediate Actions:**
```powershell
# 1. Identify break point
Verify-AuditChain -Path "D:\Nexus98_Guardian\logs\guardian_audit.jsonl"

# 2. Check for tampering
# Compare hash chain with Vault audit log
diff (Get-VaultAuditHashes) (Get-GuardianAuditHashes)

# 3. If tampering suspected: INCIDENT RESPONSE
# - Preserve logs
# - Notify security
# - Do NOT continue writing until cleared
```

**Recovery:**
- If single event corrupted: mark, continue chain from last good
- If systemic: full audit log rebuild from Vault audit device
- Document in incident report

---

### 3.6 Emergency Access Used (Break-Glass)

**Trigger:** Any `EMERGENCY_ACCESS` audit event

**Required Actions (within 5 min):**
1. **Page Admin + Security** — Automatic via alert
2. **Verify legitimacy** — Check requestor, reason, approval
3. **Monitor usage** — Track all operations by emergency token
4. **Revoke immediately after** — `Revoke-VaultToken -Token $emergencyToken`
5. **Post-incident review** — Within 24 hours

**Runbook Link:** `RUNBOOK_EMERGENCY_ACCESS.md`

---

## 4. Circuit Breaker Behavior

### 4.1 Configuration

```powershell
$SecretCircuitBreaker = @{
    FailureThreshold = 3           # Consecutive failures
    SuccessThreshold = 2           # Successes to close
    TimeoutSeconds = 30            # Open state duration
    HalfOpenRequests = 3           # Test requests in half-open
}
```

### 4.2 States

| State | Behavior | Transition |
|-------|----------|------------|
| **Closed** | Normal operation, requests pass through | 3 failures → Open |
| **Open** | Requests fail fast, return cached secret with staleness warning | 30s → Half-Open |
| **Half-Open** | Limited test requests (3), if all succeed → Closed | 2 successes → Closed, 1 failure → Open |

### 4.3 Cache During Open State

```powershell
function Get-CachedSecret {
    param([string]$Name)
    
    $cache = $script:SecretCache[$Name]
    if (-not $cache) { throw "No cached secret for $Name" }
    
    $age = (Get-Date) - $cache.Timestamp
    if ($age.TotalMinutes -gt 5) {
        Write-Warning "Cached secret for $Name is $([math]::Round($age.TotalMinutes,1)) min old (max 5)"
    }
    
    return @{
        Value = $cache.Value
        Stale = $age.TotalMinutes -gt 5
        AgeMinutes = [math]::Round($age.TotalMinutes, 1)
        Source = 'CACHE'
    }
}
```

---

## 5. Monitoring & Alerting

### 5.1 Key Metrics

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Vault latency (p99) | < 100ms | > 500ms |
| Secret read success rate | 100% | < 99.9% |
| Auth success rate | 100% | < 99.5% |
| Circuit breaker open duration | 0s | > 60s |
| Cache staleness | < 1 min | > 5 min |
| Rotation overdue | 0 | > 0 |

### 5.2 Dashboard Queries

```promql
# Vault latency
histogram_quantile(0.99, rate(vault_request_duration_seconds_bucket[5m]))

# Circuit breaker state
guardian_circuit_breaker_state{vault="GuardianVault"}

# Secret cache staleness
max(guardian_secret_cache_age_minutes)

# Rotation compliance
count(guardian_secret_rotation_overdue) > 0
```

---

## 6. Escalation Contacts

| Role | Primary | Secondary | PagerDuty |
|------|---------|-----------|-----------|
| **On-Call Engineer** | Eng-1 | Eng-2 | guardian-oncall |
| **Security Lead** | Sec-1 | Sec-2 | guardian-security |
| **Platform Admin** | Admin-1 | Admin-2 | guardian-admin |
| **Vault Operator** | Vault-1 | Vault-2 | guardian-vault |

---

## 7. Post-Incident Procedure

### 7.1 Required Within 1 Hour
- [ ] Incident timeline documented
- [ ] Root cause identified
- [ ] Mitigation verified

### 7.2 Required Within 24 Hours
- [ ] Incident report completed
- [ ] Action items created
- [ ] Stakeholders notified

### 7.3 Required Within 1 Week
- [ ] Action items implemented
- [ ] Runbook updated
- [ ] Team retrospective held

---

## 8. Quick Reference Commands

```powershell
# Health check
Test-SecretVaultConnection -Vault GuardianVault

# Force circuit breaker reset
Reset-SecretCircuitBreaker -Vault GuardianVault

# View circuit breaker state
Get-SecretCircuitBreakerStatus -Vault GuardianVault

# Emergency cache dump
Get-SecretCacheDump

# Manual secret rotation
Invoke-SecretRotation -Name "bridge/token_001" -RequireCheckpoint

# Audit chain verification
Verify-AuditChain -Path "D:\Nexus98_Guardian\logs\guardian_audit.jsonl"

# Generate emergency token (Admin only)
New-EmergencyVaultToken -Reason "Incident response" -TTL "30m"
```

---

## 9. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Guardian Operations | Initial release for WQ-002 |

---

*This runbook is executed by Guardian Operations. All procedures tested quarterly.*