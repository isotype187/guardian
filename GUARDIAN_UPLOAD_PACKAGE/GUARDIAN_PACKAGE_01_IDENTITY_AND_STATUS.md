
==================================================
SOURCE FILE: 00_READ_FIRST.md
==================================================
# Guardian Read First

## Purpose

This folder contains the operational handoff package for Nexus98 Guardian.

Guardian is the operational supervisory intelligence layer of the Nexus98 ecosystem.

This package provides continuity for future AI agents, developers, and operators.

---

# System Identity

Guardian protects Nexus98 from:

- Failure
- Unsafe actions
- Corrupted state
- Architectural drift
- Storage entropy
- Uncontrolled growth

Guardian answers:

- Should this happen?
- Is this safe?
- Is the system healthy?
- Can it recover?
- Is instability developing?

---

# System Separation

Guardian and Nexus98 are separate systems.

Nexus98:

- Intelligence engine
- Creation engine
- Development ecosystem

Guardian:

- Governance layer
- Stability layer
- Recovery layer
- Health monitoring layer

Guardian protects Nexus98.

Guardian does not become Nexus98.

---

# Reading Order

1. GUARDIAN_MASTER_HANDOFF.md
2. GUARDIAN_CURRENT_STATE.md
3. GUARDIAN_ARCHITECTURE_GUIDE.md
4. GUARDIAN_MIGRATION_HISTORY.md
5. GUARDIAN_ROADMAP.md

---

# Operating Rule

Before modifying Guardian:

- Inspect first.
- Understand current behavior.
- Review tests.
- Verify assumptions.
- Document changes.

---

# Source Of Truth

The repository is the source of truth.

Documentation provides intent and history.

When conflicts exist:

1. Investigate.
2. Resolve.
3. Update documentation.

---

# END GUARDIAN READ FIRST


==================================================
SOURCE FILE: GUARDIAN_MASTER_HANDOFF.md
==================================================
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


==================================================
SOURCE FILE: GUARDIAN_CURRENT_STATE.md
==================================================
# Guardian Current State

## Completed

M0 Foundation

M1 Storage Rules

M2 Snapshot Hygiene

M3 Recovery

M4 Governance

M5 Health

M6 Integrity

M7 DriftGuard

M8 Communication Bus

M9 Storage Entropy Remediation

---

# Working Systems

Current operational areas:

- Loader
- Health monitoring
- Audit logging
- Checkpoints
- Recovery framework
- Communication bus
- Storage rules
- Entropy remediation

---

# Known State

Guardian is functional but continues improving.

Primary focus areas:

- Increase architecture coverage.
- Improve health accuracy.
- Expand governance capabilities.
- Reduce remaining technical debt.

---

# Validation

Current tests:

14/14 passing

---

# END GUARDIAN CURRENT STATE


