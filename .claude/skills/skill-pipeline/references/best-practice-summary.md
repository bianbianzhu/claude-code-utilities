# Skill Best Practices Summary

Condensed reference for quick lookup during skill development.

---

## Core Principles

### 1. Concise is Key
- Context window is shared resource
- Only add context Claude doesn't already have
- Challenge each piece: "Does Claude really need this?"

### 2. Degrees of Freedom
| Freedom Level | When to Use | Example |
|--------------|-------------|---------|
| High (text instructions) | Multiple valid approaches | Code review guidelines |
| Medium (pseudocode/params) | Preferred pattern exists | Report generator template |
| Low (exact scripts) | Operations are fragile | Database migrations |

### 3. Test with Target Models
- Haiku: Needs more guidance
- Sonnet: Balance clarity and efficiency
- Opus: Avoid over-explaining

---

## Structure Requirements

### Frontmatter
```yaml
name: hyphen-case-name  # max 64 chars, lowercase + digits + hyphens
description: Third-person description of what it does and when to use it
```

### Naming
- Prefer gerund: `processing-pdfs`, `analyzing-data`
- Acceptable: `pdf-processor`, `data-analyzer`
- Avoid: `helper`, `utils`, `tools`

### Description Guidelines
- Write in third person: "Processes files..." not "I process..."
- Include what it does AND when to use it
- Be specific with key terms for discovery

---

## Token Budget

| Component | Limit |
|-----------|-------|
| SKILL.md body | < 500 lines |
| Reference files | < 300 lines each |
| Total content | < 1000 lines |

---

## Progressive Disclosure

### Pattern 1: High-level guide with references
```markdown
# Main Topic
## Quick Start
[Basic content here]

## Advanced
See [ADVANCED.md](ADVANCED.md) for details
```

### Pattern 2: Domain organization
```
skill/
├── SKILL.md (overview + navigation)
└── references/
    ├── domain-a.md
    └── domain-b.md
```

### Key Rules
- Max 1 level of nesting for references
- Long files (>100 lines) need TOC
- Use descriptive filenames

---

## Content Patterns

### Templates
Strict: "ALWAYS use this exact structure..."
Flexible: "Here is a sensible default, adapt as needed..."

### Examples
Provide input/output pairs:
```
Input: [example input]
Output: [expected output]
```

### Workflows
Break complex tasks into numbered steps with validation checkpoints.

### Feedback Loops
Run validator → fix errors → repeat until passing

---

## Anti-Patterns to Avoid

| Don't | Do Instead |
|-------|------------|
| Windows paths (`\`) | Unix paths (`/`) |
| Multiple library options | Single recommended approach |
| Time-sensitive info | "Current" vs "Old patterns" sections |
| Inconsistent terminology | Pick one term, use throughout |
| Deeply nested references | Flat structure, one level deep |
| Magic numbers | Documented constants |

---

## Scripts Best Practices

### Error Handling
- Handle errors explicitly, don't punt to Claude
- Provide helpful error messages
- Create default behaviors where sensible

### Documentation
- Clear docstrings
- Usage examples in markdown
- Explain non-obvious constants

### Execution vs Reference
- "Run `script.py`" = execute
- "See `script.py` for algorithm" = read as reference

---

## Quality Checklist

### Before Shipping
- [ ] Description specific with key terms
- [ ] SKILL.md < 500 lines
- [ ] References one level deep
- [ ] No time-sensitive content
- [ ] Consistent terminology
- [ ] At least 3 test cases
- [ ] Tested with target model(s)

---

## Quick Reference: Writing Style

| Location | Style |
|----------|-------|
| Frontmatter description | Third person |
| SKILL.md body | Imperative |
| Instructions | Direct, concise |
| Examples | Concrete, not abstract |
