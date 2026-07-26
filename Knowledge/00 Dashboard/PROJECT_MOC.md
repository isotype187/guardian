# Project MOC (Map of Content)

> **Central navigation hub for the Nexus98 Guardian project knowledge vault.**

---

## 🎯 Project Essentials

| Document | Purpose |
|----------|---------|
| [[PROJECT_INDEX]] | Master project index — front door |
| [[VISION]] | Mission, principles, success metrics |
| [[ROADMAP]] | Phased M0–M13+ development plan |
| [[ARCHITECTURE_OVERVIEW]] | System architecture map |

---

## 📊 Current Status

- **Active Milestone:** Post-M10 / Pre-M11 (Planning)
- **Tests Passing:** 214+ across M0–M10
- **Architecture:** Stable, drift-free baseline
- **Repository:** Clean, versioned in `vcs/.git`

---

## 🧭 Navigation by Role

### For Architects
- [[ARCHITECTURE_OVERVIEW]] — System context, data flows, trust boundaries
- [[ADR_INDEX]] — Architecture Decision Records
- [[COMPONENT_ARCHITECTURE]] — Component responsibilities & interfaces
- [[DATA_ARCHITECTURE]] — State, config, logs, reports, cache
- [[SECURITY_ARCHITECTURE]] — AuthN/Z, secrets, threat model

### For Developers
- [[CODING_STANDARDS]] — Naming, structure, error handling, logging
- [[BRANCH_STRATEGY]] — Git workflow
- [[REVIEW_PROCESS]] — PR requirements, approvals
- [[TESTING_STRATEGY]] — Unit, integration, system, performance
- [[MODULE_TEMPLATE]] — New module scaffold

### For Release Engineers
- [[RELEASE_FRAMEWORK]] — Versioning, branching, notes, migration
- [[ROADMAP]] — Milestone schedule & dependencies
- [[CI_CD_PIPELINE]] — Build, test, deploy automation

### For Operators
- [[OPERATIONS_MANUAL]] — Install, config, update, backup, recovery
- [[RUNBOOKS]] — Health checks, checkpoint ops, remediation, bridge
- [[TROUBLESHOOTING]] — Common issues, debugging
- [[MONITORING_LOGGING]] — Health scores, alerts, audit

### For Security Auditors
- [[THREAT_MODEL]] — Attack surface, mitigations
- [[SECRETS_MANAGEMENT]] — Vault integration, rotation
- [[RBAC_MODEL]] — Roles, permissions, approval flows
- [[AUDIT_LOGGING]] — Tamper-evident audit trail

---

## 📁 Vault Structure

```
Knowledge/
├── 00 Dashboard/           # System health, quick status
├── 01 Vision/              # Mission, principles, metrics
├── 02 Roadmap/             # Phased plan M0–M13+
├── 03 Architecture/        # System, component, data, security
├── 04 ADR/                 # Architecture Decision Records
├── 05 Components/          # Component specifications
├── 06 Modules/             # Module specifications
├── 07 Features/            # Feature specifications
├── 08 Research/            # Spikes, evaluations, PoCs
├── 09 Standards/           # Doc, test, code, commit, review standards
├── 10 Security/            # Threat model, RBAC, secrets, audit
├── 11 Testing/             # Strategy, fixtures, performance, chaos
├── 12 CI-CD/               # Pipeline design, quality gates
├── 13 Deployment/          # Install, config, upgrade guides
├── 14 Operations/          # Runbooks, monitoring
├── 15 Troubleshooting/     # Common issues, debugging
├── 16 Technical Debt/      # Audit, gap analysis, debt register
├── 17 Risks/               # Risk register
├── 18 Backlog/             # Prioritized work items
├── 19 Future Ideas/        # Innovation research
├── 20 Releases/            # Release notes, changelog
├── 21 Meetings/            # Session checkpoints
├── 22 Reference/           # CLI, function, config, event refs
├── 23 Glossary/            # Terminology
├── 24 Templates/           # Document templates (10 types)
├── 25 Attachments/         # Diagrams, exports
└── 99 Archive/             # Superseded content
```

---

## 🔗 Cross-References

- **Roadmap → Architecture:** [[ROADMAP]] references [[ARCHITECTURE_OVERVIEW]] for phase dependencies
- **ADR → Architecture:** Each [[ADR]] links to affected [[COMPONENT]] docs
- **Tests → Components:** [[TESTING_STRATEGY]] maps test types to [[COMPONENT]] responsibilities
- **Risks → Roadmap:** [[RISK_REGISTER]] mitigation timelines align with [[ROADMAP]] phases
- **Debt → Roadmap:** [[DEBT_REGISTER]] paydown scheduled in [[ROADMAP]] milestones

---

## 📌 Quick Actions

```powershell
# Load Guardian
. .\core\Guardian_Loader.ps1; Import-Guardian

# Validate
.\tests\run_foundation_tests.ps1
Test-GuardianArchitectureDrift

# Health
Get-GuardianHealthReport
Get-GuardianStorageEntropy
```

---

*This MOC is the project's central nervous system. Keep it current.*