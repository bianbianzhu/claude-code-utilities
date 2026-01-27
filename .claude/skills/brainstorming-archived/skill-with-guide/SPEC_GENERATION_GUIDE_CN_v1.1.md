# 规格说明生成指南

本文件定义了 brainstorming skill 在 “Presenting the design” 阶段产出的 spec 标准。
目标：产出可被 Ralph Loop（或任何自主 AI 代理循环）直接消费的规格说明，避免拷贝粘贴、类型漂移、API 过时、以及级联实现错误。

版本：1.1

---

## 核心原则

**规格说明是行为契约，而不是实现蓝图。**

一份 spec 应回答三件事：

1. **做什么**（职责、行为、数据流）
2. **做到什么程度**（验收标准、约束）
3. **失败时如何处理**（错误策略、回滚政策）

spec **不**回答：

- 具体类、方法、或哪一行代码来实现
- 具体调用哪个库的 API
- 具体重试次数、退避系数、连接池大小

---

## 系统级必备内容（适用于整个 spec 集合）

以下内容必须在 spec 集合中出现（通常放在 `specs/README.md` 或系统级 spec 文档）：

1. **范围 / 非目标 / 延后项**
   - 明确 MVP 范围与延后项，避免 scope creep。
2. **系统级成功标准**
   - 3–6 条可量化指标（可靠性、延迟、成本、准确率等）。
3. **术语表 / 权威定义**
   - 共享术语、状态值、字段命名的统一来源。
4. **数据隐私 / PII / 保留策略**
   - 什么是敏感数据、如何处理、保留多久。
5. **Spec 索引与权威性**
   - `specs/README.md` 列出所有文档，并标注每个领域的权威来源。

---

## 合约（Contracts）作为一等公民

**合约必须集中化。**二选一：

- `specs/contracts/`（多文件时优先）
- `specs/interfaces.md`（小项目单文件）

规则：

- 抽象合约写在这里（字段、类型、枚举、约束）。
- 其他 spec 只引用，不重复定义。
- Planning 层在 `src/lib/types/*` 生成实现级合约。

---

## 双层合约架构

```
Spec 层（brainstorming 输出）          Planning 层（Ralph 规划输出）
───────────────────────────           ───────────────────────────
抽象接口清单                           src/lib/types/ 中可导入类型
字段名 + 类型 + 必选/可选               语言级 dataclass / interface
枚举 + 错误码 + 约束                   完整类型定义 + 校验
行为契约（输入 → 输出 → 副作用）         ─
验收标准                               ─
```

**Spec 层定义 “what”，Planning 层翻译成 code。**

Spec 层的抽象合约示例：

```markdown
## Transaction Record

| Field          | Type             | Required | Constraints                                            |
| -------------- | ---------------- | -------- | ------------------------------------------------------ |
| transaction_id | string           | yes      | UUID v4                                                |
| session_id     | string           | yes      | references session                                     |
| status         | enum             | yes      | running / completed / rolled_back / cancelled / failed |
| steps          | list[StepRecord] | yes      | execution order                                        |
| started_at     | datetime         | yes      | UTC                                                    |
| completed_at   | datetime         | no       | set on success or failure                              |
```

这不是代码，而是 schema 约束。Planning 阶段由 Ralph 生成对应语言的实现类型。

---

## 应写内容 / 不应写内容

### 必须包含

| 内容                  | 说明                                  | 示例                                                                   |
| --------------------- | ------------------------------------- | ---------------------------------------------------------------------- |
| **组件职责**          | 一句话描述                            | “Transaction Manager 跟踪工作流执行状态，失败时回滚到干净状态”         |
| **行为契约**          | 输入 → 输出 → 副作用                  | “begin(session_id, workflow_name) → 创建事务记录，返回 transaction_id” |
| **抽象数据结构**      | 字段、类型、必选/可选、枚举、约束     | 见上表                                                                 |
| **验收标准**          | 可观察、可验证、可测试（至少 3–5 条） | “回滚后所有可逆步骤被补偿；不可逆步骤被报告但不补偿”                   |
| **失败模式与策略**    | 常见失败场景 + 预期行为               | “session 过期后，孤儿事务 35 分钟内清理”                               |
| **跨模块数据流**      | A → B 传什么数据                      | “Executor 返回 ExecutionResult 给 ConversationManager”                 |
| **约束**              | 性能/安全/顺序/兼容性                 | “所有时间统一存 UTC；API 超时上限 60s”                                 |
| **决策理由**          | 为什么这样选                          | “JWT pass-through 而非自验证：SaaS 已有完整 JWT 校验”                  |
| **依赖声明（抽象）**  | 能力 + 版本范围                       | “需要 HTTP 客户端（异步 + 重试 + 连接池）”                             |
| **架构图**            | ASCII/Mermaid                         | 高价值，建议保留                                                       |
| **状态模型 / 不变量** | 合法状态、迁移、不变量                | “completed 不能回退到 running”                                         |
| **隐私/PII 处理**     | 什么敏感、如何处理                    | “PII 存储前必须脱敏”                                                   |

