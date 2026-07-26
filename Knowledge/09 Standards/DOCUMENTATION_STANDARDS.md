# Engineering Documentation Standards

> **Authoritative standards for all documentation in the Nexus98 Guardian project.**
> **Version:** 1.0.0
> **Status:** Active
> **Last Updated:** 2026-07-26
> **Owner:** Guardian Engineering Team
> **Review Cycle:** Quarterly (next: 2026-10-26)

---

## 1. File Naming Conventions

| Document Type | Pattern | Example |
|---------------|---------|---------|
| Architecture | `UPPER_SNAKE_CASE.md` | `ARCHITECTURE_OVERVIEW.md` |
| ADR | `ADR-XXX.md` | `ADR-001.md` |
| Component Spec | `PASCAL_CASE.md` | `CHECKPOINTS.md` |
| Feature Spec | `kebab-case.md` | `event-bus.md` |
| Standard | `UPPER_SNAKE_CASE.md` | `CODING_STANDARDS.md` |
| Template | `TEMPLATE_<type>.md` | `TEMPLATE_ADR.md` |
| Research | `RESEARCH_<topic>.md` | `RESEARCH_SECRET_MANAGEMENT.md` |
| Session | `SESSION_YYYYMMDD_<topic>.md` | `SESSION_20260725_M1_COMPLETE.md` |
| Release | `RELEASE_vX.Y.Z.md` | `RELEASE_v1.0.0.md` |
| Bug Investigation | `BUG_<short-desc>.md` | `BUG_BRIDGE_STALL.md` |
| Tech Debt | `DEBT_<short-desc>.md` | `DEBT_HARDCODED_PATHS.md` |

**Rules:**
- No spaces in filenames (use `_` or `-`)
- No special characters except `_`, `-`, `.`
- Version numbers in release files only
- ADR numbers are sequential, never reused

---

## 2. Folder Placement Rules

```
Knowledge/
├── 00 Dashboard/           # System status, quick links
├── 01 Vision/              # Mission, principles, metrics
├── 02 Roadmap/             # Phased development plan
├── 03 Architecture/        # System, component, data, security arch
├── 04 ADR/                 # Architecture Decision Records
├── 05 Components/          # Component specifications
├── 06 Modules/             # Module specifications
├── 07 Features/            # Feature specifications
├── 08 Research/            # Spikes, evaluations, PoCs
├── 09 Standards/           # Documentation, test, code, commit standards
├── 10 Security/            # Threat model, RBAC, secrets, audit
├── 11 Testing/             # Strategy, fixtures, performance, chaos
├── 12 CI-CD/               # Pipeline design, quality gates
├── 13 Deployment/          # Install, config, upgrade guides
├── 14 Operations/          # Runbooks, monitoring, maintenance
├── 15 Troubleshooting/     # Common issues, debugging
├── 16 Technical Debt/      # Audit, gaps, debt register
├── 17 Risks/               # Risk register
├── 18 Backlog/             # Prioritized work items
├── 19 Future Ideas/        # Innovation research
├── 20 Releases/            # Release notes, changelog
├── 21 Meetings/            # Session checkpoints
├── 22 Reference/           # CLI, function, config, event refs
├── 23 Glossary/            # Terminology
├── 24 Templates/           # Document templates
├── 25 Attachments/         # Diagrams, exports, binaries
└── 99 Archive/             # Superseded content
```

**Rules:**
- Every document lives in exactly one category folder
- MOCs (Maps of Content) live in category root (e.g., `03 Architecture/ARCHITECTURE_MOC.md`)
- Cross-cutting concerns documented in primary category, linked from secondary
- Never create new top-level folders without Architecture Review

---

## 3. Tags Taxonomy

### Required Tags (every document)
| Tag | Values | Purpose |
|-----|--------|---------|
| `type` | `architecture`, `adr`, `component`, `feature`, `standard`, `template`, `research`, `session`, `release`, `bug`, `debt`, `risk`, `moc` | Primary classification |
| `status` | `active`, `draft`, `deprecated`, `archived`, `superseded` | Lifecycle state |
| `phase` | `0`, `1`, `2`, `3`, `4`, `5`, `6`, `7`, `n/a` | Roadmap phase |

### Optional Tags (use liberally)
| Tag | Values | Purpose |
|-----|--------|---------|
| `component` | `guardian_env`, `guardian_loader`, `guardian_bridge`, ... | Module/component ownership |
| `milestone` | `M0`, `M1`, ..., `M13` | Milestone association |
| `priority` | `P0`, `P1`, `P2`, `P3` | Work prioritization |
| `security` | `threat-model`, `rbac`, `secrets`, `audit`, `compliance` | Security domain |
| `platform` | `windows`, `linux`, `wsl`, `container`, `cross-platform` | Platform scope |

