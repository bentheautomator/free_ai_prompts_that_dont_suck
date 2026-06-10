---
title: Await Every Promise You Create
slug: await-every-promise-you-create
category: concurrency
tags: [universal, concurrency, async]
works_with: all
severity: high
one_liner: "Stops dropped awaits that silently skip work and swallow errors"
---

# Await Every Promise You Create

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from calling an async function and forgetting the `await`, so the work appears to succeed whether or not it ever ran.

**[Copy-paste ready version](../../install/await-every-promise-you-create.md)** — just the instruction block, no explanation.

## The Problem

A dropped `await` is the quietest bug in async code. `saveUser(user)` instead of `await saveUser(user)` compiles, runs, and returns — the function call really does start the work, so light testing often passes because the event loop happens to finish the save before anyone checks. Then the function returns early under load, the response goes out before the write lands, and the caller acts on state that doesn't exist yet. If the promise rejects, the error doesn't surface in the request that caused it; it becomes an unhandled rejection logged (or not) somewhere unrelated, minutes of debugging away from its cause.

AI assistants drop awaits constantly because the line *looks complete*. The statement is syntactically valid, the linter may be silent, and in the AI's single-threaded mental model "I called the function" and "the function finished" are the same event. It's especially common when refactoring a sync function to async: the body gets `async` added, but the three existing call sites keep calling it bare.

The failure also hides in expression positions: returning `items.map(fetchDetails)` produces an array of promises that gets serialized as `[{}, {}, {}]`, and `if (isValid(input))` on an async validator is always truthy because a promise is a truthy object.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Await Every Promise You Create

ALWAYS `await` (or explicitly handle) every promise at the moment you create it. A bare call to an async function is not a statement that ran — it is work you started and then abandoned, with its errors detached from the caller.

- Never call an async function as a bare statement: `saveUser(user);` → `await saveUser(user);`. If you genuinely intend fire-and-forget, say so explicitly with a named error handler: `void saveUser(user).catch(reportError);` — never an implicit drop.
- Never branch on a promise: `if (isValid(x))` where `isValid` is async is always true. Await it first.
- Never return or serialize a collection of promises: `items.map(fetchDetail)` needs `await Promise.all(...)` around it.
- When you change a function from sync to async, immediately update every call site in the same edit. Search for the function name; do not assume the type checker or tests will catch bare calls.
- In languages with explicit futures/tasks (Python asyncio, C#, Rust), the same rule applies: a coroutine you never awaited never ran; a Task you never observed hides its exception.

**Red flags that you're about to violate this:**
- "This call doesn't return anything I need, so I don't need to await it."
- "The tests pass, so the timing must be fine."
- "It's just a log/audit/notification write — it can happen whenever."
- "I made the function async but the callers don't really depend on completion."
- "The linter didn't flag it, so the promise is handled."

---

## Why It Works

1. **It redefines what a bare call means.** The AI reads `saveUser(user);` as "save the user"; the rule renames it "start a save and abandon it," which makes the omission visible as an omission.
2. **It closes the "I don't need the return value" loophole** — the most common rationalization — by separating *needing the value* from *needing completion and errors*, which you almost always need.
3. **It forces call-site updates into the same edit as the sync-to-async refactor,** the exact moment most dropped awaits are born.
4. **It makes intentional fire-and-forget syntactically loud** (`void ... .catch(...)`), so silence can never be mistaken for intent.

## Origin

A checkout handler called `await chargeCard()` and then `recordPayment(order)` — no await, added during a refactor that made `recordPayment` async. Every test passed because the in-memory test DB completed the write before assertions ran. In production under load, the response returned before the payment record committed, the fulfillment poller saw paid-but-unrecorded orders, and a week of orders shipped twice before anyone connected the unhandled-rejection log line to the missing rows.
