#!/bin/bash
# 03_verify_gitignore.sh - Verify and update .gitignore for project-local directories
# Skips if location is global (outside project)
# Outputs: JSON with gitignore status

set -e

STATE_FILE=".claude/.worktree-state.json"

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
location=$(jq -r '.location' "$STATE_FILE")
location_type=$(jq -r '.location_type' "$STATE_FILE")

cd "$repo_root"

# Skip for global directories
if [[ "$location_type" == "global" ]]; then
  jq '. + {"step": 3, "gitignore_status": "skipped_global"}' \
    "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

  cat << 'EOF'
{
  "status": "success",
  "gitignore_status": "skipped",
  "reason": "Global directory does not need .gitignore entry",
  "next_action": "validate_branch"
}
EOF
  exit 0
fi

# Normalize location for gitignore pattern
gitignore_pattern="${location%/}/"

# Check if already in .gitignore
already_ignored=false
if [[ -f ".gitignore" ]]; then
  if grep -qF "$gitignore_pattern" .gitignore 2>/dev/null || \
     grep -qF "${location%/}" .gitignore 2>/dev/null; then
    already_ignored=true
  fi
fi

added_to_gitignore=false
if [[ "$already_ignored" == "false" ]]; then
  # Add to .gitignore
  echo "" >> .gitignore
  echo "# Git worktrees directory" >> .gitignore
  echo "$gitignore_pattern" >> .gitignore
  added_to_gitignore=true
fi

# Update state file
jq --arg status "$([ "$added_to_gitignore" == "true" ] && echo "added" || echo "already_ignored")" \
  '. + {"step": 3, "gitignore_status": $status}' \
  "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

if [[ "$added_to_gitignore" == "true" ]]; then
  cat << EOF
{
  "status": "success",
  "gitignore_status": "added",
  "pattern": "$gitignore_pattern",
  "message": "Added $gitignore_pattern to .gitignore",
  "next_action": "validate_branch"
}
EOF
else
  cat << EOF
{
  "status": "success",
  "gitignore_status": "already_ignored",
  "pattern": "$gitignore_pattern",
  "message": "Directory already in .gitignore",
  "next_action": "validate_branch"
}
EOF
fi
