# Issue Lifecycle Reference

Data model, state machine, file I/O, and data flow for issues in the spec review loop.

## Required Files

Files that must exist before the loop can run.

| File | Required | Referenced by | If missing |
|------|----------|---------------|------------|
| `./references/SPEC_GENERATION_GUIDE.md` | Yes | 01, 02, 03 | STOP — report blocking issue |
| `./specs/README.md` | Yes | 01 | Cannot discover spec files or determine scope |
| `./specs/questions-and-answers.md` | Yes | 01 (core file) | Missing design decision context |
| `./specs/<YYYY-MM-DD>-<topic>.md` | Yes | 01 | All spec files listed in README.md must exist |
| `./specs/contracts/` or `./specs/interfaces.md` | Conditional | 01 | Only required when cross-module data shapes are defined; if present, treated as authoritative for data contracts |

## Issue Data Model

An issue is a structured finding about a design spec. Its fields evolve as it passes through the loop steps.

### Core Fields (all steps)

| Field | Type | Description |
|-------|------|-------------|
| ID | integer | Unique within the report file. Assigned by 01-find-issues; preserved through inner loop iterations. Regression issues from 03 start at N+1 (N = max existing ID). |
| Title | string | Short description of the problem |
| Severity | enum | `Critical` / `High` |
| Status | enum | See State Machine below |
| Location | string | `./specs/[full-filename].md` > Section: [Section Name] |
| Guide Rule ID | string | G1–G11 or Checklist item from SPEC_GENERATION_GUIDE.md |
| Problem | string | Description of the gap or inconsistency |
| Evidence | string | Quote or reference from the spec |
| Impact | string | Why it matters for implementation |
| Suggested Fix | string | Concrete recommendation |
| Human Override | string | Optional. Human decision that must be followed (e.g., `Must Fix`, `Declined-Accepted`), with brief reasoning. |

### Verification Fields (03-confirm-fix only)

These fields are added by step 03 when verifying fixes. Step 02 may receive them as input (from a previous 03 pass) but is not required to process them — it works from `Problem` and `Suggested Fix`.

| Field | Type | Description |
|-------|------|-------------|
| What Changed | string | Description of spec modifications (or lack thereof) |
| Assessment | string | Evaluator's judgment of the fix |
| Remaining Work | string | What's left to do, if anything |

### Conditional Fill Rules

Fields `Problem` through `Remaining Work` have Status-dependent values:

| Field | Fixed / Declined-Accepted | Partial | Missing | Declined |
|-------|--------------------------|---------|---------|----------|
| Problem | "Resolved" | Restate remaining gap | Restate remaining gap | Restate remaining gap |
| Evidence | "Resolved" | Current evidence | Current evidence | Current evidence |
| Impact | "None" | Remaining impact | Remaining impact | Remaining impact |
| Suggested Fix | "N/A" | Next minimal change | Next minimal change | Next minimal change |
| What Changed | Describe spec modifications / "Declined by implementer; accepted in feedback review" | Changes made + what remains unchanged | "No changes detected" | "Declined by implementer" |
| Assessment | "Fully addressed" | Brief judgment of remaining gap | "Not attempted" | "See Feedback Review" |
| Remaining Work | "None" | Describe remaining work | Briefly restate required work | "Re-raised: fix required or provide revised rationale" |

### Human Override Rules

- `Human Override` is optional and may be added by a human or human-directed agent.
- When present, **02-fix-issues must treat it as authoritative**, even if it conflicts with prior feedback.
- Typical values:
  - `Must Fix: <reasoning>` (forces a fix in the next 02 pass)
  - `Declined-Accepted: <reasoning>` (forces closure without further re-raise)

## State Machine

```
                    ┌─────────────────────────────────────────────┐
                    │              01-find-issues                  │
                    │         (creates new issues)                 │
                    └──────────────┬──────────────────────────────┘
                                   │
                                   ▼
                              ┌─────────┐
                              │  Open   │
                              └────┬────┘
                                   │
                    ┌──────────────┼──────────────────────────────┐
                    │              │   02-fix-issues               │
                    │              │   (processes issues;          │
                    │              │    modifies specs or          │
                    │              │    writes feedback)           │
                    │              │                               │
                    │              │   No status change —          │
                    │              │   issues remain Open          │
                    └──────────────┼──────────────────────────────┘
                                   │
                    ┌──────────────┼──────────────────────────────┐
                    │              │   03-confirm-fix              │
                    │              │   (verifies and assigns       │
                    │              │    final status)              │
                    │              ▼                               │
                    │   ┌──────────────────────┐                  │
                    │   │  Fixed               │──► resolved      │
                    │   ├──────────────────────┤                  │
                    │   │  Declined-Accepted   │──► resolved      │
                    │   ├──────────────────────┤                  │
                    │   │  Partial             │──► unresolved    │
                    │   ├──────────────────────┤                  │
                    │   │  Missing             │──► unresolved    │
                    │   ├──────────────────────┤                  │
                    │   │  Declined            │──► unresolved    │
                    │   └──────────────────────┘                  │
                    │                                             │
                    │   May also emit: New Issues (Regressions)   │
                    │   with Status = Open                        │
                    └─────────────────────────────────────────────┘
                                   │
                          ┌────────┴────────┐
                          │                 │
                    all resolved      any unresolved
                          │                 │
                          ▼                 ▼
                   ALL_RESOLVED      ISSUES_REMAINING
                   (outer loop)      (inner loop:
                                      back to 02)
```

