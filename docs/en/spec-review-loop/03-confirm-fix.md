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
3. **Document** your assessment in the Feedback Review section below

Use git diff/history to compare before/after states where helpful. If git history is unavailable, compare current spec content directly against the issue descriptions.

Write findings to {Output file}:

# Spec Verification Report

Verified by Codex on [DATE].

---

## Summary
| ID | Issue | Severity | Location | Guide Rule | Status (Fixed/Partial/Missing/Declined/Declined-Accepted) | Notes |
|----|-------|----------|----------|------------|--------------------------------------------------|-------|
...

## Detailed Findings

### Issue [ID]: [Title]

**Severity**:

**Status**: [Fixed/Partial/Missing/Declined/Declined-Accepted]

**Location**: `./specs/[full-filename].md` > Section: [Section Name]

**Guide Rule ID**:

**Problem**: [If Partial/Missing/Declined, restate the remaining gap; if Fixed or Declined-Accepted, write "Resolved"]

**Evidence**: [Current evidence for the remaining gap; if Fixed or Declined-Accepted, write "Resolved"]

**Impact**: [Remaining impact; if Fixed or Declined-Accepted, write "None"]

**Suggested Fix**: [Next minimal change if any remain; if Fixed or Declined-Accepted, write "N/A"]

**What Changed**: [If Fixed, describe spec modifications; if Partial, describe changes made and what remains unchanged; if Missing, write "No changes detected"; if Declined, write "Declined by implementer"; if Declined-Accepted, write "Declined by implementer; accepted in feedback review"]

**Assessment**: [If Fixed, write "Fully addressed"; if Partial, brief judgment of remaining gap; if Missing, write "Not attempted"; if Declined or Declined-Accepted, write "See Feedback Review"]

**Remaining Work** (if any): [If Fixed or Declined-Accepted, write "None"; if Partial, describe remaining work; if Missing, briefly restate required work; if Declined, write "Re-raised: fix required or provide revised rationale"]

## Feedback Review (if applicable)

### [Issue Title from Feedback]
- **Implementer's Reasoning**: (summary of why they declined)
- **Assessment**: Valid / Invalid
- **Response**:
  - If valid: Accepted - removed from tracking
  - If invalid: Re-raised - (explain why the original issue still stands)

(Repeat for each declined suggestion)

## New Issues (Regressions)

If a fix introduces new violations of SPEC_GENERATION_GUIDE.md Guardrails G1–G11, raise them here. New issue IDs start from N+1 where N is the highest existing ID in the input report. Include new issues in the Summary table above.

### Issue [ID]: [Title]

**Severity**: [Critical/High]

**Status**: Open

**Location**: `./specs/[full-filename].md` > Section: [Section Name]

**Guide Rule ID**: [G1–G11]

**Problem**: [Clear description of the regression]

**Evidence**: [Quote or reference specific text from the spec]

**Impact**: [Why this matters for implementation]

**Suggested Fix**: [Concrete recommendation]

## Completion Status

If ALL issues have Status `Fixed` or `Declined-Accepted`:
- Output: `<promise>ALL_RESOLVED</promise>`

If any issues have Status `Partial`, `Missing`, or `Declined`:
- Output: `<promise>ISSUES_REMAINING</promise>`
- List remaining issue IDs"
``` 
