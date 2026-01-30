# ROLLER iQ Booking Updates — Design Spec

## Overview

Enable venue operators to update bookings via natural language on mobile. The system transforms user requests into executable action chains, confirms with the user, and executes against ROLLER APIs with rollback on failure.

## Architecture Position

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           ROLLER iQ (existing)                          │
│                                                                         │
│   ┌─────────────────┐                                                   │
│   │ Intent Classifier│ ─────► routes "booking update" intents to:       │
│   └─────────────────┘                                                   │
└─────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    Booking Update Service (this SLC)                    │
│                                                                         │
│  ┌──────────────────┐    ┌──────────────┐    ┌──────────────────────┐  │
│  │ Action Registry  │───►│  LLM Planner │───►│   Plan Presenter     │  │
│  │ (from OpenAPI)   │    │              │    │   (confirmation UI)  │  │
│  └──────────────────┘    └──────────────┘    └──────────────────────┘  │
│           │                     │                       │               │
│           │                     ▼                       ▼               │
│           │              ┌─────────────┐         ┌────────────┐        │
│           │              │  Chat State │         │   Queue    │        │
│           │              │  (context)  │         │  Manager   │        │
│           │              └─────────────┘         └────────────┘        │
│           │                                            │               │
│           ▼                                            ▼               │
│  ┌──────────────────┐                        ┌─────────────────┐       │
│  │ Action Transformer│                        │ Action Executor │       │
│  │ (OpenAPI→Tools)  │                        │ (ReAct + rollback)│     │
│  └──────────────────┘                        └─────────────────┘       │
│                                                       │                │
└───────────────────────────────────────────────────────│────────────────┘
                                                        ▼
                                               ┌────────────────┐
                                               │  ROLLER APIs   │
                                               └────────────────┘
