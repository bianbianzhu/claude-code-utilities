---
allowed-tools: Bash(gemini:*), Bash(codex:*), Bash(claude:*), Bash(GOOGLE_*), Bash(which:*), Read, Glob, Grep, Task
argument-hint: <topic> - e.g., "routing architecture", "prompt complexity", "agent design"
description: Convene the Council of Claudes - multi-AI architectural review with Gemini, Codex, and Claude Opus
---

# Council of Claudes

**Topic:** $ARGUMENTS

Deep architectural review via multi-AI council. Take all the tokens needed - depth over speed.

## Roles

- **Claude Opus, Gemini & Codex**: Three independent reviewers (no cross-talk until debate)
- **Claude (you)**: Impartial orchestrator and synthesizer

## Phase 1: Preflight & Context

**Artifact:** Context log

1. Verify tools: `which gemini codex claude`
2. Explore codebase related to topic (Task tool or direct reads)
3. Produce structured context:
   ```
   SYSTEM: <what it does>
   STATS: <lines, files, complexity>
   CONCERNS: <specific questions>
   ```

## Phase 2: Independent Reviews

**Artifact:** Three independent review documents

Send briefing to ALL THREE in parallel. They must NOT see each other's output yet.

**Claude Opus:**
```
claude -p --model opus "<context>

Provide architectural review. Be critical. Structure as:
- STRENGTHS: what works well
- WEAKNESSES: unnecessary complexity, anti-patterns
- RECOMMENDATIONS: prioritized changes"
```

**Gemini:**
```
GOOGLE_GENAI_USE_VERTEXAI=true GOOGLE_CLOUD_PROJECT=automation-service-stag GOOGLE_CLOUD_LOCATION=us-central1 gemini "<context>

Provide architectural review. Be critical. Structure as:
- STRENGTHS: what works well
- WEAKNESSES: unnecessary complexity, anti-patterns
- RECOMMENDATIONS: prioritized changes"
```

**Codex:**
```
codex exec "<context>

Provide architectural review. Be critical. Structure as:
- STRENGTHS: what works well
- WEAKNESSES: unnecessary complexity, anti-patterns
- RECOMMENDATIONS: prioritized changes"
```

## Phase 3: Structured Debate

**Artifact:** Claims and counter-claims document

Share all three perspectives and have them challenge each other:

**Claude Opus responds:**
```
claude -p --model opus "Two other reviewers said:

GEMINI: <summary>
CODEX: <summary>

Where do you AGREE? Where do you DISAGREE and why? What did they both miss?"
```

**Gemini responds:**
```
GOOGLE_GENAI_USE_VERTEXAI=true GOOGLE_CLOUD_PROJECT=automation-service-stag GOOGLE_CLOUD_LOCATION=us-central1 gemini --resume latest "Two other reviewers said:

OPUS: <summary>
CODEX: <summary>

Where do you AGREE? Where do you DISAGREE and why? What did they both miss?"
```

**Codex responds:**
```
codex exec resume --last "Two other reviewers said:

OPUS: <summary>
GEMINI: <summary>

Where do you AGREE? Where do you DISAGREE and why? What did they both miss?"
```

Push further if findings conflict materially.

## Phase 4: Synthesis

**Artifact:** Final council report

As impartial synthesizer, produce:

| Section | Content |
|---------|---------|
| **Unanimous Findings** | Where all three reviewers agreed |
| **Majority View** | Where 2 of 3 agreed |
| **Key Tensions** | Where they disagreed, with your resolution |
| **Top 3 Recommendations** | Prioritized by impact, with rationale |
| **Residual Risks** | What remains uncertain or needs validation |
| **Next Steps** | Concrete actions (files, tests, experiments) |

## Rules

- Reviews MUST be independent before debate (no anchoring)
- You orchestrate and synthesize but your review comes from the Opus call
- Each phase produces a distinct artifact
- Depth over speed - use tokens freely

## Execution Tips

**Run as background tasks:** Launch all three reviewers using `run_in_background: true` in parallel, then use `TaskOutput` to gather results. Don't block waiting for each sequentially.

**Timeouts - trust the process:**
- Claude Opus thinks deeply on complex prompts - this is expected
- Architectural reviews routinely take 5-15+ minutes, let it cook
- Codex explores the codebase thoroughly before answering

**Check before killing:** Use `wc -l` on the output file. 0 lines on a complex prompt usually means still thinking, not stuck. Use non-blocking `TaskOutput` with `block: false` to peek without waiting.
