> 翻译基于 [英文版 commit 4c592a1](https://github.com/anthropics/claude-code-utilities/commit/4c592a15c647dc6362b5f2798076eb8d377e1e15) | [English Version](EricBuess.md)

# Claude Code Agent Teams：实测总结

Anthropic 随 Opus 4.6 一起发布了 Claude Code 的 "Agent Teams" 功能，社区里大家通常叫它 "swarm mode（蜂群模式）"。我花了不少时间亲自测试，也仔细翻阅了文档。以下是我的发现——它的工作原理、踩过的坑，以及一些让我意外的地方。部分内容可能有误，欢迎指正。

## 什么是 Agent Teams？

Agent Teams 让你协调多个 Claude Code 实例（instance）协同完成同一个任务。

其中一个会话充当**团队负责人（team lead）**——负责协调工作、分配任务、汇总结果。其余的是**队友（teammates）**——完全独立的 Claude Code 实例，各自拥有独立的上下文窗口（context window），彼此可以直接通信。

你用自然语言描述任务和团队结构，Claude 就会创建团队、生成队友、分配工作并管理协调。每个队友会加载相同的项目上下文（CLAUDE.md、MCP servers、skills），但**不会继承** team lead 的对话历史。

实际体验下来，就像有多个 Claude 实例可以互相发消息、共享一个任务看板——同时处理同一个问题的不同部分。

## "Swarm Mode" 和 Agent Teams 是同一个东西吗？

据我了解，是的。社区和博客圈把 "swarm" 和 "swarm mode" 这个叫法传开了，但 Anthropic 官方名称是 Agent Teams，并没有单独的 swarm 功能。

Hacker News、博客或 YouTube 上提到的 "Claude Code swarm"，指的都是 Agent Teams。

## 如何启用 Agent Teams

Agent Teams 目前是实验性功能（experimental），默认关闭。CLI 菜单里没有开关，需要手动配置。

我的做法是在 `settings.json` 的 `env` 字段中将 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` 设为 `"1"`，这样配置会跨会话持久化。你也可以在启动前直接在 shell 里 export 这个环境变量，但写在 `settings.json` 里省得每次都记。

如果不启用，Claude 会退回到 subagent 模式——单会话辅助工具，只能向主 agent 汇报结果，没有 agent 间通信，没有共享任务列表，也没有分屏。

## 两种显示模式

Agent Teams 有两种展示队友活动的方式。

### 进程内模式（In-Process Mode）

所有队友在你的主终端内运行。使用 **Shift+Up/Down** 选择队友，输入内容向其发送消息，按 **Enter** 查看其会话，**Escape** 中断操作，**Ctrl+T** 切换共享任务列表。

适用于任何终端，无需额外配置。

默认值其实是 "auto"——如果你已经在 tmux 会话中，就自动使用分屏；否则回退到进程内模式。所以大多数人开箱即用就是进程内模式。

### 分屏模式（Split-Pane Mode）

每个队友拥有独立的终端面板（pane），你可以同时看到所有人的输出，点击任意面板即可直接交互。

需要 tmux 或 iTerm2。仅此而已。

### 两种模式的适用场景

**分屏模式**适合需要实时观察队友工作的场景——同时监控多个输出流、及早发现错误、或在任务进行中跳进某个面板补充指令。

特别适合调试场景，比如让多个 agent 同时探索不同假设，以及想直观感受多 agent 并行工作的场景。

**进程内模式**则适合只关心结果、不需要实时监控的情况。它在队友较多时不会让屏幕变得拥挤（5 个以上的队友用分屏就会很紧凑），配置也更简单。我的大多数任务用进程内模式就够了。

## 终端支持情况

这是大家最常问的问题。以下是我的测试结果：

**支持分屏：**

- **tmux**（任何终端内）——支持
- **iTerm2**（需要 `it2` CLI 和 Python API）——支持

**仅支持进程内模式（不支持分屏）：**

- Ghostty
- VS Code 终端
- Windows Terminal
- 其他所有终端

> 文档原文："Split-pane mode is not supported in VS Code's integrated terminal, Windows Terminal, or Ghostty."

我在 iTerm2 中成功启用了分屏：先安装 `it2` CLI（安装说明见 [github.com/mkusaka/it2](https://github.com/mkusaka/it2)），然后在 iTerm2 的 **Settings > General > Magic** 中启用 Python API，最后使用 `--teammate-mode tmux` 参数启动 Claude Code：

```
claude --teammate-mode tmux
```

文档中也提到可以在 `settings.json` 里设置 `teammateMode`——值为 `"tmux"` 或 `"in-process"`。但我实际尝试时遇到了 schema 校验错误，只能用 CLI 参数。这可能跟版本有关，你那边也许能用。

有一点一开始让我困惑：`"tmux"` 这个值其实会根据你的终端自动检测是用 tmux 还是 iTerm2——如果在 iTerm2 中甚至可能不需要安装 tmux。这个命名确实有些误导。

**为什么 "auto" 在 iTerm2 中不生效：** 默认的 `teammateMode` 是 `"auto"`，它只在你已经处于 tmux 会话中时才会触发分屏。在原生 iTerm2 里，`"auto"` 会回退到进程内模式。我必须显式传入 `--teammate-mode tmux` 才能启用分屏。Anthropic 建议在 iTerm2 中通过 `tmux -CC` 进入 tmux 会话来使用。

### 队友关闭后面板会怎样

这部分让我意外，我至今也不完全确定预期的工作流是什么。

队友关闭时，Claude Code 会退出，但面板仍然保留——它会变成一个普通的 shell 提示符。tmux 和 iTerm2 都是如此，因为 Claude 运行在 shell 包装器（wrapper）内，Claude 退出后 shell 继续存活。

起初我以为这是个问题，花了不少时间研究怎么自动关闭面板。我试过 shell 脚本、`it2` CLI、让 Claude 用程序化方式关闭面板——都能做到。但后来我才意识到：**关闭面板可能会导致同一 Claude Code 会话中无法创建新团队**。Claude Code 会缓存面板 ID，尝试从已有面板分裂出新队友。如果面板已经关了，就会报 "Session not found" 错误，你不得不重新用 `--teammate-mode tmux` 启动 Claude Code。

所以实际的工作流似乎是：**一个 Claude Code 会话对应一个团队**。面板保持打开可能是有意为之——每个面板都显示会话 ID 和 `claude --resume` 命令，方便你回顾、检查最终输出或恢复某个队友的对话。用完之后，关掉所有面板，想再建团队就重新开一个 Claude Code 会话。

我不确定这是长期设计还是实验阶段的临时方案。也许以后会支持面板复用和多团队会话。总之，我不建议做自动关闭面板的配置——它会和工具当前的工作方式冲突，最终你还是得重启 Claude Code。

另外我注意到：面板似乎永远不会被复用。即使旧的队友面板还开着，Claude Code 也会每次创建全新的面板。所以如果你在不重启的情况下跑了多轮，旧面板会不断累积。

### iTerm2 原生模式 vs 在其他终端中使用 tmux

两种方案都能提供分屏，但体验差别不小。我测试了 iTerm2 的原生 Python API 集成，以下是与在其他终端中运行 tmux 的对比。

#### iTerm2 原生模式（通过 `it2` CLI）

每个队友面板都是 iTerm2 的原生分割窗口，这意味着完整的 macOS 集成——Cmd+click 打开文件路径、触控板原生滚动、原生文本选择和复制粘贴、macOS 服务菜单，以及 iTerm2 内置搜索（Cmd+F）。

面板分隔线可以拖动调整大小，每个面板继承 iTerm2 配置文件的设置——配色、字体、透明度等。还可以把队友面板拆分到独立标签页或窗口。

代价是配置更麻烦（安装 `it2` CLI、启用 Python API、使用 CLI 参数），而且仅限 macOS。

#### 在任意终端中使用 tmux（Ghostty、Kitty、Alacritty 等）

优势是跨平台——tmux 在 macOS、Linux 和远程 SSH 会话中都能使用。如果你通过 SSH 连接到开发服务器并想使用分屏的 Agent Teams，tmux 是唯一选择。tmux 还更易于脚本化——它有丰富的面板管理命令语言，并且支持分离（detach）和重新连接（reattach）。如果终端崩溃，tmux 会话不会丢失。

但我也发现了一些明显的不足。tmux 面板不支持 macOS 原生手势——没有触控板滚动（需要进入 tmux 的 copy mode）、没有 Cmd+click、无法跨面板进行原生文本选择。复制粘贴需要使用 tmux 自己的缓冲区系统或鼠标模式。我多年来用 tmux 做过很多复杂配置，它功能强大、应用场景丰富，但 UX 就是和 Mac 原生体验不同。如果你还不是 tmux 用户，学习曲线会比较陡。

#### 混合方案：在 iTerm2 中使用 `tmux -CC`

这是 Anthropic 推荐的方案。在 iTerm2 中运行 `tmux -CC`，既能获得 tmux 的会话持久化和 detach/reattach 能力，又能将 tmux 面板渲染为 iTerm2 的原生分割窗口。兼得两者的优点——macOS 原生体验加上 tmux 的可靠性。如果 SSH 过程中网络断了，tmux 会话不会中断，你可以重新连接并恢复队友的工作状态。

**我的建议：** 如果在 macOS 本地开发，iTerm2 原生模式日常体验更好。如果需要跨平台、远程访问或会话持久化，用 tmux。如果两个都想要，`tmux -CC` in iTerm2。

## Agent Teams vs Subagents

两者都能并行化工作，但机制不同。我注意到的核心区别是：**你的工作者之间是否需要互相通信？**

**Subagents** 是单会话辅助工具，只向调用者返回结果，彼此之间不能通信。主 agent 管理所有工作。Token 消耗较低，无需额外配置——默认内置。适合只需要拿到结果的聚焦型任务。

**Agent Teams** 是完全独立的 Claude Code 实例。队友之间可以直接通信、共享任务列表并自行协调。Token 消耗明显更高，需要启用实验性标志。适合需要工作者之间讨论和协作的复杂任务。

## 关于成本

Agent Teams 的 token 消耗远高于单个 Claude Code 会话。我没有精确测量，但原因显而易见：每个队友都有完整的上下文窗口并加载项目上下文，队友间每条消息都消耗 token，共享任务列表的轮询也消耗 token。乘以队友数量，开销增长很快。

我没有用同一个任务分别在单会话、subagent 和 Agent Teams 下跑对比，无法给出具体数字。但体感上明显更贵——尤其是那些单个 agent 按顺序就能完成的任务。并行带来的速度提升是实在的，但成本也是实在的。

对于研究任务、有明确边界的多文件功能开发和竞争性假设调试，这个代价值得。对于简单的顺序任务、快速修复或单个 agent 就能搞定的事情，就不太划算了。

建议从小规模开始——先用 2 个队友跑个研究任务，再考虑 5 个 agent 并行做功能开发。

## 最佳使用场景

我发现 Agent Teams 在以下场景效果最好：

- **研究与评审（Research and review）**——多个队友同时调查问题的不同方面，然后分享并相互验证发现
- **新模块或功能**——队友各自负责独立的部分，互不干扰
- **竞争性假设调试**——队友并行测试不同假设，更快收敛到答案
- **跨层协调**——前端、后端和测试分别由不同队友负责
- **并行代码评审**——安全性、性能和测试覆盖率由不同专家同时审查

## 核心架构细节

每个 Agent Team 包含四个组件：

- **Team lead**——你的主 Claude Code 会话。创建团队、生成队友、协调工作。
- **Teammates**——独立的 Claude Code 实例，处理分配的任务。
- **任务列表（Task list）**——共享的工作看板，队友可以认领和完成任务。
- **邮箱（Mailbox）**——用于 agent 之间直接通信的消息系统。

团队和任务数据存储在本地的 `~/.claude/teams/` 和 `~/.claude/tasks/` 目录下，按团队名称组织。

队友可以自行认领未分配的任务；当阻塞任务完成时，依赖关系会自动解除。文件锁机制（file locking）防止多个队友同时认领同一个任务时出现竞态条件。

## 委托模式（Delegate Mode）

我注意到 team lead 有时会自己动手实现任务，而不是等队友完成。**委托模式（Delegate Mode）**将 lead 限制为仅使用协调类工具：生成队友、发消息、关闭队友和管理任务。

在启动团队后按 **Shift+Tab** 即可启用，让 lead 专注于纯粹的编排工作。

## 新的 Memory Frontmatter（Subagent 专属）

这部分介绍一个同期发布的相关但独立的功能。Memory frontmatter 是 **subagent** 的功能，不是 Agent Teams 的——但很多人会同时接触到两者，所以值得一并介绍。

Subagent 现在支持在 agent markdown 文件的 YAML frontmatter 中添加 `memory` 字段，赋予其跨对话的持久化记忆（persistent memory）。Agent 会随着使用逐步积累知识——代码库模式、调试经验、架构决策——并在后续会话中保留这些知识。

### 工作原理（我的理解）

在 agent 的 markdown 文件的 YAML frontmatter 中添加 `memory` 字段，并设置三种作用域之一：`user`、`project` 或 `local`。

### 记忆作用域（Memory Scopes）

- **`user`**——存储在 `~/.claude/agent-memory/` 下，以 agent 名称命名。Agent 的知识跨所有项目保留。这是推荐的默认值。
- **`project`**——存储在 `.claude/agent-memory/` 下，以 agent 名称命名。知识仅限当前项目，可通过版本控制共享。
- **`local`**——存储在 `.claude/agent-memory-local/` 下，以 agent 名称命名。知识仅限当前项目，但不应提交到版本控制。

### 启用 Memory 后的行为

设置 `memory` 字段后：

- Agent 的 system prompt 会自动包含读写记忆目录的指令
- 记忆目录中 `MEMORY.md` 文件的前 200 行会注入 agent 的 system prompt
- 如果 `MEMORY.md` 超过 200 行，agent 会被指示整理和精简
- Read、Write 和 Edit 工具会自动启用，以便 agent 管理自己的记忆文件
- Agent 可以创建额外的主题文件并在 `MEMORY.md` 中链接引用

### 实用技巧

我从 `user` 作用域开始，因为这是推荐的默认值。只在知识专属于某个代码库时才用 `project` 或 `local`。

在开始工作前让 agent 先查阅记忆很有帮助，比如："Review this PR, and check your memory for patterns you've seen before."

完成工作后让 agent 更新记忆也有价值："Now that you're done, save what you learned to your memory."

直接在 agent 文件中嵌入记忆相关的指令，可以让 agent 主动维护知识库。比如："Update your agent memory as you discover codepaths, patterns, library locations, and key architectural decisions."

随着时间推移，这会形成一个不断积累的知识库——一个记住你团队常见问题的代码审查员、一个了解你架构的安全审计员、一个掌握你测试模式的测试编写者。

## Memory Frontmatter vs 其他记忆机制

Claude Code 有多种记忆机制，用途各不相同，很容易混淆。

**CLAUDE.md 文件**（项目级、用户级、规则）用于**指令**——你希望 Claude 始终了解和遵循的内容。编码规范、项目架构、偏好的模式、常用命令。它们是静态的——你来写，Claude 来读。

**Memory frontmatter**（subagent 专属）用于**学习**——agent 自行发现并逐步积累的知识。这是核心区别。CLAUDE.md 是"这是规则"，agent memory 是"这是我总结出来的经验"。Agent memory 是动态的、由 agent 自行管理、并在跨对话中不断积累。

### Memory Frontmatter 最适合的场景

- **专业评审者。** 一个能记住你团队常见错误和偏好修复方式的代码审查 agent。经过多次审查后，它能更快地发现问题，因为它记得之前哪些地方容易出错。
- **安全审计。** 一个能逐步绘制应用攻击面的 agent——哪些端点处理认证、用户输入的数据流向、现有的校验机制。
- **测试编写。** 一个能学习你的测试模式、fixture 约定，以及代码库中哪些区域容易不稳定的 agent。
- **上手辅助（Onboarding）。** 一个能探索新代码库并记录发现的 agent——架构、关键文件、数据流。

### 更适合用 CLAUDE.md 的场景

- 很少变化的内容（编码规范、项目结构）
- 你想明确控制的指令（不想让 agent 自己决定）
- 为主会话提供的上下文，而非 subagent
- 全团队共享的信息（提交到 git）

对于一次性任务、只需返回结果的简单 subagent 调用、或不需要跨会话学习的场景，两者都不需要。

## Claude Code 的记忆系统（用户级）

除了 agent memory，Claude Code 本身也有一套分层的记忆系统（hierarchical memory system），用于跨会话持久化用户偏好。

- **托管策略（Managed policy）**——操作系统级路径。macOS 位于 `/Library/Application Support/ClaudeCode/CLAUDE.md`，Linux 位于 `/etc/claude-code/CLAUDE.md`，Windows 位于 `C:\Program Files\ClaudeCode\CLAUDE.md`。对组织中的所有用户生效。
- **项目记忆（Project memory）**——项目根目录或 `.claude/` 下的 `CLAUDE.md` 文件。通过 git 团队共享。
- **项目规则（Project rules）**——`.claude/rules/` 目录下的 Markdown 文件。模块化、按主题划分、团队共享。可通过 YAML frontmatter 中的 glob 模式限定作用范围——比如 TypeScript 规则只在处理 `.ts` 文件时生效。
- **用户记忆（User memory）**——`~/.claude/` 目录下的 `CLAUDE.md` 文件。跨所有项目的个人偏好。
- **项目本地记忆（Project local）**——项目根目录下的 `CLAUDE.local.md` 文件。仅对当前项目、当前用户生效。

所有记忆文件在 Claude 启动时自动加载。CLAUDE.md 文件支持 `@path/to/import` 语法递归导入其他文件（最多 5 层）。`/memory` 命令用于编辑记忆文件，`/init` 用于初始化新项目的 CLAUDE.md。

## 当前限制

Agent Teams 还处于实验阶段。以下是我遇到的或在文档中发现的限制：

- **队友恢复有限**——Lead 会话可以恢复，但 `/resume` 和 `/rewind` 不会恢复进程内的队友。恢复后，lead 可能会尝试向已不存在的队友发消息
- **任务状态可能滞后**——队友有时未能将任务标记为已完成，导致依赖任务被阻塞
- **关闭可能较慢**——队友有时在完成当前请求后过了一段时间才真正关闭
- **每个会话一个团队**——文档说你需要先清理当前团队才能创建新团队。但我不太确定——进程内模式下似乎自动清理并且可以直接创建新团队，这点还需要更多测试。在分屏模式下，关闭面板后尝试创建第二个团队时遇到了面板 ID 过期的问题（见上面的面板章节）
- **不支持嵌套团队**——队友不能创建自己的团队
- **Lead 角色固定**——不能将队友提升为 lead
- **分屏仅限 tmux 和 iTerm2**——不支持 Ghostty、VS Code 和 Windows Terminal
- **权限在生成时设定**——所有队友继承我的权限模式。生成后可以单独修改，但无法在生成时为每个队友指定不同的权限

## 快速上手

以下大致是我启动 Agent Teams 的步骤。

先更新 Claude Code 到最新版本，然后在 `settings.json`（位于 `~/.claude/settings.json`）的 `env` 字段中添加 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` 并设为 `"1"`。

使用分屏模式：

```
claude --teammate-mode tmux
```

使用进程内模式（任何终端）直接正常启动 Claude 即可。

然后给 Claude 一个任务并要求它使用团队。比如："Create a team to review this PR. Have one teammate check for security issues, one check for performance problems, and one verify test coverage. Compare findings when done."

Claude 会创建团队、生成队友、分配任务并汇总结果。团队完成后，它会关闭队友。面板保持打开以供查看。

建议从研究和评审类任务开始——这是我看到最明显收益的地方。这类任务有清晰的边界，能展示并行探索的价值，又不需要并行实现时那样复杂的协调。我自己后续也会主要使用进程内模式，除非有明确的理由才使用 tmux 或 iTerm2 的分屏模式。

如果你发现本文有误或你的体验不同，非常欢迎反馈。以上内容全部基于 2026 年 2 月初的文档和我的亲身测试。

我发现这些功能的方式，和我通常发现 Claude Code 新功能的方式一样——运行 `/docs` 然后直接问它。如果你安装了我的 claude-code-docs 项目（一个定期更新的 Claude Code 文档本地镜像，你的 Claude Code 实例可以通过 manifest 轻松搜索），你也可以这样做。

<https://github.com/ericbuess/claude-code-docs.git>

---

*Claude Code Agent Teams 随 Opus 4.6 于 2026 年 2 月 5 日发布。*