```

**Data Flow:**

1. User sends natural language request via chat
2. LLM Planner queries Action Registry for available actions
3. Planner composes action chain (or asks clarifying questions)
4. Plan Presenter formats plan for user confirmation
5. User confirms → plan enters Queue
6. Action Executor processes queue using ReAct loop with tool calling
7. On failure: rollback reversible steps, report status with recovery guidance

---

## Component: Action Transformer

**Responsibility:** Transforms OpenAPI specifications into LLM-friendly atomic actions with enhanced metadata.

### Behavioral Contracts

**Transform Action**

- **Trigger:** On service startup or registry refresh
- **Input:** OpenAPI spec file + action metadata configuration
- **Processing:** Parse endpoints, apply metadata overlays, filter parameters, generate tool definitions
- **Output:** Atomic Action definitions registered in Action Registry
- **Side effects:** Updates Action Registry; logs transformation results to Langfuse

### Transformation Rules

1. **Endpoint Selection:** Only endpoints marked as `iq_enabled: true` in metadata are transformed
2. **Parameter Filtering:**
   - Required parameters always included
   - Optional parameters included only if explicitly allowlisted in metadata
   - Sensitive parameters (passwords, tokens) never exposed
3. **Description Enhancement:** OpenAPI descriptions augmented with LLM-friendly context, examples, and usage hints
4. **Safety Classification:** Each action tagged with safety tier (normal / high_risk / blocked)
5. **Reversibility Declaration:** Actions declare if reversible and reference their compensation action

### Metadata Overlay

Each action requires a metadata overlay that enhances the raw OpenAPI definition. See [ActionMetadataOverlay](contracts/data-definitions.md#action-metadata-overlay) for the formal contract.

Key fields:
- Operation identifier (maps to OpenAPI operationId)
- LLM-friendly description (natural language, includes when to use)
- Parameter allowlist (which optional params to expose)
- Safety tier (normal / high_risk / blocked)
- Reversible flag + compensation action reference
- Example invocations (for LLM few-shot context)

---

## Component: LLM Planner

**Responsibility:** Interprets user intent, resolves booking context, and composes a chain of atomic actions to fulfill the request.

### Behavioral Contracts

**Plan Generation**

- **Trigger:** User submits natural language request
- **Input:** User message, chat history, available actions from registry, user auth context
- **Processing:**
  1. Extract intent and entities from user message
  2. Resolve booking reference (from chat context or via fuzzy search)
  3. Identify required actions and their sequence
  4. Map extracted entities to action parameters
  5. Create placeholders for cross-action data dependencies
- **Output:** Execution plan (ordered list of actions with parameters/placeholders)
- **Side effects:** All LLM calls traced to Langfuse

**Clarification Request**

- **Trigger:** Critical information is ambiguous or missing
- **Input:** Partial understanding of user intent
- **Processing:** Identify what's missing, formulate clarifying question
- **Output:** Clarification prompt to user (single question)
- **Side effects:** Conversation state updated

### Planning Rules

1. **Context first:** Check chat history for booking references before searching
2. **Never assume critical data:** Which booking, guest counts, contact details — must be explicit or clarified
3. **Smart defaults allowed for:** Dates ("next Saturday"), times (venue's typical slots)
4. **Single question per turn:** If multiple clarifications needed, ask most important first
5. **Fail gracefully:** If intent remains unclear after bounded clarification attempts (configurable, small number), suggest user rephrase or offer quick action shortcuts

### Booking Resolution Flow

When user references a booking without explicit ID:

1. **Check context:** Look for booking ID in recent chat history
2. **Fuzzy search:** If not in context, search using user-provided terms (see [BookingSearchQuery](contracts/data-definitions.md#booking-search-query))
3. **Single match:** Proceed with that booking
4. **Multiple matches:** Present candidates (see [BookingSummary](contracts/data-definitions.md#booking-summary)) for user selection
5. **No matches:** Report "no matching booking found"; suggest user provide more details or check spelling

### Data Placeholders

Plans use typed placeholders for runtime resolution:

- `{{step_N.field}}` — Reference output from step N
- Example: `sendConfirmation(booking_id={{step_1.booking_id}})`

---

## Component: Action Executor

**Responsibility:** Executes confirmed plans using LLM tool-calling in a ReAct loop, allowing self-correction and dynamic parameter resolution.

### Behavioral Contracts

**Execute Plan**

- **Trigger:** User confirms plan; plan moves from queue to executing
- **Input:** Confirmed plan (high-level intent), available tools (atomic actions), user auth token, chat context
- **Processing:**
  1. LLM receives confirmed plan as goal
  2. **ReAct Loop:**
     - **Reason:** LLM determines next action and parameters
     - **Act:** LLM calls tool (atomic action wrapped as LangChain tool)
     - **Observe:** LLM receives tool response
     - **Iterate:** Based on response, LLM decides next step
  3. LLM can self-correct within the confirmed action sequence: fix parameter formatting, resolve placeholders, re-attempt steps that failed due to correctable issues (e.g., 400 from bad format)
  4. LLM can prompt user if missing critical information not in context
     - Execution pauses until user responds (plan remains in `executing` status)
     - Only missing data within the confirmed intent may be requested (no new actions added)
     - If requested data materially changes the plan scope, execution fails and user is asked to start a new request
  5. Each completed action recorded for potential rollback
- **Output:** Execution result (success summary or failure details)
- **Side effects:** ROLLER data modified; all tool calls traced to Langfuse

**Key Distinction:**

- **Plan** = high-level intent shown to user for confirmation ("Reschedule John's party to Saturday 3pm")
- **Execution** = LLM dynamically resolves parameters, calls tools, observes results, self-corrects minor issues
- **Not in scope (SLC):** Strategic re-planning if the overall approach fails

**Rollback**

- **Trigger:** Execution fails after some actions completed
- **Input:** Completed actions log, failure context
- **Processing:** LLM (or deterministic logic) invokes compensation actions in reverse order for reversible steps
- **Output:** Rollback report (what was reversed, what couldn't be, manual recovery steps if needed)

### Error Classification

When tool calls return errors, the executor responds based on error type:

| Error Type | Behavior |
|------------|----------|
| 400 Bad Request | LLM attempts self-correction; if persistent, fail and report parameter issue |
| 401/403 Unauthorized | Fail immediately, suggest re-authentication |
| 404 Not Found | Fail, resource no longer exists (may have been modified/deleted) |
| 409 Conflict | Fail, report conflict, suggest alternatives if available |
| 429 Rate Limited | Fail, report "retry in X seconds" (no auto-retry from this service) |
| 500+ Server Error | Fail, report "service unavailable, try later" |
| Timeout | Fail, report connectivity issue |

For non-recoverable errors, rollback is triggered for any completed reversible actions.

---

## Data Definitions

See [contracts/data-definitions.md](contracts/data-definitions.md) for centralized data shapes:

- Atomic Action
- Action Parameter
- Execution Plan
- Planned Action
- Action Result
- Rollback Report
- Enums (Plan Status, Safety Tier, Error Type)

---

## Service Interface (IQ Integration)

This service operates as a sub-agent within ROLLER iQ. The integration boundary is with the existing intent classifier, not directly with mobile clients.

### Inbound: Handle Booking Update Request

- **Trigger:** IQ intent classifier routes a "booking update" intent to this service
- **Input:** User message (string), session_id (string), user_id (string, provided by IQ from authenticated session), user auth token (opaque, passed through)
- **Processing:** Planner generates action chain or clarification
- **Output:** One of:
  - **Plan response:** ExecutionPlan (see [data-definitions.md](contracts/data-definitions.md)) with status `pending_confirmation`
  - **Clarification response:** Question text (string) to relay to user
  - **Error response:** ServiceError (see [data-definitions.md](contracts/data-definitions.md#service-error))
- **Note on error types:** Service-level errors (see [ServiceErrorType](contracts/data-definitions.md#service-error-type)) are for the IQ integration boundary. Action-level errors (see [ErrorType](contracts/data-definitions.md#error-type-action-level)) are used within execution results.
- **Caller responsibility:** IQ orchestrates the conversation flow; this service provides plan/clarification responses

### Inbound: Confirm Plan

- **Trigger:** User confirms a pending plan
- **Input:** plan_id (string, UUID), user_id (string), user auth token
- **Precondition:** `user_id` must match plan creator
- **Processing:** Validates user ownership, attempts to enqueue plan for execution
  - On enqueue success: persists status as `confirmed` (sets `confirmed_at`), returns ExecutionPlan
  - On enqueue failure: status remains `pending_confirmation`, returns ServiceError with `service_unavailable`
- **Output:** ExecutionPlan with updated status (on success) or ServiceError (on enqueue failure)
- **Idempotency:** Confirming an already-confirmed plan returns current status (no error); user may re-confirm a `pending_confirmation` plan after enqueue failure
- **Error cases:** Plan not found (404), plan already executing/completed (409), user mismatch (403), enqueue failure (503 / service_unavailable)

### Inbound: Get Plan Status

- **Trigger:** Client polls for execution status
- **Input:** plan_id (string, UUID), user_id (string), user auth token
- **Precondition:** `user_id` must match plan creator
- **Output:** ExecutionPlan including:
  - Current status
  - If `executing` with `blocking_prompt` set: the question awaiting user response
  - If terminal status: success summary or failure details with rollback_report
- **Error cases:** Plan not found (404), user mismatch (403), invalid/missing auth (401)

### Inbound: Submit Blocking Prompt Answer

- **Trigger:** User provides answer to a `blocking_prompt` question during execution
- **Input:** plan_id (string, UUID), user_id (string), user_message (string), user auth token
- **Precondition:** Plan must be in `executing` status with `blocking_prompt` set; `user_id` must match plan creator
- **Processing:** Validates preconditions, clears `blocking_prompt`, provides answer to executor to resume
- **Output:** ExecutionPlan with updated state (blocking_prompt cleared, execution resuming)
- **Error cases:** Plan not found (404), plan not in valid state for answer (409), user mismatch (403)
- **Routing note:** IQ determines whether a user message is a new request vs answer to active `blocking_prompt` by checking if session has an active plan in `executing` status with `blocking_prompt` set
- **Invariant:** At most one plan per `session_id` may be in `executing` status with `blocking_prompt` set at any time; if this invariant is violated (implementation error), the service returns a conflict error requiring user disambiguation

### Outbound: Status Updates (Deferred)

> **MVP approach:** Polling via "Get Plan Status" is the MVP integration pattern. Push-based status updates are deferred until integration requirements are validated with the IQ team.

- **Deferred capability:** Real-time push when plan status changes or `blocking_prompt` is set
- **MVP alternative:** IQ orchestrator polls "Get Plan Status" at appropriate intervals

### Not in Scope (MVP)

- **Cancel Plan:** Explicit plan cancellation is deferred; plans timeout naturally via session expiry

---

## Cross-Module Interfaces

### Action Transformer → Action Registry

- **Data passed:** List of Atomic Action definitions
- **When called:** On service startup; on manual refresh trigger
- **Error handling:** Invalid actions logged and skipped; valid actions still registered

### LLM Planner → Action Registry

- **Data passed:** Query for available actions (optionally filtered by category)
- **When called:** When generating a plan
- **Error handling:** If registry unavailable, fail with "service unavailable" message

### LLM Planner → Queue Manager

- **Data passed:** Execution Plan (status: `pending_confirmation`); status transitions to `confirmed` only after successful enqueue acknowledgement
- **When called:** After user confirms plan (enqueue attempt)
- **Error handling:** If queue insertion fails, plan status remains `pending_confirmation`, failure is reported to user, and user may re-confirm (which re-attempts enqueue)

### Queue Manager → Action Executor

- **Data passed:** Execution Plan to process
- **When called:** When plan status is confirmed and executor is available
- **Error handling:** Executor updates plan status on success/failure

### Action Executor → ROLLER APIs

- **Data passed:** API requests with user's auth token
- **When called:** During ReAct loop tool execution
- **Error handling:** Errors classified and handled per error classification table

---

## Failure Modes & Strategies

| Failure Scenario | Expected Behavior | Recovery Strategy |
|------------------|-------------------|-------------------|
| LLM fails to understand intent | After bounded clarification attempts, still unclear | Suggest user rephrase; offer quick action shortcuts as alternative |
| Booking not found | Fuzzy search returns no matches | Report "no matching booking found"; suggest search criteria adjustments |
| Multiple bookings match | Ambiguous reference (e.g., "John" has 3 bookings) | Present list of matches; ask user to select specific booking |
| Requested slot unavailable | Reschedule target time is taken | Report unavailability; suggest alternative available slots |
| Mid-chain action failure | Step 2 of 3 fails | Rollback step 1 (if reversible); report which step failed with reason |
| Rollback partially fails | Compensation action fails | Report what was rolled back, what wasn't; provide manual recovery steps |
| Irreversible action already executed | Failure after non-reversible step completed | Cannot rollback; clearly report what was done and what user may need to do manually |
| Rate limit hit (429) | ROLLER API returns rate limit | Stop execution; report "retry in X seconds"; no auto-retry |
| ROLLER API unavailable (5xx) | Server error from ROLLER | Stop execution; trigger rollback; report "service temporarily unavailable" |
| Auth token expired mid-execution | 401 during execution | Stop execution; trigger rollback; prompt user to re-authenticate |
| Network timeout | Request times out | Stop execution; trigger rollback; report connectivity issue |
| Concurrent modification detected | 409 Conflict from API | Stop execution; report booking was modified; suggest user refresh and retry |

### Rollback Principles

1. **Best effort:** Attempt rollback for all reversible completed actions
2. **Reverse order:** Compensate in reverse execution order
3. **Continue on rollback failure:** If one compensation fails, still attempt others
4. **Full transparency:** Report exactly what succeeded, what failed, what was rolled back, what couldn't be

---

## State Model

### Plan Status Transitions

```
                    ┌──────────────────┐
                    │ pending_confirmation │
                    └──────────────────┘
                              │
                    user confirms + enqueue succeeds
                              ▼
                    ┌──────────────────┐
                    │    confirmed     │
                    └──────────────────┘
                              │
                    executor picks up
                              ▼
                    ┌──────────────────┐
                    │    executing     │
                    └──────────────────┘
                     /                \
            success /                  \ failure
                   ▼                    ▼
        ┌──────────────┐      ┌──────────────┐
        │  completed   │      │    failed    │
        └──────────────┘      └──────────────┘
                                     │
                              rollback attempted
                                     ▼
                              ┌──────────────┐
                              │ rolled_back  │
                              └──────────────┘
