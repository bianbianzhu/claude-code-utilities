# Spec 生成规范指南

本文档定义 brainstorming skill 在"Presenting the design"阶段产出 spec 文件的标准。
目标：让 spec 能被 Ralph Loop（或任何自主 AI agent loop）正确消费，避免复制粘贴、类型漂移、过时 API 等连锁问题。

---

## 核心原则

**Spec 是行为契约，不是实现蓝图。**

Spec 回答三个问题：

1. **做什么**（职责、行为、数据流向）
2. **做到什么程度**（验收标准、约束条件）
3. **失败时怎么办**（错误策略、回滚策略）

Spec **不**回答：

- 用哪个类、哪个方法、哪行代码来实现
- 用哪个 library 的哪个 API
- 具体的 retry 次数、backoff 系数、连接池大小

---

## 双层 Contracts 架构

```
Spec 层（brainstorming 产出）         Planning 层（Ralph planning mode 产出）
─────────────────────────────        ──────────────────────────────────────
抽象接口清单                          src/lib/types/ 下的可 import 类型
字段名 + 类型 + 必填/可选 + 约束       具体语言的 dataclass / interface
枚举值 + 错误码                       完整的类型定义 + validation
行为契约（输入 → 输出 → 副作用）       ─
验收标准                              ─
```

**Spec 层负责"定义什么"——Planning 层负责"翻译成代码"。**

Spec 层的抽象 contract 示例：

```markdown
## 事务记录（Transaction Record）

| 字段           | 类型             | 必填 | 约束                                                   |
| -------------- | ---------------- | ---- | ------------------------------------------------------ |
| transaction_id | string           | 是   | UUID v4                                                |
| session_id     | string           | 是   | 关联到 session                                         |
| status         | enum             | 是   | running / completed / rolled_back / cancelled / failed |
| steps          | list[StepRecord] | 是   | 按执行顺序                                             |
| started_at     | datetime         | 是   | UTC                                                    |
| completed_at   | datetime         | 否   | 成功或失败时填入                                       |
```

这**不是**代码。这是 schema 约束。Planning 阶段的 Ralph 会据此生成对应语言的类型定义。

---

## 写什么 / 不写什么

### 必须写

| 内容                   | 说明                                        | 示例                                                                   |
| ---------------------- | ------------------------------------------- | ---------------------------------------------------------------------- |
| **组件职责**           | 一句话说明该组件做什么                      | "Transaction Manager 追踪工作流执行状态，失败时回滚到初始状态"         |
| **行为契约**           | 输入 → 输出 → 副作用                        | "begin(session_id, workflow_name) → 创建事务记录，返回 transaction_id" |
| **抽象 data shape**    | 字段、类型、必填/可选、枚举、约束           | 见上方表格示例                                                         |
| **验收标准**           | 可观察、可验证、可测试的结果（至少 3-5 条） | "回滚后所有可逆步骤被补偿；不可逆步骤报告但不补偿"                     |
| **失败模式与策略**     | 常见失败场景 + 期望行为                     | "session 过期时，孤立事务在 35 分钟内清理"                             |
| **模块间数据流向**     | 哪些数据从 A 流向 B                         | "Executor 将 ExecutionResult 返回给 ConversationManager"               |
| **约束条件**           | 性能、安全、顺序、兼容性                    | "所有 datetime 存储为 UTC；API 超时不超过 60s"                         |
| **决策理由**           | 为什么选这个方案而不是其他                  | "选 JWT pass-through 而非自主验签，因为 SaaS API 已有完整验签逻辑"     |
| **依赖声明（抽象化）** | 需要的能力 + 版本范围                       | "需要 HTTP client（支持 async + retry + 连接池）"                      |
| **架构图**             | ASCII/Mermaid，展示组件关系和数据流         | 保留，这是有价值的                                                     |

### 禁止写

| 内容                         | 为什么不写                             | 替代方案                        |
| ---------------------------- | -------------------------------------- | ------------------------------- |
| **完整类/方法实现**          | Agent 会原样复制，绕过自主决策         | 用行为描述替代                  |
| **具体 library API 调用**    | Library 更新后 spec 过时，导致语法错误 | 写"需要的能力"，不写具体调用    |
| **方法体内的逻辑代码**       | 混淆 spec 与实现，导致伪代码被照搬     | 用自然语言描述逻辑流程          |
| **具体配置值**               | 属于部署/运维决策，不属于设计          | 写约束范围（"超时 30-120s"）    |
| **retry/backoff 的具体实现** | 实现细节，Ralph 自行决定               | 写策略（"指数退避，最多 3 次"） |
| **具体 import 语句**         | 锁定技术选型到代码级别                 | 写依赖声明                      |
| **测试代码**                 | 测试属于实现阶段产物                   | 写验收标准，测试由 Ralph 生成   |

