# Spec Review Loop - Convergence Fix v2

## Status

**Problem**: The spec review loop can run indefinitely without converging to COMPLETE.

**Evidence**: Example run reached 16 iterations (v1 → v16) with issues still remaining.

## Design Principle

**No prompt modifications.** All convergence logic is implemented via:
- Bash script orchestration
- Additional Claude Code agents (comparison, auto-commit)
- Human-editable files (issue reports, feedback files)

This keeps prompts stateless and reusable while adding convergence guarantees at the orchestration layer.

## What v1 Proposed vs Current State

| v1 Proposal | Implemented? | Location |
|-------------|--------------|----------|
| Add "Issue Threshold" (Critical/High/Do NOT raise) | Yes | 01-find-issues.md lines 27-51 |
| Add "Definition of Done" | Yes | 01-find-issues.md lines 53-60 |
| Max 5 issues per review | Yes | 01-find-issues.md line 64 |
| Simplify criteria 9 → 4 | No | Deferred - avoiding prompt changes |
| Strengthen "Out of Scope" | Partial | Covered in Issue Threshold |

## Root Cause Analysis

The convergence problem persists because of **two failure modes**:

### 1. Decline/Re-raise Deadlock

```
02-fix-issues: "I decline Issue 3 because external API shapes are unknown"
03-confirm-fix: "Invalid reasoning - re-raised with counter-argument"
02-fix-issues: "I still decline - G9 doesn't apply to external APIs"
03-confirm-fix: "Invalid - re-raised again"
...infinite loop...
```

Codex and Claude Code can disagree indefinitely. Neither knows about previous iterations (stateless design).

### 2. No Human Override Mechanism

Humans cannot easily intervene to break deadlocks. The loop runs autonomously until max iterations.

## Proposed Solutions

### Solution 1: Re-raise Detection Agent

**Problem**: Neither Codex nor Claude Code knows if an issue was previously declined and re-raised. Codex is double-blind — it doesn't know what Claude Code changed (or didn't change). It only checks if the spec now satisfies the issue.

**Solution**: Spawn a Claude Code agent after 03-confirm-fix, but **only when `ISSUES_REMAINING`**. If `ALL_RESOLVED`, there's nothing to check.

**Position in loop**: Between 03-confirm-fix and next 02-fix-issues iteration.

```
Inner Loop:
  02-fix-issues
    ↓
  03-confirm-fix → signal
    ↓
  if ISSUES_REMAINING:
    [re-raise detection agent]  ← HERE
    if re-raised found:
      [human review & decision]
    ↓
  (next inner iteration or exit)
```

**Detection Approach**: Semantic comparison, not exact matching.

Issues may have different IDs, titles, or statuses across versions. What matters is: **are they describing the same underlying problem?**

The agent should reason about semantic similarity, not rely on field matching.

**Implementation** (bash script):

```bash
# Called only when signal == ISSUES_REMAINING
run_reraise_detection() {
  local prev_report="$1"  # Issue report BEFORE this inner iteration (e.g., v2.md)
  local curr_report="$2"  # Issue report AFTER 03-confirm-fix (e.g., v3.md)
  local prev_feedback="$3" # Feedback file from prev iteration (e.g., v2-feedback.md), may not exist
  local output_file="$4"  # e.g., v3-reraised.md

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

  # Replace placeholders
  prompt="${prompt//\{prev_report\}/$prev_report}"
  prompt="${prompt//\{curr_report\}/$curr_report}"
  prompt="${prompt//\{prev_feedback\}/$prev_feedback}"
  prompt="${prompt//\{output_file\}/$output_file}"

  claude --print "$prompt" > "$LOGS_DIR/reraise-detection-inner-$INNER_COUNTER.txt" 2>&1
}
```

**Trigger condition in main loop**:

```bash
signal="$(run_confirm_fix "$CONFIRM_PROMPT_FILE")"

if [ "$signal" = "ALL_RESOLVED" ]; then
  break
fi

# Only check for re-raises when issues remain
RERAISE_FILE="$(reraise_file_for "$(latest_issue_file)")"
PREV_REPORT="$(previous_issue_file)"  # Need to track this
PREV_FEEDBACK="$(feedback_file_for "$PREV_REPORT")"

run_reraise_detection "$PREV_REPORT" "$(latest_issue_file)" "$PREV_FEEDBACK" "$RERAISE_FILE"

if grep -q "Re-raised Issues Detected" "$RERAISE_FILE" 2>/dev/null; then
  # Human review required
  handle_reraise_escalation "$RERAISE_FILE"
fi
```

### Solution 2: Human Escalation Workflow

**Problem**: When re-raised issues are detected, human needs clear guidance on what to do.

**Escalation Mechanism**:

