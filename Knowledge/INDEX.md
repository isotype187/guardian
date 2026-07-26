# Nexus98 Guardian — Knowledge Vault Index

**Vault Version:** 1.0.0  
**Last Updated:** 2026-07-26  
**Maintained By:** Guardian Engineering Team  

---

## 📁 Vault Structure

```
Knowledge/
├── 00 Dashboard/                    # Entry point & status
├── 01 Vision/                       # Mission, principles, success metrics
├── 02 Roadmap/                      # Phased development roadmap
├── 03 Architecture/                 # System architecture & components
├── 04 ADR/                          # Architecture Decision Records
├── 05 Components/                   # Component specifications
├── 06 Modules/                      # Module specifications
├── 07 Features/                     # Feature specifications
├── 08 Research/                     # Research notes & evaluations
├── 09 Standards/                    # Engineering standards
├── 10 Security/                     # Security architecture & policies
├── 11 Testing/                      # Testing strategies & frameworks
├── 12 CI-CD/                        # CI/CD pipeline design
├── 13 Deployment/                   # Deployment guides
├── 14 Operations/                   # Runbooks & operational procedures
├── 15 Troubleshooting/              # Troubleshooting guides
├── 16 Technical Debt/               # Technical debt register
├── 17 Risks/                        # Risk register
├── 18 Backlog/                      # Prioritized backlog
├── 19 Future Ideas/                 # Innovation & research ideas
├── 20 Releases/                     # Release notes & history
├── 21 Meetings/                     # Meeting notes & decisions
├── 22 Reference/                    # Quick reference & cheat sheets
├── 23 Glossary/                     # Terminology
├── 24 Templates/                    # Document templates
├── 25 Attachments/                  # Diagrams, exports, binaries
└── 99 Archive/                      # Superseded documents
```

---

## 📋 Document Index by Category

### 00 Dashboard
| Document | Status | Description |
|----------|--------|-------------|
| `DASHBOARD.md` | 📋 Planned | Vault health, recent changes, open items |

### 01 Vision
| Document | Status | Description |
|----------|--------|-------------|
| `VISION.md` | ✅ **Complete** | Mission, principles, success metrics, scope boundaries, anti-patterns |

### 02 Roadmap
| Document | Status | Description |
|----------|--------|-------------|
| `ROADMAP.md` | ✅ **Complete** | Dependency-driven phases M0-M13+ with goals, deliverables, risks, exit criteria |

### 03 Architecture
| Document | Status | Description |
|----------|--------|-------------|
| `OVERVIEW.md` | ✅ **Complete** | System context, module map, data architecture, comms, security, operational flows, health model, testing architecture |

### 04 ADR
| Document | Status | Description |
|----------|--------|-------------|
| `ADR-FRAMEWORK.md` | ✅ **Complete** | ADR process, template, lifecycle, index |
| `ADR-001.md` | ✅ **Complete** | Separation of Guardian and Nexus98 |
| `ADR-002.md` | ✅ **Complete** | Pester v5 → v6 migration |
| `ADR-003.md` | ✅ **Complete** | Checkpoint-before-change pattern |
| `ADR-004.md` | 📋 Proposed | Platform abstraction layer |
| `ADR-005.md` | 📋 Proposed | Secrets management strategy |
| `ADR-006.md` | 📋 Proposed | Distributed state store |

### 05 Components
| Document | Status | Description |
|----------|--------|-------------|
| `GOVERNANCE.md` | 📋 Planned | Policy engine design |
| `CHECKPOINTS.md` | 📋 Planned | Checkpoint system design |
| `BRIDGE.md` | 📋 Planned | Nexus98 communication bridge |
| `STORAGE.md` | 📋 Planned | Storage intelligence & entropy |
| `MEMORY.md` | 📋 Planned | Memory intelligence & patterns |
| `REMEDIATION.md` | 📋 Planned | Controlled remediation design |

