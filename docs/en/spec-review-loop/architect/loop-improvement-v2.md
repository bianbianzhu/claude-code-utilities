# Spec Review Loop - Convergence Fix v2 (Updated)

## Status

**Problem**: The spec review loop can run indefinitely without converging to COMPLETE.

**Evidence**: Example run reached 16 iterations (v1 → v16) with issues still remaining.

## Design Principles

- **Minimal prompt changes, not zero.** Prompts remain stateless and reusable, but can include small additive instructions required for convergence.
- **Convergence logic stays in orchestration.** Bash script + helper agents + human decisions drive loop control.
- **Human decisions are authoritative.** When a human overrides a re-raise, the decision persists across inner and outer loops.

## Root Cause Analysis

The convergence problem persists because of two failure modes:

### 1) Decline/Re-raise Deadlock

```
02-fix-issues: "I decline Issue 3 because external API shapes are unknown"
03-confirm-fix: "Invalid reasoning - re-raised with counter-argument"
02-fix-issues: "I still decline - G9 doesn't apply to external APIs"
03-confirm-fix: "Invalid - re-raised again"
...infinite loop...
```

Codex and Claude Code can disagree indefinitely. Neither knows about previous iterations (stateless design).

### 2) No Human Override Mechanism

Humans cannot easily intervene to break deadlocks. The loop runs autonomously until max iterations.

## Updated Design (Key Fixes)

### A) Re-raise Detection Agent

**Goal**: Identify when Codex re-raises an issue that Claude Code previously declined.

**Position in loop**: After 03-confirm-fix, only if `ISSUES_REMAINING`.

**Detection approach**: Semantic comparison between:
- Previous issue report (before this inner iteration)
- Current issue report (after 03-confirm-fix)
- Previous feedback file (declines from last iteration)

**Output**: A `*-reraised.md` report listing re-raised issues with reasoning.

### B) Human Escalation Workflow

When re-raises are detected, pause for human review. Human chooses:

- **Valid re-raise**: Codex is right → Claude Code must fix.
- **Invalid re-raise**: Claude Code was right → issue should be closed.
- **Mixed**: Human edits manually.

### C) IMPORTANT: Human Override MUST create a new issue report

If the human decides the re-raise is VALID or INVALID, **do not write the decision into a feedback file**. Feedback files are written by 02-fix-issues and can be overwritten.

Instead, create a **new issue report version** and encode the human decision there. The issue report is the authoritative input for 02-fix-issues.

This is the key to making human decisions stick.

## Versioned Flow Example (Concrete)

### Iteration 1
1. `01-find-issues` → `v1.md`
2. `02-fix-issues` reads `v1.md`, writes `v1-summary.md`, may write `v1-feedback.md`
3. `03-confirm-fix` reads `v1.md` + `v1-feedback.md` → outputs `v2.md`

### Iteration 2 (Re-raise happens)
4. `v2.md` contains a re-raised issue from `v1-feedback.md`
5. Re-raise detection reports it
6. Human reviews and decides **Valid or Invalid re-raise**

**Correct action**:
- Create a new issue report `v3.md` and encode the decision:
  - **Valid**: keep issue open and set the **Human Override** field to `Must Fix: <reasoning>`.
  - **Invalid**: mark issue as **Declined-Accepted** and update fields per issue-lifecycle conventions.
- Do **not** create or edit `v2-feedback.md` for this decision (it will be overwritten by 02).

### Iteration 3
7. `02-fix-issues` now reads `v3.md` as the latest report
8. The human decision is enforced by the report (fix required or decline accepted)

## Persistence Across Outer Loop

Even after the inner loop exits, outer loop restarts can re-raise the same issue unless we persist human decisions.

**Solution**: Append human-approved declines to a persistent log:

- `./specs/issues/human-approved-declines.md`

Then `01-find-issues` must read this file and **not re-raise** semantically matching issues.

## Required Prompt Updates (Minimal)

1) **02-fix-issues**: Honor any **Human Override** notes in the latest issue report (not feedback).
2) **01-find-issues**: If `human-approved-declines.md` exists, read it first and do not re-raise those issues.
3) **03-confirm-fix**: Include the **Human Override** field in each issue block (set to `Must Fix: ...`, `Declined-Accepted: ...`, or `None`).

## Control Signal Update

`run_confirm_fix()` should check the **issue report** file for `<promise>` tags before the raw model output. This allows a human to force `ALL_RESOLVED` by editing the report directly.

## Updated Loop Flow (Inner)

```
02-fix-issues
  ↓
03-confirm-fix → signal
  ↓
if ISSUES_REMAINING:
  re-raise detection
  ↓
  if re-raises found:
    human review
    ├─ Valid  → create new issue report with Human Override = Must Fix
    ├─ Invalid → create new issue report with Declined-Accepted
    └─ Mixed → manual edit
  ↓
(next inner iteration)
```

## Implementation Notes (Script)

- Use `next_issue_file()` for any human override report to avoid overwriting current reports.
- Re-raise detection and human override should run with `claude --permission-mode acceptEdits` so new files are actually created.
- If creating a new issue report during human override, ensure the summary table is updated and `<promise>` tags reflect the new overall status.

## Files to Modify

- `docs/en/spec-review-loop/scripts/spec-review-loop.sh`
  - Add: `run_reraise_detection()`, `handle_reraise_escalation()`, `handle_valid_reraise()`, `handle_invalid_reraise()`, `handle_manual_edit()`
  - Ensure human override creates **new issue report versions**
  - Allow promise tags from issue report file
- `docs/en/spec-review-loop/prompts/for-loop/02-fix-issues.md` (and related prompt copies)
  - Honor Human Override notes in the latest issue report
- `docs/en/spec-review-loop/prompts/for-loop/01-find-issues.md` (and related prompt copies)
  - Read `human-approved-declines.md` if present
- `docs/en/spec-review-loop/prompts/for-loop/03-confirm-fix.md` (and related prompt copies)
  - Output the Human Override field per issue
- `docs/en/spec-review-loop/architect/issue-lifecycle.md`
  - Document re-raise detection and human override lifecycle

## Verification Checklist

1. Re-raise detection identifies a declined issue that was re-raised.
2. Human chooses **Invalid** → new issue report created with `Declined-Accepted`.
3. Next inner iteration uses the new report (issue stays closed).
4. `human-approved-declines.md` prevents re-raise in future outer loops.
5. Human can force exit by adding `<promise>ALL_RESOLVED</promise>` to report file.