```

### Invariants

- Status can only move forward once `confirmed` is reached (no `confirmed` → `pending_confirmation`)
- `pending_confirmation` → `confirmed` transition requires successful enqueue; on enqueue failure, status remains `pending_confirmation` and user may re-attempt confirmation
- `confirmed_at` is set when status becomes `confirmed`
- `completed_at` is set when status becomes `completed`, `failed`, or `rolled_back`
- `rollback_report` only present if rollback was attempted
- **User prompts during execution:** Execution may pause for user input while remaining in `executing` status; when paused, `blocking_prompt` is set with the question awaiting response; cleared when user responds and execution resumes
- **Post-confirmation immutability:** The confirmed plan's actions/parameters may not be structurally modified post-confirmation (only data gaps filled)

---

## Observability

**Primary tool:** Langfuse

### What Gets Traced

| Event Type | Data Captured | Purpose |
|------------|---------------|---------|
| LLM Call | Model, prompt, response, latency, tokens used | Debug, cost tracking, performance analysis |
| Tool Call | Action ID, parameters, response, latency, success/failure | Debug action execution, identify failing APIs |
| Clarification Request | What was unclear, question asked | Improve prompts, identify common ambiguities |
| Plan Generation | User intent, generated plan, action count | Analyze planning accuracy |
| Plan Confirmation | Plan ID, time to confirm, user accepted/modified | UX metrics |
| Execution Start/End | Plan ID, duration, outcome (success/fail/rollback) | Reliability metrics |
| Rollback Event | What triggered, actions compensated, failures | Understand failure patterns |

### Trace Structure

```
Trace: user_request_{id}
├── Span: intent_understanding
│   └── LLM call (with prompt/response)
├── Span: plan_generation
│   ├── LLM call
│   └── Actions selected
├── Span: user_confirmation
│   └── Time to confirm, outcome
└── Span: execution
    ├── Tool call: action_1
    ├── Tool call: action_2
    └── (Rollback span if failure)
