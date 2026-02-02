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

**Problem**: Neither Codex nor Claude Code knows if an issue was previously declined and re-raised.

**Solution**: Spawn a Claude Code agent after each 03-confirm-fix to compare consecutive issue reports.

**Implementation** (bash script addition):

```bash
# After run_confirm_fix completes
run_reraise_detection() {
  local prev_report="$1"  # e.g., v2.md
  local curr_report="$2"  # e.g., v3.md
  local output_file="$3"  # e.g., v3-reraised.md

  local prompt="Compare these two issue reports and identify re-raised issues:
- Previous: $prev_report
- Current: $curr_report

A re-raised issue is one where:
1. Same Location + Guide Rule ID appears in both reports
2. Status went from Declined → Open (or similar)

Output to $output_file:
## Re-raised Issues
| ID | Title | Location | Guide Rule | Times Re-raised |
|...

If no re-raised issues, output: No re-raised issues detected."

  claude --print "$prompt" > "$LOGS_DIR/reraise-detection-$INNER_COUNTER.txt"
}
```

**When re-raised issues detected**: Pause loop and notify human.

### Solution 2: Human Decision Persistence

**Problem**: Human decisions don't persist across iterations.

**Solution**: Allow humans to directly edit files to control loop behavior.

**Mechanism 1: Mark issue as Declined-Accepted**

Human edits the latest issue report file (`./specs/issues/YYYY-MM-DD-vN.md`):

```markdown
### Issue 3: External API Contracts

**Status**: Declined-Accepted   ← Human changes from "Open" or "Declined"
```

The next 03-confirm-fix pass will see this status and treat it as terminal.

**Mechanism 2: Force loop exit**

Human adds to the latest issue report:

```markdown
<promise>ALL_RESOLVED</promise>
```

The bash script's `check_control_signal` will detect this and exit the inner loop.

**Mechanism 3: Persistent decline file**

Create `./specs/issues/human-decisions.md`:

```markdown
## Permanently Declined Issues

Issues listed here will never be re-raised, regardless of Codex's assessment.

| Location | Guide Rule | Decision | Reasoning |
|----------|------------|----------|-----------|
| `./specs/design.md` > Section: API Contracts | G9 | Declined-Accepted | External API shapes unknown at design time |
```

The re-raise detection agent checks this file and filters out permanently declined issues.

### Solution 3: Human Review Pause

When re-raised issues are detected, pause the loop for human review.

**Implementation** (bash script):

```bash
if [ -s "$RERAISE_FILE" ] && grep -q "Re-raised Issues" "$RERAISE_FILE"; then
  echo ""
  echo "=== Human Review Required ==="
  echo "Re-raised issues detected. Review: $RERAISE_FILE"
  echo ""
  echo "Options:"
  echo "  1. Edit issue report to set Status: Declined-Accepted"
  echo "  2. Add to ./specs/issues/human-decisions.md for permanent decline"
  echo "  3. Press Enter to continue (let agents retry)"
  echo ""
  read -p "Press Enter when ready to continue..." _
fi
```

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
  01-find-issues (Codex)
    ↓
  INNER LOOP:
    02-fix-issues (Claude Code)
      ↓
    [auto-commit subagent]  ← NEW
      ↓
    03-confirm-fix (Codex)
      ↓
    [auto-commit subagent]  ← NEW
      ↓
    [re-raise detection agent]  ← NEW
      ↓
    [human review pause if re-raised]  ← NEW
      ↓
    (check control signal)
```

## Implementation Order

| Priority | Solution | Effort | Impact |
|----------|----------|--------|--------|
| 1 | Re-raise Detection Agent | Medium | High - surfaces deadlocks |
| 2 | Human Decision Persistence | Low | High - breaks deadlocks |
| 3 | Human Review Pause | Low | High - enables intervention |
| 4 | Auto-Commit Subagent | Low | Medium - better tracking |
| 5 | Outer Loop Convergence | Low | Medium - early warning |
| 6 | Graceful Exit | Low | Low - better UX |

## Files to Modify

| File | Changes |
|------|---------|
| `spec-review-loop.sh` | Add re-raise detection, human pause, auto-commit, convergence tracking |
| `issue-lifecycle.md` | Document human-decisions.md file, Declined-Accepted human override |

**No prompt modifications required.**

## Verification

1. **Re-raise detection**: Decline an issue, let Codex re-raise it, verify agent detects it.

2. **Human override**: Edit issue status to Declined-Accepted, verify loop respects it.

3. **Permanent decline**: Add issue to human-decisions.md, verify it's never re-raised.

4. **Auto-commit**: Verify commits are created after each step with correct messages.

5. **Convergence warning**: Run with specs that generate increasing issues, verify warning appears.

## Open Questions

1. **Re-raise detection agent model**: Should this use haiku (fast/cheap) or sonnet (accurate)?
   - Proposal: haiku - comparison is straightforward.

2. **Human pause timeout**: Should there be a timeout for human review, or wait indefinitely?
   - Proposal: Wait indefinitely (interactive mode). For CI, add `--non-interactive` flag that skips pause.

3. **Auto-commit scope**: Should commits include log files, or only spec changes?
   - Proposal: Specs only (`./specs/**`). Logs stay uncommitted.
