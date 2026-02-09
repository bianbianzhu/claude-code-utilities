#!/usr/bin/env bash
# setup_agent_teams.sh — Interactive setup for Claude Code Agent Teams with iTerm2 + tmux
#
# Assumes macOS + Homebrew. Each step explains what it does and asks for confirmation.
# Usage: bash scripts/setup_agent_teams.sh

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

step=0

info()  { echo -e "${BLUE}ℹ ${NC}$*"; }
ok()    { echo -e "${GREEN}✓ ${NC}$*"; }
warn()  { echo -e "${YELLOW}⚠ ${NC}$*"; }
err()   { echo -e "${RED}✗ ${NC}$*"; }

ask_permission() {
  echo ""
  echo -e "${YELLOW}→ $1${NC}"
  echo -e "  $2"
  echo ""
  read -rp "  Proceed? [Y/n] " answer
  case "${answer:-Y}" in
    [Yy]*) return 0 ;;
    *) warn "Skipped."; return 1 ;;
  esac
}

next_step() {
  step=$((step + 1))
  echo ""
  echo -e "${GREEN}━━━ Step $step: $1 ━━━${NC}"
}

# ─── Pre-flight checks ───────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Claude Code Agent Teams Setup (iTerm2 + tmux)     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Check macOS
if [[ "$(uname)" != "Darwin" ]]; then
  err "This script is designed for macOS. Detected: $(uname)"
  exit 1
fi
ok "macOS detected"

# Check Homebrew
if ! command -v brew &>/dev/null; then
  err "Homebrew is not installed."
  echo "  Install it first: https://brew.sh"
  exit 1
fi
ok "Homebrew found: $(brew --prefix)"

# ─── Step 1: iTerm2 ──────────────────────────────────────────────────

next_step "Install iTerm2"

if [[ -d "/Applications/iTerm.app" ]]; then
  ok "iTerm2 is already installed at /Applications/iTerm.app"
else
  if ask_permission \
    "Install iTerm2 via Homebrew?" \
    "iTerm2 is a terminal emulator that natively integrates with tmux, providing a better split-pane experience than the default Terminal.app. Claude Code agent teams use this integration to display each teammate in its own native iTerm2 window/tab."; then
    brew install --cask iterm2
    ok "iTerm2 installed"
  fi
fi

# ─── Step 2: tmux ────────────────────────────────────────────────────

next_step "Install tmux"

if command -v tmux &>/dev/null; then
  ok "tmux is already installed: $(tmux -V)"
else
  if ask_permission \
    "Install tmux via Homebrew?" \
    "tmux is a terminal multiplexer. When combined with iTerm2's control mode (tmux -CC), tmux panes are rendered as native iTerm2 windows — this is how Claude Code creates separate panels for each agent teammate."; then
    brew install tmux
    ok "tmux installed: $(tmux -V)"
  fi
fi

# ─── Step 3: Claude Code settings.json ───────────────────────────────

next_step "Configure Claude Code settings"

SETTINGS_DIR="$HOME/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

info "Claude Code needs one setting:"
info "  CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1  — enables the agent teams feature"
info "  (teammateMode defaults to \"auto\", which auto-detects tmux — no override needed)"
echo ""

# Check if already configured
ALREADY_CONFIGURED=false
if [[ -f "$SETTINGS_FILE" ]]; then
  if python3 -c "
import json, sys
with open('$SETTINGS_FILE') as f:
    s = json.load(f)
if s.get('env', {}).get('CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS') == '1':
    sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
    ALREADY_CONFIGURED=true
  fi
fi

if [[ "$ALREADY_CONFIGURED" == "true" ]]; then
  ok "Agent teams already enabled in $SETTINGS_FILE"
  sed 's/^/  /' "$SETTINGS_FILE"
elif ask_permission \
  "$(if [[ -f "$SETTINGS_FILE" ]]; then echo "Update ~/.claude/settings.json?"; else echo "Create ~/.claude/settings.json?"; fi)" \
  "$(if [[ -f "$SETTINGS_FILE" ]]; then echo "This will merge the agent teams setting into your existing config. Existing settings will be preserved. A backup will be created at settings.json.bak."; else echo "This will create a new settings file with the agent teams environment variable."; fi)"; then

  mkdir -p "$SETTINGS_DIR"

  if [[ -f "$SETTINGS_FILE" ]]; then
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"
    ok "Backup created: $SETTINGS_FILE.bak"

    # Use python to merge JSON safely
    python3 -c "
import json, sys

with open('$SETTINGS_FILE', 'r') as f:
    try:
        settings = json.load(f)
    except json.JSONDecodeError:
        settings = {}

# Merge env
env = settings.get('env', {})
env['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'] = '1'
settings['env'] = env

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
"
  else
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
EOF
  fi

  ok "settings.json updated:"
  sed 's/^/  /' "$SETTINGS_FILE"
fi

# ─── Step 4: Verify ──────────────────────────────────────────────────

next_step "Verify setup"

errors=0

# Check iTerm2
if [[ -d "/Applications/iTerm.app" ]]; then
  ok "iTerm2: installed"
else
  err "iTerm2: not found"
  errors=$((errors + 1))
fi

# Check tmux
if command -v tmux &>/dev/null; then
  ok "tmux: $(tmux -V)"
else
  err "tmux: not found"
  errors=$((errors + 1))
fi

# Check settings.json
if [[ -f "$SETTINGS_FILE" ]]; then
  if python3 -c "
import json, sys
with open('$SETTINGS_FILE') as f:
    s = json.load(f)
if s.get('env', {}).get('CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS') != '1':
    print('CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS not set', file=sys.stderr)
    sys.exit(1)
" 2>&1; then
    ok "settings.json: agent teams enabled"
  else
    err "settings.json: missing required settings"
    errors=$((errors + 1))
  fi
else
  err "settings.json: file not found"
  errors=$((errors + 1))
fi

# ─── Summary ──────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $errors -eq 0 ]]; then
  echo ""
  ok "All checks passed! Setup complete."
  echo ""
  info "To start using agent teams:"
  echo "  1. Open iTerm2"
  echo "  2. Run:  tmux -CC"
  echo "  3. In the new iTerm2 window, run:  claude"
  echo "  4. Ask Claude to create an agent team"
  echo ""
  info "Tip: Keep the tmux control window (showing Command Menu) open but minimized."
  info "Tip: To reconnect later:  tmux -CC attach"
else
  echo ""
  err "$errors check(s) failed. Review the errors above and re-run this script."
fi
