---
name: github-pr-description
description: Draft clear, concise GitHub pull request descriptions from diffs or a change summary. Use when asked to write, rewrite, tighten, or summarize a PR description, especially when the output should follow Overview, Changes, Notes, and optional How to review sections.
---

# GitHub PR Description

## Overview

Draft PR descriptions that stay short, factual, and easy to scan.

## Workflow

1. Inspect the diff, changed files, and any user context.
2. Write this structure:

```md
## Overview
- 1-3 bullets. What changed and why.

### Changes
- Main changes.
- High level implementation detail.
- No deep implementation detail.

## Notes
- Tradeoffs, constraints, risks, or follow-ups.

## How to review
1. file/path: what to look for
2. tests/commands: how to validate
```

3. Omit `Notes` if there is nothing useful to say.
4. Omit `How to review` unless review order or validation steps would help.

## Style

- Be extremely concise. Prefer bullets and sentence fragments.
- Avoid fluff, marketing, and phrases like `this PR aims to`.
- Use simple English. Keep one idea per bullet.
- State intent and impact, not step-by-step implementation.
