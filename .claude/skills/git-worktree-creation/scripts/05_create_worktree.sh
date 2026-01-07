#!/bin/bash
# 05_create_worktree.sh - Create the git worktree
# Builds path, creates directories, creates worktree, runs project setup
# Outputs: JSON with creation status and worktree path

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
project=$(jq -r '.project' "$STATE_FILE")
location=$(jq -r '.location' "$STATE_FILE")
location_type=$(jq -r '.location_type' "$STATE_FILE")
branch_name=$(jq -r '.branch_name' "$STATE_FILE")
branch_exists_local=$(jq -r '.branch_exists_local' "$STATE_FILE")
branch_exists_remote=$(jq -r '.branch_exists_remote' "$STATE_FILE")

cd "$repo_root"

# Build worktree path
# Handle slashes in branch names (e.g., feature/auth -> feature/auth directory)
if [[ "$location_type" == "global" ]]; then
  # Global: ~/.worktrees/project-name/branch-name
  expanded_location="${location/#\~/$HOME}"
  worktree_path="$expanded_location/$project/$branch_name"
else
  # Project-local: location/branch-name
  worktree_path="$location/$branch_name"
fi

# Verify worktree path doesn't already exist
if [[ -d "$worktree_path" ]]; then
  cat << EOF
{
  "status": "error",
  "error": "Worktree path already exists",
  "worktree_path": "$worktree_path",
  "next_action": "stop"
}
EOF
  exit 1
fi

# Create parent directories
mkdir -p "$(dirname "$worktree_path")"

# Create the worktree
if [[ "$branch_exists_local" == "true" ]]; then
  # Use existing local branch
  git worktree add "$worktree_path" "$branch_name"
elif [[ "$branch_exists_remote" == "true" ]]; then
  # Track existing remote branch
  git worktree add "$worktree_path" -b "$branch_name" "origin/$branch_name"
else
  # Create new branch from current HEAD
  git worktree add -b "$branch_name" "$worktree_path"
fi

# Detect and run project setup
setup_commands=()
setup_ran=false

cd "$worktree_path"

# Node.js project
if [[ -f "package.json" ]]; then
  if [[ -f "package-lock.json" ]]; then
    npm ci 2>/dev/null && setup_ran=true
    setup_commands+=("npm ci")
  elif [[ -f "yarn.lock" ]]; then
    yarn install 2>/dev/null && setup_ran=true
    setup_commands+=("yarn install")
  elif [[ -f "pnpm-lock.yaml" ]]; then
    pnpm install 2>/dev/null && setup_ran=true
    setup_commands+=("pnpm install")
  else
    npm install 2>/dev/null && setup_ran=true
    setup_commands+=("npm install")
  fi
fi

# Rust project
if [[ -f "Cargo.toml" ]]; then
  cargo fetch 2>/dev/null && setup_ran=true
  setup_commands+=("cargo fetch")
fi

# Python project with requirements
if [[ -f "requirements.txt" ]]; then
  if [[ -f ".python-version" ]]; then
    # pyenv environment
    setup_commands+=("pyenv: requirements.txt detected")
  else
    setup_commands+=("pip install -r requirements.txt (manual)")
  fi
fi

# Go project
if [[ -f "go.mod" ]]; then
  go mod download 2>/dev/null && setup_ran=true
  setup_commands+=("go mod download")
fi

# Update state file with final path
cd "$repo_root"
jq --arg path "$worktree_path" \
   --arg setup "$setup_ran" \
  '. + {
    "step": 5,
    "worktree_path": $path,
    "setup_completed": ($setup == "true")
  }' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

# Build setup info for output
setup_info=""
if [[ ${#setup_commands[@]} -gt 0 ]]; then
  setup_info=$(printf '%s\n' "${setup_commands[@]}" | jq -R . | jq -s .)
else
  setup_info="[]"
fi

# Get absolute path for output
if [[ "$worktree_path" != /* ]]; then
  abs_worktree_path="$repo_root/$worktree_path"
else
  abs_worktree_path="$worktree_path"
fi

cat << EOF
{
  "status": "success",
  "worktree_path": "$worktree_path",
  "absolute_path": "$abs_worktree_path",
  "branch_name": "$branch_name",
  "setup_completed": $setup_ran,
  "setup_commands": $setup_info,
  "message": "Worktree created successfully at $worktree_path",
  "next_action": "complete"
}
EOF
