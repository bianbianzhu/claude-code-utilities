### Codex performs comprehensive review of design specs.

- Review to identify issues, gaps, and inconsistencies (works for initial or subsequent reviews)

```markdown
Output file: !`f=$(ls -1 ./specs/issues/*.md 2>/dev/null | grep -v '\-feedback\.md$' | sort -rV | head -1); v=$(echo "$f" | grep -oE 'v[0-9]+' | tail -1 | tr -d 'v'); echo "./specs/issues/$(date +%Y-%m-%d)-v$((v+1)).md"`

**IMPORTANT**: Use the above file path to replace the placeholder in the prompt for "ask-codex" command.

/ask-codex "You are a senior software systems architect acting as a REVIEWER. Your task is to comprehensively review the design specifications in ./specs.

## Authoritative Standard (MUST)

Use `./references/SPEC_GENERATION_GUIDE.md` as the primary review standard.
If that file is missing, STOP and report a blocking issue: "Missing SPEC_GENERATION_GUIDE.md — cannot apply required review standard."
Every issue you raise must cite the relevant Guide Rule ID (e.g., G1, G4, G9).

## Scope

1. **Start with `./specs/README.md`** - This is the table of contents AND scope definition. Use it to:
   - Discover all spec files and understand their relationships
   - Reference the Scope section to identify what's in-scope vs deferred
   - Flag scope creep or over-engineering when specs include deferred features
2. **Review core files** (always present):
   - `./specs/README.md` - Table of contents and spec relationships
   - `./specs/end-state-ideal.md` - Target vision
   - `./specs/questions-and-answers.md` - Design decisions
3. **Review all spec files listed in README.md** - Follow the naming convention `<YYYY-MM-DD>-<topic>.md`. Do NOT assume any example filenames; only review files actually listed in README.md.
4. **If `specs/contracts/` or `specs/interfaces.md` exists** - treat these as authoritative for data shapes and cross-module contracts.

## Issue Threshold (MUST)

Only raise issues that meet this bar:

**Critical (MUST raise):**
- Implementation would be impossible without clarification
- Security vulnerabilities (injection, auth bypass, PII exposure)
- Direct contradictions causing incorrect behavior
- Violations of SPEC_GENERATION_GUIDE Guardrails G1–G11

**High (SHOULD raise):**
- Significant rework likely if discovered during implementation
- Missing error handling for common failure modes
- Undefined behavior in core flows
- Missing/incorrect centralized contracts for cross-module data

**Do NOT raise:**
- Style or naming preferences
- Nice-to-have improvements
- Edge cases outside core use cases
- Features explicitly marked deferred/future
- Hypothetical scenarios not in requirements
- Minor ambiguity a senior engineer could reasonably resolve

## Definition of Done (Implementation-Ready)

A spec set is IMPLEMENTATION READY when:
- Core flows can be implemented without guessing
- Cross-module interfaces are defined and centralized
- Guardrails G1–G11 are satisfied
- Common failure modes are documented
- Acceptance criteria are measurable

## Issue Limits (MUST)

- First review: **max 10 issues**
- Subsequent reviews: **max 5 new issues**
- Prioritize by severity and impact

## Review Criteria (Supplemental)

For each spec, analyze:

1. **Internal Consistency** - Are definitions, enums, field names, and IDs used consistently within the file?
2. **Cross-Spec Consistency** - Do interfaces, data structures, and terminology align across specs?
3. **Completeness** - Are there gaps, undefined behaviors, or missing error handling?
4. **Security** - Are there potential vulnerabilities (eval risks, injection, PII exposure)?
5. **Implementability** - Can a developer implement this without guessing? Are edge cases addressed?
6. **Ambiguity** - Are there vague terms, conflicting statements, or unclear flows?
7. **Testability** - Are acceptance criteria defined? Can the spec be verified? Are success/failure conditions measurable?
8. **Dependencies** - Are external systems, APIs, and data sources clearly identified? Any circular dependencies between specs?
9. **Error Handling & Failure Modes** - What happens when things fail? Are recovery paths defined? Are failure scenarios documented?

## Output Format

Write findings to {Output file}:

# Spec Review: Thresholded Issues

Identified by Codex analysis on [DATE].

---

## Critical Issues

### Issue [ID]: [Issue Title]

**Severity**: Critical

**Status**: Open

**Location**: `./specs/[full-filename].md` > Section: [Section Name]

**Guide Rule ID**: [G1–G11 or Checklist item]

**Problem**: [Clear description of the issue]

**Evidence**: [Quote or reference specific text from the spec]

**Impact**: [Why this matters for implementation]

**Suggested Fix**: [Concrete recommendation]

---

## High Priority Issues

### Issue [ID]: [Issue Title]

**Severity**: High

**Status**: Open

**Location**: `./specs/[full-filename].md` > Section: [Section Name]

**Guide Rule ID**: [G1–G11 or Checklist item]

**Problem**: [Clear description of the issue]

**Evidence**: [Quote or reference specific text from the spec]

**Impact**: [Why this matters for implementation]

**Suggested Fix**: [Concrete recommendation]

---

## Medium Priority Issues (only if within issue limits)

### Issue [ID]: [Issue Title]

**Severity**: Medium

**Status**: Open

**Location**: `./specs/[full-filename].md` > Section: [Section Name]

**Guide Rule ID**: [G1–G11 or Checklist item]

**Problem**: [Clear description of the issue]

**Evidence**: [Quote or reference specific text from the spec]

**Impact**: [Why this matters for implementation]

**Suggested Fix**: [Recommendation]

---

## Missing Specifications

List any modules or components mentioned but not fully specified:

1. **[Module Name]** - Referenced in `./specs/[filename].md` but not defined
2. ...

---

## Summary

| ID  | Issue   | Severity | Location                | Guide Rule | Status |
| --- | ------- | -------- | ----------------------- | ---------- | ------ |
| 1   | [Title] | Critical | `./specs/[filename].md` | G#         | Open   |
| 2   | [Title] | High     | `./specs/[filename].md` | G#         | Open   |
| ... | ...     | ...      | ...                     | ...        | ...    |

---

## Files Reviewed

Checklist of specs reviewed (generate from README.md):

- [ ] `./specs/README.md`
- [ ] `./specs/end-state-ideal.md`
- [ ] `./specs/questions-and-answers.md`
- [ ] (list all `<YYYY-MM-DD>-<topic>.md` files from README.md)

**IMPORTANT for File References**:

- Always use FULL relative paths (e.g., `./specs/2026-01-20-architecture.md`, NOT just `architecture.md`)
- Include the specific section name when referencing issues
- This enables quick navigation in future review iterations

## Completion

If no issues are found after reviewing all specs:

- Output ONLY: `<promise>COMPLETE</promise>`
- Do NOT create the full issue report structure"
```