```

### Key Metrics (derived from traces)

- **Planning accuracy:** % of plans confirmed without modification
- **Execution success rate:** % of confirmed plans that complete successfully
- **Clarification rate:** Average clarifications per request
- **Time to confirmation:** Median time from request to user confirm
- **Rollback frequency:** % of executions requiring rollback
- **Action failure rate:** Per-action success/failure rates

---

## Constraints

### Performance

- Plan generation: respond within 5-15 seconds (LLM latency dependent)
- Execution: individual API calls should complete within reasonable timeout (30-120s configurable)
- Queue processing: confirmed plans should begin execution within seconds

### Security

- Auth tokens passed through, never logged or persisted
- Blocked actions never exposed to LLM
- All mutations require user confirmation

### Privacy/PII

- Guest contact details are PII; passed through to ROLLER, not stored
- Langfuse traces may contain intent summaries; avoid logging raw PII in trace metadata

---

## Acceptance Criteria

### Core Functionality

- [ ] User can request a booking reschedule via natural language and receive a confirmation plan
- [ ] User can request a guest count change via natural language and receive a confirmation plan
- [ ] User can request a contact detail update via natural language and receive a confirmation plan
- [ ] LLM correctly extracts booking reference from chat history when available
- [ ] LLM performs fuzzy search when booking reference not in context
- [ ] LLM asks clarifying question when booking reference is ambiguous (multiple matches)
- [ ] LLM asks clarifying question when critical data is missing (never assumes guest count, specific booking)
- [ ] Smart defaults applied for non-critical data (e.g., "Saturday" → next Saturday)

### Plan & Confirmation

- [ ] Generated plan displays all actions that will be executed
- [ ] High-risk actions are visually distinguished in the plan
- [ ] User can confirm plan with single action
- [ ] Confirmed plan enters execution queue

### Execution

- [ ] Executor uses ReAct loop with tool calling to execute plan
- [ ] Executor can self-correct on minor issues (wrong param format, etc.)
- [ ] Executor prompts user if critical information cannot be resolved from context
- [ ] Successful execution returns clear summary of what changed
- [ ] Each completed action is recorded for potential rollback

### Failure & Rollback

- [ ] On mid-chain failure, reversible completed actions are rolled back
- [ ] Irreversible actions are reported with manual recovery guidance
- [ ] Error messages are user-friendly and actionable (e.g., "retry in 5 seconds" for 429)
- [ ] Conflict errors (409) suggest user refresh and retry

### Extensibility

- [ ] New booking action can be added by: (1) updating OpenAPI spec, (2) adding metadata overlay — no code changes required
- [ ] Action metadata supports: description, parameter allowlist, safety tier, reversibility, compensation reference

### Observability

- [ ] All LLM calls traced to Langfuse with prompt, response, latency, tokens
- [ ] All tool calls traced with parameters, response, outcome
- [ ] Execution traces link planning → confirmation → execution → rollback (if any)

---

## Decision Records

| Decision | Choice | Rationale | Alternatives Considered |
|----------|--------|-----------|-------------------------|
| Tool architecture | Atomic actions auto-imported from OpenAPI | Scales to hundreds of actions without manual coding; new APIs immediately available | Hand-coded tools per action (rejected: doesn't scale) |
| NL processing location | Backend service | Allows model improvements without app updates; keeps mobile app thin | On-device (rejected: model size, update friction) |
| Execution model | Queued with status tracking | Handles mobile connectivity; provides transparency; production-grade | Synchronous (rejected: poor UX on flaky networks), Optimistic UI (rejected: rollback complexity) |
| Plan confirmation | Full plan, confirm once | Builds user trust; single friction point; risk tiers shown but don't interrupt | Step-by-step confirm (rejected: too many interruptions) |
| LLM execution | ReAct loop with tool calling | Self-correction capability; dynamic parameter resolution; leverages LangGraph strengths | Static plan executor (rejected: can't handle unexpected responses) |
| Conflict handling | Detection at execution time, no locking | Avoids distributed lock complexity; conflicts are rare; good failure UX handles edge cases | Soft locking (deferred: add if data shows it's needed) |
| Safety model | Blocklist dangerous + confirmation tiers | Prevents catastrophic actions; tier metadata enables future auto-approval for low-risk | Allowlist only (rejected: too restrictive for scale) |
| Parameter handling | Curated subset via metadata overlay | Predictable LLM behavior; prevents hallucination on unused optional params | Full OpenAPI params (rejected: LLM confusion, unpredictable) |
| Observability | Langfuse for LLM tracing | Team familiarity; good for debugging and optimization decisions | Custom logging (rejected: reinventing wheel) |

---

## Dependency Declarations

> **Note:** These are current expectations based on team context. Subject to change during implementation as technical requirements are validated.

| Capability | Requirements | Notes |
|------------|--------------|-------|
| LLM with tool calling | Supports function/tool calling, streaming, reasonable latency | Currently Gemini; spec doesn't lock provider |
| LangGraph runtime | State management, ReAct loop support | For agent execution |
| OpenAPI parser | Read and parse OpenAPI 3.x specs | For action transformation |
| HTTP client | Async, retry support, auth header passthrough | For ROLLER API calls |
| Queue/state store | Session-scoped plan storage, status tracking | In-memory acceptable for SLC; persistence deferred |
| Langfuse client | Trace creation, span nesting, metadata attachment | For observability |
| ROLLER APIs | Booking search, booking update endpoints | Accessed via user's auth token |

---

## Open Questions

- [ ] Which specific ROLLER APIs will be used for the 3 MVP actions? (To be confirmed with API team)
- [x] What's the exact format of booking search API response? → Minimum required fields defined in [BookingSummary](contracts/data-definitions.md#booking-summary); exact API mapping is implementation detail
- [ ] How will this service integrate with the existing IQ intent classifier? (Deferred to team discussion)
- [ ] Real-time operational data integration timeline and design (1-1.5 months out; forward-compatible design ready)