### 06 Modules
| Document | Status | Description |
|----------|--------|-------------|
| `MODULE_GUARDIAN_ENV.md` | 📋 Planned | Path contracts & initialization |
| `MODULE_GUARDIAN_LOADER.md` | 📋 Planned | Module bootstrap & DAG |
| `MODULE_GUARDIAN_CONTRACTS.md` | 📋 Planned | Type system |
| `MODULE_GUARDIAN_GOVERNANCE.md` | 📋 Planned | Policy & risk |
| `MODULE_GUARDIAN_AUDIT.md` | 📋 Planned | Audit trail |
| `MODULE_GUARDIAN_HEALTH.md` | 📋 Planned | Health scoring |
| `MODULE_GUARDIAN_CHECKPOINT.md` | 📋 Planned | Checkpoint system |
| `MODULE_GUARDIAN_INTEGRITY.md` | 📋 Planned | Drift & entropy detection |
| `MODULE_GUARDIAN_RECOVERY.md` | 📋 Planned | Emergency restore |
| `MODULE_GUARDIAN_EVENTS.md` | 📋 Planned | Event store & bus |
| `MODULE_GUARDIAN_STORAGEINTEL.md` | 📋 Planned | Storage classification & health |
| `MODULE_GUARDIAN_MEMORY.md` | 📋 Planned | Short/long/pattern memory |
| `MODULE_GUARDIAN_PATTERNS.md` | 📋 Planned | Pattern recognition |
| `MODULE_GUARDIAN_OBSERVABILITY.md` | 📋 Planned | Unified observability |
| `MODULE_GUARDIAN_EXPLANATION.md` | 📋 Planned | Explanation engine |
| `MODULE_GUARDIAN_RESOURCE.md` | 📋 Planned | Resource telemetry |
| `MODULE_GUARDIAN_AGENTS.md` | 📋 Planned | Agent registry |
| `MODULE_GUARDIAN_SECURITY.md` | 📋 Planned | Config/permission monitoring |
| `MODULE_GUARDIAN_ACTIONPLANNING.md` | 📋 Planned | Remediation plans |
| `MODULE_GUARDIAN_REMEDIATION.md` | 📋 Planned | Controlled execution |
| `MODULE_GUARDIAN_GOVERNANCEINTEGRATION.md` | 📋 Planned | Decision→memory |
| `MODULE_GUARDIAN_COMMS.md` | 📋 Planned | Bridge contracts |
| `MODULE_GUARDIAN_DRIFTGUARD.md` | 📋 Planned | Architecture baseline & guard |
| `MODULE_GUARDIAN_BRIDGE.md` | 📋 Planned | Runtime message bus |
| `MODULE_GUARDIAN_STORAGERULES.md` | 📋 Planned | Hygiene rules |
| `MODULE_GUARDIAN_ENTROPYREMEDIATION.md` | 📋 Planned | Entropy analysis & remediation |
| `MODULE_GUARDIAN_OPERATIONS.md` | 📋 Planned | M10 orchestration |

### 07 Features
| Document | Status | Description |
|----------|--------|-------------|
| `event-bus.md` | 📋 Planned | Persistent event store with bus semantics |
| `checkpoint-system.md` | 📋 Planned | 4-tier checkpoint with rotation |
| `drift-detection.md` | 📋 Planned | 6-class architecture drift |
| `self-mod-guard.md` | 📋 Planned | Six-lock self-modification gate |
| `entropy-remediation.md` | 📋 Planned | Governed storage cleanup |
| `bridge-transport.md` | 📋 Planned | JSONL message bus with retry/dedup |

### 08 Research
| Document | Status | Description |
|----------|--------|-------------|
| `RESEARCH_SECRET_MANAGEMENT.md` | 📋 Planned | Vault/AKS/KeyVault evaluation |
| `RESEARCH_DISTRIBUTED_STATE.md` | 📋 Planned | etcd/Consul/SQL comparison |
| `RESEARCH_PLATFORM_ABSTRACTION.md` | 📋 Planned | Cross-platform path/process model |
| `RESEARCH_AI_TROUBLESHOOTING.md` | 📋 Planned | LLM-assisted root cause |

### 09 Standards
|| Document | Status | Description ||
||----------|--------|-------------|
|| `DOCUMENTATION_STANDARDS.md` | ✅ **Complete** | Frontmatter, naming, linking, validation ||
|| `TESTING_STANDARDS.md` | 📋 Planned | Pester v6, coverage, fixtures, CI gates ||
|| `CODING_STANDARDS.md` | 📋 Planned | PowerShell style, patterns, linting ||
|| `COMMIT_STANDARDS.md` | 📋 Planned | Conventional commits, milestone discipline ||
|| `REVIEW_STANDARDS.md` | 📋 Planned | PR requirements, architecture review ||
|| `RELEASE_STANDARDS.md` | 📋 Planned | Versioning, changelog, tagging ||
|| `RESOURCE_GOVERNANCE.md` | ✅ **Complete** | Resource monitoring, early warning, checkpoint, retry, failure intelligence ||

