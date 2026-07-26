# Security Architecture

> **Security model, threat analysis, RBAC, secrets management, and audit for Nexus98 Guardian.**
> **Version:** 1.0.0
> **Status:** Active
> **Type:** Architecture
> **Component:** Security_Architecture
> **Phase:** 0, 6, 7
> **Related:** [[ARCHITECTURE_OVERVIEW]], [[COMPONENT_ARCHITECTURE]], [[DATA_ARCHITECTURE]], [[THREAT_MODEL]], [[RBAC_MODEL]], [[SECRETS_MANAGEMENT]], [[AUDIT_LOGGING]], [[COMPLIANCE_REPORTING]]
> **Created:** 2026-07-19
> **Updated:** 2026-07-26
> **Owner:** Guardian Engineering Team
> **Review Date:** 2026-10-26

---

## 1. Security Principles

| Principle | Implementation |
|-----------|----------------|
| **Zero Trust** | Never trust, always verify; every mutation passes policy gate |
| **Least Privilege** | Roles scoped to minimum required operations |
| **Defense in Depth** | 4 trust zones, multiple gates per mutation |
| **Audit Everything** | Immutable audit trail on all decisions and mutations |
| **Fail Safe** | Default deny on policy errors; checkpoint before change |
| **Explain Decisions** | WHAT/WHY/EVIDENCE/IMPACT/REC for every automated decision |
| **Separation of Concerns** | Guardian ≠ Nexus98; bridge-only communication |

---

## 2. Trust Boundaries (Zero Trust Zones)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TRUSTED ZONE (Zone 0)                                │
│  Guardian Core: Loader, Contracts, Governance, Audit                        │
│  - Immutable after bootstrap                                                │
│  - No external input accepted directly                                      │
│  - Policy engine is the authority                                           │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │ Policy Gate: Test-GuardianPolicy
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       CONTROLLED ZONE (Zone 1)                               │
│  Observability, Memory, Storage, Recovery, Remediation                      │
│  - Read/write own state                                                     │
│  - Must pass Policy Gate for mutations                                      │
│  - Checkpoint Gate for state changes                                        │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │ Checkpoint Gate: New-GuardianCheckpoint
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       EXECUTION ZONE (Zone 2)                                │
│  Agents, Bridge Dispatcher, Remediation Executor                            │
│  - Execute approved plans only                                              │
│  - Manifest-backed operations                                               │
│  - Automatic rollback on failure                                            │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │ Validation Gate: Schema + Permissions
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       EXTERNAL ZONE (Zone 3)                                 │
│  Nexus98 Bridge, File System, Network, User Input                           │
│  - All input validated, sanitized                                           │
│  - Bridge messages: schema + sender auth + permissions                      │
│  - File ops: path traversal prevention, allowlist                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Zone Transition Rules

| Transition | Gate | Validation |
|------------|------|------------|
| Trusted → Controlled | Policy Gate | `Test-GuardianPolicy` evaluates action |
| Controlled → Execution | Checkpoint Gate | `New-GuardianCheckpoint -Tier Emergency` |
| Execution → External | Validation Gate | Schema validation, sender auth, permission check |
| External → Trusted | **Forbidden** | No direct path; must go through bridge |

---

## 3. Threat Model (STRIDE)

### 3.1 Asset Inventory

| Asset | Zone | Sensitivity | Impact if Compromised |
|-------|------|-------------|----------------------|
| Policy Engine | Trusted | Critical | Governance bypass |
| Audit Log | Trusted | Critical | Repudiation, forensics loss |
| Checkpoint Manifests | Controlled | High | Rollback failure |
| Bridge Messages | External | High | Command injection, data leak |
| Configuration | Controlled | High | Unauthorized changes |
| Secrets (future) | External | Critical | Full system compromise |
| Remediation Manifests | Controlled | High | Rollback corruption |

### 3.2 STRIDE Analysis

