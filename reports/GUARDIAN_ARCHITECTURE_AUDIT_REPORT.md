# GUARDIAN ARCHITECTURE AUDIT REPORT

Date: 2026-07-20
Auditor: Codex (autonomous architecture compliance audit)
Scope: Nexus98_Guardian after extended autonomous development (M0-M10)
Method: Inspection-only first; repairs restricted to clear violations.
Repo: D:\Nexus98\guardian_dev (standalone git repo, branch master).
Canonical entry: core\Guardian_Loader.ps1 -> Import-Guardian.

======================================================================
1. CURRENT ARCHITECTURE SUMMARY
======================================================================

Guardian is a PowerShell supervisory layer for Nexus98. It is loaded by
dot-sourcing core\Guardian_Loader.ps1, which imports 23 Guardian_* modules in
a fixed order. State lives under data\ (checkpoints, ops, events, remediation),
config\, logs\, reports\, communication\ (governed message bus), and snapshots\.

Active production modules (core\, wired into the loader):
- Env, Loader, Contracts        : path contract + bootstrap + message types
- Governance, Audit, Health     : authority, append-only audit, health score
- Checkpoint, Integrity, Recovery: tiers, drift, 6-level rollback
- Events, StorageIntelligence, Memory, Patterns : event bus, entropy, memory
- Observability, Explanation    : dashboards + plain-language reasons
- Resource, Agents, Security    : sampling, agent registry, config monitoring
- ActionPlanning, Remediation   : governed remediation plans + executor
- GovernanceIntegration, Comms  : decision/memory link, Nexus98 comms (v1)
- DriftGuard, Bridge            : architecture baseline drift gate, M8 bus
- StorageRules, EntropyRemediation : M1 hygiene + M9 entropy remediation
- Operations                    : M10 scheduler/heartbeat/risk/ops-state (validated)

Subsystems present and functional:
- Scheduler engine (5 default jobs, configurable intervals, enable/disable,
  failure recording, restart persistence, no-stale-overwrite cycle).
- Checkpoint authority (rolling/milestones/emergency/archive tiers).
- Rollback authority (Invoke-GuardianRollback, levels 1-6).
- Audit authority (append-only guardian_audit.jsonl).
- Health authority (Get-GuardianHealthScore).
- Communication with Nexus98 (Bridge: outbox/inbox, validation, dispatcher,
  acknowledgement, governance decisions). These are real and Pester-verified.
- Event logging (now persisting after M10 fix).

======================================================================
2. NEXUS98 COMPATIBILITY SCORE
======================================================================

Scored against the audit's compatibility checklist (0-10 each, weighted):

Communication:
- reliable message exchange ........ 9  (Bridge outbox/inbox + dispatcher)
- event reporting .................. 9  (Events module, now persisted)
- health reporting ................. 9  (Send-GuardianHealthReportToNexus98Bridge)
- task requests .................... 8  (Receive-Nexus98AnalysisRequestBridge)
- acknowledgement handling ......... 8  (Add-GuardianAck / Get-GuardianAcks)
- failure reporting ................ 8  (JOB_FAILURE event + warning to bridge)

Governance:
- Nexus requests changes ........... 9  (bridge inbound + governance decisions)
- Guardian validates changes ....... 9  (Test-GuardianRuntimeConfig, DriftGuard)
- Guardian checkpoints before risk . 9  (New-GuardianSelfModificationCheckpoint)
- Guardian approves preservation ... 8  (governance gate on remediation)

Recovery:
- Nexus failures detected .......... 7  (risk analysis + drift, not auto-watchdog)
- valid states restored ............ 8  (rollback levels)
- rollback paths exist ............. 9  (6-level rollback)
- recovery history exists .......... 8  (audit + checkpoint manifests)

Weighted total: ~8.5 / 10. Guardian is correctly designed as Nexus98's
supervisory authority and is compatible.

======================================================================
3. DESIGN VIOLATIONS (clear)
======================================================================

V1. Stale root entry point (Nexus98.ps1).
    The documented canonical entry is core\Guardian_Loader.ps1. Nexus98.ps1
    instead dot-sources the abandoned engines (snapshot_engine.ps1,
    verification_engine.ps1, recovery_engine.ps1) and calls New-Nexus98RecoveryPoint.
    This bypasses the real Guardian systems and is a broken integration.
    Severity: HIGH (wrong authority bootstrap).

V2. Abandoned duplicate systems in core\ (NOT wired, hard-code D:\Nexus98_Toolkit).
    13 Nexus98_*.ps1 files + recovery_engine.ps1 + snapshot_engine.ps1 +
    verification_engine.ps1 + run_snapshot_test.ps1 duplicate Guardian's mature
    Checkpoint/Recovery/Events/Memory/Snapshot subsystems, contain syntax issues,
    and write to a non-existent path (D:\Nexus98_Toolkit). docs\ARCHITECTURE_MAP.md
    already labels them "legacy stubs - NOT production-safe - superseded".
    Severity: MEDIUM (dormant, but a maintenance/entropy hazard and confusion risk).