### 灰色地带：参考代码

如果某些逻辑确实很复杂、自然语言难以精确表达，可以附带参考代码，但**必须隔离**：

````markdown
## 参考实现（Reference Only — DO NOT COPY）

> 以下代码仅用于辅助理解上述行为契约的意图。
> 实现时应根据项目实际技术栈编写生产级代码。

​```python

# 伪代码：展示回滚的逆序补偿逻辑

for step in reversed(completed_steps):
if step.has_compensation:
execute(step.compensation_action)
​```
````

**规则：**

- 放在 section 末尾，用明确标题隔离
- 标注 `Reference Only — DO NOT COPY`
- 尽量短（<20 行），只展示核心逻辑
- 不用具体 library 的 API
- 如果代码很长（>30 行），移到 `references/` 目录，spec 中只放链接

---

## Spec 模板

```markdown
# [组件/主题名称]

## 概述

一句话描述该组件/主题的职责。

## 架构位置

在系统中的位置、与其他组件的关系（ASCII 图 或 Mermaid 图）。

## 行为契约

### [行为 1 名称]

- **触发条件：** 什么时候触发
- **输入：** 需要什么数据
- **处理逻辑：** （自然语言描述）做什么
- **输出：** 返回什么
- **副作用：** 对外部状态有什么影响

### [行为 2 名称]

...

## 数据定义

### [数据结构名称]

| 字段    | 类型     | 必填 | 约束                        | 说明     |
| ------- | -------- | ---- | --------------------------- | -------- |
| field_a | string   | 是   | UUID v4                     | 唯一标识 |
| field_b | enum     | 是   | value_1 / value_2 / value_3 | 当前状态 |
| field_c | datetime | 否   | UTC, ISO 8601               | 完成时间 |

### [枚举/错误码]

| 值  | 含义 |
| --- | ---- |
| ... | ...  |

## 模块间接口

### 本组件 → [目标组件]

- **传递数据：** 什么数据、什么格式
- **调用时机：** 什么条件下调用
- **错误处理：** 调用失败时本组件如何响应

### [来源组件] → 本组件

...

## 失败模式与策略

| 失败场景 | 期望行为 | 恢复策略 |
| -------- | -------- | -------- |
| ...      | ...      | ...      |

## 约束条件

- 性能：...
- 安全：...
- 兼容性：...

## 验收标准

- [ ] 标准 1（可测试的行为描述）
- [ ] 标准 2
- [ ] 标准 3
- [ ] ...（至少 3-5 条）

## 决策记录

| 决策 | 选择 | 理由 | 备选方案 |
| ---- | ---- | ---- | -------- |
| ...  | ...  | ...  | ...      |

## 依赖声明

| 能力        | 要求                   | 说明             |
| ----------- | ---------------------- | ---------------- |
| HTTP client | async + retry + 连接池 | 用于调用外部 API |
| 缓存存储    | KV 存储，支持 TTL      | 用于 session     |

## 参考实现（Reference Only — DO NOT COPY）

> 仅用于辅助理解意图。实现时根据项目技术栈编写生产级代码。

（如有必要，简短代码片段，<20 行）

## 未决问题

- [ ] 问题 1
- [ ] 问题 2
```

---

## Guardrails（护栏规则）

在撰写 spec 的每个 section 时，对照以下规则：

### G1 — 无完整实现代码

> **检查：** spec 中是否存在完整的 class 定义、完整的 function 定义（含方法体）？
>
> **违规示例：**
>
> ```python
> class TransactionManager:
>     def __init__(self, db: Database):
>         self.db = db
>     def begin(self, session_id, workflow_name):
>         tx = TransactionRecord(...)
>         self.db.save(tx)
>         return tx
> ```
>
> **修正：** 用行为契约描述：
> "begin(session_id, workflow_name) → 创建事务记录并持久化，返回 transaction_id"

### G2 — 无 Library 具体 API

> **检查：** spec 中是否引用了具体 library 的类名、方法名、构造参数？
>
> **违规示例：**
>
> ```python
> from langchain_google_genai import ChatGoogleGenerativeAI
> self.model = ChatGoogleGenerativeAI(model="gemini-1.5-pro", temperature=0.2)
> ```
>
> **修正：** 依赖声明：
> "需要 LLM adapter（支持 tool-calling、streaming、retry）；推荐 Gemini 系列模型"

