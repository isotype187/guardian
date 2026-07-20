# Guardian M7 Self-Development Guard & Drift Gate Report

Generated: 2026-07-19   |   Author: Codex (Guardian Lead Architect)
Milestone: M7 (highest-priority governance layer, precedes live Nexus98 transport)
Checkpoint: CK_20260719_112211_6181 (milestones tier)

## 1. Architecture

M7 introduces `core/Guardian_DriftGuard.ps1`, wired into `core/Guardian_Loader.ps1`
and registered in the Health coverage as the Architecture Drift Detector. It enforces
the core principle that every change has (1) a reason, (2) a checkpoint, (3) a
validation process, (4) a comparison step, and (5) a rollback path. No autonomous
modification proceeds without this chain.

```
Guardian_DriftGuard.ps1
  + New-GuardianArchitectureBaseline / Save-GuardianArchitectureBaseline
        -> config/guardian_architecture_baseline.json
  + Get-GuardianDrift            (6 drift classes)
  + New-GuardianChangeRequest / Set-GuardianChangeStage / Test-GuardianChangeGovernance
  + New-GuardianSelfModificationCheckpoint / Test-GuardianSelfModification
  + Get-GuardianStorageGovernance (5 storage rules + lifecycle)
  + Invoke-GuardianDriftGuard    (orchestrator)
```

## 2. Protections Added

- **P1 Architecture Baseline**: `config/guardian_architecture_baseline.json` records
  approved directories, modules (active vs legacy-stub), data locations, config files
  (with SHA256 hashes), generated-artifact locations, top-level files, and 5 protected
  surfaces (Guardian Core, Governance Rules, Recovery, Checkpoint, Communication Layer).
- **P2 Drift Detection** — six classes enforced:
  `NEW_UNAPPROVED_DIRECTORY`, `NEW_UNAPPROVED_MODULE`, `MOVED_COMPONENT`,
  `RENAMED_COMPONENT`, `CONFIGURATION_DRIFT`, `DUPLICATE_SYSTEM`, plus
  `UNCONTROLLED_ARTIFACT` for stray top-level files.
- **P3 Change Governance**: `New-GuardianChangeRequest` models the seven-stage chain
  (CHECKPOINT_CREATED, CHANGE_DECLARED, RISK_CLASSIFIED, TEST_PLAN_CREATED,
  CHANGE_EXECUTED, VALIDATION_COMPLETED, COMPARISON_COMPLETED). `Test-GuardianChangeGovernance`
  BLOCKs until checkpoint/plan/validation/comparison are satisfied.
- **P4 Self-Modification Guard**: `Test-GuardianSelfModification` requires all six
  safeguards (emergency checkpoint, change proposal, impact analysis, automated tests,
  health comparison, rollback availability) before returning ALLOW_WITH_MONITORING;
  otherwise BLOCK. Unrecognized surfaces are BLOCKed outright.
- **P5 Storage Governance Integration**: `Get-GuardianStorageGovernance` emits five
  rules — UNCONTROLLED_SNAPSHOTS, BACKUP_MULTIPLICATION, ABANDONED_REPORT,
  DUPLICATE_ARTIFACT, NESTED_PROJECT_COPY — each annotated with a lifecycle
  (owner/category/retention/cleanup). It observes and classifies only; it never deletes.

Observation-first rule: the storage scan deliberately excludes the 2.1 GB
`snapshots/` archive from deep recursion to stay tractable and read-only.

## 3. Tests

`tests/Guardian.M7.Tests.ps1` — 17 tests, all passing. Coverage:
- Baseline creation (all sections populated) + persistence.
- Allowed change = stable (drift 0) when tree matches baseline.
- Unauthorized change detection for each drift class (directory, module, config, artifact).
- Change-governance BLOCK (incomplete chain) and ALLOW (complete chain).
- Self-modification BLOCK (missing safeguards), ALLOW (all six), and BLOCK (unknown surface).
- Emergency-checkpoint creation for self-modification.
- Storage governance: uncontrolled-snapshot detection + lifecycle completeness.
- Orchestrator returns a verdict; all M7 functions load.

Full suite (M0-M7): **102/102 passing**.

## 4. Limitations

- Baseline is a point-in-time snapshot; it must be regenerated deliberately (e.g. after
  sanctioned M-changes) so it does not treat legitimate evolution as drift.
- CONFIGURATION_DRIFT hash comparison is limited to Guardian-owned (`guardian_*`),
  baseline-tracked config; volatile `nexus98_*` reference state files are excluded to
  avoid false positives.
- Storage governance classifies but does not act; remediation (rotation, dedupe, archive)
  remains a separate, checkpoint-gated step in M8+.
- Drift detection is passive (scan + report). It does not yet auto-revert; enforcement is
  advisory pending the live loop (M8).

## 5. Future Improvements

- Wire `Invoke-GuardianDriftGuard` into a scheduled cadence (cron/loop) with alerting.
- Promote storage findings into actionable, checkpoint-gated remediation plans (M8+).
- Add baseline-regen tooling so sanctioned changes update the baseline atomically.
- After M8's live loop exists, escalate detected drift into Nexus98 advisories via the
  M6 comms bridge.

## 6. Not Implemented (by design, per M7 scope)

- Live Nexus98 transport (M8).
- Autonomous remediation (observation-first; proposals only).
- Automatic deletion (never silent-delete per operating rules).
