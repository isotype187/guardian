# Architecture MOC (Map of Content)

> **Navigation hub for system architecture documentation.**

---

## 🏗️ System Overview

| Document | Purpose |
|----------|---------|
| [[ARCHITECTURE_OVERVIEW]] | System context, module map, data flows, trust boundaries, operational flows, health model |
| [[SYSTEM_CONTEXT]] | High-level topology: Human → Guardian → Bridge → Nexus98 |
| [[MODULE_TAXONOMY]] | 33 modules organized by layer: Foundation → Observability → Operations → Communication → Docs |

---

## 📦 Component Architecture

| Component | Document | Responsibility |
|-----------|----------|----------------|
| **Foundation** | [[COMPONENT_FOUNDATION]] | Env, Loader, Contracts, Governance, Audit, Health, Checkpoint, Integrity, Recovery |
| **Observability** | [[COMPONENT_OBSERVABILITY]] | Events, StorageIntel, Memory, Patterns, Observability, Explanation |
| **Operations** | [[COMPONENT_OPERATIONS]] | Resource, Agents, Security, ActionPlanning, Remediation, GovernanceIntegration |
| **Communication** | [[COMPONENT_COMMUNICATION]] | Comms, Bridge, DriftGuard, StorageRules, EntropyRemediation, Operations |
| **Documentation** | [[COMPONENT_SCRIBE]] | 7 Scribe modules for auto-generation |

---

## 🔄 Data Architecture

| Document | Purpose |
|----------|---------|
| [[DATA_ARCHITECTURE]] | Config, state, metadata, cache, logs, reports storage strategies |
| [[CHECKPOINT_SYSTEM]] | 4-tier checkpoint: rolling (72h), milestones (∞), emergency (30d), archive (7yr) |
| [[EVENT_STORE]] | JSONL event store with rotation, deduplication, replay |
| [[MEMORY_SYSTEM]] | Short-term (7d), long-term (365d), pattern memory with compression |
| [[AUDIT_LOG]] | Append-only JSONL with hash chaining (planned M13) |

---

## 🔒 Security Architecture

| Document | Purpose |
|----------|---------|
| [[SECURITY_ARCHITECTURE]] | Trust boundaries, threat model, RBAC model, audit requirements |
| [[THREAT_MODEL]] | Attack surface analysis, mitigations per zone |
| [[SECRETS_MANAGEMENT]] | SecretManagement + Vault/AKS integration (planned M11) |
| [[RBAC_MODEL]] | Operator/Engineer/Admin/Auditor/System roles (planned M13) |

---

## 🌉 Communication Architecture

| Document | Purpose |
|----------|---------|
| [[BRIDGE_ARCHITECTURE]] | Guardian ↔ Nexus98: JSONL bus, 6 message types, guarantees |
| [[MESSAGE_CONTRACTS]] | `Guardian_Contracts` types: HEALTH_REPORT, EXPLANATION, ALERT, TASK_CONTEXT, COMMAND, QUERY |
| [[TRANSPORT_GUARANTEES]] | FIFO ordering, exactly-once dedup, exponential backoff, dead-letter, replay |

---

## 🧪 Testing Architecture

| Document | Purpose |
|----------|---------|
| [[TESTING_ARCHITECTURE]] | Pyramid: Unit → Integration → E2E → Architecture drift → Policy compliance |
| [[QUALITY_GATES]] | Syntax → Unit → Milestone → Arch drift → Policy → Checkpoint (per milestone) |

---

## 📊 Health & Observability Model

| Document | Purpose |
|----------|---------|
| [[HEALTH_SCORING]] | Composite: Runtime(20%) + Storage(20%) + Memory(15%) + Recovery(20%) + Events(10%) + Checkpoints(15%) |
| [[EXPLANATION_ENGINE]] | WHAT/WHY/EVIDENCE/IMPACT/REC format for every automated decision |

---

## 🔗 Related MOCs

- [[PROJECT_MOC]] — Project central hub
- [[ROADMAP_MOC]] — Phase/milestone dependencies
- [[DEVELOPMENT_MOC]] — Dev standards per component
- [[TESTING_MOC]] — Test strategy
- [[OPERATIONS_MOC]] — Runbooks for each component
- [[SECURITY_MOC]] — Security deep-dive

---

*Architecture documents are the source of truth for system design. Keep them current.*