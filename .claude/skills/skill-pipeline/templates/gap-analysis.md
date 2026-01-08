# Gap Analysis Template (Phase 1)

Use this template to analyze gaps between baseline Claude behavior and desired skill output.

## Skill Information

**Skill Name:** [skill-name]
**Date:** [YYYY-MM-DD]
**Analyst:** [name]

---

## Baseline Summary

| Metric | Value |
|--------|-------|
| Examples Tested | [N] |
| Avg Baseline Quality | [1-5] |
| Consistent Issues | [count] |

---

## Gap Categories

### 1. Missing Knowledge Gaps

Claude lacks domain-specific information that the skill should provide.

| Gap | Example | Impact | Solution Type |
|-----|---------|--------|---------------|
| [Gap description] | [Which example showed this] | High/Med/Low | Reference doc / Instruction |

---

### 2. Format/Structure Gaps

Output format doesn't match desired structure.

| Gap | Baseline Produces | Desired Format | Solution |
|-----|-------------------|----------------|----------|
| [Gap description] | [What Claude outputs] | [What we want] | Template / Instruction |

---

### 3. Process/Workflow Gaps

Claude doesn't follow the desired workflow or steps.

| Gap | Baseline Behavior | Desired Workflow | Solution |
|-----|-------------------|------------------|----------|
| [Gap description] | [What Claude does] | [What we want] | Step-by-step instruction |

---

### 4. Consistency Gaps

Output varies when it should be consistent.

| Gap | Variation Observed | Desired Consistency | Solution |
|-----|-------------------|---------------------|----------|
| [Gap description] | [How it varies] | [What should be stable] | Constraint / Example |

---

### 5. Tool Usage Gaps

Claude doesn't use tools optimally for this task.

| Gap | Current Tool Use | Optimal Tool Use | Solution |
|-----|------------------|------------------|----------|
| [Gap description] | [What Claude does] | [What's better] | Tool guidance |

---

## Priority Matrix

Plot gaps by impact vs effort to address:

```
High Impact │ QUICK WINS    │ MAJOR PROJECTS
            │ [gaps here]   │ [gaps here]
            ├───────────────┼───────────────
            │ FILL INS      │ HARD PROBLEMS
Low Impact  │ [gaps here]   │ [gaps here]
            └───────────────┴───────────────
              Low Effort      High Effort
```

---

## Skill Complexity Assessment

Based on gap analysis:

- [ ] **Simple** - Few gaps, mostly format/structure
- [ ] **Medium** - Multiple gap types, requires reference docs
- [ ] **Complex** - Many gaps, requires extensive knowledge injection

---

## Recommended Approach

### Must Address (for MVP)
1. [Gap to address]
2. [Gap to address]

### Should Address (for quality)
1. [Gap to address]
2. [Gap to address]

### Could Address (stretch)
1. [Gap to address]

---

## Skill Structure Recommendation

Based on analysis, recommend skill structure:

```
skill-name/
├── SKILL.md           [Est. lines: ___]
├── references/
│   ├── [ref1.md]      [Est. lines: ___]
│   └── [ref2.md]      [Est. lines: ___]
└── scripts/           [If needed: Y/N]
```

---

## Next Steps

- [ ] Review priority matrix with stakeholders
- [ ] Finalize MVP scope
- [ ] Create test cases (Phase 2)
- [ ] Begin skill authoring (Phase 3)