| Threat | Vector | Likelihood | Impact | Mitigation |
|--------|--------|------------|--------|------------|
| **Spoofing** | Bridge sender impersonation | Medium | High | Sender auth (cert/token), schema validation |
| **Tampering** | Checkpoint manifest modification | Low | Critical | SHA256 manifest, immutable tiers |
| **Repudiation** | Audit log deletion/modification | Low | Critical | Append-only JSONL, hash chaining (M13) |
| **Information Disclosure** | Bridge message interception | Medium | High | File perms, encryption at rest (M11) |
| **Denial of Service** | Event store flood | Medium | Medium | Size limits, rotation, monitoring |
| **Elevation of Privilege** | Policy engine bypass | Low | Critical | Multi-gate, default deny, drift detection |

### 3.3 Attack Surface

| Surface | Exposure | Controls |
|---------|----------|----------|
| Bridge Inbox | File system (JSONL) | Schema validation, sender auth, governance gate |
| Bridge Outbox | File system (JSONL) | Advisory only, no Nexus98 mutation |
| Config Files | File system (JSON) | File perms, checkpoint before change |
| Audit Log | File system (JSONL) | Append-only, immutable |
| Checkpoints | File system (dirs) | SHA256 manifest, tiered retention |
| Remediation Quarantine | File system (dirs) | Manifest-backed, checkpoint gate |
| Module Load | PowerShell session | Loader DAG validation, drift detection |

---

## 4. Authentication & Authorization

### 4.1 Current State (M10)
- **Authentication:** None (local execution only)
- **Authorization:** Policy engine (`Test-GuardianPolicy`) based on risk tier + checkpoint availability
- **Identity:** Implicit (process identity)

### 4.2 Planned RBAC Model (M13)

#### Roles
| Role | Description | Permissions |
|------|-------------|-------------|
| **System** | Automated Guardian processes | Write events, create checkpoints, execute approved plans |
| **Operator** | Day-to-day operations | Read health, view audit, request remediation |
| **Engineer** | Development & maintenance | Operator + approve remediation, modify policy (scoped) |
| **Admin** | Full control | Engineer + manage checkpoints, configure bridge, manage users |
| **Auditor** | Read-only compliance | Read audit, health, compliance reports |

#### Permission Matrix

| Operation | System | Operator | Engineer | Admin | Auditor |
|-----------|--------|----------|----------|-------|---------|
| Read health | ✅ | ✅ | ✅ | ✅ | ✅ |
| View audit log | ✅ | ✅ | ✅ | ✅ | ✅ |
| Request remediation | ✅ | ✅ | ✅ | ✅ | ❌ |
| Approve remediation | ✅ | ❌ | ✅ | ✅ | ❌ |
| Create checkpoint | ✅ | ❌ | ✅ | ✅ | ❌ |
| Restore checkpoint (rolling) | ✅ | ❌ | ✅ | ✅ | ❌ |
| Restore checkpoint (milestone) | ✅ | ❌ | ❌ | ✅ | ❌ |
| Modify policy packs | ✅ | ❌ | ✅ (scoped) | ✅ | ❌ |
| Configure bridge | ✅ | ❌ | ❌ | ✅ | ❌ |
| Manage users/roles | ❌ | ❌ | ❌ | ✅ | ❌ |
| Export compliance package | ✅ | ❌ | ✅ | ✅ | ✅ |

#### Approval Workflows
| Policy Decision | Required Approvers |
|-----------------|-------------------|
| `REQUIRE_REVIEW` (critical) | 1 Engineer + 1 Admin |
| `REQUIRE_CHECKPOINT` (high) | 1 Engineer |
| `ALLOW_WITH_MONITORING` (medium) | Auto (Operator notified) |
| `ALLOW` (low) | Auto |

---

## 5. Secrets Management (M11+)

### 5.1 Requirements
- No secrets in config files, checkpoints, or audit logs
- Integration with platform vaults (Azure Key Vault, HashiCorp Vault, AWS Secrets Manager)
- Automatic injection at runtime (never written to disk)
- Audit trail on every secret access
- Automated rotation with configurable schedules
- Emergency access procedures

