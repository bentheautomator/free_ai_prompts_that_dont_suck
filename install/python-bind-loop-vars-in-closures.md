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
