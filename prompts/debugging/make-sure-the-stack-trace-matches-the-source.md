---
title: Make Sure the Stack Trace Matches the Source
slug: make-sure-the-stack-trace-matches-the-source
category: debugging
tags: [universal, debugging, errors]
works_with: all
severity: high
one_liner: "AI debugging line numbers from a stale build against current source"
---

# Make Sure the Stack Trace Matches the Source

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from mapping a stack trace onto source code the running build wasn't actually compiled from.

**[Copy-paste ready version](../../install/make-sure-the-stack-trace-matches-the-source.md)** — just the instruction block, no explanation.

## The Problem

The trace says the crash is at `orders.py:147`, so the AI opens `orders.py`, reads line 147 — a harmless logging call — and starts constructing elaborate theories about how a log statement could throw a `KeyError`. It can't. The trace came from the version deployed last Thursday; the file in the working tree has forty new lines above 147. The AI is debugging a fictional program assembled from one version's line numbers and another version's text.

Version skew between trace and source is everywhere: stale Docker images, an old release in production while you read `main`, transpiled JavaScript without source maps, a dev server that didn't hot-reload, a cached `.pyc`, the error report a user filed three versions ago. Humans get burned by this early and develop a reflex — "wait, is this even the code that ran?" — that AI assistants entirely lack. The assistant takes file-plus-line as ground truth because checking deployment provenance is outside the text it was handed.

The failure mode is distinctive and expensive: theories that have to be contorted to explain how innocent-looking code threw the error, fixes applied to lines that were never involved, and in the worst case "the fix didn't work" loops where the fix was never in the running build to begin with.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Make Sure the Stack Trace Matches the Source

ALWAYS verify that a stack trace was produced by the exact code you're reading before debugging from its file and line numbers. A trace from one version mapped onto another version's source describes a program that doesn't exist.

If the line the trace points at couldn't plausibly throw that error, your first suspect is version skew, not exotic behavior.

- Establish provenance first: what build/commit/deployment produced this trace, and does it match your working tree? Check version endpoints, image tags, deploy logs, or the commit SHA in the error report
- Sanity-check the mapping: does the code at the named line match the error? A `KeyError` blamed on a log statement, or a function name in the trace that doesn't exist at that line, means the trace and source have diverged
- For transpiled/minified code, confirm source maps are present and applied; line numbers from bundled output mapped onto source files are meaningless
- After making a fix, confirm the next run actually contains it: rebuild, redeploy, bust the cache, verify the version marker changed — "the fix didn't work" frequently means "the fix never ran"
- Old error reports need old code: check out the commit that was running when the trace was captured, and debug there
- When in doubt, force a fresh failure from a build you control, and use that trace instead

**Red flags that you're about to violate this:**
- "Line 147 is just a log call, but maybe under certain conditions..."
- "The trace mentions a function I can't find — must have been inlined..."
- "My fix didn't change anything, the bug must be deeper..." (is the fix even deployed?)
- "This error report from last month should map onto current main..."
- Constructing a complicated theory to explain how innocuous code threw the error
- Never once asking which commit the failing process was built from

---

## Why It Works

1. **It installs the missing reflex.** "Could this line even throw this error?" is the human-acquired sanity check assistants skip; making mismatch the *default* explanation for innocent-looking crash sites catches skew at first contact.

2. **It attacks both directions of the skew.** Stale trace against new source, and new fix against stale build — the second causes the demoralizing "fix didn't work" spiral, and the instruction names rebuild-verification as its cure.

3. **It treats provenance as step zero.** Asking "which commit produced this?" before any code reading costs one command and invalidates entire categories of wasted theorizing.

4. **It handles the transpilation case explicitly.** Bundled-output line numbers are the most common silent skew in web stacks, and the AI will otherwise happily read `main.js:1:48211` as if it meant something about `src/`.

## Origin

An assistant spent two hours on a production `TypeError` whose trace pointed at a line that, in the repo, was a comment. It produced three escalating theories involving monkey-patching and import-order corruption, plus two fixes that "didn't work." The production pod was running an image built nine days earlier, from a branch that had since been rebased. Pulling the actual deployed commit made the trace line up perfectly with an obvious one-line bug — which had, in fact, already been fixed on main the day before.
