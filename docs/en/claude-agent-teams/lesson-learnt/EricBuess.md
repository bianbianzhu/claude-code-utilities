# Claude Code Agent Teams: What I Learned from Testing

Anthropic just shipped "Agent Teams" in Claude Code alongside Opus 4.6 — and the community's been calling it "swarm mode." I spent a while testing it hands-on and digging through the docs. Here's what I found — how it works, what the gotchas are, and what surprised me based on the docs and my own testing. I could be wrong about some of this, and I'd love feedback.

## What Are Agent Teams?

Agent teams let you coordinate multiple Claude Code instances working together on a single task.

One session acts as the **team lead** — it coordinates work, assigns tasks, and synthesizes results. The rest are **teammates** — fully independent Claude Code instances, each with their own context window, that communicate directly with each other.

You describe the task and team structure in natural language. Claude creates the team, spawns teammates, distributes work, and manages coordination. Each teammate loads the same project context (CLAUDE.md, MCP servers, skills) but doesn't inherit the lead's conversation history.

In practice, it felt like having multiple Claude instances that could message each other and share a task board — all working on different parts of the same problem at the same time.

## "Swarm Mode" vs Agent Teams — Same Thing?

From what I can tell, yes — they're the same thing. The community and blogosphere popularized "swarm" and "swarm mode," but Anthropic's official name is Agent Teams. There's no separate swarm feature.

When you see "Claude Code swarm" referenced on Hacker News, blog posts, or YouTube — they're all referring to agent teams.

## How to Enable Agent Teams

Agent teams are experimental and disabled by default. There's no toggle in the Claude Code CLI menu — you have to set it manually.

