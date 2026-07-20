# Guardian Handoff Plan

## Objective
Keep Guardian as the active project and park Toolkit as a reference workspace while preserving useful assets.

## Direction
- Guardian is now the canonical project path.
- Toolkit remains bench/paused and should not be treated as the main working directory.

## Immediate Actions
1. Continue all new work in Guardian.
2. Keep Toolkit unchanged unless a specific file needs to be copied into Guardian for migration.
3. Use Guardian as the place for future updates, scripts, reports, and configuration.

## Migration Strategy
- Review Toolkit files that contain useful logic, scripts, or configuration.
- Copy or port only the items that are still relevant to Guardian.
- Place migrated assets into clearly named folders inside Guardian, such as:
  - scripts/
  - core/
  - config/
  - reports/
  - snapshots/

## Suggested Working Rules
- Do not create new major work in Toolkit.
- When something from Toolkit is needed, bring it into Guardian first.
- Keep a short note in Guardian when a Toolkit asset is merged or archived.

## Near-Term Next Steps
- Review the most valuable Toolkit scripts and configs.
- Copy the best ones into Guardian.
- Update Guardian documentation so it reflects the new canonical direction.
