# Questions and Answers — Brainstorming Session

> **Date:** 2026-01-29
> **Topic:** ROLLER iQ Booking Updates on Mobile
> **Input:** idea-end-state.md

---

## Understanding the Idea

### Q1: Does ROLLER iQ already exist, or is this being built from scratch?

**Answer:** ROLLER iQ already exists. However, for this spec design, treat it as a new project that will later integrate (loosely coupled) with the existing system. Don't follow legacy designs.

---

### Q2: For MVP scope, which describes your intent for the 3 core actions?

**Options:**
- A. Only these 3 actions (strictly limited)
- B. These 3 + extensible design
- C. These 3 are examples of a broader set

**Answer:** B — Start with these 3, but design the system so adding new actions later is straightforward.

---

### Q3: How should the system handle ambiguity or missing information?

**Options:**
- A. Strict clarification (always ask)
- B. Smart defaults + confirm
- C. Context-aware hybrid

**Answer:** B — Smart defaults (e.g., "next Saturday"), then show confirmation card. However, truly uncertain things (number of guests, which booking) MUST trigger explicit follow-up questions.

---

### Q4: What happens after the user confirms the plan?

**Options:**
- A. Synchronous execution
- B. Optimistic UI
- C. Queued with status

**Answer:** C — Queued with status. Building production-level SLC, not a prototype.

---

### Q5: How should failures be handled when a change cannot be applied?

**Options:**
- A. Notify + manual retry
- B. Notify + suggest alternatives
- C. Auto-resolve when possible

**Answer:** B — Notify with suggestions, but user must still manually retry.

---

### Q6: What's the authentication/authorization model?

**Options:**
- A. Inherit existing auth
- B. Feature-specific permissions
- C. Booking-level access control

**Answer:** A — Users are already logged into ROLLER; this feature uses their existing session/permissions.

---

### Q7: Where does NL parsing/understanding happen?

**Options:**
- A. On-device
- B. Backend service
- C. Hybrid

**Answer:** B — Mobile sends raw text to backend; all NL understanding happens on the backend.

---

### Q8: What's the expectation for the underlying NL technology?

**Options:**
- A. LLM-based
- B. Traditional NLU
- C. Agnostic

**Answer:** A — LLM-based (GPT, Claude, Gemini, etc.).

---

### Q9: How does this feature access booking information?

**Options:**
- A. API calls to existing ROLLER
- B. Replicated data store
- C. Passed from mobile app

**Answer:** Currently A (API calls to ROLLER). Real-time operational data coming in 1-1.5 months; design should be forward-compatible.

---

### Q10: How does the change actually get applied to ROLLER?

**Options:**
- A. Direct API mutation
- B. Event/message-based
- C. To be designed

**Answer:** A — Using existing APIs (public or internal TBD). May be a chain of APIs executed in sequence, where each consumes the previous one's output.

---

### Q11: Are "quick actions" shortcuts to NL or structured forms?

**Options:**
- A. Shortcuts to NL (pre-fill text input)
- B. Structured forms
- C. Both paths to same backend

**Answer:** A — Tapping a quick action pre-fills the text input with a template. Unified flow through NL.

---

### Q12: Does the user need to see a history of past changes?

**Options:**
- A. Current session only
- B. Persistent history
- C. MVP: session only, future: history

**Answer:** C — Session-scoped visibility for MVP; persistent history deferred.

---

### Q13: Should the system actively prevent concurrent edits (locking)?

**Discussion:** User asked for recommendation.

**Recommendation & Answer:** No locking for MVP. Detect conflicts at execution time; fail gracefully with suggestions. Reasons:
- Distributed locks add complexity
- Confirmation card shows current state (natural freshness check)
- ROLLER APIs likely have optimistic locking already
- Good failure handling provides acceptable UX

Soft locking can be added later if data shows it's needed.

---

### Q14: How should users be notified of status updates?

**Options:**
- A. In-app only
- B. Push notifications
- C. MVP: in-app, future: push