### G3 — 无具体配置值

> **检查：** spec 中是否写死了超时时间、池大小、retry 次数等具体数值？
>
> **违规示例：**
>
> ```yaml
> timeout_seconds: 30
> max_retries: 3
> connection_pool_size: 10
> ```
>
> **修正：** 写约束范围：
> "API 超时：30-120s 可配置；retry：指数退避，上限可配置"

### G4 — Data Shape 是抽象的

> **检查：** spec 中的数据定义是语言无关的表格，还是具体语言的 dataclass/interface？
>
> **违规示例：**
>
> ```python
> @dataclass
> class TransactionRecord:
>     transaction_id: str
>     session_id: str
>     status: Literal["running", "completed", "rolled_back"]
> ```
>
> **修正：** 用表格：
> | 字段 | 类型 | 必填 | 约束 |
> |------|------|------|------|
> | transaction_id | string | 是 | UUID v4 |
> | status | enum | 是 | running / completed / rolled_back |

### G5 — 验收标准充分

> **检查：** 每个 spec 是否有至少 3-5 条可测试的验收标准？
>
> **违规示例：** 只写了"系统应该正确处理错误"
>
> **修正：**
>
> - 可重试错误（timeout/5xx）自动重试，最终失败则回滚
> - 不可重试错误（4xx）立即报错，不重试
> - 回滚后所有可逆步骤已补偿
> - 不可逆步骤的执行结果明确报告给用户

### G6 — 失败路径完整

> **检查：** 是否只描述了 happy path？
>
> **修正：** 每个行为契约至少覆盖：成功路径、预期失败、意外失败

### G7 — 参考代码已隔离

> **检查：** 如果存在代码片段，是否在 `Reference Only — DO NOT COPY` section 下、<20 行、不含具体 library API？

### G8 — 模块间接口已声明

> **检查：** 当组件与其他组件交互时，是否声明了传递的数据和调用时机？
>
> **目的：** 避免模块间数据结构不一致（integration test 失败的根因）

---

## 检查清单

Spec 完成后，逐项检查。全部通过才算 ready。

### 结构完整性

- [ ] 有概述（一句话职责）
- [ ] 有架构位置（图或文字说明与其他组件的关系）
- [ ] 有行为契约（每个公开行为的 输入/输出/副作用）
- [ ] 有数据定义（语言无关的表格，含字段/类型/必填/约束）
- [ ] 有模块间接口声明（与谁交互、传什么数据）
- [ ] 有失败模式与策略
- [ ] 有约束条件（性能/安全/兼容性）
- [ ] 有验收标准（至少 3-5 条可测试的）
- [ ] 有决策记录（关键选择的理由）
- [ ] 有依赖声明（需要的能力，不是具体 library）

### 去实现化检查

- [ ] 无完整 class/function 定义（含方法体的）
- [ ] 无具体 library 的 import / API 调用
- [ ] 无具体配置值（只有约束范围）
- [ ] 数据定义用表格，不用语言特定的 dataclass/interface
- [ ] 如有参考代码：已隔离、已标注 DO NOT COPY、<20 行、无具体 library

### 消费者友好性

- [ ] 新读者能在 30 秒内理解该组件做什么（概述 + 架构图）
- [ ] 验收标准可以直接转化为测试用例
- [ ] 数据定义足以在 planning 阶段生成共享类型
- [ ] 模块间接口定义足以写 contract test
- [ ] 失败策略足以实现错误处理（不需要猜测）

---

## 反模式对照表

| 反模式                         | 问题                                  | 修正方向                                                    |
| ------------------------------ | ------------------------------------- | ----------------------------------------------------------- |
| Spec 里 500+ 行代码            | Agent 照搬，绕过自主决策              | 行为契约 + 验收标准                                         |
| `from library import X`        | Library 更新 → spec 过时 → 语法错误   | 依赖声明（能力 + 版本范围）                                 |
| 多个 spec 各自定义相同数据结构 | 模块间类型漂移 → integration 失败     | 在 spec 中声明抽象 schema，planning 时统一到 src/lib/types/ |
| 只描述 happy path              | 实现时缺失错误处理 → placeholder/TODO | 失败模式表 + 每个行为的失败路径                             |
| 验收标准模糊（"正确处理"）     | 无法转化为测试 → 无有效反压           | 具体、可观察、可验证的标准                                  |
| Spec 即文档，无人维护          | 实现偏离 spec → spec 成为噪音         | Review loop 持续校验，spec 是活文档                         |
| 具体配置值写死                 | 属于运维决策，不属于设计              | 写约束范围，配置在部署层决定                                |
