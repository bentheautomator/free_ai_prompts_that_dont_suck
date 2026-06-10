---
title: Match the Async Style in Use
slug: match-async-style-in-use
category: code-quality
tags: [universal, async, patterns]
works_with: all
severity: medium
one_liner: "AI mixing promise chains, callbacks, and async/await against the file's grain"
---

# Match the Async Style in Use

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from introducing a different concurrency idiom than the one the surrounding code uses.

**[Copy-paste ready version](../../install/match-async-style-in-use.md)** — just the instruction block, no explanation.

## The Problem

An async/await codebase receives a new function written with `.then()` chains. A callback-style Node module gets an async function spliced into the middle of its flow. A Python service built on `asyncio` gains a thread-spawning helper; a threading-based one gains a stray coroutine that nothing ever awaits. The AI picks its concurrency idiom from training-data probability, not from the file in front of it, and concurrency idioms are exactly where "functionally equivalent" stops being true.

Mixing async styles isn't just ugly — the seams between idioms are bug habitats. A `.then()` chain inside an async function invites the classic missing-return that swallows rejections. A promise dropped into callback-style code loses its error path entirely unless someone bridges it correctly. An unawaited coroutine in Python silently never runs (with a warning nobody reads), and `asyncio.run()` called from inside a running loop throws at runtime. Even when the mixed code works, every reader now context-switches between error-handling models — `catch` here, error-first callback there, try/except around await elsewhere — in a domain where misread error flow becomes a swallowed production failure.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Match the Async Style in Use

ALWAYS write asynchronous code in the same idiom the surrounding code uses. Concurrency style is not a preference slot — the file already chose between async/await, promise chains, callbacks, threads, or an event loop, and your addition joins that choice.

The seams between mixed idioms are where errors get lost: unreturned promises inside async functions, rejections that no callback ever sees, coroutines that are never awaited and never run.

**Before writing async code:**
- Look at how the nearest similar code handles it: async/await vs `.then()` vs callbacks (JS); asyncio vs threads vs sync (Python); goroutines/channels vs sync (Go); and match it — including the error idiom that goes with it (`try/catch` around `await`, `.catch()` on chains, error-first callbacks)
- Don't convert existing code's style to enable yours — write yours to fit theirs; if bridging is unavoidable (a callback API in promise-land), use the codebase's established bridge (`promisify`, existing wrapper utilities), not a hand-rolled adapter
- In an async/await file, never bolt `.then()` onto an awaited expression or leave a promise floating unawaited — every promise is awaited, returned, or explicitly handled
- In Python, never call a coroutine without awaiting it, and never start a new event loop (`asyncio.run`) inside code that may already be in one — find how the codebase enters async and use that path
- Respect the codebase's concurrency primitives: if it has a task queue, a worker pool, or a scheduler for background work, use it rather than spawning ad-hoc threads/tasks

**Red flags that you're about to violate this:**
- ".then() reads more cleanly for this short chain..."
- "I'll fire this off without awaiting; we don't need the result..."
- "A quick background thread is simpler than their task queue..."
- "I'll make this one function async; callers can adapt..."
- "Mixing styles here is fine, JavaScript supports both..."
- Writing async code without having looked at how the file's existing async code handles errors

---

## Why It Works

1. **It moves async style out of the preference category.** The AI treats `.then()` vs `await` as interchangeable syntax. Tying each idiom to its distinct error-flow model reframes the choice as behavioral, where the AI takes matching seriously.

2. **It names the seam bugs specifically.** Floating promises, unawaited coroutines, and nested event loops are the concrete failure modes of mixing. Concrete failure modes get checked; "inconsistency" gets shrugged at.

3. **It blocks the convert-the-file move.** An AI that prefers async/await will sometimes "helpfully" convert surrounding code to enable its style — turning a one-function change into a paradigm migration. Setting the direction of conformity prevents the scope explosion.

4. **It routes background work to existing primitives.** Ad-hoc threads and fire-and-forget tasks bypass the observability and shutdown handling the project's queue already provides — the same reinvention failure, in the domain where it's hardest to debug.

## Origin

A Python service handled webhooks with asyncio throughout. An AI session added a notification call as a coroutine — invoked, but never awaited, inside a function the model had written in a half-callback style it imported from somewhere in its training. No error, one ignorable `RuntimeWarning` in the logs, and zero notifications delivered, ever. Because the warning didn't fail anything, the gap was discovered by the customer success team, three weeks in, asking why nobody was receiving anything.