### Status Definitions

| Status | Meaning | Assigned by | Terminal? |
|--------|---------|-------------|-----------|
| Open | Issue identified, not yet processed | 01-find / 03-confirm (regressions) | No |
| Fixed | Spec updated, fix fully addresses the gap | 03-confirm | Yes |
| Partial | Spec partially updated, gap remains | 03-confirm | No |
| Missing | No spec changes detected for this issue | 03-confirm | No |
| Declined | Implementer declined; reviewer disagrees or re-raises | 03-confirm | No |
| Declined-Accepted | Implementer declined; reviewer accepts the reasoning | 03-confirm | Yes |

**Terminal** means the issue is considered resolved and won't re-enter the inner loop.

## Files

### Naming Convention

All issue-related files live under `./specs/issues/`.

| File | Pattern | Created by |
|------|---------|-----------|
| Issue report | `<YYYY-MM-DD>-v<N>.md` | 01-find-issues, 03-confirm-fix |
| Processing summary | `<YYYY-MM-DD>-v<N>-summary.md` | 02-fix-issues |
| Feedback (declined items) | `<YYYY-MM-DD>-v<N>-feedback.md` | 02-fix-issues (only if declines exist) |

The version number `N` increments each time a new report is written (by either 01 or 03). The date is the date of report creation.

### File Lifecycle

```
01-find → v1.md
02-fix  → v1-summary.md, v1-feedback.md (optional)
03-confirm → v2.md
  ↓ (if ISSUES_REMAINING)
02-fix  → v2-summary.md, v2-feedback.md (optional)
03-confirm → v3.md
  ↓ (if ALL_RESOLVED)
01-find → v4.md (or COMPLETE with no file)
```

### Per-Step I/O

#### 01-find-issues

| Direction | File | Notes |
|-----------|------|-------|
| Input | `./specs/**/*.md` | All spec files discovered via README.md |
| Input | `./references/SPEC_GENERATION_GUIDE.md` | Review standard (required) |
| Output | `./specs/issues/<date>-v<N>.md` | New issue report — only if issues found |
| Output | `<promise>COMPLETE</promise>` (stdout) | Termination signal — no file created |

#### 02-fix-issues

| Direction | File | Notes |
|-----------|------|-------|
| Input | Latest `./specs/issues/*.md` (excluding feedback) | Issue report to process |
| Input | `./references/SPEC_GENERATION_GUIDE.md` | Spec standard for changes |
| Input | `./specs/**/*.md` | Specs to modify |
| Output | `./specs/**/*.md` (modified in place) | Applied fixes |
| Output | `<issues>-summary.md` | Processing summary (always created) |
| Output | `<issues>-feedback.md` | Decline reasoning (only if declines exist) |

#### 03-confirm-fix

| Direction | File | Notes |
|-----------|------|-------|
| Input | Latest `./specs/issues/*.md` (excluding feedback) | Issue report to verify |
| Input | `<issues>-feedback.md` | Feedback file (if exists) |
| Input | `./references/SPEC_GENERATION_GUIDE.md` | Spec standard for re-verification |
| Input | `./specs/**/*.md` | Current spec state |
| Output | `./specs/issues/<date>-v<N+1>.md` | Next version report with updated statuses |
| Output | `<promise>ALL_RESOLVED</promise>` (stdout) | All issues Fixed or Declined-Accepted |
| Output | `<promise>ISSUES_REMAINING</promise>` (stdout) | Any issue Partial, Missing, or Declined |

## Report Structure

### 01-find-issues Output

```
# Spec Review: Thresholded Issues
## Critical Issues
  ### Issue [ID]: [Title]        ← repeated per issue
## High Priority Issues
  ### Issue [ID]: [Title]        ← repeated per issue
## Summary                       ← table of all issues
## Files Reviewed                ← checklist of specs reviewed
## Completion                    ← COMPLETE promise (only when no issues)
```

### 03-confirm-fix Output

```
# Spec Verification Report
## Summary                       ← table with updated statuses
## Detailed Findings
  ### Issue [ID]: [Title]        ← repeated per issue (all fields + verification fields)
## Feedback Review               ← evaluation of declined items (if feedback file exists)
## New Issues (Regressions)      ← new issues from fixes that introduced violations
## Completion Status             ← ALL_RESOLVED or ISSUES_REMAINING promise
```

### 02-fix-issues Output (Summary)

```
Issue ID / Title
Decision: Accepted / Declined / Already Resolved
Changes Applied: (short description)
Guide Rule IDs affected
```

### 02-fix-issues Output (Feedback)

```
## Feedback
### [Issue Title/Number]
- Suggestion: (what Codex proposed)
- Decision: Declined
- Reasoning: (why — technical, scoped, design intent)
```

## Control Signals

| Signal | Emitted by | Condition | Orchestrator action |
|--------|-----------|-----------|-------------------|
| `<promise>COMPLETE</promise>` | 01-find-issues | Zero issues meeting threshold | Terminate all loops |
| `<promise>ALL_RESOLVED</promise>` | 03-confirm-fix | All statuses are Fixed or Declined-Accepted | Exit inner loop → next 01-find pass |
| `<promise>ISSUES_REMAINING</promise>` | 03-confirm-fix | Any status is Partial, Missing, or Declined | Continue inner loop → next 02-fix pass |

Step 02-fix-issues emits no control signal. Its completion is implicit — the orchestrator proceeds to 03 after 02 finishes.
