# Template: Risk Assessment

**Type:** Risk Assessment  
**Status:** Draft  
**Version:** 1.0.0  

---

```yaml
---
title: "RISK-XXX: [Short Description]"
version: "1.0.0"
status: "Identified|Assessing|Mitigating|Monitoring|Accepted|Closed"
type: "Risk Assessment"
likelihood: "Rare|Unlikely|Possible|Likely|Almost Certain"
impact: "Insignificant|Minor|Moderate|Major|Critical"
score: "1-25"
category: "Technical|Operational|Security|Compliance|Strategic"
module: "Guardian_[ModuleName]"
tags:
  - risk
  - [category]
related:
  - "[[Components/[Component]]]"
  - "[[Gap Analysis/GAP-XXX]]"
  - "[[Technical Debt/DEBT-XXX]]"
  - "[[ADR-XXX]]"
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
owner: "Risk Owner"
review_date: "YYYY-MM-DD"
---
```

---

# RISK-XXX: [Short Description]

## 1. Risk Statement
**If [condition], then [consequence], resulting in [impact].**

## 2. Risk Analysis

### 2.1 Likelihood Assessment
| Factor | Rating | Evidence |
|--------|--------|----------|
| Threat frequency |  |  |
| Vulnerability exposure |  |  |
| Control effectiveness |  |  |
| **Overall Likelihood** |  |  |

### 2.2 Impact Assessment
| Dimension | Rating | Evidence |
|-----------|--------|----------|
| Availability |  |  |
| Integrity |  |  |
| Confidentiality |  |  |
| Compliance |  |  |
| Reputation |  |  |
| Financial |  |  |
| **Overall Impact** |  |  |

### 2.3 Risk Score
**Score: [Likelihood 1-5] × [Impact 1-5] = [Score 1-25]**

## 3. Current Controls
| Control | Type | Effectiveness | Gap |
|---------|------|---------------|-----|
|  | Preventive/Detective/Corrective | High/Med/Low |  |

## 4. Mitigation Options

### Option 1: [Name]
**Description:**
**Cost:**
**Timeline:**
**Residual Risk:**
**Pros:**
**Cons:**

### Option 2: [Name]
**Description:**
**Cost:**
**Timeline:**
**Residual Risk:**
**Pros:**
**Cons:**

### Option 3: Accept Risk
**Justification:**
**Monitoring Plan:**

## 5. Selected Mitigation
**Chosen Option:** Option [N]  
**Rationale:**

### Implementation Plan
| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
|  |  |  |  |

## 6. Monitoring & Review
| Metric | Threshold | Frequency | Owner |
|--------|-----------|-----------|-------|
|  |  |  |  |

**Next Review Date:** YYYY-MM-DD

## 7. History
| Date | Event | By |
|------|-------|-----|
|  | Identified |  |
|  | Assessed |  |
|  | Mitigated |  |
|  | Reviewed |  |

## 8. Related
- [[Gap Analysis/GAP-XXX]]
- [[Technical Debt/DEBT-XXX]]
- [[ADR-XXX]]

---

*Template Version: 1.0.0*