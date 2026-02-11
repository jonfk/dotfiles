---
name: showboat-rodney-demo-docs
description: Create feature-focused demo documents for technical or non-technical audiences. Use when a user asks for walkthrough docs, showcase narratives, sample demo artifacts, or proof-style documentation that explains how a capability works and what outcomes to expect.
---

# Showboat Rodney Demo Docs

## Overview

Create demo documents that showcase a specific feature by using `uvx showboat` or `uvx rodney`.
Always inspect current CLI usage from tool help first, then generate the requested demo output.

## Tools

IMPORTANT: Do not modify the demo documents directly. Only use the showboat and rodney cli tools to interact with the demo document.

showboat documents and proves agent work; rodney automates web browser behavior.

1. showboat is a demo-document builder.
- It creates Markdown docs that combine notes, executable code blocks, and captured outputs/images.
- It supports proving reproducibility with verify (re-run code blocks and diff outputs).
- Core flow: init → note/exec/image → verify/extract.

2. rodney is a browser automation CLI for Chrome.
- It controls a headless browser for navigation, interaction, scraping, waiting, screenshots, tab management, and accessibility inspection.
- It is effectively a scriptable command-line interface for end-to-end browser actions (open pages, click/type, wait, capture, inspect).

## Mandatory Preflight

- Run `uvx showboat --help` and read it to understand what the tool does and how to use it.
- Run `uvx rodney --help` and read it to understand what the tool does and how to use it.

## Workflow

1. Clarify the demo goal:
- Capture the feature to demonstrate.

2. Report results clearly:
- State which tool was used and why.
- List the command used.
- List output file path(s).
- Summarize what feature behavior the demo document covers.

## Output Standard

Ensure every demo document includes:
- A concise title naming the feature.
- A short "what this demonstrates" section.
- A step-by-step usage or behavior walkthrough.
- Expected outcomes or success criteria.
- Any assumptions, prerequisites, or environment notes.
