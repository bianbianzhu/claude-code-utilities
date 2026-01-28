### Architect Review Loop - Collaborative design review between Claude Code and Codex

A bash script that orchestrates iterative design document reviews between two AI architects:
- **Review Architect** (Codex / GPT-5.2): Reviews and identifies blockers
- **Working Architect** (Claude Code / Opus 4.5): Addresses issues interactively with user

```mermaid
flowchart TD
    Start([Start]) --> Args{Valid args?}
    Args -->|No| Usage[Show usage & exit]
    Args -->|Yes| Setup[Setup logs directory]
    Setup --> Loop{iteration <= max?}

    Loop -->|Yes| Phase1[Phase 1: Codex Review]
    Phase1 --> ReviewLog[Write review-log-iteration-N.md]
    ReviewLog --> CheckIssues{NO_MORE_ISSUES?}

    CheckIssues -->|Yes| Success([Success: Design Ready])
    CheckIssues -->|No| Phase2[Phase 2: Claude Code]

    Phase2 --> Interactive[Interactive session with user]
    Interactive --> UpdateDoc[Update design document]
    UpdateDoc --> WorkLog[Write work-log-iteration-N.md]
    WorkLog --> Increment[iteration++]
    Increment --> Loop

    Loop -->|No| MaxReached([Max iterations reached])

    style Start fill:#000,stroke:#fff,color:#fff
    style Args fill:#333,stroke:#fff,color:#fff
    style Usage fill:#666,stroke:#fff,color:#fff
    style Setup fill:#333,stroke:#fff,color:#fff
    style Loop fill:#333,stroke:#fff,color:#fff
    style Phase1 fill:#7b1fa2,stroke:#fff,color:#fff
    style ReviewLog fill:#7b1fa2,stroke:#fff,color:#fff
    style CheckIssues fill:#333,stroke:#fff,color:#fff
    style Phase2 fill:#1565c0,stroke:#fff,color:#fff
    style Interactive fill:#1565c0,stroke:#fff,color:#fff
    style UpdateDoc fill:#1565c0,stroke:#fff,color:#fff
    style WorkLog fill:#1565c0,stroke:#fff,color:#fff
    style Increment fill:#333,stroke:#fff,color:#fff
    style Success fill:#2e7d32,stroke:#fff,color:#fff
    style MaxReached fill:#f57c00,stroke:#000,color:#000
```

#### Usage

```bash
./architect-review-loop.sh <max_iterations> <design_doc_path>
```

#### Arguments

| Argument | Description |
|----------|-------------|
| `max_iterations` | Maximum number of review iterations (positive integer) |
| `design_doc_path` | Path to the design document to review (relative or absolute) |

#### Example

```bash
./architect-review-loop.sh 5 docs/plans/orchestrator-design.md
```

#### Output Structure

```
logs/architect-review-YYYYMMDD-HHMMSS/
├── review-log-iteration-1.md   # Codex review findings
├── work-log-iteration-1.md     # Claude Code changes made
├── review-log-iteration-2.md
├── work-log-iteration-2.md
└── ...
```

#### Exit Conditions

1. **Success**: Codex outputs `NO_MORE_ISSUES` - design is ready for implementation
2. **Max iterations**: Loop limit reached - may need manual continuation

#### Phase Details

**Phase 1 - Review Architect (Codex)**
- Reviews design document for Critical/High blockers
- Tracks issue resolution across iterations
- Limits: max 5 blockers, max 2 new issues after first iteration
- Outputs structured review log with acceptance criteria

**Phase 2 - Working Architect (Claude Code)**
- Reads review feedback
- Addresses issues one-by-one with user approval
- Updates design document directly
- Creates work log summarizing changes
