# Spec Review Loop - Convergence Fix

## Problem

Multiple independent reviews (new sessions = new colleagues) keep finding new issues indefinitely.
We WANT multiple reviews (double-blind, fresh eyes). We want natural convergence where issue count decreases.

## Root Cause

The current 01-find-issues prompt has:
- 9 broad review criteria (covers everything)
- No definition of what's WORTH raising
- No severity threshold for flagging

AI reviewers don't have implicit "good enough" thresholds. They'll always find SOMETHING.

## Solution: Raise the Issue Threshold

Make the reviewer prompt STRICTER about what qualifies as a reportable issue.

### Changes to `01-find-issues.md`

#### 1. Add "Issue Threshold" Section

```markdown
## Issue Threshold

Only raise issues that meet this bar:

**Critical** (MUST raise):
- Would make implementation IMPOSSIBLE without clarification
- Security vulnerabilities (injection, auth bypass, data exposure)
- Contradictions that would cause incorrect behavior

**High** (SHOULD raise):
- Would require significant rework if discovered during implementation
- Missing error handling for COMMON failure modes
- Undefined behavior in CORE flows

**Do NOT raise** (even if technically imperfect):
- Style or naming preferences
- "Nice to have" improvements
- Edge cases outside core use cases
- Features explicitly marked deferred/future
- Hypothetical scenarios not in requirements
- Minor ambiguity that a developer could reasonably resolve
```

#### 2. Simplify Review Criteria (9 → 4)

Replace the 9 criteria with 4 focused ones:

```markdown
## Review Criteria

Focus on these four questions:

1. **Implementable?** - Can a senior developer implement this without asking clarifying questions about core flows?

2. **Consistent?** - Do interfaces, data structures, and terminology align across all specs?

3. **Secure?** - Are there vulnerabilities that would cause production incidents?

4. **Complete for MVP?** - Are the CORE flows fully specified? (Ignore edge cases and future features)
```

#### 3. Add "Implementation Ready" Definition

```markdown
## Definition of Done

A spec is IMPLEMENTATION READY when:
- A senior developer can implement core flows without guessing
- All interfaces between components are defined
- No security vulnerabilities exist
- Error handling for common failures is documented

It does NOT require:
- Perfect prose or formatting
- Every edge case documented
- Future features specified
- Exhaustive error handling
```

#### 4. Update Scope Section

Strengthen the "out of scope" guidance:

```markdown
## Scope

...existing content...

### Explicitly Out of Scope for Review

Do NOT flag issues related to:
- Anything marked "deferred", "future", or "v2"
- Implementation details (this is design, not code)
- Performance optimizations (unless critical path)
- Observability/monitoring details (unless security-relevant)
- Documentation style or formatting
```

### Changes to `specs/README.md` Template

The user should ensure their README.md has:

```markdown
## Scope

### In Scope (MVP)
- [List core features]

### Explicitly Deferred
- [List anything that should NOT be reviewed]
- [Reviewers should IGNORE these even if mentioned in specs]

### Success Criteria
This design is ready for implementation when:
- [Concrete, measurable criteria]
```

---

## Why This Works

1. **High bar = fewer issues**: If only blockers get raised, mature specs have nothing to flag
2. **Double-blind preserved**: New reviewer doesn't know about previous reviews
3. **Natural convergence**: First review catches real issues, second catches fewer, third catches near-zero
4. **Still catches real problems**: Security, contradictions, and blockers always get flagged

---

## Files to Modify

| File | Changes |
|------|---------|
| `01-find-issues.md` | Add Issue Threshold, simplify criteria (9→4), add Definition of Done |
| `specs/README.md` (template/docs) | Document required Scope section format |

---

## Verification

1. Run review on mature specs → should find 0-2 issues max
2. Run review on draft specs → should find real blockers only
3. Run 3 iterations on same specs → issue count should decrease: N → fewer → 0
