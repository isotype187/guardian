# Secret Retrieval Policy

**Document ID:** SECRET_RETRIEVAL_POLICY.md  
**Version:** 1.0.0  
**Status:** Active  
**Owner:** Guardian Security Architecture  
**Review Date:** 2026-10-26  
**Classification:** Guardian Internal  

---

## 1. Purpose

Define the complete lifecycle of secret retrieval within the Guardian ecosystem, including caching behavior, invalidation triggers, staleness tolerance, and emergency access procedures. This policy ensures secrets are retrieved securely, efficiently, and with auditable guarantees.

---

## 2. Scope

**Applies to:**
- All Guardian modules retrieving secrets via `Guardian_Secrets.ps1`
- CI/CD pipelines consuming secrets
- Nexus98 bridge authentication
- Automated remediation and scheduled operations

**Excludes:**
- Human interactive sessions (separate procedure)
- One-time bootstrap secrets (handled via `Initialize-GuardianSecrets`)

---

## 3. Retrieval Lifecycle

### 3.1 Standard Retrieval Flow

```
Requestor (Module/CI/Task)
        │
        ▼
┌───────────────────────┐
│  Get-GuardianSecret   │  ← Validates caller identity
│  -Name <secret>       │
└───────────┬───────────┘
        │
        ▼
┌───────────────────────┐
│  Cache Lookup         │  ← Check in-memory + disk cache
│  (TTL: 5 min default) │
└───────────┬───────────┘
        │
    ┌───┴───┐
    │       │
  HIT     MISS
    │       │
    ▼       ▼
Return   Vault Request
Cached   (auth + fetch)
Value    │
    │       │
    ▼       ▼
Update   Return
Cache    Value
    │       │
    └───┬───┘
        ▼
    Return to Requestor
```

### 3.2 Cache Behavior

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| **Default TTL** | 5 minutes | Balance between performance and freshness |
| **Maximum TTL** | 1 hour | Hard ceiling regardless of secret class |
| **Minimum TTL** | 30 seconds | Prevents thundering herd on rotation |
| **Storage** | Encrypted (DPAPI/ProtectedData) | Memory protection at rest |
| **In-Memory** | Protected byte array | Not in plaintext in process memory |
| **Disk Cache** | Optional, encrypted file | Survives process restart |

### 3.3 Cache Key Structure

```
CacheKey = Hash(VaultName + MountPath + SecretName + Version)
```

- Version included to auto-invalidate on rotation
- Collision-resistant (SHA-256)

---

## 4. Invalidation Triggers

### 4.1 Automatic Invalidation

| Trigger | Action | Scope |
|---------|--------|-------|
| **Rotation Event** (Vault dynamic secret) | Immediate cache purge | Specific secret |
| **Manual Rotation** (`Invoke-SecretRotation`) | Immediate cache purge | Specific secret |
| **Policy Change** (Vault policy update) | Full cache flush | All secrets from affected mount |
| **Authentication Failure** | Full cache flush | All secrets for that vault |
| **Circuit Breaker Open** | Full cache flush | All secrets from that vault |

### 4.2 Explicit Invalidation

```powershell
# Module-initiated
Remove-GuardianSecretCache -Name 'bridge/token' -Vault 'GuardianVault'

# Administrative
Clear-GuardianSecretCache -All -Confirm:$true
```

---

## 5. Staleness Tolerance by Secret Class

| Secret Class | Max Staleness | Rotation Type | Cache TTL Override |
|--------------|---------------|---------------|-------------------|
| **Bridge Token** | 1 minute | Manual (30-day) | 1 minute |
| **Database Credentials** | 30 seconds | Dynamic (Vault TTL) | 30 seconds |
| **API Keys** | 5 minutes | Manual (90-day) | 5 minutes |
| **Certificates** | 15 minutes | Manual (365-day) | 15 minutes |
| **CI/CD Tokens** | 2 minutes | Manual (90-day) | 2 minutes |
| **Notification Webhooks** | 10 minutes | Manual (180-day) | 10 minutes |

**Configuration:** Defined in `config/vault.json` under `secretCategories`

---

## 6. Emergency Override Rules