```bash
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
  echo "            → Edit the feedback file to add your reasoning"
  echo "            → The loop will continue with your guidance"
  echo ""
  echo "  Option B: Re-raise is INVALID (Claude Code was right)"
  echo "            → A new issue report will be created"
  echo "            → The re-raised issue(s) will be marked Declined-Accepted"
  echo ""
  echo "─────────────────────────────────────────────────────────────────"
  read -p "Press Enter when you have reviewed $reraise_file ..."
  echo ""

  # Ask for decision
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
      handle_invalid_reraise "$reraise_file" "$latest_report"
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
```

**Option A: Re-raise is VALID** (Claude Code should fix it)

Human believes Codex is right and Claude Code should actually fix the issue, even if there were reasons to decline.

Example: "The other team has no capacity right now, so we need to handle this ourselves."

```bash
handle_valid_reraise() {
  local reraise_file="$1"
  local latest_report="$2"
  local feedback_file="$(feedback_file_for "$latest_report")"

  echo ""
  echo "You chose: Re-raise is VALID"
  echo ""
  echo "Please provide your reasoning (why Claude Code should fix this):"
  echo "(This will be added to the feedback file for Claude Code to see)"
  echo ""
  read -p "Reasoning: " human_reasoning

  # Append human guidance to feedback file
  cat >> "$feedback_file" <<EOF

## Human Override

**Decision**: Re-raise is valid. Claude Code should fix the following issues.

**Human Reasoning**: $human_reasoning

**Action Required**: Claude Code must address these issues in the next iteration, incorporating the human reasoning above.
EOF

  echo ""
  echo "Guidance added to: $feedback_file"
  echo "Loop will continue. Claude Code will see your reasoning."
}
```

**Option B: Re-raise is INVALID** (Mark as Declined-Accepted)

Human believes Claude Code's decline was correct. The re-raised issues should be permanently closed.

```bash
handle_invalid_reraise() {
  local reraise_file="$1"
  local latest_report="$2"

  echo ""
  echo "You chose: Re-raise is INVALID"
  echo ""
  echo "Please provide your reasoning (why Claude Code was right to decline):"
  read -p "Reasoning: " human_reasoning

  # Spawn Claude Code agent to create new version with Declined-Accepted status
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
   - Update **Problem** to: \`Resolved\`
   - Update **Evidence** to: \`Resolved\`
   - Update **Impact** to: \`None\`
   - Update **Suggested Fix** to: \`N/A\`
   - Update **What Changed** to: \`Human approved decline. Reasoning: [human's reasoning]\`
   - Update **Assessment** to: \`Human reviewed re-raise and determined original decline was correct.\`
   - Update **Remaining Work** to: \`None\`
4. Keep all other issues unchanged
5. Update the Summary table to reflect new statuses
6. Check if ALL issues are now Fixed or Declined-Accepted:
   - If yes: Add \`<promise>ALL_RESOLVED</promise>\` at the end
   - If no: Add \`<promise>ISSUES_REMAINING</promise>\` at the end

Do NOT modify the original issue report. Only create the new version file.
PROMPT_EOF
)

  echo ""
  echo "Creating new issue report with Declined-Accepted status..."
  claude --print "$prompt" > "$LOGS_DIR/human-override-inner-$INNER_COUNTER.txt" 2>&1

  echo "Done. New issue report created."
  echo "Loop will continue with updated statuses."
}
```

**Option M: Manual Edit**

Human wants to handle it themselves (e.g., some re-raises are valid, some are not).

```bash
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
```

### Solution 3: Human Decision Persistence (Cross-Loop)

**Problem**: Human decisions should persist across ALL iterations, including outer loop restarts. Within inner loop, `Declined-Accepted` status works. But when outer loop starts fresh (01-find-issues), Codex has no memory of previous decisions.

**Solution**: Create a persistent log file that 01-find-issues reads.

#### Mechanism 1: Persistent decline log

When `handle_invalid_reraise()` runs, append to `./specs/issues/human-approved-declines.md`:

```bash
# Add to handle_invalid_reraise() after creating new issue report version

append_to_decline_log() {
  local reraise_file="$1"
  local human_reasoning="$2"
  local log_file="$SPECS_DIR/issues/human-approved-declines.md"

  # Create file with header if doesn't exist
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

  # Use Claude Code agent to extract issue details and append
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

  claude --print "$prompt" >> "$LOGS_DIR/append-decline-log-$INNER_COUNTER.txt" 2>&1
}
```

#### Mechanism 2: 01-find-issues reads the log

**Small prompt addition to 01-find-issues.md** (insert after "## Scope" section):

```markdown
## Previously Declined Issues (Human Approved)

If `./specs/issues/human-approved-declines.md` exists, read it first.

These issues were previously raised, declined by the implementer, re-raised by a reviewer, and then a **human reviewer** determined the decline was correct.

**Do NOT re-raise any issue that semantically matches an entry in this file.** The human has final authority on these decisions.
```

