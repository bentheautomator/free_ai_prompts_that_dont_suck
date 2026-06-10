---
title: Raise Specific Error Types, Not Generic
slug: raise-specific-error-types-not-generic
category: error-handling
tags: [universal, errors, exceptions]
works_with: all
severity: medium
one_liner: "AI raising bare Exception('msg') so callers can't catch anything selectively"
---

# Raise Specific Error Types, Not Generic

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents new code from raising only base-class errors that no caller can selectively catch.

**[Copy-paste ready version](../../install/raise-specific-error-types-not-generic.md)** — just the instruction block, no explanation.

## The Problem

`raise Exception("user not found")`. `throw new Error("rate limit exceeded")`. Every failure in the module, raised as the language's base error class, differentiated only by prose. Now look at it from the caller's side: they want to handle not-found by returning a 404 and rate-limit by backing off. Their options are `except Exception` — which also catches every bug in the module — or matching on message strings, which break the day someone improves the wording. The raiser had perfect knowledge of which failure was happening and encoded none of it in the one channel built for the purpose: the type.

This is the producer-side twin of error stringification. AI assistants raising new errors default to the base class because it needs no import and no class definition — `raise Exception(...)` works everywhere, while `raise UserNotFoundError(...)` requires either finding the project's existing exception or defining one, both of which take a lookup the model skips under momentum. The cost lands later and elsewhere: every consumer of the module inherits an API whose failures are catchable only in bulk.

It also poisons broad-catch hygiene. When a codebase's own errors are all `Exception`, callers are *forced* into `except Exception`, and the discipline of narrow catching becomes structurally impossible.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Raise Specific Error Types, Not Generic

When raising an error, raise a type a caller could catch selectively. NEVER raise the base class — `Exception`, `Error`, `RuntimeError` with prose — for a failure that has a name.

The type is the API of the failure. Prose is for humans; the class is what code branches on.

- First, reuse: check whether the project defines domain exceptions (`NotFoundError`, `ValidationError`) or whether a built-in fits exactly (`ValueError` for bad arguments, `KeyError`, `TimeoutError`, `FileNotFoundError`) — raise the most specific existing fit
- If a distinct failure has no type, define one — a one-line class (`class QuotaExceededError(Exception): pass`) is cheap, and inheriting from the project's base exception keeps it catchable in bulk too
- Distinct failures that callers will treat differently need distinct types: not-found, permission-denied, and quota-exceeded raised as one shared class with different messages forces callers back to string matching
- In JavaScript/TypeScript, subclass `Error` (`class RateLimitError extends Error`) or set a stable `code` property; never throw plain strings or object literals, which lack stacks and instanceof identity
- Give structured fields to the type, not just the message: `QuotaExceededError(limit=100, retry_after=30)` lets handlers act on the numbers without parsing prose
- Don't go taxonomically wild either: a new exception class per call site is noise — one type per *distinct caller-visible failure*, organized under a small module hierarchy

**Red flags that you're about to violate this:**
- "raise Exception with a clear message is enough..."
- "Defining a custom exception class is overkill here..."
- "The message tells the caller exactly what went wrong..."
- "I'll use RuntimeError; it's basically for things like this..."
- "Callers can check the text if they need to distinguish..."

---

## Why It Works

1. **It declares the type to be the failure's API.** The model invests in the message because that's the visible artifact; reframing the class as the part code consumes redirects effort to the channel callers can actually branch on.

2. **It collapses the cost objection.** "Defining a class is overkill" is the operative rationalization; pointing out the one-line definition makes the comparison honest — one line now versus string matching in every caller forever.

3. **It sets the granularity dial on both ends.** "One type per caller-visible failure" prevents both the base-class collapse and the opposite failure of fifty ceremonial classes — models overcorrect without an upper bound.

4. **It connects producer discipline to consumer hygiene.** Narrow catching downstream is impossible when upstream raises only `Exception`; showing that link recruits the model's existing knowledge that broad catches are bad.

## Origin

An internal client library, largely AI-generated, raised `RuntimeError` with seventeen different messages. The first consuming team needed to retry timeouts but not auth failures, so they wrote `except RuntimeError as e: if "timed out" in str(e): ...` — and a later "message cleanup" PR that rephrased it to "deadline exceeded" silently disabled their retries. Three teams eventually maintained three separate string-matching tables against the same library. Replacing seventeen messages with five exception classes deleted all three tables and about two hundred lines of regex.
