### Codex confirms design spec fixes done by Claude Code.

- Iterate the findings to a new version of the issue report

```markdown
/ask-codex "Verify fixes for @specs/issues/2026-01-20-v2.md against design specs in ./specs.

For each issue in the report:
1. Check if the corresponding spec has been updated
2. Confirm the fix fully addresses the identified gap
3. Flag any partial fixes, regressions, or missed issues

Use git diff/history to compare before/after states where helpful.

Write findings to ./specs/issues/<YYYY-MM-DD>-v3.md with this structure:

## Summary
| Issue | Status (Fixed/Partial/Missing) | Notes |
|-------|-------------------------------|-------|
...

## Detailed Findings

### Issue 1: [Title]
- **Status**: 
- **Original Gap**: 
- **What Changed**: 
- **Assessment**: 
- **Remaining Work** (if any): 

(Repeat for each issue)"
```