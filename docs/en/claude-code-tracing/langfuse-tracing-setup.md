# Langfuse Tracing Setup for Claude Code

Send Claude Code conversation traces to [Langfuse](https://langfuse.com) for observability, debugging, and analytics.

## Prerequisites

- [Claude Code](https://code.claude.com/) installed
- A Langfuse account ([Cloud](https://cloud.langfuse.com) or [self-hosted](https://langfuse.com/docs/deployment/self-host))
- [uv](https://docs.astral.sh/uv/) installed (for running the hook script with automatic dependency management)

## Step 1: Set Up Langfuse

1. Sign up for [Langfuse Cloud](https://cloud.langfuse.com) or self-host Langfuse.
2. Create a new project and copy your API keys from the project settings.

## Step 2: Set Up the Hook Script

The tracing hook script is included in this repository at `.claude/hooks/langfuse-claude-code-tracing.py`. Copy it to the appropriate location depending on your configuration scope (see Step 3).

## Step 3: Configure the Hook

Claude Code settings follow a scope hierarchy. Choose the scope that fits your use case:

| Scope                    | Location                      | Shared with team?      | Best for                              |
| :----------------------- | :---------------------------- | :--------------------- | :------------------------------------ |
| **User (Global)**        | `~/.claude/settings.json`     | No                     | Personal tracing across all projects  |
| **Project**              | `.claude/settings.json`       | Yes (committed to git) | Team-wide tracing for a specific repo |
| **Project User (Local)** | `.claude/settings.local.json` | No (gitignored)        | Personal tracing in a specific repo   |

> **Precedence:** When the same setting exists in multiple scopes, more specific scopes win: **Local** > **Project** > **User**.

### Option A: User (Global) Scope

Enables tracing for all your Claude Code projects.

1. Copy the script to your global hooks directory:

   ```bash
   mkdir -p ~/.claude/hooks
   cp .claude/hooks/langfuse-claude-code-tracing.py ~/.claude/hooks/
   ```

2. Add the hook to `~/.claude/settings.json`:

   ```json
   {
     "hooks": {
       "Stop": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "uv run ~/.claude/hooks/langfuse-claude-code-tracing.py"
             }
           ]
         }
       ]
     }
   }
   ```

### Option B: Project Scope

Enables tracing for all collaborators on the repository. The hook script and configuration are committed to git.

1. Ensure the script exists at `.claude/hooks/langfuse-claude-code-tracing.py` in the project root.

2. Add the hook to `.claude/settings.json`:

   ```json
   {
     "hooks": {
       "Stop": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "uv run .claude/hooks/langfuse-claude-code-tracing.py"
             }
           ]
         }
       ]
     }
   }
   ```

> **Note:** Each team member still needs to set the environment variables (see Step 4) on their own machine.

### Option C: Project User (Local) Scope

Enables tracing only for you in a specific repository, without affecting other collaborators.

1. Ensure the script exists at `.claude/hooks/langfuse-claude-code-tracing.py` in the project root (or copy it to `~/.claude/hooks/` and use the absolute path).

2. Add the hook to `.claude/settings.local.json`:

   ```json
   {
     "hooks": {
       "Stop": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "uv run .claude/hooks/langfuse-claude-code-tracing.py"
             }
           ]
         }
       ]
     }
   }
   ```

> **Note:** `.claude/settings.local.json` is automatically gitignored by Claude Code.

## Step 4: Set Environment Variables

The hook requires the following environment variables. Add them to your shell profile (e.g., `~/.bashrc`, `~/.zshrc`):

```bash
# Required: enable tracing
export TRACE_TO_LANGFUSE=true

# Required: Langfuse API keys
export LANGFUSE_PUBLIC_KEY="pk-lf-..."
export LANGFUSE_SECRET_KEY="sk-lf-..."

# Optional: Langfuse host (defaults to https://cloud.langfuse.com)
export LANGFUSE_HOST="https://cloud.langfuse.com"

# Optional: enable debug logging
export CC_LANGFUSE_DEBUG=true
```

The hook also supports `CC_LANGFUSE_PUBLIC_KEY` and `CC_LANGFUSE_SECRET_KEY` prefixed variants, which take precedence over the standard `LANGFUSE_*` names.

## How It Works

The hook script runs on every Claude Code **Stop** event (after each assistant response). It:

1. Reads the latest Claude Code conversation transcript from `~/.claude/projects/`
2. Parses new messages since the last run (tracked via state file at `~/.claude/state/langfuse_state.json`)
3. Groups messages into turns (user -> assistant -> tool calls)
4. Sends each turn as a trace to Langfuse with tool call details

## Troubleshooting

- **Logs:** Check `~/.claude/state/langfuse_hook.log` for errors
- **Debug mode:** Set `CC_LANGFUSE_DEBUG=true` for verbose logging
- **Not sending traces?** Verify `TRACE_TO_LANGFUSE=true` is set and your API keys are correct
