# Architecture Decision Record (ADR) Framework

**Version:** 1.0.0  
**Status:** Active  
**Last Updated:** 2026-07-26  
**Owner:** Guardian Engineering Team  

---

## 📋 Purpose

This document defines the Architecture Decision Record (ADR) framework for the Nexus98 Guardian project. ADRs capture significant architectural decisions, their context, and consequences to maintain architectural clarity over time.

---

## 🎯 When to Create an ADR

Create an ADR for any decision that:

| Category | Examples |
|----------|----------|
| **Structural** | Module boundaries, layering, separation of concerns |
| **Technological** | Language, framework, platform, database, protocol choices |
| **Process** | Testing strategy, release cadence, branching model |
| **Cross-cutting** | Security model, observability, error handling patterns |
| **Integration** | External system contracts, API designs, bridge patterns |
| **Governance** | Policy enforcement, approval workflows, compliance |

**Do NOT create ADRs for:**
- Tactical implementation details (single function design)
- Reversible decisions with low impact
- Decisions already captured in existing ADRs

---

## 📝 ADR Template

Every ADR must follow this structure:

```markdown
# ADR-XXX: Short Descriptive Title

**ADR Number:** ADR-XXX  
**Title:** [Concise title]  
**Status:** [Proposed | Accepted | Rejected | Superseded | Deprecated]  
**Date:** YYYY-MM-DD  
**Authors:** [Names]  
**Reviewers:** [Names]  

---

## Context

Describe the situation forcing this decision. Include:
- Current state
- Constraints (technical, organizational, regulatory)
- Problem statement

## Problem Statement

Clear, concise statement of the architectural problem.

## Options Considered

### Option 1: [Name]
**Description:** Brief description
**Pros:**
- 
**Cons:**
-

### Option 2: [Name]
**Description:** Brief description
**Pros:**
- 
**Cons:**
-

### Option 3: [Name] (if applicable)
...

## Decision

**Selected Option:** Option [N] — [Name]

Explain the rationale for the selection.

## Consequences

### Positive
- 

### Negative
- 

### Risks Introduced
- Risk: Mitigation:

## Alternatives Rejected

Briefly explain why other options were not chosen.

## Implementation Notes

Any specific implementation guidance, patterns, or code references.

## Future Review

**Review Date:** YYYY-MM-DD (typically 6 months)
**Review Triggers:**
- 
- 

## References

- [[Related ADR]]
- [[Component/Document]]
- External links

---

*ADR Version: 1.0.0*
```

---

## 📂 ADR Lifecycle

```
Proposed → Under Review → Accepted → (Superseded) → (Deprecated)
                ↓
           Rejected
```

### Status Definitions

| Status | Meaning |
|--------|---------|
| **Proposed** | Draft under discussion; not yet approved |
| **Accepted** | Approved; implementation authorized |
| **Rejected** | Considered but not adopted; rationale recorded |
| **Superseded** | Replaced by newer ADR; link to replacement |
| **Deprecated** | No longer relevant; not replaced |

---

## 🔢 ADR Numbering

- Sequential: ADR-001, ADR-002, ADR-003...
- Never reuse numbers
- Superseded ADRs keep their number; new ADR references old

---

## 📋 Current ADR Index

| ADR | Title | Status | Date | Supersedes |
|-----|-------|--------|------|------------|
| [[ADR-001]] | Separation of Concerns: Guardian vs Nexus98 | Accepted | 2026-07-19 | — |
| [[ADR-002]] | Pester v5 to v6 Migration | Accepted | 2026-07-25 | — |
| [[ADR-003]] | Checkpoint-Before-Change Pattern | Accepted | 2026-07-19 | — |
| ADR-004 | [Reserved: Platform Abstraction Layer] | Proposed | — | — |
| ADR-005 | [Reserved: Secrets Management Strategy] | Proposed | — | — |
| ADR-006 | [Reserved: Distributed State Store] | Proposed | — | — |

---

## 🔗 ADR Cross-Reference Rules

1. **Every ADR must link** to related ADRs, components, and code
2. **Superseded ADRs must link** to their replacement
3. **Components must link** to governing ADRs
4. **Code comments should reference** ADR numbers for architectural patterns

Example in code:
```powershell
# Per ADR-003: Checkpoint before mutation
$cp = New-GuardianCheckpoint -Tier Emergency -Label "Pre-$MyInvocation.MyCommand"
```

---

## 🛠️ ADR Tooling (Future)

Planned for M11+:
- `New-GuardianADR` — Scaffold new ADR from template
- `Validate-GuardianADR` — Check format, links, required fields
- `Index-GuardianADRs` — Generate ADR index (this table)
- `Graph-GuardianADRs` — Visualize ADR dependency graph

---

## 📚 Related Documents

- [[Standards/DOCUMENTATION]] — Documentation standards
- [[Architecture/OVERVIEW]] — System architecture
- [[Roadmap/PHASES]] — Development roadmap
- [[Templates/ADR]] — ADR template file

---

*Framework Version: 1.0.0*