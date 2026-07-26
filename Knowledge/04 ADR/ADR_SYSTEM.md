# Architecture Decision Record (ADR) System

> **Governance for architectural decisions in Nexus98 Guardian.**
> **Version:** 1.0.0
> **Status:** Active
> **Type:** Standard
> **Scope:** Project
> **Tags:** standard, adr, architecture, governance
> **Related:** [[ADR_INDEX]], [[ADR_TEMPLATE]], [[ARCHITECTURE_OVERVIEW]], [[ROADMAP_MANAGEMENT]]
> **Created:** 2026-07-26
> **Updated:** 2026-07-26
> **Owner:** Guardian Engineering Team
> **Review Date:** 2026-10-26

---

## 1. Purpose

Architecture Decision Records (ADRs) capture **significant architectural decisions** — their context, alternatives considered, rationale, and consequences. They provide a historical record for future maintainers and enforce deliberate decision-making.

---

## 2. When to Create an ADR

**Create an ADR for any decision that:**

| Category | Examples |
|----------|----------|
| **Structural** | Module boundaries, layering, separation of concerns |
| **Technological** | Language, framework, platform, protocol, database |
| **Cross-cutting** | Security model, observability, error handling, configuration |
| **Integration** | External system contracts, API design, bridge patterns |
| **Governance** | Policy enforcement, approval workflows, compliance |
| **Operational** | Deployment model, backup strategy, disaster recovery |

**Do NOT create ADRs for:**
- Tactical implementation details (single function design)
- Reversible decisions with low impact
- Decisions already captured in existing ADRs
- Tooling preferences (editor, formatter) — use standards docs

---

## 3. ADR Lifecycle

```
PROPOSED → UNDER_REVIEW → ACCEPTED → (SUPERSEDED) → (DEPRECATED)
                ↓
           REJECTED
```

### Status Definitions

| Status | Meaning |
|--------|---------|
| **PROPOSED** | Draft submitted, awaiting review |
| **UNDER_REVIEW** | Active review period (min 3 business days) |
| **ACCEPTED** | Approved; implementation authorized |
| **SUPERSEDED** | Replaced by newer ADR (link to replacement) |
| **DEPRECATED** | No longer relevant; not replaced |
| **REJECTED** | Reviewed but not adopted; rationale recorded |

---

## 4. ADR Process

### 4.1 Submission
1. Copy [[ADR_TEMPLATE]] to `Knowledge/04 ADR/ADR-XXX.md`
2. Fill all sections
3. Set `status: PROPOSED`
4. Link from `ADR_INDEX.md`

### 4.2 Review
- **Minimum review period:** 3 business days
- **Reviewers:** Architect + 1 domain expert + 1 stakeholder
- **Comments:** In PR or linked discussion

### 4.3 Decision
- **Accept:** Architect merges, sets `status: ACCEPTED`, updates `ADR_INDEX.md`
- **Reject:** Architect closes with rationale, sets `status: REJECTED`
- **Defer:** Return to PROPOSED with action items

### 4.4 Supersession
- New ADR created with `supersedes: ADR-XXX`
- Old ADR updated: `status: SUPERSEDED`, `superseded_by: ADR-YYY`
- Both linked in `ADR_INDEX.md`

---

## 5. ADR Template

See [[ADR_TEMPLATE]] for the authoritative template.

### Required Sections
| Section | Purpose |
|---------|---------|
| **Context** | Current situation, constraints, problem |
| **Decision** | What was decided (one sentence) |
| **Alternatives** | Options considered with trade-offs |
| **Consequences** | Positive, negative, risks, mitigations |
| **Implementation** | Key steps, timeline, dependencies |

### Metadata (Frontmatter)
```yaml
---
adr_number: "001"
title: "Short descriptive title"
status: "PROPOSED|UNDER_REVIEW|ACCEPTED|SUPERSEDED|DEPRECATED|REJECTED"
date: "YYYY-MM-DD"
authors: ["Name"]
reviewers: ["Name"]
supersedes: "ADR-XXX"  # optional
superseded_by: "ADR-YYY"  # optional
tags: ["architecture", "security", "platform"]
related_components: ["Guardian_Component"]
---
```

---

## 6. ADR Index

Maintained in `Knowledge/04 ADR/ADR_INDEX.md`:

| ADR | Title | Status | Date | Supersedes |
|-----|-------|--------|------|------------|
| [[ADR-001]] | Separation of Guardian and Nexus98 | ACCEPTED | 2026-07-19 | — |
| [[ADR-002]] | Pester v5 to v6 Migration | ACCEPTED | 2026-07-25 | — |
| [[ADR-003]] | Checkpoint-Before-Change Pattern | ACCEPTED | 2026-07-19 | — |
| ADR-004 | Platform Abstraction Layer | PROPOSED | — | — |
| ADR-005 | Secrets Management Strategy | PROPOSED | — | — |
| ADR-006 | Distributed State Store | PROPOSED | — | — |

---

## 7. ADR Quality Checklist

Before accepting, verify:

- [ ] Context clearly states the problem
- [ ] At least 3 alternatives considered (including status quo)
- [ ] Trade-offs documented (not just pros)
- [ ] Consequences include risks + mitigations
- [ ] Implementation notes are actionable
- [ ] Links to related components, ADRs, docs
- [ ] Frontmatter complete and accurate
- [ ] No orphan — linked from `ADR_INDEX.md` and component docs

---

## 8. Integration with Development

| Trigger | Action |
|---------|--------|
| **New milestone planning** | Review relevant ADRs for constraints |
| **Architecture review** | Verify implementation matches ADRs |
| **Incident postmortem** | Check if ADR gap contributed |
| **Onboarding** | New engineers read all ACCEPTED ADRs |
| **Quarterly audit** | Review SUPERSEDED/DEPRECATED for cleanup |

---

## 9. Tooling (M11+)

| Tool | Purpose |
|------|---------|
| `New-GuardianADR` | Scaffold ADR from template |
| `Validate-GuardianADR` | Check format, links, frontmatter |
| `Index-GuardianADRs` | Regenerate `ADR_INDEX.md` |
| `Graph-GuardianADRs` | Visualize ADR dependency graph |

---

## 📝 Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Team | Initial ADR system from M10 validated state |

---