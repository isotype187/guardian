# Security MOC (Map of Content)

> **Navigation hub for security architecture, threat model, RBAC, secrets, and audit.**

---

## 🛡️ Security Architecture

| Document | Purpose |
|----------|---------|
| [[SECURITY_ARCHITECTURE]] | Trust boundaries, defense in depth, zero-trust principles |
| [[THREAT_MODEL]] | STRIDE analysis, attack surface, mitigations |
| [[ZERO_TRUST_MODEL]] | Never trust, always verify, least privilege |

---

## 🔐 Authentication & Authorization

| Document | Purpose |
|----------|---------|
| [[RBAC_MODEL]] | Roles: Operator/Engineer/Admin/Auditor/System; permissions matrix |
| [[AUTHENTICATION]] | Identity providers: AD, OIDC, GitHub, API keys |
| [[AUTHORIZATION_POLICIES]] | Policy engine integration, approval workflows |

---

## 🔑 Secrets Management

| Document | Purpose |
|----------|---------|
| [[SECRETS_MANAGEMENT]] | Vault integration, rotation, injection, audit |
| [[SECRET_SCANNING]] | Pre-commit, CI, runtime scanning |
| [[CREDENTIAL_ROTATION]] | Automated rotation schedules, emergency procedures |

---

## 📋 Audit & Compliance

| Document | Purpose |
|----------|---------|
| [[AUDIT_LOGGING]] | Tamper-evident JSONL, hash chaining, retention |
| [[COMPLIANCE_REPORTING]] | SOX/PCI/HIPAA templates, evidence packages |
| [[FORENSIC_READINESS]] | Immutable logs, timeline reconstruction |

---

## 🛡️ Supply Chain Security

| Document | Purpose |
|----------|---------|
| [[DEPENDENCY_SCANNING]] | Pester, PowerShell modules, NuGet, container images |
| [[SBOM_GENERATION]] | Software Bill of Materials per release |
| [[SIGNING_VERIFICATION]] | Module signing, git commit signing, artifact verification |

---

## 🔒 Platform Hardening

| Document | Purpose |
|----------|---------|
| [[WINDOWS_HARDENING]] | JEA, constrained language mode, AMSI, WDAC |
| [[LINUX_HARDENING]] | Capabilities, seccomp, AppArmor, systemd sandboxing |
| [[CONTAINER_SECURITY]] | Non-root, read-only rootfs, dropped capabilities |

---

## 🚨 Incident Response

| Document | Purpose |
|----------|---------|
| [[SECURITY_INCIDENT_RESPONSE]] | Security-specific playbooks, containment, eradication |
| [[THREAT_INTELLIGENCE]] | IOC integration, threat feeds, hunting |
| [[VULNERABILITY_MANAGEMENT]] | CVE tracking, patch SLAs, compensating controls |

---

## 📊 Security Metrics

| Metric | Target | Source |
|--------|--------|--------|
| Mean Time to Detect (MTTD) | < 30 min | Audit log + monitoring |
| Mean Time to Respond (MTTR) | < 4 hours | Incident response |
| Secret Rotation Compliance | 100% | Vault audit |
| Dependency Vulnerability Age | < 7 days (critical) | Dependency scan |
| Audit Log Integrity | 100% verified | Hash chain verification |
| RBAC Policy Coverage | 100% protected surfaces | Policy engine |

---

## 🔗 Trust Boundaries (Recap)

```
┌────────────────────────────────────────────────────────────────┐
│                      TRUSTED ZONE                               │
│  Guardian Core (Loader, Contracts, Governance, Audit)          │
└──────────────────────────┬─────────────────────────────────────┘
                           │ Policy Gate (Test-GuardianPolicy)
                           ▼
┌────────────────────────────────────────────────────────────────┐
│                     CONTROLLED ZONE                             │
│  Observability, Memory, Storage, Recovery, Remediation         │
└──────────────────────────┬─────────────────────────────────────┘
                           │ Checkpoint Gate (New-GuardianCheckpoint)
                           ▼
┌────────────────────────────────────────────────────────────────┐
│                     EXECUTION ZONE                              │
│  Agents, Bridge Dispatcher, Remediation Executor               │
└──────────────────────────┬─────────────────────────────────────┘
                           │ Validation Gate (Schema + Permissions)
                           ▼
┌────────────────────────────────────────────────────────────────┐
│                     EXTERNAL ZONE                               │
│  Nexus98 Bridge, File System, Network, User Input              │
└────────────────────────────────────────────────────────────────┘
```

---

## 🔗 Related MOCs

- [[PROJECT_MOC]] — Project central hub
- [[ARCHITECTURE_MOC]] — Security architecture details
- [[OPERATIONS_MOC]] — Security operations runbooks
- [[DEVELOPMENT_MOC]] — Secure coding standards
- [[RELEASE_MOC]] — Security in release process

---

*Security is not a feature. It's the foundation.*