---
title: Follow the Conventions on Disk
slug: follow-the-conventions-on-disk
category: context
tags: [universal, conventions]
works_with: all
severity: high
one_liner: "AI writing code in its house style instead of the repo's existing patterns"
---

# Follow the Conventions on Disk

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from importing its own stylistic defaults into a codebase that already has answers to every style question.

**[Copy-paste ready version](../../install/follow-the-conventions-on-disk.md)** — just the instruction block, no explanation.

## The Problem

Every codebase has already decided things: how errors are handled, how modules export, whether it's classes or functions, what gets a named type, how files are named, how logging works. The AI also has decided things — a house style averaged from millions of repos — and when it writes new code without studying the neighbors, the house style wins. The result is a file that's individually fine and contextually wrong: `camelCase` files in a `kebab-case` directory, thrown exceptions in a result-type codebase, a default export where everything else is named, `async/await` in a promise-chain module.

Convention violations aren't cosmetic. Error-handling style is a contract — a function that throws in a codebase that returns errors will have its failures silently uncaught by callers that never expected a throw. Naming and structure conventions are how grep and humans find things; the file that breaks them is the file nobody finds. And every reviewer round-trip spent saying "we don't do it that way here" is the AI exporting its preferences as someone else's cost.

The repo is self-documenting on every one of these questions. Three sibling files answer more style questions than any prompt could enumerate.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Follow the Conventions on Disk

ALWAYS write new code in the style of the code around it, not in your default style. The repo has already answered its style questions; your job is to read the answers, not to re-vote.

Convention breaks aren't cosmetic — error-handling style is a caller contract, and naming patterns are how anyone finds anything.

**Before writing code in any part of a repo:**
- Read 2-3 sibling files (same directory, same layer) and extract their working conventions before writing your first line
- Match specifically: file naming (`kebab-case` vs `camelCase` vs `snake_case`), export style (named vs default), error handling (throw vs result types vs error codes), async style, class vs function orientation, and how logging/metrics are invoked
- Use the project's existing utilities and base classes where siblings do — don't inline what neighbors import from a shared module
- Check for written law too: `CONTRIBUTING.md`, lint configs, and editorconfig encode decisions the code alone might show inconsistently
- When the codebase is internally inconsistent, match the nearest neighbors or the newest code, and say which you chose
- Your style preference is not an upgrade; if you believe a convention is genuinely harmful, flag it separately — don't unilaterally "improve" it in a feature change

**Red flags that you're about to violate this:**
- "I'll write this the clean, modern way..."
- "Default exports are fine, it's a minor thing..."
- "I always structure services like this..."
- "Their error handling is unusual; I'll use normal try/catch..."
- "No time to read sibling files for such a small addition..."
- Writing a new file without having opened any file from its directory

---

## Why It Works

1. **It reframes style as contract.** "Error-handling style is a caller contract" turns the strongest violation — throw vs result-type — from a taste question into a correctness question, which is the register the AI actually respects.

2. **It prescribes the sample size.** "Read 2-3 siblings" converts the vague "follow conventions" into a concrete pre-write step with a defined cost, removing the "too small a change to bother" exit.

3. **It de-authorizes the upgrade instinct.** AIs break conventions believing they're improving things. Separating "flag the harmful convention" from "follow it meanwhile" honors the instinct without letting it corrupt the diff.

4. **It handles the inconsistent-repo case.** Real codebases drift; "nearest neighbors or newest code, and say which" gives a deterministic rule where "follow conventions" alone would deadlock.

## Origin

A service handled every failure with result objects — no exceptions anywhere, callers checked `.ok` religiously. An AI added a new repository function in its own style: it threw. Callers, written to the repo's convention, never wrapped it in try/catch, so the first malformed record took down the worker process instead of being logged and skipped like every other failure for three years. The fix was one line. Finding why a "fully conventional-looking" function was the only thing in the service that could crash it took a day.
