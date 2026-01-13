1. Copy the command from `.claude/commands/ask-codex.md` to your commands folder.
2. Go to ~/.codex/config.toml (if not present, create it) and add the following (if not already present):

```toml
[profiles.claude]
approval_policy = "never"
sandbox_mode = "danger-full-access"
model = "gpt-5.2"
model_reasoning_effort = "high"
show_raw_agent_reasoning = false
```

This adds the `claude` profile to your Codex config, so that you can run `codex exec --profile claude <your prompt>`.
