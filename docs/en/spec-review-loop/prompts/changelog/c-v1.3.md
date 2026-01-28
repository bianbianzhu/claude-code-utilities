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

---

## Open — 01-find-issues.md

### Problems

- **[High] A: Medium severity undefined but present in output format**
  Issue Threshold defines Critical, High, and "Do NOT raise" — no Medium. The output template includes `## Medium Priority Issues`. Codex has no criteria to classify Medium.

- **[High] J: Missing Specifications bypasses issue limit and severity filter**
  The `## Missing Specifications` section is independent of Critical/High sections. Items have no severity and don't count toward the 5-issue cap. A report could list 5 issues + N missing specs, bypassing the limit.

- **[Low] B: Completion behavior is ambiguous**
  Completion says "Output ONLY `<promise>COMPLETE</promise>` — Do NOT create the full issue report structure." But Output Format says "Write findings to {Output file}." Unclear whether the file should be created when no issues exist.

### Proposed Changes

- **A**: Remove the `## Medium Priority Issues` section from the output template. Two tiers (Critical + High) with a 5-issue cap are sufficient.

- **J**: Remove the standalone `## Missing Specifications` section. Add to review criteria: "If a module is referenced but not specified, raise it as a Critical or High issue depending on whether it blocks implementation." Missing specs then compete for the same cap slots.

- **B**: Add: "If no issues are found, do NOT create the output file. Output `<promise>COMPLETE</promise>` in your response only."

---

## Open — 02-fix-issues.md

### Problems

- **[Low] D: Verification-only fields in input are unaddressed**
  When input comes from step 03, the file contains `What Changed`, `Assessment`, `Remaining Work` fields that don't exist in step 01's format. Processing works via shared `Problem`/`Suggested Fix` fields, but explicit guidance is missing.

- **[Low] L: Handling of "Fixed" status issues is unspecified**
  The "Skip issues already resolved" instruction requires re-reading the spec. It doesn't allow skipping by Status field, which is wasteful for clearly resolved items.

### Proposed Changes

- **D**: Add: "If the input contains verification-only fields (`What Changed`, `Assessment`, `Remaining Work`), use them as context but base Verify/Validate/Evaluate on `Problem` and `Suggested Fix`."

- **L**: Add: "If issues have `Status: Fixed` and `Problem: Resolved`, skip without re-verification."

---

## Open — 03-confirm-fix.md

### Problems

- **[Medium] M: Accepted decline has no distinct Status value**
  Status enum is `Fixed/Partial/Missing/Declined`. Completion says "ALL issues resolved (including accepted declines)." When a decline is accepted, there's no Status to represent this — `Declined` looks unresolved, `Fixed` is inaccurate. An orchestrator cannot distinguish accepted declines from pending re-raises.

- **[Medium] G: What Changed and Assessment fields lack fill guidance**
  `Problem`, `Evidence`, `Impact`, `Suggested Fix` have conditional instructions. `What Changed` and `Assessment` have none — unclear what to write for each Status value.

- **[Medium] K: New issues from regressions have no section or ID rules**
  Step 03 allows raising new issues for regressions but provides no output section or ID numbering rule. New IDs could collide with existing ones.

### Proposed Changes

- **M**: Add `Declined-Accepted` to Status enum. `ALL_RESOLVED` when every issue is `Fixed` or `Declined-Accepted`; `ISSUES_REMAINING` when any is `Partial`, `Missing`, or `Declined`.

- **G**: Add conditional guidance:
  - `What Changed`: describe modifications; if Missing → "No changes detected"; if Declined → "Declined by implementer"
  - `Assessment`: if Fixed → "Fully addressed"; if Missing → "Not attempted"; if Declined → "See Feedback Review"

- **K**: Add `## New Issues (Regressions)` section after Detailed Findings. New issue IDs start from N+1 where N is the highest existing ID in the input report.

---

## Open — Cross-Prompt

### Problem

- **Issue ID namespace is fragile**: IDs are local to each report file. Step 03 regression issues and step 01 subsequent reviews can produce colliding IDs.

### Proposed Change

- Adopt `v{version}-{sequence}` convention (e.g., `v1-1`, `v2-3`). Version comes from the output filename. Globally unique without cross-file reads.

---

## Priority Order (remaining)

1. **[High]** Remove Medium severity section from 01 output template (A).
2. **[High]** Fold Missing Specifications into issue cap in 01 (J).
3. **[Medium]** Add `Declined-Accepted` Status to 03 (M).
4. **[Medium]** Add What Changed / Assessment fill guidance to 03 (G).
5. **[Medium]** Add New Issues section and ID rules to 03 (K).
6. **[Low]** Clarify completion file behavior in 01 (B).
7. **[Low]** Clarify verification-only field handling in 02 (D).
8. **[Low]** Clarify Fixed status skip rule in 02 (L).
