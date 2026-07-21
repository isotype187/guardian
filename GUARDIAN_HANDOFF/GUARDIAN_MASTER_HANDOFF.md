# Nexus98 Guardian Master Handoff

## Identity

Guardian is the operational supervisory intelligence layer for Nexus98.

Guardian protects Nexus98 from:

- Failure
- Unsafe action
- Corrupted state
- Architectural drift
- Storage entropy
- Uncontrolled growth

---

# Separation Principle

Guardian is not Nexus98.

Nexus98:

- Intelligence
- Creation
- Development

Guardian:

- Governance
- Stability
- Recovery
- Oversight

They cooperate but remain separate.

---

# Current Status

Milestone:

M9 - Storage Entropy Remediation

Status:

Complete

Completed:

M0-M9

Tests:

14/14 passing

Test Suite:

tests/Guardian.Foundation.Tests.ps1

---

# Health

Current score:

40.0%

Architecture:

40%

Storage Hygiene:

40%

Runtime:

98%

---

# Canonical Startup

Guardian loads through:

Guardian Bootstrap

↓

Guardian_Loader.ps1

↓

Import-Guardian

↓

Foundation Modules

---

# Legacy Warning

Do not load:

- snapshot_engine.ps1
- verification_engine.ps1
- recovery_engine.ps1

These are abandoned duplicates.

The M0 foundation replaced them.

---

# Foundation Modules

Guardian_Env.ps1
Guardian_Loader.ps1
Guardian_Contracts.ps1
Guardian_Governance.ps1
Guardian_Audit.ps1
Guardian_Health.ps1
Guardian_Checkpoint.ps1
Guardian_Integrity.ps1
Guardian_Recovery.ps1
Guardian_Comms.ps1
Guardian_DriftGuard.ps1
Guardian_Bridge.ps1
Guardian_StorageRules.ps1
Guardian_EntropyRemediation.ps1

---

# END GUARDIAN MASTER HANDOFF
