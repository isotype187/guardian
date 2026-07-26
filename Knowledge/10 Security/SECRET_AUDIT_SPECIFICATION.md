# Secret Audit Specification

**Version:** 1.0.0  
**Status:** Active  
**Owner:** Guardian Security Architecture  
**Review Date:** 2026-10-26  
**Classification:** Internal — Security Controlled

---

## 1. Purpose

Define the audit logging requirements, format, retention, and tamper-evidence mechanisms for all secret operations in Guardian. Ensure every secret access is traceable, verifiable, and compliant.

---

## 2. Audit Event Categories

| Category | Operations | Log Level |
|----------|------------|-----------|
| **Read** | Get-GuardianSecret, dynamic cred retrieval | INFO |
| **Write** | Set-GuardianSecret, secret creation | INFO |
| **Delete** | Remove-GuardianSecret, version destruction | WARN |
| **Rotation** | Invoke-SecretRotation, automated rotation | INFO |
| **Metadata** | Get-GuardianSecretInventory, policy changes | INFO |
| **Auth** | Vault login, token renewal, AppRole auth | INFO |
| **Admin** | Policy changes, seal/unseal, emergency access | WARN |
| **Failure** | Permission denied, vault sealed, network error | ERROR |

---

## 3. Audit Event Schema

### 3.1 Core Fields (Every Event)

```json
{
  "event_id": "EV_20260726_134254_abc123",
  "timestamp": "2026-07-26T13:42:54.123Z",
  "event_type": "SECRET_READ",
  "category": "READ",
  "severity": "INFO",
  
  "actor": {
    "entity_id": "approle_guardian-system_abc123",
    "role": "System",
    "auth_method": "approle",
    "client_ip": "10.0.1.42",
    "user_agent": "Guardian/1.0.0 (PowerShell 7.4)"
  },
  
  "target": {
    "secret_path": "secret/data/bridge/token_001",
    "secret_category": "BRIDGE_TOKEN",
    "vault_mount": "secret",
    "version": 5
  },
  
  "operation": {
    "action": "read",
    "success": true,
    "duration_ms": 23,
    "ttl_seconds": 3600,
    "cache_hit": false
  },
  
  "result": {
    "status": "SUCCESS",
    "error_code": null,
    "error_message": null,
    "value_hash": "sha256:a1b2c3d4..."  // Hash of secret value, NOT the value
  },
  
  "context": {
    "correlation_id": "corr_bridge_dispatch_001",
    "request_id": "req_abc123",
    "session_id": "sess_xyz789",
    "checkpoint_id": "CK_20260726_130000_0001"
  },
  
  "integrity": {
    "hash_chain_prev": "sha256:prev_event_hash...",
    "hash_chain_curr": "sha256:current_event_hash...",
    "signature": "sig_ed25519:..."
  }
}
```

### 3.2 Event Type Enumeration

| Event Type | Category | Description |
|------------|----------|-------------|
| `SECRET_READ` | READ | Secret value retrieved |
| `SECRET_WRITE` | WRITE | Secret created or updated |
| `SECRET_DELETE` | DELETE | Secret version destroyed |
| `SECRET_ROTATE` | ROTATION | Rotation executed |
| `SECRET_LIST` | METADATA | Inventory/list operation |
| `VAULT_AUTH` | AUTH | Successful authentication |
| `VAULT_AUTH_FAILED` | AUTH | Failed authentication |
| `TOKEN_RENEW` | AUTH | Token renewal |
| `POLICY_CHANGE` | ADMIN | Policy create/update/delete |
| `SEAL_STATUS` | ADMIN | Vault seal/unseal |
| `EMERGENCY_ACCESS` | ADMIN | Break-glass token used |
| `CACHE_HIT` | READ | Served from local cache |
| `CACHE_MISS` | READ | Cache miss, fetched from vault |
| `CACHE_INVALIDATE` | READ | Cache entry invalidated |

---

## 4. Tamper-Evidence: Hash Chaining

### 4.1 Chain Structure

```
Event_1: hash_curr = SHA256(event_data || "genesis")
Event_2: hash_curr = SHA256(event_data || hash_prev)
Event_3: hash_curr = SHA256(event_data || hash_prev)
...
```

### 4.2 Verification Algorithm

```powershell
function Verify-AuditChain {
    param([string]$AuditLogPath)
    
    $events = Get-Content $AuditLogPath | ConvertFrom-Json
    $prevHash = "genesis"
    
    foreach ($event in $events) {
        $expectedCurr = Get-HashChainCurrent $event $prevHash
        if ($event.integrity.hash_chain_curr -ne $expectedCurr) {
            throw "Chain broken at event $($event.event_id): expected $expectedCurr, got $($event.integrity.hash_chain_curr)"
        }
        if ($event.integrity.hash_chain_prev -ne $prevHash) {
            throw "Previous hash mismatch at event $($event.event_id)"
        }
        $prevHash = $event.integrity.hash_chain_curr
    }
    return $true
}
```

### 4.3 Digital Signing (Optional, High-Security)

- Ed25519 signature on each event
- Public key stored in Guardian config (read-only)
- Private key in HSM or Vault Transit

---

## 5. Audit Log Destinations

| Destination | Purpose | Retention | Format |
|-------------|---------|-----------|--------|
| **Guardian Audit Log** | Primary operational audit | 7 years | JSONL (append-only) |
| **Vault Audit Device** | Vault-native audit | 7 years | JSONL |
| **SIEM Forward** | Centralized monitoring | Per org policy | CEF/Syslog |
| **Immutable Archive** | Legal/compliance | 7+ years | WORM storage |

### 5.1 Guardian Audit Log Path

```
D:\Nexus98_Guardian\logs\guardian_audit.jsonl
```

