# Architecture Decision Record Index

> **Master index of all ADRs for Nexus98 Guardian.**
> **Version:** 1.0.0
> **Status:** Active
> **Type:** Reference
> **Scope:** Project
> **Tags:** reference, adr, index
> **Related:** [[ADR_SYSTEM]], [[ADR_TEMPLATE]], [[ARCHITECTURE_OVERVIEW]]
> **Created:** 2026-07-19
> **Updated:** 2026-07-26
> **Owner:** Guardian Engineering Team
> **Review Date:** 2026-10-26

---

## 📋 ADR Registry

| ADR | Title | Status | Date | Authors | Supersedes | Related Components |
|-----|-------|--------|------|---------|------------|-------------------|
| [[ADR-001]] | Separation of Guardian and Nexus98 | ACCEPTED | 2026-07-19 | Guardian Team | — | Guardian_Bridge, Guardian_Contracts, Guardian_Governance |
| [[ADR-002]] | Pester v5 to v6 Migration | ACCEPTED | 2026-07-25 | Guardian Team | — | All test modules |
| [[ADR-003]] | Checkpoint-Before-Change Pattern | ACCEPTED | 2026-07-19 | Guardian Team | — | Guardian_Checkpoint, Guardian_Remediation, Guardian_Bridge |
| ADR-004 | Platform Abstraction Layer | PROPOSED | — | — | — | Guardian_Env, Guardian_Platform (future) |
| ADR-005 | Secrets Management Strategy | PROPOSED | — | — | — | Guardian_Secrets (future), Guardian_Config |
| ADR-006 | Distributed State Store | PROPOSED | — | — | — | Guardian_Orchestrator (future) |

---

## 📊 Status Summary

| Status | Count |
|--------|-------|
| ACCEPTED | 3 |
| PROPOSED | 3 |
| UNDER_REVIEW | 0 |
| SUPERSEDED | 0 |
| DEPRECATED | 0 |
| REJECTED | 0 |
| **TOTAL** | **6** |

---

## 🔗 ADR Dependency Graph

```
ADR-001 (Separation) ◄────┐
                          │
ADR-003 (Checkpoint) ◄────┼── Guardian_Bridge, Guardian_Remediation
                          │
ADR-002 (Pester v6) ◄─────┤   All test modules
                          │
ADR-004 (Platform) ──────►┤   Guardian_Env, Guardian_Platform
                          │
ADR-005 (Secrets) ────────►┤   Guardian_Config, Guardian_Bridge
                          │
ADR-006 (State Store) ────►┘   Guardian_Orchestrator
```

---

## 📝 ADR Creation Checklist

When creating a new ADR:

- [ ] Use next sequential number (ADR-XXX)
- [ ] Copy [[ADR_TEMPLATE]]
- [ ] Fill all required sections
- [ ] Set `status: PROPOSED`
- [ ] Add to this index table
- [ ] Link from affected component specs (`related` frontmatter)
- [ ] Submit for review (min 3 business days)

---

## 📚 Quick Links by Topic

### Foundation
- [[ADR-001]] — Guardian ≠ Nexus98 separation
- [[ADR-003]] — Checkpoint before mutation

### Testing
- [[ADR-002]] — Pester v6 migration

### Platform (Planned)
- [[ADR-004]] — Cross-platform abstraction
- [[ADR-005]] — Secrets management
- [[ADR-006]] — Distributed coordination

---

## 🔄 Maintenance

| Action | Frequency | Owner |
|--------|-----------|-------|
| Update index on new ADR | Immediate | ADR Author |
| Review PROPOSED ADRs | Weekly | Architect |
| Archive SUPERSEDED/DEPRECATED | Quarterly | Architect |
| Regenerate dependency graph | On change | Architect |

---

*This index is the single source of truth for ADR status. Update on every ADR change.*