V3. Dormant legacy config (config\nexus98_*.json, 32 files).
    None are referenced by any Guardian_* module (verified by grep). They are
    stale state from the pre-M0 orchestrator era.
    Severity: LOW (storage entropy / clutter).

V4. Stray nested git repo at vcs\.git.
    An empty .git exists under vcs\. guardian-git.ps1 points GIT_DIR there, but
    no real git history lives there (and the parent D:\Nexus98\guardian_dev .git
    is the actual repo). The empty vcs\.git is a stray artifact.
    Severity: LOW (storage hygiene).

V5. Dual root ambiguity.
    Guardian_Env.ps1 resolves GuardianRoot from PSScriptRoot\.. (D:\Nexus98\guardian_dev)
    but falls back to D:\Nexus98_Guardian if not found. Both paths currently exist.
    Not a hard failure, but two candidate roots is a config smell that can cause
    split-brain state if run from the wrong directory.
    Severity: LOW.

======================================================================
4. MISSING CAPABILITIES
======================================================================

- Autonomous watchdog: no always-on process that detects a Nexus98 failure and
  auto-restores. Recovery is on-demand (Invoke-GuardianRollback / checkpoint),
  which is acceptable but the audit asks to "verify failures can be detected" -
  currently detection is via risk analysis, not an automated watcher.
- Configurable paths: most paths derive from GuardianEnv (good), but the legacy
  engines hard-code D:\Nexus98_Toolkit (covered by V2).
- Test coverage gaps: Nexus98 integration points (bridge in/out) ARE covered by
  M6/M8. Scheduler IS covered (M10). Checkpoints/rollback storage governance/
  drift/recovery/runtime health are covered by M2-M9. No major missing area
  beyond an end-to-end watchdog test.

======================================================================
5. RISK RANKING
======================================================================

R1 (HIGH)  V1 stale entry point bootstraps wrong engines.
R2 (MED)   V2 abandoned duplicate systems (entropy + confusion).
R3 (LOW)   V3 dormant legacy config clutter.
R4 (LOW)   V4 stray vcs\.git.
R5 (LOW)   V5 dual-root ambiguity.

======================================================================
6. RECOMMENDED FIXES
======================================================================

F1. Replace Nexus98.ps1 content with a thin bootstrap that calls the canonical
    Guardian loader (Import-Guardian) so the real systems are used. Do NOT delete
    capability; redirect the entry point.
F2. Move the abandoned engines (Nexus98_*.ps1, recovery_engine.ps1,
    snapshot_engine.ps1, verification_engine.ps1, run_snapshot_test.ps1) into
    archive\legacy_stubs\ (where siblings already live) so core\ contains only
    production modules. core\ is the loader scope; removing them from core\
    eliminates the duplicate-system hazard with zero behavior change.
F3. Leave config\nexus98_*.json in place but document them as legacy (low risk;
    bulk deletion is out of scope per "preserve backward compatibility").
F4. Remove the empty vcs\.git stray artifact (or relocate guardian-git wrapper).
F5. Resolve dual-root: keep PSScriptRoot\.. resolution; drop or clearly de-risk
    the D:\Nexus98_Guardian fallback to avoid split-brain.

======================================================================
7. PRIORITY ORDER
======================================================================

1. F1 (HIGH) - fix entry point.
2. F2 (MED)  - quarantine abandoned engines out of core\.
3. F4 (LOW)  - remove stray vcs\.git.
4. F5 (LOW)  - de-risk dual root.
5. F3 (LOW)  - document dormant config (no deletion).

======================================================================
8. REQUIRED FUTURE MILESTONES
======================================================================

M11 - Guardian Runtime Watchdog: always-on detection of Nexus98 failures with
     automated checkpoint-restore path (closes the "detect failure" gap).
M12 - Unified Config Hygiene: retire legacy nexus98_*.json, single source of
     truth, schema-validated runtime config only.
M13 - Repository Preservation Authority (separate amendment, out of scope now):
     promote guardian-git.ps1 + the controlled preservation mechanism so Guardian
     becomes the authority over Nexus98 preservation per the design note.
M14 - Cross-Milestone Integration Test: one Pester run covering scheduler ->
     bridge -> checkpoint -> rollback -> recovery as a single narrative.

======================================================================
REPAIR SCOPE (this session)
======================================================================

Per audit rules: repair ONLY clear violations (V1, V2, V4, V5), do not redesign
working systems, preserve backward compatibility. F3 (document, no delete) is
applied. Tests re-run after changes.
