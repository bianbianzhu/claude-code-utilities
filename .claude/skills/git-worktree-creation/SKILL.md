---
name: git-worktree-creation
description: Create isolated git worktrees for parallel development. Use when user wants to work on a feature in isolation, start a new branch with a clean workspace, or needs multiple branches checked out simultaneously.
---

# Git Worktree Creation

Create an isolated git worktree for parallel development work.

## State Management

This skill uses a JSON state file (`.claude/.worktree-state.json`) to persist variables between steps. Each script reads from and writes to this file.

## Workflow

Execute phases sequentially. Each script outputs JSON - parse the `status` and `next_action` fields to determine how to proceed.

### Phase 1: Verify Git Repository

Run `scripts/01_verify_git.sh`

**Possible outcomes:**

- `status: "success"` → Continue to Phase 2
- `status: "error"` → Stop and inform user they must be in a git repository

### Phase 2: Determine Worktree Location

Run `scripts/02_determine_location.sh`

**Possible outcomes:**

- `status: "success"` → Location found, continue to Phase 3
- `status: "needs_input"` → Ask user to choose location

**If user input needed**, ask which directory to use:

- `.worktrees/` - Hidden directory (recommended for clean file browsers)
- `worktrees/` - Visible directory
- `~/.worktrees/` - Global directory (shared across projects)

After user chooses, run `scripts/02b_set_location.sh <chosen_location>`

### Phase 3: Verify .gitignore

Run `scripts/03_verify_gitignore.sh`

This step is automatic:

- For project-local directories: Ensures directory is in `.gitignore`
- For global directories: Skips (no gitignore needed)

Continue to Phase 4 regardless of outcome.

### Phase 4: Get and Validate Branch Name

**Ask user** for the branch name they want to create/use.

Then run `scripts/04_validate_branch.sh <branch_name>`

**Possible outcomes:**

- `status: "success"` → Branch valid and new, continue to Phase 5
- `status: "needs_confirmation"` → Branch exists, ask user if they want to use it
  - If yes → Continue to Phase 5
  - If no → Ask for different branch name
- `status: "error"` → Invalid name or branch in use, ask for different name

### Phase 5: Create Worktree

Run `scripts/05_create_worktree.sh`

**Outputs:**

- `worktree_path` - Relative path to the worktree
- `absolute_path` - Full path for opening in editor
- `setup_completed` - Whether project dependencies were installed
- `setup_commands` - What setup commands ran

### Completion

After successful creation, inform user:

1. **Worktree path** - Where the worktree was created
2. **How to use it**:
   - `cd <path>` to enter the worktree
   - Open `<absolute_path>` in a new editor window
3. **Cleanup** - When done: `git worktree remove <path>`

Optionally clean up the state file: `rm .claude/.worktree-state.json`

## Quick Reference

| Script                     | Purpose              | User Interaction   |
| -------------------------- | -------------------- | ------------------ |
| `01_verify_git.sh`         | Verify git repo      | None               |
| `02_determine_location.sh` | Find/detect location | Maybe ask choice   |
| `02b_set_location.sh`      | Set user's choice    | After user chooses |
| `03_verify_gitignore.sh`   | Update .gitignore    | None               |
| `04_validate_branch.sh`    | Validate branch      | Ask branch name    |
| `05_create_worktree.sh`    | Create worktree      | None               |

## Error Recovery

If any step fails:

1. Read `.claude/.worktree-state.json` to see current state
2. The `step` field shows which phase completed last
3. Fix the issue and re-run from the failed step

## Example Interaction

```
User: I want to work on a login feature in isolation

Claude: I'll create a git worktree for you. Let me verify we're in a git repo.
[Runs 01_verify_git.sh]

Claude: We're in the my-project repository. Let me check for existing worktree directories.
[Runs 02_determine_location.sh]

Claude: No existing worktree directory found. Where would you like to store worktrees?
[AskUserQuestion with 3 options]

User: .worktrees/

Claude: Got it, using hidden .worktrees directory.
[Runs 02b_set_location.sh ".worktrees"]
[Runs 03_verify_gitignore.sh]

Claude: I've added .worktrees/ to .gitignore. What branch name do you want for this feature?
[AskUserQuestion]

User: feature/login

Claude: Let me validate that branch name.
[Runs 04_validate_branch.sh "feature/login"]

Claude: Branch name is valid. Creating the worktree now.
[Runs 05_create_worktree.sh]

Claude: Worktree created at .worktrees/feature/login
- Ran npm ci to install dependencies
- Open /Users/you/my-project/.worktrees/feature/login in a new editor window
- When done: git worktree remove .worktrees/feature/login
```
