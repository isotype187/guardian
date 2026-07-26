# Gap Analysis — Nexus98 Guardian (M10 State)

**Version:** 1.0.0  
**Date:** 2026-07-26  
**Source:** Architecture Audit  
**Status:** Active  

---

## 📋 Gap Summary

| Category | Critical | Significant | Minor | Total |
|----------|----------|-------------|-------|-------|
| **Infrastructure** | 2 | 1 | 2 | 5 |
| **Security** | 1 | 1 | 0 | 2 |
| **Platform** | 0 | 1 | 2 | 3 |
| **Extensibility** | 0 | 1 | 1 | 2 |
| **Observability** | 0 | 1 | 2 | 3 |
| **Testing** | 0 | 1 | 1 | 2 |
| **Operations** | 1 | 0 | 1 | 2 |
| **TOTAL** | **4** | **6** | **9** | **19** |

---

## 🔴 Critical Gaps (Must Fix Before Scaling)

### GAP-001: No CI/CD Pipeline
**Category:** Infrastructure  
**Description:** No automated validation on pull requests or commits. All quality gates (syntax, tests, architecture drift, policy) run manually.  
**Impact:** High — Human error; no gate on main branch; unreviewed code can merge  
**Current State:** Manual `Invoke-Pester` runs; manual `Test-GuardianArchitectureDrift`  
**Required:** GitHub Actions workflow with stages:
1. Syntax validation (`Import-Module` all core modules)
2. Unit tests (Foundation + changed milestone tests)
3. Integration tests (affected cross-module flows)
4. Architecture drift check
5. Policy compliance on changed files
6. Documentation sync check  
**Dependencies:** None  
**Effort:** Medium (3-5 days)  
**Target:** M11  

---

### GAP-002: No Secrets Management
**Category:** Security  
**Description:** Configuration files (`config/guardian_state.json`, `config/guardian_runtime_config.json`) may contain sensitive values (API keys, connection strings). No integration with secret stores.  
**Impact:** High — Credential leakage; compliance violation; rotation impossible  
**Current State:** Plaintext JSON; `Guardian_Security` monitors file changes but doesn't encrypt  
**Required:** 
- Integrate `Microsoft.PowerShell.SecretManagement` + `SecretStore` extensions
- Support Azure Key Vault, HashiCorp Vault, AWS Secrets Manager
- Automatic injection at runtime (never written to disk)
- Audit trail on secret access  
**Dependencies:** GAP-001 (CI for secret scanning)  
**Effort:** Medium (5-7 days)  
**Target:** M11  

---

### GAP-003: No API Service Layer
**Category:** Infrastructure  
**Description:** All external interaction is via file-based JSONL bridge. No REST/gRPC API for health, checkpoints, remediation, policy evaluation, or inventory.  
**Impact:** High — Cannot integrate with monitoring, orchestration, or custom UIs  
**Current State:** `Guardian_Bridge` provides file-based message bus only  
**Required:** 
- `Guardian_API` module with REST endpoints
- Authentication (OIDC, API keys, mTLS)
- Authorization (RBAC — see GAP-006)
- OpenAPI/Swagger documentation
- Health/checkpoint/remediation/event/memory endpoints  
**Dependencies:** GAP-002 (auth needs secrets), GAP-006 (RBAC)  
**Effort:** High (15-20 days)  
**Target:** M13  

---

### GAP-004: Single-Node Architecture
**Category:** Operations  
**Description:** Guardian runs as a single process on one machine. No leader election, no shared state, no fleet coordination.  
**Impact:** High — No HA; no fleet management; single point of failure  
**Current State:** All state local (filesystem, JSONL, memory)  
**Required:**
- External state store (etcd, Consul, or SQL)
- Leader election for scheduler/orchestrator
- Fleet health aggregation
- Rolling update coordination
- Distributed checkpoint catalog  
**Dependencies:** GAP-003 (API for inter-node), GAP-002 (secrets for cluster auth)  
**Effort:** Very High (30+ days)  
**Target:** M13  

---

## 🟠 Significant Gaps

### GAP-005: Linux/WSL Platform Parity
**Category:** Platform  
**Description:** `Guardian_Env` has Windows paths hardcoded in places. Resource sampling (`Guardian_Resource`) uses CIM/WMI only. Scheduling uses Windows Task Scheduler only.  
**Impact:** Medium — Cannot run on primary dev platforms (Linux, WSL2); limits contributor pool  
**Current State:** Partial abstraction in `Guardian_Env`; `Get-GuardianPlatform` returns `Windows` only  
**Required:**
- Complete `Guardian_Platform` abstraction module
- Linux: `/proc`, `systemd` timers, `systemd` journal
- WSL: Hybrid path translation (`wslpath`), cross-boundary bridge
- Container: Health endpoint, volume mounts  
**Dependencies:** None  
**Effort:** High (10-15 days)  
**Target:** M12  

---

### GAP-006: No RBAC Implementation
**Category:** Security  
**Description:** Role model designed (Operator, Engineer, Admin, Auditor, System) but not enforced. All operations run as current user.  
**Impact:** Medium — No least-privilege; audit cannot distinguish actor intent  
**Current State:** `Guardian_Governance` has risk tiers but no identity context  
**Required:**
- Identity provider integration (AD, OIDC, GitHub)
- Token-based auth with claims
- Permission matrix per role per operation
- Approval workflows for `REQUIRES_APPROVAL` policies  
**Dependencies:** GAP-002 (secrets for IdP config), GAP-003 (API for auth)  
**Effort:** High (15-20 days)  
**Target:** M13  

