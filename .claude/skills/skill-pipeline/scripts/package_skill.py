#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml"]
# ///
"""
Skill Pipeline Packager - Creates a distributable .skill file with evaluation bundling

Extended from official package_skill.py to include:
- Integration with extended validation (token budget, reference depth)
- Evaluation report bundling
- Package manifest with metrics and test results
- Optional exclusion of test files

Usage:
    uv run package_skill.py <skill_directory> [output_directory] [--include-test-files] [--verbose]

Examples:
    uv run package_skill.py .claude/skills/my-skill
    uv run package_skill.py .claude/skills/my-skill ./dist
    uv run package_skill.py .claude/skills/my-skill ./dist --include-test-files
"""

import sys
import json
import zipfile
from pathlib import Path
from datetime import datetime
from quick_validate import validate_skill


def gather_evaluation_summary(skill_path: Path) -> dict | None:
    """
    Gather evaluation summary from skill's evaluations directory.

    Returns:
        Summary dict with test results, or None if no evaluations found
    """
    eval_dir = skill_path / 'evaluations'
    if not eval_dir.exists():
        return None

    summary = {
        'has_evaluations': True,
        'test_cases_count': 0,
        'baseline_recorded': False,
        'latest_results': None,
        'target_models': [],
    }

    # Check for test cases
    test_cases_file = eval_dir / 'test-cases.json'
    if test_cases_file.exists():
        try:
            test_cases = json.loads(test_cases_file.read_text())
            summary['test_cases_count'] = len(test_cases.get('test_cases', []))
            summary['target_models'] = test_cases.get('target_models', [])
        except json.JSONDecodeError:
            pass

    # Check for baseline results
    baseline_file = eval_dir / 'baseline-results.json'
    if baseline_file.exists():
        try:
            baseline = json.loads(baseline_file.read_text())
            # Check if it's been filled out (not just template)
            if baseline.get('baseline_date', '').startswith('[TODO'):
                summary['baseline_recorded'] = False
            else:
                summary['baseline_recorded'] = True
        except json.JSONDecodeError:
            pass

    # Check for latest evaluation results
    results_file = eval_dir / 'results.json'
    if results_file.exists():
        try:
            results = json.loads(results_file.read_text())
            summary['latest_results'] = {
                'date': results.get('date', 'unknown'),
                'passed': results.get('passed', 0),
                'failed': results.get('failed', 0),
                'total': results.get('total', 0),
            }
        except json.JSONDecodeError:
            pass

    return summary


def create_package_manifest(skill_path: Path, validation_result, eval_summary: dict | None) -> dict:
    """
    Create a package manifest with metadata, validation, and evaluation info.

    Returns:
        Manifest dictionary
    """
    manifest = {
        'package_version': '1.0',
        'packaged_at': datetime.now().isoformat(),
        'skill_name': skill_path.name,
        'validation': {
            'valid': validation_result.valid,
            'errors': validation_result.errors,
            'warnings': validation_result.warnings,
            'metrics': validation_result.metrics,
        },
        'evaluations': eval_summary,
    }

    return manifest


