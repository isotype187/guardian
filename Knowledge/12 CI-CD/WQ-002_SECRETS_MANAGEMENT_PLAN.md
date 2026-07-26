# WQ-002 Implementation Plan: Secrets Management

**Work Item:** WQ-002  
**Milestone:** M11 Core Hardening  
**Status:** PLANNING  
**Date:** 2026-07-26  
**Author:** Guardian Engineering Team  
**Review Required:** Guardian Architecture Review

---

## 1. Goal

Integrate Microsoft.PowerShell.SecretManagement with HashiCorp Vault (primary) and Azure Key Vault (secondary) to provide secure, auditable secret storage and retrieval for Guardian operations. Eliminate plaintext secrets from configuration files and environment variables.

---

## 2. Current State Analysis

### 2.1 Secrets Found in Codebase
- **None in active core modules** — No hardcoded secrets in `core/Guardian_*.ps1`
- **Potential exposure vectors:**
  - `config/` directory (gitignored) — Runtime config may contain secrets
  - `.env` files — Not currently used but possible future vector
  - Bridge communication — Message payloads could contain sensitive data
  - Nexus98 bridge credentials — Not yet implemented

### 2.2 Security Architecture Alignment
Per `Knowledge/10 Security/SECURITY_MOC.md` trust boundaries:
- **Trusted Zone** (Guardian Core) — Should NOT hold secrets directly
- **Controlled Zone** — SecretManagement module operates here
- **Execution Zone** — Consumes secrets via SecretManagement vault
- **External Zone** — Vault/Key Vault servers

---

## 3. Architecture Design

### 3.1 Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    Guardian Secret Layer                        │
├─────────────────────────────────────────────────────────────────┤
│  Guardian_Secrets.ps1 (New Module)                              │
│  ├── Register-SecretVault                                       │
│  ├── Get-GuardianSecret                                         │
│  ├── Set-GuardianSecret                                         │
│  ├── Remove-GuardianSecret                                      │
│  ├── Test-SecretVaultConnection                                 │
│  └── Invoke-SecretRotation                                      │
├─────────────────────────────────────────────────────────────────┤
│  Microsoft.PowerShell.SecretManagement (Wrapper)               │
│  ├── SecretStore (Abstract Interface)                           │
│  └── Cmdlets: Get-Secret, Set-Secret, Remove-Secret, etc.      │
├─────────────────────────────────────────────────────────────────┤
│  Vault Extension: Microsoft.PowerShell.SecretStore.Vault       │
│  OR: Az.KeyVault Extension                                     │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Vault Selection Matrix

| Criteria | HashiCorp Vault | Azure Key Vault | Local Dev Fallback |
|----------|-----------------|-----------------|-------------------|
| **On-prem/Cloud** | ✅ Both | ⚠️ Cloud only | ✅ Local |
| **PowerShell Module** | `SecretStore.Vault` | `Az.KeyVault` | Built-in |
| **Authentication** | Token, AppRole, AWS IAM | Managed Identity, SPN | File-based |
| **Rotation** | Native | Native | Manual |
| **Audit** | Comprehensive | Comprehensive | Basic |
| **M11 Priority** | **PRIMARY** | Secondary | Dev only |

---

## 4. Implementation Plan

### Phase 1: Foundation (Week 1)
**Goal:** Core SecretManagement integration module

| Task | Description | Deliverable |
|------|-------------|-------------|
| 1.1 | Create `core/Guardian_Secrets.ps1` module | Module skeleton with cmdlets |
| 1.2 | Add SecretManagement as dependency in loader | Updated `Guardian_Loader.ps1` |
| 1.3 | Implement `Register-SecretVault` with Vault config | Vault registration function |
| 1.4 | Implement `Get-GuardianSecret`/`Set-GuardianSecret` | Secret CRUD wrappers |
| 1.5 | Add to module inventory in PROJECT_INDEX.md | Documentation update |

### Phase 2: Vault Integration (Week 1-2)
**Goal:** Production-ready HashiCorp Vault integration

| Task | Description | Deliverable |
|------|-------------|-------------|
| 2.1 | Add `Microsoft.PowerShell.SecretManagement` module | Dependency installed |
| 2.2 | Add `Microsoft.PowerShell.SecretStore.Vault` extension | Vault extension installed |
| 2.3 | Configure Vault connection (address, token, mount path) | `config/vault.json` template |
| 2.4 | Implement AppRole authentication for CI/CD | AppRole config + token helper |
| 2.5 | Create Vault policy for Guardian secrets | HCL policy file |
| 2.6 | Test secret read/write/rotate cycles | Integration tests |

### Phase 3: Azure Key Vault Support (Week 2)
**Goal:** Secondary provider for Azure environments