---

### GAP-007: No Plugin SDK
**Category:** Extensibility  
**Description:** Extension points designed (health probes, event handlers, remediation actions, policy packs, bridge transports) but no SDK for third-party development.  
**Impact:** Medium — No ecosystem; all logic must be in core  
**Current State:** `Guardian_Agents` provides supervision but no plugin manifest/loading  
**Required:**
- `Guardian_PluginSDK` module
- Plugin manifest schema (name, version, permissions, entry points)
- Isolated runspace loading (or separate process)
- Permission sandbox (deny by default)
- Template: `New-GuardianPluginTemplate`
- Documentation generator  
**Dependencies:** GAP-003 (API for plugin registration)  
**Effort:** High (15-20 days)  
**Target:** M12  

---

### GAP-008: Audit Log Not Tamper-Evident
**Category:** Observability  
**Description:** `logs/guardian_audit.jsonl` is append-only but not cryptographically chained. No detection of truncation, modification, or injection.  
**Impact:** Medium — Compliance risk; forensic reliability  
**Current State:** JSONL lines with timestamp, actor, action, decision, result  
**Required:**
- Hash chaining: each entry includes `prevHash = SHA256(prevEntry)`
- Periodic anchoring (e.g., to git commit, external timestamp service)
- Verification command: `Test-GuardianAuditIntegrity`
- Alert on verification failure  
**Dependencies:** None  
**Effort:** Low (3-5 days)  
**Target:** M13  

---

### GAP-009: No Contract Testing for Bridge
**Category:** Testing  
**Description:** Bridge message schemas (`Guardian_Contracts` classes) validated at runtime but not in CI. Schema drift between Guardian and Nexus98 undetected until runtime.  
**Impact:** Medium — Integration failures in production  
**Current State:** PowerShell classes with `ValidateSet` enums; no JSON Schema  
**Required:**
- Generate JSON Schema from `Guardian_Contracts` classes
- Validate all bridge messages against schema in CI
- Schema versioning with backward compatibility rules
- Nexus98 consumer-driven contract testing (Pact or similar)  
**Dependencies:** GAP-001 (CI pipeline)  
**Effort:** Medium (5-7 days)  
**Target:** M11  

---

### GAP-010: No Performance Baselines
**Category:** Observability  
**Description:** No automated benchmarks. Cannot detect performance regressions in checkpoint creation, event ingestion, storage scan, remediation execution.  
**Impact:** Medium — Silent degradation  
**Current State:** Manual `Measure-Command` only  
**Required:**
- Benchmark suite: `Invoke-GuardianBenchmarks`
- Key operations: checkpoint create/restore, event write/read, storage scan, memory search, policy eval
- CI integration: fail if >10% regression
- Historical tracking in `data/benchmarks/`  
**Dependencies:** GAP-001 (CI pipeline)  
**Effort:** Medium (5-7 days)  
**Target:** M11  

---

## 🟡 Minor Gaps

| ID | Gap | Category | Effort | Target |
|----|-----|----------|--------|--------|
| GAP-011 | Hot module reload | Infrastructure | High | M14+ |
| GAP-012 | macOS support | Platform | High | M14+ |
| GAP-013 | Container health probes | Platform | Low | M12 |
| GAP-014 | Structured logging (Serilog-style) | Observability | Medium | M11 |
| GAP-015 | Prometheus metrics export | Observability | Medium | M13 |
| GAP-016 | Module manifest (`Guardian_Manifest.psd1`) | Infrastructure | Low | M11 |
| GAP-017 | Circular dependency detection in Loader | Infrastructure | Low | M12 |
| GAP-018 | Hard-coded paths audit | Technical Debt | Medium | M11 |
| GAP-019 | Shared test fixtures | Testing | Medium | M11 |

---

## 📊 Gap Closure Roadmap

```
M11 (Core Hardening)          M12 (SDK + Platform)         M13 (Enterprise)
├─ GAP-001: CI/CD             ├─ GAP-005: Linux/WSL        ├─ GAP-003: API Service
├─ GAP-002: Secrets           ├─ GAP-007: Plugin SDK       ├─ GAP-004: Multi-Node
├─ GAP-009: Contract Tests    ├─ GAP-013: Container        ├─ GAP-006: RBAC
├─ GAP-010: Benchmarks        ├─ GAP-017: Loader           ├─ GAP-008: Audit Hash
├─ GAP-014: Structured Logs   ├─ GAP-018: Hardcoded Paths  ├─ GAP-015: Prometheus
├─ GAP-016: Module Manifest   ├─ GAP-019: Test Fixtures    └─ GAP-011: Hot Reload (M14+)
└─ GAP-019: Test Fixtures
```

---

## 🔗 Related Documents

- [[Architecture Audit/ARCHITECTURE_AUDIT]] — Source audit
- [[Roadmap/ROADMAP]] — Phased remediation plan
- [[Technical Debt/DEBT_REGISTER]] — Technical debt items
- [[Risks/RISK_REGISTER]] — Risk register
- [[ADR/ADR-001]] — Separation of concerns
- [[ADR/ADR-004]] — Platform abstraction (proposed)
- [[ADR/ADR-005]] — Secrets management (proposed)

---

*Generated from Architecture Audit 2026-07-26. Update on each milestone completion.*