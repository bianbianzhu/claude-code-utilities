#!/bin/bash
# 01_verify_git.sh - Verify git repository and initialize state file
# Outputs: JSON with repo_root, project name, and status

set -e

STATE_FILE=".claude/.worktree-state.json"

# Ensure .claude directory exists
mkdir -p .claude

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  cat << 'EOF'
{
  "status": "error",
  "error": "Not in a git repository",
  "next_action": "stop"
}
EOF
  exit 1
fi

# Get repository root and project name
repo_root=$(git rev-parse --show-toplevel)
project=$(basename "$repo_root")

# Initialize state file
cat > "$STATE_FILE" << EOF
{
  "step": 1,
  "repo_root": "$repo_root",
  "project": "$project"
}
EOF

# Output result for Claude
cat << EOF
{
  "status": "success",
  "repo_root": "$repo_root",
  "project": "$project",
  "next_action": "determine_location"
}
EOF
