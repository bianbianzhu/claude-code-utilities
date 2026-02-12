# Background Tasks in Claude Code

## Overview

Claude Code can run various tasks in the background, allowing you to continue working while they execute. Background tasks come in three types:

| Type                | How to launch                            | Use case                                                           |
| ------------------- | ---------------------------------------- | ------------------------------------------------------------------ |
| **Background Bash** | Bash tool with `run_in_background: true` | Builds, test suites, servers, any long-running shell command       |
| **Subagents**       | Task tool with `run_in_background: true` | Complex multi-step research, code exploration, parallel agent work |
| **Remote sessions** | Claude Code remote sessions              | Offloaded work running on a remote machine                         |

All three produce a **task ID** and an **output file path**, and all three can be checked with the same **TaskOutput** tool.

## Workflow (without TaskOutput tool)

### 1. Launch a background task

#### **Background Bash:**

Step 1 - User prompt:

```json
{
  "role": "user",
  "content": "run the @docs/en/background-tasks/long-running-bash.sh in background"
}
```

Step 2 - Claude Code uses the **Bash** tool with `run_in_background: true`. Returns a task ID and output file path.

tool_input:

```json
{
  "command": "bash /Users/<user_name>/<project_name>/docs/en/background-tasks/long-running-bash.sh",
  "description": "Run long-running bash script in background",
  "timeout": 30000,
  "run_in_background": true
}
```

tool_output:

```markdown
"Command running in background with ID: bcc53f3. Output is being written to: /private/tmp/claude-502/-Users-<user_name>-<project_name>/tasks/bcc53f3.output"
```

Step 3 - Claude code responds immediately with the task ID

```json
{
  "role": "assistant",
  "content": "The script is running in the background (task ID: `bcc53f3`). It'll count from 1 to 10 with 1-second delays. I'll be notified when it completes, or you can ask me to check its output anytime."
}
```

Step 4 - after the script finishes, claude code automatically get notified (a user message will be passed to claude code).

```json
{
  "role": "user",
  "content": "<task-notification>\n<task-id>bcc53f3</task-id>\n<output-file>/private/tmp/claude-502/-Users-<user_name>-<project_name>/tasks/bcc53f3.output</output-file>\n<status>completed</status>\n<summary>Background command \"Run long-running test script in background\" completed (exit code 0)</summary>\n</task-notification>\nRead the output file to retrieve the result: /private/tmp/claude-502/-Users-<user_name>-<project_name>/tasks/bcc53f3.output"
}
```

Step 5 - Claude Code reads the output file to get the result.

tool_input:

```json
{
  "file_path": "/private/tmp/claude-502/-Users-<user_name>-<project_name>/tasks/bcc53f3.output"
}
```

tool_output:

```markdown
     1→Step 1 of 10...
     ...
    11→Done! The secret phrase is: '🌽 is a cat'
```

Step 6 - Claude Code responds with the result.

```json
{
  "role": "assistant",
  "content": "The script completed successfully — all 10 steps ran and the secret phrase is: **🌽 is a cat**."
}
```

#### **Subagents:**

Use the **Task** tool with `run_in_background: true`. The agent runs autonomously in the background — researching, exploring, or executing multi-step work — and returns results when done.

Step 1 - User prompt:

```json
{
  "role": "user",
  "content": "spawn a background subagent and use it to do a Websearch on the openclaw's release date."
}
```

Step 2 - Claude Code uses the **Task** tool with `run_in_background: true`. Returns an agentId and output file path.

tool_input:

```json
{
  "description": "Search OpenClaw release date",
  "prompt": "Do a web search to find the release date of \"OpenClaw\". Report back with the release date and any relevant details you find.",
  "subagent_type": "general-purpose",
  "run_in_background": true
}
```

tool_output:

