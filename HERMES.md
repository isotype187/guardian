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

---

# Hermes Agent Operating Policy

## Token Preservation
Always optimize for efficient token usage.

Rules:
- Do not repeat information already established.
- Do not dump full files unless explicitly required.
- Prefer targeted searches over broad repository scans.
- Summarize command output instead of copying unnecessary logs.
- Batch related inspections together.
- Stop investigating when acceptance criteria are satisfied.

## Iteration Preservation
Protect available reasoning/tool iterations.

Rules:
- Before every command, determine whether it is necessary.
- Avoid exploratory commands without a clear purpose.
- Do not rerun validated tests unless changes could affect them.
- Do not continue after the objective is complete.
- If blocked, report the blocker instead of consuming iterations guessing.

## Decision Making Authority
Within the approved task scope:

- Independently choose inspection methods.
- Choose the smallest safe implementation path.
- Prioritize correctness and maintainability.
- Use engineering judgment instead of requesting unnecessary confirmation.

Approval is required before:
- Deleting files.
- Expanding task scope.
- Changing architecture.
- Modifying unrelated systems.
- Removing historical data.

## Execution Style
Preferred workflow:

1. Inspect.
2. Plan minimal change.
3. Modify only required files.
4. Validate.
5. Report.

Avoid:
- Large rewrites.
- Unrequested refactors.
- Duplicate verification.
- Scope creep.

## Reporting Format

Always provide concise reports:

STATUS:
CHANGES:
VALIDATION:
RISKS:
NEXT STEP:

---


---

# Persistent Memory Policy

## Knowledge Management

Use persistent memory responsibly.

Memory priorities:
1. Project architecture decisions.
2. Completed milestones.
3. Important constraints.
4. User-approved preferences.
5. Reusable procedures.

Do not store:
- Temporary debugging noise.
- Failed experiments unless historically important.
- Secrets or API keys.
- Unverified assumptions.

## Obsidian Knowledge Integration

Knowledge vault:

D:\Nexus98_Guardian\Knowledge

Use categories:

Architecture/
- system design
- module relationships
- technical decisions

Milestones/
- completed work
- validation results
- checkpoints

Decisions/
- approved design choices
- tradeoffs

Sessions/
- significant session summaries

Research/
- external references

## Memory Updates

After major milestones:
- Create concise summaries.
- Record validation results.
- Record changed files.
- Record remaining risks.

Avoid duplicate entries.

---


---

# Guardian Agent Operating Policy

## Token Preservation

Always optimize for efficient token usage.

Rules:
- Avoid unnecessary explanations.
- Do not repeat previous findings.
- Do not dump complete files unless required.
- Prefer targeted searches.
- Batch related inspections.
- Summarize command results.

## Iteration Preservation

Protect available agent iterations.

Rules:
- Evaluate necessity before every command.
- Avoid exploratory commands without purpose.
- Do not rerun validated tests without reason.
- Stop once acceptance criteria are met.
- Report blockers instead of consuming iterations guessing.

## Engineering Decision Rules

Within approved scope:

- Choose the smallest safe solution.
- Inspect before modifying.
- Preserve existing architecture.
- Prefer reversible changes.
- Validate after modifications.

Approval required before:

- Deleting files.
- Changing architecture.
- Expanding scope.
- Removing historical records.

## Session Continuity

Before ending a significant session:

Create checkpoint:

Location:
D:\Nexus98_Guardian\Knowledge\Sessions

Include:

- Objective
- Completed work
- Files changed
- Tests run
- Current state
- Remaining tasks
- Resume instructions

New sessions must read the newest checkpoint before continuing.

## Reporting Format

STATUS:
CHANGES:
VALIDATION:
RISKS:
NEXT STEP:

---

