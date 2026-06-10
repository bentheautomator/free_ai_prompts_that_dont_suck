---
title: Match the Existing Error Handling Style
slug: match-existing-error-handling-style
category: code-quality
tags: [universal, errors, patterns]
works_with: all
severity: high
one_liner: "AI bolting its favorite error paradigm onto a codebase that uses another"
---

# Match the Existing Error Handling Style

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from introducing a second error-handling paradigm into a codebase that already committed to one.

**[Copy-paste ready version](../../install/match-existing-error-handling-style.md)** — just the instruction block, no explanation.

## The Problem

Your codebase returns `Result<T, E>` from every fallible function. The AI, asked to add one more, throws an exception — because try/throw/catch is the statistically dominant pattern in its training data and it reaches for the default unless something stops it. Or the inverse: your Express app has a centralized error middleware, and the AI wraps its new route in a bespoke try/catch that formats its own error response, bypassing the one place errors were supposed to flow through.

A codebase with two error paradigms is worse than a codebase with either one alone. Callers written for Result types don't have catch blocks, so the AI's thrown exception sails past every caller straight to a crash. Error-shape consistency breaks: clients now receive two different JSON error formats depending on which handler failed. Retry logic, logging, and metrics that hook the canonical path miss everything on the rogue path entirely.

The paradigm choice was an architectural decision someone made on purpose. The AI overrides it casually, one function at a time, until "how do errors work here" has no single true answer.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Match the Existing Error Handling Style

NEVER introduce an error-handling paradigm the codebase doesn't already use. Before writing any fallible code, find out how this codebase signals failure — then signal failure exactly that way.

Your default (usually throw/try/catch) is a statistical habit, not a decision. The codebase's pattern *was* a decision, and code that breaks it doesn't merely look different — it escapes the error flow: callers expecting Results won't catch your exception, and centralized handlers never see your hand-rolled response.

**Before writing code that can fail:**
- Read 2-3 existing functions that handle similar failures and identify the pattern: exceptions, Result/Either types, error codes, `(value, err)` tuples, callbacks, sentinel values, centralized middleware
- Use that pattern, including its details: the project's custom error classes (not bare `Error`/`Exception`), its error message conventions, its wrapping idiom (`fmt.Errorf("...: %w", err)`, `raise ... from e`)
- Route errors through existing central machinery (error middleware, global handlers, error boundaries) instead of formatting your own responses inline
- Never silently convert between paradigms at a boundary — a Result-returning function that internally swallows exceptions it should propagate, or vice versa — unless the codebase has an established adapter for exactly that
- If the codebase genuinely has no discernible pattern, use the language's idiomatic default and say which one you chose

**Red flags that you're about to violate this:**
- "I'll wrap this in a try/catch to be safe..." (in a Result-type codebase)
- "Throwing is more idiomatic than what they're doing..."
- "I'll just return null on failure here, simpler..."
- "I'll format the error response right in this handler..."
- "A plain Error is fine, no need for their custom classes..."
- Writing a fallible function without having looked at how its siblings fail

---

## Why It Works

1. **It demotes the AI's default from "idiomatic" to "habit."** The model believes try/catch is the correct way because it's the frequent way. Reframing frequency as bias removes the authority the default carries.

2. **It explains the mechanical breakage, not just the aesthetic one.** "Inconsistent" sounds ignorable; "callers won't catch your exception" does not. Connecting the style mismatch to escaped errors makes the rule load-bearing.

3. **It includes the machinery, not just the syntax.** Custom error classes, wrapping idioms, and central handlers are where half the violations happen even when the AI gets the broad paradigm right. Listing them closes the gap between "matched the pattern" and "actually matched the pattern."

4. **It defines a fallback.** "No pattern exists" is real in young codebases; giving the AI a sanctioned move (idiomatic default, declared openly) prevents it from inventing a paradigm silently.

## Origin

A Go service wrapped every error with context strings using `%w` and matched on them upstream with `errors.Is`. An AI-written storage function returned a freshly constructed error instead of wrapping the underlying one. The retry layer, which checked for a wrapped timeout error, never matched, so transient database timeouts were treated as permanent failures and dropped jobs on the floor. Three engineers debugged the retry layer for two days before anyone thought to check whether the error chain was intact.