**Tag Format:** lowercase, hyphen-separated, no spaces

---

## 4. Frontmatter Standard

**Every document MUST have YAML frontmatter:**

```yaml
---
title: "Human-Readable Title"
version: "1.0.0"
status: "active|draft|deprecated|archived|superseded"
type: "architecture|adr|component|feature|standard|template|research|session|release|bug|debt|risk|moc"
component: "Guardian_ModuleName"  # optional, for module/component docs
phase: "0|1|2|3|4|5|6|7|n/a"
milestone: "M0|M1|...|M13|n/a"  # optional
tags:
  - required-tag
  - optional-tag
related:
  - "[[LINK_TO_RELATED_DOC]]"
  - "[[ANOTHER_LINK]]"
dependencies:
  - "PREREQUISITE_DOC"
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
owner: "Team Name|Individual"
review_date: "YYYY-MM-DD"  # required for standards, ADRs, architecture
---
```

**Rules:**
- `title` must match H1 heading
- `version` follows SemVer for specs; `1.0.0` for standards/templates
- `status` must be one of the defined values
- `related` uses Obsidian wiki-links `[[DOC_NAME]]`
- `dependencies` lists prerequisite documents by title
- `review_date` required for: standards, ADRs, architecture docs (quarterly)
- `owner` = accountable team/individual

---

## 5. Linking Standards

### Internal Links (Obsidian Wiki-Links)
```markdown
# Correct
[[ARCHITECTURE_OVERVIEW]]
[[COMPONENT_CHECKPOINTS]]
[[ADR-001]]

# With display text
[[ARCHITECTURE_OVERVIEW|System Architecture]]
```

### External Links (Markdown)
```markdown
[PowerShell 7 Docs](https://learn.microsoft.com/powershell/)
[Pester v6 Migration](https://pester.dev/docs/usage/migration-guide)
```

### Code References
```markdown
# File reference
`core/Guardian_Loader.ps1`

# Function reference
`Test-GuardianPolicy`

# Line reference
`core/Guardian_Governance.ps1:L33-L45`
```

### Cross-Reference Rules
1. **No orphan documents** — every doc links to at least one other
2. **Bidirectional** — if A links to B, B should link back to A (in `related` or body)
3. **MOCs are hubs** — category MOCs link to all docs in category
4. **ADRs link to components** — every ADR references affected components
5. **Components link to governing ADRs** — every component spec lists its ADRs

---

## 6. Versioning & Change Tracking

### Document Versioning
| Document Type | Version Scheme | When to Bump |
|---------------|----------------|--------------|
| Architecture | SemVer | Structural changes |
| ADR | Immutable (never change after Accepted) | New ADR supersedes |
| Component Spec | SemVer | API changes, new responsibilities |
| Feature Spec | SemVer | Scope changes |
| Standard | SemVer | Rule changes |
| Template | SemVer | Structural changes |
| Research | `1.0.0` only | New research = new doc |
| Session | `1.0.0` only | Immutable after complete |
| Release | Matches release version | Per release |

### Change Log Section
Every document (except ADRs, sessions, research) ends with:

```markdown
---

## 📝 Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.1.0 | 2026-07-26 | Team | Added Linux path support |
| 1.0.0 | 2026-07-19 | Team | Initial release |

---
```

### ADR Supersession
```markdown
# ADR-003: New Decision

**Status:** Accepted
**Supersedes:** ADR-001
**Superseded By:** —
```

---

## 7. Document Ownership

| Document Type | Owner | Reviewers |
|---------------|-------|-----------|
| Architecture | Lead Architect | Engineering Team |
| ADR | Proposer | Architecture Review Board |
| Component Spec | Module Owner | Lead Architect, Peer |
| Feature Spec | Feature Owner | Lead Architect, QA |
| Standard | Standards Owner | All Engineers |
| Template | Standards Owner | All Engineers |
| Research | Researcher | Stakeholders |
| Session | Session Lead | Participants |
| Release | Release Manager | Engineering Team |

**Ownership Rules:**
- Every document has exactly one `owner` (team or individual)
- Owner accountable for accuracy, currency, review scheduling
- Ownership transfers documented in change log

---

## 8. Review Cycles

| Document Type | Review Frequency | Trigger |
|---------------|------------------|---------|
| Architecture | Quarterly | Milestone completion, ADR |
| ADR | On decision + 6 months | Supersession, architecture change |
| Component Spec | Per release | API changes, new dependencies |
| Feature Spec | On completion + quarterly | Scope change, milestone |
| Standard | Quarterly | Process change, tooling change |
| Template | Quarterly | Standard change |
| Research | On decision | Decision made |
| Session | Immutable after complete | — |
| Release | Per release | — |

