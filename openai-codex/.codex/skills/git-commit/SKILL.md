---
name: git-commit
description: Create Git commits using conventions of the repo and Conventional Commits. Use when asked to create a git commit. Analyze repository context by checking the last 10 commits and reviewing diffs before writing messages, and use the user's prompt as intent for commit wording when it matches the actual changes.
---

# Git Commit

Create Conventional Commit messages grounded in actual code changes.

## Workflow
When creating git commits, if there is only 1 unambiguous commit to create. No need to plan or approval of the plan. Assume pre-approval and commit.

1. Inspect repository context.
- Run `git status --short`.
- Run `git log -n 10 --pretty=format:'%h %ad %s' --date=short` to infer style and scope patterns.
- Read any relevant files when needed to understand intent.

2. Capture user intent from the prompt if provided.
- Extract explicit intent from the user request (feature/fix target, subsystem, motivation, desired scope).
- Use this intent to shape commit wording.
- Do not let prompt intent override what the diff actually changes.

3. Prioritize staged changes first.
- Run `git diff --staged --name-only`.
- If staged files exist:
  - Run `git diff --staged` and understand the behavioral impact.
  - Choose a Conventional Commit type and optional scope from the actual changes, informed by prompt intent.
  - Write the commit subject and optional body using prompt context when accurate.
  - Commit staged changes with `git commit -m "<subject>"` (add additional `-m` flags for body paragraphs when needed).
  - Do not use `\n` escape sequences inside `-m` strings. They will be committed literally.
  - For multiline messages, prefer one `-m` per paragraph. Example: `git commit -m "feat(scope): subject" -m "Body paragraph 1." -m "Body paragraph 2."`
  - If the body is long or needs exact formatting, use stdin with a heredoc so literal newlines are preserved:
    `git commit -F- <<'EOF'
    feat(scope): subject

    Body paragraph 1.
    Body paragraph 2.
    EOF`
  - Avoid including unstaged changes in this commit.
  - You can proceed to commit these staged changes without approval.

4. If no files are staged, propose staging and commit plan.
- Use `git status` and `git diff` to figure out what are the changes.
- Inspect per-file diffs with `git diff -- <file>`, if necessary.
- Propose a focused set of files to stage and a Commit for that set that is aligned to prompt intent and actual diffs.
- If there is only 1 set of files and they make sense to commit together, stage them and create the commit without requiring approval.
- If there are multiple options, or the sets are ambiguous, state the options but don't stage or commit.

## Quality Bar

- Base messages on inspected diffs, not file names alone.
- Use the user prompt to improve specificity and intent, but do not claim changes not present in diffs.
- Prefer the smallest coherent commit.
- If changes mix concerns, propose split commits.
- If there is no meaningful change, state that clearly and do not force a commit.
