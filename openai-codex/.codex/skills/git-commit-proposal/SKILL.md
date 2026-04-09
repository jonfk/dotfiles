---
name: git-commit-proposal
description: Propose a commit as structured JSON without modifying git state. Use when a wrapper script wants Codex to inspect diffs and return a schema-validated commit plan for preview, optional editing, staging, and commit execution outside Codex.
---

# Git Commit Proposal

Return a structured commit proposal grounded in the actual repository state. Do not mutate git state.

## Rules
- Never run `git add`, `git commit`, `git reset`, or any other mutating git command.
- Inspect actual diffs before proposing a commit.
- Return only content that fits the provided output schema.
- Prefer the smallest coherent commit.
- Use the user's prompt to improve wording, but do not claim changes that are not present in the diff.

## Workflow
1. Inspect repository context.
- Run `git status --short`.
- Run `git log -n 10 --pretty=format:'%h %ad %s' --date=short`.
- Check staged files first with `git diff --staged --name-only`.

2. If there are staged changes:
- Treat the staged set as the only candidate commit for this proposal.
- Inspect `git diff --staged`.
- If the staged set is coherent, return `status="ready"` and set `stage_paths` to exactly the staged file list.
- If the staged set mixes concerns, return `status="split_required"` and explain the split options without proposing new staging changes.

3. If nothing is staged:
- Inspect the unstaged diff with `git diff`.
- If there is one unambiguous commit, return `status="ready"` with the repo-relative files for that commit in `stage_paths`.
- If changes should be split, return `status="split_required"` with concise alternative commit suggestions.
- If there is no meaningful change to commit, return `status="nothing_to_commit"`.

## Output requirements
- `summary` should explain why the proposal is ready or why it stopped.
- Always include `stage_paths`, `commit`, and `alternatives` so the response matches the schema.
- When `status="ready"`, `commit.subject` must be a Conventional Commit style subject and `commit.body_paragraphs` should contain only meaningful paragraphs. Use an empty array when no body is needed.
- When `status` is not `ready`, set `commit` to `null`.
- When there is no single ready proposal, use `stage_paths: []`.
- When `status="split_required"`, populate `alternatives`. Otherwise use `alternatives: []`.