### 6.1 Break-Glass Access

When cache is stale but Vault is unreachable:

```powershell
Get-GuardianSecret -Name 'critical/db' -AllowStale -MaxStaleness 300
```

**Constraints:**
- Requires `Admin` or `Engineer` role
- Logs `SECRET_EMERGENCY_READ` audit event
- Alerts on-call via PagerDuty
- Maximum staleness: 5 minutes (configurable per secret class)
- Returns cached value with `Stale = $true` metadata flag

### 6.2 Emergency Cache Bypass

```powershell
Get-GuardianSecret -Name 'critical/api' -ForceVault
```

- Skips cache entirely
- Direct Vault request
- Used when cache corruption suspected
- Requires `Admin` role

---

## 7. Memory Protection

| Layer | Mechanism |
|-------|-----------|
| **In-Memory** | `System.Security.Cryptography.ProtectedMemory` (DPAPI) |
| **Process Isolation** | Secret never logged, never in string, never in pipeline |
| **Cache File** | `ProtectedData.Protect()` with `CurrentUser` scope |
| **Paging Prevention** | `[GC]::KeepAlive()` on secret byte arrays |
| **Debugger Protection** | `DebuggerNonUserCode` attribute on secret handling functions |

---

## 8. Metrics & Monitoring

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Cache Hit Rate | > 80% | < 50% for 5 min |
| Vault Latency (p95) | < 200ms | > 1s |
| Stale Reads | 0 | > 0 |
| Emergency Reads | 0 | > 0 |
| Cache Miss Storm | < 10/sec | > 50/sec |

---

## 9. Failure Handling

| Scenario | Behavior |
|----------|----------|
| Vault unreachable, cache valid | Return cached value, emit `VAULT_UNAVAILABLE_CACHE_USED` |
| Vault unreachable, cache expired | Throw `VaultUnavailableException`, trigger circuit breaker |
| Authentication failure | Flush cache, throw `AuthenticationFailedException` |
| Permission denied | Throw `AccessDeniedException`, no cache fallback |
| Network timeout | Retry 3x with exponential backoff, then circuit breaker |

---

## 10. Implementation Requirements

### 10.1 `Get-GuardianSecret` Parameters

```powershell
param(
    [Parameter(Mandatory)][string]$Name,
    [string]$Vault = 'GuardianVault',
    [int]$CacheTTLSeconds = 300,           # Default 5 min
    [switch]$ForceVault,                   # Bypass cache
    [switch]$AllowStale,                   # Allow expired cache
    [int]$MaxStalenessSeconds = 300,       # Max staleness if AllowStale
    [ValidateSet('Operator','Engineer','Admin','Auditor')]
    [string]$CallerRole = 'Engineer'       # For audit/override
)
```

### 10.2 Return Object

```powershell
[PSCustomObject]@{
    Value           = $secretBytes          # Protected byte array
    Vault           = $vaultName
    Name            = $secretName
    RetrievedAt     = (Get-Date).ToString('o')
    Stale           = $false                # True if AllowStale used
    CacheHit        = $true                 # False if from Vault
    Version         = $vaultVersion         # For invalidation
    Metadata        = @{}                   # RotationDue, Owner, etc.
}
```

---

## 11. Compliance

| Requirement | Implementation |
|-------------|----------------|
| SOC 2 CC6.1 | Encrypted cache, access logging |
| PCI DSS 3.2.1 | No plaintext in memory/logs, rotation tracking |
| NIST 800-53 SC-28 | Memory protection, cache encryption |

---

## 12. Related Documents

- `SECRET_ROTATION_POLICY.md` — Rotation schedules and procedures
- `RBAC_SECRET_MAPPING.md` — Role-based access definitions
- `SECRET_AUDIT_SPECIFICATION.md` — Audit log format and integrity
- `RUNBOOK_SECRET_FAILURES.md` — Circuit breaker and fallback procedures
- `ADR-005-CICD-SECRET-AUTH.md` — CI/CD authentication decision

---

## 13. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Guardian Security Architecture | Initial release for WQ-002 condition resolution |

---

*This policy is enforced by Guardian architecture. Violations are detected at runtime and reported via audit system.*