# start a session in Control Mode

tmux -CC

# start a new **named** session in Control Mode

tmux -CC new -s <session_name>

# list all sessions

tmux ls

# kill a session by id

tmux kill-session -t <session-id>

# kill a session by name

tmux kill-session -t <session-name>

# attach to a session in Control Mode

tmux -CC attach -t <session-id>

# attach to a session by name in Control Mode

tmux -CC attach -t <session-name>
