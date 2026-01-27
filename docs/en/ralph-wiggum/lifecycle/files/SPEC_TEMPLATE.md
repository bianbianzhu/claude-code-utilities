# Spec Template

> Purpose: define behavior and constraints, not implementation. Keep it implementable and testable.

## Overview
- **Problem / JTBD**:
- **Goals**:
- **Non‑Goals**:

## Scope
- **In Scope (MVP)**:
- **Explicitly Deferred**:

## Glossary
- **Term**: Definition

## Core Flows
Describe the happy path and common failure modes.

### Happy Path
1. ...

### Common Failures
- ...

## Interfaces & Contracts (Abstract)
Define cross‑module boundaries here. No concrete library calls.

### Interface List
- **Interface Name**: Producer → Consumer
- **Purpose**:

### Data Shapes
Use a structured format (table or JSON‑like schema). Example:

| Field | Type | Required | Constraints | Notes |
|------|------|----------|-------------|------|
| id   | string | yes | non-empty | |

### Error Codes / Failure Modes
- **ERROR_CODE**: when it occurs, expected handling

## External Dependencies
- **Library/Service**: version pin (or compatibility range)
- **Required behavior** (avoid concrete API calls unless unavoidable)

## Acceptance Criteria (Testable)
- [ ] ...
- [ ] ...

## Open Questions
- ...

## References (Optional)
If you must include pseudocode or detailed logic, put it here and **mark it explicitly as non‑executable**:

```
PSEUDOCODE ONLY — DO NOT COPY VERBATIM
```
