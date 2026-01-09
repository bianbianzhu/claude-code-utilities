#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""
Skill Pipeline Initializer - Creates a new skill with evaluation structure

Extended from official skill-creator to include:
- Evaluation directory structure
- Pipeline phase documentation templates
- Model-specific test case placeholders

Usage:
    uv run init_skill.py <skill-name> --path <path> [--with-evaluations]

Examples:
    uv run init_skill.py my-new-skill --path .claude/skills
    uv run init_skill.py my-api-helper --path skills --with-evaluations
"""

import sys
import json
from pathlib import Path


SKILL_TEMPLATE = """---
name: {skill_name}
description: |
  [TODO: Third-person description of what the skill does].
  Use when [TODO: specific triggers that should activate this skill].
---

# {skill_title}

## Overview

[TODO: 1-2 sentences explaining what this skill enables]

## Pipeline Context

> **Phase 3: Skill Authoring** - You should have:
> - Gap analysis from Phase 1 (what context Claude lacks)
> - Test cases from Phase 2 (success criteria to meet)
>
> This template provides structure guidance. Delete this section when done.

## Structuring This Skill

[TODO: Choose the structure pattern that best fits this skill's purpose:

**1. Workflow-Based** (best for sequential processes)
- Works well when there are clear step-by-step procedures
- Example: DOCX skill with "Workflow Decision Tree" → "Reading" → "Creating" → "Editing"
- Structure: ## Overview → ## Workflow Decision Tree → ## Step 1 → ## Step 2...

**2. Task-Based** (best for tool collections)
- Works well when the skill offers different operations/capabilities
- Example: PDF skill with "Quick Start" → "Merge PDFs" → "Split PDFs" → "Extract Text"
- Structure: ## Overview → ## Quick Start → ## Task Category 1 → ## Task Category 2...

**3. Reference/Guidelines** (best for standards or specifications)
- Works well for brand guidelines, coding standards, or requirements
- Example: Brand styling with "Brand Guidelines" → "Colors" → "Typography" → "Features"
- Structure: ## Overview → ## Guidelines → ## Specifications → ## Usage...

**4. Capabilities-Based** (best for integrated systems)
- Works well when the skill provides multiple interrelated features
- Example: Product Management with "Core Capabilities" → numbered capability list
- Structure: ## Overview → ## Core Capabilities → ### 1. Feature → ### 2. Feature...

Patterns can be mixed and matched as needed. Most skills combine patterns (e.g., start with task-based, add workflow for complex operations).

**Delete this entire section when done - it's just guidance.**]

## Degrees of Freedom

[TODO: Choose the right level of prescription based on your gap analysis:

| Freedom Level | When to Use | What to Include |
|--------------|-------------|-----------------|
| **High** (text instructions) | Multiple valid approaches exist | Guidelines, principles, examples |
| **Medium** (pseudocode/params) | Preferred pattern exists | Flexible templates, key parameters |
| **Low** (exact scripts) | Operations are fragile/exact | Runnable scripts, strict sequences |

Match to identified gaps:
- Knowledge gaps → High freedom (reference docs)
- Format gaps → Medium freedom (templates)
- Process gaps → Low freedom (exact scripts)

**Delete this section when done.**]

## [TODO: Replace with first main section based on chosen structure]

[TODO: Add content based on your gap analysis from Phase 1. Include:
- Concrete examples with realistic user requests
- Code samples for technical operations
- Decision trees for complex workflows
- References to scripts/templates/references as needed]

## Feedback Loop

[TODO: If applicable, add validation cycle:
1. Run validation script
2. If errors: fix and re-validate
3. Only proceed when validation passes

This is especially important for low-freedom (script-driven) skills.]

## Resources

This skill includes resource directories for different types of bundled content:

### scripts/
Executable code (Python/Bash/etc.) that can be run directly to perform specific operations.

**Examples from other skills:**
- PDF skill: `fill_fillable_fields.py`, `extract_form_field_info.py` - utilities for PDF manipulation
- DOCX skill: `document.py`, `utilities.py` - Python modules for document processing

**Appropriate for:** Python scripts, shell scripts, or any executable code that performs automation, data processing, or specific operations.

**Note:** Scripts may be executed without loading into context, but can still be read by Claude for patching or environment adjustments.

### references/
Documentation and reference material intended to be loaded into context to inform Claude's process and thinking.

**Examples from other skills:**
- Product management: `communication.md`, `context_building.md` - detailed workflow guides
- BigQuery: API reference documentation and query examples
- Finance: Schema documentation, company policies

**Appropriate for:** In-depth documentation, API references, database schemas, comprehensive guides, or any detailed information that Claude should reference while working.

### assets/
Files not intended to be loaded into context, but rather used within the output Claude produces.

**Examples from other skills:**
- Brand styling: PowerPoint template files (.pptx), logo files
- Frontend builder: HTML/React boilerplate project directories
- Typography: Font files (.ttf, .woff2)

**Appropriate for:** Templates, boilerplate code, document templates, images, icons, fonts, or any files meant to be copied or used in the final output.

---

## Token Budget Reminder

- SKILL.md body: < 500 lines
- Reference files: < 300 lines each
- Max 1 level of nesting for references
- Long files (>100 lines) need TOC

**Delete unused directories.** Not every skill needs scripts/, references/, and assets/.
**Delete guidance sections** (Pipeline Context, Structuring, Degrees of Freedom) before Phase 4 validation.
"""

EXAMPLE_SCRIPT = '''#!/usr/bin/env python3
"""
Example utility script for {skill_name}

Replace with actual implementation or delete if not needed.

For code-heavy skills, scripts should:
- Handle errors explicitly
- Document all parameters
- Include validation
"""

import sys
import json


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: python example.py <input>")
        sys.exit(1)

    input_arg = sys.argv[1]

    # TODO: Implement actual logic
    print(f"Processing: {{input_arg}}")

    result = {{
        "status": "success",
        "input": input_arg,
        "output": "TODO: actual output"
    }}

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
'''

EXAMPLE_REFERENCE = """# Reference: {skill_title}

## Overview

[TODO: What this reference file covers]

## Contents

- [Section 1](#section-1)
- [Section 2](#section-2)

## Section 1

[TODO: Detailed information]

## Section 2

[TODO: Detailed information]
"""

ASSETS_README = """# Assets Directory

Files used in skill output (not loaded into context).

## Common asset types

- Templates (.pptx, .docx, boilerplate directories)
- Images (.png, .jpg, .svg)
- Fonts (.ttf, .otf, .woff)
- Sample data (.csv, .json)

Assets are copied or referenced in output, not read by Claude.
"""

# Evaluation templates
EVALUATION_TEST_CASES = """{
  "skill": "{skill_name}",
  "version": "1.0.0",
  "target_models": ["sonnet"],
  "test_cases": [
    {
      "test_id": "{skill_name}-001",
      "description": "[TODO: What this test verifies]",
      "query": "[TODO: What the user would ask]",
      "files": [],
      "expected_behavior": [
        "[TODO: Expected behavior 1]",
        "[TODO: Expected behavior 2]"
      ],
      "success_criteria": {
        "must_pass": ["[TODO: Required criterion]"],
        "should_pass": ["[TODO: Nice-to-have criterion]"]
      }
    },
    {
      "test_id": "{skill_name}-002",
      "description": "[TODO: Second test case]",
      "query": "[TODO: User query]",
      "files": [],
      "expected_behavior": [],
      "success_criteria": {
        "must_pass": [],
        "should_pass": []
      }
    },
    {
      "test_id": "{skill_name}-003",
      "description": "[TODO: Third test case]",
      "query": "[TODO: User query]",
      "files": [],
      "expected_behavior": [],
      "success_criteria": {
        "must_pass": [],
        "should_pass": []
      }
    }
  ]
}
"""

BASELINE_RESULTS = """{
  "skill": "{skill_name}",
  "baseline_date": "[TODO: Date baseline was recorded]",
  "model_results": {
    "sonnet": {
      "test_results": [],
      "metrics": {
        "success_rate": 0,
        "avg_tokens": 0,
        "avg_time_seconds": 0
      }
    }
  },
  "notes": "[TODO: Observations from baseline testing without skill]"
}
"""

MODEL_CRITERIA = """# Model-Specific Criteria: {skill_title}

## Target Models

- [ ] Haiku
- [x] Sonnet (default)
- [ ] Opus

## Model-Specific Adjustments

### Haiku

- May need: More explicit step-by-step instructions
- Watch for: Skipped validation steps
- Token budget: Stricter (more cost-sensitive)

### Sonnet (Default)

- Standard instructions should suffice
- Watch for: Over-engineering solutions
- Token budget: Standard

### Opus

- Can handle higher ambiguity
- Watch for: Unnecessary complexity
- Token budget: More flexible

## Model Testing Notes

[TODO: Record observations from testing with different models]
"""


def title_case(skill_name: str) -> str:
    """Convert hyphenated skill name to Title Case."""
    return ' '.join(word.capitalize() for word in skill_name.split('-'))


def validate_skill_name(name: str) -> tuple[bool, str]:
    """Validate skill name format."""
    import re

    if not name:
        return False, "Skill name cannot be empty"

    if len(name) > 64:
        return False, f"Skill name too long ({len(name)} chars, max 64)"

    if not re.match(r'^[a-z0-9-]+$', name):
        return False, "Skill name must be lowercase letters, digits, and hyphens only"

    if name.startswith('-') or name.endswith('-') or '--' in name:
        return False, "Skill name cannot start/end with hyphen or contain consecutive hyphens"

    return True, "Valid"


def init_skill(skill_name: str, path: str, with_evaluations: bool = False) -> Path | None:
    """
    Initialize a new skill directory with template structure.

    Args:
        skill_name: Name of the skill (hyphen-case)
        path: Path where the skill directory should be created
        with_evaluations: Whether to create evaluation directory structure

    Returns:
        Path to created skill directory, or None if error
    """
    # Validate skill name
    valid, msg = validate_skill_name(skill_name)
    if not valid:
        print(f"Error: {msg}")
        return None

    skill_path = Path(path).resolve()
    skill_dir = skill_path / skill_name

    # Check if directory already exists
    if skill_dir.exists():
        print(f"Error: Skill directory already exists: {skill_dir}")
        return None

    # Create skill directory
    try:
        skill_dir.mkdir(parents=True, exist_ok=False)
        print(f"Created: {skill_dir}")
    except Exception as e:
        print(f"Error creating directory: {e}")
        return None

    skill_title = title_case(skill_name)

    # Create SKILL.md
    try:
        skill_md = skill_dir / 'SKILL.md'
        skill_md.write_text(SKILL_TEMPLATE.format(
            skill_name=skill_name,
            skill_title=skill_title
        ))
        print("Created: SKILL.md")
    except Exception as e:
        print(f"Error creating SKILL.md: {e}")
        return None

    # Create resource directories
    try:
        # scripts/
        scripts_dir = skill_dir / 'scripts'
        scripts_dir.mkdir()
        (scripts_dir / 'example.py').write_text(
            EXAMPLE_SCRIPT.format(skill_name=skill_name)
        )
        (scripts_dir / 'example.py').chmod(0o755)
        print("Created: scripts/example.py")

        # references/
        refs_dir = skill_dir / 'references'
        refs_dir.mkdir()
        (refs_dir / 'reference.md').write_text(
            EXAMPLE_REFERENCE.format(skill_title=skill_title)
        )
        print("Created: references/reference.md")

        # assets/
        assets_dir = skill_dir / 'assets'
        assets_dir.mkdir()
        (assets_dir / 'README.md').write_text(ASSETS_README)
        print("Created: assets/README.md")

    except Exception as e:
        print(f"Error creating resources: {e}")
        return None

    # Create evaluation structure if requested
    if with_evaluations:
        try:
            eval_dir = skill_dir / 'evaluations'
            eval_dir.mkdir()

            (eval_dir / 'test-cases.json').write_text(
                EVALUATION_TEST_CASES.format(skill_name=skill_name)
            )
            print("Created: evaluations/test-cases.json")

            (eval_dir / 'baseline-results.json').write_text(
                BASELINE_RESULTS.format(skill_name=skill_name)
            )
            print("Created: evaluations/baseline-results.json")

            (eval_dir / 'model-criteria.md').write_text(
                MODEL_CRITERIA.format(skill_title=skill_title)
            )
            print("Created: evaluations/model-criteria.md")

            test_files_dir = eval_dir / 'test-files'
            test_files_dir.mkdir()
            (test_files_dir / '.gitkeep').touch()
            print("Created: evaluations/test-files/")

        except Exception as e:
            print(f"Error creating evaluations: {e}")
            return None

    # Print summary
    print(f"\nSkill '{skill_name}' initialized at {skill_dir}")
    print("\nNext steps:")
    print("1. Edit SKILL.md - complete TODO items and update description")
    print("2. Customize or delete example files in scripts/, references/, assets/")
    if with_evaluations:
        print("3. Complete test cases in evaluations/test-cases.json")
        print("4. Run baseline tests and record in evaluations/baseline-results.json")
    print(f"\nValidate: python quick_validate.py {skill_dir}")

    return skill_dir


def main():
    args = sys.argv[1:]

    if len(args) < 3 or '--path' not in args:
        print("Usage: init_skill.py <skill-name> --path <path> [--with-evaluations]")
        print("\nSkill name requirements:")
        print("  - Hyphen-case (e.g., 'data-analyzer')")
        print("  - Lowercase letters, digits, hyphens only")
        print("  - Max 64 characters")
        print("\nOptions:")
        print("  --with-evaluations  Create evaluation directory structure")
        print("\nExamples:")
        print("  init_skill.py my-skill --path .claude/skills")
        print("  init_skill.py my-skill --path skills --with-evaluations")
        sys.exit(1)

    skill_name = args[0]
    path_index = args.index('--path') + 1
    path = args[path_index]
    with_evaluations = '--with-evaluations' in args

    result = init_skill(skill_name, path, with_evaluations)
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
