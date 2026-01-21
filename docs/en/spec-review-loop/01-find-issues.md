### Codex performs comprehensive review of design specs.

- Initial review to identify issues, gaps, and inconsistencies

```markdown
Output file: !`echo "./specs/issues/$(date +%Y-%m-%d)-v1.md"`

**IMPORTANT**: Use the above file path to replace the placeholder in the prompt for "ask-codex" command.

/ask-codex "Perform a comprehensive review of the design specifications in ./specs.

## Scope

Start by reading ./specs/README.md (if exists) to understand the spec structure and relationships. Then review all dated spec files (e.g., `2026-01-20-*.md`) and supporting documents.

Key spec files to review:
- `./specs/README.md` - Table of contents and spec relationships
- `./specs/2026-*-architecture.md` - System architecture
- `./specs/2026-*-conversation.md` - Conversation flow
- `./specs/2026-*-execution-engine.md` - Execution layer
- `./specs/2026-*-action-catalog.md` - Action definitions
- `./specs/2026-*-observability.md` - Logging and monitoring
- `./specs/2026-*-testing.md` - Testing strategy
- `./specs/2026-*-shared-conventions.md` - Shared definitions
- `./specs/end-state-ideal.md` - Target vision
- `./specs/questions-and-answers.md` - Design decisions

## Review Criteria

For each spec, analyze:

1. **Internal Consistency** - Are definitions, enums, field names, and IDs used consistently within the file?
2. **Cross-Spec Consistency** - Do interfaces, data structures, and terminology align across specs?
3. **Completeness** - Are there gaps, undefined behaviors, or missing error handling?
4. **Security** - Are there potential vulnerabilities (eval risks, injection, PII exposure)?
5. **Implementability** - Can a developer implement this without guessing? Are edge cases addressed?
6. **Ambiguity** - Are there vague terms, conflicting statements, or unclear flows?

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

Checklist of specs reviewed (for tracking):

- [ ] `./specs/README.md`
- [ ] `./specs/2026-*-architecture.md`
- [ ] `./specs/2026-*-conversation.md`
- [ ] `./specs/2026-*-execution-engine.md`
- [ ] `./specs/2026-*-action-catalog.md`
- [ ] `./specs/2026-*-observability.md`
- [ ] `./specs/2026-*-testing.md`
- [ ] `./specs/2026-*-shared-conventions.md`
- [ ] `./specs/end-state-ideal.md`
- [ ] `./specs/questions-and-answers.md`

**IMPORTANT for File References**:
- Always use FULL relative paths (e.g., `./specs/2026-01-20-architecture.md`, NOT just `architecture.md`)
- Include the specific section name when referencing issues
- This enables quick navigation in future review iterations"
```