### 禁止包含

| 内容                  | 原因              | 替代         |
| --------------------- | ----------------- | ------------ |
| **完整类/方法实现**   | agent 会直接复制  | 行为描述     |
| **库级 API 调用**     | 版本变化导致过时  | 能力声明     |
| **含逻辑的方法体**    | 模糊 spec vs impl | 自然语言描述 |
| **具体配置值**        | 运维决策非设计    | 约束范围     |
| **具体重试/退避实现** | 实现细节          | 策略描述     |
| **import 语句**       | 锁死技术选型      | 依赖声明     |
| **测试代码**          | 实现阶段产物      | 验收标准     |

### 灰区：参考代码

当逻辑复杂且难以自然语言表达时，可使用参考代码，但必须隔离：

````markdown
## Reference Implementation (DO NOT COPY)

> 代码仅用于理解行为契约。
> 请使用项目真实技术栈实现生产级代码。

​```python

# Pseudocode: 逆序补偿逻辑

for step in reversed(completed_steps):
if step.has_compensation:
execute(step.compensation_action)
​```
````

规则：

- 放在章节末尾，且明确标注
- 标题注明 “Reference Only — DO NOT COPY”
- 短小（<20 行），只展示核心逻辑
- 不得包含库级 API
- 超过 30 行则移到 `references/` 并在 spec 中链接

---

## Spec 模板

```markdown
# [组件/主题名称]

## Overview

一句话描述该组件/主题职责。

## Scope

- **In Scope (MVP)**:
- **Explicitly Deferred**:
- **Non‑Goals**:

## Architecture Position

组件在系统中的位置、与其他组件关系（ASCII/Mermaid）。

## Behavioral Contracts

### [行为 1 名称]

- **Trigger:** 触发条件
- **Input:** 所需数据
- **Processing:** 自然语言描述
- **Output:** 输出
- **Side effects:** 外部副作用

### [行为 2 名称]

...

## Data Definitions

### [数据结构名]

| Field   | Type     | Required | Constraints                 | Description       |
| ------- | -------- | -------- | --------------------------- | ----------------- |
| field_a | string   | yes      | UUID v4                     | unique identifier |
| field_b | enum     | yes      | value_1 / value_2 / value_3 | current status    |
| field_c | datetime | no       | UTC, ISO 8601               | completion time   |

### [枚举/错误码]

| Value | Meaning |
| ----- | ------- |
| ...   | ...     |

## Cross-Module Interfaces

### 本组件 → [目标组件]

- **Data passed:** 传递什么数据、格式
- **When called:** 何时调用
- **Error handling:** 调用失败时如何处理

### [来源组件] → 本组件

...

## Failure Modes & Strategies

| Failure Scenario | Expected Behavior | Recovery Strategy |
| ---------------- | ----------------- | ----------------- |
| ...              | ...               | ...               |

## State Model (if applicable)

| State | Allowed Transitions | Invariants |
| ----- | ------------------- | ---------- |
| ...   | ...                 | ...        |

## Constraints

- Performance: ...
- Security: ...
- Compatibility: ...
- Privacy/PII: ...
- Retention: ...

## Acceptance Criteria

- [ ] Criterion 1（可测试）
- [ ] Criterion 2
- [ ] Criterion 3
- [ ] ...（至少 3–5 条）

## Decision Records

| Decision | Choice | Rationale | Alternatives Considered |
| -------- | ------ | --------- | ----------------------- |
| ...      | ...    | ...       | ...                     |

## Dependency Declarations

| Capability  | Requirements                       | Notes                  |
| ----------- | ---------------------------------- | ---------------------- |
| HTTP client | async + retry + connection pooling | for external API calls |
| Cache store | KV store with TTL                  | for sessions           |

## Reference Implementation (DO NOT COPY)

> 仅用于理解，禁止复制。

(如需，短代码片段 <20 行)

## Open Questions

- [ ] Question 1
- [ ] Question 2
```

