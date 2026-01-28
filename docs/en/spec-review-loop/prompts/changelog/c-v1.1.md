# Spec Review Loop Prompt Changes (v1.1)

This note captures required changes to the spec-review loop prompts (`01-find-issues.md`, `02-fix-issues.md`, `03-confirm-fix.md`) based on the latest `SPEC_GENERATION_GUIDE.md`.

---

## Summary

The loop’s flow is correct, but quality gates are missing. Prompts are not aligned with `SPEC_GENERATION_GUIDE.md`, lack convergence controls, and don’t provide machine‑readable signals for automation.

---

## 01-find-issues.md — Review Phase

### Problems
- **Not aligned with `SPEC_GENERATION_GUIDE.md`**: G1–G11, Checklist, and De‑Implementation rules are not enforced.
- **No convergence controls**: broad criteria → infinite issue discovery.
- **Hardcoded example filenames**: can mislead reviewers.
- **No cap on issue count**: leads to noisy, low‑value issues.

### Changes
- Add **Spec Guide Compliance** section: enforce G1–G11 + Checklist; require Rule ID tagging per issue.
- Integrate `loop-improvement-v1.md` rules: **Issue Threshold**, **Definition of Done**, **Out of Scope**.
- Replace hardcoded examples with **README‑driven spec discovery** only.
- Add **issue caps**: e.g., first pass ≤10; subsequent passes ≤5 new issues.

---

## 02-fix-issues.md — Fix Phase

### Problems
- **Spec standard missing**: fixer can add implementation code or library APIs.
- **“Already resolved” rule is vague**.
- **AFK mode lacks scope bounds**: can over‑edit unrelated content.
- **No durable fix summary** for confirm stage.

### Changes
- Require reading `references/SPEC_GENERATION_GUIDE.md` before changes.
- Enforce **G1–G11** during fixes; run **De‑Implementation Check** after.
- Define “Already Resolved” explicitly by re‑reading current spec content.
- Add guard: **only modify content directly related to an issue**.
- Produce a **structured fix summary** (Accepted/Declined + changes), not only declined feedback.

---

## 03-confirm-fix.md — Confirm Phase

### Problems
- **No machine‑readable loop status**.
- **No guide‑compliance verification**.
- **Decline ↔ re‑raise loop has no termination rule**.
- **`git diff` may be unavailable**.

### Changes
- Add completion signal:
  - `<promise>ALL_RESOLVED</promise>` or
  - `<promise>ISSUES_REMAINING</promise>` + list IDs
- Re‑verify against **SPEC_GENERATION_GUIDE.md**; re‑raise any G1–G11 violations.
- Add escalation rule for repeated decline/re‑raise: **require human decision**.
- Allow `git diff` if available; otherwise validate via current spec content.

---

## Cross‑Prompt System Issues

### Problems
- **No shared issue schema** across 01/02/03.
- **No uniform reference to spec guide**.
- **Convergence fixes not integrated**.
- **No orchestration automation** (optional, not required for correctness).

### Changes
- Standardize issue format: `ID / Title / Severity / Location / RuleID / Evidence / Impact / Suggested Fix`.
- Add **SPEC_GENERATION_GUIDE.md** reference to all three prompts.
- Integrate convergence thresholds in 01.
- (Optional) add orchestration script after prompts are aligned.

---

## Priority Order

1. Add **SPEC_GENERATION_GUIDE.md** reference to all three prompts.
2. Integrate **Issue Threshold / DoD / Out‑of‑Scope** into 01.
3. Add **completion signal** to 03.
4. Standardize issue schema across the loop.
5. Add durable fix summary in 02.
6. Optional orchestration script.
