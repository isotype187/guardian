# Template: Bug Investigation

**Type:** Bug Investigation  
**Status:** Draft  
**Version:** 1.0.0  

---

```yaml
---
title: "BUG: [Short Description]"
version: "1.0.0"
status: "Open|Investigating|Root Cause Found|Fixed|Closed|Won't Fix"
type: "Bug Investigation"
severity: "Critical|High|Medium|Low"
component: "[Guardian_Module]"
milestone: "[M-Number]"
tags:
  - bug
  - [module-name]
related:
  - "[[Components/[Component]]]"
  - "[[Tests/[Test Suite]]]"
  - "[[ADR-XXX]]"
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
owner: "Investigator"
---
```

---

# BUG: [Short Description]

## 1. Summary
One-sentence description of the bug.

## 2. Environment
| Property | Value |
|----------|-------|
| Guardian Version |  |
| PowerShell Version |  |
| OS |  |
| Platform | Windows/Linux/WSL/Container |
| Test Suite |  |

## 3. Reproduction Steps
1. 
2. 
3. 
4. 

## 4. Expected Behavior
What should happen.

## 5. Actual Behavior
What actually happens (error message, stack trace, incorrect output).

## 6. Logs & Evidence
```powershell
# Relevant log entries
Get-GuardianAudit -Filter @{Action='...'}
```

## 7. Investigation

### 7.1 Hypothesis 1
**Description:**  
**Test:**  
**Result:** ✅ Confirmed / ❌ Ruled out

### 7.2 Hypothesis 2
**Description:**  
**Test:**  
**Result:** ✅ Confirmed / ❌ Ruled out

## 8. Root Cause
Definitive cause statement.

## 9. Fix
### 9.1 Immediate (Workaround)
### 9.2 Permanent (Code Change)
| File | Change |
|------|--------|
|  |  |

## 10. Verification
- [ ] Unit test added
- [ ] Integration test added
- [ ] Regression test passes
- [ ] Manual verification

## 11. Prevention
| Measure | Implementation |
|---------|----------------|
|  |  |

## 12. Related
- [[Components/[Component]]]
- [[Tests/[Test Suite]]]
- [[ADR-XXX]]

---

*Template Version: 1.0.0*