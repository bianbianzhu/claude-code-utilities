### Codex performs comprehensive review of design specs.

- Review to identify issues, gaps, and inconsistencies (works for initial or subsequent reviews)

```markdown
Output file: !`f=$(ls -1 ./specs/issues/*.md 2>/dev/null | grep -v '\-feedback\.md$' | sort -rV | head -1); v=$(echo "$f" | grep -oE 'v[0-9]+' | tail -1 | tr -d 'v'); echo "./specs/issues/$(date +%Y-%m-%d)-v$((v+1)).md"`

**IMPORTANT**: Use the above file path to replace the placeholder in the prompt for "ask-codex" command.

/ask-codex "You are a senior software systems architect acting as a REVIEWER. Your task is to comprehensively review the design specifications in ./specs.

## Scope

1. **Start with `./specs/README.md`** - This is the table of contents AND scope definition. Use it to:
   - Discover all spec files and understand their relationships
   - Reference the Scope section to identify what's in-scope vs deferred
   - Flag scope creep or over-engineering when specs include deferred features
2. **Review core files** (always present):
   - `./specs/README.md` - Table of contents and spec relationships
   - `./specs/end-state-ideal.md` - Target vision
   - `./specs/questions-and-answers.md` - Design decisions
3. **Review all spec files listed in README.md** - These follow the naming convention `<YYYY-MM-DD>-<topic>.md` and vary by project. Examples:
   - `2026-01-20-architecture.md`
   - `2026-01-20-conversation.md`
   - `2026-01-20-execution-engine.md`
   - `2026-01-20-observability.md`

## Review Criteria

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

# Spec Review: Critical Issues & Gaps

Identified by Codex analysis on [DATE].

---

## Critical Issues

### 1. [Issue Title]

**Location**: `./specs/[full-filename].md` > Section: [Section Name]

**Problem**: [Clear description of the issue]

**Evidence**: [Quote or reference specific text from the spec]

**Impact**: [Why this matters for implementation]

**Suggested Fix**: [Concrete recommendation]

---

(Repeat for each critical issue)

---

## Medium Priority Issues

### [N]. [Issue Title]

**Location**: `./specs/[full-filename].md` > Section: [Section Name]

**Problem**: [Description]

**Suggested Fix**: [Recommendation]

---

## Low Priority / Recommendations

- [Brief issue] → `./specs/[filename].md`
- [Brief issue] → `./specs/[filename].md`

---

## Missing Specifications

List any modules or components mentioned but not fully specified:

1. **[Module Name]** - Referenced in `./specs/[filename].md` but not defined
2. ...

---

## Summary

| # | Issue | Severity | Location | Status |
|---|-------|----------|----------|--------|
| 1 | [Title] | Critical | `./specs/[filename].md` | Open |
| 2 | [Title] | Medium | `./specs/[filename].md` | Open |
| ... | ... | ... | ... | ... |

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
- This enables quick navigation in future review iterations"
```