# Prompt Change Management

How the spec review loop's prompts are versioned, reviewed, and evolved.

## Directory Layout

```
spec-review-loop/
├── 01-find-issues.md          # Active prompts (current version)
├── 02-fix-issues.md
├── 03-confirm-fix.md
├── architect/                  # Design documentation
│   ├── spec-review-loop.md    #   Loop architecture (nested loops, control signals)
│   ├── prompt-change-management.md  #   This document
│   └── *.md                   #   Design rationale docs (e.g., convergence fix)
├── prompts/
│   ├── archived/              #   Previous prompt versions (read-only)
│   │   ├── 01-find-issues-v1.md
│   │   ├── 01-find-issues-v1.1.md
│   │   └── ...
│   └── changelog/             #   Change tracking per version
│       ├── c-v1.1.md
│       └── c-v1.3.md
├── example/                   #   Reference specs and issues for testing
└── scripts/                   #   Orchestrator scripts
```

**Active prompts** live at the root level. They are always the latest version — no version suffix in the filename. Previous versions are archived under `prompts/archived/` with version suffixes (e.g., `01-find-issues-v1.2.md`).

## Versioning

Prompts are versioned as a set. All three step prompts share the same version number.

| Version | Meaning |
|---------|---------|
| v1      | Initial release |
| v1.1    | Patch — minor fixes, no structural changes |
| v1.3    | Minor — structural changes (new sections, new status values, removed sections) |
| v2      | Major — breaking changes to loop architecture or control signals |

When a new version is finalized:
1. Copy current active prompts to `prompts/archived/` with version suffix
2. Apply changes to the active prompts (root level)
3. The changelog records what changed and why

## Changelog System

Each version that involves deliberate changes gets a changelog file at `prompts/changelog/c-v{version}.md`.

### Structure

```markdown
# Spec Review Loop Prompt Changes (v{version})

## Summary
One-paragraph overview of what this version addresses.

## Resolved
### {Change title}
- ~~**[Severity] ID**: Problem description~~
**Change applied**: What was done.
  (or)
**Rationale**: Why no change was needed (accepted-as-is / won't-fix).

## Open — {filename}
### Problems
- **[Severity] ID: Title**
  Problem description.
### Proposed Changes
- **ID**: Proposed fix.

## Priority Order (remaining)
1. **[Severity]** Description (ID).
```

### Issue Fields

| Field | Description |
|-------|-------------|
| **ID** | Single letter (A, B, C…), unique within the changelog |
| **Severity** | Critical / High / Medium / Low |
| **Affected file** | Which prompt or architect doc has the problem |
| **Problem** | What's wrong — observable symptom, not speculation |
| **Proposed Change** | Concrete fix — what to add, remove, or modify |

### Resolution Types

| Type | When to use | What to record |
|------|-------------|----------------|
| **Change applied** | Fix was implemented in the prompt | Describe the change and affected locations |
| **Accepted as-is** | Problem exists but doesn't justify a change | Explain why the current behavior is acceptable |
| **Won't-fix** | Problem is theoretical or cost exceeds benefit | State the decision, document assumptions that could invalidate it |

### Conventions

- **Resolved items use strikethrough**: `~~**[Severity] ID**: description~~` makes it immediately visible which items are done.
- **Each resolution has a rationale block**: Either `Change applied`, `Rationale`, or `Decision` — never just "done" or "fixed."
- **Assumptions are explicit**: When a won't-fix depends on design assumptions, list them under `Assumptions (if any change, revisit this decision)`.
- **Priority Order is maintained**: Open items are ranked by severity, giving clear execution order. Updated as items are resolved.

## Change Workflow

```
Discover issue → Record in changelog → Analyze & propose fix → Execute → Record resolution
```

### Step by step

1. **Discover**: Issues come from usage, review, or systematic analysis of prompts.

2. **Record**: Add to the changelog's Open section under the affected file. Assign ID, severity, describe problem and proposed change.

3. **Analyze**: Before executing, discuss the approach:
   - Is the problem real or a misunderstanding?
   - Does the proposed fix introduce new problems?
   - What's the minimal change needed?
   - Are there cross-prompt implications?

4. **Execute**: Apply changes to the active prompts. Scope guardrail — only modify what's directly related to the issue.

5. **Record resolution**: Move the item from Open to Resolved. Document what was done (or why nothing was done).

6. **Update dependents**: If the change affects the architect doc (e.g., new control signals, changed loop semantics), update `spec-review-loop.md` as well.

### Batch processing

Issues are typically processed in priority order within a single session. The changelog serves as the work queue — Priority Order tracks what's left. When all items are resolved, the changelog is complete.

## Relationship to Other Documents

| Document | Role | Updated when |
|----------|------|-------------|
| Active prompts (01, 02, 03) | What the loop actually executes | Changes are applied |
| `architect/spec-review-loop.md` | Loop architecture and semantics | Loop behavior changes |
| `prompts/changelog/c-v{N}.md` | Change history and rationale | Issues are found or resolved |
| `prompts/archived/*` | Read-only snapshots | Before applying a new version |
| Design rationale docs (`architect/*.md`) | Why specific design decisions were made | When novel problems are solved |
