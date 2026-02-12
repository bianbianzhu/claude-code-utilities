# Background Tasks in Claude Code

## Overview

Claude Code can run various tasks in the background, allowing you to continue working while they execute. Background tasks come in three types:

| Type                | How to launch                            | Use case                                                           |
| ------------------- | ---------------------------------------- | ------------------------------------------------------------------ |
| **Background Bash** | Bash tool with `run_in_background: true` | Builds, test suites, servers, any long-running shell command       |
| **Subagents**       | Task tool with `run_in_background: true` | Complex multi-step research, code exploration, parallel agent work |
| **Remote sessions** | Claude Code remote sessions              | Offloaded work running on a remote machine                         |

All three produce a **task ID** and an **output file path**, and all three can be checked with the same **TaskOutput** tool.

## Workflow

### 1. Launch a background task

**Background Bash:**

Use the **Bash** tool with `run_in_background: true`. Returns a task ID and output file path.

```json
{
  "command": "bash /Users/<user_name>/<project_name>/docs/en/background-tasks/long-running-bash.sh",
  "description": "Run long-running bash script in background",
  "timeout": 30000,
  "run_in_background": true
}
```

**Subagents:**

Use the **Task** tool with `run_in_background: true`. The agent runs autonomously in the background — researching, exploring, or executing multi-step work — and returns results when done.

**Remote sessions:**

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

It counts from 1 to 10 with a 1-second delay between each step (~10 seconds total), useful for testing the background task workflow.

## Tips

- You can run **multiple background tasks in parallel** — for example, kick off a build, a linter, and a subagent exploration all at the same time, then check results later.
- Use `block: false` with `TaskOutput` to monitor progress without waiting for completion.
- The output file persists on disk, so you can read it even after the task finishes.
- Subagent results are also delivered as notifications when they complete, so you'll be alerted automatically.