### 5.2 Vault Audit Device Configuration

```hcl
# vault audit enable file file_path=/var/log/vault/audit.log
path "sys/audit/file" {
  capabilities = ["read", "update"]
}
```

---

## 6. Retention Policy

| Data Type | Retention | Disposal |
|-----------|-----------|----------|
| Secret value hashes | 7 years | Secure delete |
| Full audit events | 7 years | Secure delete |
| Hash chain anchors | Permanent | Never |
| Correlation indices | 7 years | Secure delete |
| Failed auth events | 3 years | Secure delete |
| Emergency access logs | 10 years | Secure delete |

---

## 7. Query & Analysis Patterns

### 7.1 Standard Queries

```powershell
# All secret reads in last 24h
Get-GuardianAuditTrail -EventType SECRET_READ -Since (Get-Date).AddDays(-1)

# Failed access attempts
Get-GuardianAuditTrail -Severity ERROR -Category AUTH

# Secret rotations in window
Get-GuardianAuditTrail -EventType SECRET_ROTATE -Since $start -Until $end

# Actor activity summary
Get-GuardianAuditTrail -EntityId "approle_guardian-system_*" | Group-Object event_type
```

### 7.2 Compliance Reports

| Report | Frequency | Audience |
|--------|-----------|----------|
| Secret Access Summary | Daily | Operator |
| Rotation Compliance | Weekly | Engineer |
| Failed Access Analysis | Weekly | Security |
| Emergency Access Review | Monthly | Admin |
| Full Audit Trail Export | Quarterly | Auditor |

---

## 8. Alerting Rules

| Rule | Condition | Severity | Action |
|------|-----------|----------|--------|
| `secret_access_anomaly` | > 3 std dev from baseline reads/hour | HIGH | Page on-call |
| `failed_auth_burst` | > 10 failed auths in 5 min | HIGH | Page security |
| `emergency_access_used` | Any emergency token generated | CRITICAL | Page admin + security |
| `audit_chain_break` | Verification fails | CRITICAL | Page admin + security |
| `vault_sealed` | Vault seal status change | CRITICAL | Page on-call |
| `rotation_overdue` | Secret past rotation window | MEDIUM | Ticket engineer |

---

## 9. Integration with Guardian Audit System

### 9.1 Write-GuardianAudit Extension

```powershell
function Write-GuardianSecretAudit {
    param(
        [Parameter(Mandatory)][string]$EventType,
        [Parameter(Mandatory)][string]$SecretPath,
        [Parameter(Mandatory)][string]$Action,
        [bool]$Success = $true,
        [string]$ErrorMessage,
        [hashtable]$Context = @{},
        [string]$ValueHash
    )
    
    $event = @{
        event_id = "EV_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$([guid]::NewGuid().ToString()[0..7])"
        timestamp = (Get-Date).ToString('o')
        event_type = $EventType
        category = $EventType -replace 'SECRET_|VAULT_|TOKEN_|POLICY_|SEAL_|EMERGENCY_|CACHE_' -split '_' | Select-Object -First 1
        severity = if ($Success) { 'INFO' } elseif ($ErrorMessage) { 'ERROR' } else { 'WARN' }
        actor = Get-CurrentActorInfo
        target = @{
            secret_path = $SecretPath
            secret_category = Get-SecretCategory $SecretPath
        }
        operation = @{
            action = $Action
            success = $Success
            error_message = $ErrorMessage
            value_hash = $ValueHash
        }
        context = $Context
        integrity = Get-HashChainValues
    }
    
    $event | ConvertTo-Json -Depth 10 | Add-Content -Path $Global:GuardianAuditPath
}
```

### 9.2 Calling Convention

```powershell
# In Get-GuardianSecret
Write-GuardianSecretAudit -EventType 'SECRET_READ' -SecretPath $Name -Action 'read' -Success $true -ValueHash (Get-SecretHash $secret.Value)

# In Set-GuardianSecret
Write-GuardianSecretAudit -EventType 'SECRET_WRITE' -SecretPath $Name -Action 'write' -Success $true

# In Remove-GuardianSecret
Write-GuardianSecretAudit -EventType 'SECRET_DELETE' -SecretPath $Name -Action 'delete' -Success $true
```

---

## 10. Failure Handling

### 10.1 Audit Write Failure

```powershell
try {
    Write-GuardianSecretAudit @params
}
catch {
    # Log to local fallback (Event Log)
    Write-EventLog -LogName 'Application' -Source 'Guardian' -EventId 1001 -EntryType Error -Message "Audit write failed: $($_.Exception.Message)"
    
    # Increment failure counter
    $script:auditFailures++
    
    # Alert if threshold exceeded
    if ($script:auditFailures -gt 5) {
        Send-GuardianAlert -Type 'AUDIT_WRITE_FAILURE' -Severity 'CRITICAL'
    }
}
```

### 10.2 Disk Full / Log Rotation

- Rotate at 100MB or daily
- Compress rotated logs
- Maintain hash chain across rotation (include last hash of previous file in first event of new file)

---

## 11. Testing Requirements

| Test | Description |
|------|-------------|
| **Audit Write** | Every secret operation produces audit event |
| **Schema Validation** | All events pass JSON schema validation |
| **Hash Chain** | Chain verifies correctly across 10,000 events |
| **Tamper Detection** | Modified event detected within 1 second |
| **Rotation** | Chain maintained across log rotation |
| **Failure Alert** | Alert fires on 5+ consecutive audit failures |
| **Query Performance** | 24h query returns in < 5 seconds |

---

## 12. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Guardian Security Architecture | Initial release for WQ-002 |

---

*This specification is enforced by `Guardian_Audit.ps1` and `Guardian_Secrets.ps1`. All secret operations MUST call `Write-GuardianSecretAudit`.*