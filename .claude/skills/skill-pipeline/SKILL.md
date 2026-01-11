---
name: skill-pipeline
description: |
  Systematic pipeline for creating high-quality agent skills with evaluation-driven
  development. Guides through 6 phases: Example Collection, Discovery, Evaluation Design,
  Authoring, Validation Loop, and Review & Deploy. Use when creating a new skill,
  improving an existing skill, or when the user asks for help building a skill.
---

# Skill Development Pipeline

Evaluation-driven workflow for building high-quality skills.

## Contents

- [Quick Start](#quick-start)
- [Proactive Clarification](#proactive-clarification)
- [Phase Overview](#phase-overview)
- [Phase 0: Example Collection](#phase-0-example-collection)
- [Phase 1: Discovery](#phase-1-discovery)
- [Phase 2: Evaluation Design](#phase-2-evaluation-design)
- [Phase 3: Skill Authoring](#phase-3-skill-authoring)
- [Phase 4: Validation Loop](#phase-4-validation-loop)
- [Phase 5: Review & Deploy](#phase-5-review--deploy)
- [Utility Scripts](#utility-scripts)

---

## Quick Start

**Before starting:** Read [references/skill-fundamentals.md](references/skill-fundamentals.md) to understand skill anatomy, core principles, and progressive disclosure patterns.

1. Collect 3+ concrete usage examples
2. Work through examples WITHOUT a skill (identify gaps)
3. Create test cases with success criteria
4. Author minimal skill content
5. Iterate until tests pass
6. Review and deploy

---

## Proactive Clarification

Use `AskUserQuestion` throughout the pipeline to avoid assumptions and rework.

**Always ask when:**
- User's example is ambiguous or incomplete
- Multiple valid interpretations exist
- Success criteria are unclear
- Failure root cause is uncertain
- Trade-offs require user preference (e.g., simplicity vs. coverage)

**Do NOT assume - ask early.** Each phase below includes specific "🔍 Ask when..." prompts.

---

## Phase Overview

| Phase | Goal | Output |
|-------|------|--------|
| 0. Examples | Understand concrete usage | Example collection doc |
| 1. Discovery | Identify Claude's gaps | Gap analysis doc |
| 2. Evaluation | Define success criteria | Test cases JSON |
| 3. Authoring | Write minimal content | SKILL.md + resources |
| 4. Validation | Iterate until pass | Refined skill |
| 5. Review | Human approval | Deployed .skill file |

---

## Phase 0: Example Collection

**Goal**: Establish concrete understanding before development.

### Steps

1. **Identify the need**: What task/domain? Who uses it?

2. **Collect 3+ examples**: For each, document:
   - Trigger phrase ("What would a user say?")
   - Input provided
   - Expected output
   - Success criteria

3. **Classify complexity**:
   | Level | Characteristics | Expected Size |
   |-------|-----------------|---------------|
   | Simple | Single workflow, no scripts | <100 lines |
   | Medium | Multiple workflows OR scripts | 100-300 lines |
   | Complex | Multi-domain, validation loops | >300 lines |

**Template**: See [templates/example-collection.md](templates/example-collection.md)

🔍 **Ask when:**
- Example lacks clear expected output → "What should the result look like?"
- Trigger phrase is vague → "What exact words would you use to invoke this?"
- Edge cases are unclear → "How should it handle [specific scenario]?"
- Complexity classification is uncertain → "Do you need [feature X] or is the simpler version enough?"

---

## Phase 1: Discovery

**Goal**: Understand what context Claude lacks.

### Steps

1. **Work through each example WITHOUT a skill**
   - Use normal prompting
   - Note information you repeatedly provide
   - Document specific failures

2. **Identify reusable resources**:
   - Code to rewrite each time → `scripts/`
   - Documentation needed → `references/`
   - Templates/assets → `assets/`

**Template**: See [templates/gap-analysis.md](templates/gap-analysis.md)

🔍 **Ask when:**
- Multiple gaps identified → "Which gaps are most critical to address?"
- Unsure if something is a gap or feature → "Is [behavior X] a bug or intended?"
- Resource type unclear → "Should this be a script (exact) or reference doc (flexible)?"

---

## Phase 2: Evaluation Design

**Goal**: Create measurable success criteria BEFORE writing the skill.

### Steps

1. **Select target models**:
   | Model | Use Case | Guidance Needs |
   |-------|----------|----------------|
   | Haiku | Fast, economical | More explicit |
   | Sonnet | Balanced | Standard |
   | Opus | Complex reasoning | Less hand-holding |

2. **Create 3+ test cases** in JSON format:
   ```json
   {
     "test_id": "skill-name-001",
     "query": "User's query",
     "success_criteria": {
       "must_pass": ["criterion 1", "criterion 2"],
       "should_pass": ["optional criterion"]
     }
   }
   ```

3. **Establish baseline**: Run tests WITHOUT skill, record results

4. **Define targets**: Success rate ≥95%, token efficiency, consistency

**Schema**: See [templates/evaluation.json](templates/evaluation.json)
**Model criteria**: See [templates/model-criteria.md](templates/model-criteria.md)

🔍 **Ask when:**
- Success criteria are subjective → "How would you judge if [output] is good enough?"
- must_pass vs should_pass unclear → "Is [criterion] required or nice-to-have?"
- Target model unclear → "Which model will this skill primarily run on?"
- Baseline results are ambiguous → "Does this baseline failure count as a gap we need to fix?"

---

## Phase 3: Skill Authoring

**Goal**: Write minimal, effective content.

### 3.1 Initialize

```bash
init_skill.py <skill-name> --path .claude/skills
```

### 3.2 Write Frontmatter

```yaml
---
name: verb-ing-noun  # hyphen-case, max 64 chars
description: |
  Third-person description of what it does.
  Use when [specific triggers].
---
```

**Rules**:
- Description in third person ("Processes..." not "I process...")
- Include both WHAT and WHEN to trigger
- Max 1024 chars, no angle brackets

### 3.3 Choose Content Type

| Task Type | Freedom Level | Include |
|-----------|---------------|---------|
| Fragile/exact sequence | Low | Exact scripts |
| Pattern exists | Medium | Pseudocode + params |
| Context-dependent | High | Text instructions |

### 3.4 Apply Progressive Disclosure

- Keep SKILL.md < 500 lines
- Split details into reference files
- Max 1 level of nesting
- Long files (>100 lines) need TOC

### 3.5 Validate Structure

```bash
quick_validate.py .claude/skills/<skill-name>
```

Must pass before proceeding to Phase 4.

**Reference**: See [references/best-practice-summary.md](references/best-practice-summary.md)

🔍 **Ask when:**
- Content type tradeoff → "Do you prefer exact scripts (reliable) or flexible instructions (adaptable)?"
- Structure decisions → "Should this be one large section or split into references?"
- Terminology choices → "What term should we use for [concept]?"
- Validation fails on structure → "The skill exceeds 500 lines - which parts should move to references?"

---

## Phase 4: Validation Loop

**Goal**: Iterate until all evaluations pass.

### Run Evaluations

```bash
run_evaluations.py .claude/skills/<skill-name> --model sonnet
```

### Failure Analysis

For each failure, identify:
- **Discovery issue**: Skill didn't trigger → improve description
- **Execution issue**: Wrong approach → clarify instructions
- **Output issue**: Incorrect result → add examples/validation

### Token Budget Check

- [ ] SKILL.md body < 500 lines
- [ ] No redundant explanations
- [ ] Progressive disclosure used
- [ ] References max 1 level deep

**Template**: See [templates/failure-report.md](templates/failure-report.md)

🔍 **Ask when:**
- Multiple failures with different root causes → "Which failure should we prioritize fixing first?"
- Failure diagnosis is ambiguous → "Is this a discovery, execution, or output issue?"
- Fix has tradeoffs → "Fixing [A] might break [B] - acceptable?"
- Stuck after iterations → "We've tried N approaches - should we reconsider the scope?"

---

## Phase 5: Review & Deploy

**Goal**: Mandatory human review before deployment.

### Review Checklist

**Core Quality**:
- [ ] Description specific with triggers
- [ ] Written in third person
- [ ] SKILL.md < 500 lines
- [ ] Consistent terminology

**Testing**:
- [ ] 3+ evaluations pass
- [ ] Tested with target models
- [ ] Token usage within budget

**Template**: See [templates/review-checklist.md](templates/review-checklist.md)

### Package

```bash
package_skill.py .claude/skills/<skill-name> ./dist
```

Creates `<skill-name>.skill` file for distribution.

🔍 **Ask when:**
- Review reveals issues → "Should we fix [issue] now or note it for v2?"
- Deployment scope unclear → "Deploy to user-level, project-level, or both?"
- Checklist item fails → "This fails [criterion] - block deploy or accept as-is?"

---

## Utility Scripts

All scripts use PEP 723 inline metadata and run via `uv run` for automatic dependency management.

| Script | Purpose | Usage |
|--------|---------|-------|
| `init_skill.py` | Create skill template | `uv run init_skill.py my-skill --path .claude/skills` |
| `quick_validate.py` | Validate structure | `uv run quick_validate.py .claude/skills/my-skill` |
| `run_evaluations.py` | Run test cases | `uv run run_evaluations.py .claude/skills/my-skill` |
| `package_skill.py` | Create .skill file | `uv run package_skill.py .claude/skills/my-skill ./dist` |

All scripts in: `.claude/skills/skill-pipeline/scripts/`

---

## References

- [Skill Fundamentals](references/skill-fundamentals.md): Core concepts, anatomy, and principles (read first)
- [Best Practice Summary](references/best-practice-summary.md): Condensed authoring guidelines
- [Model Guidance](references/model-guidance.md): Haiku/Sonnet/Opus optimization
