# Guardian M5 - Controlled Remediation, Action Planning & Governance Integration

Generated: 2026-07-19 10:09
Milestone: M5 - Controlled Remediation + Action Planning + Governance Integration
Status: COMPLETE (policy-gated, checkpoint-backed, reversible; no destructive auto-action).

## Architecture Changes
- core/Guardian_ActionPlanning.ps1: structured plans (objective/risk/affected/rollback/acceptance), validation, issue->plan mapping.
- core/Guardian_Remediation.ps1: controlled execution - low/medium reversible auto-run under checkpoint; high/critical/destructive deferred to human review.
- core/Guardian_GovernanceIntegration.ps1: unified decision surface (policy + checkpoint + audit + memory + explanation + Nexus98 contract).
- Wired into core/Guardian_Loader.ps1.

## Files Created
core/Guardian_ActionPlanning.ps1, core/Guardian_Remediation.ps1, core/Guardian_GovernanceIntegration.ps1, tests/Guardian.M5.Tests.ps1.

## Capabilities Added
- Action plans with validation (high-risk rejected without rollback).
- Controlled remediation: auto-executes only safe reversible actions under a rolling checkpoint; defers destructive and high/critical to REQUIRE_REVIEW/REQUIRE_CHECKPOINT.
- Governance decision flow: returns decision + explanation + memory_id + Nexus98 contract.

## Live Snapshot
Governance decisions recorded=3. Remediation options from current state=1.

## Key Safety Properties
- Destructive intent (delete/remove/purge) is ALWAYS deferred to human review.
- No action executes without an available checkpoint (recovery capability preserved).
- Every remediation execution is audited with its checkpoint id.

## Limitations
- Remediation execution is conservative (rotation + observation); broader safe automations are later milestones.
- Human review is a state, not yet a live notification channel (M6 adds communication).

## Future Integration Points
- M6: surface DEFERRED decisions to Nexus98 via the communication layer.
- Promote approved remediation outcomes into PATTERN memory.
