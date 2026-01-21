### Claude Code fixes design spec issues found by Codex reviewer.

# AFK Version
```markdown
Review design spec issues from ./specs/issues/2026-01-20-v2.md (2nd iteration from Codex reviewer).

For each finding:
1. **Verify** - Does the current design spec (under ./specs) actually have this gap/issue?
2. **Validate** - Is this a legitimate concern that would impact implementation?
3. **Evaluate** - If valid, is Codex's suggested spec change:
   - Addressing the root issue
   - Appropriately scoped (not over-specified or under-specified)
   - Following best practices
   - Not over-engineered or adding unnecessary complexity
   - Consistent with the overall design
4. **Update** - Apply good suggestions to the design spec; propose alternatives for flawed ones

Skip issues already resolved completely.

After all findings are processed:
1. Provide a summary of: resolved issues, accepted changes, rejected suggestions
2. If any rejections, write to @specs/issues/<YYYY-MM-DD>-v2-rejected.md:

## Rejected Suggestions

### [Issue Title/Number]
- **Suggestion**: (one-line summary of what Codex proposed)
- **Rejection Reason**: (concise explanation - why it's not needed, incorrect, or conflicts with design intent)

(Repeat for each rejection)

Keep rejection reasoning direct and technical - this serves as documented feedback for the next review cycle.
```

# HITL version
```markdown
Review design spec issues from @specs/issues/2026-01-20-v2.md (2nd iteration from Codex reviewer).

For each finding:
1. **Verify** - Does the current design spec actually have this gap/issue?
2. **Validate** - Is this a legitimate concern that would impact implementation?
3. **Evaluate** - If valid, is Codex's suggested spec change:
   - Addressing the root issue
   - Appropriately scoped (not over-specified or under-specified)
   - Following best practices
   - Not over-engineered or adding unnecessary complexity
   - Consistent with the overall design
4. **Checkpoint** - Present your analysis and proposed action, then wait for my approval before making any changes
5. **Update** - Only after I confirm, apply the change to the design spec

Process one finding at a time. Do not proceed to the next finding until I approve or provide feedback on the current one.

Skip issues already resolved completely.

After all findings are processed:
1. Provide a summary of: resolved issues, accepted changes, rejected suggestions
2. If any rejections, write to ./specs/issues/<YYYY-MM-DD>-v2-rejected.md:

## Rejected Suggestions

### [Issue Title/Number]
- **Suggestion**: (one-line summary of what Codex proposed)
- **Rejection Reason**: (concise explanation - why it's not needed, incorrect, or conflicts with design intent)

(Repeat for each rejection)

Keep rejection reasoning direct and technical - this serves as documented feedback for the next review cycle.
```