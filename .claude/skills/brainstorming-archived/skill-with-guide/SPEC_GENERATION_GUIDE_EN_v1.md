# Spec Generation Guide

This document defines the standard for spec files produced by the brainstorming skill during the "Presenting the design" phase.
Goal: produce specs consumable by Ralph Loop (or any autonomous AI agent loop), avoiding copy-paste, type drift, stale APIs, and cascading implementation errors.

---

## Core Principle

**Specs are behavioral contracts, not implementation blueprints.**

A spec answers three questions:

1. **What does it do** (responsibilities, behaviors, data flow)
2. **How well must it do it** (acceptance criteria, constraints)
3. **What happens when it fails** (error strategies, rollback policies)

A spec does **not** answer:

- Which class, method, or line of code implements it
- Which library's API to call
- Specific retry counts, backoff coefficients, pool sizes

---

## Dual-Layer Contracts Architecture

```
Spec layer (brainstorming output)            Planning layer (Ralph planning mode output)
──────────────────────────────────           ─────────────────────────────────────────
Abstract interface inventory                  Importable types in src/lib/types/
Field names + types + required/optional       Language-specific dataclass / interface
Enums + error codes + constraints             Full type definitions + validation
Behavioral contracts (in → out → side effects)  ─
Acceptance criteria                           ─
```

**Spec layer defines "what" — Planning layer translates to code.**

Abstract contract example in spec layer:

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

This is **not** code. It is schema constraints. Ralph generates the corresponding language-specific type definitions during planning.

---

## What to Write / What Not to Write

### Must Include

| Content                                | Description                                          | Example                                                                                                     |
| -------------------------------------- | ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Component responsibilities**         | One-sentence description                             | "Transaction Manager tracks workflow execution state and rolls back to clean state on failure"              |
| **Behavioral contracts**               | Input → output → side effects                        | "begin(session_id, workflow_name) → creates transaction record, returns transaction_id"                     |
| **Abstract data shapes**               | Fields, types, required/optional, enums, constraints | See table example above                                                                                     |
| **Acceptance criteria**                | Observable, verifiable, testable outcomes (min 3-5)  | "After rollback, all reversible steps are compensated; irreversible steps are reported but not compensated" |
| **Failure modes & strategies**         | Common failure scenarios + expected behavior         | "On session expiry, orphaned transactions cleaned up within 35 min"                                         |
| **Cross-module data flow**             | What data flows from A to B                          | "Executor returns ExecutionResult to ConversationManager"                                                   |
| **Constraints**                        | Performance, security, ordering, compatibility       | "All datetimes stored as UTC; API timeout max 60s"                                                          |
| **Decision rationale**                 | Why this approach over alternatives                  | "JWT pass-through chosen over self-validation because SaaS API already has full JWT validation"             |
| **Dependency declarations (abstract)** | Required capabilities + version range                | "Needs HTTP client (async + retry + connection pooling)"                                                    |
| **Architecture diagrams**              | ASCII/Mermaid showing component relationships        | Keep these — high value                                                                                     |

### Must Not Include

| Content                                   | Why Not                                                    | Alternative                                     |
| ----------------------------------------- | ---------------------------------------------------------- | ----------------------------------------------- |
| **Complete class/method implementations** | Agent copies verbatim, bypasses autonomous decision-making | Behavioral description                          |
| **Library-specific API calls**            | Library updates → stale spec → syntax errors               | Capability declarations                         |
| **Method bodies with logic code**         | Blurs spec vs implementation, pseudocode gets copy-pasted  | Natural language logic description              |
| **Concrete config values**                | Deployment/ops decisions, not design                       | Constraint ranges ("timeout 30-120s")           |
| **Retry/backoff implementations**         | Implementation detail, Ralph decides                       | Strategy ("exponential backoff, max 3 retries") |
| **Import statements**                     | Locks tech choices to code level                           | Dependency declarations                         |
| **Test code**                             | Tests are implementation-phase artifacts                   | Acceptance criteria; Ralph generates tests      |

