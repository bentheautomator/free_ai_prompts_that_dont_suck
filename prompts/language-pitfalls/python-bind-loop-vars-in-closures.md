---
title: Python Bind Loop Vars in Closures
slug: python-bind-loop-vars-in-closures
category: language-pitfalls
tags: [universal, python]
works_with: all
severity: high
one_liner: "Stops Python closures in loops from all capturing the last loop value"
---

# Python Bind Loop Vars in Closures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the bug where every lambda created in a Python loop ends up using the loop's final value.

**[Copy-paste ready version](../../install/python-bind-loop-vars-in-closures.md)** — just the instruction block, no explanation.

## The Problem

Build a list of callbacks in a loop — `handlers = [lambda: process(item) for item in items]` — and every single handler processes the last item. Python closures capture variables by reference, not by value, and they look the variable up when the function is *called*, not when it's defined. By call time, the loop is finished and `item` holds its final value. Same failure with `for i in range(n): callbacks.append(lambda: do(i))`, with nested `def`s in loops, and with `functools.partial`-shaped code written as lambdas.

The result is quietly wrong behavior rather than a crash: N buttons all wired to the last button's action, N scheduled jobs all operating on the last tenant, N retry handlers all retrying the same URL. It often survives testing because testing one callback (or a one-element list) works fine.

AI assistants generate this because the code is syntactically perfect and the equivalent pattern is safe in languages with per-iteration scoping, like JavaScript's `let` or Go 1.22+ loop variables. Python is the language where this idiom is broken.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Python Bind Loop Vars in Closures

NEVER create a closure (lambda or nested `def`) inside a Python loop that references the loop variable directly. Python closures capture by reference and resolve at call time, so every closure sees the loop's final value.

- Wrong: `callbacks = [lambda: handle(item) for item in items]` — all callbacks handle the last item.
- Right: bind at definition time with a default argument: `callbacks = [lambda item=item: handle(item) for item in items]`.
- Also right: `functools.partial(handle, item)` — clearer intent than the default-arg trick.
- Also right: extract a factory: `def make_handler(item): return lambda: handle(item)` — the function call creates a new scope per iteration.
- This applies to any late-executed code created in a loop: thread targets, signal handlers, `dict` of dispatch functions, pytest parametrization helpers, GUI callbacks.
- The same trap exists when closing over any variable that is reassigned later, not just loop variables. If the closure runs later and the variable changes, bind it.
- If a closure in a loop intentionally reads the live variable, add a comment saying so; otherwise assume it's a bug.

**Red flags that you're about to violate this:**

- "A lambda right here is more concise than defining a helper."
- "Each iteration creates its own lambda, so each one has its own `item`."
- "This worked when I wrote the same thing in JavaScript with `let`."
- "The callbacks fire immediately anyway, so capture timing doesn't matter."
- "Adding `item=item` looks redundant, so I'll clean it up."

**Red-flag bonus:** if you find yourself *removing* an existing `lambda x=x:` because it "looks like a typo," stop — that's the fix, not the bug.

---

## Why It Works

1. **It corrects the per-iteration-scope assumption.** The model's intuition comes from JS `let` and modern Go; stating that Python resolves at call time replaces the wrong mental model with the right one.
2. **It protects the fix from "cleanup."** The `x=x` idiom looks like a mistake, and assistants routinely delete it during refactors. Explicitly blessing it prevents regression.
3. **It offers three sanctioned alternatives**, so "concise lambda" never wins by being the only pattern the model has at hand.

## Origin

A scheduler refactor generated `for tenant in tenants: jobs.append(lambda: sync(tenant))`. Every nightly job synced the final tenant in the list — the other forty tenants silently received no sync for eleven days, while the last tenant got synced forty-one times. The data-staleness tickets were initially blamed on the upstream API.
