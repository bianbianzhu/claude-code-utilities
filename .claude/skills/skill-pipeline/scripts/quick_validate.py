#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml"]
# ///
"""
Skill Pipeline Validator - Extended validation with token budget checking

Extended from official quick_validate.py to include:
- Token budget checking (line counts as proxy)
- Reference depth validation
- TOC presence checking for long files
- Comprehensive reporting

Usage:
    uv run quick_validate.py <skill_directory> [--verbose]

Examples:
    uv run quick_validate.py .claude/skills/my-skill
    uv run quick_validate.py .claude/skills/my-skill --verbose
"""

import sys
import os
import re
import yaml
from pathlib import Path
from dataclasses import dataclass, field


@dataclass
class ValidationResult:
    """Container for validation results."""
    valid: bool
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    metrics: dict = field(default_factory=dict)


# Token budget thresholds (using line count as proxy)
MAX_SKILL_MD_LINES = 500
MAX_REFERENCE_LINES = 300
MAX_TOTAL_LINES = 1000
TOC_THRESHOLD_LINES = 100  # Files above this should have TOC


def count_lines(file_path: Path) -> int:
    """Count non-empty lines in a file."""
    try:
        content = file_path.read_text()
        return len([line for line in content.split('\n') if line.strip()])
    except Exception:
        return 0


def has_table_of_contents(content: str) -> bool:
    """Check if content has a table of contents section."""
    toc_patterns = [
        r'^##?\s*(Table of Contents|Contents|TOC)',
        r'^##?\s*.*\n\s*-\s*\[.*\]\(#',  # Markdown link list pattern
        r'\n\s*-\s*\[.*\]\(#.*\)\n\s*-\s*\[.*\]\(#',  # Multiple TOC links
    ]
    for pattern in toc_patterns:
        if re.search(pattern, content, re.IGNORECASE | re.MULTILINE):
            return True
    return False


def validate_frontmatter(content: str) -> tuple[bool, str, dict | None]:
    """Extract and validate YAML frontmatter."""
    if not content.startswith('---'):
        return False, "No YAML frontmatter found", None

    match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not match:
        return False, "Invalid frontmatter format", None

    frontmatter_text = match.group(1)

    try:
        frontmatter = yaml.safe_load(frontmatter_text)
        if not isinstance(frontmatter, dict):
            return False, "Frontmatter must be a YAML dictionary", None
    except yaml.YAMLError as e:
        return False, f"Invalid YAML in frontmatter: {e}", None

    return True, "OK", frontmatter


def validate_name(name: str) -> list[str]:
    """Validate skill name format. Returns list of errors."""
    errors = []

    if not isinstance(name, str):
        return [f"Name must be a string, got {type(name).__name__}"]

    name = name.strip()
    if not name:
        return ["Name cannot be empty"]

    if not re.match(r'^[a-z0-9-]+$', name):
        errors.append(f"Name '{name}' should be hyphen-case (lowercase letters, digits, and hyphens only)")

    if name.startswith('-') or name.endswith('-') or '--' in name:
        errors.append(f"Name '{name}' cannot start/end with hyphen or contain consecutive hyphens")

    if len(name) > 64:
        errors.append(f"Name is too long ({len(name)} characters). Maximum is 64 characters.")

    return errors


def validate_description(description: str) -> list[str]:
    """Validate skill description. Returns list of errors."""
    errors = []

    if not isinstance(description, str):
        return [f"Description must be a string, got {type(description).__name__}"]

    description = description.strip()
    if not description:
        return ["Description cannot be empty"]

    if '<' in description or '>' in description:
        errors.append("Description cannot contain angle brackets (< or >)")

    if len(description) > 1024:
        errors.append(f"Description is too long ({len(description)} characters). Maximum is 1024 characters.")

    return errors


def validate_reference_depth(skill_path: Path) -> list[str]:
    """
    Check that references don't nest more than 1 level deep.
    Returns list of warnings.
    """
    warnings = []
    refs_dir = skill_path / 'references'

    if not refs_dir.exists():
        return []

    # Check for nested directories in references
    for item in refs_dir.rglob('*'):
        if item.is_dir() and item != refs_dir:
            rel_path = item.relative_to(refs_dir)
            depth = len(rel_path.parts)
            if depth > 1:
                warnings.append(f"Reference nesting too deep ({depth} levels): {rel_path}")

    return warnings


def check_token_budget(skill_path: Path) -> tuple[dict, list[str], list[str]]:
    """
    Check token budget using line counts as proxy.
    Returns (metrics, errors, warnings).
    """
    errors = []
    warnings = []
    metrics = {
        'skill_md_lines': 0,
        'total_reference_lines': 0,
        'total_lines': 0,
        'files_needing_toc': [],
    }

    # Check SKILL.md
    skill_md = skill_path / 'SKILL.md'
    if skill_md.exists():
        content = skill_md.read_text()
        lines = count_lines(skill_md)
        metrics['skill_md_lines'] = lines

        if lines > MAX_SKILL_MD_LINES:
            errors.append(f"SKILL.md too long: {lines} lines (max {MAX_SKILL_MD_LINES})")

        if lines > TOC_THRESHOLD_LINES and not has_table_of_contents(content):
            metrics['files_needing_toc'].append('SKILL.md')
            warnings.append(f"SKILL.md ({lines} lines) should have a Table of Contents")

    # Check reference files
    refs_dir = skill_path / 'references'
    if refs_dir.exists():
        for ref_file in refs_dir.glob('**/*.md'):
            content = ref_file.read_text()
            lines = count_lines(ref_file)
            metrics['total_reference_lines'] += lines

            if lines > MAX_REFERENCE_LINES:
                rel_path = ref_file.relative_to(skill_path)
                warnings.append(f"Reference file too long: {rel_path} ({lines} lines, recommended max {MAX_REFERENCE_LINES})")

            if lines > TOC_THRESHOLD_LINES and not has_table_of_contents(content):
                rel_path = ref_file.relative_to(skill_path)
                metrics['files_needing_toc'].append(str(rel_path))
                warnings.append(f"{rel_path} ({lines} lines) should have a Table of Contents")

    metrics['total_lines'] = metrics['skill_md_lines'] + metrics['total_reference_lines']

    if metrics['total_lines'] > MAX_TOTAL_LINES:
        warnings.append(f"Total content too long: {metrics['total_lines']} lines (recommended max {MAX_TOTAL_LINES})")

    return metrics, errors, warnings