### Review Checklist
- [ ] Frontmatter complete and accurate
- [ ] All wiki-links resolve (no broken links)
- [ ] Content reflects current implementation
- [ ] Related documents updated if needed
- [ ] Change log entry added
- [ ] `updated` date set to today
- [ ] `review_date` extended by review period

---

## 9. Documentation Lifecycle

```
DRAFT → REVIEW → ACTIVE → (SUPERSEDED → ARCHIVED)
         ↑           ↓
         └── DEPRECATED (if abandoned)
```

### State Transitions

| From | To | Conditions |
|------|-----|------------|
| Draft | Active | Review approved, frontmatter complete |
| Active | Superseded | New version replaces it (ADR, spec) |
| Active | Deprecated | No longer relevant, not replaced |
| Superseded | Archived | 2 quarters after supersession |
| Deprecated | Archived | 1 quarter after deprecation |
| Active | Archived | Never (must go through Superseded/Deprecated) |

### Archive Rules
- Move to `99 Archive/` with date prefix: `99 Archive/2026-Q3_DEPRECATED_DOC.md`
- Update `status: archived` in frontmatter
- Add `superseded_by: "[[NEW_DOC]]"` or `deprecated_reason: "..."`
- MOCs updated to remove links

---

## 10. What Gets Documented (and When)

### Mandatory Documentation
| Trigger | Required Documents |
|---------|-------------------|
| New module | Module spec (`06 Modules/`), Component spec if new component (`05 Components/`) |
| New feature | Feature spec (`07 Features/`), update component/module specs |
| Architectural decision | ADR (`04 ADR/`), update affected architecture/component docs |
| Milestone completion | Update roadmap (`02 Roadmap/`), release notes (`20 Releases/`), session checkpoint (`21 Meetings/`) |
| Breaking change | ADR, migration guide (`13 Deployment/`), version bump |
| Security incident | Incident report (`10 Security/`), update threat model if new vector |
| Technical debt identified | Debt entry (`16 Technical Debt/`), link from component spec |
| Risk identified | Risk entry (`17 Risks/`), link from roadmap/architecture |

### Timing Rules
- **Before implementation:** ADR, feature spec, component spec updates
- **During implementation:** Module spec updates, test plan
- **At milestone:** Roadmap update, release notes, session checkpoint
- **After incident:** Incident report, runbook updates, threat model review
- **Quarterly:** Standards review, architecture review, debt/risk review

---

## 11. Documentation Debt Prevention

### Anti-Patterns to Avoid
| Anti-Pattern | Prevention |
|--------------|------------|
| "We'll document later" | Doc required for PR merge (code + doc in same PR) |
| Outdated docs | Quarterly review gates, automated link checking |
| Orphan docs | MOC maintenance required per category |
| Duplicate content | Single source of truth; reference don't copy |
| Missing frontmatter | Template enforcement, CI validation |
| Broken links | CI check: `Validate-GuardianDocLinks` |

### Automation (M11 Target)
- `Validate-GuardianDocFrontmatter` — required fields, valid values
- `Validate-GuardianDocLinks` — all wiki-links resolve
- `Validate-GuardianDocOrphans` — no documents without inbound links
- `Index-GuardianDocs` — regenerate MOCs, cross-reference matrix

---

## 12. Templates

All templates in `24 Templates/`:

| Template | Purpose |
|----------|---------|
| `TEMPLATE_ADR.md` | Architecture Decision Record |
| `TEMPLATE_ARCHITECTURE.md` | Component/System Architecture |
| `TEMPLATE_COMPONENT.md` | Component Specification |
| `TEMPLATE_FEATURE.md` | Feature Specification |
| `TEMPLATE_MODULE.md` | Module Specification |
| `TEMPLATE_RESEARCH.md` | Research Note |
| `TEMPLATE_SESSION.md` | Session Checkpoint |
| `TEMPLATE_RELEASE.md` | Release Notes |
| `TEMPLATE_BUG_INVESTIGATION.md` | Bug Investigation |
| `TEMPLATE_TECH_DEBT.md` | Technical Debt Entry |
| `TEMPLATE_RISK.md` | Risk Assessment |
| `TEMPLATE_STANDARD.md` | Engineering Standard |

**Usage:** Copy template → fill frontmatter → write content → save in correct folder → link from MOC.

---

## 13. Enforcement

| Check | When | Failure Action |
|-------|------|----------------|
| Frontmatter validity | Pre-commit, CI | Block commit/PR |
| Link integrity | CI, Quarterly | Warn → Block after 2 quarters |
| Orphan detection | Quarterly | Warn → Create MOC entry |
| Review currency | Quarterly | Escalate to owner → Deprecate after 2 missed |
| Template compliance | PR review | Request changes |

---

*Standards are the grammar of engineering communication. Follow them.*