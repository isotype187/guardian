# Nexus98 Guardian - Architecture

Last updated: 2026-07-19 (Milestone M1)

## Principle

Guardian is the operational supervisory intelligence layer for Nexus98.
Nexus98 (D:\Nexus98, read-only reference) is the creation engine. Guardian
is the stability and governance layer. They are separate but cooperative and
must never become the same application.

## Repository Topology

    Human Operator
          |
       Guardian
          |
   ---------------------------------
   |         |          |          |
  Core    Config     Data       Snapshots (archive)
   |         |          |
  Env    state*.json  checkpoints/
 Loader     logs/      rolling/
 Contracts   reports/  milestones/
 Governance   tests/   emergency/
 Audit        plugins/ archive/
 Health       scripts/
 Checkpoint   docs/
 Integrity    storage/
 Recovery     communication/
              governance/
              monitoring/
              memory/
              recovery/
              archive/legacy_stubs/

## Module Map

### Foundation (core/, active since M0)
| Module                   | Responsibility                          |
|--------------------------|-----------------------------------------|
| Guardian_Env.ps1         | Path contract + directory init          |
| Guardian_Loader.ps1      | Bootstraps all foundation modules       |
| Guardian_Contracts.ps1   | Structured message types (bridge)       |
| Guardian_Governance.ps1  | Risk tiers + policy decisions           |
| Guardian_Audit.ps1       | Append-only audit trail                |
| Guardian_Health.ps1      | Coverage + health score                |
| Guardian_Checkpoint.ps1  | Rolling checkpoint system (4 tiers)     |
| Guardian_Integrity.ps1   | Drift + storage entropy detection       |
| Guardian_Recovery.ps1    | Emergency snapshot + rollback levels    |

### Domain directories (created M1)
- governance/  - policy decisions, risk classification, approval workflow
- recovery/     - rollback levels, emergency restore, recovery memory
- monitoring/   - health, integrity, resource telemetry
- communication/ - structured message contracts (bridge)
- memory/       - short/long/pattern operational memory
- storage/      - archive, retention, storage-entropy intelligence
- archive/legacy_stubs/ - quarantined broken legacy scripts (OBSOLETE)

### Data layout
- data/checkpoints/{rolling,milestones,emergency,archive}/ - governed tiers
- data/latest_recovery.json - legacy recovery marker (ignored by git)
- logs/guardian_audit.jsonl - audit trail
- snapshots/ - legacy recovery archive (3,411 files, ~2.1 GB; ignored by git)

### Version Control Note
The project-root .git directory is write-protected in this sandbox, so the
canonical git metadata is relocated to vcs/.git with core.worktree pointing to
the project root. Use scripts/guardian-git.ps1 (or set GIT_DIR=vcs/.git) for
all git operations. This is documented and intentional, not a defect.

## Milestone Status (M0 + M1)
- M0 Foundation & Governance Contract: DONE
- M1 Foundation Establishment: DONE
- M2-M5: see CAPABILITY_REPORT.md
