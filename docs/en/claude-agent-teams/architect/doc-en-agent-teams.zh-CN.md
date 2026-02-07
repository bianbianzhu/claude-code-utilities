> 翻译基于 [英文版 commit d1c0365](https://github.com/anthropics/claude-code-utilities/commit/d1c0365a66cfa88d30f4d61700ae1af39410c440) | [English Version](doc-en-agent-teams.md)

> ## 文档索引
>
> 完整文档索引请访问：https://code.claude.com/docs/llms.txt
> 通过该文件可查阅所有可用页面。

# 编排 Claude Code agent teams

> 协调多个 Claude Code 实例组成团队协作，支持共享任务、agent 间通信和集中管理。

Agent teams 为实验性功能，默认关闭。需在 `settings.json` 或环境变量中添加 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` 来启用。Agent teams 存在[已知限制](#限制)，涉及会话恢复、任务协调和关闭行为。

Agent teams 允许你协调多个 Claude Code 实例协同工作。

- 其中一个会话担任 **team lead**，负责协调工作、分配任务和汇总结果。

- **Teammates** 独立运行，各自拥有独立的上下文窗口，彼此之间可以直接通信。

与 subagents 不同——subagents 运行在单个会话内，只能向主 agent 汇报——你还可以直接与单个 teammate 交互，无需通过 lead 中转。

本页内容包括：

- [何时使用 agent teams](#何时使用-agent-teams)，包括最佳使用场景以及与 subagents 的对比
- [启动团队](#启动你的第一个-agent-team)
- [控制 teammates](#控制你的-agent-team)，包括显示模式、任务分配和委派
- [并行工作最佳实践](#最佳实践)

## 何时使用 agent teams

Agent teams 最适合并行探索能带来实际价值的任务。完整场景请参阅[用例示例](#用例示例)。最典型的使用场景包括：

- **调研与审查**：多个 teammates 可同时调查问题的不同方面，然后共享并互相质疑发现
- **新模块或功能**：每个 teammate 负责一个独立部分，互不干扰
- **多假设并行调试**：teammates 并行验证不同假说，更快定位答案
- **跨层协调**：前端、后端和测试的跨层变更，分别由不同 teammate 负责

Agent teams 会增加协调开销，token 消耗也远高于单会话。最适合 teammates 能独立运作的场景。

> 对于顺序性任务、同文件编辑或强依赖关系的工作，单会话或 subagents 更高效。

### 与 subagents 对比

Agent teams 和 subagents 都支持并行化工作，但运作方式不同。根据 worker 之间是否需要互相通信来选择：

|                | Subagents                        | Agent teams                              |
| :------------- | :------------------------------- | :--------------------------------------- |
| **上下文**     | 独立上下文窗口；结果返回给调用者 | 独立上下文窗口；完全独立                 |
| **通信方式**   | 仅向主 agent 汇报结果            | Teammates 之间直接通信                   |
| **协调方式**   | 主 agent 管理所有工作            | 共享任务列表，自主协调                   |
| **适用场景**   | 只需结果的聚焦任务               | 需要讨论和协作的复杂工作                 |
| **Token 开销** | 较低：结果汇总回主上下文         | 较高：每个 teammate 是独立的 Claude 实例 |

需要快速、聚焦的 worker 并汇报结果时，使用 subagents。需要 teammates 之间共享发现、互相质疑并自主协调时，使用 agent teams。

## 启用 agent teams

Agent teams 默认关闭。通过将 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` 环境变量设为 `1` 来启用，可在 shell 环境或 `settings.json` 中设置：

```json settings.json theme={null}
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## 启动你的第一个 agent team

启用 agent teams 后，告诉 Claude 创建一个 agent team，用自然语言描述任务和所需的团队结构。Claude 会创建团队、生成 teammates，并根据你的 prompt 协调工作。

以下示例效果良好，因为三个角色相互独立，可以各自探索问题而无需等待彼此：

```
I'm designing a CLI tool that helps developers track TODO comments across
their codebase. Create an agent team to explore this from different angles: one
teammate on UX, one on technical architecture, one playing devil's advocate.
```

随后，Claude 创建一个带有共享任务列表的团队，为每个视角生成 teammate，让他们探索问题，汇总发现，并在完成后尝试[清理团队](#清理团队)。

Lead 的终端会列出所有 teammates 及其当前工作。使用 Shift+Up/Down 选择一个 teammate 并直接发消息。

如果希望每个 teammate 有独立的分屏面板，请参阅[选择显示模式](#选择显示模式)。

## 控制你的 agent team

用自然语言告诉 lead 你的需求。它会根据你的指令处理团队协调、任务分配和委派。

### 选择显示模式

Agent teams 支持两种显示模式：

- **In-process（进程内）**：所有 teammates 在主终端内运行。使用 Shift+Up/Down 选择 teammate 并直接输入消息。适用于任何终端，无需额外配置。
- **Split panes（分屏面板）**：每个 teammate 拥有独立面板。可同时查看所有人的输出，点击面板即可直接交互。需要 tmux 或 iTerm2。

`tmux` 在某些操作系统上存在已知限制，传统上在 macOS 上表现最佳。建议在 iTerm2 中使用 `tmux -CC` 作为进入 `tmux` 的方式。

默认值为 `"auto"`：如果你已在 tmux 会话中运行，则使用分屏面板模式，否则使用 in-process 模式。

`"tmux"` 设置启用分屏面板模式，并根据终端自动检测使用 tmux 还是 iTerm2。如需覆盖，在 `settings.json` 中设置 `teammateMode`：

```json theme={null}
{
  "teammateMode": "in-process"
}
```

单次会话强制使用 in-process 模式，可通过启动参数指定：

```bash theme={null}
claude --teammate-mode in-process
```

分屏面板模式需要 [tmux](https://github.com/tmux/tmux/wiki) 或 iTerm2 并安装 [`it2` CLI](https://github.com/mkusaka/it2)。手动安装方式：

- **tmux**：通过系统包管理器安装。各平台安装说明请参阅 [tmux wiki](https://github.com/tmux/tmux/wiki/Installing)。
- **iTerm2**：安装 [`it2` CLI](https://github.com/mkusaka/it2)，然后在 **iTerm2 → Settings → General → Magic → Enable Python API** 中启用 Python API。

### 指定 teammates 和模型

Claude 根据任务自动决定生成多少个 teammates，你也可以明确指定：

```
Create a team with 4 teammates to refactor these modules in parallel.
Use Sonnet for each teammate.
```

### 要求 teammates 提交计划审批

对于复杂或高风险任务，可以要求 teammates 在实施前先制定计划。Teammate 在只读 plan mode 下工作，直到 lead 批准其方案：

```
Spawn an architect teammate to refactor the authentication module.
Require plan approval before they make any changes.
```

Teammate 完成规划后，会向 lead 发送计划审批请求。Lead 审查计划并批准或附带反馈拒绝。如被拒绝，teammate 留在 plan mode 中，根据反馈修改后重新提交。一旦批准，teammate 退出 plan mode 并开始实施。

Lead 自主做出审批决策。要影响 lead 的判断，可在 prompt 中给出标准，例如"仅批准包含测试覆盖的计划"或"拒绝修改数据库 schema 的计划"。

### 使用 delegate mode

不启用 delegate mode 时，lead 有时会自己开始实现任务而非等待 teammates。Delegate mode 将 lead 限制为仅使用协调工具：生成 teammate、发送消息、关闭 teammate 和管理任务。

适用于希望 lead 专注于编排——拆分工作、分配任务和汇总结果——而不直接接触代码的场景。

启用方式：先启动团队，然后按 Shift+Tab 切换到 delegate mode。

### 直接与 teammates 对话

每个 teammate 都是一个完整、独立的 Claude Code 会话。你可以直接向任何 teammate 发消息，给出额外指令、追问或调整其方向。

- **In-process 模式**：使用 Shift+Up/Down 选择 teammate，然后输入发送消息。按 Enter 查看 teammate 的会话，按 Escape 中断其当前轮次。按 Ctrl+T 切换任务列表。
- **Split-pane 模式**：点击 teammate 的面板直接与其会话交互。每个 teammate 都有完整的独立终端视图。

### 分配和认领任务

共享任务列表协调团队间的工作。Lead 创建任务，teammates 逐一完成。任务有三种状态：待处理（pending）、进行中（in progress）和已完成（completed）。任务还可以设置依赖关系：有未完成依赖的待处理任务在依赖完成前无法被认领。

Lead 可以显式分配任务，teammates 也可以自行认领：

- **Lead 分配**：告诉 lead 将哪个任务分配给哪个 teammate
- **自行认领**：teammate 完成一个任务后，自动领取下一个未分配、未阻塞的任务

任务认领使用文件锁机制，防止多个 teammates 同时认领同一任务时出现竞态条件。

### 关闭 teammates

优雅地结束 teammate 会话：

```
Ask the researcher teammate to shut down
```

Lead 发送关闭请求。Teammate 可以同意并优雅退出，或拒绝并说明原因。

### 清理团队

工作完成后，让 lead 清理：

```
Clean up the team
```

这会移除共享的团队资源。Lead 执行清理时会检查活跃 teammates，如果仍有 teammate 在运行则会失败，因此需先关闭所有 teammates。

> 务必通过 lead 执行清理。Teammates 不应自行清理，因为其团队上下文可能无法正确解析，可能导致资源处于不一致状态。

### 通过 hooks 实施质量门禁

使用 hooks 在 teammates 完成工作或任务完成时实施规则：

- `TeammateIdle`：teammate 即将进入空闲时触发。以退出码 2 退出可发送反馈并让 teammate 继续工作。
- `TaskCompleted`：任务被标记为完成时触发。以退出码 2 退出可阻止完成并发送反馈。

## Agent teams 工作原理

本节介绍 agent teams 的架构和运行机制。如需开始使用，请参阅上方的[控制你的 agent team](#控制你的-agent-team)。

### Claude 如何启动 agent teams

Agent teams 有两种启动方式：

- **你主动请求**：给 Claude 一个适合并行处理的任务，并明确要求创建 agent team。Claude 根据你的指令创建团队。
- **Claude 主动建议**：如果 Claude 判断你的任务适合并行处理，可能会建议创建团队。你确认后才会执行。

两种情况下，控制权都在你手中。Claude 不会在未经你同意的情况下创建团队。

### 架构

一个 agent team 由以下组件构成：

| 组件                      | 职责                                                         |
| :------------------------ | :----------------------------------------------------------- |
| **Team lead**             | 主 Claude Code 会话，负责创建团队、生成 teammates 和协调工作 |
| **Teammates**             | 独立的 Claude Code 实例，各自处理分配的任务                  |
| **Task list（任务列表）** | teammates 认领和完成的共享工作项列表                         |
| **Mailbox（信箱）**       | agent 之间的通信系统                                         |

显示配置选项请参阅[选择显示模式](#选择显示模式)。Teammate 的消息会自动送达 lead。

系统自动管理任务依赖关系。当 teammate 完成了其他任务所依赖的任务时，被阻塞的任务会自动解除阻塞，无需手动干预。

团队和任务数据存储在本地：

- **团队配置**：`~/.claude/teams/{team-name}/config.json`
- **任务列表**：`~/.claude/tasks/{team-name}/`

团队配置文件包含 `members` 数组，记录每个 teammate 的名称、agent ID 和 agent 类型。Teammates 可以读取此文件来发现其他团队成员。

### 权限

Teammates 启动时继承 lead 的权限设置。如果 lead 以 `--dangerously-skip-permissions` 运行，所有 teammates 也会如此。生成后可以修改单个 teammate 的模式，但无法在生成时设置逐 teammate 的权限模式。

### 上下文与通信

每个 teammate 拥有独立的上下文窗口。生成时，teammate 加载与常规会话相同的项目上下文：CLAUDE.md、MCP servers 和 skills。它还会收到来自 lead 的 spawn prompt。Lead 的对话历史不会继承。

**Teammates 如何共享信息：**

- **自动消息送达**：teammates 发送的消息会自动送达接收方。Lead 无需轮询更新。
- **空闲通知**：teammate 完成工作并停止时，会自动通知 lead。
- **共享任务列表**：所有 agent 都能查看任务状态并认领可用工作。

**Teammate 消息方式：**

- **message**：向特定 teammate 发送消息
- **broadcast**：同时发送给所有 teammates。由于开销随团队规模增长，应谨慎使用。

### Token 消耗

Agent teams 的 token 消耗远高于单会话。每个 teammate 拥有独立的上下文窗口，token 使用量随活跃 teammates 数量线性增长。对于调研、审查和新功能开发，额外的 token 开销通常是值得的。对于常规任务，单会话更具性价比。使用指南请参阅 agent team token 开销相关文档。

## 用例示例

以下示例展示 agent teams 如何处理并行探索能带来价值的任务。

### 并行代码审查

单个 reviewer 往往会在某一时间偏向某类问题。将审查标准拆分为独立领域，意味着安全性、性能和测试覆盖率都能同时得到充分关注。Prompt 为每个 teammate 分配不同的审查视角以避免重叠：

```
Create an agent team to review PR #142. Spawn three reviewers:
- One focused on security implications
- One checking performance impact
- One validating test coverage
Have them each review and report findings.
```

每个 reviewer 审查同一个 PR，但应用不同的关注点。所有人完成后，lead 汇总各方发现。

### 竞争性假设调查

当根本原因不明确时，单个 agent 往往找到一个合理解释就停止了。Prompt 通过设计对抗性机制来应对：每个 teammate 的职责不仅是调查自己的假说，还要质疑其他人的假说。

```
Users report the app exits after one message instead of staying connected.
Spawn 5 agent teammates to investigate different hypotheses. Have them talk to
each other to try to disprove each other's theories, like a scientific
debate. Update the findings doc with whatever consensus emerges.
```

辩论结构是关键机制。顺序调查容易产生锚定效应（anchoring）：一旦探索了某个假说，后续调查就会偏向它。

多个独立调查者积极尝试推翻彼此的假说，最终存活下来的假说更可能是真正的根本原因。

## 最佳实践

### 为 teammates 提供充分的上下文

Teammates 会自动加载项目上下文（包括 CLAUDE.md、MCP servers 和 skills），但不会继承 lead 的对话历史。详情参阅[上下文与通信](#上下文与通信)。在 spawn prompt 中包含任务特定的细节：

```
Spawn a security reviewer teammate with the prompt: "Review the authentication module
at src/auth/ for security vulnerabilities. Focus on token handling, session
management, and input validation. The app uses JWT tokens stored in
httpOnly cookies. Report any issues with severity ratings."
```

### 合理划分任务粒度

- **太小**：协调开销超过收益
- **太大**：teammates 长时间独立工作而缺乏检查点，增加浪费风险
- **恰当**：自包含的工作单元，能产出明确的交付物——如一个函数、一个测试文件或一份审查报告

<Tip>
  Lead 会自动将工作拆分为任务并分配给 teammates。如果创建的任务不够多，要求它将工作拆分成更小的部分。每个 teammate 分配 5-6 个任务可以保持高效运转，也方便 lead 在某人卡住时重新分配工作。
</Tip>

### 等待 teammates 完成

有时 lead 会自己开始实现任务而非等待 teammates。如果发现这种情况：

```
Wait for your teammates to complete their tasks before proceeding
```

### 从调研和审查开始

如果你刚接触 agent teams，建议先从边界清晰、不需要写代码的任务开始：审查 PR、调研技术库或排查 bug。这类任务能展示并行探索的价值，同时避免并行实现带来的协调挑战。

### 避免文件冲突

两个 teammates 编辑同一个文件会导致覆盖。将工作拆分为每个 teammate 负责不同的文件集。

### 监控和引导

定期检查 teammates 的进展，及时调整低效的方向，并在发现产出时及时汇总。让团队长时间无人看管会增加浪费风险。

## 故障排除

### Teammates 未出现

如果请求 Claude 创建团队后 teammates 没有出现：

- 在 in-process 模式下，teammates 可能已在运行但不可见。按 Shift+Down 浏览活跃的 teammates。
- 检查你给 Claude 的任务是否足够复杂，值得组建团队。Claude 会根据任务判断是否需要生成 teammates。
- 如果你明确要求了分屏面板，确保 tmux 已安装且在 PATH 中：
  ```bash theme={null}
  which tmux
  ```
- 对于 iTerm2，确认已安装 `it2` CLI 并在 iTerm2 偏好设置中启用了 Python API。

### 权限提示过多

Teammate 的权限请求会冒泡到 lead，可能造成干扰。在生成 teammates 前，在权限设置中预先批准常见操作以减少中断。

### Teammates 遇错停止

Teammates 可能在遇到错误后停止而非恢复。在 in-process 模式下使用 Shift+Up/Down 或在 split 模式下点击面板查看其输出，然后选择：

- 直接给予额外指令
- 生成替代 teammate 继续工作

### Lead 在工作完成前关闭

Lead 可能在所有任务实际完成前就判定团队已完成。如果发生这种情况，告诉它继续。你也可以告诉 lead 在开始做事之前等待 teammates 完成。

### 残留的 tmux 会话

如果团队结束后 tmux 会话仍然存在，可能是未完全清理。列出会话并终止团队创建的那个：

```bash theme={null}
tmux ls
tmux kill-session -t <session-name>
```

## 限制

Agent teams 是实验性功能。需注意的当前限制：

- **In-process teammates 不支持会话恢复**：`/resume` 和 `/rewind` 不会恢复 in-process teammates。恢复会话后，lead 可能尝试向已不存在的 teammates 发消息。遇到此情况，让 lead 生成新的 teammates。
- **任务状态可能滞后**：teammates 有时未能将任务标记为已完成，导致依赖任务被阻塞。如果任务看起来卡住了，检查工作是否实际已完成，手动更新任务状态或让 lead 催促 teammate。
- **关闭可能较慢**：teammates 会在关闭前完成当前请求或工具调用，这可能需要一些时间。
- **每个会话一个团队**：lead 同一时间只能管理一个团队。启动新团队前需清理当前团队。
- **不支持嵌套团队**：teammates 无法生成自己的团队或 teammates。只有 lead 可以管理团队。
- **Lead 固定不变**：创建团队的会话在整个生命周期内都是 lead。无法将 teammate 提升为 lead 或转移领导权。
- **权限在生成时设定**：所有 teammates 启动时继承 lead 的权限模式。生成后可修改单个 teammate 的模式，但无法在生成时设置逐 teammate 的权限模式。
- **分屏面板需要 tmux 或 iTerm2**：默认的 in-process 模式适用于任何终端。分屏面板模式不支持 VS Code 内置终端、Windows Terminal 或 Ghostty。

<Tip>
  **`CLAUDE.md` 正常工作**：teammates 会从其工作目录读取 `CLAUDE.md` 文件。利用此机制可为所有 teammates 提供项目特定的指导。
</Tip>

## 后续探索

了解并行工作和委派的其他方式：

- **轻量级委派**：subagents 在你的会话中生成辅助 agent 进行调研或验证，更适合不需要 agent 间协调的任务
- **手动并行会话**：Git worktrees 允许你自行运行多个 Claude Code 会话，无需自动化团队协调
- **方案对比**：参阅 subagent 与 agent team 对比的并排分析
