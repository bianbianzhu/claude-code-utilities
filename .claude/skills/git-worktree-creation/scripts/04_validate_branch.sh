#!/bin/bash
# 04_validate_branch.sh - Validate branch name and check existence
# Usage: ./04_validate_branch.sh <branch_name>
# Outputs: JSON with branch validation status

set -e

STATE_FILE=".claude/.worktree-state.json"

if [[ -z "$1" ]]; then
  cat << 'EOF'
{
  "status": "error",
  "error": "Branch name argument required",
  "usage": "./04_validate_branch.sh <branch_name>",
  "next_action": "stop"
}
EOF
  exit 1
fi

branch_name="$1"

# Read state
if [[ ! -f "$STATE_FILE" ]]; then
  cat << 'EOF'
{
  "status": "error",
  "error": "State file not found",
  "next_action": "stop"
}
EOF
  exit 1
fi

repo_root=$(jq -r '.repo_root' "$STATE_FILE")
cd "$repo_root"

# Validate branch name format using git's built-in validation
if ! git check-ref-format --branch "$branch_name" > /dev/null 2>&1; then
  cat << EOF
{
  "status": "error",
  "error": "Invalid branch name: $branch_name",
  "reason": "Branch name does not conform to git naming rules",
  "next_action": "ask_branch_name"
}
EOF
  exit 1
fi

# Check if branch is already checked out in another worktree
if git worktree list 2>/dev/null | grep -q "\\[$branch_name\\]"; then
  cat << EOF
{
  "status": "error",
  "error": "Branch already in use",
  "branch_name": "$branch_name",
  "reason": "Branch is already checked out in another worktree",
  "next_action": "ask_branch_name"
}
EOF
  exit 1
fi

# Check local and remote branch existence
local_exists=false
remote_exists=false

if git show-ref --verify --quiet "refs/heads/$branch_name" 2>/dev/null; then
  local_exists=true
fi

if git ls-remote --exit-code --heads origin "$branch_name" > /dev/null 2>&1; then
  remote_exists=true
fi

# Update state file
jq --arg name "$branch_name" \
   --argjson local "$local_exists" \
   --argjson remote "$remote_exists" \
  '. + {
    "step": 4,
    "branch_name": $name,
    "branch_exists_local": $local,
    "branch_exists_remote": $remote
  }' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

# Determine if we need user confirmation
needs_confirmation=false
if [[ "$local_exists" == "true" || "$remote_exists" == "true" ]]; then
  needs_confirmation=true
fi

if [[ "$needs_confirmation" == "true" ]]; then
  cat << EOF
{
  "status": "needs_confirmation",
  "branch_name": "$branch_name",
  "branch_exists_local": $local_exists,
  "branch_exists_remote": $remote_exists,
  "message": "Branch '$branch_name' already exists (local: $local_exists, remote: $remote_exists). Use existing branch?",
  "next_action": "ask_user_use_existing"
}
EOF
else
  cat << EOF
{
  "status": "success",
  "branch_name": "$branch_name",
  "branch_exists_local": false,
  "branch_exists_remote": false,
  "message": "Branch name is valid and available",
  "next_action": "create_worktree"
}
EOF
fi
