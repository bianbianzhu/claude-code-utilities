#!/bin/bash
set -e
set -o pipefail

# Architect Review Loop Script
# Simulates a collaborative review between Claude Code (working architect) and Codex (reviewing architect)
# for a design document.
#
# Flow:
# 1. Review Architect (Codex) reviews design doc -> outputs review-log-iteration-{n}.md
# 2. Working Architect (Claude Code) addresses issues interactively with user -> updates design doc
#    -> outputs work-log-iteration-{n}.md
# 3. Repeat until max_iterations OR review architect has no more issues
#
# Exit conditions:
# 1. Number of iterations provided by user is hit
# 2. Review architect indicates no more issues to address

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

CURRENT_ITERATION=""
exit_safely() {
    local reason="${1:-Exiting}"
    echo ""
    echo -e "${BOLD}${YELLOW}>>> ${reason}${NC}"
    if [ -n "${CURRENT_ITERATION:-}" ]; then
        echo -e "${CYAN}Iteration:${NC} $CURRENT_ITERATION"
    fi
    if [ -n "${LOGS_DIR:-}" ]; then
        echo -e "${CYAN}Logs directory:${NC} $LOGS_DIR"
    fi
    exit 130
}

on_interrupt() {
    exit_safely "Interrupted (Ctrl+C)"
}

trap on_interrupt INT TERM HUP

usage() {
    echo -e "${BOLD}Usage:${NC} $0 <max_iterations> <design_doc_path>"
    echo ""
    echo "Runs a collaborative architecture review loop between Claude Code and Codex."
    echo ""
    echo -e "${BOLD}Flow:${NC}"
    echo "  1. Codex (Review Architect) reviews and outputs review-log-iteration-{n}.md"
    echo "  2. Claude Code (Working Architect) addresses issues interactively with you"
    echo "  3. Claude Code updates the design doc and outputs work-log-iteration-{n}.md"
    echo "  4. Repeat until done or max iterations reached"
    echo ""
    echo -e "${BOLD}Arguments:${NC}"
    echo "  max_iterations    Maximum number of review iterations (required)"
    echo "  design_doc_path   Path to the design document to review (required)"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  $0 5 docs/plans/orchestrator-design.md"
    exit 1
}

# Validate arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    usage
fi

MAX_ITERATIONS=$1
DESIGN_DOC_ARG=$2

# Validate max_iterations
if ! [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] || [ "$MAX_ITERATIONS" -lt 1 ]; then
    echo -e "${RED}Error: max_iterations must be a positive integer${NC}"
    exit 1
fi

