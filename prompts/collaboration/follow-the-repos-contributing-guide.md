---
title: Follow the Repo's Contributing Guide
slug: follow-the-repos-contributing-guide
category: collaboration
tags: [universal, teamwork, process]
works_with: all
severity: medium
one_liner: "Stops changes that ignore CONTRIBUTING.md and burn maintainer review time"
---

# Follow the Repo's Contributing Guide

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from producing changes that ignore the repo's documented contribution rules, forcing maintainers to reject or rework them.

**[Copy-paste ready version](../../install/follow-the-repos-contributing-guide.md)** — just the instruction block, no explanation.

## The Problem

Most shared repos have a `CONTRIBUTING.md` (or `DEVELOPMENT.md`, or a "Contributing" section in the README) that encodes hard-won rules: how to format commits, which directories need a changelog entry, which test suite must pass, whether new code needs a design doc first. The AI skips straight to the code. It produces a technically fine change that violates three documented requirements, and a maintainer — the scarcest resource in any shared codebase — has to spend their time explaining rules that were written down precisely so nobody would have to explain them.

The AI does this because its objective is "make the change work," and the contributing guide isn't in its way. The code compiles without it. Tests pass without it. The cost of skipping it lands entirely on the humans downstream: the reviewer who bounces the change, the contributor who has to redo it, the maintainer whose guide is now apparently optional.

In team repos the damage is quieter but real. The guide says "add a changelog entry under `unreleased/`" and the release notes silently miss a change. It says "schema changes need a migration note" and the on-call engineer deploys blind. Every skipped rule is a small tax on someone who isn't in the conversation.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Follow the Repo's Contributing Guide

ALWAYS look for and follow the repo's contribution rules before making changes. If a `CONTRIBUTING.md` exists, it outranks your defaults and your preferences.

The rules in that file exist because someone got burned without them. Skipping them shifts work onto maintainers and reviewers who never agreed to do it.

- Before your first change in a repo, check for `CONTRIBUTING.md`, `DEVELOPMENT.md`, `docs/contributing/`, and contribution sections in the README. Read what you find.
- Follow the documented requirements exactly: commit message format, changelog entries, required tests, lint commands, sign-offs, issue references, directory layout for new code.
- If the guide requires a step you cannot perform (e.g., filing an issue first, getting a design review), say so explicitly instead of silently skipping it.
- If the guide conflicts with what the user asked for, surface the conflict — do not quietly pick a side.
- Do not treat the guide as advisory because it is old or because existing code violates it. Flag the inconsistency; don't use it as permission.
- When you've followed nonobvious rules (changelog entry added, specific test suite run), mention it so the human knows the requirements are covered.

**Red flags that you're about to violate this:**
- "I'll just write the code; the process stuff is the human's problem."
- "The contributing guide is probably outdated anyway."
- "This change is too small for a changelog entry."
- "I'll match the commit style I usually use instead of theirs."
- "Other recent commits skipped this rule, so I can too."

---

## Why It Works

1. **It moves the guide from invisible to mandatory** — the AI's default search path never includes process docs, and an explicit check-first step puts them in the loop before code is written.
2. **It prices in the downstream cost** — the rules encode maintainer time, and following them is the difference between a change that merges and a change that generates a review thread.
3. **It closes the "existing violations as precedent" loophole**, which is the most common rationalization for ignoring written rules in aging repos.
4. **It forces conflicts into the open** — when the task and the guide disagree, a human decides, instead of the AI silently choosing the path of least resistance.

## Origin

A team's contributing guide required every user-facing change to add a fragment file for the release-notes generator. An assistant shipped four PRs over two weeks, none with fragments, all merged by reviewers who assumed the tooling would catch it. The next release went out with notes missing every one of those changes, and support spent two days fielding "undocumented behavior change" tickets for features that were, in fact, documented nowhere.
