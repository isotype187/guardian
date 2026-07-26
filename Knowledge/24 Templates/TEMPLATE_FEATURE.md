# Template: Feature Specification

**Type:** Feature Specification  
**Status:** Draft  
**Version:** 1.0.0  

---

```yaml
---
title: "[Feature Name]"
version: "1.0.0"
status: "Proposed|Approved|In Progress|Done|Deferred"
type: "Feature Specification"
phase: "[Phase Number]"
milestone: "M-Number"
priority: "Critical|High|Medium|Low"
effort: "Small|Medium|Large|Extra Large"
module: "Guardian_[ModuleName]"
tags:
  - feature
  - [module-name]
related:
  - "[[Roadmap/ROADMAP]]"
  - "[[Components/[Component]]]"
  - "[[ADR-XXX]]"
  - "[[Tests/[TestFile]]]"
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
owner: "Feature Owner"
reviewers:
  - "Reviewer"
---
```

---

# [Feature Name]

## 1. Problem Statement
What user need or system requirement does this address?

## 2. User Story
**As a** [role]  
**I want to** [action]  
**So that** [benefit]

## 3. Acceptance Criteria
| ID | Criterion | Testable? |
|----|-----------|-----------|
| AC-01 |  | Yes/No |
| AC-02 |  | Yes/No |

## 4. Design

### 4.1 Architecture
How this fits into the existing architecture. Reference components.

### 4.2 Data Model
New or modified data structures.

### 4.3 API / Interface
Public functions, types, contracts.

### 4.4 Configuration
New config keys, defaults.

## 5. Implementation Plan
| Step | Task | Module | Effort | Dependencies |
|------|------|--------|--------|--------------|
| 1 |  |  |  |  |
| 2 |  |  |  |  |

## 6. Testing Strategy
| Test Type | Coverage | Tools |
|-----------|----------|-------|
| Unit |  | Pester |
| Integration |  | Pester |
| Architecture |  | Drift test |
| Policy |  | Governance test |

## 7. Rollout Plan
- [ ] Feature flag
- [ ] Canary
- [ ] Full rollout

## 8. Metrics
| Metric | Target | Measurement |
|--------|--------|-------------|
|  |  |  |

## 9. Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
|  |  |  |  |

## 10. Documentation
- [ ] Module help
- [ ] Architecture doc update
- [ ] ADR (if needed)
- [ ] Runbook

## 11. Related
- [[Milestones/M-XX]]
- [[Roadmap/ROADMAP]]
- [[ADR-XXX]]

---

*Template Version: 1.0.0*