### 10 Security
| Document | Status | Description |
|----------|--------|-------------|
| `SECURITY_ARCHITECTURE.md` | 📋 Planned | Trust boundaries, threat model |
| `RBAC_MODEL.md` | 📋 Planned | Role definitions, permissions |
| `SECRETS_MANAGEMENT.md` | 📋 Planned | Vault integration, rotation |
| `AUDIT_POLICY.md` | 📋 Planned | What to audit, retention |
| `COMPLIANCE.md` | 📋 Planned | SOX/HIPAA/PCI mappings |

### 11 Testing
| Document | Status | Description |
|----------|--------|-------------|
| `TEST_STRATEGY.md` | 📋 Planned | Pyramid, conventions, gates |
| `TEST_FIXTURES.md` | 📋 Planned | Shared fixtures, factories |
| `PERFORMANCE_TESTING.md` | 📋 Planned | Benchmarks, regression detection |
| `CHAOS_TESTING.md` | 📋 Planned | Failure injection scenarios |

### 12 CI-CD
|| Document | Status | Description ||
||----------|--------|-------------|
|| `PIPELINE_DESIGN.md` | ✅ **Complete** | Full pipeline architecture with quality gates, matrix, security, contracts ||
|| `QUALITY_GATES.md` | 📋 Planned | Syntax → Unit → Integration → Arch → Policy → Contracts → Security → Performance ||
|| `ARTIFACTS.md` | 📋 Planned | Module packages, docs, SBOM |

### 13 Deployment
| Document | Status | Description |
|----------|--------|-------------|
| `DEPLOYMENT_GUIDE.md` | 📋 Planned | Single-node install |
| `CONTAINER_DEPLOYMENT.md` | 📋 Planned | Dockerfile, k8s manifests |
| `UPGRADE_PROCEDURE.md` | 📋 Planned | Rolling updates, rollback |

### 14 Operations
| Document | Status | Description |
|----------|--------|-------------|
| `RUNBOOK_HEALTH.md` | 📋 Planned | Health check procedures |
| `RUNBOOK_CHECKPOINT.md` | 📋 Planned | Create/restore/verify checkpoints |
| `RUNBOOK_REMEDIATION.md` | 📋 Planned | Safe remediation execution |
| `RUNBOOK_BRIDGE.md` | 📋 Planned | Bridge monitoring & recovery |
| `RUNBOOK_STORAGE.md` | 📋 Planned | Entropy scans & cleanup |
| `INCIDENT_RESPONSE.md` | 📋 Planned | Severity, escalation, communication |

### 15 Troubleshooting
| Document | Status | Description |
|----------|--------|-------------|
| `TROUBLESHOOTING_GUIDE.md` | 📋 Planned | Common issues, diagnostics |
| `DEBUGGING.md` | 📋 Planned | Module loading, bridge, drift |

### 16 Technical Debt
| Document | Status | Description |
|----------|--------|-------------|
| `ARCHITECTURE_AUDIT.md` | ✅ **Complete** | Full architecture audit M10 state |
| `GAP_ANALYSIS.md` | ✅ **Complete** | 19 gaps categorized by severity |
| `DEBT_REGISTER.md` | ✅ **Complete** | 20 debt items scored & scheduled |

### 17 Risks
| Document | Status | Description |
|----------|--------|-------------|
| `RISK_REGISTER.md` | ✅ **Complete** | 15 risks scored, mitigated, tracked |

### 18 Backlog
| Document | Status | Description |
|----------|--------|-------------|
| `BACKLOG.md` | 📋 Planned | Prioritized feature/tech debt backlog |

### 19 Future Ideas
| Document | Status | Description |
|----------|--------|-------------|
| `AI_ASSISTED_TROUBLESHOOTING.md` | 📋 Planned | LLM integration for root cause |
| `PREDICTIVE_MAINTENANCE.md` | 📋 Planned | Failure forecasting |
| `SELF_HEALING.md` | 📋 Planned | Autonomous remediation |
| `INTELLIGENT_DEPENDENCY.md` | 📋 Planned | ML-based conflict prediction |

### 20 Releases
| Document | Status | Description |
|----------|--------|-------------|
| `RELEASE_v1.0.0.md` | 📋 Planned | M10 completion release |
| `CHANGELOG.md` | 📋 Planned | Cumulative changes |

### 21 Meetings
| Document | Status | Description |
|----------|--------|-------------|
| `SESSION_20260725_M1_COMPLETE.md` | ✅ **Complete** | M1 repo hygiene session |
| `SESSION_20260725_M8_VALIDATION.md` | ✅ **Complete** | M8 bridge validation |
| `SESSION_20260725_M9_M10_VALIDATION.md` | ✅ **Complete** | M9/M10 validation |

