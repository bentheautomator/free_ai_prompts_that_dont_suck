---
title: No Hallucinated Library Methods
slug: no-hallucinated-library-methods
category: code-quality
tags: [universal, apis]
works_with: all
severity: high
one_liner: "AI calling library methods that don't exist but sound like they should"
---

# No Hallucinated Library Methods

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from calling library methods that sound plausible but don't actually exist.

**[Copy-paste ready version](../../install/no-hallucinated-library-methods.md)** — just the instruction block, no explanation.

## The Problem

`lodash.flattenDeep()` exists. `lodash.flattenAll()` does not. `axios.get()` exists. `axios.fetchJson()` does not. AI assistants generate method calls by pattern-matching against what a library's API *should* look like, and library authors don't always agree with the model's sense of aesthetics. The result is code that reads perfectly, passes a skim review, and explodes at runtime with `TypeError: x.fetchJson is not a function` — or worse, fails silently in a dynamic language where the attribute lookup gets swallowed somewhere.

This happens because models are trained on millions of API calls across thousands of libraries, and the boundaries blur. A method that exists in `requests` gets attributed to `httpx`. A pandas method gets hallucinated onto polars. The model's confidence is identical whether the method is real or invented, because to the model, both are just statistically likely token sequences.

The cost compounds when the hallucinated call is buried in a rarely-executed branch. The happy path works, the PR merges, and three weeks later an error handler crashes because the recovery code calls a method that never existed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Hallucinated Library Methods

NEVER call a library method you haven't verified exists. Plausible is not the same as real.

You generate API calls by pattern-matching against what a library's interface "should" look like. Library authors did not consult your training data. Methods get blended across similar libraries (`requests` vs `httpx`, `lodash` vs `ramda`, `pandas` vs `polars`), and the resulting call reads perfectly while being completely fictional.

**Before calling any library method, verify it one of these ways:**
- Find an existing call to the same method elsewhere in this codebase
- Check the library's source or type definitions in `node_modules/`, `site-packages/`, `vendor/`, or wherever dependencies live
- Check official documentation for the exact method name and signature
- Run a quick REPL check or `grep` against the installed package

**Specific rules:**
- If you can't verify a method exists, say so and verify before writing the call
- Prefer methods the codebase already uses over methods you "remember"
- Pay extra attention to utility libraries and ORMs — these have the highest hallucination rates because so many near-identical variants exist
- Hallucinated methods in error handlers and rare branches are the most dangerous, because the happy path hides them — verify those calls hardest

**Red flags that you're about to violate this:**
- "This library almost certainly has a method for this..."
- "The conventional name for this would be..."
- "I remember this API from similar libraries..."
- "It follows the same pattern as the other methods, so..."
- "This is such a common operation, there must be a built-in..."
- Writing a method call you've never seen in this codebase or its docs

---

## Why It Works

1. **It names the confidence trap.** The model's certainty feels identical for real and invented methods. Stating that explicitly forces a verification step exactly where overconfidence is highest.

2. **It gives concrete verification paths.** "Be careful" doesn't work; "grep the codebase, check node_modules, check the docs" gives the AI an actionable checklist it can execute in seconds.

3. **It targets the blast radius.** Calling out error handlers and rare branches focuses scrutiny where hallucinations survive longest, instead of spreading attention evenly.

4. **The red flags catch the blend.** "I remember this from similar libraries" is the literal mechanism of the failure — cross-library contamination — named before it fires.

## Origin

A developer asked for retry logic around an HTTP client. The AI wrapped the calls in a clean retry helper that invoked `client.cloneRequest()` — a method that existed in a different HTTP library entirely. The happy path never retried, so nothing failed in review or staging. The first production timeout three weeks later crashed the retry handler itself, turning a transient network blip into a hard outage.