**Answer:** C — Backend provides status; mobile team handles display. Focus is on backend.

---

### Q15: How should the system identify which booking the user means?

**Answer:** Use chat history context first (tool call responses, user mentions). If no context, do fuzzy search. Never assume — ask when uncertain.

---

### Q16: What's the operator's visibility when searching bookings?

**Options:**
- A. Venue-scoped
- B. All bookings
- C. Handled by ROLLER API

**Answer:** C — ROLLER API handles RBAC. This service passes auth token and gets back only what user is permitted to see.

---

### Q17: Do booking changes need audit logging?

**Options:**
- A. ROLLER handles it
- B. This service logs too
- C. MVP: minimal, future: full

**Answer:** C — Primary focus is Langfuse observability for LLM operations (calls, tool use, latency, tokens). Full audit trail deferred.

---

### Q18: Tech stack?

**Answer:** LangGraph/LangChain ecosystem, Python, Gemini models (open to change). Captured for context; spec remains behavioral.

---

## Exploring Approaches

### Architecture Discussion

User confirmed **Approach A: Single Agent with Tool Calling** as the base.

However, significant discussion refined the approach:

---

### Q19: Intent routing?

**Answer:** Existing ROLLER iQ has multi-agent supervisor structure with intent classifier. Adding booking updates will integrate later. This SLC excludes intent routing but should plug in cleanly as a sub-agent.

---

### Q20: Tool architecture?

**Answer:** Don't hand-code tools one by one. Vision is **Atomic Actions** auto-imported from OpenAPI specs. LLM composes actions dynamically at runtime. New API endpoints become available without manual coding.

---

### Q21: OpenAPI to tool transformation level?

**Options:**
- A. Direct mapping
- B. Curated subset
- C. Enhanced with metadata

**Answer:** C — OpenAPI + metadata layer (descriptions, examples, safety rules). Limit optional parameters for SLC to make API calls predictable.

---

### Q22: Safety and guardrails model?

**Options:**
- A. Allowlist actions
- B. Blocklist dangerous
- C. Confirmation tiers

**Answer:** C with B — Blocklist truly dangerous actions (delete user, delete org). Remaining actions have confirmation tiers (high-risk highlighted, low-risk normal).

---

### Q23: Action chain execution model?

**Options:**
- A. Plan then confirm all
- B. Step-by-step confirm
- C. Confirm high-risk only

**Answer:** A — User sees full plan, confirms once, execution proceeds without further interruptions. Tier classification used for display emphasis (high-risk highlighted) now; execution policy changes possible in future.

---

### Q24: How does the LLM handle data dependencies in chains?

**Options:**
- A. LLM plans with placeholders (executor resolves at runtime)
- B. Iterative planning
- C. Hybrid

**Answer:** A — Full plan first. Re-planning is not in SLC scope.

---

### Q25: Execution failure handling?

**Options:**
- A. Fail and report
- B. Rollback completed steps
- C. Partial success

**Answer:** B — Rollback as much as possible. Error-aware reporting (429 → "retry in X seconds", 500 → "server down"). No auto-retry from this service. For irreversible actions that completed, report what was done and manual recovery steps.

---

### Q26: How does the system know which actions can be rolled back?

**Options:**
- A. Metadata in action definition
- B. Convention-based
- C. Explicit pairs

**Answer:** A — Each atomic action declares if reversible and references its compensation action in metadata.

---

### Q27: Execution mechanism clarification

**Correction from user:** The executor is not a mechanical script runner. It's an LLM-driven ReAct loop using tool calling. The LLM:
- Decides which tool to call with what parameters
- Observes tool response
- Can self-correct (wrong params, wrong sequence)
- Can prompt user if missing critical info

Distinction:
- **Plan** = high-level intent for user confirmation
- **Execution** = LLM dynamically calls tools, self-corrects minor issues
- **Not in scope:** Strategic re-planning if overall approach fails

---

## Final Alignment

User confirmed the problem statement, constraints, success criteria, and architectural decisions before proceeding to design documentation.
