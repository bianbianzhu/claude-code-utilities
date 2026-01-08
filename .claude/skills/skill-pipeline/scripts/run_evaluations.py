#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""
Skill Pipeline Evaluation Runner - Automated skill testing and validation

Runs test cases against a skill and generates detailed evaluation reports.
Supports multiple Claude models and compares results against baseline.

Usage:
    uv run run_evaluations.py <skill_directory> [options]

Options:
    --model MODEL       Model to test (haiku, sonnet, opus). Default: sonnet
    --test TEST_ID      Run specific test by ID. Default: run all
    --baseline          Record baseline (without skill)
    --output DIR        Output directory for results
    --verbose           Show detailed output
    --dry-run           Show what would be run without executing

Examples:
    uv run run_evaluations.py .claude/skills/my-skill
    uv run run_evaluations.py .claude/skills/my-skill --model haiku
    uv run run_evaluations.py .claude/skills/my-skill --test my-skill-001
    uv run run_evaluations.py .claude/skills/my-skill --baseline
"""

import sys
import json
import subprocess
import time
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass, field, asdict


# Model name mapping for Claude CLI
MODEL_MAP = {
    'haiku': 'haiku',
    'sonnet': 'sonnet',
    'opus': 'opus',
}


@dataclass
class TestResult:
    """Result of a single test case execution."""
    test_id: str
    model: str
    query: str
    passed: bool
    criteria_results: dict = field(default_factory=dict)
    output: str = ""
    error: str = ""
    execution_time_seconds: float = 0.0
    token_estimate: int = 0  # Rough estimate based on output length


@dataclass
class EvaluationReport:
    """Complete evaluation report for a skill."""
    skill_name: str
    date: str
    model: str
    total: int = 0
    passed: int = 0
    failed: int = 0
    test_results: list = field(default_factory=list)
    metrics: dict = field(default_factory=dict)
    baseline_comparison: dict | None = None


def load_test_cases(skill_path: Path) -> dict | None:
    """Load test cases from skill's evaluations directory."""
    test_file = skill_path / 'evaluations' / 'test-cases.json'

    if not test_file.exists():
        print(f"Error: Test cases not found: {test_file}")
        return None

    try:
        return json.loads(test_file.read_text())
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in test cases: {e}")
        return None


def load_baseline(skill_path: Path) -> dict | None:
    """Load baseline results if they exist."""
    baseline_file = skill_path / 'evaluations' / 'baseline-results.json'

    if not baseline_file.exists():
        return None

    try:
        baseline = json.loads(baseline_file.read_text())
        # Check if it's been filled out
        if baseline.get('baseline_date', '').startswith('[TODO'):
            return None
        return baseline
    except json.JSONDecodeError:
        return None


def estimate_tokens(text: str) -> int:
    """Rough estimate of token count (1 token ~ 4 characters)."""
    return len(text) // 4


def run_claude_query(
    query: str,
    skill_path: Path | None = None,
    model: str = 'sonnet',
    timeout: int = 120,
    verbose: bool = False
) -> tuple[str, float, str | None]:
    """
    Run a query through Claude CLI.

    Args:
        query: The query to send
        skill_path: Path to skill (None for baseline without skill)
        model: Model to use
        timeout: Timeout in seconds

    Returns:
        Tuple of (output, execution_time, error_message)
    """
    cmd = ['claude', '--model', MODEL_MAP.get(model, 'sonnet')]

    # Add skill if provided
    if skill_path:
        cmd.extend(['--skill', str(skill_path)])

    # Add query via stdin
    cmd.extend(['--print', '-p', query])

    if verbose:
        print(f"  Running: {' '.join(cmd[:4])}...")

    start_time = time.time()

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=Path.cwd()
        )
        execution_time = time.time() - start_time

        if result.returncode != 0:
            return "", execution_time, result.stderr or "Command failed"

        return result.stdout, execution_time, None

    except subprocess.TimeoutExpired:
        return "", timeout, f"Timeout after {timeout}s"
    except FileNotFoundError:
        return "", 0, "Claude CLI not found. Please install claude-code."
    except Exception as e:
        return "", time.time() - start_time, str(e)


def evaluate_criteria(output: str, test_case: dict) -> dict:
    """
    Evaluate output against test case criteria.

    Returns dict with:
        - must_pass: dict of criterion -> passed (bool)
        - should_pass: dict of criterion -> passed (bool)
        - all_must_passed: bool
    """
    results = {
        'must_pass': {},
        'should_pass': {},
        'all_must_passed': True,
    }

    success_criteria = test_case.get('success_criteria', {})
    output_lower = output.lower()

    # Check must_pass criteria
    for criterion in success_criteria.get('must_pass', []):
        if criterion.startswith('[TODO'):
            continue  # Skip template placeholders

        # Simple keyword/phrase matching
        # In a real implementation, this could use LLM-based evaluation
        passed = criterion.lower() in output_lower or _check_criterion(criterion, output)
        results['must_pass'][criterion] = passed
        if not passed:
            results['all_must_passed'] = False

    # Check should_pass criteria
    for criterion in success_criteria.get('should_pass', []):
        if criterion.startswith('[TODO'):
            continue

        passed = criterion.lower() in output_lower or _check_criterion(criterion, output)
        results['should_pass'][criterion] = passed

    return results


