# Model-Specific Criteria Template (Phase 2)

Use this template to define model-specific requirements and adjust skill for different Claude models.

## Skill Information

**Skill Name:** [skill-name]
**Primary Target Model:** [haiku/sonnet/opus]

---

## Model Compatibility Matrix

| Feature | Haiku | Sonnet | Opus | Notes |
|---------|-------|--------|------|-------|
| Core functionality | | | | |
| Complex reasoning | | | | |
| Long-form output | | | | |
| Code generation | | | | |
| Format compliance | | | | |

Legend: ✅ Full support | ⚠️ Partial | ❌ Not recommended

---

## Haiku-Specific Criteria

### Strengths to Leverage
- Fast response time
- Cost-effective for simple tasks
- Good for structured output

### Limitations to Account For
- May struggle with complex multi-step reasoning
- Shorter context window
- Less nuanced responses

### Skill Adjustments for Haiku
1. [Adjustment 1: e.g., Simplify decision trees]
2. [Adjustment 2: e.g., Provide more explicit templates]
3. [Adjustment 3: e.g., Reduce reference doc size]

### Haiku-Specific Test Cases
- [ ] Simple query produces correct format
- [ ] Handles most common use case
- [ ] Stays within token budget

---

## Sonnet-Specific Criteria

### Strengths to Leverage
- Balanced performance/cost
- Good reasoning capability
- Reliable format following

### Limitations to Account For
- May over-elaborate sometimes
- Medium context window

### Skill Adjustments for Sonnet
1. [Adjustment 1]
2. [Adjustment 2]

### Sonnet-Specific Test Cases
- [ ] Handles moderate complexity
- [ ] Produces consistent output format
- [ ] Appropriate level of detail

---

## Opus-Specific Criteria

### Strengths to Leverage
- Superior reasoning
- Excellent at complex tasks
- Best at nuanced judgment

### Limitations to Account For
- Higher cost
- May over-think simple tasks
- Slower response

### Skill Adjustments for Opus
1. [Adjustment 1: e.g., Can handle more complex instructions]
2. [Adjustment 2: e.g., Trust more with edge cases]

### Opus-Specific Test Cases
- [ ] Handles complex edge cases
- [ ] Makes good judgment calls
- [ ] Produces high-quality output

---

## Token Budget by Model

| Model | SKILL.md Max | References Max | Total Max |
|-------|--------------|----------------|-----------|
| Haiku | 300 lines | 200 lines | 500 lines |
| Sonnet | 500 lines | 300 lines | 800 lines |
| Opus | 500 lines | 500 lines | 1000 lines |

---

## Model Selection Guidance

### Use Haiku When:
- [ ] Task is straightforward
- [ ] Format is highly structured
- [ ] Speed/cost is priority
- [ ] High volume of requests

### Use Sonnet When:
- [ ] Task requires moderate reasoning
- [ ] Balance of quality and cost needed
- [ ] Standard complexity tasks

### Use Opus When:
- [ ] Task requires complex judgment
- [ ] High-stakes output
- [ ] Edge cases are common
- [ ] Quality is paramount

---

## Cross-Model Test Matrix

| Test ID | Haiku | Sonnet | Opus | Notes |
|---------|-------|--------|------|-------|
| [test-001] | | | | |
| [test-002] | | | | |
| [test-003] | | | | |

---

## Recommendations

### Primary Target Model
[Model]: [Reason]

### Secondary Support
[Model(s)]: [With what limitations]

### Not Recommended
[Model(s)]: [Reason]
