# Template: Technical Debt Entry

**Type:** Technical Debt  
**Status:** Draft  
**Version:** 1.0.0  

---

```yaml
---
title: "DEBT: [Short Description]"
version: "1.0.0"
status: "Identified|Prioritized|In Progress|Done|Won't Fix"
type: "Technical Debt"
severity: "Critical|High|Medium|Low"
component: "[Guardian_Module]"
origin_milestone: "[M-Number]"
tags:
  - debt
  - [category]
related:
  - "[[Components/[Component]]]"
  - "[[ADR-XXX]]"
  - "[[Gap Analysis/GAP_ANALYSIS]]"
  - "[[Risk Register/RISK_REGISTER]]"
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
owner: "Debt Owner"
target_milestone: "[M-Number]"
---
```

---

# DEBT: [Short Description]

## 1. Description
What is the debt? What code/design is suboptimal?

## 2. Origin
When and why was this introduced?
- **Introduced:** [Milestone/Date]
- **Reason:** [Expediency, lack of knowledge, scope cut, etc.]
- **Context:** 

## 3. Impact
| Dimension | Impact |
|-----------|--------|
| Maintainability |  |
| Performance |  |
| Security |  |
| Scalability |  |
| Developer Experience |  |
| Operational Risk |  |

## 4. Current Workaround
How is this handled today?

## 5. Remediation Options

### Option A: [Name]
**Description:**  
**Effort:** [S/M/L/XL]  
**Risk:** [Low/Medium/High]  
**Pros:**  
-  
**Cons:**  
-  

### Option B: [Name]
**Description:**  
**Effort:** [S/M/L/XL]  
**Risk:** [Low/Medium/High]  
**Pros:**  
-  
**Cons:**  
-  

## 6. Recommended Approach
**Selected Option:** [A/B]  
**Rationale:**  

## 7. Remediation Plan
| Task | Effort | Dependencies | Target |
|------|--------|--------------|--------|
|  |  |  |  |

## 8. Acceptance Criteria
- [ ] 
- [ ] 

## 9. Related
- [[Components/[Component]]]
- [[ADR-XXX]]
- [[Gap Analysis/GAP_ANALYSIS]]
- [[Risk Register/RISK_REGISTER]]

---

*Template Version: 1.0.0*