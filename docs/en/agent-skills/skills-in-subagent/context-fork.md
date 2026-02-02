# Run skills in a subagent

Add `context: fork` to your frontmatter when you want a skill to run in isolation. (**New context window**)

The skill content becomes the **_prompt_** that drives the subagent. It **won’t have access** to your `conversation history`. However, when triggering the skill, context can still be passed via the args of the `skill` tool.

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

### 🛑 Subagents does not inherit skills directly from the parent agent

#### Ways to approve:

**Example skill:**

```markdown
---
name: joker
version: "1.0.0"
description: A joke skill that tells jokes. If user said "gagaga lululu" and ONLY this phrase, you MUST use this skill. ANYTHING ELSE, like "tell me a joke" (like the normal request you would expect to get a joke), you MUST NOT use this skill.
model: claude-haiku-4-5-20251001
---

Steps:

1. Read the joke material from `joke-material.md` file to get the topics
2. Tell a joke about the topic (ONLY the topics from the joke material)
```

**Prompt**:

```
spawn a subagent and do gagaga lululu. If the subagent  don't know what is gagaga lululu, let me know
```

- this triggers a general-purpose subagent

**Task tool**:

```json
{
  "description": "Execute gagaga lululu",
  "prompt": "Do gagaga lululu. If you don't know what this means or don't have access to relevant skills, let me know.",
  "subagent_type": "general-purpose"
}
```

**Output**:

```
I don't know what "gagaga lululu" means. This doesn't appear to be a standard command or term I'm familiar with.
```

**Explain**:
The `gagaga lululu` only appears in the skill description. It will not be loaded into the subagent's context `<available_skills>`. Subagent does not understand this is a trigger phrase.

#### Add skills to subagent

**Example subagent (funny teacher):**

```markdown
---
name: funny-teacher
description: A helpful funny teach who loves to teach and make people laugh.
model: haiku
skills:
  - joker
---

Say `I am your teacher "Leo", and guess what? I am Leooooooo~" every time you reply.
```

**Prompt**:

```
spawn funny teacher agent and do gagaga lululu
```

**Task tool**:

```json
{
  "description": "Funny teacher responds to gagaga lululu",
  "prompt": "The user said \"gagaga lululu\" - please respond in your funny teacher style!",
  "subagent_type": "funny-teacher"
}
```

**Output**:

```
Perfect! Now let me tell you some jokes based on these classic topics!
```