#### Mechanism 3: Force loop exit

Human can add to any issue report:

```markdown
<promise>ALL_RESOLVED</promise>
```

The bash script's `check_control_signal` will detect this and exit the inner loop.

#### File Flow

```
Inner Loop (re-raise detected, human chooses Invalid):
  handle_invalid_reraise()
    ├── Creates new issue report (vN+1.md) with Declined-Accepted
    └── Appends to human-approved-declines.md  ← PERSISTENT

Outer Loop (fresh review):
  01-find-issues reads:
    ├── ./specs/**/*.md
    ├── ./references/SPEC_GENERATION_GUIDE.md
    └── ./specs/issues/human-approved-declines.md  ← IF EXISTS

  Codex sees human-approved declines and avoids re-raising them
```

This ensures human decisions persist across **all** iterations, not just consecutive ones.

### Solution 4: Auto-Commit Subagent

**Problem**: Changes accumulate without commits, making it hard to track/revert.

**Solution**: Spawn a commit subagent after each step.

**Implementation** (bash script):

```bash
run_auto_commit() {
  local step_name="$1"  # e.g., "02-fix-issues"
  local iteration="$2"  # e.g., "outer-1-inner-2"

  # Use Claude Code with /commit skill or direct git commands
  claude --print "Review git status. If there are changes:
1. Stage spec files only (./specs/**)
2. Commit with message: 'spec-review: $step_name ($iteration)'
Do not push."
}

# Call after each step
run_fix_issues "$FIX_PROMPT_FILE"
run_auto_commit "02-fix-issues" "outer-${CURRENT_OUTER}-inner-${CURRENT_INNER}"
```

### Solution 5: Outer Loop Convergence Logic

**Problem**: Outer loop can keep finding new issues indefinitely.

**Solution**: Track issue discovery rate across outer iterations. If rate doesn't decrease, warn and optionally exit.

**Implementation** (bash script):

```bash
# Track issues found per outer iteration
ISSUE_COUNTS=()

# After run_find_issues
count_issues() {
  local report="$1"
  grep -c "^### Issue" "$report" 2>/dev/null || echo "0"
}

# In outer loop
ISSUE_COUNTS+=("$(count_issues "$latest_report")")

# After 3+ outer iterations, check convergence
if [ "${#ISSUE_COUNTS[@]}" -ge 3 ]; then
  prev="${ISSUE_COUNTS[-2]}"
  curr="${ISSUE_COUNTS[-1]}"
  if [ "$curr" -ge "$prev" ]; then
    warn "Issue count not decreasing: $prev → $curr"
    warn "Consider reviewing specs manually or adjusting scope"
  fi
fi
```

### Solution 6: Graceful Exit on Limits

**Current behavior**: `exit 1` on max iterations.

**Proposed**: `exit 0` with summary report.

```bash
if [ "$inner" -ge "$INNER_MAX" ] && [ "$signal" != "ALL_RESOLVED" ]; then
  warn "Inner limit reached: $INNER_MAX"
  echo "=== Unresolved Issues ==="
  # Print summary from latest report
  grep -A1 "^### Issue" "$(latest_issue_file)" || true
  echo ""
  echo "Specs are usable but not fully verified. See: $LOGS_DIR"
  exit 0  # Graceful - specs are usable
fi
```

## Updated Loop Flow

```
OUTER LOOP:
  01-find-issues (Codex) ─────────────────────────────────────┐
    │                                                          │
    ▼                                                          │
  INNER LOOP:                                                  │
    ┌─────────────────────────────────────────────────────┐   │
    │                                                     │   │
    │  02-fix-issues (Claude Code)                        │   │
    │    │                                                │   │
    │    ▼                                                │   │
    │  [auto-commit subagent]  ← NEW                      │   │
    │    │                                                │   │
    │    ▼                                                │   │
    │  03-confirm-fix (Codex) → signal                    │   │
    │    │                                                │   │
    │    ├── ALL_RESOLVED ──────────────────────────────────→─┤
    │    │                                                │   │
    │    ▼ (ISSUES_REMAINING)                             │   │
    │  [auto-commit subagent]  ← NEW                      │   │
    │    │                                                │   │
    │    ▼                                                │   │
    │  [re-raise detection agent]  ← NEW                  │   │
    │    │                                                │   │
    │    ├── No re-raise ─────────────────────┐           │   │
    │    │                                    │           │   │
    │    ▼ (re-raise detected)                │           │   │
    │  [human review & decision]  ← NEW       │           │   │
    │    │                                    │           │   │
    │    ├── Valid: add guidance to feedback  │           │   │
    │    ├── Invalid: create new version      │           │   │
    │    │   with Declined-Accepted           │           │   │
    │    │                                    │           │   │
    │    ▼                                    ▼           │   │
    │  (next inner iteration) ◄───────────────┘           │   │
    │                                                     │   │
    └─────────────────────────────────────────────────────┘   │
                                                              │
    (after inner loop exits) ◄─────────────────────────────────┘
```

