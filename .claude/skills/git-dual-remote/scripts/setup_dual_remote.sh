#!/bin/bash
# Setup dual remote git configuration
# Usage: ./setup_dual_remote.sh <mirror_url> [all_remote_name]
#
# Example:
#   ./setup_dual_remote.sh git@github.com:company/repo.git
#   ./setup_dual_remote.sh git@github.com:company/repo.git all

set -e

MIRROR_URL="${1:-}"
ALL_REMOTE_NAME="${2:-all}"

if [ -z "$MIRROR_URL" ]; then
    echo "Error: Mirror URL is required"
    echo "Usage: $0 <mirror_url> [all_remote_name]"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not inside a git repository"
    exit 1
fi

# Get origin URL
ORIGIN_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [ -z "$ORIGIN_URL" ]; then
    echo "Error: No 'origin' remote found"
    exit 1
fi

echo "Setting up dual remote configuration..."
echo "  Origin URL: $ORIGIN_URL"
echo "  Mirror URL: $MIRROR_URL"
echo "  All remote name: $ALL_REMOTE_NAME"
echo ""

# Add mirror remote if it doesn't exist
if git remote get-url mirror > /dev/null 2>&1; then
    echo "Remote 'mirror' already exists, updating URL..."
    git remote set-url mirror "$MIRROR_URL"
else
    echo "Adding 'mirror' remote..."
    git remote add mirror "$MIRROR_URL"
fi

# Add 'all' remote if it doesn't exist
if git remote get-url "$ALL_REMOTE_NAME" > /dev/null 2>&1; then
    echo "Remote '$ALL_REMOTE_NAME' already exists, reconfiguring..."
    git remote remove "$ALL_REMOTE_NAME"
fi

echo "Adding '$ALL_REMOTE_NAME' remote with dual push URLs..."
git remote add "$ALL_REMOTE_NAME" "$ORIGIN_URL"
git remote set-url --add --push "$ALL_REMOTE_NAME" "$ORIGIN_URL"
git remote set-url --add --push "$ALL_REMOTE_NAME" "$MIRROR_URL"

echo ""
echo "✅ Dual remote configuration complete!"
echo ""
echo "Current remote configuration:"
git remote -v
echo ""
echo "Usage:"
echo "  git push $ALL_REMOTE_NAME <branch>  # Push to both remotes"
echo "  git push origin <branch>            # Push to origin only"
echo "  git push mirror <branch>            # Push to mirror only"
