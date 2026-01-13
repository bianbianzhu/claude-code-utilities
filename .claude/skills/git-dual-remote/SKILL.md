---
name: git-dual-remote
description: Configure a local git repository to push to two remote repositories simultaneously. Use when setting up a repo that needs to sync to both personal GitHub and company/organization GitHub, or any scenario requiring the same code to be pushed to multiple remotes at once.
allowed-tools: Bash(git remote -v)
---

# Git Dual Remote

Configure a local repo to manage two remote repositories, enabling simultaneous push to both with a single command.

## Setup

Run the setup script to configure dual remotes:

Run `scripts/setup_dual_remote.sh <mirror_url>`

Example: `scripts/setup_dual_remote.sh git@github.com:company/repo.git`

This creates three remotes:

- `origin` - Primary repo (existing)
- `mirror` - Secondary repo
- `all` - Push to both repos simultaneously

After setup, run `git remote -v` to verify the configuration.

Expected `git remote -v` output:

```
origin    git@github.com:you/repo.git (fetch)
origin    git@github.com:you/repo.git (push)
mirror    git@github.com:company/repo.git (fetch)
mirror    git@github.com:company/repo.git (push)
all       git@github.com:you/repo.git (fetch)
all       git@github.com:you/repo.git (push)
all       git@github.com:company/repo.git (push)
```

Note: The `all` remote has one fetch URL but two push URLs.