| Task | Description | Deliverable |
|------|-------------|-------------|
| 3.1 | Add `Az.KeyVault` module | Dependency installed |
| 3.2 | Implement Managed Identity auth | MI configuration |
| 3.3 | Add provider selection logic (Vault vs KeyVault) | Auto-detection logic |
| 3.4 | Document Azure-specific setup | Setup guide |

### Phase 4: Integration & Hardening (Week 2-3)
**Goal:** Replace all secret vectors, add rotation, audit

| Task | Description | Deliverable |
|------|-------------|-------------|
| 4.1 | Audit config files for plaintext secrets | Scan report |
| 4.2 | Migrate any found secrets to Vault | Migration log |
| 4.3 | Implement `Invoke-SecretRotation` with schedule | Rotation function |
| 4.4 | Add secret access audit to `Guardian_Audit.ps1` | Audit integration |
| 4.5 | Create rotation schedule (90-day default) | Schedule config |
| 4.6 | Add emergency rotation procedure | Runbook |

### Phase 5: CI/CD Integration (Week 3)
**Goal:** Secure secret handling in pipeline

| Task | Description | Deliverable |
|------|-------------|-------------|
| 5.1 | Add Vault token to GitHub Actions secrets | OIDC or AppRole |
| 5.2 | Update `guardian-ci.yml` to register vault | Workflow update |
| 5.3 | Add secret validation step in CI | Pre-deployment check |
| 5.4 | Document secret promotion (dev→staging→prod) | Promotion guide |

---

## 5. Technical Specification

### 5.1 Module Interface: `Guardian_Secrets.ps1`

```powershell
# Register Vault as default secret store
function Register-SecretVault {
    param(
        [Parameter(Mandatory)][string]$VaultAddress,
        [Parameter(Mandatory)][string]$MountPath,
        [string]$AuthMethod = 'Token',  # Token, AppRole, AzureAD
        [string]$RoleId,
        [string]$SecretId,
        [string]$Token,
        [string]$Name = 'GuardianVault',
        [switch]$SetAsDefault
    )
}

# Get secret with metadata
function Get-GuardianSecret {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Vault = 'GuardianVault',
        [switch]$AsPlainText
    )
    # Returns: @{ Value; Metadata; Vault; RetrievedAt }
}

# Set secret with optional metadata
function Set-GuardianSecret {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value,
        [string]$Vault = 'GuardianVault',
        [hashtable]$Metadata = @{},
        [switch]$RequireCheckpoint
    )
}

# Remove secret
function Remove-GuardianSecret {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Vault = 'GuardianVault',
        [switch]$RequireCheckpoint
    )
}

# Test vault connectivity
function Test-SecretVaultConnection {
    param([string]$Vault = 'GuardianVault')
    # Returns: @{ Connected; LatencyMs; Version; MountPath }
}

# Rotate secret (generate new, update, audit)
function Invoke-SecretRotation {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Vault = 'GuardianVault',
        [int]$Length = 32,
        [ValidateSet('Alphanumeric','Base64','Hex')][string]$Format = 'Base64',
        [switch]$RequireCheckpoint
    )
}

# List all secrets (metadata only, no values)
function Get-GuardianSecretInventory {
    param([string]$Vault = 'GuardianVault')
    # Returns: @{ Name; Metadata; Created; Updated; RotationDue }
}
```

### 5.2 Configuration Schema

**`config/vault.json`** (template — gitignored, deployed via CI):
```json
{
  "vault": {
    "address": "https://vault.example.com:8200",
    "mountPath": "secret/guardian",
    "authMethod": "AppRole",
    "roleId": "${VAULT_ROLE_ID}",
    "secretId": "${VAULT_SECRET_ID}",
    "token": "${VAULT_TOKEN}",
    "namespace": "",
    "tlsSkipVerify": false,
    "timeoutSeconds": 30
  },
  "keyVault": {
    "vaultUri": "https://guardian-kv.vault.azure.net",
    "useManagedIdentity": true,
    "clientId": "",
    "tenantId": ""
  },
  "defaults": {
    "provider": "Vault",
    "rotationIntervalDays": 90,
    "requireCheckpointForWrite": true,
    "requireCheckpointForDelete": true,
    "auditAccess": true
  },
  "secretCategories": {
    "bridge": { "rotationDays": 30, "format": "Base64" },
    "api": { "rotationDays": 90, "format": "Alphanumeric" },
    "database": { "rotationDays": 60, "format": "Base64" },
    "certificate": { "rotationDays": 365, "format": "PEM" }
  }
}
```

### 5.3 Vault Policy (HCL)

```hcl
# guardian-secrets-policy.hcl
path "secret/data/guardian/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/guardian/*" {
  capabilities = ["list", "read"]
}

path "secret/rotate/guardian/*" {
  capabilities = ["update"]
}

# Deny raw access to root
path "secret/*" {
  capabilities = []
}
```

