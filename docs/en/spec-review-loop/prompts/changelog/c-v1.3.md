# Spec Review Loop Prompt Changes (v1.3)

This note captures required changes to the spec-review loop prompts (`01-find-issues.md`, `02-fix-issues.md`, `03-confirm-fix.md`), the flow diagram (`architect/spec-review-loop.md`), and the upstream brainstorming skill (`SKILL.md`) based on a full review.

---

## Summary

Prompts are structurally solid but have remaining gaps: (1) step 01 output format has sections with no matching threshold criteria, and (2) step 03's output format has under-specified fields and status values. The escalation mechanism (added in v1.2) was removed — cross-session state tracking is infeasible. Loop termination is handled by an external max iteration count.

---

## Resolved

### Escalation removed

Removed from `03-confirm-fix.md` (6 locations) and `architect/spec-review-loop.md` (flow diagram + loop logic).

- ~~**[Critical] E**: Promise signal cannot distinguish partial fix from escalation~~
- ~~**[Critical] F**: Escalation judgment requires history that isn't available~~
- ~~**[High] C**: No guidance for processing escalated items after human decision~~

**Rationale**: Each review/fix cycle is a new session with no access to prior iteration state. The external max iteration count prevents infinite loops; the user checks in periodically to resolve disagreements.

### Issue limits simplified

- ~~**[High] I**: "max 5 new issues" is unenforceable~~

**Change applied**: Replaced first/subsequent distinction (`max 10` / `max 5 new`) with a flat `Each review: max 5 issues`. Removed the word "new" — no cross-session deduplication needed.

### `end-state-ideal.md` removed from 01 scope

Removed from core files list (01:26) and Files Reviewed checklist (01:182). The brainstorming skill (`SKILL.md`) and `SPEC_GENERATION_GUIDE.md` do not generate this file. `README.md` already defines scope; a separate vision doc risks reviewer raising issues about deferred features.

### Upstream skill fixes (`SKILL.md`)

Two gaps between the brainstorming skill and the spec review loop were identified and fixed:

1. **Q&A file wording**: Changed from "Capture key design decisions and trade-offs" to "Record all questions asked and answers given during Understanding the idea." The old wording overlapped with each spec's Decision Records section and was vague about what counts as "key."

2. **Contracts file generation missing**: `SPEC_GENERATION_GUIDE.md` requires centralized contracts (`specs/contracts/` or `specs/interfaces.md`) and 01-find-issues checks for them, but `SKILL.md` had no instruction to create them. Added: "If cross-module data shapes are defined, centralize abstract contracts in `specs/contracts/` (multiple files) or `specs/interfaces.md` (single file). Other specs must reference these contracts, not redefine them."

### Completion behavior clarified

- ~~**[Low] B**: Completion behavior is ambiguous~~

**Change applied**: Updated Completion section in `01-find-issues.md` to: "If no issues meeting the Issue Threshold (Critical or High) are found … Do NOT create the output file or the full issue report structure." Explicitly ties termination to severity scope and clarifies no file is created on completion.

### 02-fix-issues edge cases accepted as-is

- ~~**[Low] D**: Verification-only fields in input are unaddressed~~
- ~~**[Low] L**: Handling of "Fixed" status issues is unspecified~~

**Rationale**: Both are minor inefficiencies, not correctness issues. D: Claude Code already processes via shared `Problem`/`Suggested Fix` fields regardless of extra fields. L: Re-reading the spec to confirm resolution is redundant but harmless — the cost doesn't justify adding more rules to the prompt.

### Medium severity section removed from 01 output template

- ~~**[High] A**: Medium severity undefined but present in output format~~

**Change applied**: Removed `## Medium Priority Issues` section from the output template in `01-find-issues.md`. Issue Threshold only defines Critical and High — two tiers with a 5-issue cap are sufficient.

### Missing Specifications folded into issue cap

- ~~**[High] J**: Missing Specifications bypasses issue limit and severity filter~~

**Change applied**: Removed standalone `## Missing Specifications` section from the output template in `01-find-issues.md`. Added classification rule to Issue Threshold: "If a module or component is referenced but not specified, raise it as a Critical or High issue depending on whether it blocks implementation." Missing specs now compete for the same 5-issue cap slots.

### `Declined-Accepted` Status added to 03

- ~~**[Medium] M**: Accepted decline has no distinct Status value~~

**Change applied**: Added `Declined-Accepted` to Status enum in `03-confirm-fix.md` (Summary table + Detailed Findings). Updated conditional field instructions (`Problem`, `Evidence`, `Impact`, `Suggested Fix`) to treat `Declined-Accepted` same as `Fixed`. Completion Status logic now explicit: `ALL_RESOLVED` when all `Fixed` or `Declined-Accepted`; `ISSUES_REMAINING` when any `Partial`, `Missing`, or `Declined`.

### Fill guidance added for What Changed, Assessment, Remaining Work

- ~~**[Medium] G**: What Changed and Assessment fields lack fill guidance~~

**Change applied**: Added per-Status conditional instructions for `What Changed`, `Assessment`, and `Remaining Work` in `03-confirm-fix.md` Detailed Findings. Covers all 5 Status values. Key distinctions: `Declined-Accepted` What Changed reads "Declined by implementer; accepted in feedback review" (distinguishes from plain `Declined`). `Declined` Remaining Work reads "Re-raised: fix required or provide revised rationale" (not "pending" — Feedback Review completes in same round). Scope extended to include `Remaining Work` which had the same gap.

---

## Open — 03-confirm-fix.md

### Problems

- **[Medium] K: New issues from regressions have no section or ID rules**
  Step 03 allows raising new issues for regressions but provides no output section or ID numbering rule. New IDs could collide with existing ones.

### Proposed Changes

- **K**: Add `## New Issues (Regressions)` section after Detailed Findings. New issue IDs start from N+1 where N is the highest existing ID in the input report.

---

## Open — Cross-Prompt

### Problem

- **Issue ID namespace is fragile**: IDs are local to each report file. Step 03 regression issues and step 01 subsequent reviews can produce colliding IDs.

### Proposed Change

- Adopt `v{version}-{sequence}` convention (e.g., `v1-1`, `v2-3`). Version comes from the output filename. Globally unique without cross-file reads.

---

## Priority Order (remaining)

1. **[Medium]** Add New Issues section and ID rules to 03 (K).
