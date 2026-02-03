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
  latest=$(printf "%s\n" "${files[@]}" | grep -vE '(-feedback|-summary|-reraised|human-approved-declines)\.md$' | sort -rV | head -1 || true)
  echo "$latest"
}

previous_issue_file() {
  local dir
  dir="$(issues_dir)"
  shopt -s nullglob
  local files=("$dir"/*.md)
  shopt -u nullglob

  if [ ${#files[@]} -lt 2 ]; then
    echo ""
    return
  fi

  local previous
  previous=$(printf "%s\n" "${files[@]}" | grep -vE '(-feedback|-summary|-reraised|human-approved-declines)\.md$' | sort -rV | sed -n '2p' || true)
  echo "$previous"
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

reraise_file_for() {
  local file="$1"
  echo "${file%.md}-reraised.md"
}

check_control_signal() {
  local input="$1"
  # Use ^...$ anchors to match standalone lines only (avoid prompt template text)
  if [ -f "$input" ]; then
    if grep -qE '^<promise>COMPLETE</promise>$' "$input"; then
      echo "COMPLETE"
      return
    fi
    if grep -qE '^<promise>ALL_RESOLVED</promise>$' "$input"; then
      echo "ALL_RESOLVED"
      return
    fi
    if grep -qE '^<promise>ISSUES_REMAINING</promise>$' "$input"; then
      echo "ISSUES_REMAINING"
      return
    fi
    echo ""
    return
  fi

  if echo "$input" | grep -qE '^<promise>COMPLETE</promise>$'; then
    echo "COMPLETE"
    return
  fi
  if echo "$input" | grep -qE '^<promise>ALL_RESOLVED</promise>$'; then
    echo "ALL_RESOLVED"
    return
  fi
  if echo "$input" | grep -qE '^<promise>ISSUES_REMAINING</promise>$'; then
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
    if [ -e "$output_file" ]; then
      warn "Output file created despite COMPLETE signal: $output_file"
    fi
    return 0
  fi

  [ -s "$output_file" ] || die "Output file not created by Codex: $output_file (see $log_raw)"
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

  [ -s "$output_file" ] || die "Output file not created by Codex: $output_file (see $log_raw)"
  echo "$output_file" > "$log_out_path"

  local signal
  # Allow human to override by editing the issue report with a promise tag.
  signal="$(check_control_signal "$output_file")"
  if [ -z "$signal" ]; then
    signal="$(check_control_signal "$log_raw")"
  fi
  if [ -z "$signal" ]; then
    die "Missing promise tag in confirmation output: $log_raw"
  fi
  echo "$signal"
}

run_reraise_detection() {
  local prev_report="$1"
  local curr_report="$2"
  local prev_feedback="$3"
  local output_file="$4"

  [ -n "$prev_report" ] || die "Missing previous report for re-raise detection"
  [ -n "$curr_report" ] || die "Missing current report for re-raise detection"

  local prompt
  prompt=$(cat <<'PROMPT_EOF'
You are analyzing two consecutive issue reports from a spec review loop to detect **re-raised issues**.

## Context

- Codex (reviewer) is double-blind: it doesn't know what Claude Code changed
- In each inner loop iteration:
  1. Claude Code attempts fixes (may decline some with reasoning in feedback file)
  2. Codex verifies the spec and produces a new issue report
- A **re-raised issue** is one where:
  - Claude Code declined to fix it (documented in feedback file)
  - Codex disagreed and raised it again in the new report
  - They are **semantically the same problem**, even if ID/title/wording differs

## Your Task

1. Read the previous feedback file (if exists) to understand what Claude Code declined and why
2. Read both issue reports
3. Identify any issues in the NEW report that are semantically the same as declined issues from the PREVIOUS iteration
4. For each re-raised issue, explain WHY you believe it's a re-raise (what connects them)

## Input Files

- Previous issue report: {prev_report}
- Current issue report: {curr_report}
- Previous feedback file: {prev_feedback} (may not exist)

## Output

Write to {output_file}:

If NO re-raised issues detected:
```
No re-raised issues detected.
```

If re-raised issues ARE detected:
```
# Re-raised Issues Detected

Human review required. The following issues appear to be re-raises of previously declined items.

## Re-raised Issue 1

**Current Report Issue**: Issue [ID] - [Title]
**Previous Declined Issue**: [Title/description from feedback]
**Why This Is a Re-raise**: [Your reasoning - what makes these semantically the same problem]
**Claude Code's Original Reasoning**: [Quote from feedback file]
**Codex's Counter-argument**: [From current report, if any]

## Re-raised Issue 2
...
```
PROMPT_EOF
)

  prompt="${prompt//\{prev_report\}/$prev_report}"
  prompt="${prompt//\{curr_report\}/$curr_report}"
  prompt="${prompt//\{prev_feedback\}/$prev_feedback}"
  prompt="${prompt//\{output_file\}/$output_file}"

  claude --permission-mode acceptEdits --print "$prompt" > "$LOGS_DIR/reraise-detection-inner-$INNER_COUNTER.txt" 2>&1
}

handle_valid_reraise() {
  local reraise_file="$1"
  local latest_report="$2"

  echo ""
  echo "You chose: Re-raise is VALID"
  echo ""
  echo "Please provide your reasoning (why Claude Code should fix this):"
  read -p "Reasoning: " human_reasoning

  local prompt
  prompt=$(cat <<PROMPT_EOF
Human has reviewed the re-raised issues and determined they are VALID re-raises.

## Input Files
- Re-raise report: $reraise_file
- Current issue report: $latest_report

## Human's Reasoning
$human_reasoning

## Your Task

1. Read the re-raise report to identify which issues are re-raises
2. Copy the current issue report to a new version file:
   - If current is \`YYYY-MM-DD-vN.md\`, create \`YYYY-MM-DD-v(N+1).md\`
3. In the new file, for EACH re-raised issue:
   - Set **Human Override** to: \`Must Fix: [human's reasoning]\`
   - Keep Status as-is (do not mark Declined-Accepted)
4. Keep all other issues unchanged
5. Update the Summary table to reflect any Human Override notes (if included)
6. Add completion promise at the end:
   - If ALL issues are Fixed or Declined-Accepted: add \`<promise>ALL_RESOLVED</promise>\`
   - Else: add \`<promise>ISSUES_REMAINING</promise>\`

Do NOT modify the original issue report. Only create the new version file.
PROMPT_EOF
)

  echo ""
  echo "Creating new issue report with Human Override..."
  claude --permission-mode acceptEdits --print "$prompt" > "$LOGS_DIR/human-override-valid-inner-$INNER_COUNTER.txt" 2>&1

  echo "Done. New issue report created."
}

handle_invalid_reraise() {
  local reraise_file="$1"
  local latest_report="$2"
  local human_reasoning="${3:-}"

  if [ -z "$human_reasoning" ]; then
    echo ""
    echo "You chose: Re-raise is INVALID"
    echo ""
    echo "Please provide your reasoning (why Claude Code was right to decline):"
    read -p "Reasoning: " human_reasoning
  fi

  local prompt
  prompt=$(cat <<PROMPT_EOF
Human has reviewed the re-raised issues and determined they are INVALID re-raises.

## Input Files
- Re-raise report: $reraise_file
- Current issue report: $latest_report

## Human's Reasoning
$human_reasoning

## Your Task

1. Read the re-raise report to identify which issues are re-raises
2. Copy the current issue report to a new version file:
   - If current is \`YYYY-MM-DD-vN.md\`, create \`YYYY-MM-DD-v(N+1).md\`
3. In the new file, for EACH re-raised issue:
   - Change **Status** to: \`Declined-Accepted\`
   - Set **Human Override** to: \`Declined-Accepted: [human's reasoning]\`
   - Update **Problem** to: \`Resolved\`
   - Update **Evidence** to: \`Resolved\`
   - Update **Impact** to: \`None\`
   - Update **Suggested Fix** to: \`N/A\`
   - Update **What Changed** to: \`Human approved decline. Reasoning: [human's reasoning]\`
   - Update **Assessment** to: \`Human reviewed re-raise and determined original decline was correct.\`
   - Update **Remaining Work** to: \`None\`
4. Keep all other issues unchanged
5. Update the Summary table to reflect new statuses
6. Add completion promise at the end:
   - If ALL issues are Fixed or Declined-Accepted: add \`<promise>ALL_RESOLVED</promise>\`
   - Else: add \`<promise>ISSUES_REMAINING</promise>\`

Do NOT modify the original issue report. Only create the new version file.
PROMPT_EOF
)

  echo ""
  echo "Creating new issue report with Declined-Accepted status..."
  claude --permission-mode acceptEdits --print "$prompt" > "$LOGS_DIR/human-override-invalid-inner-$INNER_COUNTER.txt" 2>&1

  echo "Done. New issue report created."
}

append_to_decline_log() {
  local reraise_file="$1"
  local human_reasoning="$2"
  local log_file="$SPECS_DIR/issues/human-approved-declines.md"

  if [ ! -f "$log_file" ]; then
    cat > "$log_file" <<'HEADER'
# Human-Approved Declines

Issues listed here were:
1. Raised by a reviewer
2. Declined by the implementer with reasoning
3. Re-raised by the reviewer
4. Reviewed by a human who approved the decline

**Codex: Do NOT re-raise any issue that matches an entry in this file.**

---

HEADER
  fi

  local prompt
  prompt=$(cat <<PROMPT_EOF
Read the re-raise report: $reraise_file

For EACH re-raised issue, append an entry to $log_file in this format:

## [DATE]: [Issue Title]

**Location**: [exact location from issue]
**Guide Rule**: [G1-G11]
**Original Problem**: [brief description of what the issue was about]
**Implementer's Reasoning**: [why they declined - from feedback file]
**Human's Decision**: Decline approved
**Human's Reasoning**: $human_reasoning

---

PROMPT_EOF
)

  claude --permission-mode acceptEdits --print "$prompt" >> "$LOGS_DIR/append-decline-log-$INNER_COUNTER.txt" 2>&1
}

handle_manual_edit() {
  local reraise_file="$1"
  local latest_report="$2"

  echo ""
  echo "You chose: Manual edit"
  echo ""
  echo "Please manually edit the files as needed:"
  echo "  - $reraise_file (for reference)"
  echo "  - $latest_report (to modify statuses)"
  echo ""
  echo "To mark an issue as Declined-Accepted:"
  echo "  1. Change Status to: Declined-Accepted"
  echo "  2. Update fields per issue-lifecycle.md conventions"
  echo ""
  echo "To force loop exit:"
  echo "  Add: <promise>ALL_RESOLVED</promise>"
  echo ""
  read -p "Press Enter when done editing..."
}

handle_reraise_escalation() {
  local reraise_file="$1"
  local latest_report="$(latest_issue_file)"

  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║              HUMAN REVIEW REQUIRED                           ║"
  echo "╠══════════════════════════════════════════════════════════════╣"
  echo "║  Re-raised issues detected. Codex and Claude Code disagree.  ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""
  echo "Re-raise report: $reraise_file"
  echo "Current issues:  $latest_report"
  echo ""
  echo "Please review each re-raised issue and decide:"
  echo ""
  echo "  Option A: Re-raise is VALID (Claude Code should fix it)"
  echo "            → A new issue report will be created with Human Override: Must Fix"
  echo ""
  echo "  Option B: Re-raise is INVALID (Claude Code was right)"
  echo "            → A new issue report will be created with Declined-Accepted"
  echo "            → Decline will be appended to human-approved-declines.md"
  echo ""
  echo "─────────────────────────────────────────────────────────────────"
  read -p "Press Enter when you have reviewed $reraise_file ..."
  echo ""

  echo "For EACH re-raised issue, what is your decision?"
  echo "  [V] Valid re-raise - Claude Code should fix it"
  echo "  [I] Invalid re-raise - Mark as Declined-Accepted"
  echo "  [M] Mixed - I'll handle some of each (manual edit)"
  echo ""
  read -p "Decision [V/I/M]: " decision

  case "$decision" in
    [Vv])
      handle_valid_reraise "$reraise_file" "$latest_report"
      ;;
    [Ii])
      echo ""
      echo "Please provide your reasoning (why Claude Code was right to decline):"
      read -p "Reasoning: " human_reasoning
      handle_invalid_reraise "$reraise_file" "$latest_report" "$human_reasoning"
      append_to_decline_log "$reraise_file" "$human_reasoning"
      ;;
    [Mm])
      handle_manual_edit "$reraise_file" "$latest_report"
      ;;
    *)
      echo "Invalid choice. Defaulting to Manual edit."
      handle_manual_edit "$reraise_file" "$latest_report"
      ;;
  esac
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

    # Re-raise detection + human escalation (only when issues remain)
    prev_report="$(previous_issue_file)"
    curr_report="$(latest_issue_file)"
    if [ -n "$prev_report" ]; then
      prev_feedback="$(feedback_file_for "$prev_report")"
      reraise_report="$(reraise_file_for "$curr_report")"

      run_reraise_detection "$prev_report" "$curr_report" "$prev_feedback" "$reraise_report"
      if grep -q "Re-raised Issues Detected" "$reraise_report" 2>/dev/null; then
        handle_reraise_escalation "$reraise_report"
      fi
    fi
  done

  if [ "$inner" -ge "$INNER_MAX" ] && [ "$signal" != "ALL_RESOLVED" ]; then
    warn "Inner limit reached: $INNER_MAX"
    exit 1
  fi
done

warn "Outer limit reached: $OUTER_MAX"
exit 1
