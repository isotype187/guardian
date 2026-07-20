# Nexus98 Guardian

The operational supervisory intelligence layer for the Nexus98 ecosystem.
Guardian protects Nexus98 from failure, unsafe action, corrupted state,
uncontrolled growth, architectural drift, and storage entropy.

Guardian answers: *Should this happen? Is it safe? Is it healthy?
Can it recover? Is the system becoming unstable?*

Nexus98 (D:\Nexus98, read-only reference) is the intelligence and creation
engine. Guardian is the stability and governance layer. They are separate
but cooperative systems and must never become the same application.

## Status

- Milestone: **M9 - Storage Entropy Remediation** (complete; M0-M8 also committed)
- Guardian Health Score: 40.0% (architecture 40% | storage hygiene 40% | runtime 98%)
- Tests: 14/14 passing (`tests/Guardian.Foundation.Tests.ps1`)

## Structure

core/        Foundation modules (Guardian_*.ps1) + legacy stubs (not wired in)
config/      State manifests (legacy)
data/        checkpoints/{rolling,milestones,emergency,archive}, logs
logs/        guardian_audit.jsonl
reports/     Generated reports
tests/       Pester test suite
communication/ Local JSONL message bus (M8)
docs/        ARCHITECTURE_MAP.md, CAPABILITY_REPORT.md
snapshots/   Legacy recovery archive (entropy source, addressed in M1/M2)

## Foundation Modules (M0)

| Module                  | Responsibility                          |
|-------------------------|-----------------------------------------|
| Guardian_Env.ps1        | Path contract + directory initialization|
| Guardian_Loader.ps1     | Bootstraps all foundation modules       |
| Guardian_Contracts.ps1  | Structured message types (bridge)       |
| Guardian_Governance.ps1 | Risk tiers + policy decisions           |
| Guardian_Audit.ps1      | Append-only audit trail                 |
| Guardian_Health.ps1     | Coverage + health score                 |
| Guardian_Checkpoint.ps1 | Rolling checkpoint system (4 tiers)     |
| Guardian_Integrity.ps1  | Drift + storage entropy detection       |
| Guardian_Recovery.ps1   | Emergency snapshot + rollback levels     |
| Guardian_Comms.ps1     | Nexus98 bridge: outbox/inbox + modulation |
| Guardian_DriftGuard.ps1 | M7 architecture baseline + drift gate |
| Guardian_Bridge.ps1     | M8 governed Nexus98 message bus + dispatcher |
| Guardian_StorageRules.ps1 | M1 hygiene rules (wired, reused by M9) |
| Guardian_EntropyRemediation.ps1 | M9 storage entropy analysis + governed remediation |

## Quick Start

```powershell
. ".\core\Guardian_Loader.ps1"          # loads all foundation modules
$health = Get-GuardianHealthScore()     # current health score
New-GuardianCheckpoint -Tier rolling    # create a recovery point
```

## Development Rules

1. Audit before change. 2. Preserve working systems. 3. No duplicate systems.
4. Every persistent artifact has an owner, purpose, lifecycle. 5. No recovery
capability is ever removed. 6. Nothing important happens invisibly (audit it).

See `docs/CAPABILITY_REPORT.md` for the full milestone roadmap (M0-M5).



