### Codex confirms design spec fixes done by Claude Code.

- Iterate the findings to a new version of the issue report

```markdown
**IMPORTANT**: Use the below files to replace the placeholders in the prompt for "ask-codex" command. Run bash commands to generate the values for the placeholders FIRST.

Issues file: !`ls -1 ./specs/issues/*.md 2>/dev/null | grep -v '\-feedback\.md$' | sort -rV | head -1`

Feedback file: !`ls -1 ./specs/issues/*.md 2>/dev/null | grep -v '\-feedback\.md$' | sort -rV | head -1 | sed 's/\.md$/-feedback.md/'`

Output file: !`f=$(ls -1 ./specs/issues/*.md 2>/dev/null | grep -v '\-feedback\.md$' | sort -rV | head -1); v=$(echo "$f" | grep -oE 'v[0-9]+' | tail -1 | tr -d 'v'); echo "./specs/issues/$(date +%Y-%m-%d)-v$((v+1)).md"`

/ask-codex "Verify fixes for {Issues file} against design specs in ./specs.

Before verifying, read `./references/SPEC_GENERATION_GUIDE.md`. If missing, STOP and report a blocking issue: "Missing SPEC_GENERATION_GUIDE.md — cannot apply required spec standard."

If {Feedback file} exists, also review it.

For each issue in the report:
1. Check if the corresponding spec has been updated
2. Confirm the fix fully addresses the identified gap
3. Flag any partial fixes, regressions, or missed issues
4. Re‑verify compliance with SPEC_GENERATION_GUIDE.md Guardrails G1–G11. If a fix introduces any new violations, raise a new issue with the relevant Guide Rule ID.

## Feedback Review (if feedback file is present)

When a feedback file exists, the implementer has declined some suggestions. For each declined item:
1. **Evaluate the reasoning** - Is it valid? Does it align with design goals?
2. **Decide**:
   - If reasoning is sound → Accept the decline, remove from next iteration
   - If reasoning is flawed → Re-raise the issue with counter-argument in next iteration
   - If the same issue was declined and re-raised in a prior iteration → Mark as **Escalate: requires human decision** (do not re-raise again)
3. **Document** your assessment in the Feedback Review section below

Use git diff/history to compare before/after states where helpful. If git history is unavailable, compare current spec content directly against the issue descriptions.

Write findings to {Output file}:

# Spec Verification Report

Verified by Codex on [DATE].

---

## Summary
| ID | Issue | Severity | Location | Guide Rule | Status (Fixed/Partial/Missing/Declined/Escalate) | Notes |
|----|-------|----------|----------|------------|--------------------------------------------------|-------|
...

## Detailed Findings

### Issue [N]: [Title]
- **Guide Rule ID**:
- **Severity**:
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
  - If previously re-raised and declined again: Escalate — requires human decision (do not re-raise)

(Repeat for each declined suggestion)

## Completion Status

If ALL issues are resolved (including accepted declines):
- Output: `<promise>ALL_RESOLVED</promise>`

If any issues remain unresolved or escalated:
- Output: `<promise>ISSUES_REMAINING</promise>`
- List remaining issue IDs (including escalated)"
``` 
