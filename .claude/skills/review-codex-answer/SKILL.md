---
name: review-codex-answer
description: >
  Fetch the latest final_answer from a local Codex CLI session for cross-agent review.
  Trigger: /review-codex-answer slash command. Use when the user wants to see what Codex replied,
  compare Codex's answer with Claude Code's own analysis, or cross-check plans/bugfixes
  between Claude Code and Codex.
disable-model-invocation: true
---

# Codex Review

Retrieve and display the most recent Codex final_answer from local session files (`~/.codex/sessions/`).

## Workflow

1. Run the extraction script:

```bash
uv run <skill-path>/scripts/get_codex_final_answer.py
```

2. Parse the JSON output. Present to the user:
   - Source file path and timestamp
   - The full `text` content, rendered as markdown
   - Total number of final_answers available in that session

3. Use the **AskUserQuestion** tool to confirm:
   - Question: "Is this the Codex answer you want to review?"
   - Options: "Yes, review this one" / "No, show me the previous one"
   - If **yes** — proceed to step 4.
   - If **no** — re-run with `--offset N` (start with 1, increment) to fetch the previous final_answer, then ask again:

```bash
uv run <skill-path>/scripts/get_codex_final_answer.py --offset 1
```

4. Once confirmed, perform a **cross-review** of the Codex answer against your own prior analysis in this conversation. Address the following:
   - Did you and the other engineer identify the **same root causes / key points**?
   - Is your analysis **better or worse** than theirs? In what ways?
   - Is there anything you can **learn from** their content?
   - Is there anything **missing in their analysis** that you covered, or vice versa?

5. If the script returns an `error` key in JSON, report the error to the user.

## Notes

- `<skill-path>` refers to the directory containing this SKILL.md.
- The script finds the most recently modified `.jsonl` file under `~/.codex/sessions/` automatically.
- Each Codex session may contain multiple final_answers (one per turn). The script returns the last one by default.