**Key insight**: Re-raise detection only runs when `ISSUES_REMAINING`. If all issues are resolved, there's nothing to check for re-raises.

## Implementation Order

| Priority | Solution | Effort | Impact |
|----------|----------|--------|--------|
| 1 | Re-raise Detection Agent | Medium | High - surfaces deadlocks |
| 2 | Human Escalation Workflow | Medium | High - breaks deadlocks with human judgment |
| 3 | Human Decision Persistence | Low | High - ensures decisions stick |
| 4 | Auto-Commit Subagent | Low | Medium - better tracking |
| 5 | Outer Loop Convergence | Low | Medium - early warning |
| 6 | Graceful Exit | Low | Low - better UX |

## Files to Modify

| File | Changes |
|------|---------|
| `spec-review-loop.sh` | Add `run_reraise_detection()`, `handle_reraise_escalation()`, `handle_valid_reraise()`, `handle_invalid_reraise()`, `handle_manual_edit()`, `append_to_decline_log()`, auto-commit calls, convergence tracking, graceful exit |
| `01-find-issues.md` | Add "Previously Declined Issues (Human Approved)" section (~8 lines) |
| `issue-lifecycle.md` | Document re-raise detection step, human override workflow, `human-approved-declines.md` file |

**Minimal prompt modification**: Only 01-find-issues.md, additive change (doesn't alter existing behavior).

## New Helper Functions Required

| Function | Purpose |
|----------|---------|
| `previous_issue_file()` | Get the issue report from the previous inner iteration |
| `reraise_file_for(issue_file)` | Generate re-raise report filename (e.g., `v3-reraised.md`) |
| `run_reraise_detection()` | Spawn Claude Code agent to compare consecutive reports |
| `handle_reraise_escalation()` | Main human escalation entry point |
| `handle_valid_reraise()` | Add human guidance to feedback file |
| `handle_invalid_reraise()` | Create new version with Declined-Accepted + append to log |
| `handle_manual_edit()` | Pause for human to manually edit files |
| `append_to_decline_log()` | Append human decision to persistent `human-approved-declines.md` |
| `run_auto_commit()` | Spawn commit subagent after each step |

## Verification

1. **Re-raise detection**:
   - Decline an issue in 02-fix-issues
   - Let Codex re-raise it in 03-confirm-fix
   - Verify re-raise detection agent identifies it
   - Verify human escalation is triggered

2. **Valid re-raise workflow**:
   - Trigger re-raise escalation
   - Choose "Valid" option
   - Verify human reasoning is added to feedback file
   - Verify Claude Code sees the guidance in next iteration

3. **Invalid re-raise workflow**:
   - Trigger re-raise escalation
   - Choose "Invalid" option
   - Verify new issue report version is created
   - Verify re-raised issue has Status: Declined-Accepted
   - Verify all fields are updated per issue-lifecycle.md
   - Verify entry is appended to `human-approved-declines.md`

4. **Cross-loop persistence** (critical):
   - Complete an inner loop with human-approved decline
   - Exit inner loop (ALL_RESOLVED)
   - Start new outer loop (01-find-issues)
   - Verify Codex does NOT re-raise the human-approved decline
   - Verify `human-approved-declines.md` is read by Codex

5. **Human decision persistence within inner loop**:
   - Mark issue as Declined-Accepted
   - Verify it's not re-raised in subsequent inner iterations

6. **Auto-commit**: Verify commits are created after each step with correct messages.

7. **Convergence warning**: Run with specs that generate increasing issues, verify warning appears.

## Open Questions

1. **Re-raise detection agent model**: Should this use haiku (fast/cheap) or sonnet (accurate)?
   - Proposal: sonnet — semantic comparison requires understanding, not just pattern matching.

2. **Human pause timeout**: Should there be a timeout for human review, or wait indefinitely?
   - Proposal: Wait indefinitely (interactive mode). For CI, add `--non-interactive` flag that auto-continues.

3. **Auto-commit scope**: Should commits include log files, or only spec changes?
   - Proposal: Specs only (`./specs/**`). Logs stay uncommitted.

4. **Multiple re-raises in one iteration**: If 3 issues are all re-raises, can human give different decisions for each?
   - Proposal: Yes via "Manual edit" option. "Valid" and "Invalid" options apply to ALL re-raises.

5. **Log file cleanup**: Should `human-approved-declines.md` be cleaned up periodically, or kept indefinitely?
   - Proposal: Keep indefinitely. It's a permanent record of human decisions. Can be archived manually if needed.
