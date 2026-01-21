### Codex confirms design spec fixes done by Claude Code.

- Iterate the findings to a new version of the issue report

```markdown
/ask-codex "Verify fixes for !`ls -1 ./specs/issues/*.md 2>/dev/null | grep -v '\-feedback\.md$' | sort -rV | head -1` against design specs in ./specs.
!`ls -1 ./specs/issues/*.md 2>/dev/null | grep -v '\-feedback\.md$' | sort -rV | head -1 | sed 's/\.md$/-feedback.md/' | xargs -I{} sh -c '[ -f "{}" ] && printf "\nAlso review feedback from previous iteration: {}"'`

For each issue in the report:
1. Check if the corresponding spec has been updated
2. Confirm the fix fully addresses the identified gap
3. Flag any partial fixes, regressions, or missed issues

## Feedback Review (if feedback file is present)

When a feedback file exists, the implementer has declined some suggestions. For each declined item:
1. **Evaluate the reasoning** - Is it valid? Does it align with design goals?
2. **Decide**:
   - If reasoning is sound → Accept the decline, remove from next iteration
   - If reasoning is flawed → Re-raise the issue with counter-argument in next iteration
3. **Document** your assessment in the Feedback Review section below

Use git diff/history to compare before/after states where helpful.

Write findings to ./specs/issues/<YYYY-MM-DD>-v<N+1>.md (use today's date; N is the version from the input issues file, e.g., v2 → v3):

## Summary
| Issue | Status (Fixed/Partial/Missing/Declined) | Notes |
|-------|----------------------------------------|-------|
...

## Detailed Findings

### Issue [N]: [Title]
- **Status**:
- **Original Gap**:
- **What Changed**:
- **Assessment**:
- **Remaining Work** (if any):

## Feedback Review (if applicable)

### [Issue Title from Feedback]
- **Implementer's Reasoning**: (summary of why they declined)
- **Assessment**: Valid / Invalid
- **Response**:
  - If valid: Accepted - removed from tracking
  - If invalid: Re-raised - (explain why the original issue still stands)

(Repeat for each declined suggestion)"
```