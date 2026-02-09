# Broadcast Input to All Panes in iTerm2

tmux has a **synchronize-panes** feature — any keystrokes you type are sent to all panes in the current window simultaneously.

However, `tmux -CC` (control mode) with iTerm2 maps tmux panes/windows to native iTerm2 splits and tabs, and **synchronize-panes generally doesn't work** in this mode.

## Workaround: iTerm2 Broadcast Input

iTerm2 has its own **Broadcast Input** feature: go to **Shell → Broadcast Input**.

### Options

#### 1. Send Input to Current Session Only

<kbd>Shift</kbd> + <kbd>Option</kbd> + <kbd>Cmd</kbd> + <kbd>I</kbd>

The default — your keystrokes only go to the one pane you're focused on. Normal behavior.

#### 2. Broadcast Input to All Panes in All Tabs

<kbd>Shift</kbd> + <kbd>Cmd</kbd> + <kbd>I</kbd>

Every keystroke goes to every pane across every tab/window in the iTerm2 window. Useful if you have multiple servers spread across different tabs and want to run the same command everywhere.

#### 3. Broadcast Input to All Panes in Current Tab

<kbd>Option</kbd> + <kbd>Cmd</kbd> + <kbd>I</kbd>

Keystrokes go to all panes/splits within the current tab only. This is the closest equivalent to tmux's `synchronize-panes` — great for when you have one window with 4–5 panes and want to run the same command on all of them.

> **Most commonly used.** Pressing the shortcut again returns to option 1 (current session only).

#### 4. Toggle Broadcast Input to Current Session

<kbd>Shift</kbd> + <kbd>Ctrl</kbd> + <kbd>Option</kbd> + <kbd>Cmd</kbd> + <kbd>I</kbd>

Confusingly named — "Session" here means the iTerm2 session (i.e., a single pane). It toggles whether a specific pane **participates** in broadcasting. So if you have 5 panes broadcasting but want to exclude one, select that pane and use this toggle to opt it out.

## Visual Indicator

When broadcasting is active, iTerm2 can overlay a subtle **background pattern** (diagonal stripes) on panes receiving broadcast input, giving you a visual reminder that typing is going to multiple places.