---

## 6. Security Requirements

### 6.1 Threat Mitigation

| Threat | Mitigation |
|--------|------------|
| Secret leakage in config | All secrets in Vault, config references only |
| Vault token compromise | AppRole with short TTL, CIDR-bound tokens |
| Unauthorized secret access | `Test-GuardianPolicy` gate on all secret ops |
| Secret rotation failure | Checkpoint before rotation, rollback on failure |
| Audit gap | Every secret access logged to `Guardian_Audit` |
| CI/CD secret exposure | OIDC token exchange, no static tokens in GH |

### 6.2 Compliance Controls

- **Rotation:** 90-day default, 30-day for bridge credentials
- **Access:** Checkpoint required for write/delete
- **Audit:** All operations logged with actor, timestamp, secret name (not value)
- **Backup:** Vault snapshots per Guardian checkpoint schedule

---

## 7. Testing Strategy

### 7.1 Unit Tests (New: `tests/Guardian.Secrets.Tests.ps1`)
- Vault registration with valid/invalid configs
- Secret CRUD operations (mock Vault)
- Rotation generates valid format
- Inventory returns metadata only
- Policy enforcement on write/delete

### 7.2 Integration Tests
- Live Vault (test namespace) read/write/rotate
- Azure Key Vault (dev subscription) read/write
- Failover: Vault → KeyVault automatic
- Checkpoint enforcement

### 7.3 Security Tests
- Gitleaks scan passes (no secrets in repo)
- PSScriptAnalyzer: no plaintext credentials
- Penetration test: token theft simulation

---

## 8. Documentation Updates

| Document | Update |
|----------|--------|
| `PROJECT_INDEX.md` | Add WQ-002 status, secret inventory |
| `Knowledge/10 Security/SECRETS_MANAGEMENT.md` | Full implementation guide |
| `Knowledge/12 CI-CD/PIPELINE_DESIGN.md` | Vault integration in pipeline |
| `Knowledge/14 Operations/RUNBOOK_SECRETS.md` | Rotation, emergency procedures |
| `Knowledge/15 Troubleshooting/TROUBLESHOOTING_GUIDE.md` | Vault connection issues |

---

## 9. Acceptance Criteria

| Criterion | Verification |
|-----------|--------------|
| Zero plaintext secrets in repo | `gitleaks detect --source .` passes |
| SecretManagement module loads | `Get-Module SecretManagement` |
| Vault registration succeeds | `Register-SecretVault` returns success |
| Secret read/write works | Round-trip test passes |
| Rotation produces valid secret | Format validation passes |
| Checkpoint required for write | Policy test blocks without checkpoint |
| Audit logs every access | `Get-GuardianAuditTrail` shows secret ops |
| CI pipeline uses Vault | Workflow run shows secret retrieval |
| Documentation complete | All 5 docs updated |

---

## 10. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Vault unavailable | Medium | High | Local fallback store, circuit breaker |
| AppRole token expiry | Low | High | Auto-renewal, monitoring alert |
| Migration misses secret | Low | Critical | Pre-migration scan, post-migration audit |
| KeyVault not available in CI | Medium | Medium | Skip Azure tests if no subscription |
| Secret format mismatch | Low | Medium | Validation in `Set-GuardianSecret` |

---

## 11. Effort Estimate

| Phase | Tasks | Effort (days) |
|-------|-------|---------------|
| 1. Foundation | 5 | 2 |
| 2. Vault Integration | 6 | 3 |
| 3. KeyVault Support | 4 | 2 |
| 4. Integration & Hardening | 6 | 3 |
| 5. CI/CD Integration | 4 | 2 |
| **Testing & Documentation** | **5** | **3** |
| **Total** | **30** | **15** |

---

## 12. Dependencies

### 12.1 Internal
- `Guardian_Audit.ps1` — Audit integration
- `Guardian_Checkpoint.ps1` — Write/delete gating
- `Guardian_Governance.ps1` — Policy enforcement
- `Guardian_Loader.ps1` — Module registration

### 12.2 External
- `Microsoft.PowerShell.SecretManagement` (≥ 1.4)
- `Microsoft.PowerShell.SecretStore.Vault` (≥ 1.0)
- `Az.KeyVault` (≥ 4.0) — Optional
- HashiCorp Vault server (≥ 1.15)

---

## 13. Next Steps

1. **Submit this plan** for Guardian architecture review
2. **On approval:** Begin Phase 1 implementation
3. **Create ADR-005** for Secrets Management Strategy
4. **Update PROJECT_INDEX.md** with WQ-002 READY → IN_PROGRESS
5. **Create checkpoint** before implementation starts

---

**Plan Status:** Ready for Guardian Review  
**Next Action:** Architecture review → Implementation start