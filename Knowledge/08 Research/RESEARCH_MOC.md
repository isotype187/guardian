# Research MOC (Map of Content)

> **Navigation hub for research notes, spikes, evaluations, and proof-of-concepts.**

---

## 🔬 Active Research Topics

| Topic | Document | Status | Target Milestone |
|-------|----------|--------|------------------|
| **Secret Management** | [[RESEARCH_SECRET_MANAGEMENT]] | 📋 Planned | M11 |
| **Distributed State Store** | [[RESEARCH_DISTRIBUTED_STATE]] | 📋 Planned | M13 |
| **Platform Abstraction** | [[RESEARCH_PLATFORM_ABSTRACTION]] | 📋 Planned | M12 |
| **AI-Assisted Troubleshooting** | [[RESEARCH_AI_TROUBLESHOOTING]] | 📋 Planned | M14+ |
| **Plugin Architecture** | [[RESEARCH_PLUGIN_ARCHITECTURE]] | 📋 Planned | M12 |
| **Bridge Transport Pluggability** | [[RESEARCH_BRIDGE_TRANSPORT]] | 📋 Planned | M12 |

---

## 📋 Research Template

Each research note follows [[TEMPLATE_RESEARCH]]:

```markdown
# RESEARCH: [Topic]

## 1. Research Question
Clear, specific question this research answers.

## 2. Context
Why this matters now. Related work, blockers, decisions waiting.

## 3. Scope
What is in scope. What is explicitly out of scope.

## 4. Methodology
- [ ] Literature review
- [ ] Prototype / Spike
- [ ] Benchmark
- [ ] Proof of concept
- [ ] Vendor evaluation
- [ ] Team discussion

## 5. Findings

### Option A: [Name]
**Description:**
**Pros:**
**Cons:**
**Evidence:**

### Option B: [Name]
...

## 6. Comparison
| Criterion | Option A | Option B | Option C |
|-----------|----------|----------|----------|
| Performance |  |  |  |
| Complexity |  |  |  |
| Maintenance |  |  |  |
| Cost |  |  |  |
| Risk |  |  |  |

## 7. Recommendation
**Recommended Option:** [Option X]
**Rationale:**

## 8. Implementation Implications
- Architecture changes:
- New dependencies:
- Migration path:
- Effort estimate:

## 9. Decision
**Status:** [None|Proceed|Reject|Defer]
**Decided By:** [Name]
**Date:** YYYY-MM-DD
**ADR Created:** [[ADR-XXX]] (if applicable)

## 10. Future Work
-

## 11. Sources
| Source | Type | Date | Relevance |
|--------|------|------|-----------|
|  | Doc|Blog|Paper|Video |  |  |
```

---

## 🎯 Research Priorities

### Immediate (M11 Blockers)
1. **Secret Management** — Must choose Vault/AKS/KeyVault + SecretManagement integration pattern
2. **CI/CD Pipeline Design** — GitHub Actions matrix, quality gates, artifact strategy
3. **JSON Schema Generation** — From `Guardian_Contracts` classes for contract testing

### Near-term (M12 Enablers)
4. **Platform Abstraction** — `Guardian_Platform` module design for Linux/WSL/Container parity
5. **Plugin SDK Architecture** — Manifest schema, isolated runspace, permission sandbox, extension points
6. **Bridge Transport Interface** — Abstract transport layer for JSONL/HTTP/MQTT/gRPC

### Medium-term (M13+)
7. **Distributed State Store** — etcd vs Consul vs SQL for multi-node coordination
8. **Audit Hash Chaining** — Tamper-evident audit log implementation

### Long-term (M14+ Intelligence)
9. **AI-Assisted Troubleshooting** — LLM integration with structured context, confidence scoring
10. **Predictive Maintenance** — Failure forecasting from pattern + resource trends
11. **Self-Healing Policies** — Autonomous remediation within policy bounds
12. **Intelligent Dependency Resolution** — ML-based conflict prediction for module updates

---

## 📁 Research Artifacts Location

```
Knowledge/
├── 08 Research/
│   ├── RESEARCH_SECRET_MANAGEMENT.md
│   ├── RESEARCH_DISTRIBUTED_STATE.md
│   ├── RESEARCH_PLATFORM_ABSTRACTION.md
│   ├── RESEARCH_AI_TROUBLESHOOTING.md
│   ├── RESEARCH_PLUGIN_ARCHITECTURE.md
│   ├── RESEARCH_BRIDGE_TRANSPORT.md
│   └── spikes/                    # Throwaway prototypes, benchmarks
│       ├── spike-secret-mgmt/
│       ├── spike-platform-abstraction/
│       └── ...
└── 19 Future Ideas/               # Promoted research → innovation backlog
```

---

## 🔗 Related MOCs

- [[PROJECT_MOC]] — Project central hub
- [[ROADMAP_MOC]] — Research → Milestone mapping
- [[ARCHITECTURE_MOC]] — Architecture impact of research
- [[DEVELOPMENT_MOC]] — SDK/Platform dev standards
- [[FUTURE_IDEAS_MOC]] — Promoted research ideas

---

*Research drives architecture. Document everything.*