def _check_criterion(criterion: str, output: str) -> bool:
    """
    Check if a criterion is satisfied by the output.

    This is a simple implementation. In production, you might want to:
    - Use an LLM to evaluate
    - Support regex patterns
    - Support structured criteria
    """
    # Handle common criterion patterns
    criterion_lower = criterion.lower()

    # Pattern: "uses X" - check if X is mentioned
    if criterion_lower.startswith('uses '):
        target = criterion_lower[5:]
        return target in output.lower()

    # Pattern: "creates X" or "generates X"
    for prefix in ['creates ', 'generates ', 'outputs ']:
        if criterion_lower.startswith(prefix):
            target = criterion_lower[len(prefix):]
            return target in output.lower()

    # Pattern: "handles X"
    if criterion_lower.startswith('handles '):
        # Can't really verify handling without more context
        return True  # Optimistic default

    # Default: substring match
    return criterion.lower() in output.lower()


def run_single_test(
    test_case: dict,
    skill_path: Path | None,
    model: str,
    verbose: bool = False
) -> TestResult:
    """Run a single test case and return the result."""
    test_id = test_case.get('test_id', 'unknown')
    query = test_case.get('query', '')

    if verbose:
        print(f"\n  Test: {test_id}")
        print(f"  Query: {query[:50]}...")

    # Run the query
    output, exec_time, error = run_claude_query(
        query=query,
        skill_path=skill_path,
        model=model,
        verbose=verbose
    )

    # Evaluate criteria
    if error:
        criteria_results = {'error': error}
        passed = False
    else:
        criteria_results = evaluate_criteria(output, test_case)
        passed = criteria_results['all_must_passed']

    result = TestResult(
        test_id=test_id,
        model=model,
        query=query,
        passed=passed,
        criteria_results=criteria_results,
        output=output[:1000] if output else "",  # Truncate for storage
        error=error or "",
        execution_time_seconds=round(exec_time, 2),
        token_estimate=estimate_tokens(output)
    )

    if verbose:
        status = "PASS" if passed else "FAIL"
        print(f"  Result: {status} ({exec_time:.1f}s)")

    return result


def run_evaluations(
    skill_path: Path,
    model: str = 'sonnet',
    test_id: str | None = None,
    baseline_mode: bool = False,
    verbose: bool = False,
    dry_run: bool = False
) -> EvaluationReport | None:
    """
    Run all evaluations for a skill.

    Args:
        skill_path: Path to the skill directory
        model: Model to use for testing
        test_id: Specific test to run (None = all)
        baseline_mode: If True, run without skill (for baseline)
        verbose: Print detailed output
        dry_run: Show what would run without executing

    Returns:
        EvaluationReport or None if error
    """
    # Load test cases
    test_data = load_test_cases(skill_path)
    if not test_data:
        return None

    test_cases = test_data.get('test_cases', [])
    if not test_cases:
        print("Error: No test cases found")
        return None

    # Filter to specific test if requested
    if test_id:
        test_cases = [t for t in test_cases if t.get('test_id') == test_id]
        if not test_cases:
            print(f"Error: Test case not found: {test_id}")
            return None

    # Check if model is in target models
    target_models = test_data.get('target_models', ['sonnet'])
    if model not in target_models:
        print(f"Warning: Model '{model}' not in target_models {target_models}")

    print(f"Running {len(test_cases)} test(s) with model: {model}")
    if baseline_mode:
        print("Mode: BASELINE (without skill)")
    else:
        print(f"Skill: {skill_path.name}")

    if dry_run:
        print("\n[DRY RUN] Would run:")
        for tc in test_cases:
            print(f"  - {tc.get('test_id')}: {tc.get('query', '')[:50]}...")
        return None

    # Run tests
    report = EvaluationReport(
        skill_name=skill_path.name,
        date=datetime.now().isoformat(),
        model=model,
        total=len(test_cases),
    )

    for test_case in test_cases:
        result = run_single_test(
            test_case=test_case,
            skill_path=None if baseline_mode else skill_path,
            model=model,
            verbose=verbose
        )
        report.test_results.append(asdict(result))

        if result.passed:
            report.passed += 1
        else:
            report.failed += 1

    # Calculate metrics
    report.metrics = {
        'success_rate': round(report.passed / report.total * 100, 1) if report.total else 0,
        'avg_execution_time': round(
            sum(r['execution_time_seconds'] for r in report.test_results) / len(report.test_results), 2
        ) if report.test_results else 0,
        'total_token_estimate': sum(r['token_estimate'] for r in report.test_results),
    }

    # Compare to baseline if available and not in baseline mode
    if not baseline_mode:
        baseline = load_baseline(skill_path)
        if baseline:
            baseline_model = baseline.get('model_results', {}).get(model, {})
            baseline_metrics = baseline_model.get('metrics', {})

            if baseline_metrics:
                report.baseline_comparison = {
                    'baseline_success_rate': baseline_metrics.get('success_rate', 0),
                    'improvement': report.metrics['success_rate'] - baseline_metrics.get('success_rate', 0),
                }

    return report


