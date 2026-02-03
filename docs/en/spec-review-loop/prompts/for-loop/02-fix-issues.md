Review design spec issues from {Issues file} (latest iteration from Codex reviewer).

Before making any changes, read `./references/SPEC_GENERATION_GUIDE.md`. If missing, STOP and report a blocking issue: "Missing SPEC_GENERATION_GUIDE.md — cannot apply required spec standard."

For each finding:
1. **Verify** - Does the current design spec (under ./specs) actually have this gap/issue?
2. **Validate** - Is this a legitimate concern that would impact implementation?
3. **Evaluate** - If valid, is Codex's suggested spec change:
   - Addressing the root issue
   - Appropriately scoped (not over-specified or under-specified)
   - Following best practices
   - Not over-engineered or adding unnecessary complexity
   - Consistent with the overall design
4. **Check Human Override** - If the issue includes `Human Override: Must Fix`, you MUST address it in this iteration.
5. **Update** - Apply good suggestions to the design spec; apply better alternatives for flawed ones. All changes MUST comply with SPEC_GENERATION_GUIDE Guardrails G1–G11 and the De-Implementation Check. Do not introduce implementation code, library APIs, or concrete config values.

Skip issues already resolved completely. To determine "Already Resolved", re-read the current spec section cited in the issue and confirm the problem no longer exists. If resolved, mark it as **Already Resolved** in your summary.

Scope guardrail: Only modify content directly related to the identified issue. Do not refactor or "improve" surrounding content.

Do NOT create any files beyond those explicitly specified below.

After all findings are processed:
1. Provide a summary of: accepted changes, declined suggestions, and already-resolved items.
2. Write a structured processing summary to {Summary file} with:
   - Issue ID / Title
   - Decision (Accepted / Declined / Already Resolved)
   - Changes Applied (short)
   - Guide Rule IDs affected (if any)
3. If any suggestions were declined, write feedback to {Feedback file}:

## Feedback

### [Issue Title/Number]
- **Suggestion**: (one-line summary of what Codex proposed)
- **Decision**: Declined
- **Reasoning**: (concise explanation - why it's out of scope, not needed, or conflicts with design intent)

(Repeat for each declined suggestion)

Keep reasoning direct and technical - this serves as documented feedback for the next review cycle.