def package_skill(
    skill_path: str | Path,
    output_dir: str | Path | None = None,
    include_test_files: bool = False,
    verbose: bool = False
) -> Path | None:
    """
    Package a skill folder into a .skill file.

    Args:
        skill_path: Path to the skill folder
        output_dir: Optional output directory for the .skill file
        include_test_files: Whether to include evaluations/test-files/ in package
        verbose: Print detailed progress

    Returns:
        Path to the created .skill file, or None if error
    """
    skill_path = Path(skill_path).resolve()

    # Validate skill folder exists
    if not skill_path.exists():
        print(f"Error: Skill folder not found: {skill_path}")
        return None

    if not skill_path.is_dir():
        print(f"Error: Path is not a directory: {skill_path}")
        return None

    # Validate SKILL.md exists
    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        print(f"Error: SKILL.md not found in {skill_path}")
        return None

    # Run extended validation
    print("Validating skill...")
    validation_result = validate_skill(skill_path, verbose=verbose)

    if not validation_result.valid:
        print("Validation failed:")
        for error in validation_result.errors:
            print(f"  [ERROR] {error}")
        print("\nPlease fix validation errors before packaging.")
        return None

    print("Validation passed")

    if validation_result.warnings:
        print(f"\nWarnings ({len(validation_result.warnings)}):")
        for warning in validation_result.warnings:
            print(f"  [WARN] {warning}")
        print()

    # Gather evaluation summary
    eval_summary = gather_evaluation_summary(skill_path)
    if eval_summary and verbose:
        print(f"Evaluations found: {eval_summary['test_cases_count']} test cases")
        if eval_summary['latest_results']:
            r = eval_summary['latest_results']
            print(f"  Latest results: {r['passed']}/{r['total']} passed")

    # Determine output location
    skill_name = skill_path.name
    if output_dir:
        output_path = Path(output_dir).resolve()
        output_path.mkdir(parents=True, exist_ok=True)
    else:
        output_path = Path.cwd()

    skill_filename = output_path / f"{skill_name}.skill"

    # Create package manifest
    manifest = create_package_manifest(skill_path, validation_result, eval_summary)

    # Directories/patterns to exclude
    exclude_patterns = [
        '__pycache__',
        '.git',
        '.DS_Store',
        '*.pyc',
        '.gitkeep',
    ]

    if not include_test_files:
        exclude_patterns.append('evaluations/test-files')

    def should_exclude(file_path: Path, base_path: Path) -> bool:
        """Check if a file should be excluded from package."""
        rel_path = str(file_path.relative_to(base_path))

        for pattern in exclude_patterns:
            if pattern.startswith('*'):
                # Suffix match
                if rel_path.endswith(pattern[1:]):
                    return True
            elif '/' in pattern:
                # Path prefix match
                if rel_path.startswith(pattern):
                    return True
            else:
                # Name match anywhere in path
                if pattern in rel_path.split('/'):
                    return True

        return False

    # Create the .skill file (zip format)
    try:
        print(f"\nCreating package: {skill_filename}")
        with zipfile.ZipFile(skill_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
            # Add manifest
            manifest_content = json.dumps(manifest, indent=2)
            zipf.writestr(f"{skill_name}/MANIFEST.json", manifest_content)
            if verbose:
                print(f"  Added: {skill_name}/MANIFEST.json")

            # Walk through the skill directory
            file_count = 0
            for file_path in skill_path.rglob('*'):
                if file_path.is_file():
                    if should_exclude(file_path, skill_path):
                        if verbose:
                            print(f"  Skipped: {file_path.relative_to(skill_path)}")
                        continue

                    # Calculate the relative path within the zip
                    arcname = file_path.relative_to(skill_path.parent)
                    zipf.write(file_path, arcname)
                    file_count += 1
                    if verbose:
                        print(f"  Added: {arcname}")

        print(f"\nSuccessfully packaged {file_count} files to: {skill_filename}")

        # Print summary
        if eval_summary:
            print(f"\nEvaluation Summary:")
            print(f"  Test cases: {eval_summary['test_cases_count']}")
            print(f"  Baseline recorded: {'Yes' if eval_summary['baseline_recorded'] else 'No'}")
            if eval_summary['latest_results']:
                r = eval_summary['latest_results']
                print(f"  Latest results: {r['passed']}/{r['total']} passed ({r['date']})")

        return skill_filename

    except Exception as e:
        print(f"Error creating .skill file: {e}")
        return None


def main():
    args = sys.argv[1:]

    if not args or args[0] in ['-h', '--help']:
        print("Usage: uv run package_skill.py <skill_directory> [output_directory] [options]")
        print("\nPackages a skill folder into a distributable .skill file.")
        print("Runs validation before packaging and includes evaluation summary.")
        print("\nOptions:")
        print("  --include-test-files  Include evaluations/test-files/ in package")
        print("  --verbose             Print detailed progress")
        print("\nExamples:")
        print("  uv run package_skill.py .claude/skills/my-skill")
        print("  uv run package_skill.py .claude/skills/my-skill ./dist")
        print("  uv run package_skill.py .claude/skills/my-skill ./dist --verbose")
        sys.exit(0)

    skill_path = args[0]
    output_dir = None
    include_test_files = '--include-test-files' in args
    verbose = '--verbose' in args

    # Find output_dir (first arg that's not a flag)
    for arg in args[1:]:
        if not arg.startswith('--'):
            output_dir = arg
            break

    print(f"Packaging skill: {skill_path}")
    if output_dir:
        print(f"Output directory: {output_dir}")
    print()

    result = package_skill(skill_path, output_dir, include_test_files, verbose)
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
