# Secret Rotation Policy

**Version:** 1.0.0  
**Status:** Active  
**Owner:** Guardian Security Architecture  
**Review Date:** 2026-10-26  
**Classification:** Internal — Security Controlled

---

## 1. Purpose

Define automated and manual rotation procedures for all secrets managed by Guardian via HashiCorp Vault and Azure Key Vault. Ensure zero-downtime rotation, auditability, and compliance with 90-day maximum lifetime for static secrets.

---

## 2. Secret Categories & Rotation Schedules

| Category | Examples | Rotation Method | Max Lifetime | Emergency SLA |
|----------|----------|-----------------|--------------|---------------|
| **Dynamic Database** | PostgreSQL, SQL Server, Redis credentials | Vault Dynamic Secrets (TTL-based) | 1 hour (TTL) | N/A — auto |
| **Bridge/API Credentials** | Nexus98 bridge token, webhook secrets | Manual (Vault KV v2) | 30 days | 2 hours |
| **External API Keys** | GitHub, Azure, AWS, third-party SaaS | Manual (Vault KV v2) | 90 days | 4 hours |
| **Certificates** | TLS, mTLS, code signing | Manual (Vault PKI) | 365 days | 24 hours |
| **Encryption Keys** | Data encryption, backup encryption | Manual (Vault Transit) | 180 days | 8 hours |
| **Service Accounts** | CI/CD, automation, monitoring | Manual (Vault KV v2) | 90 days | 4 hours |
| **Recovery Keys** | Checkpoint decryption, disaster recovery | Manual (Vault KV v2) | 365 days | N/A — cold |

---

## 3. Rotation Methods

### 3.1 Automated: Vault Dynamic Secrets (Databases)

**Mechanism:** Vault database secrets engine generates short-lived credentials on read.

```hcl
# Vault database role configuration
path "database/creds/guardian-readonly" {
  capabilities = ["read"]
}
```

**Lifecycle:**
1. Guardian requests credential via `Get-GuardianSecret -Name 'db/guardian-readonly'`
2. Vault generates username/password with 1-hour TTL
3. Guardian caches for 50 minutes (TTL - 10 min buffer)
4. On cache expiry, new credential requested automatically
5. Vault revokes old credential at TTL expiry

**Advantages:** Zero manual intervention, automatic revocation, audit trail per request.

---

### 3.2 Semi-Automated: Vault KV v2 with Rotation Helper

**Mechanism:** `Invoke-GuardianSecretRotation` generates new value, writes to Vault, updates consumers.

```powershell
# Rotation command
Invoke-GuardianSecretRotation -Name 'bridge/nexus98-token' `
    -Format Base64 -Length 32 `
    -RequireCheckpoint
```

**Process:**
1. Checkpoint created (emergency tier)
2. New secret generated (cryptographically secure)
3. Written to Vault KV v2 (versioned)
4. Consumers notified via bridge (if applicable)
5. Checkpoint validated
6. Old version marked deprecated (not deleted — rollback available)

**Consumer Update Strategies:**
- **Polling:** Consumers re-read on 5-min cache expiry
- **Push:** Bridge sends `SECRET_ROTATED` event to Nexus98
- **Hybrid:** Critical consumers push, others poll

---

### 3.3 Manual: Azure Key Vault (Static Secrets)

**Mechanism:** Key Vault keys/secrets rotated via Azure CLI/PowerShell, synced to Vault if hybrid.

**Process:**
1. Generate new key/secret in AKV
2. Update Vault reference (if hybrid)
3. Update consumer configuration
4. Validate consumer functionality
4. Schedule old version purge (90-day retention)

---

### 3.4 Certificate Rotation (Vault PKI)

**Mechanism:** Vault PKI engine issues short-lived certificates.

```hcl
# Vault PKI role
path "pki/issue/guardian-internal" {
  capabilities = ["create", "update"]
}
```

**Process:**
1. Guardian requests cert via `Get-GuardianSecret -Name 'pki/guardian-internal'`
2. Vault issues cert with 90-day TTL (configurable)
3. Automated renewal at 75% TTL (67 days)
4. Old cert added to CRL if compromised
5. Consumers reload cert on next cache miss

---

## 4. Rotation Schedule & Automation

### 4.1 Automated Schedule (Cron in Guardian Operations)

| Secret Pattern | Schedule | Function |
|----------------|----------|----------|
| `bridge/*` | Daily 02:00 UTC | `Invoke-GuardianSecretRotation` |
| `api/*` | Weekly Sunday 03:00 UTC | `Invoke-GuardianSecretRotation` |
| `cert/*` | Daily 04:00 UTC | `Invoke-GuardianCertRenewal` |
| `db/*` | N/A — dynamic | N/A |

### 4.2 Manual Rotation Trigger

```powershell
# Emergency rotation
Invoke-GuardianSecretRotation -Name 'api/github-token' `
    -Emergency -Reason 'Suspected compromise' `
    -Checkpoint -NotifyConsumers
```