---

## 护栏规则

### G1 — 禁止完整实现代码

> **检查：** 是否包含完整类/函数定义及方法体？
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
> **修正：** 行为描述：
> “begin(session_id, workflow_name) → 创建事务记录并返回 transaction_id”

### G2 — 禁止库级 API

> **检查：** 是否出现具体库类名、方法名、构造参数？
>
> **违规示例：**
>
> ```python
> from langchain_google_genai import ChatGoogleGenerativeAI
> self.model = ChatGoogleGenerativeAI(model="gemini-1.5-pro", temperature=0.2)
> ```
>
> **修正：** 依赖声明：
> “需要 LLM 适配器（支持 tool-calling、streaming、retry）”

### G3 — 禁止具体配置值

> **检查：** 是否硬编码 timeout、pool size、retries？
>
> **违规示例：**
>
> ```yaml
> timeout_seconds: 30
> max_retries: 3
> connection_pool_size: 10
> ```
>
> **修正：** 约束范围：
> “超时 30–120s 可配置；重试为指数退避，最大可配置”

### G4 — 数据结构必须抽象

> **检查：** 是否使用语言特定 dataclass/interface？
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
> **修正：** 使用表格定义字段/类型/约束

### G5 — 验收标准必须充分

> **检查：** 是否至少 3–5 条可测试标准？
>
> **违规示例：** “系统应正确处理错误”
>
> **修正示例：**
>
> - 可重试错误（timeout/5xx）自动重试，最终失败触发回滚
> - 不可重试错误（4xx）立即失败，不重试
> - 回滚后所有可逆步骤已补偿
> - 不可逆步骤被明确报告

### G6 — 失败路径完整

> **检查：** 是否只有 happy path？
>
> **修正：** 每个行为至少覆盖成功、预期失败、未知失败

### G7 — 参考代码隔离

> **检查：** 代码是否在 “Reference Only — DO NOT COPY” 下，<20 行，无库 API？

### G8 — 跨模块接口声明

> **检查：** 是否清楚写出数据流动与调用时机？

### G9 — 合约集中化

> **检查：** 数据结构是否集中在 `specs/contracts/` 或 `specs/interfaces.md`？

### G10 — 状态迁移明确

> **检查：** 有状态组件是否定义合法迁移和不变量？

### G11 — 隐私/PII/保留策略明确

> **检查：** 涉及用户数据时是否定义敏感性/脱敏/保留规则？

---

## Checklist

### 结构完整性

- [ ] 有 overview（职责一句话）
- [ ] 有 scope（范围/延后/非目标）
- [ ] 有架构位置（图或文字）
- [ ] 有行为契约（输入/输出/副作用）
- [ ] 有数据定义（表格形式）
- [ ] 合约集中化（contracts 或 interfaces）
- [ ] 有跨模块接口声明
- [ ] 有失败模式与策略
- [ ] 有状态模型（如为有状态组件）
- [ ] 有约束（性能/安全/兼容/隐私）
- [ ] 有隐私/PII/保留说明
- [ ] 有验收标准（≥3–5 条）
- [ ] 有决策记录
- [ ] 有依赖声明（能力级）

### 去实现化检查

- [ ] 没有完整类/函数实现
- [ ] 没有库级 API 或 import
- [ ] 没有具体配置值
- [ ] 数据结构为表格而非语言类型
- [ ] 参考代码隔离、短小、无库 API

### 使用者友好性

- [ ] 30 秒内可理解组件职责
- [ ] 验收标准可直接转成测试
- [ ] 数据定义足够生成共享类型
- [ ] 跨模块接口足够生成 contract tests
- [ ] 失败策略清晰，避免猜测
- [ ] 状态迁移无歧义

---

## 反例清单

| 反模式                     | 问题               | 修正                 |
| -------------------------- | ------------------ | -------------------- |
| spec 里 500+ 行代码        | agent 直接复制     | 行为契约 + 验收标准  |
| `from library import X`    | 库更新 → spec 过时 | 能力级依赖声明       |
| 多个 spec 重复定义同一结构 | 类型漂移           | 合约集中化           |
| 只写 happy path            | 错误处理缺失       | 失败模式表           |
| “处理正确”这类模糊验收     | 无法落测试         | 具体可观察标准       |
| spec 写一次就不维护        | 实现漂移           | review loop 持续校验 |
| 硬编码配置值               | 运维决策非设计     | 约束范围             |
