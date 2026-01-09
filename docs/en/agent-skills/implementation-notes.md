# Implementation Notes: Skill Pipeline

Notes and insights captured during skill-pipeline development for future reference.

---

## Issue: init_skill.py Template Richness Gap

**Date**: 2025-01-09

### Context

The `skill-pipeline/scripts/init_skill.py` has less detailed templates compared to the official `skill-creator/scripts/init_skill.py`.

### Key Insight: What Gets Loaded to LLM Context

| Source | Loaded to Context? | Reason |
|--------|-------------------|--------|
| Python code/comments in `init_skill.py` | ❌ No | Script is executed, not read |
| **Generated files** (SKILL.md, example.py, etc.) | ✅ Yes | Claude reads these when working on the skill |
| Script stdout/stderr | ✅ Yes | Execution output is captured |

**Implication**: The content embedded in generated file templates DOES matter because Claude will read those files later. The Python code comments don't matter for context.

### What the Official Version Does Well

The official `skill-creator/scripts/init_skill.py` embeds ~100 lines of rich guidance INTO the generated SKILL.md template:

- 4 structure patterns (Workflow-Based, Task-Based, Reference/Guidelines, Capabilities-Based)
- Detailed resource directory explanations (scripts/, references/, assets/)
- Real examples from other skills
- Comprehensive TODO placeholders

This guidance is available to Claude when it reads the generated SKILL.md during skill authoring.

### The Gap in skill-pipeline

The pipeline version's `init_skill.py` has simpler templates because:
1. Assumed the separate `templates/` directory would provide guidance
2. Didn't account for the fact that generated files are what Claude reads during authoring

**Workflow disconnect**: The `templates/` files (example-collection.md, gap-analysis.md, etc.) are for human workflow documentation. The generated SKILL.md is for Claude's context during skill authoring.

### Pipeline Phase Context

From `skill-pipeline/SKILL.md`:

| Phase | Name | When init_skill.py runs |
|-------|------|------------------------|
| 0 | Example Collection | ❌ Before any code |
| 1 | Discovery | ❌ Work WITHOUT skill |
| 2 | Evaluation Design | ❌ Create test cases |
| 3 | Skill Authoring | ✅ **init_skill.py runs here** |
| 4 | Validation Loop | After authoring |
| 5 | Review & Deploy | Final stage |

Structure decisions come after gap analysis (Phase 1), but once in Phase 3, the generated SKILL.md **should** have rich guidance.

### Recommended Fix

Update `skill-pipeline/scripts/init_skill.py` to include comprehensive templates from the official version in the generated files. The templates/ directory serves a different purpose (workflow documentation for humans).

### Status

**Implemented** - 2025-01-09

Updated `skill-pipeline/scripts/init_skill.py` SKILL_TEMPLATE to include:
- **Pipeline Context section**: References Phase 1 (gap analysis) and Phase 2 (test cases)
- **4 Structure Patterns**: Workflow-Based, Task-Based, Reference/Guidelines, Capabilities-Based
- **Degrees of Freedom guidance**: Maps gap types to prescription levels (from best-practice-summary.md)
- **Rich resource directory documentation**: Real examples from other skills
- **Token Budget Reminder**: With Phase 4 validation reference

---

## General Principle: Script Output vs Script Content

When writing utility scripts for skills:

```
┌─────────────────────────────────────────────────────────────┐
│ What Claude sees when script runs:                          │
│                                                             │
│   ✅ stdout/stderr (print statements, errors)               │
│   ✅ Files created/modified by the script                   │
│   ✅ Exit code (success/failure)                            │
│                                                             │
│   ❌ Python code in the script                              │
│   ❌ Comments/docstrings in the script                      │
│   ❌ Variable names or internal logic                       │
└─────────────────────────────────────────────────────────────┘
```

**Best practice**: Put guidance in generated file content, not in script comments.
