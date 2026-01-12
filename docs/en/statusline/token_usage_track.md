# Context Window Usage

Display the percentage of context window consumed. The context_window object contains:

- **total_input_tokens / total_output_tokens**: Cumulative totals across the entire session

- **current_usage**: Current context window usage from the last API call (may be null if no messages yet)
  - **input_tokens**: Input tokens in current context
  - **output_tokens**: Output tokens generated
  - **cache_creation_input_tokens**: Tokens written to cache
  - **cache_read_input_tokens**: Tokens read from cache

For accurate context percentage, use **current_usage** which reflects the actual context window state.

## Steps:

1. Create a new file `~/.claude/statusline.sh` with the following content:

```bash
#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size')
USAGE=$(echo "$input" | jq '.context_window.current_usage')

if [ "$USAGE" != "null" ]; then
    # Calculate current context from current_usage fields
    CURRENT_TOKENS=$(echo "$USAGE" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    PERCENT_USED=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
    echo "[$MODEL] Context: ${PERCENT_USED}%"
else
    echo "[$MODEL] Context: 0%"
fi
```

2. Make the script executable:

```bash
chmod +x ~/.claude/statusline.sh
```

3. Add the script to your `~/.claude/settings.json` file (user scope):

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
    "padding": 0
  }
}
```

or `.claude/settings.json` (project scope).
or `.claude/settings.local.json` (project local scope).

## Troubleshooting

- If your status line doesn’t appear, check that your script is executable (**chmod +x**)
- Ensure your script outputs to stdout (not stderr)
