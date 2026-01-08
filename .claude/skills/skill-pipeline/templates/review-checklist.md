# Skill Review Checklist (Phase 5)

Use this checklist before deploying a skill to production.

## Skill Information

**Skill Name:** [skill-name]
**Version:** [1.0]
**Author:** [name]
**Review Date:** [YYYY-MM-DD]
**Reviewer:** [name]

---

## Pre-Review Requirements

- [ ] All evaluation tests passing (success rate: ___%)
- [ ] Baseline comparison shows improvement
- [ ] No regression from previous version (if applicable)
- [ ] Failure analysis complete for any failures

---

## 1. Frontmatter Validation

### Required Fields
- [ ] `name` is hyphen-case, max 64 chars
- [ ] `description` is clear, no angle brackets, max 1024 chars
- [ ] Description uses third-person ("Helps users..." not "Help users...")

### Optional Fields (if present)
- [ ] `allowed-tools` list is appropriate for skill
- [ ] `license` is valid SPDX identifier
- [ ] `metadata` contains only valid fields

---

## 2. Content Quality

### Structure
- [ ] Clear section organization
- [ ] Table of Contents present (if > 100 lines)
- [ ] Headings follow logical hierarchy
- [ ] No orphaned sections

### Writing Style
- [ ] Uses imperative form ("Do X" not "You should do X")
- [ ] Concise - no unnecessary words
- [ ] No redundant explanations
- [ ] Technical terms explained on first use

### Instructions
- [ ] Clear, actionable instructions
- [ ] No ambiguous directions
- [ ] Edge cases addressed
- [ ] Error handling guidance included

---

## 3. Token Budget

| Metric | Value | Limit | Status |
|--------|-------|-------|--------|
| SKILL.md lines | | 500 | |
| Reference lines | | 300 each | |
| Total lines | | 1000 | |

- [ ] Within token budget for target model
- [ ] No unnecessary content
- [ ] Progressive disclosure used appropriately

---

## 4. References (if any)

### Organization
- [ ] Max 1 level of nesting
- [ ] Clear file naming
- [ ] No circular references

### Content
- [ ] Each reference serves clear purpose
- [ ] No duplicate content across references
- [ ] References are appropriately sized
- [ ] Long references have TOC

---

## 5. Scripts (if any)

### Code Quality
- [ ] Proper shebang (`#!/usr/bin/env python3`)
- [ ] Clear docstrings and usage
- [ ] Error handling implemented
- [ ] No hardcoded paths

### Security
- [ ] No secrets or credentials
- [ ] Input validation present
- [ ] Safe file operations
- [ ] No command injection risks

---

## 6. Evaluations

### Test Coverage
- [ ] Core functionality covered
- [ ] Edge cases covered
- [ ] Regression tests for known issues
- [ ] At least 3-5 test cases

### Test Quality
- [ ] Clear success criteria
- [ ] Realistic queries
- [ ] Appropriate difficulty distribution

### Results
| Model | Tests | Passed | Rate |
|-------|-------|--------|------|
| Haiku | | | |
| Sonnet | | | |
| Opus | | | |

---

## 7. Documentation

- [ ] README or usage instructions present
- [ ] Examples included
- [ ] Known limitations documented
- [ ] Version history maintained (if applicable)

---

## 8. Compatibility

- [ ] Works with target Claude model(s)
- [ ] No deprecated features used
- [ ] Compatible with current Claude Code version

---

## Review Decision

### Status: [ ] APPROVED / [ ] NEEDS CHANGES / [ ] REJECTED

### If Needs Changes:
| Item | Required Change | Priority |
|------|-----------------|----------|
| | | |
| | | |

### If Rejected:
**Reason:** [explanation]

---

## Sign-off

**Reviewer:** _________________ **Date:** _________

**Author Acknowledgment:** _________________ **Date:** _________

---

## Post-Deployment Checklist

- [ ] Skill packaged with `package_skill.py`
- [ ] Package validated
- [ ] Deployed to target location
- [ ] Smoke test in production environment
- [ ] Monitoring configured (if applicable)
- [ ] Team notified of deployment
