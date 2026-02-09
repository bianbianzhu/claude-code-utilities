---
name: setup-agent-teams
description: Set up Claude Code agent teams with iTerm2 and tmux split-pane mode on macOS. Only trigger when the user mentions BOTH "setup/configure/install agent teams" AND "tmux" together — e.g. "setup agent teams with tmux", "configure agent teams tmux". Do NOT trigger for general agent teams usage like "create an agent team to review code" — that is starting a workflow, not environment setup.
---

# Setup Agent Teams (iTerm2 + tmux)

Set up the environment for Claude Code agent teams using iTerm2 with tmux control mode (`tmux -CC`). This provides native split-pane display where each teammate gets its own iTerm2 window/tab.

## Prerequisites

- macOS
- Homebrew (`brew`)

## Automated Setup

Run the setup script. It checks each dependency, explains what it does and why, and asks for user permission before every install or config change:

```bash
bash <skill-path>/scripts/setup_agent_teams.sh
```

The script handles:
1. **iTerm2** — install via `brew install --cask iterm2` if missing
2. **tmux** — install via `brew install tmux` if missing
3. **~/.claude/settings.json** — enable `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` (backs up existing config first)
4. **Verify** — confirm all components are correctly installed and configured

## Usage After Setup

```
1. Open iTerm2
2. Run:   tmux -CC
3. In the new iTerm2 window, run:   claude
4. Ask Claude to create an agent team
```

Keep the tmux control window (showing `** tmux mode started **` and Command Menu) open but minimized. To reconnect to a previous session: `tmux -CC attach`.

## Key Concepts

- **tmux -CC** = tmux control mode, iTerm2-specific. Renders tmux panes as native iTerm2 windows instead of text-based splits. Do NOT use the `it2` CLI — it is not needed with this approach.
- **teammateMode** defaults to `"auto"`, which auto-detects tmux. Since this workflow starts `claude` inside a `tmux -CC` session, `"auto"` handles split panes correctly — no explicit override needed.
- **Agent teams are experimental** — known limitations include no session resumption, possible task status lag, and one team per session.

## Troubleshooting

See [references/troubleshooting.md](references/troubleshooting.md) for common issues:
- tmux -CC shows no new window
- Teammates not appearing as split panes
- Orphaned tmux sessions (`tmux ls` / `tmux kill-session -t <name>`)
- iTerm2 "control sequence" permission prompt → Always Allow
- Verifying settings manually
