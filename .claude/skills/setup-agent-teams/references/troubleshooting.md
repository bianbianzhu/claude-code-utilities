# Troubleshooting Agent Teams with iTerm2 + tmux

## Table of Contents

- [tmux -CC shows nothing / no new window](#tmux--cc-shows-nothing--no-new-window)
- [Teammates not appearing as split panes](#teammates-not-appearing-as-split-panes)
- [Orphaned tmux sessions](#orphaned-tmux-sessions)
- [iTerm2 "control sequence" permission prompt](#iterm2-control-sequence-permission-prompt)
- [Too many permission prompts from teammates](#too-many-permission-prompts-from-teammates)
- [Teammates stopping on errors](#teammates-stopping-on-errors)
- [Lead shuts down before work is done](#lead-shuts-down-before-work-is-done)
- [Session resumption does not restore teammates](#session-resumption-does-not-restore-teammates)
- [Verifying settings manually](#verifying-settings-manually)

## tmux -CC shows nothing / no new window

**Symptom**: Running `tmux -CC` in iTerm2 shows `** tmux mode started **` but no new window appears.

**Fix**:
1. Ensure you are running inside **iTerm2**, not Terminal.app or another emulator
2. Check iTerm2 version is up to date: `iTerm2 → Check for Updates`
3. Try killing any existing tmux sessions first:
   ```bash
   tmux kill-server
   tmux -CC
   ```

## Teammates not appearing as split panes

**Symptom**: Agent team created but all teammates run inside the main terminal (in-process mode).

**Fix**:
1. Verify you started Claude **inside a tmux session** (`tmux -CC` first, then `claude` in the new window)
2. Check the env variable:
   ```bash
   echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
   ```
   Must be `1`
3. `teammateMode` defaults to `"auto"`, which detects tmux automatically. Make sure you started `claude` inside a `tmux -CC` session.

## Orphaned tmux sessions

**Symptom**: After team cleanup, tmux sessions persist.

**Fix**:
```bash
# List all sessions
tmux ls

# Kill a specific session
tmux kill-session -t <session-name>

# Nuclear option: kill all tmux sessions
tmux kill-server
```

## iTerm2 "control sequence" permission prompt

**Symptom**: iTerm2 shows "A control sequence attempted to clear scrollback history. Allow in the future?"

**Explanation**: Claude Code sends terminal escape codes to clear the screen. This is normal.

**Fix**: Click **Always Allow** (⌥A). No security risk.

## Too many permission prompts from teammates

**Symptom**: Teammates constantly ask for tool permissions, interrupting workflow.

**Fix**: Pre-approve common operations in Claude Code permission settings before spawning teammates. Or use `--dangerously-skip-permissions` for the lead session (all teammates inherit it).

## Teammates stopping on errors

**Symptom**: A teammate encounters an error and stops working instead of recovering.

**Fix**:
- In split-pane mode: click into the teammate's pane, give it instructions to retry
- Tell the lead to spawn a replacement teammate
- Provide more specific context in the spawn prompt to avoid the error

## Lead shuts down before work is done

**Symptom**: The lead decides the team is finished while tasks are still incomplete.

**Fix**: Tell the lead:
```
Wait for your teammates to complete their tasks before proceeding
```
Or use delegate mode (Shift+Tab) to prevent the lead from doing implementation work.

## Session resumption does not restore teammates

**Symptom**: After `/resume` or `/rewind`, the lead tries to message teammates that no longer exist.

**Explanation**: This is a known limitation. `/resume` and `/rewind` do not restore in-process teammates.

**Fix**: Tell the lead to spawn new teammates.

## Verifying settings manually

Check everything is configured correctly:

```bash
# 1. iTerm2 installed?
ls /Applications/iTerm.app || ls ~/Applications/iTerm.app

# 2. tmux installed?
tmux -V

# 3. Agent teams enabled?
cat ~/.claude/settings.json
# Should contain: "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
```
