---
title: Python Equality Not Is
slug: python-equality-not-is
category: language-pitfalls
tags: [universal, python]
works_with: all
severity: high
one_liner: "Stops Python 'is' comparisons that only pass by interning accident"
---

# Python Equality Not Is

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `is` being used for value comparison in Python, where it only works by interpreter accident.

**[Copy-paste ready version](../../install/python-equality-not-is.md)** — just the instruction block, no explanation.

## The Problem

`if status is "active":` and `if count is 0:` look reasonable and — here's the trap — they often *work in testing*. CPython interns small integers (-5 to 256) and many short string literals, so identity comparison accidentally agrees with equality for the values you happen to test with. Then the string arrives from user input, a database driver, or an f-string, it's a different object with the same value, and the branch silently stops firing. `1000 is 1000` can even differ between the REPL and a script because of compile-time constant folding.

The reverse mistake also shows up: `if value == None:` instead of `is None`. That one usually works, until `value` is a numpy array or an ORM column object whose `__eq__` returns something unexpected — pandas raises "truth value of an array is ambiguous" precisely here.

Assistants generate `is` for values because it reads like English and because training data is full of it. Modern Python even emits a `SyntaxWarning` for `is` with literals, but generated code rarely gets run with warnings visible.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Python Equality Not Is

Use `is` ONLY for singletons (`None`, `True`, `False`, module-level sentinel objects) and deliberate identity checks. Use `==` for every value comparison. In Python, `is` compares object identity; it agrees with `==` for small ints and interned strings only by interpreter accident, so `is`-based value checks pass in tests and fail on real data.

- Wrong: `if status is "active":`, `if code is 200:`, `if char is 'x':` — replace with `==`.
- Right: `if value is None:`, `if value is not None:` — never `== None`, which invokes `__eq__` and misbehaves on numpy arrays, pandas objects, and ORM columns.
- Right: `if result is _MISSING:` where `_MISSING = object()` is a sentinel — identity is the point.
- Don't "fix" `is None` to `== None` for stylistic consistency; `is None` is the canonical form.
- For booleans, prefer `if flag:` over `if flag is True:` unless you specifically need to exclude truthy non-bool values — and say so in a comment if you do.
- Treat any `is` whose right-hand side is a literal (string, number) as a bug, full stop.

**Red flags that you're about to violate this:**

- "`is` reads more naturally here than `==`."
- "I tested it and `x is 5` returned True, so it's fine."
- "Identity is faster than equality, and this is a hot loop."
- "The codebase uses `is` for None, so I'll use it for strings too for consistency."
- "These are both literals, so they're obviously the same object."

---

## Why It Works

1. **It explains why testing lies.** The interning accident is the reason this bug survives review; once stated, "I tested it and it worked" stops being persuasive evidence.
2. **It draws the line at a checkable rule.** "`is` with a literal RHS is a bug" is mechanical — no judgment call, no loophole.
3. **It handles both directions.** Banning `is "literal"` while mandating `is None` prevents the over-correction where the model flips every `is` to `==` and breaks numpy/ORM code.

## Origin

A request router used `if method is "POST":`. It worked for months because the literal in the comparison and the literal in the test suite were interned to the same object. A refactor started reading the method from a parsed buffer — same string value, different object — and every POST began returning 405. The diff that broke it didn't touch the comparison line at all, which made it a miserable bisect.
