# Spec Review Loop

A systematic review cycle using Codex for analysis and Claude Code for fixes. The loop continues until all spec issues are resolved.

## Flow Diagram

```mermaid
flowchart TD
    START([Start]) --> FIND

    subgraph REVIEW ["Review Phase (Codex)"]
        FIND[01-find-issues<br/>Codex analyzes specs]
    end

    FIND --> ISSUES{Issues<br/>found?}
    ISSUES -->|No| DONE([Done])
    ISSUES -->|Yes| FIX

    subgraph FIXING ["Fix Phase (Claude Code)"]
        FIX[02-fix-issues<br/>Claude Code applies fixes]
        FIX --> FEEDBACK[Write feedback for<br/>declined suggestions]
    end

    FEEDBACK --> CONFIRM

    subgraph VERIFY ["Verify Phase (Codex)"]
        CONFIRM[03-confirm-fix<br/>Codex verifies fixes]
        CONFIRM --> REVIEW_FB[Review feedback<br/>Accept or re-raise]
    end

    REVIEW_FB --> FIXED{Resolution<br/>status?}
    FIXED -->|Issues remaining| FIX
    FIXED -->|Escalation needed| ESCALATE([Human Decision<br/>Required])
    ESCALATE -->|Direction provided| FIX
    FIXED -->|All resolved| FIND
```

## Steps

| Step | Tool | Purpose |
|------|------|---------|
| 01-find-issues | Codex | Comprehensive spec review to identify gaps and inconsistencies |
| 02-fix-issues | Claude Code | Apply fixes; decline invalid suggestions with documented reasoning |
| 03-confirm-fix | Codex | Verify fixes; review feedback and accept or re-raise declined items |

## Loop Logic

1. **Find**: Codex reviews all specs and outputs issues to `./specs/issues/<date>-v<N>.md`
2. **Fix**: Claude Code addresses each issue (AFK or HITL mode)
   - Valid suggestions → apply to specs
   - Invalid suggestions → decline with reasoning in feedback file
3. **Confirm**: Codex verifies fixes and reviews any feedback
   - Partial/missing fixes → return to Fix (step 2)
   - Re-raised declined items → return to Fix (step 2)
   - Escalated items (declined twice) → pause for human decision, then return to Fix (step 2)
   - All resolved → return to Find (step 1)
4. **Done**: Loop ends when Find discovers no new issues
