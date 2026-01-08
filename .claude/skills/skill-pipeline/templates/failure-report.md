# Failure Analysis Report Template (Phase 4)

Use this template to document and analyze evaluation failures during the validation loop.

## Report Information

**Skill Name:** [skill-name]
**Evaluation Date:** [YYYY-MM-DD]
**Model Tested:** [haiku/sonnet/opus]
**Iteration:** [N]

---

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | [N] |
| Passed | [N] |
| Failed | [N] |
| Success Rate | [N%] |
| Previous Success Rate | [N%] |
| Change | [+/-N%] |

---

## Failed Tests

### Test: [test-id-001]

**Query:**
```
[The test query]
```

**Expected Behavior:**
[What should have happened]

**Actual Output:**
```
[Truncated actual output]
```

**Failed Criteria:**
- [ ] [Criterion 1 that failed]
- [ ] [Criterion 2 that failed]

**Root Cause Analysis:**

| Factor | Assessment |
|--------|------------|
| Instruction clarity | Clear / Ambiguous / Missing |
| Reference coverage | Sufficient / Partial / Missing |
| Example quality | Good / Needs improvement |
| Edge case handling | Covered / Not covered |

**Proposed Fix:**
- [ ] [Specific change to make]
- [ ] [Another change]

---

### Test: [test-id-002]

**Query:**
```
[The test query]
```

**Expected Behavior:**
[What should have happened]

**Actual Output:**
```
[Truncated actual output]
```

**Failed Criteria:**
- [ ] [Criterion that failed]

**Root Cause Analysis:**

| Factor | Assessment |
|--------|------------|
| Instruction clarity | |
| Reference coverage | |
| Example quality | |
| Edge case handling | |

**Proposed Fix:**
- [ ] [Specific change to make]

---

## Failure Pattern Analysis

### Common Patterns

| Pattern | Occurrences | Affected Tests | Root Cause |
|---------|-------------|----------------|------------|
| [Pattern 1] | [N] | [test-ids] | [cause] |
| [Pattern 2] | [N] | [test-ids] | [cause] |

### Category Breakdown

| Category | Failures | % of Total |
|----------|----------|------------|
| Format issues | | |
| Missing content | | |
| Wrong approach | | |
| Tool misuse | | |
| Other | | |

---

## Regression Analysis

### New Failures (not in previous iteration)
1. [test-id]: [brief description]

### Fixed (passed this iteration)
1. [test-id]: [what was fixed]

### Persistent Failures (multiple iterations)
1. [test-id]: [iterations failing], [analysis]

---

## Action Items

### High Priority (blocking)
- [ ] [Action 1]
- [ ] [Action 2]

### Medium Priority (quality)
- [ ] [Action 1]
- [ ] [Action 2]

### Low Priority (nice to have)
- [ ] [Action 1]

---

## Changes Made This Iteration

### SKILL.md Changes
```diff
- [old line]
+ [new line]
```

### Reference Changes
- [file]: [description of change]

### Test Case Changes
- [test-id]: [description of change]

---

## Next Steps

1. [ ] Implement high-priority fixes
2. [ ] Re-run evaluation
3. [ ] Update this report with results
4. [ ] If success rate >= target, proceed to review (Phase 5)

---

## Notes

[Any additional observations or context]