I enabled it by adding an `env` block to my `settings.json` with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` set to `"1"`. That persists across sessions. You can also just export the variable in your shell before launching, but the `settings.json` approach means you don't have to remember it every time.

If you don't enable it, Claude falls back to subagents instead — single-session helpers that report results back to the main agent. No inter-agent messaging, no shared task list, no split panes.

## The Two Display Modes

Agent teams have two ways of showing teammate activity.

### In-Process Mode

All teammates run inside your main terminal. You use **Shift+Up/Down** to select a teammate, type to message them, press **Enter** to view their session, and **Escape** to interrupt. **Ctrl+T** toggles the shared task list.

Works in any terminal. No extra setup.

The default is actually "auto," which uses split panes if you're already in a tmux session and falls back to in-process otherwise — so for most people, in-process is what you'll get out of the box.

### Split-Pane Mode

Each teammate gets its own terminal pane. You see everyone's output at once and can click into any pane to interact directly.

Requires tmux or iTerm2. That's it.

### When I Found Each Mode Useful

**Split-pane mode** was valuable when I wanted to watch teammates work in real time — monitoring multiple streams of output simultaneously, catching mistakes early, or jumping into a pane to give additional instructions mid-task.

It was especially useful for debugging sessions where I wanted to see competing hypotheses explored live, and for the visual impact of seeing multiple agents working in parallel.

**In-process mode** worked better when I just wanted results and didn't need to monitor. It handles many teammates without the screen getting cramped (split panes get tiny with 5+ teammates), and there's less setup friction. Most of my tasks worked fine in in-process mode.

## Terminal Support — What Works Where

This is the question everyone asks. Here's what I found:

**Supports split panes:**

- **tmux** (inside any terminal) — Yes
- **iTerm2** (with the `it2` CLI and the Python API enabled) — Yes

**In-process mode only (no split panes):**

- Ghostty
- VS Code terminal
- Windows Terminal
- All other terminals

> The docs say: "Split-pane mode is not supported in VS Code's integrated terminal, Windows Terminal, or Ghostty."

I got split panes working in iTerm2 by installing the `it2` CLI (see [github.com/mkusaka/it2](https://github.com/mkusaka/it2) for installation instructions), enabling the Python API in iTerm2 under **Settings > General > Magic**, and launching Claude Code with the `--teammate-mode tmux` flag. The command I used was:

```
claude --teammate-mode tmux
```

The docs also show a `teammateMode` setting for `settings.json` — you can set it to `"tmux"` or `"in-process"` there. When I tried it, my version rejected it with a schema validation error, so I had to use the CLI flag instead. This might be version-specific — it could work for you.

One thing that confused me at first: the `"tmux"` value actually auto-detects whether to use tmux or iTerm2 based on your terminal — and maybe you don't need tmux installed if you're in iTerm2? If so, the name is misleading.

**Why "auto" didn't work in iTerm2:** The default `teammateMode` is `"auto,"` which only triggers split panes if you're already inside a tmux session. In native iTerm2, `"auto"` falls back to in-process mode. I had to explicitly pass `--teammate-mode tmux` to get panes. I think Anthropic suggests `tmux -CC` inside iTerm2 as the recommended entrypoint into tmux if you prefer that route.

### What Happens to Panes After Teammates Shut Down

This part surprised me and I'm still not entirely sure what the intended workflow is.

When a teammate shuts down, Claude Code exits but the pane stays open — it drops to a regular shell prompt. This happens in both iTerm2 and tmux because Claude runs inside a shell wrapper, and when Claude exits, the shell stays alive.

At first I thought this was a problem and spent a while trying to figure out how to auto-close them. I tried shell snippets, the `it2` CLI, telling Claude to close them programmatically. You can do all of that — but here's the thing I didn't realize until later: I think closing panes breaks your ability to create another team in the same Claude Code session. Claude Code caches the pane ID and tries to split new teammates from it. If that pane is gone, it fails with a "Session not found" error and you have to restart Claude Code with the `--teammate-mode tmux` flag all over again.

So the actual workflow seems to be: **one team per Claude Code session**. The panes staying open is probably intentional — each one shows the session ID with a `claude --resume` command, so you can review what happened, inspect final output, or resume a specific teammate's conversation. When you're done, you close everything and start a fresh Claude Code session if you want to run another team.

I'm honestly not sure if this is the long-term design or just how it works right now in the experimental phase. Maybe pane reuse and multi-team sessions will come later. Maybe the one-team-per-session pattern is the intended model. Either way, I wouldn't recommend setting up auto-close automation — it fights against how the tool currently works and you'll just end up needing to restart Claude Code anyway.

One other thing I noticed: it seems panes are never reused. Even if old teammate panes are still open, Claude Code creates brand new ones each time. So if you somehow do manage multiple rounds without restarting, the old panes just accumulate.

### iTerm2 Native vs tmux Inside Another Terminal

Both approaches give you split panes, but the experience is pretty different. I tested iTerm2 with its native Python API integration, and here's how it compared to running tmux inside another terminal.

#### iTerm2 Native (via the `it2` CLI)

Each teammate pane was a first-class iTerm2 split. That meant native macOS integration — Cmd+click on file paths, proper scrollback with trackpad, native text selection and copy/paste, macOS Services menu, and iTerm2's built-in search (Cmd+F) within each pane.

Pane dividers resized smoothly by dragging. Each pane respected my iTerm2 profile settings — colors, fonts, transparency, everything. I could also detach a teammate pane into its own tab or window.

The tradeoff was more setup friction (installing the `it2` CLI, enabling the Python API, using the CLI flag) and it's macOS-only.

#### tmux Inside Any Terminal (Ghostty, Kitty, Alacritty, etc.)

The advantage here is portability. tmux works on macOS, Linux, and inside remote SSH sessions. If you SSH into a dev server and want agent teams with split panes, tmux is your only option. It's also more scriptable — tmux has a rich command language for pane management, and you can detach and reattach sessions. If your terminal crashes, the tmux session survives.

I found some real tradeoffs though. tmux panes don't support native macOS gestures — no trackpad scrolling (you need tmux's copy mode), no Cmd+click, no native text selection across pane boundaries. Copy/paste requires tmux's own buffer system or mouse mode. I've done a lot of intricate things with tmux configs over the years and it has awesome use cases. It's great, but the UX is just different than mac native. The learning curve is steeper if you're not already a tmux user.

#### The Hybrid: `tmux -CC` in iTerm2

This is what Anthropic suggests. Running `tmux -CC` in iTerm2 gives you tmux's session persistence and detach/reattach capabilities while rendering tmux panes as native iTerm2 splits. Best of both worlds — native macOS feel plus tmux's durability. If your network drops during an SSH session, the tmux session survives and you can reattach with your teammates intact.

**My take:** If you're on macOS and working locally, iTerm2 native felt better day-to-day. If you need portability, remote access, or session persistence, tmux. If you want both, `tmux -CC` in iTerm2.

## Agent Teams vs Subagents

Both let you parallelize work, but they work differently. The key distinction I noticed: **do your workers need to talk to each other?**

**Subagents** are single-session helpers that report results back to the caller. They can't message each other. The main agent manages all work. They have lower token cost and don't require any opt-in — they're built in by default. They worked well for focused tasks where I just needed a result back.

**Agent Teams** are fully independent Claude Code instances. Teammates message each other directly and share a task list with self-coordination. They cost significantly more tokens and require the experimental flag. They worked better for complex tasks that needed discussion and collaboration between workers.

## A Note on Cost

Agent teams burn significantly more tokens than working with a single Claude Code session. I didn't measure this precisely, but it's easy to see why: every teammate has its own full context window loaded with project context, every message between teammates costs tokens, and the shared task list polling costs tokens. Multiply that by however many teammates you spawn and it adds up fast.

I didn't run the same task with a single session vs subagents vs an agent team to compare, so I can't give you a number. But it felt noticeably more expensive — especially for tasks that could have been done by one agent working sequentially. The parallel speed was real, but so was the cost.

That tradeoff felt worth it for research tasks, multi-file features with clear boundaries, and debugging with competing hypotheses. It didn't feel worth it for simple sequential tasks, quick fixes, or anything where one agent could do the job.

I'd start small. A 2-teammate team on a research task before spinning up 5 agents on a feature build.

## Best Use Cases

I found agent teams worked well for:

- **Research and review** — Multiple teammates investigating different aspects of a problem simultaneously, then sharing and challenging each other's findings
- **New modules or features** — Teammates each owning a separate piece without stepping on each other
- **Debugging with competing hypotheses** — Teammates testing different theories in parallel and converging faster
- **Cross-layer coordination** — Frontend, backend, and tests each owned by a different teammate
- **Parallel code review** — Security, performance, and test coverage reviewed simultaneously by specialists

## Key Architecture Details

Every agent team has four components:

- **Team lead** — Your main Claude Code session. Creates the team, spawns teammates, coordinates work.
- **Teammates** — Separate Claude Code instances working on assigned tasks.
- **Task list** — A shared board of work items that teammates claim and complete.
- **Mailbox** — Messaging system for direct inter-agent communication.

Teams and tasks are stored locally under `~/.claude/teams/` and `~/.claude/tasks/`, organized by team name.

Teammates can self-claim unassigned tasks, and task dependencies auto-resolve when blocking tasks complete. File locking prevents race conditions when multiple teammates try to claim the same task.

## Delegate Mode

I noticed the lead would sometimes start implementing tasks itself instead of waiting for teammates. **Delegate mode** restricts the lead to coordination-only tools: spawning, messaging, shutting down teammates, and managing tasks.

I enabled it by pressing **Shift+Tab** after starting a team. Kept the lead focused purely on orchestration.

## The New Memory Frontmatter for Subagents

This section covers a separate but related feature that shipped around the same time. Memory frontmatter is a **subagent** feature, not an agent teams feature — but since a lot of people discover both at once, it's worth covering here.

Subagents now support a `memory` frontmatter field in their agent markdown files that gives them persistent memory across conversations. The agent builds up knowledge over time — codebase patterns, debugging insights, architectural decisions — and retains it for future sessions.

### How It Works (I Think)

You add `memory` to the YAML frontmatter in your agent's markdown file and set it to one of three scopes: `user`, `project`, or `local`.

### Memory Scopes

- **`user`** — Stored at `~/.claude/agent-memory/` under the agent's name. The agent remembers learnings across all projects. This is the recommended default.
- **`project`** — Stored at `.claude/agent-memory/` under the agent's name. Knowledge is project-specific and shareable via version control.
- **`local`** — Stored at `.claude/agent-memory-local/` under the agent's name. Knowledge is project-specific but shouldn't be checked into version control.

### What Happens When Memory Is Enabled

When the `memory` field is set:

- The agent's system prompt automatically includes instructions for reading and writing to its memory directory
- The first 200 lines of a `MEMORY.md` file in the memory directory get injected into the agent's system prompt
- If `MEMORY.md` exceeds 200 lines, the agent is instructed to curate and trim it
- Read, Write, and Edit tools are automatically enabled so the agent can manage its memory files
- The agent can create additional topic-specific files and link to them from `MEMORY.md`

### What I Found Useful

I started with `user` scope since it's the recommended default. Only using `project` or `local` when the knowledge was specific to a single codebase made sense.

Asking the agent to consult its memory before starting work helped — something like "Review this PR, and check your memory for patterns you've seen before."

Asking it to update memory after completing work also helped: "Now that you're done, save what you learned to your memory."

Embedding memory instructions directly in the agent file made it proactively maintain its own knowledge base. Something like: "Update your agent memory as you discover codepaths, patterns, library locations, and key architectural decisions."

Over time, this creates a compounding knowledge base. A code reviewer that remembers your team's common issues. A security auditor that knows your architecture. A test writer that knows your patterns.

## When to Use Memory Frontmatter vs Other Memory

Claude Code has multiple memory mechanisms. They serve different purposes and it's easy to confuse them.

**CLAUDE.md files** (project, user, rules) are for **instructions** — things you want Claude to always know and follow. Coding standards, project architecture, preferred patterns, common commands. These are static. You write them, Claude reads them.

**Memory frontmatter** on subagents is for **learning** — things the agent discovers on its own and builds up over time. That's the key difference. CLAUDE.md is "here are the rules." Agent memory is "here's what I've figured out." Agent memory is dynamic, agent-managed, and compounds across conversations.

### Where I Saw Memory Frontmatter Make the Most Sense

- **Specialized reviewers.** A code review agent that learns your team's common mistakes and preferred fixes. After several reviews, it catches issues faster because it remembers what tripped people up before.
- **Security auditors.** An agent that maps your app's attack surface over time — which endpoints handle auth, where user input flows, what validation exists.
- **Test writers.** An agent that learns your testing patterns, fixture conventions, and which areas of the codebase are flaky.
- **Onboarding helpers.** An agent that explores a new codebase and documents what it finds — architecture, key files, data flow.

### Where CLAUDE.md Made More Sense

- Things that rarely change (coding standards, project structure)
- Instructions I wanted to control explicitly (not let the agent decide)
- Context for my main session, not a subagent
- Information the whole team should share (committed to git)

Neither was necessary for one-off tasks, quick subagent calls where I just needed a result, or anything that didn't benefit from cross-session learning.

## Claude Code's Memory System (User-Level)

Beyond agent memory, Claude Code itself has a hierarchical memory system for persisting preferences across sessions.

- **Managed policy** — OS-specific system path. On macOS it's at `/Library/Application Support/ClaudeCode/CLAUDE.md`. On Linux it's at `/etc/claude-code/CLAUDE.md`. On Windows it's at `C:\Program Files\ClaudeCode\CLAUDE.md`. Applies to all users in an organization.
- **Project memory** — A `CLAUDE.md` file in the project root or under `.claude/`. Team-shared via git.
- **Project rules** — Markdown files in `.claude/rules/`. Modular, topic-specific, team-shared. Can be scoped to specific file paths using YAML frontmatter with glob patterns — so your TypeScript rules only fire when working on `.ts` files.
- **User memory** — A `CLAUDE.md` file at `~/.claude/`. Personal preferences across all projects.
- **Project local** — A `CLAUDE.local.md` file in the project root. Personal, this project only.

All memory files load automatically when Claude starts. CLAUDE.md files support an `@path/to/import` syntax for importing other files recursively (up to 5 hops deep). The `/memory` command edits files, and `/init` bootstraps a new project CLAUDE.md.

## Current Limitations

Agent teams are experimental. Here's what I ran into or found in the docs:

- **Teammate resumption is limited** — I think we can resume the lead session, but `/resume` and `/rewind` won't restore in-process teammates. After resuming, the lead might try to message teammates that no longer existed
- **Task status can lag** — Teammates sometimes failed to mark tasks completed, which blocked dependent work
- **Shutdown can be slow** — Teammates sometimes finish their current request a while before shutting down
- **One team per session** — per the docs, you need to clean up the current team before starting a new one. I'm not sure though. I think it worked fine and the teams were cleaned up and I was able to have it make new ones in in-process mode. I need more testing here. In split-pane mode, however, I ran into stale pane ID issues when trying to start a second team after closing the panes (see the pane section above)
- **No nested teams** — Teammates can't spawn their own teams
- **Lead is fixed** — You can't promote a teammate to lead
- **Split panes are tmux and iTerm2 only** — No Ghostty, VS Code, or Windows Terminal support
- **Permissions set at spawn** — All teammates started with my permission mode. I could change individual modes after spawning, but couldn't set per-teammate modes at spawn time

## Getting Started

Here's roughly what I did to get agent teams running.

I updated Claude Code to the latest version, then added `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` set to `"1"` inside an `env` block in my `settings.json` (at `~/.claude/settings.json`).

For split panes, I launched with:

```
claude --teammate-mode tmux
```

For in-process mode (any terminal), I just launched Claude normally.

Then I gave Claude a task and asked it to use a team. Something like: "Create a team to review this PR. Have one teammate check for security issues, one check for performance problems, and one verify test coverage. Compare findings when done."

Claude created the team, spawned teammates, assigned tasks, and coordinated the results. When the team finished, it shut down teammates. The panes stayed open for me to review.

I'd recommend starting with research and review tasks — that's where I saw the clearest benefit. They have clear boundaries and show the value of parallel exploration without the coordination complexity of parallel implementation. I'm also going to be largely working in in-process mode, meaning not using tmux or iterm with tmux split-pane mode unless I have a compelling reason to do so.

If you find something wrong here or your experience differs, I'd genuinely love to hear about it. This is all based on my own testing and the docs as of early February 2026.

I discovered all this largely the way I normally discover new features for Claude Code — I ran `/docs` and asked it about the features. You can do this to if you have or install my claude-code-docs project which provides a regularly updated local mirror of the Claude Code documentation that your Claude Code instance can easily search with a manifest.

<https://github.com/ericbuess/claude-code-docs.git>

---

*Claude Code Agent Teams shipped alongside Opus 4.6 on February 5, 2026.*
