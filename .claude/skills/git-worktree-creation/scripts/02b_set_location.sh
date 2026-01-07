#!/bin/bash
# 02b_set_location.sh - Set worktree location from user choice
# Usage: ./02b_set_location.sh <location>
# Example: ./02b_set_location.sh ".worktrees"

set -e

STATE_FILE=".claude/.worktree-state.json"

if [[ -z "$1" ]]; then
  cat << 'EOF'
{
  "status": "error",
  "error": "Location argument required",
  "usage": "./02b_set_location.sh <location>",
  "next_action": "stop"
}
EOF
  exit 1
fi

location="$1"

# Determine location type
location_type="project-local"
if [[ "$location" == .* ]]; then
  location_type="project-local-hidden"
elif [[ "$location" == ~/* || "$location" == /* ]]; then
  location_type="global"
fi

# Update state file
jq --arg loc "$location" --arg type "$location_type" \
  '. + {"location": $loc, "location_type": $type}' \
  "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

cat << EOF
{
  "status": "success",
  "location": "$location",
  "location_type": "$location_type",
  "next_action": "verify_gitignore"
}
EOF
