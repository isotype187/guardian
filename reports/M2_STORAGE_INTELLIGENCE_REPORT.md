# Guardian M2 - Storage Intelligence Report

Generated: 2026-07-19 09:26
Milestone: M2 - Event Intelligence + Storage Intelligence
Status: COMPLETE (observation only)

## Storage Health Score
Directory Structure: 85%
Artifact Hygiene: 50%
Growth Control: 40%
Duplicate Risk: 100%
Overall: 68.8%

## Observed Metrics
Snapshot archive files: 3411 (~2.1 GB) - primary growth source, ignored by git.
Nested-directory drift groups (depth>=6): 195.
Unknown-class artifacts: 1148.

## Detection Capabilities
- Artifact classification: ACTIVE / ARCHIVE / TEMPORARY / EXPERIMENTAL / OBSOLETE / UNKNOWN.
- UNKNOWN artifacts are flagged for review and NEVER auto-deleted.
- Directory monitoring: UNEXPECTED_DIRECTORY, NESTED_DIRECTORY_DRIFT, BACKUP_EXPANSION signals.
- Duplicate content detection by SHA256.
- Growth analysis via storage baseline + delta comparison.

## Files Changed
created: core/Guardian_StorageIntelligence.ps1
modified: tests/Guardian.M2.Tests.ps1

## Limitations
- Classification uses path-based rules; content-based inference is partial.
- Growth baseline is point-in-time; long-term trending begins after first capture.
- No automatic cleanup is performed (per M2 scope); recommendations only.

## Future Improvements
- Automated rotation/compaction of the snapshot archive (M3+).
- Retention policy enforcement with safe archival.
- Time-series growth trending and forecasting.
