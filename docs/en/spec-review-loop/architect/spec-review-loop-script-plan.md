# Spec Review Loop Script Plan

## Goal
Implement a bash orchestrator that runs the 01/02/03 spec-review loop end‑to‑end, extracts inline `!` script snippets into bash, enforces outer/inner guardrails, and drives Codex/Claude via CLI with structured logging.

## Files to Add
- `docs/en/spec-review-loop/scripts/spec-review-loop.sh`

## CLI Interface
- `--outer N` (default `5`): max outer iterations.
- `--inner N` (default `10`): max inner iterations per outer loop.
- `--specs-dir PATH` (default `./specs`).
- `--guide-path PATH` (default `./references/SPEC_GENERATION_GUIDE.md`).
- `--prompt-dir PATH` (default `./spec-review-loop-prompts`).
- `--logs-dir PATH` (optional; default `./logs/spec-review-loop-<timestamp>`).
- `-h|--help`: usage.

## Commands
### Codex
Use:
```
codex exec --profile claude -C "$PROJECT_ROOT" "$PROMPT"
```

### Claude
Use:
```
claude --permission-mode acceptEdits --verbose --print --output-format stream-json "$PROMPT"
```
Stream text to console using `jq`:
- `stream_text='select(.type == "assistant").message.content[]? | select(.type == "text").text // empty | gsub("\n"; "\r\n") | . + "\r\n\n"'`
- `final_result='select(.type == "result").result // empty'`

## Guardrails & Preflight
- Validate `--outer`, `--inner` are positive integers.
- Validate `--specs-dir` exists.
- Validate `--guide-path` exists.
- Validate `--prompt-dir` exists.
- Validate required commands: `codex`, `claude`, `jq`, `perl`.
- Trap `SIGINT`/`SIGTERM` → clean exit with context.

## Helpers (exact names + behavior)
- `usage()`: prints usage and exits.
- `die(msg)`: prints error and exits 1.
- `ensure_cmd(cmd)`: checks command existence.
- `resolve_root()`: sets `SCRIPT_DIR` and resolves `PROJECT_ROOT` via git root if available, else falls back to script directory.
- `issues_dir()` → `"$SPECS_DIR/issues"`.
- `latest_issue_file()`:
  - list `"$ISSUES_DIR"/*.md`, exclude `*-feedback.md` and `*-summary.md`, pick newest by `sort -rV`.
  - returns empty string if none.
- `next_issue_file()`:
  - if latest exists, parse `vN`, increment; else `v1`.
  - returns `"$ISSUES_DIR/$(date +%Y-%m-%d)-v<N>.md"`.
- `summary_file_for(issue_file)` → `${issue_file%.md}-summary.md`
- `feedback_file_for(issue_file)` → `${issue_file%.md}-feedback.md`
- `check_control_signal(file_or_text)`:
  - parse `<promise>...</promise>` tags.
  - returns `COMPLETE`, `ALL_RESOLVED`, `ISSUES_REMAINING`, or empty if not found.
- `run_codex(prompt, raw_out)`:
  - logs prompt + executes codex command into `raw_out`.
- `run_claude(prompt)`:
  - runs Claude streaming JSON to console with `jq`.

## Prompt Construction
### 01-find-issues
- Use `docs/en/spec-review-loop/01-find-issues.md`.
- Replace `{Output file}` with `OUTPUT_FILE`.

### 02-fix-issues (AFK block only)
- Use AFK section from `docs/en/spec-review-loop/02-fix-issues.md`.
- Replace inline `!` with:
  - `ISSUES_FILE = latest_issue_file()`
  - `SUMMARY_FILE = summary_file_for(ISSUES_FILE)`
  - `FEEDBACK_FILE = feedback_file_for(ISSUES_FILE)`

### 03-confirm-fix
- Use `docs/en/spec-review-loop/03-confirm-fix.md`.
- Replace inline `!` with:
  - `ISSUES_FILE = latest_issue_file()`
  - `FEEDBACK_FILE = feedback_file_for(ISSUES_FILE)`
  - `OUTPUT_FILE = next_issue_file()`

## Main Loop Logic
```
for outer in 1..MAX_OUTER:
    run_find_issues()
    if COMPLETE: exit 0

    for inner in 1..MAX_INNER:
        run_fix_issues()
        run_confirm_fix()
        if ALL_RESOLVED: break
        # else ISSUES_REMAINING: continue inner

    if inner == MAX_INNER: warn "inner limit reached" and exit non-zero

if outer == MAX_OUTER: warn "outer limit reached" and exit non-zero
```

### run_find_issues()
- `OUTPUT_FILE = next_issue_file()`
- Build prompt with substituted output path.
- run Codex; log raw output.
- if `<promise>COMPLETE</promise>` → exit without creating output file.
- otherwise write raw output to `OUTPUT_FILE`.

### run_fix_issues()
- `ISSUES_FILE = latest_issue_file()`; if empty → die.
- Build AFK prompt with computed files.
- run Claude with AFK prompt (streaming JSON and jq filtering)
- ensure `SUMMARY_FILE` exists; if missing → die.

### run_confirm_fix()
- `ISSUES_FILE = latest_issue_file()`; if empty → die.
- `OUTPUT_FILE = next_issue_file()`
- run Codex; write output to `OUTPUT_FILE`.
- parse promise tag:
  - `ALL_RESOLVED` → exit inner loop
  - `ISSUES_REMAINING` → continue inner
  - missing → error (die)

## Logging
Directory: `./logs/spec-review-loop-<timestamp>/`

- `01-outer-<n>-prompt.txt`
- `01-outer-<n>-raw.txt`
- `01-outer-<n>-output-path.txt`
- `02-inner-<n>-prompt.txt`
- `03-inner-<n>-prompt.txt`
- `03-inner-<n>-raw.txt`
- `03-inner-<n>-output-path.txt`

Full raw Codex output is captured (no truncation).

## Edge Cases
- No issue files exist: `next_issue_file()` yields `v1`.
- Feedback file may not exist; still pass path to prompt.
- Missing promise tag in confirm step → fail fast.

## Assumptions
- `claude` supports `--verbose --print --output-format stream-json` plus `--permission-mode acceptEdits`.
- `jq` is available for streaming filters.

## Verification
- Run with `--outer 1 --inner 1`.
- Confirm issue files, summaries, and logs are created as expected.
- Confirm promise tags drive loop transitions.