### 4.3 Rotation Notification

All rotations emit:
- **Audit Log:** `SECRET_ROTATED` event with old/new version IDs
- **Bridge Event:** `SECRET_ROTATION` to Nexus98 (if consumer)
- **Metrics:** Rotation duration, success/failure, consumer update status

---

## 5. Emergency Rotation Procedure

### 5.1 Triggers

- Suspected credential compromise
- Security incident response
- Vendor security advisory
- Failed compliance audit
- Personnel departure (privileged access)

### 5.2 Procedure

```powershell
# 1. Create emergency checkpoint
$ck = New-GuardianCheckpoint -Tier emergency -Reason "Emergency rotation: $reason"

# 2. Rotate secret with forced consumer notification
$new = Invoke-GuardianSecretRotation -Name $secretName `
    -Emergency -Reason $reason `
    -CheckpointId $ck.id `
    -NotifyConsumers

# 3. Validate consumer update
$status = Test-GuardianSecretConsumers -SecretName $secretName

# 4. If validation fails, rollback
if (-not $status.AllUpdated) {
    Restore-GuardianCheckpoint -Id $ck.id -Confirm:$false
    throw "Consumer update failed, rolled back"
}

# 5. Log and close
Write-GuardianAudit -Action 'EMERGENCY_ROTATION_COMPLETE' -Reason $reason
```

### 5.3 SLA

| Severity | Rotation Initiated | Consumers Updated | Validation Complete |
|----------|-------------------|-------------------|---------------------|
| Critical (compromise) | < 30 min | < 2 hours | < 4 hours |
| High (advisory) | < 2 hours | < 4 hours | < 8 hours |
| Medium (departure) | < 8 hours | < 24 hours | < 48 hours |

---

## 6. Rollback Procedure

### 6.1 Automatic Rollback Triggers

- Consumer validation fails (health check, auth failure)
- Rotation function throws exception
- Checkpoint restore requested manually

### 6.2 Rollback Process

```powershell
# 1. Identify last good checkpoint
$ck = Get-GuardianCheckpoint -Latest -Tier emergency

# 2. Restore (preserves Vault version history)
Restore-GuardianCheckpoint -Id $ck.id -Confirm:$false

# 3. Force consumer re-read
Invoke-GuardianCacheInvalidation -Pattern "secret/*"

# 4. Validate
Test-GuardianSecretConsumers -All
```

### 6.3 Vault Version Recovery

Vault KV v2 retains 10 versions by default. Manual version restore:

```bash
# Vault CLI
vault kv patch -version=3 secret/guardian/bridge/nexus98-token
```

---

## 7. Compliance & Audit

### 7.1 Required Evidence per Rotation

| Artifact | Location | Retention |
|----------|----------|-----------|
| Rotation request | Guardian audit log | 7 years |
| Checkpoint ID | Guardian checkpoint store | 7 years |
| Vault version diff | Vault audit log | 7 years |
| Consumer validation | Guardian health log | 2 years |
| Emergency justification | Incident record | 7 years |

### 7.2 Compliance Mapping

| Standard | Requirement | Implementation |
|----------|-------------|----------------|
| PCI DSS 3.2.1 | 8.2.3 / 8.2.4 | 90-day max, emergency procedure |
| NIST 800-53 | IA-5(1) / SC-12 | Cryptographic generation, key mgmt |
| SOC 2 | CC6.1 / CC6.7 | Access control, monitoring |
| ISO 27001 | A.9.4.3 / A.12.3.1 | Rotation schedule, audit trail |

---

## 8. Metrics & KPIs

| Metric | Target | Measurement |
|--------|--------|-------------|
| Rotation Success Rate | 100% | Automated + Manual |
| Emergency Rotation Time | < 30 min (initiate) | Timestamp diff |
| Consumer Update Latency | < 5 min (poll) / < 30 sec (push) | Bridge event timestamp |
| Rollback Frequency | < 1% of rotations | Audit log analysis |
| Secret Age at Rotation | < 95% of max lifetime | Secret metadata |

---

## 9. Runbook References

| Scenario | Runbook |
|----------|---------|
| Scheduled rotation failure | `RUNBOOK_SCHEDULED_ROTATION_FAILURE.md` |
| Emergency rotation | `RUNBOOK_EMERGENCY_ROTATION.md` |
| Consumer update failure | `RUNBOOK_CONSUMER_UPDATE_FAILURE.md` |
| Vault outage during rotation | `RUNBOOK_VAULT_OUTAGE.md` |
| Certificate renewal failure | `RUNBOOK_CERT_RENEWAL_FAILURE.md` |

---

## 10. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Guardian Security Architecture | Initial release for WQ-002 |

---

*This policy is enforced by Guardian Operations scheduler. Deviations require emergency checkpoint and audit log entry.*