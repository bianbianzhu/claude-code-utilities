# Langfuse Tracing Setup for Claude Code

Send Claude Code conversation traces to [Langfuse](https://langfuse.com) for observability, debugging, and analytics.

## Prerequisites

- [Claude Code](https://code.claude.com/) installed
- A Langfuse account ([Cloud](https://cloud.langfuse.com) or [self-hosted](https://langfuse.com/docs/deployment/self-host))
- [uv](https://docs.astral.sh/uv/) installed (for running the hook script with automatic dependency management)

## Step 1: Set Up Langfuse

1. Sign up for [Langfuse Cloud](https://cloud.langfuse.com) or self-host Langfuse.
2. Create a new project and copy your API keys from the project settings.

## Step 2: Install the Hook Script

The tracing hook script is included in this repository at `.claude/hooks/langfuse-claude-code-tracing.py`. Copy it to your global hooks directory:

```bash
mkdir -p ~/.claude/hooks
cp .claude/hooks/langfuse-claude-code-tracing.py ~/.claude/hooks/
```

> **Best practice:** Always keep the hook script in `~/.claude/hooks/` and reference it with an absolute path. This ensures the hook works regardless of the current working directory and avoids path resolution issues.

## Step 3: Configure the Hook

Claude Code settings follow a scope hierarchy. Choose the scope that fits your use case:

| Scope                    | Location                      | Shared with team?      | Best for                              |
| :----------------------- | :---------------------------- | :--------------------- | :------------------------------------ |
| **User (Global)**        | `~/.claude/settings.json`     | No                     | Personal tracing across all projects  |
| **Project**              | `.claude/settings.json`       | Yes (committed to git) | Team-wide tracing for a specific repo |
| **Project User (Local)** | `.claude/settings.local.json` | No (gitignored)        | Personal tracing in a specific repo   |

> **Precedence:** When the same setting exists in multiple scopes, more specific scopes win: **Local** > **Project** > **User**.

### Option A: User (Global) Scope

Enables tracing for all your Claude Code projects. Add to `~/.claude/settings.json`:

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
  },
  "env": {
    "TRACE_TO_LANGFUSE": "true",
    "LANGFUSE_PUBLIC_KEY": "pk-lf-...",
    "LANGFUSE_SECRET_KEY": "sk-lf-...",
    "LANGFUSE_HOST": "https://cloud.langfuse.com"
  }
}
```

### Option B: Project Scope

Enables tracing for all collaborators on the repository. The configuration is committed to git. Add to `.claude/settings.json`:

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

> **Note:** The hook script must be installed on each team member's machine (see Step 2). API keys should **not** be committed to git — each team member should configure them in their own `.claude/settings.local.json` (see Option C).

### Option C: Project User (Local) Scope

Enables tracing only for you in a specific repository, without affecting other collaborators. Add to `.claude/settings.local.json`:

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
  },
  "env": {
    "TRACE_TO_LANGFUSE": "true",
    "LANGFUSE_PUBLIC_KEY": "pk-lf-...",
    "LANGFUSE_SECRET_KEY": "sk-lf-...",
    "LANGFUSE_HOST": "https://cloud.langfuse.com"
  }
}
```

> **Note:** `.claude/settings.local.json` is automatically gitignored by Claude Code.

## Environment Variables Reference

Environment variables are configured via the `env` key in your settings file. The hook requires:

| Variable | Required | Description |
|:---------|:---------|:------------|
| `TRACE_TO_LANGFUSE` | Yes | Set to `"true"` to enable tracing |
| `LANGFUSE_PUBLIC_KEY` | Yes | Your Langfuse project public key |
| `LANGFUSE_SECRET_KEY` | Yes | Your Langfuse project secret key |
| `LANGFUSE_HOST` | No | Langfuse host URL (defaults to `https://cloud.langfuse.com`) |
| `CC_LANGFUSE_DEBUG` | No | Set to `"true"` for verbose debug logging |

## How It Works

The hook script runs on every Claude Code **Stop** event (after each assistant response). It:

1. Reads the latest Claude Code conversation transcript from `~/.claude/projects/`
2. Parses new messages since the last run (tracked via state file at `~/.claude/state/langfuse_state.json`)
3. Groups messages into turns (user -> assistant -> tool calls)
4. Sends each turn as a trace to Langfuse with tool call details

## Troubleshooting

- **Logs:** Check `~/.claude/state/langfuse_hook.log` for errors
- **Debug mode:** Set `CC_LANGFUSE_DEBUG` to `"true"` in your settings `env` for verbose logging
- **Not sending traces?** Verify `TRACE_TO_LANGFUSE` is `"true"` and your API keys are correct