### 5.2 Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                    GUARDIAN PROCESS                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              SecretManagement Module                     │   │
│  │  Get-GuardianSecret -Name "bridge/api-key" -Vault "AKV"  │   │
│  │         │                                              │   │
│  │         ▼ (in-memory only, never logged)                │   │
│  │  [Secret] → Used for bridge auth, DB connections, etc.  │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (mTLS / Managed Identity)
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNAL VAULT                                │
│  Azure Key Vault / HashiCorp Vault / AWS Secrets Manager        │
│  - RBAC on secrets                                              │
│  - Rotation policies                                            │
│  - Access logging                                               │
└─────────────────────────────────────────────────────────────────┘
```

### 5.3 Secret Categories
| Category | Examples | Rotation |
|----------|----------|----------|
| **Bridge Auth** | API keys, certificates | 90 days |
| **Vault Auth** | Vault tokens, AppRole credentials | 30 days |
| **External APIs** | Nexus98 tokens, cloud credentials | 90 days |
| **Encryption Keys** | Audit hash chain keys, backup encryption | 1 year |

---

## 6. Audit Logging

### 6.1 Current State (M10)
- **Format:** JSONL append-only (`logs/guardian_audit.jsonl`)
- **Integrity:** None (planned M13: hash chaining)
- **Retention:** 7 years (ARCHIVE class)
- **Schema:** See [[DATA_ARCHITECTURE#8]]

### 6.2 Planned Enhancements (M13)

#### Hash Chaining
```json
{
  "timestamp": "2026-07-26T14:30:00.123Z",
  "auditId": "AUD_abc123",
  "prevHash": "sha256:abc123...",  // Hash of previous entry
  "actor": "Guardian_Remediation",
  "action": "Invoke-GuardianRemediation",
  "...": "..."
}
```

#### Anchoring
- Periodic anchor to git commit: `anchor = HMAC(key, gitCommitHash + timestamp)`
- Stored in milestone checkpoint manifest
- Enables tamper detection across restarts

#### Verification
```powershell
Test-GuardianAuditIntegrity
# Returns: { valid: $true, brokenAt: null, entriesVerified: 12457 }
```

---

## 7. Compliance & Reporting

### 7.1 Compliance Frameworks (M13+)
| Framework | Scope | Evidence Required |
|-----------|-------|-------------------|
| **SOX** | Financial systems integrity | Audit log, change control, access control |
| **PCI-DSS** | Payment data protection | Encryption, access logging, vulnerability mgmt |
| **HIPAA** | Healthcare data | Audit trail, access control, encryption |
| **GDPR** | Personal data | Consent records, deletion logs, DPIA |

### 7.2 Evidence Package (Per Audit)
```
compliance-package-YYYY-MM-DD/
├── audit-log-hash-chain.json      # Verified integrity
├── checkpoint-manifests/          # All milestone checkpoints
├── policy-decisions.json          # All governance decisions
├── access-control-matrix.json     # RBAC assignments
├── secret-rotation-log.json       # Rotation compliance
├── vulnerability-scan-results.json # Dependency scans
├── incident-log.json              # Security incidents
└── architecture-baseline.json     # Drift-free certification
```

---

## 8. Platform Hardening

### 8.1 Windows (Primary)
| Control | Implementation |
|---------|----------------|
| **JEA** | Constrained endpoints for remediation, checkpoint ops |
| **Constrained Language Mode** | All Guardian modules run in CLM |
| **AMSI** | PowerShell script block logging |
| **WDAC** | Signed module enforcement (future) |
| **File Permissions** | ACLs on config, checkpoints, audit (Admin + System only) |

### 8.2 Linux/WSL (M12+)
| Control | Implementation |
|---------|----------------|
| **Capabilities** | Minimal: `CAP_DAC_READ_SEARCH`, `CAP_SYS_ADMIN` (checkpoint) |
| **Seccomp** | Syscall filter for Guardian process |
| **AppArmor** | Profile restricting filesystem access |
| **systemd Sandbox** | `ProtectSystem=strict`, `ReadWritePaths=/data /config /logs` |

### 8.3 Container (M12+)
| Control | Implementation |
|---------|----------------|
| **Non-root** | `USER guardian:guardian` |
| **Read-only rootfs** | `readOnlyRootFilesystem: true` |
| **Dropped capabilities** | `ALL` except `CAP_DAC_READ_SEARCH` |
| **Security contexts** | `allowPrivilegeEscalation: false` |

---

## 9. Supply Chain Security

### 9.1 Dependency Management
| Dependency Type | Source | Scanning |
|-----------------|--------|----------|
| **PowerShell Modules** | PSGallery, private feed | `PSScriptAnalyzer`, `Get-Module -ListAvailable` |
| **NuGet Packages** | nuget.org, private | `dotnet list package --vulnerable` |
| **Container Base Images** | MCR, distroless | `Trivy`, `Grype` |
| **Git Submodules** | Internal repos | Signed commits, verified checkout |

### 9.2 SBOM Generation (M11+)
- **Tool:** `Syft` or `dotnet sbom`
- **Format:** SPDX JSON
- **Per Release:** Published with release artifacts
- **Monitoring:** `Dependabot` / `Renovate` for updates

### 9.3 Signing & Verification
| Artifact | Signing | Verification |
|----------|---------|--------------|
| **Git Commits** | GPG/SSH | `git verify-commit` |
| **Module Files** | Authenticode | `Get-AuthenticodeSignature` |
| **Release Packages** | Cosign/Notary | `cosign verify` |
| **Container Images** | Cosign | `cosign verify` |

---

## 10. Incident Response (Security)

### 10.1 Security-Specific Playbooks

| Incident Type | Detection | Containment | Eradication | Recovery |
|---------------|-----------|-------------|-------------|----------|
| **Bridge Injection** | Schema validation failure | Disable bridge (`Set-GuardianBridgeEnabled $false`) | Purge malicious messages, rotate auth | Re-enable with new certs |
| **Policy Bypass** | Audit shows `BLOCK` → `ALLOW` anomaly | Emergency checkpoint, disable affected module | Root cause: code/config fix | Restore from clean checkpoint |
| **Secret Leak** | Secret scanning alert | Rotate leaked secret immediately | Audit all access since leak | Verify no unauthorized access |
| **Checkpoint Corruption** | Integrity check failure | Quarantine tier, use prior tier | Rebuild from source + known-good config | Verify restore, resume operations |

### 10.2 Escalation Matrix
| Severity | Response | Notify |
|----------|----------|--------|
| **Critical** (active breach) | 15 min | Security lead, Engineering lead, Management |
| **High** (vulnerability exploited) | 1 hour | Security lead, Engineering lead |
| **Medium** (policy anomaly) | 4 hours | Engineering lead |
| **Low** (scan finding) | Next sprint | Backlog |

---

## 11. Security Metrics

| Metric | Target | Source |
|--------|--------|--------|
| Mean Time to Detect (MTTD) | < 30 min | Audit log + monitoring |
| Mean Time to Respond (MTTR) | < 4 hours | Incident response |
| Secret Rotation Compliance | 100% | Vault audit |
| Dependency Vulnerability Age | < 7 days (critical) | Dependency scan |
| Audit Log Integrity | 100% verified | Hash chain verification |
| RBAC Policy Coverage | 100% protected surfaces | Policy engine |
| Bridge Message Validation Rate | 100% | Bridge metrics |
| Drift Detection Coverage | 100% load-time | Architecture baseline |

---

## 12. Future Security Enhancements

| Enhancement | Target | Description |
|-------------|--------|-------------|
| **eBPF Monitoring** | M14+ | Kernel-level syscall monitoring for anomaly detection |
| **ML Anomaly Detection** | M14+ | Behavioral analysis of event patterns |
| **Hardware Root of Trust** | M15+ | TPM-backed checkpoint signing |
| **Zero-Knowledge Proofs** | M15+ | Audit verification without log exposure |
| **Confidential Computing** | M15+ | Enclave-based policy evaluation |

---

## 📝 Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Team | Initial security architecture from M10 validated state |

---