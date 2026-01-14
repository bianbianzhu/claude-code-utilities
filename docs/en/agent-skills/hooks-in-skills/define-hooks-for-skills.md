# Define hooks for Skills

Skills can define hooks that run during the Skill's lifecycle.

Use the `hooks` field to specify `PreToolUse`, `PostToolUse`, or `Stop` handlers:

Only supported events: `PreToolUse`, `PostToolUse`, and `Stop`

```yaml theme={null}
---
name: secure-operations
description: Perform operations with additional security checks
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/security-check.sh"
          once: true
---
```

- `once: true` option runs the hook only once per session. After the first successful execution, the hook is removed.

- Hooks defined in a Skill (component-scoped hooks) are scoped to that Skill's execution and are `automatically cleaned up` when the Skill finishes.

## Python Script Examples:

```yaml theme={null}
---
hooks:
  PreToolUse:
    - matcher: "Write|Edit|Bash|Read|AskUserQuestion"
      hooks:
        - type: command
          command: "uv run /Users/<user_name>/<project_name>/<script_name>.py"
---
```

The python script is a simple script that logs the input data to a file.

- Receives JSON via stdin
- Must use `os.path.expanduser` to expand the user's home dir (`~/.claude/bash-command-log.txt`)
- Use PEP 723 inline metadata

```python
#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
import json
import sys
import os

input_data = json.load(sys.stdin) # 👈 all PreToolUse input is passed to the script via stdin

log_path = os.path.expanduser("~/.claude/bash-command-log.txt")
with open(log_path, "a") as f:
    f.write(json.dumps(input_data) + "\n")

sys.exit(0)
```

**Output**:

```json
{
  "session_id": "<session_id>",
  "transcript_path": "/Users/<user_name>/.claude/projects/-Users-<user_name>-<project_name>/<session_id>.jsonl",
  "cwd": "/Users/<user_name>/<project_name>",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "AskUserQuestion",
  "tool_input": {
    "questions": [
      {
        "question": "What topic would you like a joke about?",
        "header": "Joke topic",
        "options": [
          {
            "label": "Programming",
            "description": "Jokes about coding, bugs, and developer life"
          },
          {
            "label": "Animals",
            "description": "Jokes about creatures great and small"
          },
          { "label": "Food", "description": "Jokes about eating and cuisine" },
          {
            "label": "Science",
            "description": "Jokes about physics, chemistry, and more"
          }
        ],
        "multiSelect": false
      }
    ]
  },
  "tool_use_id": "toolu_018T5XMF381n1DQ5gTN8S7Cn"
}
```

```json
{
  "session_id": "<session_id>",
  "transcript_path": "/Users/<user_name>/.claude/projects/-Users-<user_name>-<project_name>/<session_id>.jsonl",
  "cwd": "/Users/<user_name>/<project_name>",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Read",
  "tool_input": {
    "file_path": "/Users/<user_name>/<project_name>/.claude/skills/<skill_name>/<file_name>.md"
  },
  "tool_use_id": "toolu_01NxbUis4YJLZjCLuE9fjFXW"
}
```

- tool_input may contain different fields depending on the tool. Like `file_path` for `Read` tool, `command` for `Bash` tool, etc.

## Access the variables in the hook command

1. **Access the file path**:
- can use absolute path to the file
- or use `$CLAUDE_PROJECT_DIR` to access the project directory

Log out the project directory:
```yaml
command: "echo \"$CLAUDE_PROJECT_DIR\" >> ~/.claude/bash-command-log.txt"
```
Run script under the project directory:
```yaml
command: "\"$CLAUDE_PROJECT_DIR\"/test.sh"
```

2. **JSON data via stdin**:
- hooks also receive JSON data via stdin containing session information like session_id, transcript_path, cwd, permission_mode, and event-specific fields

## Run different scripts in the hook command

1. **Shell with `jq`**:

```yaml
hooks:
  PreToolUse:
    - matcher: "Write|Edit|Bash|Read|AskUserQuestion"
      hooks:
        - type: command
          command: "jq -r '\"\\(.tool_name) - \\(.tool_input)\"' >> ~/.claude/bash-command-log.txt"
```

- jq -r extracts the specific field from the stdin JSON object
- jq's string interpolation syntax is `\(expression)`
- single field: `jq -r '.tool_name'`
- multiple fields: `jq -r '"\(.tool_name) - \(.tool_input.command)"'`
  - need to escape the double quotes and the backslashes. `" -> \"` , `\ -> \\`
- with fallback `jq -r '.tool_input.description // "No description"'`

2. **With bash script**:

```yaml
hooks:
  PreToolUse:
    - matcher: "Write|Edit|Bash|Read|AskUserQuestion"
      hooks:
        - type: command
          command: "/Users/<user_name>/<project_name>/<script_name>.sh"
```

- no need to use `bash xxx.sh` to run the script
- can use absolute path to the script or use `$CLAUDE_PROJECT_DIR` to access the project directory

The script:

```bash
#!/bin/bash

input=$(cat)

tool_input=$(echo $input | jq -r '.tool_input')

echo "🔥 - $tool_input" >> ~/.claude/bash-command-log.txt
```

- use `cat` to read the stdin
- use `jq -r '.tool_input'` to extract the tool_input field
- use `echo "🔥 - $tool_input" >> ~/.claude/bash-command-log.txt` to log the tool_input to the file

or simply inline the bash script:

```yaml theme={null}
hooks:
  PreToolUse:
    - matcher: "Write|Edit|Bash|Read|AskUserQuestion"
      hooks:
        - type: command
          command: 'bash -c ''input=$(cat) && echo "🔥 - $(echo $input | jq -r ''.tool_input'')" >> ~/.claude/bash-command-log.txt'''
```

- use `bash -c` to inline the bash script

3. With Python script:

- Refer the [Python script example](#examples) above
- Use `sys.stdin` to access the input data
- Add any dependencies in the PEP 723 inline metadata's `dependencies` field, like `dependencies = ["PyPDF2"]`