# Resolve design doc path (support both relative and absolute)
if [[ "$DESIGN_DOC_ARG" = /* ]]; then
    DESIGN_DOC="$DESIGN_DOC_ARG"
else
    DESIGN_DOC="$PROJECT_ROOT/$DESIGN_DOC_ARG"
fi

# Validate design doc exists
if [ ! -f "$DESIGN_DOC" ]; then
    echo -e "${RED}Error: Design document not found: $DESIGN_DOC${NC}"
    exit 1
fi

# Extract relative path for prompts
DESIGN_DOC_REL=$(realpath --relative-to="$PROJECT_ROOT" "$DESIGN_DOC" 2>/dev/null || echo "$DESIGN_DOC_ARG")

# Setup logs directory
LOGS_DIR="$PROJECT_ROOT/logs/architect-review-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOGS_DIR"

# Print header
echo ""
echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║            ARCHITECT REVIEW LOOP                           ║${NC}"
echo -e "${BOLD}${BLUE}║     Claude Code (Opus 4.5) × Codex (GPT-5.2)               ║${NC}"
echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Design doc:${NC}     $DESIGN_DOC_REL"
echo -e "${CYAN}Logs dir:${NC}       $LOGS_DIR"
echo -e "${CYAN}Max iterations:${NC} $MAX_ITERATIONS"
echo ""

for ((iteration=1; iteration<=MAX_ITERATIONS; iteration++)); do
    CURRENT_ITERATION="$iteration"
    echo ""
    echo -e "${BOLD}${GREEN}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${GREEN}│  ITERATION $iteration of $MAX_ITERATIONS                                            │${NC}"
    echo -e "${BOLD}${GREEN}└────────────────────────────────────────────────────────────┘${NC}"

    REVIEW_LOG="$LOGS_DIR/review-log-iteration-${iteration}.md"
    WORK_LOG="$LOGS_DIR/work-log-iteration-${iteration}.md"

    # ============================================
    # Phase 1: Review Architect (Codex) - Review
    # ============================================
    echo ""
    echo -e "${BOLD}${MAGENTA}▶ PHASE 1: Review Architect (Codex / GPT-5.2)${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────${NC}"

	    # Build context for Codex based on iteration
	    if [ "$iteration" -eq 1 ]; then
	        CONTEXT="This is the first review iteration."
	        PREV_LOGS=""
	    else
	        PREV_ITERATION=$((iteration - 1))
	        PREV_REVIEW="$LOGS_DIR/review-log-iteration-${PREV_ITERATION}.md"
	        PREV_WORK="$LOGS_DIR/work-log-iteration-${PREV_ITERATION}.md"
	        CONTEXT="This is iteration $iteration. Please review the UPDATED design document.

	Reference the previous review and work logs to understand what was already addressed:
	- Previous review: review-log-iteration-${PREV_ITERATION}.md
	- Previous work response: work-log-iteration-${PREV_ITERATION}.md"
	        PREV_LOGS="
Previous iteration artifacts (read from disk):
- Previous review log: $PREV_REVIEW
- Previous work log: $PREV_WORK"
	    fi
	
    read -r -d '' CODEX_PROMPT <<EOF || true
You are a senior experienced architect acting as a REVIEWER for a design document.
Your goal is to CONVERGE quickly by identifying ONLY the smallest set of remaining BLOCKERS required to declare the design ready for implementation. Avoid scope creep.

$CONTEXT

Files to review (read from disk):
- Design document: $DESIGN_DOC_REL
$PREV_LOGS

Review protocol:
1. If previous logs are provided, read them and build an issue ledger:
   - For each prior issue: mark it Resolved / Partially Resolved / Not Addressed / Unclear
   - Do NOT re-list issues you consider Resolved
2. Re-read the current design document and verify whether each prior issue is actually resolved
3. Add NEW issues only if they are Critical/High blockers not previously mentioned

Hard limits:
- List at most 5 blocker issues total
- If this is not the first iteration, no more than 2 of the blockers may be NEW issues
- Do not include Medium/Low issues as blockers; put them in a short "Backlog (non-blocking)" section (max 5 bullets) or omit them
- If you believe there are more than 5 Critical/High blockers, say so explicitly, then list ONLY the top 5 and group the rest by theme (max 5 themes, 1 line each)

Definition of done:
- If there are no remaining Critical/High blockers AND the doc is internally consistent (no contradictory contracts/state-machine rules/data-store semantics), conclude with the exact line:
  NO_MORE_ISSUES - Design is ready for implementation
- If you are not confident the design is READY, mark it BLOCKED (do not use the NO_MORE_ISSUES line)

Output format (this will be saved to review-log-iteration-${iteration}.md):

# Review Log - Iteration $iteration

## Summary
- Readiness: [BLOCKED or READY]
- Delta since last iteration: [1-3 bullets, or "N/A"]
- Remaining blockers: [0-5]

## Resolved Since Last Iteration (if applicable)
- [Iteration N Issue M] ...
(or "None" / "N/A")

## Remaining Blockers (Critical/High only; max 5)

### Issue 1: [Title]
**Severity**: [Critical/High]
**Type**: [Carryover/New]
**Tracking**: [e.g., Iteration 4 Issue 2, or "New"]
**Location**: [Section heading or line reference in the design doc]
**Problem**: [What's still wrong or missing]
**Acceptance Criteria**: [Concrete check that proves it is resolved]
**Recommendation**: [Specific, minimal doc change]

### Issue 2: [Title]
...
(continue up to Issue 5 max)

## Backlog (non-blocking, optional, max 5 bullets)
- ...

## Additional Blockers (grouped, optional)
- [Theme]: [1 line]

## Conclusion
- If READY, include the exact NO_MORE_ISSUES line on its own line
- If BLOCKED, state what must be fixed next before another review iteration

---

IMPORTANT:
- Do not exceed the blocker limits above
- Prefer closing existing issues over finding new ones
- Merge duplicates/overlapping items into one root-cause issue
- Do NOT propose new features; focus on correctness, safety, and internal consistency
- Be constructive but rigorous
EOF

    echo -e "${CYAN}>>> Codex reviewing design document...${NC}"

    # Run Codex and capture raw output
    CODEX_RAW=$(mktemp)
    codex exec -C "$PROJECT_ROOT" "$CODEX_PROMPT" > "$CODEX_RAW" 2>&1

    # Extract only the actual response (between "codex" line and "tokens used" line)
    # This filters out: header info, user prompt echo, thinking process
    sed -n '/^codex$/,/^tokens used$/p' "$CODEX_RAW" | sed '1d;$d' > "$REVIEW_LOG"
    rm -f "$CODEX_RAW"

    if [ ! -s "$REVIEW_LOG" ]; then
        echo -e "${YELLOW}>>> Review log not created (Codex may have been interrupted)${NC}"
        echo -e "${CYAN}Expected file:${NC} $REVIEW_LOG"
        exit_safely "Codex review interrupted"
    fi

    echo -e "${GREEN}>>> Review saved to: ${NC}review-log-iteration-${iteration}.md"

    # Check if Codex found no more issues
    if grep -q "NO_MORE_ISSUES" "$REVIEW_LOG"; then
        echo ""
        echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${GREEN}║  SUCCESS! Review Architect found no more issues            ║${NC}"
        echo -e "${BOLD}${GREEN}║  Design review complete after $iteration iteration(s)                  ║${NC}"
        echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${CYAN}Final review log:${NC} $REVIEW_LOG"
        echo -e "${CYAN}Logs directory:${NC} $LOGS_DIR"
        exit 0
    fi

    # ============================================
    # Phase 2: Working Architect (Claude Code) - Address Issues
    # ============================================
    echo ""
    echo -e "${BOLD}${MAGENTA}▶ PHASE 2: Working Architect (Claude Code / Opus 4.5)${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}>>> Claude Code will now address issues interactively...${NC}"
    echo ""

    # Build prompt for Claude Code
    read -r -d '' CLAUDE_PROMPT <<EOF || true
You are a senior experienced architect working on improving a design document based on review feedback.

## Context
- Design document: $DESIGN_DOC_REL
- Review feedback: $REVIEW_LOG (iteration $iteration)

## Your Task
1. Read the review log at $REVIEW_LOG
2. Read the current design document at $DESIGN_DOC_REL
3. For EACH blocker issue identified in the review ("Remaining Blockers" section):
   a. Discuss the issue and your proposed solution with the user
   b. After user agrees, update the design document ($DESIGN_DOC_REL)
   c. Move to the next issue
4. After ALL blocker issues are addressed, create a work log summarizing what you did

## Work Log Format (save to $WORK_LOG)
Create a markdown file with:

# Work Log - Iteration $iteration

## Issues Addressed

### Issue 1: [Title from review]
**Original Concern**: [What the reviewer said]
**Solution Implemented**: [What you changed]
**Files Modified**: [List of files]

### Issue 2: [Title from review]
...

## Summary
[Brief summary of all changes made]

---

## Important Instructions
- Work through issues ONE BY ONE with the user
- Prioritize Critical/High blockers; treat "Backlog (non-blocking)" as optional unless the user asks
- ASK the user before making changes if the solution approach is unclear
- Actually EDIT the design document file to make the changes
- Be thorough but don't over-engineer
- After completing all issues, save the work log to: $WORK_LOG
- The work log should ONLY contain the issues addressed and solutions implemented
- Do NOT include any thinking process, reasoning, or internal deliberation in the work log
- Keep the work log concise and focused on WHAT was changed, not WHY you thought about it
- After saving the work log, type /exit to end the session so the review loop can continue
EOF

    # Run Claude Code interactively (no --verbose to avoid extra output)
    echo "$CLAUDE_PROMPT" | claude --permission-mode acceptEdits

    if [ ! -s "$WORK_LOG" ]; then
        echo -e "${YELLOW}>>> Work log not created (Claude session may have been interrupted)${NC}"
        echo -e "${CYAN}Expected file:${NC} $WORK_LOG"
        exit_safely "Claude session interrupted"
    fi

    echo ""
    echo -e "${GREEN}>>> Work log saved to: ${NC}work-log-iteration-${iteration}.md"

    # ============================================
    # Iteration Complete
    # ============================================
    echo ""
    echo -e "${BOLD}${BLUE}┌─ ITERATION $iteration COMPLETE ────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}  Review log: review-log-iteration-${iteration}.md"
    echo -e "${BLUE}│${NC}  Work log:   work-log-iteration-${iteration}.md"
    echo -e "${BOLD}${BLUE}└──────────────────────────────────────────────────────────────┘${NC}"

    if [ "$iteration" -lt "$MAX_ITERATIONS" ]; then
        echo ""
        echo -e "${YELLOW}>>> Starting next iteration...${NC}"
    fi
done

# Max iterations reached
echo ""
echo -e "${BOLD}${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║  MAX ITERATIONS REACHED ($MAX_ITERATIONS)                               ║${NC}"
echo -e "${BOLD}${YELLOW}║  Review may need more iterations                           ║${NC}"
echo -e "${BOLD}${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Logs directory:${NC} $LOGS_DIR"
echo ""
echo "You can continue manually or re-run with more iterations."

exit 0
