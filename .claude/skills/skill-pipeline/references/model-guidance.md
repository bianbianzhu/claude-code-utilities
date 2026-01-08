# Model-Specific Guidance

Reference for optimizing skills across Claude models.

---

## Model Comparison

| Aspect | Haiku | Sonnet | Opus |
|--------|-------|--------|------|
| Speed | Fastest | Balanced | Slowest |
| Cost | Lowest | Medium | Highest |
| Reasoning | Basic | Good | Best |
| Context | Shorter | Medium | Longest |
| Best for | Simple, structured | General purpose | Complex judgment |

---

## Haiku Optimization

### Strengths
- Fast response time
- Cost-effective for high volume
- Good at following structured templates
- Reliable for simple, well-defined tasks

### Limitations
- Struggles with complex multi-step reasoning
- May miss nuance in instructions
- Shorter outputs preferred
- Needs more explicit guidance

### Skill Adjustments
1. **Simplify decision trees** - Reduce branching logic
2. **Provide explicit templates** - Don't rely on inference
3. **Reduce reference size** - Keep under 200 lines
4. **Use concrete examples** - More examples, less explanation
5. **Break into smaller steps** - One concept per section

### Token Budget for Haiku
- SKILL.md: < 300 lines
- References: < 200 lines each
- Total: < 500 lines

---

## Sonnet Optimization

### Strengths
- Best balance of capability and cost
- Reliable format following
- Good reasoning for standard tasks
- Handles moderate complexity well

### Limitations
- May over-elaborate on simple tasks
- Occasionally verbose
- Medium context window

### Skill Adjustments
1. **Standard guidance level** - Neither too detailed nor sparse
2. **Include workflow patterns** - Benefits from structure
3. **Moderate examples** - 2-3 well-chosen examples
4. **Trust with interpretation** - Can handle some ambiguity

### Token Budget for Sonnet
- SKILL.md: < 500 lines
- References: < 300 lines each
- Total: < 800 lines

---

## Opus Optimization

### Strengths
- Superior reasoning and judgment
- Handles complex, nuanced tasks
- Best at edge cases
- Excellent at synthesis

### Limitations
- Higher cost per query
- May over-think simple tasks
- Slower response time
- Overkill for routine work

### Skill Adjustments
1. **Can handle complexity** - More sophisticated instructions OK
2. **Trust judgment calls** - Less hand-holding needed
3. **Focus on constraints** - What NOT to do matters more
4. **Reduce redundancy** - Don't explain obvious things

### Token Budget for Opus
- SKILL.md: < 500 lines
- References: < 500 lines each
- Total: < 1000 lines

---

## Cross-Model Compatibility

### Writing for Multiple Models

If your skill must work across models:

1. **Structure for Haiku** - Clear, explicit, well-organized
2. **Add depth for Sonnet/Opus** - Via reference files
3. **Use progressive disclosure** - Simple in SKILL.md, detailed in refs

### Universal Best Practices
- Clear section headings
- Numbered steps for workflows
- Concrete examples over abstract rules
- Validation/feedback loops
- One level of reference nesting

---

## Model Selection Guide

### Choose Haiku When:
- Task is well-defined and structured
- High volume of requests
- Cost is primary concern
- Simple transformations or lookups
- Template-based outputs

### Choose Sonnet When:
- Standard complexity tasks
- Balance of quality and cost needed
- General-purpose usage
- Most production workloads

### Choose Opus When:
- Complex reasoning required
- High-stakes decisions
- Edge cases are common
- Quality is paramount
- Novel or unusual requests

---

## Testing Strategy

### Minimum Testing
| Primary Model | Also Test |
|--------------|-----------|
| Haiku | Sonnet |
| Sonnet | Haiku |
| Opus | Sonnet |

### Full Testing (Recommended)
Test all three models with:
1. Core functionality (2-3 tests)
2. Edge cases (1-2 tests)
3. Format compliance (1 test)

### Evaluation Checklist
- [ ] Core tests pass on primary model
- [ ] Core tests pass on secondary model
- [ ] Format is consistent across models
- [ ] No model produces errors
- [ ] Performance is acceptable

---

## Common Model-Specific Issues

### Haiku Issues
| Problem | Solution |
|---------|----------|
| Misses instructions | Make more explicit |
| Wrong format | Add template |
| Incomplete output | Break into steps |
| Ignores constraints | Repeat constraints |

### Sonnet Issues
| Problem | Solution |
|---------|----------|
| Too verbose | Add "be concise" |
| Over-explains | Reduce examples |
| Slow on simple tasks | Simplify skill |

### Opus Issues
| Problem | Solution |
|---------|----------|
| Over-thinks simple tasks | Use Sonnet instead |
| Too detailed | Add brevity constraint |
| Expensive for routine | Reserve for complex work |