def validate_skill(skill_path: str | Path, verbose: bool = False) -> ValidationResult:
    """
    Comprehensive validation of a skill.

    Args:
        skill_path: Path to the skill directory
        verbose: If True, include detailed metrics in result

    Returns:
        ValidationResult with valid flag, errors, warnings, and metrics
    """
    skill_path = Path(skill_path)
    result = ValidationResult(valid=True)

    # Check skill directory exists
    if not skill_path.exists():
        result.valid = False
        result.errors.append(f"Skill directory not found: {skill_path}")
        return result

    if not skill_path.is_dir():
        result.valid = False
        result.errors.append(f"Path is not a directory: {skill_path}")
        return result

    # Check SKILL.md exists
    skill_md = skill_path / 'SKILL.md'
    if not skill_md.exists():
        result.valid = False
        result.errors.append("SKILL.md not found")
        return result

    # Read and validate frontmatter
    content = skill_md.read_text()
    valid_fm, msg, frontmatter = validate_frontmatter(content)

    if not valid_fm:
        result.valid = False
        result.errors.append(msg)
        return result

    # Define allowed properties
    ALLOWED_PROPERTIES = {'name', 'description', 'license', 'allowed-tools', 'metadata'}

    # Check for unexpected properties
    unexpected_keys = set(frontmatter.keys()) - ALLOWED_PROPERTIES
    if unexpected_keys:
        result.valid = False
        result.errors.append(
            f"Unexpected key(s) in SKILL.md frontmatter: {', '.join(sorted(unexpected_keys))}. "
            f"Allowed properties are: {', '.join(sorted(ALLOWED_PROPERTIES))}"
        )

    # Check required fields
    if 'name' not in frontmatter:
        result.valid = False
        result.errors.append("Missing 'name' in frontmatter")
    else:
        name_errors = validate_name(frontmatter['name'])
        if name_errors:
            result.valid = False
            result.errors.extend(name_errors)

    if 'description' not in frontmatter:
        result.valid = False
        result.errors.append("Missing 'description' in frontmatter")
    else:
        desc_errors = validate_description(frontmatter['description'])
        if desc_errors:
            result.valid = False
            result.errors.extend(desc_errors)

    # Check reference depth (warnings only)
    ref_warnings = validate_reference_depth(skill_path)
    result.warnings.extend(ref_warnings)

    # Check token budget
    metrics, budget_errors, budget_warnings = check_token_budget(skill_path)
    result.errors.extend(budget_errors)
    result.warnings.extend(budget_warnings)
    result.metrics = metrics

    # Update valid flag based on errors
    if result.errors:
        result.valid = False

    return result


def format_report(result: ValidationResult, skill_path: Path, verbose: bool = False) -> str:
    """Format validation result as a human-readable report."""
    lines = []
    lines.append(f"Skill Validation Report: {skill_path.name}")
    lines.append("=" * 50)

    if result.valid:
        lines.append("Status: VALID")
    else:
        lines.append("Status: INVALID")

    if result.errors:
        lines.append(f"\nErrors ({len(result.errors)}):")
        for error in result.errors:
            lines.append(f"  [ERROR] {error}")

    if result.warnings:
        lines.append(f"\nWarnings ({len(result.warnings)}):")
        for warning in result.warnings:
            lines.append(f"  [WARN] {warning}")

    if verbose and result.metrics:
        lines.append("\nMetrics:")
        lines.append(f"  SKILL.md lines: {result.metrics.get('skill_md_lines', 0)}")
        lines.append(f"  Reference lines: {result.metrics.get('total_reference_lines', 0)}")
        lines.append(f"  Total lines: {result.metrics.get('total_lines', 0)}")

        toc_files = result.metrics.get('files_needing_toc', [])
        if toc_files:
            lines.append(f"  Files needing TOC: {', '.join(toc_files)}")

    if not result.errors and not result.warnings:
        lines.append("\nNo issues found.")

    return '\n'.join(lines)


def main():
    args = sys.argv[1:]

    if not args or args[0] in ['-h', '--help']:
        print("Usage: uv run quick_validate.py <skill_directory> [--verbose]")
        print("\nValidates a skill directory for:")
        print("  - SKILL.md exists and has valid frontmatter")
        print("  - Name format (hyphen-case, max 64 chars)")
        print("  - Description format (no angle brackets, max 1024 chars)")
        print("  - Token budget (line counts)")
        print("  - Reference depth (max 1 level)")
        print("  - TOC presence for long files")
        print("\nOptions:")
        print("  --verbose    Show detailed metrics")
        print("\nExamples:")
        print("  uv run quick_validate.py .claude/skills/my-skill")
        print("  uv run quick_validate.py .claude/skills/my-skill --verbose")
        sys.exit(0)

    skill_path = Path(args[0])
    verbose = '--verbose' in args

    result = validate_skill(skill_path, verbose)
    report = format_report(result, skill_path, verbose)

    print(report)
    sys.exit(0 if result.valid else 1)


if __name__ == "__main__":
    main()
