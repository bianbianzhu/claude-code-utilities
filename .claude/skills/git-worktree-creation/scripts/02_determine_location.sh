#!/bin/bash
# 02_determine_location.sh - Determine worktree directory location
# Checks: .worktrees/ > worktrees/ > CLAUDE.md config > needs user input
# Outputs: JSON with location info or prompts for user decision

set -e

STATE_FILE=".claude/.worktree-state.json"

# Read state
if [[ ! -f "$STATE_FILE" ]]; then
  cat << 'EOF'
{
  "status": "error",
  "error": "State file not found. Run 01_verify_git.sh first.",
  "next_action": "stop"
}
EOF
  exit 1
fi

repo_root=$(jq -r '.repo_root' "$STATE_FILE")
cd "$repo_root"

location=""
location_type=""
needs_user_input=false

# Priority 1: Check for hidden .worktrees directory
if [[ -d ".worktrees" ]]; then
  location=".worktrees"
  location_type="project-local-hidden"
# Priority 2: Check for visible worktrees directory
elif [[ -d "worktrees" ]]; then
  location="worktrees"
  location_type="project-local"
# Priority 3: Check CLAUDE.md for configuration
elif [[ -f "CLAUDE.md" ]]; then
  # Look for worktree directory configuration in CLAUDE.md
  claude_config=$(grep -iE "worktree.*director|worktrees.*location" CLAUDE.md 2>/dev/null | head -1 || true)
  if [[ -n "$claude_config" ]]; then
    # Try to extract path from the config line
    extracted_path=$(echo "$claude_config" | grep -oE '`[^`]+`|"[^"]+"' | tr -d '`"' | head -1 || true)
    if [[ -n "$extracted_path" ]]; then
      location="$extracted_path"
      location_type="claude-md-config"
    fi
  fi
fi

# If no location found, need user input
if [[ -z "$location" ]]; then
  needs_user_input=true
fi

# Update state file
if [[ -n "$location" ]]; then
  jq --arg loc "$location" --arg type "$location_type" \
    '. + {"step": 2, "location": $loc, "location_type": $type}' \
    "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
else
  jq '. + {"step": 2}' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
fi

# Output result for Claude
if [[ "$needs_user_input" == "true" ]]; then
  cat << 'EOF'
{
  "status": "needs_input",
  "message": "No existing worktree directory found. Please ask user to choose.",
  "options": [
    {
      "value": ".worktrees",
      "label": "Hidden directory (.worktrees/)",
      "description": "Project-local, hidden from file browsers"
    },
    {
      "value": "worktrees",
      "label": "Visible directory (worktrees/)",
      "description": "Project-local, visible in file browsers"
    },
    {
      "value": "~/.worktrees",
      "label": "Global directory (~/.worktrees/)",
      "description": "Shared across all projects"
    }
  ],
  "next_action": "ask_user_location"
}
EOF
else
  cat << EOF
{
  "status": "success",
  "location": "$location",
  "location_type": "$location_type",
  "next_action": "verify_gitignore"
}
EOF
fi
