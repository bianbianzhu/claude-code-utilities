#!/bin/bash
set -euo pipefail

# Required files/directories to run this script (defaults shown):
# - $SPECS_DIR/ (default: ./specs; will create ./specs/issues/ if missing)
# - $GUIDE_PATH (default: ./references/SPEC_GENERATION_GUIDE.md)
# - $PROMPT_DIR/01-find-issues.md (default: ./spec-review-loop-prompts/01-find-issues.md)
# - $PROMPT_DIR/02-fix-issues.md (default: ./spec-review-loop-prompts/02-fix-issues.md)
# - $PROMPT_DIR/03-confirm-fix.md (default: ./spec-review-loop-prompts/03-confirm-fix.md)

SCRIPT_DIR=""
PROJECT_ROOT=""
SPECS_DIR="./specs"
GUIDE_PATH="./references/SPEC_GENERATION_GUIDE.md"
PROMPT_DIR="./spec-review-loop-prompts"
LOGS_DIR=""
OUTER_MAX=5
INNER_MAX=10
CURRENT_OUTER=""
CURRENT_INNER=""
INNER_COUNTER=0

usage() {
  cat <<USAGE
Usage: $0 [--outer N] [--inner N] [--specs-dir PATH] [--guide-path PATH] [--prompt-dir PATH] [--logs-dir PATH]

Runs the spec review loop:
  01-find-issues -> 02-fix-issues -> 03-confirm-fix

Options:
  --outer N       Max outer iterations (default: 5)
  --inner N       Max inner iterations (default: 10)
  --specs-dir     Specs directory (default: ./specs)
  --guide-path    SPEC_GENERATION_GUIDE.md path (default: ./references/SPEC_GENERATION_GUIDE.md)
  --prompt-dir    Prompt directory (default: ./spec-review-loop-prompts)
  --logs-dir      Logs directory (default: ./logs/spec-review-loop-<timestamp>)
  -h, --help      Show this help
USAGE
  exit 1
}

die() {
  echo "Error: $*" >&2
  exit 1
}

warn() {
  echo "Warning: $*" >&2
}

ensure_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

validate_positive_int() {
  local value="$1"
  local name="$2"
  [[ "$value" =~ ^[0-9]+$ ]] || die "$name must be a positive integer"
  [ "$value" -ge 1 ] || die "$name must be a positive integer"
}

resolve_root() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if command -v git >/dev/null 2>&1; then
    if git -C "$SCRIPT_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
      PROJECT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
      return
    fi
  fi
  PROJECT_ROOT="$SCRIPT_DIR"
}

