# Run skills in a subagent

Add `context: fork` to your frontmatter when you want a skill to run in isolation. (**New context window**)

The skill content becomes the **_prompt_** that drives the subagent. It **won’t have access** to your `conversation history`.

`context: fork` only makes sense for skills with explicit instructions. If your skill contains guidelines like “use these API conventions” without a task, the subagent receives the guidelines but no actionable prompt, and returns without meaningful output.

Skills and subagents work together in two directions:
| Approach | System prompt source | Task prompt source | Also loads |
|-----------------------------------|----------------------------------------|-------------------------|----------------------------|
| Skill with `context: fork` | From agent type (Explore, Plan, etc.) | `SKILL.md` content | `CLAUDE.md` |
| Subagent with `skills` field | Subagent’s markdown body | Claude’s delegation msg | Preloaded skills + `CLAUDE.md` |

With `context: fork`, you write the task in your skill and pick an agent type to execute it. For the inverse (defining a custom subagent that uses skills as reference material), see [Preload skills into subagents](#preload-skills-into-subagents).
​

## Example: Research skill using Explore agent

This skill runs research in a forked Explore agent. The skill content becomes the task, and the agent provides read-only tools optimized for codebase exploration:

```markdown
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS thoroughly:

1. Find relevant files using Glob and Grep
2. Read and analyze the code
3. Summarize findings with specific file references
```

### When this skill runs:

1. A new isolated context is created
2. The subagent receives the skill content as its prompt (“Research $ARGUMENTS thoroughly…”)
3. The `agent` field determines the execution environment (model, tools, and permissions)
4. Results are summarized and returned to your main conversation

The agent field specifies which subagent configuration to use. Options include built-in agents (`Explore`, `Plan`, `general-purpose`) or any custom subagent from `.claude/agents/`. If omitted, uses `general-purpose`.

## Preload skills into subagents

Use the skills field to inject skill content into a subagent’s context at startup. This gives the subagent domain knowledge without requiring it to discover and load skills during execution.

```markdown
---
name: api-developer
description: Implement API endpoints following team conventions
skills:
  - api-conventions
  - error-handling-patterns
---

Implement API endpoints. Follow the conventions and patterns from the preloaded skills.
```

The full content of each skill is injected into the subagent’s context, not just made available for invocation. Subagents don’t inherit skills from the parent conversation; you must list them explicitly.

This is the inverse of [running a skill in a subagent](#run-skills-in-a-subagent). With skills in a subagent, the subagent controls the system prompt and loads skill content. With `context: fork` in a skill, the skill content is injected into the agent you specify. Both use the same underlying system.