```json
[
  {
    "type": "text",
    "text": "Async agent launched successfully.\nagentId: a51202c (internal ID - do not mention to user. Use to resume later if needed.)\nThe agent is working in the background. You will be notified automatically when it completes.\nContinue with other tasks.\noutput_file: /private/tmp/claude-502/-Users-<user_name>-<project_name>/tasks/a51202c.output\nTo check progress before completion (optional), use Read or Bash tail on the output file."
  }
]
```

Step 3 - Claude Code responds immediately (without a agentId)

```json
{
  "role": "assistant",
  "content": "I've spawned a background agent to search for OpenClaw's release date. I'll let you know the results once it finishes. You can continue working on other things in the meantime."
}
```

#### **Remote sessions:**

Remote sessions also produce task IDs that can be checked with TaskOutput.

### 2. Retrieve the result

All background task types share the same retrieval methods:

| Approach                      | How                                | Best for                     |
| ----------------------------- | ---------------------------------- | ---------------------------- |
| **TaskOutput** (blocking)     | `TaskOutput(task_id, block=true)`  | Waiting for the final result |
| **TaskOutput** (non-blocking) | `TaskOutput(task_id, block=false)` | Peeking at progress mid-run  |
| **Read** the output file      | `Read(output_file_path)`           | Reading raw output anytime   |

## TaskOutput Tool Reference

### Purpose

Retrieves output from a running or completed background task — whether it's a background shell, an async subagent, or a remote session.

### Parameters

| Parameter | Type    | Default | Required | Description                                                        |
| --------- | ------- | ------- | -------- | ------------------------------------------------------------------ |
| `task_id` | string  | —       | Yes      | The ID of the background task to check                             |
| `block`   | boolean | `true`  | No       | Whether to wait for the task to complete before returning          |
| `timeout` | number  | `30000` | No       | Max wait time in milliseconds (range: 0–600,000 ms / up to 10 min) |

### Behavior

- **`block: true`** (default) — Waits until the task finishes (or until `timeout` is reached), then returns the full output and status.
- **`block: false`** — Returns immediately with whatever output is available so far. Useful for checking progress on a still-running task without waiting.

### Return value

- **Status** — whether the task is still running or completed
- **Exit code** — the process exit code (`0` = success, applies to Bash tasks)
- **Output** — stdout/result from the task

### TaskOutput vs. Reading the output file

| Approach                  | Pros                                                       | Cons                                               |
| ------------------------- | ---------------------------------------------------------- | -------------------------------------------------- |
| `TaskOutput`              | Blocking/non-blocking modes; structured status + exit code | Only works while the Claude Code session is active |
| `Read` on the output file | Works anytime, even after the session ends                 | No status or exit code info, just raw text         |

## When to use background tasks

### Background Bash

**Good candidates:**

- Long builds (`npm run build`, `cargo build`)
- Test suites (`pytest`, `npm test`)
- Server startup (`npm run dev`, `uvicorn ...`)
- Any shell command that might take more than a few seconds

**Not recommended:**

- Quick commands where you need the result immediately for the next step
- Commands whose output determines your next action in a chain

### Subagents

**Good candidates:**

- Deep codebase exploration across many files
- Research tasks that require multiple search rounds
- Parallel independent investigations (e.g., launch 3 agents to explore different subsystems)

**Not recommended:**

- Simple file reads or single grep searches (use Glob/Grep directly)
- Tasks where you need the result before your next action

## Example

A test script for background Bash is included in this directory:

```bash
./long-running-bash.sh
```

````

```

It counts from 1 to 10 with a 1-second delay between each step (~10 seconds total), useful for testing the background task workflow.

## Tips

- You can run **multiple background tasks in parallel** — for example, kick off a build, a linter, and a subagent exploration all at the same time, then check results later.
- Use `block: false` with `TaskOutput` to monitor progress without waiting for completion.
- The output file persists on disk, so you can read it even after the task finishes.
- Subagent results are also delivered as notifications when they complete, so you'll be alerted automatically.
```
````
