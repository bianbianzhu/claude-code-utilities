---
name: brainstorming
description: "Use this before any creative work - designing a new system, creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

## The Process

**Understanding the idea:**
- Check out the current project state first (files, docs, recent commits; skip if none exist)
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria
- Once you can restate the problem, constraints, and success criteria clearly, move to exploring approaches

**Exploring approaches:**
- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why
- If user rejects all options: ask what specifically fails, update constraints, propose new approaches. If still blocked, return to Understanding to uncover missing constraints

**Alignment checkpoint:**
- Before writing the design, restate the problem, constraints, and success criteria
- Ask "Ready for the design?" to confirm alignment

**Presenting the design:**
- If the scope covers more than one major feature, break it into separate design files. Maintain a `specs/README.md` file that lists all design files and their purpose (as a table of references)
- Break the design document into sections of 200-300 words
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing, security/privacy, performance, observability
- Be ready to go back and clarify if something doesn't make sense

## After the Design

**Documentation:**
- Write the validated design to `specs/YYYY-MM-DD-<topic>-design.md`
- If the design document is part of a larger design, add a link to the `specs/README.md` file

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense