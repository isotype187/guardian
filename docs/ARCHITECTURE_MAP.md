# Nexus98 Guardian - Architecture Map (through M7)

Generated: 2026-07-19

## Current Topology

GuardianRoot = D:\Nexus98_Guardian
Reference    = D:\Nexus98 (READ ONLY)

    Human Operator
          |
       Guardian
          |
   ---------------------------------
   |          |           |        |
  Core     Config      Data     Snapshots (archive)
   |          |           |
  Env     state*.json  checkpoints/
 Contracts      logs/      rolling/
 Governance     reports/   milestones/
 Audit          tests/    emergency/
 Health         plugins/  archive/
 Checkpoint     scripts/
 Integrity
 Recovery

## Live Foundation Modules (core/, new in M0)

| Module                  | Responsibility                           | Status |
|-------------------------|------------------------------------------|--------|
| Guardian_Env.ps1        | Path contract, dir init                  | active |
| Guardian_Loader.ps1     | Module bootstrap                         | active |
| Guardian_Contracts.ps1  | Structured message types                 | active |
| Guardian_Governance.ps1 | Risk tiers + policy decisions            | active |
| Guardian_Audit.ps1      | Append-only audit log                    | active |
| Guardian_Health.ps1     | Coverage + health score                  | active |
| Guardian_Checkpoint.ps1 | Rolling/milestone/emergency/archive tiers | active |
| Guardian_Integrity.ps1  | Drift + storage entropy detection        | active |
| Guardian_Recovery.ps1     | Emergency snapshot + rollback levels      | active |
| Guardian_Events.ps1       | Event store + event bus                  | active |
| Guardian_StorageIntelligence.ps1 | Storage class + duplicate/nested drift | active |
| Guardian_Memory.ps1       | Short/long/pattern memory               | active |
| Guardian_Patterns.ps1     | Pattern recognition                     | active |
| Guardian_Observability.ps1| Health dashboard + observability         | active |
| Guardian_Explanation.ps1  | Plain-language explanation engine       | active |
| Guardian_Resource.ps1     | CPU/mem/disk sampling                   | active |
| Guardian_Agents.ps1       | Agent registry + supervision           | active |
| Guardian_Security.ps1     | Config/permission change monitoring     | active |
| Guardian_ActionPlanning.ps1 | Remediation plan builder               | active |
| Guardian_Remediation.ps1  | Controlled remediation executor         | active |
| Guardian_GovernanceIntegration.ps1 | Decision + memory integration    | active |
| Guardian_Comms.ps1        | Nexus98 bridge: outbox/inbox + modulation | active |
| Guardian_DriftGuard.ps1   | M7 architecture baseline + drift gate   | active |
| Guardian_Bridge.ps1      | M8 governed Nexus98 message bus + dispatcher | active |
| Guardian_StorageRules.ps1 | M1 hygiene rules (wired)         | active |
| Guardian_EntropyRemediation.ps1 | M9 entropy analysis + governed remediation | active |

## Legacy Stub Modules (core/, NOT production-safe)

26 files (Nexus98_*.ps1, snapshot_engine.ps1, verification_engine.ps1,
recovery_engine.ps1, run_snapshot_test.ps1). Most contain PowerShell syntax
errors and hard-code D:\Nexus98_Toolkit. Preserved but NOT wired into the
Guardian loader. Superseded by the M0 foundation; snapshot_engine.ps1 is real
work and is retained as reference.

## Data Layout (post M0)

data/checkpoints/{rolling,milestones,emergency,archive}/  <- governed tiers
config/*.json                                            <- state (legacy)
logs/guardian_audit.jsonl                                <- audit trail
snapshots/                                               <- legacy archive (3,411 files, ~2.1 GB)
  communication/                                         <- M8 governed message bus (JSONL)
  data/remediation/                                      <- M9 quarantine + rollback manifest