### 22 Reference
| Document | Status | Description |
|----------|--------|-------------|
| `CLI_REFERENCE.md` | 📋 Planned | `guardian.ps1` command reference |
| `FUNCTION_REFERENCE.md` | 📋 Planned | All public functions by module |
| `CONFIG_REFERENCE.md` | 📋 Planned | All config keys with defaults |
| `EVENT_TYPES.md` | 📋 Planned | All event categories & schemas |
| `MESSAGE_TYPES.md` | 📋 Planned | Bridge message contracts |

### 23 Glossary
| Document | Status | Description |
|----------|--------|-------------|
| `GLOSSARY.md` | 📋 Planned | Canonical terminology |

### 24 Templates
| Document | Status | Description |
|----------|--------|-------------|
| `TEMPLATE_ADR.md` | ✅ **Complete** | Architecture Decision Record |
| `TEMPLATE_ARCHITECTURE.md` | ✅ **Complete** | Component architecture spec |
| `TEMPLATE_FEATURE.md` | ✅ **Complete** | Feature specification |
| `TEMPLATE_MODULE.md` | ✅ **Complete** | Module specification |
| `TEMPLATE_RESEARCH.md` | ✅ **Complete** | Research note |
| `TEMPLATE_BUG_INVESTIGATION.md` | ✅ **Complete** | Bug investigation report |
| `TEMPLATE_TECH_DEBT.md` | ✅ **Complete** | Technical debt entry |
| `TEMPLATE_RISK.md` | ✅ **Complete** | Risk assessment |
| `TEMPLATE_SESSION.md` | ✅ **Complete** | Session checkpoint |
| `TEMPLATE_MEETING.md` | ✅ **Complete** | Meeting notes |

### 25 Attachments
| Document | Status | Description |
|----------|--------|-------------|
| `ARCHITECTURE_DIAGRAM.drawio` | 📋 Planned | System architecture diagram |
| `MODULE_DEPENDENCY_GRAPH.svg` | 📋 Planned | Module DAG visualization |
| `BRIDGE_SEQUENCE.svg` | 📋 Planned | Message flow sequence |

### 99 Archive
| Document | Status | Description |
|----------|--------|-------------|
| `LEGACY_ROADMAP_v0.md` | 📦 Archived | Pre-M0 roadmap |
| `OLD_ADRS/` | 📦 Archived | Superseded ADRs |

---

## 🔗 Cross-Reference Matrix

| Document | Links To |
|----------|----------|
| `VISION.md` | `ROADMAP.md`, `OVERVIEW.md`, `ADR-001.md` |
| `ROADMAP.md` | `VISION.md`, `OVERVIEW.md`, `GAP_ANALYSIS.md`, `DEBT_REGISTER.md`, `RISK_REGISTER.md` |
| `OVERVIEW.md` | `VISION.md`, `ADR-001.md`, `ADR-003.md`, `Components/*`, `Modules/*` |
| `ADR-FRAMEWORK.md` | `ADR-001.md`, `ADR-002.md`, `ADR-003.md` |
| `GAP_ANALYSIS.md` | `ARCHITECTURE_AUDIT.md`, `ROADMAP.md`, `DEBT_REGISTER.md`, `RISK_REGISTER.md` |
| `DEBT_REGISTER.md` | `ARCHITECTURE_AUDIT.md`, `GAP_ANALYSIS.md`, `ROADMAP.md` |
| `RISK_REGISTER.md` | `ARCHITECTURE_AUDIT.md`, `GAP_ANALYSIS.md`, `DEBT_REGISTER.md` |

---

## 📊 Vault Health

| Metric | Target | Current |
|--------|--------|---------|
| **Orphan Documents** | 0 | 0 |
| **Broken Links** | 0 | 0 |
| **Frontmatter Coverage** | 100% | 100% |
| **Template Coverage** | All types | 10/10 |
| **Review Currency** | < 90 days | N/A (new) |

---

## 🛠️ Maintenance Rules

1. **Every code change** → Update affected specs in `05 Components/`, `06 Modules/`, `07 Features/`
2. **Every architectural decision** → Create ADR in `04 ADR/`
3. **Every session** → Checkpoint in `21 Meetings/`
4. **Every milestone** → Update `02 Roadmap/ROADMAP.md`, `20 Releases/`
5. **Quarterly** → Review `16 Technical Debt/`, `17 Risks/`, `18 Backlog/`
6. **Per Release** → Freeze `20 Releases/RELEASE_vX.Y.Z.md`

---

*Vault Index Version: 1.0.0*