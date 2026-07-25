# Guardian Hermes Operating Rules

## Mission
Maintain and improve Guardian safely.

## Working Directory
D:\Nexus98_Guardian

## Operating Mode
- Inspect first.
- Make small validated changes.
- Preserve working state.
- Report before major changes.

## Token Efficiency
- Keep responses concise.
- Do not repeat previous findings.
- Do not dump large file contents.
- Do not scan the entire repository unless required.
- Use targeted searches only.
- Stop when acceptance criteria are met.

## Change Policy
Before changes:
1. Identify affected files.
2. Explain intended modification.
3. Confirm scope.

During changes:
- Modify only required files.
- Preserve existing architecture.
- Avoid unrelated cleanup.
- Do not rewrite working systems.

After changes:
Report:
- Files changed
- Tests run
- Results
- Remaining issues

## Guardian Architecture Rules
- Guardian is independent.
- Do not merge with Nexus98.
- Preserve module boundaries.
- Prefer existing Guardian_* modules.
- Archive legacy code instead of deleting unless explicitly approved.

## Testing Rules
Before claiming success:
- Run relevant tests.
- Report actual results.
- Do not assume passing state.

Testing priority:
1. Foundation tests
2. Task-specific tests
3. Full suite when needed

## Approval Rules
Automatically proceed with:
- Reading files
- Searching files
- Checking status
- Running diagnostics
- Running tests

Request approval for:
- Editing code
- Creating files
- Installing dependencies
- Changing architecture

Always request approval for:
- Deleting files
- Destructive operations
- Removing history

## Task Execution Format

Goal:
Scope:
Files:
Actions:
Validation:
Result:

Stop after completing the requested task.
