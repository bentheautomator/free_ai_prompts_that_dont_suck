---
title: Python No Mutable Default Args
slug: python-no-mutable-default-args
category: language-pitfalls
tags: [universal, python]
works_with: all
severity: high
one_liner: "Stops shared-state bugs from mutable default arguments in Python"
---

# Python No Mutable Default Args

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents Python functions whose default list/dict/set silently accumulates state across every call.

**[Copy-paste ready version](../../install/python-no-mutable-default-args.md)** — just the instruction block, no explanation.

## The Problem

`def add_item(item, items=[])` looks like a clean signature, which is exactly why AI assistants generate it constantly. Python evaluates default values once, at function definition time — not per call. That one list object is shared by every invocation that omits the argument. Call the function twice and the second caller sees the first caller's data. Same trap with `cache={}`, `seen=set()`, and the sneakier `timestamp=datetime.now()` (frozen at import time, not call time).

The bug is invisible in unit tests that call the function once, invisible in code review unless you know to look, and then it surfaces in production as cross-request data bleed: user A's items showing up in user B's response. In long-running processes (web servers, workers) the shared object grows forever.

Assistants produce this because the pattern is statistically everywhere in training data — it reads like Java or JavaScript, where default expressions are evaluated per call. The Python semantics are the outlier, so the model ports the wrong intuition.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Python No Mutable Default Args

NEVER use a mutable object (`[]`, `{}`, `set()`, class instances) or any call expression (`datetime.now()`, `uuid4()`) as a Python default argument value. Python evaluates defaults once at definition time, so the same object is shared across all calls.

- Wrong: `def add(item, items=[]):` — every call without `items` appends to one shared list.
- Right: `def add(item, items=None):` then `if items is None: items = []` as the first lines of the body.
- Wrong: `def log(msg, when=datetime.now()):` — the timestamp is frozen at import.
- Right: `def log(msg, when=None):` then `when = when or datetime.now()` (use the explicit `is None` check if falsy values like `0` are valid inputs).
- Immutable defaults are fine: `None`, numbers, strings, `True`/`False`, tuples of immutables, `frozenset()`.
- In dataclasses, use `field(default_factory=list)` — never `= []`.
- When you see an existing mutable default in code you are editing, flag it; do not copy the pattern into new functions.

**Red flags that you're about to violate this:**

- "A default empty list is the cleanest signature here."
- "The None-check boilerplate makes the function longer for no reason."
- "This function is only called once, so sharing the default can't matter."
- "I'll default the timestamp to now() so callers don't have to pass it."
- "Other functions in this file already do `items=[]`, so I'll stay consistent."

---

## Why It Works

1. **It corrects a false cross-language equivalence.** The model's prior says defaults are evaluated per call (true in JS, Java, C#). Stating Python's definition-time evaluation explicitly overrides the ported intuition.
2. **It names the rationalization.** "Cleanest signature" and "stay consistent with the file" are the exact thoughts that precede the bug; flagging them interrupts the pattern before it's emitted.
3. **It supplies the replacement idiom.** The `None` sentinel and `default_factory` patterns are stated as the default, so the model doesn't have to choose — it just substitutes.

## Origin

A request-handler helper was generated with `def build_response(data, warnings=[])`. Tests passed (one call per test). In production, the gunicorn worker reused the function across requests and warnings from earlier requests leaked into later users' API responses — including a warning containing another customer's account ID. Two days of grepping request logs to assess the exposure, all from one default argument.
