# Ralph 操作手册（The Ralph Playbook）

2025 年 12 月，[Ralph](https://ghuntley.com/ralph/) 那强大却看起来呆呆的小脸蛋被推上了大多数 AI 相关时间线的风口浪尖。

我一直在关注 [@GeoffreyHuntley](https://x.com/GeoffreyHuntley) 分享的那些极其聪明的见解，但说实话，今年夏天 Ralph 并没有真正让我"开窍"。而最近的这波热议让人很难再忽视它了。

[@mattpocockuk](https://x.com/mattpocockuk/status/2008200878633931247) 和 [@ryancarson](https://x.com/ryancarson/status/2008548371712135632) 的概述帮了大忙——直到 Geoff 本人跳出来[说了句"不对"](https://x.com/GeoffreyHuntley/status/2008731415312236984)。

<img src="references/nah.png" alt="nah" width="500" />

## 那么 Ralph 的最佳用法到底是什么？

很多人似乎用各种各样的方式都取得了不错的效果——但我想尽可能从源头上去研读，毕竟这个方法不仅是由这个人提出的，而且他也是实践时间最长的那个人。

所以我深入研究了[最近的视频](https://www.youtube.com/watch?v=O2bBWDoxO4s)和 Geoff 的[原始文章](https://ghuntley.com/ralph/)，试图为自己理清什么方法才是最有效的。

以下就是结果——一份（可能是强迫症驱动的）Ralph 操作手册，将各种零散的细节组织起来以便实践，希望不会在这个过程中阉割它的精髓。

> 深入研究这些内容的过程中，我还想到了一些可能有价值的[额外增强方案](#增强方案enhancements)，旨在与 Ralph 成功运作的核心准则保持一致。

> [!TIP] > [📖 查看格式化指南 →](https://ClaytonFarr.github.io/ralph-playbook/)

---

## 目录

- [工作流程（Workflow）](#工作流程workflow)
- [核心原则（Key Principles）](#核心原则key-principles)
- [循环机制（Loop Mechanics）](#循环机制loop-mechanics)
- [文件结构（Files）](#文件结构files)
- [增强方案？（Enhancements）](#增强方案enhancements)

---

## 工作流程（Workflow）

一张图胜过千条推文和一个小时的视频。Geoff 的[概述](https://ghuntley.com/ralph/)（注册他的 newsletter 可以看到完整文章）确实帮助我理清了工作流程的细节：从 1) 创意 → 2) 与 JTBD（待完成任务）对齐的独立规格说明（Spec） → 3) 全面的实施计划 → 4) Ralph 工作循环。

![ralph-diagram.png](references/ralph-diagram.png)

### 🗘 三个阶段、两个提示词、一个循环

这张图让我明白了 Ralph 不仅仅是"一个编码循环"。它是一个包含 3 个阶段（Phase）、2 个提示词（Prompt）和 1 个循环（Loop）的漏斗。

#### 阶段一：定义需求（Phase 1. Define Requirements）（LLM 对话）

- 讨论项目创意 → 识别待完成任务（Jobs to Be Done，JTBD）
- 将单个 JTBD 拆分为关注主题（Topic of Concern）
- 使用子代理（subagent）将 URL 中的信息加载到上下文中
- LLM 理解 JTBD 的关注主题后：子代理为每个主题编写 `specs/FILENAME.md`

#### 阶段二 / 三：运行 Ralph 循环（Phase 2 / 3. Run Ralph Loop）（两种模式，根据需要切换 `PROMPT.md`）

同样的循环机制，不同的提示词对应不同的目标：

| 模式                   | 何时使用                      | 提示词聚焦点                         |
| ---------------------- | ----------------------------- | ------------------------------------ |
| _规划模式（PLANNING mode）_ | 计划不存在，或计划已过时/有误 | 仅生成/更新 `IMPLEMENTATION_PLAN.md` |
| _构建模式（BUILDING mode）_ | 计划已存在                    | 按计划实施、提交、附带更新计划       |

_各模式的提示词差异：_

- "规划"提示词执行差距分析（Gap Analysis）（规格说明（Spec） vs 代码），输出优先级排序的待办列表——不实施、不提交。
- "构建"提示词假设计划已存在，从中选取任务，实施，运行测试（反压，backpressure），提交。

_为什么两种模式都使用循环？_

- 构建模式（BUILDING mode）本身就需要循环：本质上是迭代的（多任务 × 全新上下文 = 隔离）
- 规划模式（PLANNING mode）使用循环是为了一致性：相同的执行模型，虽然通常 1-2 次迭代就完成
- 灵活性：如果计划需要优化，循环允许多次读取自身输出
- 简洁性：一种机制处理所有事情；干净的文件 I/O；易于停止/重启

_每次迭代加载的上下文：_ `PROMPT.md` + `AGENTS.md`

_规划模式（PLANNING mode）循环生命周期：_

1. 子代理研读 `specs/*` 和现有的 `/src`
2. 将规格说明（Spec）与代码进行比较（差距分析）
3. 创建/更新 `IMPLEMENTATION_PLAN.md`，包含优先级排序的任务
4. 不进行任何实施

_构建模式（BUILDING mode）循环生命周期：_

1. _定向_ – 子代理研读 `specs/*`（需求）
2. _阅读计划_ – 研读 `IMPLEMENTATION_PLAN.md`
3. _选择_ – 挑选最重要的任务
4. _调查_ – 子代理研读相关的 `/src`（"不要假设未实现"）
5. _实施_ – N 个子代理用于文件操作
6. _验证_ – 1 个子代理用于构建/测试（反压）
7. _更新 `IMPLEMENTATION_PLAN.md`_ – 标记任务完成，记录发现/缺陷
8. _更新 `AGENTS.md`_ – 如果有操作层面的经验教训
9. _提交_
10. _循环结束_ → 上下文清除 → 下一次迭代全新开始

#### 概念

| 术语                                 | 定义                                              |
| ------------------------------------ | ------------------------------------------------- |
| _待完成任务（Job to be Done，JTBD）_ | 高层次的用户需求或期望结果                        |
| _关注主题（Topic of Concern）_       | JTBD 中一个独立的方面/组件                        |
| _规格说明（Spec）_                   | 针对一个关注主题的需求文档（`specs/FILENAME.md`） |
| _任务（Task）_                       | 通过比较规格说明（Spec）与代码得出的工作单元              |

_关系：_

- 1 个 JTBD → 多个关注主题
- 1 个关注主题 → 1 份规格说明（Spec）
- 1 份规格说明（Spec） → 多个任务（规格说明（Spec）的粒度大于任务）

_示例：_

- JTBD："帮助设计师创建情绪板"
- 关注主题：图片收集、颜色提取、布局、分享
- 每个主题 → 一个 spec 文件
- 每个 spec → 实施计划中的多个任务

_主题范围测试："一句话不带'和'"_

- 你能否用一句话（不使用"和"连接不相关的功能）来描述这个关注主题？
  - ✓ "颜色提取系统分析图像以识别主色调"
  - ✗ "用户系统处理认证、用户资料和计费" → 这是 3 个主题
- 如果你需要用"和"来描述它做什么，那它可能是多个主题

---

## 核心原则（Key Principles）

### ⏳ 上下文就是*一切*

- 当宣称的 200K+ token = 实际可用约 176K
- 且 40-60% 的上下文利用率为"智能区间（smart zone）"
- 精简任务 + 每次循环 1 个任务 = _100% 智能区间上下文利用率_

这个原则驱动和影响着其他所有设计：

- _将主代理/上下文用作调度器（scheduler）_
  - 不要将高开销的工作分配给主上下文；尽可能生成子代理来处理
- _将子代理用作内存扩展_
  - 每个子代理获得约 156kb，用完即回收（garbage collected）
  - 分散处理以避免污染主上下文
- _简洁至上_
  - 适用于系统的部件数量、循环配置和内容
  - 冗长的输入会降低确定性（determinism）
- _优先使用 Markdown 而非 JSON_
  - 用于定义和跟踪工作，以获得更好的 token 效率

### 🧭 引导 Ralph：模式 + 反压（Patterns + Backpressure）

创建正确的信号和门控来引导 Ralph 成功输出是**至关重要的**。你可以从两个方向进行引导：

- _上游引导（Steer upstream）_
  - 确保确定性的设置：
    - 将前约 5,000 个 token 分配给规格说明（Spec）
    - 每次循环的上下文都加载相同的文件，使模型从已知状态开始（`PROMPT.md` + `AGENTS.md`）
  - 你现有的代码会影响生成和使用的内容
  - 如果 Ralph 生成了错误的模式，添加/更新工具函数和现有代码模式来引导它走向正确的方向
- _下游引导（Steer downstream）_
  - 通过测试、类型检查、代码检查（lint）、构建等创建反压（backpressure），用以拒绝无效/不可接受的工作
  - 提示词中泛泛地说"运行测试"。`AGENTS.md` 指定实际命令以使反压具有项目特定性
  - 反压可以超越代码验证的范畴：某些验收标准无法通过程序化检查来验证——创意质量、美学、用户体验感受。LLM 作为评审（LLM-as-judge）测试可以为主观标准提供具有二元通过/失败结果的反压。（[下面有更详细的思考](#非确定性反压non-deterministic-backpressure)关于如何在 Ralph 中实现这一点。）
- _提醒 Ralph 创建/使用反压_
  - 在实施时提醒 Ralph 使用反压："重要：在编写文档时，记录原因（why）——测试和实施的重要性。"

### 🙏 让 Ralph 做 Ralph（Let Ralph Ralph）

Ralph 的有效性来自于你对它的信任程度——信任它最终会做对事情——以及你促进其能力的方式。

- _让 Ralph 做 Ralph_
  - 充分利用 LLM 的自我识别、自我纠正和自我改进能力
  - 适用于实施计划、任务定义和优先级排序
  - 通过迭代实现最终一致性（eventual consistency）
- _做好防护_
  - 为了自主运行，Ralph 需要 `--dangerously-skip-permissions`——在每次工具调用时请求批准会打断循环。这完全绕过了 Claude 的权限系统——因此沙箱（sandbox）成为你唯一的安全边界。
  - 理念："不是会不会被攻破的问题，而是什么时候被攻破。以及爆炸半径有多大？"
  - 不使用沙箱运行会暴露你机器上的凭证、浏览器 cookie、SSH 密钥和访问令牌
  - 在隔离环境中运行，仅提供最小可行的访问权限：
    - 仅需任务所需的 API 密钥和部署密钥
    - 不访问需求以外的私有数据
    - 尽可能限制网络连接
  - 选项：Docker 沙箱（本地），Fly Sprites/E2B 等（远程/生产）- [附加说明](references/sandbox-environments.md)
  - 额外的逃生通道：Ctrl+C 停止循环；`git reset --hard` 回滚未提交的更改；如果轨迹偏离则重新生成计划

### 🚦 站在循环外面（Move Outside the Loop）

要最大化发挥 Ralph 的价值，你需要让开他的路。Ralph 应该完成*所有*工作，包括决定接下来实施哪项计划工作以及如何实施。你的工作现在是坐在循环上面而不是里面——去设计能让 Ralph 成功的配置和环境。

_观察与纠偏_ – 尤其是在早期，坐下来观察。出现了什么模式？Ralph 在哪里出错？它需要什么信号？你开始时的提示词不会是你最终的提示词——它们通过观察到的失败模式来演化。

_像调吉他一样调优_ – 不要一开始就规定所有东西，而是观察并被动调整。当 Ralph 以某种特定方式失败时，添加一个信号来帮助它下次做对。

但信号不仅仅是提示词文本。它是 Ralph 可以发现的*任何东西*：

- 提示词护栏 - 明确的指示，如"不要假设未实现"
- `AGENTS.md` - 关于如何构建/测试的操作性经验
- 你代码库中的工具函数 - 当你添加一个模式时，Ralph 会发现并遵循它
- 其他可发现的相关输入……

记住，_计划是可丢弃的：_

- 如果它是错的，扔掉重来
- 重新生成的成本只是一次规划循环；比 Ralph 原地打转便宜得多
- 在以下情况下重新生成：
  - Ralph 跑偏了（实施了错误的东西，重复工作）
  - 计划感觉过时或与当前状态不符
  - 已完成的项目过多导致杂乱
  - 你做了重大的规格说明（Spec）变更
  - 你搞不清楚什么实际上已经完成了

---

## 循环机制（Loop Mechanics）

### 外循环控制（Outer Loop Control）

Geoff 的 `loop.sh` 脚本初始最简形式：

```bash
while :; do cat PROMPT.md | claude ; done
```

_注意：_ 同样的方式可以用于其他 CLI 工具；例如 `amp`、`codex`、`opencode` 等。

_什么控制任务的延续？_

延续机制非常优雅简洁：

1. _Bash 循环运行_ → 将 `PROMPT.md` 输入给 claude
2. _PROMPT.md 指示_ → "研读 IMPLEMENTATION_PLAN.md 并选择最重要的事项"
3. _代理完成一个任务_ → 更新磁盘上的 IMPLEMENTATION_PLAN.md，提交，退出
4. _Bash 循环立即重启_ → 全新的上下文窗口
5. _代理读取更新后的计划_ → 选择下一个最重要的事项

_关键洞察：_ IMPLEMENTATION_PLAN.md 文件在迭代之间持久化在磁盘上，充当原本隔离的循环执行之间的共享状态。每次迭代确定性地加载相同的文件（`PROMPT.md` + `AGENTS.md` + `specs/*`）并从磁盘读取当前状态。

_不需要复杂的编排_ - 只需要一个愚蠢的 bash 循环不断重启代理，代理通过每次读取计划文件来弄清楚接下来该做什么。

### 内循环控制（Inner Loop Control）（任务执行）

单个任务执行没有硬性的技术限制。控制依赖于：

- _范围纪律_ - PROMPT.md 指示"一个任务"和"测试通过后提交"
- _反压_ - 测试/构建失败迫使代理在提交前修复问题
- _自然完成_ - 代理在成功提交后退出

_Ralph 可能会原地打转、忽略指示或走错方向_ - 这是预期中的，是调优过程的一部分。当 Ralph 以特定方式"考验你"时，你在提示词中添加护栏或调整反压机制。非确定性通过观察和迭代是可管理的。

### 增强版循环示例

在核心循环基础上封装了模式选择（规划/构建）、最大迭代次数支持和每次迭代后的 git push。

_此增强版使用两个保存的提示词文件：_

- `PROMPT_plan.md` - 规划模式（PLANNING mode）（差距分析，生成/更新计划）
- `PROMPT_build.md` - 构建模式（BUILDING mode）（按计划实施）

```bash
#!/bin/bash
# Usage: ./loop.sh [plan] [max_iterations]
# Examples:
#   ./loop.sh              # Build mode, unlimited iterations
#   ./loop.sh 20           # Build mode, max 20 iterations
#   ./loop.sh plan         # Plan mode, unlimited iterations
#   ./loop.sh plan 5       # Plan mode, max 5 iterations

# Parse arguments
if [ "$1" = "plan" ]; then
    # Plan mode
    MODE="plan"
    PROMPT_FILE="PROMPT_plan.md"
    MAX_ITERATIONS=${2:-0}
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    # Build mode with max iterations
    MODE="build"
    PROMPT_FILE="PROMPT_build.md"
    MAX_ITERATIONS=$1
else
    # Build mode, unlimited (no arguments or invalid input)
    MODE="build"
    PROMPT_FILE="PROMPT_build.md"
    MAX_ITERATIONS=0
fi

ITERATION=0
CURRENT_BRANCH=$(git branch --show-current)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Mode:   $MODE"
echo "Prompt: $PROMPT_FILE"
echo "Branch: $CURRENT_BRANCH"
[ $MAX_ITERATIONS -gt 0 ] && echo "Max:    $MAX_ITERATIONS iterations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verify prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: $PROMPT_FILE not found"
    exit 1
fi

while true; do
    if [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"
        break
    fi

    # Run Ralph iteration with selected prompt
    # -p: Headless mode (non-interactive, reads from stdin)
    # --dangerously-skip-permissions: Auto-approve all tool calls (YOLO mode)
    # --output-format=stream-json: Structured output for logging/monitoring
    # --model opus: Primary agent uses Opus for complex reasoning (task selection, prioritization)
    #               Can use 'sonnet' in build mode for speed if plan is clear and tasks well-defined
    # --verbose: Detailed execution logging
    cat "$PROMPT_FILE" | claude -p \
        --dangerously-skip-permissions \
        --output-format=stream-json \
        --model opus \
        --verbose

    # Push changes after each iteration
    git push origin "$CURRENT_BRANCH" || {
        echo "Failed to push. Creating remote branch..."
        git push -u origin "$CURRENT_BRANCH"
    }

    ITERATION=$((ITERATION + 1))
    echo -e "\n\n======================== LOOP $ITERATION ========================\n"
done
```

_模式选择：_

- 无关键字 → 使用 `PROMPT_build.md` 进行构建（实施）
- `plan` 关键字 → 使用 `PROMPT_plan.md` 进行规划（差距分析、计划生成）

_最大迭代次数：_

- 限制的是*外循环*（尝试的任务数量；不是单个任务中的工具调用次数）
- 每次迭代 = 一个全新的上下文窗口 = IMPLEMENTATION_PLAN.md 中的一个任务 = 一次提交
- `./loop.sh` 无限运行（手动用 Ctrl+C 停止）
- `./loop.sh 20` 最多运行 20 次迭代后停止

_Claude CLI 参数：_

- `-p`（无头模式，headless mode）：启用非交互操作，从标准输入读取提示词
- `--dangerously-skip-permissions`：跳过所有权限提示，实现全自动运行
- `--output-format=stream-json`：输出结构化 JSON 用于日志/监控/可视化
- `--model opus`：主代理使用 Opus 进行任务选择、优先级排序和协调（如果任务明确可以使用 `sonnet` 以提高速度）
- `--verbose`：提供详细的执行日志

---

## 文件结构（Files）

```
project-root/
├── loop.sh                         # Ralph 循环脚本
├── PROMPT_build.md                 # 构建模式（BUILDING mode）指令
├── PROMPT_plan.md                  # 规划模式（PLANNING mode）指令
├── AGENTS.md                       # 每次迭代加载的操作指南
├── IMPLEMENTATION_PLAN.md          # 优先级排序的任务列表（由 Ralph 生成/更新）
├── specs/                          # 需求规格说明（Spec）（每个 JTBD 主题一份）
│   ├── [jtbd-topic-a].md
│   └── [jtbd-topic-b].md
├── src/                            # 应用源代码
└── src/lib/                        # 共享工具函数和组件
```

### `loop.sh`

编排 Ralph 迭代的外循环脚本。

详细的实现示例和配置选项请参见[循环机制](#循环机制loop-mechanics)章节。

_设置：_ 首次使用前使脚本可执行：

```bash
chmod +x loop.sh
```

_核心功能：_ 持续将提示词文件输入给 claude，管理迭代限制，并在每次任务完成后推送更改。

### 提示词（PROMPTS）

每次循环迭代的指令集。根据需要在规划和构建版本之间切换。

_提示词结构：_

| 部分                   | 目的                                     |
| ---------------------- | ---------------------------------------- |
| _阶段 0_（0a, 0b, 0c） | 定向：研读规格说明（Spec）、源代码位置、当前计划 |
| _阶段 1-4_             | 主指令：任务、验证、提交                 |
| _999... 编号_          | 护栏/不变量（数字越大 = 越关键）         |

_关键语言模式_（Geoff 的特定措辞）：

- "study"（研读）（不是 "read" 或 "look at"）
- "don't assume not implemented"（不要假设未实现）（关键——阿喀琉斯之踵）
- "using parallel subagents"（使用并行子代理）/ "up to N subagents"
- "only 1 subagent for build/tests"（构建/测试仅用 1 个子代理）（反压控制）
- "Think extra hard"（现为 "Ultrathink"）
- "capture the why"（记录原因）
- "keep it up to date"（保持更新）
- "if functionality is missing then it's your job to add it"（如果功能缺失那就是你的工作）
- "resolve them or document them"（解决或记录它们）

#### `PROMPT_plan.md` 模板

_注意：_

- 更新下方的 [project-specific goal]（项目特定目标）占位符。
- 当前子代理名称假设使用 Claude。

```
0a. Study `specs/*` with up to 250 parallel Sonnet subagents to learn the application specifications.
0b. Study @IMPLEMENTATION_PLAN.md (if present) to understand the plan so far.
0c. Study `src/lib/*` with up to 250 parallel Sonnet subagents to understand shared utilities & components.
0d. For reference, the application source code is in `src/*`.

1. Study @IMPLEMENTATION_PLAN.md (if present; it may be incorrect) and use up to 500 Sonnet subagents to study existing source code in `src/*` and compare it against `specs/*`. Use an Opus subagent to analyze findings, prioritize tasks, and create/update @IMPLEMENTATION_PLAN.md as a bullet point list sorted in priority of items yet to be implemented. Ultrathink. Consider searching for TODO, minimal implementations, placeholders, skipped/flaky tests, and inconsistent patterns. Study @IMPLEMENTATION_PLAN.md to determine starting point for research and keep it up to date with items considered complete/incomplete using subagents.

IMPORTANT: Plan only. Do NOT implement anything. Do NOT assume functionality is missing; confirm with code search first. Treat `src/lib` as the project's standard library for shared utilities and components. Prefer consolidated, idiomatic implementations there over ad-hoc copies.

ULTIMATE GOAL: We want to achieve [project-specific goal]. Consider missing elements and plan accordingly. If an element is missing, search first to confirm it doesn't exist, then if needed author the specification at specs/FILENAME.md. If you create a new element then document the plan to implement it in @IMPLEMENTATION_PLAN.md using a subagent.
```

#### `PROMPT_build.md` 模板

_注意：_ 当前子代理名称假设使用 Claude。

```
0a. Study `specs/*` with up to 500 parallel Sonnet subagents to learn the application specifications.
0b. Study @IMPLEMENTATION_PLAN.md.
0c. For reference, the application source code is in `src/*`.

1. Your task is to implement functionality per the specifications using parallel subagents. Follow @IMPLEMENTATION_PLAN.md and choose the most important item to address. Before making changes, search the codebase (don't assume not implemented) using Sonnet subagents. You may use up to 500 parallel Sonnet subagents for searches/reads and only 1 Sonnet subagent for build/tests. Use Opus subagents when complex reasoning is needed (debugging, architectural decisions).
2. After implementing functionality or resolving problems, run the tests for that unit of code that was improved. If functionality is missing then it's your job to add it as per the application specifications. Ultrathink.
3. When you discover issues, immediately update @IMPLEMENTATION_PLAN.md with your findings using a subagent. When resolved, update and remove the item.
4. When the tests pass, update @IMPLEMENTATION_PLAN.md, then `git add -A` then `git commit` with a message describing the changes. After the commit, `git push`.

99999. Important: When authoring documentation, capture the why — tests and implementation importance.
999999. Important: Single sources of truth, no migrations/adapters. If tests unrelated to your work fail, resolve them as part of the increment.
9999999. As soon as there are no build or test errors create a git tag. If there are no git tags start at 0.0.0 and increment patch by 1 for example 0.0.1  if 0.0.0 does not exist.
99999999. You may add extra logging if required to debug issues.
999999999. Keep @IMPLEMENTATION_PLAN.md current with learnings using a subagent — future work depends on this to avoid duplicating efforts. Update especially after finishing your turn.
9999999999. When you learn something new about how to run the application, update @AGENTS.md using a subagent but keep it brief. For example if you run commands multiple times before learning the correct command then that file should be updated.
99999999999. For any bugs you notice, resolve them or document them in @IMPLEMENTATION_PLAN.md using a subagent even if it is unrelated to the current piece of work.
999999999999. Implement functionality completely. Placeholders and stubs waste efforts and time redoing the same work.
9999999999999. When @IMPLEMENTATION_PLAN.md becomes large periodically clean out the items that are completed from the file using a subagent.
99999999999999. If you find inconsistencies in the specs/* then use an Opus 4.5 subagent with 'ultrathink' requested to update the specs.
999999999999999. IMPORTANT: Keep @AGENTS.md operational only — status updates and progress notes belong in `IMPLEMENTATION_PLAN.md`. A bloated AGENTS.md pollutes every future loop's context.
```

### `AGENTS.md`

唯一的、权威的"循环核心"——一份简洁的、操作性的"如何运行/构建"指南。

- 不是变更日志或进度日记
- 描述如何构建/运行项目
- 记录改进循环的操作性经验
- 保持简短（约 60 行）

状态、进度和计划属于 `IMPLEMENTATION_PLAN.md`，不属于这里。

_回环 / 即时自我评估（Loopback / Immediate Self-Evaluation）：_

AGENTS.md 应包含启用回环的项目特定命令——即 Ralph 在同一循环内立即评估自己工作的能力。这包括：

- 构建命令
- 测试命令（针对性和全套）
- 类型检查/代码检查命令
- 任何其他验证工具

构建提示词泛泛地说"运行测试"；AGENTS.md 指定实际命令。这就是反压如何按项目接入的方式。

#### 示例

```
## Build & Run

Succinct rules for how to BUILD the project:

## Validation

Run these after implementing to get immediate feedback:

- Tests: `[test command]`
- Typecheck: `[typecheck command]`
- Lint: `[lint command]`

## Operational Notes

Succinct learnings about how to RUN the project:

...

### Codebase Patterns

...
```

### `IMPLEMENTATION_PLAN.md`

从差距分析（规格说明（Spec） vs 代码）中得出的优先级排序的要点列表任务——由 Ralph 生成。

- _创建_ 通过规划模式（PLANNING mode）
- _更新_ 在构建模式（BUILDING mode）期间（标记完成、添加发现、记录缺陷）
- _可以重新生成_ – Geoff："我已经多次删除了 TODO 列表" → 切换到规划模式（PLANNING mode）
- _自我纠正_ – 构建模式（BUILDING mode）甚至可以在缺失时创建新的规格说明（Spec）

循环性是有意为之的：通过迭代实现最终一致性。

_无预设模板_ - 让 Ralph/LLM 自行决定和管理最适合它的格式。

### `specs/*`

每个关注主题一个 Markdown 文件。这些是应该构建什么的真实来源（source of truth）。

- 在需求阶段创建（人类 + LLM 对话）
- 被规划模式（PLANNING mode）和构建模式（BUILDING mode）共同使用
- 如果发现不一致可以更新（罕见，使用子代理）

_无预设模板_ - 让 Ralph/LLM 自行决定和管理最适合它的格式。

### `src/` 和 `src/lib/`

应用源代码和共享工具函数/组件。

在 `PROMPT.md` 模板中用于定向步骤的引用。

---

## 增强方案？（Enhancements）

我（Clayton）仍在评估这些可能增强方案的价值和可行性，但这些机会听起来很有前景。

- [使用 Claude 的 AskUserQuestionTool 进行规划](#使用-claude-的-askuserquestiontool-进行规划) - 使用 Claude 内置的访谈工具来系统性地澄清 JTBD、边界情况和规格说明（Spec）的验收标准。
- [验收驱动的反压（Acceptance-Driven Backpressure）](#验收驱动的反压acceptance-driven-backpressure) - 在规划阶段从验收标准中推导测试需求。防止"作弊"——没有适当的测试通过就不能声称完成。
- [非确定性反压（Non-Deterministic Backpressure）](#非确定性反压non-deterministic-backpressure) - 使用 LLM 作为评审来测试主观任务（语气、美学、用户体验）。二元通过/失败审查，迭代直到通过。
- [Ralph 友好的工作分支（Ralph-Friendly Work Branches）](#ralph-友好的工作分支ralph-friendly-work-branches) - 在运行时要求 Ralph "过滤到功能 X"是不可靠的。相反，在前期为每个分支创建有范围的计划。
- [JTBD → 故事地图 → SLC 发布](#jtbd--故事地图story-map-slc-发布) - 将"让 Ralph 做 Ralph"的力量推进到将 JTBD 的受众和活动连接到简单/可爱/完整（Simple/Lovable/Complete）的发布。

---

### 使用 Claude 的 AskUserQuestionTool 进行规划

在阶段一（定义需求）中，使用 Claude 内置的 `AskUserQuestionTool`，通过结构化访谈来系统性地探索 JTBD、关注主题、边界情况和验收标准，然后再编写规格说明（Spec）。

_何时使用：_ 初始需求极简/模糊，需要澄清约束条件，或存在多种有效方案。

_调用方式：_ "Interview me using AskUserQuestion to understand [JTBD/topic/acceptance criteria/...]"（使用 AskUserQuestion 采访我以了解 [JTBD/主题/验收标准/...]）

Claude 会提出有针对性的问题来澄清需求并确保在生成 `specs/*.md` 文件之前达成一致。

_流程：_

1. 从已知信息开始 →
2. _Claude 通过 AskUserQuestion 进行访谈_ →
3. 迭代直到清晰 →
4. Claude 编写包含验收标准的规格说明（Spec） →
5. 进入规划/构建阶段

不需要任何代码或提示词变更——这只是利用现有的 Claude Code 功能来增强阶段一。

_灵感来源_ - [Thariq 的 X 帖子](https://x.com/trq212/status/2005315275026260309)：

---

### 验收驱动的反压（Acceptance-Driven Backpressure）

Geoff 的 Ralph _隐式地_ 通过涌现迭代（emergent iteration）将规格说明（Spec） → 实施 → 测试连接起来。这个增强方案会通过在规划阶段推导测试需求来使这种连接*显式化*，建立从"成功是什么样子"到"什么来验证它"的直接关联。

这个增强方案将验收标准（在规格说明（Spec）中）直接连接到测试需求（在实施计划中），通过以下方式提高反压质量：

- _防止"作弊"_ - 没有从验收标准推导出的必要测试通过，就不能声称完成
- _启用 TDD 工作流_ - 在实施开始前就知道测试需求
- _改善收敛性_ - 清晰的完成信号（必要测试通过）vs 模糊的（"好像做完了？"）
- _维持确定性_ - 测试需求在计划中（已知状态）而非涌现的（概率性的）

#### 与核心理念的兼容性

| 原则                             | 是否保持？ | 如何保持                               |
| -------------------------------- | ---------- | -------------------------------------- |
| 单体操作（Monolithic operation） | ✅ 是      | 一个代理，一个任务，一次一个循环       |
| 反压至关重要                     | ✅ 是      | 测试是机制，只是现在显式推导了         |
| 上下文效率                       | ✅ 是      | 规划一次性确定测试 vs 构建时重复发现   |
| 确定性设置                       | ✅ 是      | 测试需求在计划中（已知状态）而非涌现的 |
| 让 Ralph 做 Ralph                | ✅ 是      | Ralph 仍然优先排序并选择实施方案       |
| 计划可丢弃                       | ✅ 是      | 测试需求错了？重新生成计划             |
| "记录原因"                       | ✅ 是      | 测试意图在实施前记录在计划中           |
| 不作弊                           | ✅ 是      | 必要测试防止占位符式实施               |

#### 规范性的平衡

关键区分：

_验收标准_（在规格说明（Spec）中）= 行为结果，可观察的结果，成功是什么样子

- ✅ "从任何上传的图像中提取 5-10 个主色调"
- ✅ "处理 <5MB 的图像在 <100ms 内完成"
- ✅ "处理边界情况：灰度图、单色图、透明背景"

_测试需求_（在实施计划中）= 从验收标准推导出的验证点

- ✅ "必要测试：提取 5-10 个颜色，性能 <100ms，处理灰度边界情况"

_实施方案_（由 Ralph 决定）= 关于如何实现的技术决策

- ❌ "使用 K-means 聚类，3 次迭代和 LAB 色彩空间转换"

关键：_指定验证什么（结果），而非如何实施（方法）_

这维持了"让 Ralph 做 Ralph"的原则——Ralph 决定实施细节，同时拥有清晰的成功信号。

#### 架构：三阶段连接

```
Phase 1: Requirements Definition
    specs/*.md + Acceptance Criteria
    ↓
Phase 2: Planning (derives test requirements)
    IMPLEMENTATION_PLAN.md + Required Tests
    ↓
Phase 3: Building (implements with tests)
    Implementation + Tests → Backpressure
```

#### 阶段一：需求定义

在产出规格说明（Spec）的人类 + LLM 对话过程中：

- 讨论 JTBD 并拆分为关注主题
- 根据需要使用子代理加载外部上下文
- _讨论并定义验收标准_ - 什么可观察的、可验证的结果表明成功
- 保持标准是行为性的（结果），而非实施性的（如何构建）
- LLM 以最合理的方式编写包含验收标准的规格说明（Spec）
- 验收标准成为在规划阶段推导测试需求的基础

#### 阶段二：规划模式（PLANNING mode）增强

修改 `PROMPT_plan.md` 的指令 1 以包含测试推导。在第一句之后添加：

```markdown
For each task in the plan, derive required tests from acceptance criteria in specs - what specific outcomes need verification (behavior, performance, edge cases). Tests verify WHAT works, not HOW it's implemented. Include as part of task definition.
```

#### 阶段三：构建模式（BUILDING mode）增强

修改 `PROMPT_build.md` 指令：

_指令 1：_ 在 "choose the most important item to address" 之后添加：

```markdown
Tasks include required tests - implement tests as part of task scope.
```

_指令 2：_ 将 "run the tests for that unit of code" 替换为：

```markdown
run all required tests specified in the task definition. All required tests must exist and pass before the task is considered complete.
```

_在 9 系列序列中前置新护栏：_

```markdown
999. Required tests derived from acceptance criteria must exist and pass before committing. Tests are part of implementation scope, not optional. Test-driven development approach: tests can be written first or alongside implementation.
```

---

### 非确定性反压（Non-Deterministic Backpressure）

某些验收标准无法通过程序化验证：

- _创意质量_ - 写作语气、叙事流畅度、吸引力
- _美学判断_ - 视觉和谐、设计平衡、品牌一致性
- _用户体验质量_ - 直觉式导航、清晰的信息层次
- _内容适当性_ - 上下文感知的信息传达、受众适配

这些需要类人判断，但也需要反压来确保在构建循环中满足验收标准。

_解决方案：_ 添加 LLM 作为评审（LLM-as-Judge）测试作为具有二元通过/失败结果的反压。

LLM 审查是非确定性的（同一产物在不同运行中可能收到不同判断）。这与 Ralph 的理念一致："在非确定性世界中做到确定性地不好。" 循环通过迭代提供最终一致性——审查运行直到通过，接受自然方差。

#### 需要创建什么（第一步）

在 `src/lib/` 中创建两个文件：

```
src/lib/
  llm-review.ts          # 核心工具 - 单一函数，简洁 API
  llm-review.test.ts     # 参考示例，展示使用模式（Ralph 从中学习）
```

##### `llm-review.ts` - Ralph 可发现的二元通过/失败 API：

```typescript
interface ReviewResult {
  pass: boolean;
  feedback?: string; // Only present when pass=false
}

function createReview(config: {
  criteria: string; // What to evaluate (behavioral, observable)
  artifact: string; // Text content OR screenshot path
  intelligence?: "fast" | "smart"; // Optional, defaults to 'fast'
}): Promise<ReviewResult>;
```

_多模态支持：_ 两种智能级别都使用多模态模型（文本 + 视觉）。产物类型检测是自动的：

- 文本评估：`artifact: "Your content here"` → 作为文本输入路由
- 视觉评估：`artifact: "./tmp/screenshot.png"` → 作为视觉输入路由（检测 .png, .jpg, .jpeg 扩展名）

_智能级别_（判断质量，而非能力类型）：

- `fast`（默认）：快速、低成本的模型，用于直接的评估
  - 示例：Gemini 3.0 Flash（多模态、快速、廉价）
- `smart`：更高质量的模型，用于细致的美学/创意判断
  - 示例：GPT 5.1（多模态、更好的判断力、更高成本）

工具函数的实现负责选择合适的模型。（示例是当前的选项，不是要求。）

##### `llm-review.test.ts` - 向 Ralph 展示如何使用（文本和视觉示例）：

```typescript
import { createReview } from "@/lib/llm-review";

// Example 1: Text evaluation
test("welcome message tone", async () => {
  const message = generateWelcomeMessage();
  const result = await createReview({
    criteria:
      "Message uses warm, conversational tone appropriate for design professionals while clearly conveying value proposition",
    artifact: message, // Text content
  });
  expect(result.pass).toBe(true);
});

// Example 2: Vision evaluation (screenshot path)
test("dashboard visual hierarchy", async () => {
  await page.screenshot({ path: "./tmp/dashboard.png" });
  const result = await createReview({
    criteria:
      "Layout demonstrates clear visual hierarchy with obvious primary action",
    artifact: "./tmp/dashboard.png", // Screenshot path
  });
  expect(result.pass).toBe(true);
});

// Example 3: Smart intelligence for complex judgment
test("brand visual consistency", async () => {
  await page.screenshot({ path: "./tmp/homepage.png" });
  const result = await createReview({
    criteria:
      "Visual design maintains professional brand identity suitable for financial services while avoiding corporate sterility",
    artifact: "./tmp/homepage.png",
    intelligence: "smart", // Complex aesthetic judgment
  });
  expect(result.pass).toBe(true);
});
```

_Ralph 从这些示例中学习：_ 文本和截图都可以作为产物使用。根据需要评估的内容来选择。工具函数在内部处理其余部分。

_未来可扩展性：_ 当前设计为了简洁使用单一的 `artifact: string`。如果出现明确的模式需要多个产物（前后对比、跨项目一致性、多角度评估），可以扩展为 `artifact: string | string[]`。组合截图或拼接文本可以处理大多数多项目需求。

#### 与 Ralph 工作流的集成

_规划阶段_ - 更新 `PROMPT_plan.md`：

在以下内容之后：

```
...Study @IMPLEMENTATION_PLAN.md to determine starting point for research and keep it up to date with items considered complete/incomplete using subagents.
```

插入这段：

```
When deriving test requirements from acceptance criteria, identify whether verification requires programmatic validation (measurable, inspectable) or human-like judgment (perceptual quality, tone, aesthetics). Both types are equally valid backpressure mechanisms. For subjective criteria that resist programmatic validation, explore src/lib for non-deterministic evaluation patterns.
```

_构建阶段_ - 更新 `PROMPT_build.md`：

在 9 系列序列中前置新护栏：

```markdown
9999. Create tests to verify implementation meets acceptance criteria and include both conventional tests (behavior, performance, correctness) and perceptual quality tests (for subjective criteria, see src/lib patterns).
```

_发现而非文档化（Discovery, not documentation）：_ Ralph 在 `src/lib` 探索阶段（Phase 0c）从 `llm-review.test.ts` 示例中学习 LLM 审查模式。无需更新 AGENTS.md——代码示例就是文档。

#### 与核心理念的兼容性

| 原则              | 是否保持？ | 如何保持                                                                           |
| ----------------- | ---------- | ---------------------------------------------------------------------------------- |
| 反压至关重要      | ✅ 是      | 将反压扩展到非程序化验收                                                           |
| 确定性设置        | ⚠️ 部分    | 标准在计划中（确定性），评估是非确定性的但通过迭代收敛。这是对主观质量的有意权衡。 |
| 上下文效率        | ✅ 是      | 工具函数通过 `src/lib` 复用，测试定义体积小                                        |
| 让 Ralph 做 Ralph | ✅ 是      | Ralph 发现模式，选择何时使用，编写标准                                             |
| 计划可丢弃        | ✅ 是      | 审查需求是计划的一部分，错了就重新生成                                             |
| 简洁至上          | ✅ 是      | 单一函数，二元结果，无评分复杂性                                                   |
| 为 Ralph 添加信号 | ✅ 是      | 轻量级提示词补充，从代码探索中学习                                                 |

---

### Ralph 友好的工作分支（Ralph-Friendly Work Branches）

_关键原则：_ Geoff 的 Ralph 从单一的、可丢弃的计划中工作，由 Ralph 选择"最重要的"。要在使用分支的同时维持这个模式，你必须在计划创建时限定范围，而非在任务选择时。

_为什么这很重要：_

- ❌ _错误方法_：创建完整计划，然后要求 Ralph 在运行时"过滤"任务 → 不可靠（70-80%），违反确定性
- ✅ _正确方法_：为每个工作分支提前创建有范围限定的计划 → 确定性、简单、维持"计划可丢弃"

_解决方案：_ 添加 `plan-work` 模式来在当前分支上创建工作范围限定的 IMPLEMENTATION_PLAN.md。用户创建工作分支，然后使用自然语言描述工作重点来运行 `plan-work`。LLM 使用此描述来限定计划范围。规划完成后，Ralph 从已限定范围的计划中构建，无需任何语义过滤——像往常一样选择"最重要的"。

_术语：_ "工作（Work）"故意使用宽泛的含义——它可以描述功能特性、关注主题、重构工作、基础设施变更、缺陷修复或任何具有内聚性的相关变更体。你传递给 `plan-work` 的工作描述是给 LLM 的自然语言——可以是散文，不受 git 分支命名规则的约束。

#### 设计原则

- ✅ *每个 Ralph 会话在一个分支上单体运行*一个工作体
- ✅ _用户手动创建分支_ - 完全控制命名约定和策略（如 worktree）
- ✅ _自然语言工作描述_ - 向 LLM 传递散文，不受 git 命名规则约束
- ✅ _在计划创建时限定范围_（确定性）而非任务选择时（概率性）
- ✅ _每个分支单一计划_ - 每个分支一个 IMPLEMENTATION_PLAN.md
- ✅ _计划保持可丢弃_ - 当分支的计划错误/过时时重新生成有范围的计划
- ✅ 循环会话内不动态切换分支
- ✅ 维持简洁性和确定性
- ✅ 可选——主分支工作流仍然有效
- ✅ 构建时无语义过滤——Ralph 只选择"最重要的"

#### 工作流程

_1. 完整规划（在主分支上）_

```bash
./loop.sh plan
# 为整个项目生成完整的 IMPLEMENTATION_PLAN.md
```

_2. 创建工作分支_

用户执行：

```bash
git checkout -b ralph/user-auth-oauth
# 用你偏好的任何命名约定创建分支
# 建议：使用 ralph/* 前缀命名工作分支
```

_3. 有范围的规划（在工作分支上）_

```bash
./loop.sh plan-work "user authentication system with OAuth and session management"
# 传入自然语言描述 - LLM 用它来限定计划范围
# 创建仅包含此工作任务的聚焦 IMPLEMENTATION_PLAN.md
```

_4. 按计划构建（在工作分支上）_

```bash
./loop.sh
# Ralph 从有范围的计划构建（无需过滤）
# 从已限定范围的计划中选择最重要的任务
```

_5. 创建 PR（工作完成时）_

用户执行：

```bash
gh pr create --base main --head ralph/user-auth-oauth --fill
```

#### 工作范围循环脚本

扩展基础增强版循环脚本，添加工作分支支持和有范围的规划：

```bash
#!/bin/bash
set -euo pipefail

# Usage:
#   ./loop.sh [plan] [max_iterations]       # Plan/build on current branch
#   ./loop.sh plan-work "work description"  # Create scoped plan on current branch
# Examples:
#   ./loop.sh                               # Build mode, unlimited
#   ./loop.sh 20                            # Build mode, max 20
#   ./loop.sh plan 5                        # Full planning, max 5
#   ./loop.sh plan-work "user auth"         # Scoped planning

# Parse arguments
MODE="build"
PROMPT_FILE="PROMPT_build.md"

if [ "$1" = "plan" ]; then
    # Full planning mode
    MODE="plan"
    PROMPT_FILE="PROMPT_plan.md"
    MAX_ITERATIONS=${2:-0}
elif [ "$1" = "plan-work" ]; then
    # Scoped planning mode
    if [ -z "$2" ]; then
        echo "Error: plan-work requires a work description"
        echo "Usage: ./loop.sh plan-work \"description of the work\""
        exit 1
    fi
    MODE="plan-work"
    WORK_DESCRIPTION="$2"
    PROMPT_FILE="PROMPT_plan_work.md"
    MAX_ITERATIONS=${3:-5}  # Default 5 for work planning
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    # Build mode with max iterations
    MAX_ITERATIONS=$1
else
    # Build mode, unlimited
    MAX_ITERATIONS=0
fi

ITERATION=0
CURRENT_BRANCH=$(git branch --show-current)

# Validate branch for plan-work mode
if [ "$MODE" = "plan-work" ]; then
    if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
        echo "Error: plan-work should be run on a work branch, not main/master"
        echo "Create a work branch first: git checkout -b ralph/your-work"
        exit 1
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Mode:    plan-work"
    echo "Branch:  $CURRENT_BRANCH"
    echo "Work:    $WORK_DESCRIPTION"
    echo "Prompt:  $PROMPT_FILE"
    echo "Plan:    Will create scoped IMPLEMENTATION_PLAN.md"
    [ "$MAX_ITERATIONS" -gt 0 ] && echo "Max:     $MAX_ITERATIONS iterations"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Warn about uncommitted changes to IMPLEMENTATION_PLAN.md
    if [ -f "IMPLEMENTATION_PLAN.md" ] && ! git diff --quiet IMPLEMENTATION_PLAN.md 2>/dev/null; then
        echo "Warning: IMPLEMENTATION_PLAN.md has uncommitted changes that will be overwritten"
        read -p "Continue? [y/N] " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi

    # Export work description for PROMPT_plan_work.md
    export WORK_SCOPE="$WORK_DESCRIPTION"
else
    # Normal plan/build mode
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Mode:   $MODE"
    echo "Branch: $CURRENT_BRANCH"
    echo "Prompt: $PROMPT_FILE"
    echo "Plan:   IMPLEMENTATION_PLAN.md"
    [ "$MAX_ITERATIONS" -gt 0 ] && echo "Max:    $MAX_ITERATIONS iterations"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

# Verify prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: $PROMPT_FILE not found"
    exit 1
fi

# Main loop
while true; do
    if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"

        if [ "$MODE" = "plan-work" ]; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Scoped plan created: $WORK_DESCRIPTION"
            echo "To build, run:"
            echo "  ./loop.sh 20"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        fi
        break
    fi

    # Run Ralph iteration with selected prompt
    # -p: Headless mode (non-interactive, reads from stdin)
    # --dangerously-skip-permissions: Auto-approve all tool calls (YOLO mode)
    # --output-format=stream-json: Structured output for logging/monitoring
    # --model opus: Primary agent uses Opus for complex reasoning (task selection, prioritization)
    #               Can use 'sonnet' for speed if plan is clear and tasks well-defined
    # --verbose: Detailed execution logging

    # For plan-work mode, substitute ${WORK_SCOPE} in prompt before piping
    if [ "$MODE" = "plan-work" ]; then
        envsubst < "$PROMPT_FILE" | claude -p \
            --dangerously-skip-permissions \
            --output-format=stream-json \
            --model opus \
            --verbose
    else
        cat "$PROMPT_FILE" | claude -p \
            --dangerously-skip-permissions \
            --output-format=stream-json \
            --model opus \
            --verbose
    fi

    # Push to current branch
    CURRENT_BRANCH=$(git branch --show-current)
    git push origin "$CURRENT_BRANCH" || {
        echo "Failed to push. Creating remote branch..."
        git push -u origin "$CURRENT_BRANCH"
    }

    ITERATION=$((ITERATION + 1))
    echo -e "\n\n======================== LOOP $ITERATION ========================\n"
done
```

#### `PROMPT_plan_work.md` 模板

_注意：_ 与 `PROMPT_plan.md` 相同，但增加了范围限定指令和 `WORK_SCOPE` 环境变量替换（由循环脚本自动完成）。

```
0a. Study `specs/*` with up to 250 parallel Sonnet subagents to learn the application specifications.
0b. Study @IMPLEMENTATION_PLAN.md (if present) to understand the plan so far.
0c. Study `src/lib/*` with up to 250 parallel Sonnet subagents to understand shared utilities & components.
0d. For reference, the application source code is in `src/*`.

1. You are creating a SCOPED implementation plan for work: "${WORK_SCOPE}". Study @IMPLEMENTATION_PLAN.md (if present; it may be incorrect) and use up to 500 Sonnet subagents to study existing source code in `src/*` and compare it against `specs/*`. Use an Opus subagent to analyze findings, prioritize tasks, and create/update @IMPLEMENTATION_PLAN.md as a bullet point list sorted in priority of items yet to be implemented. Ultrathink. Consider searching for TODO, minimal implementations, placeholders, skipped/flaky tests, and inconsistent patterns. Study @IMPLEMENTATION_PLAN.md to determine starting point for research and keep it up to date with items considered complete/incomplete using subagents.

IMPORTANT: This is SCOPED PLANNING for "${WORK_SCOPE}" only. Create a plan containing ONLY tasks directly related to this work scope. Be conservative - if uncertain whether a task belongs to this work, exclude it. The plan can be regenerated if too narrow. Plan only. Do NOT implement anything. Do NOT assume functionality is missing; confirm with code search first. Treat `src/lib` as the project's standard library for shared utilities and components. Prefer consolidated, idiomatic implementations there over ad-hoc copies.

ULTIMATE GOAL: We want to achieve the scoped work "${WORK_SCOPE}". Consider missing elements related to this work and plan accordingly. If an element is missing, search first to confirm it doesn't exist, then if needed author the specification at specs/FILENAME.md. If you create a new element then document the plan to implement it in @IMPLEMENTATION_PLAN.md using a subagent.
```

#### 与核心理念的兼容性

| 原则               | 是否保持？ | 如何保持                                                           |
| ------------------ | ---------- | ------------------------------------------------------------------ |
| 单体操作           | ✅ 是      | Ralph 仍作为分支内的单一进程运行                                   |
| 每次循环一个任务   | ✅ 是      | 不变                                                               |
| 全新上下文         | ✅ 是      | 不变                                                               |
| 确定性             | ✅ 是      | 在计划创建时限定范围（确定性），而非运行时（概率性）               |
| 简洁               | ✅ 是      | 可选增强，主工作流仍然有效                                         |
| 计划驱动           | ✅ 是      | 每个分支一个 IMPLEMENTATION_PLAN.md                                |
| 单一真实来源       | ✅ 是      | 每个分支一个计划——有范围的计划替换分支上的完整计划                 |
| 计划可丢弃         | ✅ 是      | 随时重新生成有范围的计划：`./loop.sh plan-work "work description"` |
| Markdown 优于 JSON | ✅ 是      | 仍然是 Markdown 计划                                               |
| 让 Ralph 做 Ralph  | ✅ 是      | Ralph 从已限定范围的计划中选择"最重要的"——无需过滤                 |

---

### JTBD → 故事地图（Story Map）→ SLC 发布

#### 关注主题 → 活动（Activities）

Geoff 的[建议工作流](https://ghuntley.com/content/images/size/w2400/2025/07/The-ralph-Process.png)已经将规划与待完成任务（JTBD）对齐——将 JTBD 拆分为关注主题，再转化为规格说明（Spec）。我很喜欢这个方式，我认为有机会通过将*关注主题*重新定义为*活动（Activities）*来进一步发挥这种方法的产品优势。

活动是旅程中的动词（"上传照片"、"提取颜色"），而非能力（"颜色提取系统"）。它们天然地按用户意图来限定范围。

> 主题："颜色提取"、"布局引擎" → 能力导向
> 活动："上传照片"、"查看提取的颜色"、"排列布局" → 旅程导向

#### 活动 → 用户旅程

活动——及其组成步骤——自然地排列成用户流程，创建一个*旅程结构*，使差距和依赖关系可见。[用户故事地图（User Story Map）](https://www.nngroup.com/articles/user-story-mapping/)将活动组织为列（旅程骨架），将能力深度组织为行——这是*可以*构建的完整空间：

```
UPLOAD    →   EXTRACT    →   ARRANGE     →   SHARE

basic         auto           manual          export
bulk          palette        templates       collab
batch         AI themes      auto-layout     embed
```

#### 用户旅程 → 发布切片（Release Slices）

通过地图的水平切片成为候选发布。不是每个活动都需要在每个发布中有新能力——有些格子保持空白，只要切片仍然是连贯的就没问题：

```
                  UPLOAD    →   EXTRACT    →   ARRANGE     →   SHARE

Release 1:        basic         auto                           export
                  ───────────────────────────────────────────────────
Release 2:                      palette        manual
                  ───────────────────────────────────────────────────
Release 3:        batch         AI themes      templates       embed
```

#### 发布切片 → SLC 发布

故事地图给你提供切片的*结构*。Jason Cohen 的 _[简单、可爱、完整（Simple, Lovable, Complete，SLC）](https://longform.asmartbear.com/slc/)_ 给你提供判断切片好坏的*标准*：

- _简单（Simple）_ — 可以快速发布的窄范围。不是每个活动，不是每个深度。
- _完整（Complete）_ — 在该范围内完全完成一项工作。不是一个残缺的预览。
- _可爱（Lovable）_ — 人们真的想用它。在其边界内令人愉悦。

_为什么选 SLC 而非 MVP？_ MVP 以牺牲客户体验来优化学习——"最小"往往意味着破碎或令人沮丧。SLC 翻转了这一点：在市场中学习的*同时*提供真正的价值。如果成功了，你有更多选择权。如果失败了，你至少善待了用户。

每个切片可以成为一个具有明确价值和身份的发布：

```
                  UPLOAD    →   EXTRACT    →   ARRANGE     →   SHARE

Palette Picker:   basic         auto                           export
                  ───────────────────────────────────────────────────
Mood Board:                     palette        manual
                  ───────────────────────────────────────────────────
Design Studio:    batch         AI themes      templates       embed
```

- _Palette Picker（色板选择器）_ — 上传、提取、导出。从第一天起就有即时价值。
- _Mood Board（情绪板）_ — 添加排列功能。创意表达进入旅程。
- _Design Studio（设计工作室）_ — 专业功能：批量处理、AI 主题、可嵌入输出。

---

#### 与 Ralph 的实际操作

上述概念——活动、故事地图、SLC 发布——是*思维工具*。我们如何将它们转化为 Ralph 的工作流？

_默认的 Ralph 方法：_

1. _定义需求_：人类 + LLM 定义 JTBD 关注主题 → `specs/*.md`
2. _创建任务计划_：LLM 分析所有规格说明（Spec） + 当前代码 → `IMPLEMENTATION_PLAN.md`
3. _构建_：Ralph 针对完整范围构建

这对以能力为中心的工作（功能特性、重构、基础设施）效果很好。但它不会自然地产出有价值的（SLC）产品发布——它产出的是"规格说明（Spec）描述的任何东西"。

_活动 → SLC 发布方法：_

要获得 SLC 发布，我们需要将活动扎根于受众上下文。受众定义了谁拥有 JTBD，这反过来决定了什么活动重要以及"可爱"意味着什么。

```
受众（Audience，谁）
    └── 拥有 JTBD（为什么）
            └── 通过活动（Activities）来实现（怎么做）
```

##### 工作流程

_I. 需求阶段（2 个步骤）：_

仍在人类与 LLM 的对话中进行，类似于默认的 Ralph 方法。

1. _定义受众及其 JTBD_ — 我们为谁构建，他们想要什么结果？
   - 人类 + LLM 讨论并确定受众及其 JTBD（他们想要的结果）
   - 可能包含多个关联的受众（例如"设计师"创建，"客户"审阅）
   - 生成 `AUDIENCE_JTBD.md`

2. _定义活动_ — 用户做什么来完成他们的 JTBD？
   - 以 `AUDIENCE_JTBD.md` 为参考
   - 对每个 JTBD，识别完成它所需的活动
   - 对每个活动，确定：
     - 能力深度（基础 → 增强）——精细度的层级
     - 每个深度的期望结果——成功是什么样子？
   - 生成 `specs/*.md`（每个活动一份）

   活动中的离散步骤是隐式的，LLM 可以在规划期间推断。

_II. 规划阶段：_

在 Ralph 循环中使用*更新的*规划提示词进行。

- LLM 分析：
  - `AUDIENCE_JTBD.md`（谁，期望结果）
  - `specs/*`（可以构建什么）
  - 当前代码状态（已有什么）
- LLM 确定下一个 SLC 切片（哪些活动、在什么能力深度）并为该切片规划任务
- LLM 生成 `IMPLEMENTATION_PLAN.md`
- *人类验证*构建前的计划：
  - 范围是否代表一个连贯的 SLC 发布？
  - 是否包含了正确深度的正确活动？
  - 如果不对 → 重新运行规划循环以重新生成计划，可选择更新输入或规划提示词
  - 如果正确 → 进入构建阶段

_III. 构建阶段：_

在 Ralph 循环中使用标准构建提示词进行。

##### 更新的规划提示词

`PROMPT_plan.md` 的变体，添加了受众上下文和 SLC 导向的切片推荐。

_注意：_

- 与默认模板不同，这里没有 `[project-specific goal]` 占位符——目标是隐含的：为受众推荐最有价值的下一个发布。
- 当前子代理名称假设使用 Claude。

```
0a. Study @AUDIENCE_JTBD.md to understand who we're building for and their Jobs to Be Done.
0b. Study `specs/*` with up to 250 parallel Sonnet subagents to learn JTBD activities.
0c. Study @IMPLEMENTATION_PLAN.md (if present) to understand the plan so far.
0d. Study `src/lib/*` with up to 250 parallel Sonnet subagents to understand shared utilities & components.
0e. For reference, the application source code is in `src/*`.

1. Sequence the activities in `specs/*` into a user journey map for the audience in @AUDIENCE_JTBD.md. Consider how activities flow into each other and what dependencies exist.

2. Determine the next SLC release. Use up to 500 Sonnet subagents to compare `src/*` against `specs/*`. Use an Opus subagent to analyze findings. Ultrathink. Given what's already implemented recommend which activities (at what capability depths) form the most valuable next release. Prefer thin horizontal slices - the narrowest scope that still delivers real value. A good slice is Simple (narrow, achievable), Lovable (people want to use it), and Complete (fully accomplishes a meaningful job, not a broken preview).

3. Use an Opus subagent (ultrathink) to analyze and synthesize the findings, prioritize tasks, and create/update @IMPLEMENTATION_PLAN.md as a bullet point list sorted in priority of items yet to be implemented for the recommended SLC release. Begin plan with a summary of the recommended SLC release (what's included and why), then list prioritized tasks for that scope. Consider TODOs, placeholders, minimal implementations, skipped tests - but scoped to the release. Note discoveries outside scope as future work.

IMPORTANT: Plan only. Do NOT implement anything. Do NOT assume functionality is missing; confirm with code search first. Treat `src/lib` as the project's standard library for shared utilities and components. Prefer consolidated, idiomatic implementations there over ad-hoc copies.

ULTIMATE GOAL: We want to achieve the most valuable next release for the audience in @AUDIENCE_JTBD.md. Consider missing elements and plan accordingly. If an element is missing, search first to confirm it doesn't exist, then if needed author the specification at specs/FILENAME.md. If you create a new element then document the plan to implement it in @IMPLEMENTATION_PLAN.md using a subagent.
```

##### 说明

_为什么 `AUDIENCE_JTBD.md` 作为单独的制品：_

- 单一真实来源——防止跨规格说明（Spec）的漂移
- 启用全局推理："这个受众最需要什么？"
- JTBD 与受众一同记录（"为什么"与"谁"在一起）
- 被引用两次：在规格说明（Spec）创建和 SLC 规划时
- 让活动规格说明（Spec）专注于"做什么"，而不是重复"为谁做"

_基数关系：_

- 一个受众 → 多个 JTBD（"设计师"有"捕捉空间"、"探索概念"、"向客户展示"）
- 一个 JTBD → 多个活动（"捕捉空间"包括上传、测量、房间检测）
- 一个活动 → 可以服务多个 JTBD（"上传照片"同时服务于"捕捉"和"收集灵感"）