### Gray Area: Reference Code

When logic is genuinely complex and hard to express precisely in natural language, reference code is allowed but **must be isolated**:

````markdown
## Reference Implementation (DO NOT COPY)

> The code below is only to aid understanding of the behavioral contract above.
> Implement production-quality code using the project's actual tech stack.

​```python

# Pseudocode: illustrates reverse-order compensation logic

for step in reversed(completed_steps):
if step.has_compensation:
execute(step.compensation_action)
​```
````

**Rules:**

- Place at end of section, under explicit header
- Label `Reference Only — DO NOT COPY`
- Keep short (<20 lines), show only core logic
- Do not use library-specific APIs
- If code is long (>30 lines), move to `references/` directory, link from spec

---

## Spec Template

```markdown
# [Component/Topic Name]

## Overview

One-sentence description of this component/topic's responsibility.

## Architecture Position

Position in the system, relationships with other components (ASCII or Mermaid diagram).

## Behavioral Contracts

### [Behavior 1 Name]

- **Trigger:** when does this happen
- **Input:** what data is needed
- **Processing:** (natural language) what it does
- **Output:** what it returns
- **Side effects:** impact on external state

### [Behavior 2 Name]

...

## Data Definitions

### [Data Structure Name]

| Field   | Type     | Required | Constraints                 | Description       |
| ------- | -------- | -------- | --------------------------- | ----------------- |
| field_a | string   | yes      | UUID v4                     | unique identifier |
| field_b | enum     | yes      | value_1 / value_2 / value_3 | current status    |
| field_c | datetime | no       | UTC, ISO 8601               | completion time   |

### [Enums/Error Codes]

| Value | Meaning |
| ----- | ------- |
| ...   | ...     |

## Cross-Module Interfaces

### This Component → [Target Component]

- **Data passed:** what data, what format
- **When called:** under what conditions
- **Error handling:** how this component responds if call fails

### [Source Component] → This Component

...

## Failure Modes & Strategies

| Failure Scenario | Expected Behavior | Recovery Strategy |
| ---------------- | ----------------- | ----------------- |
| ...              | ...               | ...               |

## Constraints

- Performance: ...
- Security: ...
- Compatibility: ...

## Acceptance Criteria

- [ ] Criterion 1 (testable behavioral description)
- [ ] Criterion 2
- [ ] Criterion 3
- [ ] ... (minimum 3-5)

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

> Only to aid understanding. Implement production-quality code using the project's tech stack.

(If necessary, short code snippet, <20 lines)

## Open Questions

- [ ] Question 1
- [ ] Question 2
```

---

## Guardrails

Check against these rules while writing each spec section:

### G1 — No Complete Implementation Code

> **Check:** Does the spec contain complete class definitions or function definitions with method bodies?
>
> **Violation:**
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
> **Fix:** Behavioral contract:
> "begin(session_id, workflow_name) → creates transaction record, persists it, returns transaction_id"

### G2 — No Library-Specific APIs

> **Check:** Does the spec reference specific library class names, method names, or constructor parameters?
>
> **Violation:**
>
> ```python
> from langchain_google_genai import ChatGoogleGenerativeAI
> self.model = ChatGoogleGenerativeAI(model="gemini-1.5-pro", temperature=0.2)
> ```
>
> **Fix:** Dependency declaration:
> "Needs LLM adapter (supports tool-calling, streaming, retry); Gemini family models recommended"

### G3 — No Concrete Config Values

> **Check:** Does the spec hardcode timeout durations, pool sizes, retry counts, etc.?
>
> **Violation:**
>
> ```yaml
> timeout_seconds: 30
> max_retries: 3
> connection_pool_size: 10
> ```
>
> **Fix:** Constraint range:
> "API timeout: 30-120s configurable; retry: exponential backoff, max configurable"

### G4 — Data Shapes Are Abstract

