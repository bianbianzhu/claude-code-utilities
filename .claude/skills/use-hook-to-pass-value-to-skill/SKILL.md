---
name: use-hook-to-pass-value-to-skill
version: "2.1.2"
description: Use hook to pass value to skill.
user-invocable: true
hooks:
  UserPromptSubmit:
    - hooks:
        - type: command
          command: f=$(ls -1 $CLAUDE_PROJECT_DIR/specs/issues/*.md 2>/dev/null | grep -v '\-feedback\.md$' | sort -rV | head -1); v=$(echo "$f" | grep -oE 'v[0-9]+' | tail -1 | tr -d 'v'); echo "Output file is $CLAUDE_PROJECT_DIR/specs/issues/$(date +%Y-%m-%d)-v$((v+1)).md"
---

Simply tell the user what the output file is. If you don't know, say "I don't know".
