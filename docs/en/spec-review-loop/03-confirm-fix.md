### Codex confirms design spec fixes done by Claude Code.

- Iterate the findings to a new version of the issue report

```markdown
/ask-codex "Verify fixes for @specs/issues/2026-01-20-v2.md against design specs in ./specs.

For each issue in the report:
1. Check if the corresponding spec has been updated
2. Confirm the fix fully addresses the identified gap
3. Flag any partial fixes, regressions, or missed issues

If @specs/issues/2026-01-20-v2-rejected.md exists:
- Review each rejection reasoning
- Assess if the rejection is valid (sound reasoning, aligns with design goals)
- Flag if you disagree with the rejection and why

Use git diff/history to compare before/after states where helpful.

Write findings to ./specs/issues/03-<YYYY-MM-DD>.md:

## Summary
| Issue | Status (Fixed/Partial/Missing/Rejected) | Notes |
|-------|----------------------------------------|-------|
...

## Detailed Findings

### Issue [N]: [Title]
- **Status**: 
- **Original Gap**: 
- **What Changed**: 
- **Assessment**: 
- **Remaining Work** (if any): 

## Rejection Review (if applicable)

### Issue [N]: [Title]
- **Rejection Reason Given**: 
- **Valid**: Yes/No
- **Response**: (agree with reasoning / counter-argument if disagree)

(Repeat for each)"
```