> **Check:** Are data definitions language-agnostic tables, or language-specific dataclass/interface definitions?
>
> **Violation:**
>
> ```python
> @dataclass
> class TransactionRecord:
>     transaction_id: str
>     session_id: str
>     status: Literal["running", "completed", "rolled_back"]
> ```
>
> **Fix:** Use table:
> | Field | Type | Required | Constraints |
> |-------|------|----------|-------------|
> | transaction_id | string | yes | UUID v4 |
> | status | enum | yes | running / completed / rolled_back |

### G5 — Sufficient Acceptance Criteria

> **Check:** Does each spec have at least 3-5 testable acceptance criteria?
>
> **Violation:** Only wrote "system should handle errors correctly"
>
> **Fix:**
>
> - Retryable errors (timeout/5xx) auto-retry, final failure triggers rollback
> - Non-retryable errors (4xx) fail immediately, no retry
> - After rollback, all reversible steps are compensated
> - Irreversible step execution results explicitly reported to user

### G6 — Complete Failure Paths

> **Check:** Does the spec only describe the happy path?
>
> **Fix:** Each behavioral contract should cover at minimum: success path, expected failure, unexpected failure

### G7 — Reference Code Is Isolated

> **Check:** If code snippets exist, are they under a `Reference Only — DO NOT COPY` section, <20 lines, no library-specific APIs?

### G8 — Cross-Module Interfaces Declared

> **Check:** When a component interacts with others, does the spec declare what data is passed and when?
>
> **Purpose:** Prevent cross-module data structure mismatch (root cause of integration test failures)

---

## Checklist

Run through after spec is complete. All items must pass before spec is ready.

### Structural Completeness

- [ ] Has overview (one-sentence responsibility)
- [ ] Has architecture position (diagram or text describing relationships to other components)
- [ ] Has behavioral contracts (input/output/side effects for each public behavior)
- [ ] Has data definitions (language-agnostic tables with field/type/required/constraints)
- [ ] Has cross-module interface declarations (who it interacts with, what data)
- [ ] Has failure modes & strategies
- [ ] Has constraints (performance/security/compatibility)
- [ ] Has acceptance criteria (at least 3-5 testable)
- [ ] Has decision records (rationale for key choices)
- [ ] Has dependency declarations (capabilities needed, not specific libraries)

### De-Implementation Check

- [ ] No complete class/function definitions (with method bodies)
- [ ] No library-specific import / API calls
- [ ] No concrete config values (only constraint ranges)
- [ ] Data definitions use tables, not language-specific dataclass/interface
- [ ] If reference code exists: isolated, labeled DO NOT COPY, <20 lines, no specific libraries

### Consumer Friendliness

- [ ] New reader can understand what the component does within 30 seconds (overview + diagram)
- [ ] Acceptance criteria can directly translate to test cases
- [ ] Data definitions are sufficient to generate shared types during planning phase
- [ ] Cross-module interface definitions are sufficient to write contract tests
- [ ] Failure strategies are sufficient to implement error handling (no guessing needed)

---

## Anti-Pattern Reference

| Anti-Pattern                                    | Problem                                                       | Fix                                                                      |
| ----------------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------ |
| 500+ lines of code in spec                      | Agent copies verbatim, bypasses autonomous decisions          | Behavioral contracts + acceptance criteria                               |
| `from library import X`                         | Library update → stale spec → syntax errors                   | Dependency declarations (capability + version range)                     |
| Multiple specs each define same data structure  | Cross-module type drift → integration failures                | Declare abstract schema in spec, unify to src/lib/types/ during planning |
| Only happy path described                       | Missing error handling → placeholders/TODOs in implementation | Failure mode table + failure path per behavior                           |
| Vague acceptance criteria ("handles correctly") | Cannot translate to tests → no effective backpressure         | Specific, observable, verifiable criteria                                |
| Spec as write-once document                     | Implementation drifts from spec → spec becomes noise          | Review loop continuously validates; spec is living document              |
| Hardcoded config values                         | Ops decision, not design                                      | Constraint ranges; config decided at deployment                          |
