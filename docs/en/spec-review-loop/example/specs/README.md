# ROLLER iQ Booking Updates — Spec Index

## Overview

This spec set defines the design for ROLLER iQ's booking update capability — enabling venue operators to update bookings via natural language on mobile.

## What We're Building

A dynamic action execution system that:

1. Accepts natural language requests for booking updates
2. Uses an LLM Planner to compose chains of atomic actions
3. Shows the full plan for user confirmation (once)
4. Executes the plan with rollback on failure
5. Reports outcomes with actionable error messages

This foundation is designed to scale beyond booking updates — new actions can be added by importing from OpenAPI specs without code changes.

## Scope

### In Scope (MVP/SLC)

- 3 booking actions: reschedule, change guest count, update contact details
- OpenAPI → Atomic Action transformation with metadata (descriptions, limited params, safety tier, reversibility)
- LLM Planner that composes action chains using ReAct loop with tool calling
- Plan confirmation UI (full plan, confirm once, high-risk actions highlighted)
- Queued execution with session-scoped status tracking
- Rollback/compensation for failed chains
- Langfuse observability for LLM operations

### Explicitly Deferred

- Intent routing integration (existing IQ classifier handles; this plugs in as a sub-agent)
- Strategic re-planning on failure (self-correction within execution is in scope)
- Auto-retry from this service
- Persistent change history (session-scoped only for SLC)
- Push notifications (mobile team owns; backend provides status via polling)
- Push-based status updates to IQ orchestrator (MVP uses polling; push deferred)
- Soft locking for concurrent edits (detection at execution time only)
- Explicit plan cancellation (plans timeout via session expiry for MVP)

### Non-Goals

- Hand-coded tools per action
- Building a new auth system (inherits ROLLER auth)
- Managing RBAC (delegated to ROLLER APIs)
- Mobile app UI implementation (this spec covers backend only)

## System Success Criteria

1. User can update a booking via NL in under 30 seconds (input to confirmation)
2. LLM correctly composes action chains for the 3 core booking update types
3. Ambiguous critical data always triggers clarification (never assumes)
4. User sees full plan with risk indicators before execution
5. Failed operations roll back reversible steps and provide clear recovery guidance
6. New booking-related APIs can be added via OpenAPI + metadata (no code changes)

## Glossary

| Term | Definition |
|------|------------|
| Atomic Action | A single API operation, auto-imported from OpenAPI with enhanced metadata |
| Action Chain | Ordered sequence of atomic actions composed by LLM to fulfill user intent |
| Compensation Action | The action called to reverse/rollback a previously executed action |
| Safety Tier | Risk classification (normal / high_risk / blocked) determining confirmation behavior |
| ReAct Loop | Reason-Act-Observe cycle where LLM calls tools, observes results, and iterates |
| Plan | High-level intent shown to user for confirmation before execution |
| Execution | LLM-driven tool calling to carry out the confirmed plan |

## Data Privacy / PII / Retention

- **Sensitive data:** Guest contact details (email, phone) are PII
- **Handling:** PII passed through to ROLLER APIs; not stored in this service beyond session
- **Retention:** Session-scoped data cleared on session end; Langfuse traces follow org retention policy
- **Auth tokens:** Passed through, never logged or stored

## Spec Index

| Spec | Authority | Description |
|------|-----------|-------------|
| [contracts/data-definitions.md](contracts/data-definitions.md) | Data shapes | Centralized data definitions for all components |
| [2026-01-29-booking-updates-design.md](2026-01-29-booking-updates-design.md) | Feature design | Main design spec for booking updates capability |
| [questions-and-answers.md](questions-and-answers.md) | Discovery record | Q&A from brainstorming session |

## Tech Stack Context

> **Note:** Captured for context; spec remains behavioral and doesn't lock implementation.

- **Framework:** LangGraph / LangChain ecosystem
- **Language:** Python
- **LLM:** Gemini models (open to change)
- **Observability:** Langfuse