normalize_path() {
  local path="$1"
  if [[ "$path" = /* ]]; then
    echo "$path"
  else
    echo "$PROJECT_ROOT/$path"
  fi
}

issues_dir() {
  echo "$SPECS_DIR/issues"
}

latest_issue_file() {
  local dir
  dir="$(issues_dir)"
  shopt -s nullglob
  local files=("$dir"/*.md)
  shopt -u nullglob

  if [ ${#files[@]} -eq 0 ]; then
    echo ""
    return
  fi

  local latest
  latest=$(printf "%s\n" "${files[@]}" | grep -vE '(-feedback|-summary)\.md$' | sort -rV | head -1 || true)
  echo "$latest"
}

next_issue_file() {
  local latest
  latest="$(latest_issue_file)"
  local v="0"
  if [ -n "$latest" ]; then
    v=$(echo "$latest" | grep -oE 'v[0-9]+' | tail -1 | tr -d 'v' || echo "0")
  fi
  echo "$(issues_dir)/$(date +%Y-%m-%d)-v$((v + 1)).md"
}

summary_file_for() {
  local file="$1"
  echo "${file%.md}-summary.md"
}

feedback_file_for() {
  local file="$1"
  echo "${file%.md}-feedback.md"
}

check_control_signal() {
  local input="$1"
  if [ -f "$input" ]; then
    if grep -q "<promise>COMPLETE</promise>" "$input"; then
      echo "COMPLETE"
      return
    fi
    if grep -q "<promise>ALL_RESOLVED</promise>" "$input"; then
      echo "ALL_RESOLVED"
      return
    fi
    if grep -q "<promise>ISSUES_REMAINING</promise>" "$input"; then
      echo "ISSUES_REMAINING"
      return
    fi
    echo ""
    return
  fi

  if echo "$input" | grep -q "<promise>COMPLETE</promise>"; then
    echo "COMPLETE"
    return
  fi
  if echo "$input" | grep -q "<promise>ALL_RESOLVED</promise>"; then
    echo "ALL_RESOLVED"
    return
  fi
  if echo "$input" | grep -q "<promise>ISSUES_REMAINING</promise>"; then
    echo "ISSUES_REMAINING"
    return
  fi

  echo ""
}

read_prompt() {
  local file="$1"
  cat "$file"
}

replace_placeholder() {
  local prompt="$1"
  local placeholder="$2"
  local value="$3"
  prompt="${prompt//$placeholder/$value}"
  printf "%s" "$prompt"
}

normalize_prompt_paths() {
  local prompt="$1"
  prompt="${prompt//.\/specs/$SPECS_DIR}"
  prompt="${prompt//.\/references\/SPEC_GENERATION_GUIDE.md/$GUIDE_PATH}"
  printf "%s" "$prompt"
}

run_codex() {
  local prompt="$1"
  local raw_out="$2"
  codex exec --profile claude -C "$PROJECT_ROOT" "$prompt" > "$raw_out" 2>&1
}

run_claude() {
  local prompt="$1"
  local raw_json="$2"

  local stream_text='select(.type == "assistant").message.content[]? | select(.type == "text").text // empty | gsub("\n"; "\r\n") | . + "\r\n\n"'

  claude --permission-mode acceptEdits --verbose --print --output-format stream-json "$prompt" \
    | awk '/^{/ { print; fflush(); }' \
    | tee "$raw_json" \
    | jq --unbuffered -rj "$stream_text"
}

run_find_issues() {
  local prompt_file="$1"
  local output_file
  output_file="$(next_issue_file)"

  local prompt
  prompt="$(read_prompt "$prompt_file")"
  [ -n "$prompt" ] || die "Failed to load prompt from $prompt_file"

  prompt="$(normalize_prompt_paths "$prompt")"
  prompt="$(replace_placeholder "$prompt" "{Output file}" "$output_file")"

  local log_prompt="$LOGS_DIR/01-outer-${CURRENT_OUTER}-prompt.txt"
  local log_raw="$LOGS_DIR/01-outer-${CURRENT_OUTER}-raw.txt"
  local log_out_path="$LOGS_DIR/01-outer-${CURRENT_OUTER}-output-path.txt"

  printf "%s" "$prompt" > "$log_prompt"
  run_codex "$prompt" "$log_raw"

  local signal
  signal="$(check_control_signal "$log_raw")"
  if [ "$signal" = "COMPLETE" ]; then
    return 0
  fi

  cat "$log_raw" > "$output_file"
  [ -s "$output_file" ] || die "Output file not created: $output_file"
  echo "$output_file" > "$log_out_path"

  return 1
}

run_fix_issues() {
  local prompt_file="$1"
  local issues_file
  issues_file="$(latest_issue_file)"
  [ -n "$issues_file" ] || die "No issues file found"

  local summary_file
  summary_file="$(summary_file_for "$issues_file")"
  local feedback_file
  feedback_file="$(feedback_file_for "$issues_file")"

  local prompt
  prompt="$(read_prompt "$prompt_file")"
  [ -n "$prompt" ] || die "Failed to load prompt from $prompt_file"

  prompt="$(normalize_prompt_paths "$prompt")"
  prompt="$(replace_placeholder "$prompt" "{Issues file}" "$issues_file")"
  prompt="$(replace_placeholder "$prompt" "{Summary file}" "$summary_file")"
  prompt="$(replace_placeholder "$prompt" "{Feedback file}" "$feedback_file")"

  local log_prompt="$LOGS_DIR/02-inner-${INNER_COUNTER}-prompt.txt"
  local log_raw="$LOGS_DIR/02-inner-${INNER_COUNTER}-raw.json"

  printf "%s" "$prompt" > "$log_prompt"
  run_claude "$prompt" "$log_raw"

  [ -s "$summary_file" ] || die "Summary file not created: $summary_file"
}

run_confirm_fix() {
  local prompt_file="$1"
  local issues_file
  issues_file="$(latest_issue_file)"
  [ -n "$issues_file" ] || die "No issues file found"

  local output_file
  output_file="$(next_issue_file)"
  local feedback_file
  feedback_file="$(feedback_file_for "$issues_file")"

  local prompt
  prompt="$(read_prompt "$prompt_file")"
  [ -n "$prompt" ] || die "Failed to load prompt from $prompt_file"

  prompt="$(normalize_prompt_paths "$prompt")"
  prompt="$(replace_placeholder "$prompt" "{Issues file}" "$issues_file")"
  prompt="$(replace_placeholder "$prompt" "{Feedback file}" "$feedback_file")"
  prompt="$(replace_placeholder "$prompt" "{Output file}" "$output_file")"

  local log_prompt="$LOGS_DIR/03-inner-${INNER_COUNTER}-prompt.txt"
  local log_raw="$LOGS_DIR/03-inner-${INNER_COUNTER}-raw.txt"
  local log_out_path="$LOGS_DIR/03-inner-${INNER_COUNTER}-output-path.txt"

  printf "%s" "$prompt" > "$log_prompt"
  run_codex "$prompt" "$log_raw"

  cat "$log_raw" > "$output_file"
  [ -s "$output_file" ] || die "Output file not created: $output_file"
  echo "$output_file" > "$log_out_path"

  local signal
  signal="$(check_control_signal "$log_raw")"
  if [ -z "$signal" ]; then
    die "Missing promise tag in confirmation output"
  fi
  echo "$signal"
}

on_interrupt() {
  echo ""
  echo "Interrupted."
  [ -n "$CURRENT_OUTER" ] && echo "Outer iteration: $CURRENT_OUTER"
  [ -n "$CURRENT_INNER" ] && echo "Inner iteration: $CURRENT_INNER"
  [ -n "$LOGS_DIR" ] && echo "Logs directory: $LOGS_DIR"
  exit 130
}

trap on_interrupt INT TERM HUP

while [ $# -gt 0 ]; do
  case "$1" in
    --outer)
      OUTER_MAX="$2"
      shift 2
      ;;
    --inner)
      INNER_MAX="$2"
      shift 2
      ;;
    --specs-dir)
      SPECS_DIR="$2"
      shift 2
      ;;
    --guide-path)
      GUIDE_PATH="$2"
      shift 2
      ;;
    --prompt-dir)
      PROMPT_DIR="$2"
      shift 2
      ;;
    --logs-dir)
      LOGS_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

resolve_root

validate_positive_int "$OUTER_MAX" "--outer"
validate_positive_int "$INNER_MAX" "--inner"

SPECS_DIR="$(normalize_path "$SPECS_DIR")"
GUIDE_PATH="$(normalize_path "$GUIDE_PATH")"
PROMPT_DIR="$(normalize_path "$PROMPT_DIR")"

if [ -z "$LOGS_DIR" ]; then
  LOGS_DIR="$PROJECT_ROOT/logs/spec-review-loop-$(date +%Y%m%d-%H%M%S)"
else
  LOGS_DIR="$(normalize_path "$LOGS_DIR")"
fi

ensure_cmd codex
ensure_cmd claude
ensure_cmd jq

[ -d "$SPECS_DIR" ] || die "Specs directory not found: $SPECS_DIR"
[ -f "$GUIDE_PATH" ] || die "Guide file not found: $GUIDE_PATH"
[ -d "$PROMPT_DIR" ] || die "Prompt directory not found: $PROMPT_DIR"

mkdir -p "$LOGS_DIR"
mkdir -p "$(issues_dir)"

FIND_PROMPT_FILE="$PROMPT_DIR/01-find-issues.md"
FIX_PROMPT_FILE="$PROMPT_DIR/02-fix-issues.md"
CONFIRM_PROMPT_FILE="$PROMPT_DIR/03-confirm-fix.md"

[ -f "$FIND_PROMPT_FILE" ] || die "Missing prompt file: $FIND_PROMPT_FILE"
[ -f "$FIX_PROMPT_FILE" ] || die "Missing prompt file: $FIX_PROMPT_FILE"
[ -f "$CONFIRM_PROMPT_FILE" ] || die "Missing prompt file: $CONFIRM_PROMPT_FILE"

for ((outer=1; outer<=OUTER_MAX; outer++)); do
  CURRENT_OUTER="$outer"
  echo "=== Outer iteration $outer/$OUTER_MAX ==="

  if run_find_issues "$FIND_PROMPT_FILE"; then
    echo "Success: No issues found. Spec review complete."
    exit 0
  fi

  signal=""
  for ((inner=1; inner<=INNER_MAX; inner++)); do
    CURRENT_INNER="$inner"
    INNER_COUNTER=$((INNER_COUNTER + 1))
    echo "--- Inner iteration $inner/$INNER_MAX ---"

    run_fix_issues "$FIX_PROMPT_FILE"
    signal="$(run_confirm_fix "$CONFIRM_PROMPT_FILE")"

    if [ "$signal" = "ALL_RESOLVED" ]; then
      break
    fi
  done

  if [ "$inner" -ge "$INNER_MAX" ] && [ "$signal" != "ALL_RESOLVED" ]; then
    warn "Inner limit reached: $INNER_MAX"
    exit 1
  fi
done

warn "Outer limit reached: $OUTER_MAX"
exit 1
