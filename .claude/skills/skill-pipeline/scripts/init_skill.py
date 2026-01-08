#!/usr/bin/env python3
"""
Skill Pipeline Initializer - Creates a new skill with evaluation structure

Extended from official skill-creator to include:
- Evaluation directory structure
- Pipeline phase documentation templates
- Model-specific test case placeholders

Usage:
    init_skill.py <skill-name> --path <path> [--with-evaluations]

Examples:
    init_skill.py my-new-skill --path .claude/skills
    init_skill.py my-api-helper --path skills --with-evaluations
"""

import sys
import json
from pathlib import Path


SKILL_TEMPLATE = """---
name: {skill_name}
description: |
  [TODO: What the skill does]. [TODO: When to use it].
  Use when [TODO: specific triggers that should activate this skill].
---

# {skill_title}

## Overview

[TODO: 1-2 sentences explaining what this skill enables]

## Quick Start

[TODO: Minimal example to get started - show the simplest use case]

## Workflow

[TODO: Choose structure based on skill type:
- Instruction-heavy: Decision guides and text workflows
- Code-heavy: Script-driven with validation loops
- Mixed: Combination of both]

### Step 1: [TODO]

[Instructions or script]

### Step 2: [TODO]

[Instructions or script]

### Step 3: [TODO]

[Instructions or script]

## Feedback Loop

[TODO: If applicable, add validation cycle:
1. Run validation script
2. If errors: fix and re-validate
3. Only proceed when validation passes]

## References

[TODO: Link to reference files if needed]
- [reference-name.md](references/reference-name.md): For [specific scenario]

---

**Delete unused directories:** Not every skill needs scripts/, references/, and assets/.
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
