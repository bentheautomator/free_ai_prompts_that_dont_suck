---
title: Await or Handle Every Promise
slug: await-or-handle-every-promise
category: error-handling
tags: [universal, errors, async]
works_with: all
severity: high
one_liner: "AI firing async calls without await or catch, so their failures vanish"
---

# Await or Handle Every Promise

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents fire-and-forget async calls whose errors evaporate into unhandled-rejection limbo.

**[Copy-paste ready version](../../install/await-or-handle-every-promise.md)** — just the instruction block, no explanation.

## The Problem

One missing keyword: `saveAuditLog(event);` instead of `await saveAuditLog(event);`. The function returns a promise, nobody awaits it, nobody attaches `.catch()`. If the save fails, the rejection has no handler — in Node it surfaces as a process-level `unhandledRejection` warning (or a crash, depending on version and config), in browsers as a console message nobody reads, and in either case nowhere near the code that caused it. If it *doesn't* fail, you still have a race: the caller may finish, respond, or exit before the work completes. Python has the same trap with un-awaited coroutines and `asyncio.create_task()` results nobody stores — tasks whose exceptions are reported only when garbage-collected, if then.

AI assistants drop awaits in recognizable spots: "background" work the model decides shouldn't block (logging, analytics, cache warm-up), `forEach(async item => ...)` loops (forEach ignores the returned promises — the loop "finishes" instantly and every error is orphaned), and refactors where a sync function became async but one call site didn't get updated. The code reads naturally — that's the problem. A missing `await` looks identical to a deliberate fire-and-forget.

The result is a class of failures with no stack trace pointing anywhere useful, intermittent ordering bugs, and work that silently didn't happen.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Await or Handle Every Promise

Every promise (and coroutine/task) must be awaited, returned, or given an explicit rejection handler. NEVER leave an async call floating — its failure has nowhere to go.

- Default to `await`. If you genuinely want fire-and-forget, you must still handle rejection: `void doWork().catch(err => logger.error("background work failed", err));` — and the `void` plus `.catch` signals the choice was deliberate
- Never use `forEach(async ...)`: forEach discards the promises, so nothing is awaited and every rejection is orphaned. Use `for...of` with `await`, or `await Promise.all(items.map(...))`
- `Promise.all` rejects on first failure and abandons the rest; when each item's outcome matters, use `Promise.allSettled` and *inspect the results* — calling allSettled and ignoring the rejected entries is the same swallowing with extra steps
- Python: every coroutine call gets `await`; every `asyncio.create_task()` result gets stored and eventually awaited (or given a done-callback that logs exceptions) — a bare `create_task` whose reference is dropped can be garbage-collected mid-flight, exception unreported
- When making a function async during a refactor, update every call site in the same change; search for calls to it that lack `await`
- Enable the linter that catches this (`@typescript-eslint/no-floating-promises`, `no-misused-promises`) when touching project config is in scope; it converts this whole class from runtime mystery to compile-time error

**Red flags that you're about to violate this:**
- "This doesn't need to block, so I'll skip the await..."
- "Logging/analytics can be fire-and-forget..."
- "forEach with an async callback handles each item..."
- "If the background task fails, it's not critical..."
- "I made the function async; the callers should still work..."

---

## Why It Works

1. **It converts fire-and-forget from a default into a marked decision.** The `void` + `.catch` form costs a few characters and produces the same non-blocking behavior — removing every legitimate reason to leave the bare floating call, so a bare call becomes unambiguous evidence of a mistake.

2. **It targets the three generation sites by name.** Background-ish work, `forEach(async)`, and async-refactor stragglers are where the model actually drops awaits; site-specific rules outperform the abstract principle.

3. **It closes the allSettled loophole.** Models "fix" Promise.all rejections by switching to allSettled and moving on; requiring inspection of results keeps the fix from being a quieter version of the bug.

4. **It recruits tooling.** A linter makes the invariant machine-enforced after the conversation ends, which is worth more than any phrasing of the rule.

## Origin

A compliance-sensitive app recorded every admin action via `writeAuditEntry(action)` — called without await in a handler an assistant had refactored, because audit writes "shouldn't slow down responses." The audit database had an intermittent connection issue for two months; roughly 7% of entries silently never landed, with only process-level unhandledRejection noise in logs nobody monitored. The gap was discovered during an actual audit, which is the single worst possible time to learn your audit log has holes.