def save_results(report: EvaluationReport, skill_path: Path, output_dir: Path | None = None):
    """Save evaluation results to file."""
    if output_dir:
        results_dir = output_dir
    else:
        results_dir = skill_path / 'evaluations'

    results_dir.mkdir(parents=True, exist_ok=True)
    results_file = results_dir / 'results.json'

    # Convert report to dict
    report_dict = {
        'skill_name': report.skill_name,
        'date': report.date,
        'model': report.model,
        'total': report.total,
        'passed': report.passed,
        'failed': report.failed,
        'metrics': report.metrics,
        'baseline_comparison': report.baseline_comparison,
        'test_results': report.test_results,
    }

    results_file.write_text(json.dumps(report_dict, indent=2))
    print(f"\nResults saved to: {results_file}")


def save_baseline(report: EvaluationReport, skill_path: Path):
    """Save results as baseline."""
    baseline_file = skill_path / 'evaluations' / 'baseline-results.json'

    baseline = {
        'skill': skill_path.name,
        'baseline_date': report.date,
        'model_results': {
            report.model: {
                'test_results': report.test_results,
                'metrics': {
                    'success_rate': report.metrics['success_rate'],
                    'avg_tokens': report.metrics['total_token_estimate'] // report.total if report.total else 0,
                    'avg_time_seconds': report.metrics['avg_execution_time'],
                }
            }
        },
        'notes': 'Baseline recorded without skill'
    }

    baseline_file.write_text(json.dumps(baseline, indent=2))
    print(f"\nBaseline saved to: {baseline_file}")


def print_report(report: EvaluationReport):
    """Print human-readable report."""
    print("\n" + "=" * 50)
    print(f"Evaluation Report: {report.skill_name}")
    print("=" * 50)
    print(f"Date: {report.date}")
    print(f"Model: {report.model}")
    print(f"\nResults: {report.passed}/{report.total} passed ({report.metrics['success_rate']}%)")
    print(f"Avg execution time: {report.metrics['avg_execution_time']}s")
    print(f"Total tokens (est): {report.metrics['total_token_estimate']}")

    if report.baseline_comparison:
        bc = report.baseline_comparison
        print(f"\nBaseline comparison:")
        print(f"  Baseline success rate: {bc['baseline_success_rate']}%")
        print(f"  Improvement: {bc['improvement']:+.1f}%")

    if report.failed > 0:
        print(f"\nFailed tests ({report.failed}):")
        for result in report.test_results:
            if not result['passed']:
                print(f"  - {result['test_id']}")
                if result['error']:
                    print(f"    Error: {result['error']}")
                else:
                    failed_criteria = [
                        c for c, p in result['criteria_results'].get('must_pass', {}).items()
                        if not p
                    ]
                    if failed_criteria:
                        print(f"    Failed criteria: {', '.join(failed_criteria)}")

    print("=" * 50)


def main():
    args = sys.argv[1:]

    if not args or args[0] in ['-h', '--help']:
        print(__doc__)
        sys.exit(0)

    skill_path = Path(args[0]).resolve()

    # Parse options
    model = 'sonnet'
    test_id = None
    baseline_mode = False
    output_dir = None
    verbose = '--verbose' in args
    dry_run = '--dry-run' in args

    for i, arg in enumerate(args[1:], 1):
        if arg == '--model' and i + 1 < len(args):
            model = args[i + 1]
        elif arg == '--test' and i + 1 < len(args):
            test_id = args[i + 1]
        elif arg == '--baseline':
            baseline_mode = True
        elif arg == '--output' and i + 1 < len(args):
            output_dir = Path(args[i + 1])

    # Validate skill path
    if not skill_path.exists():
        print(f"Error: Skill directory not found: {skill_path}")
        sys.exit(1)

    # Run evaluations
    report = run_evaluations(
        skill_path=skill_path,
        model=model,
        test_id=test_id,
        baseline_mode=baseline_mode,
        verbose=verbose,
        dry_run=dry_run
    )

    if not report:
        sys.exit(1)

    # Print report
    print_report(report)

    # Save results
    if baseline_mode:
        save_baseline(report, skill_path)
    else:
        save_results(report, skill_path, output_dir)

    # Exit with appropriate code
    sys.exit(0 if report.failed == 0 else 1)


if __name__ == "__main__":
    main()
