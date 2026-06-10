---
title: JS Strict Equality Only
slug: js-strict-equality-only
category: language-pitfalls
tags: [universal, javascript]
works_with: all
severity: high
one_liner: "Stops JS == coercion bugs where '0' equals 0 but not '0.0'"
---

# JS Strict Equality Only

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents loose `==` comparisons whose coercion rules make `"" == 0` true and `null == 0` false.

**[Copy-paste ready version](../../install/js-strict-equality-only.md)** — just the instruction block, no explanation.

## The Problem

JavaScript's `==` runs both operands through a coercion algorithm before comparing, and the algorithm's outputs are memorably weird: `"" == 0` is true, `"0" == 0` is true, `[] == 0` is true, `null == undefined` is true, but `null == 0` is false and `NaN == NaN` is false. Code like `if (user.id == requestedId)` works while both sides are strings, then someone parses one side to a number, and suddenly `"007" == 7` is true and you've matched the wrong user.

The one place loose equality is genuinely idiomatic — `value == null` to catch both `null` and `undefined` in a single check — is also the place where an AI "cleanup" pass converts it to `=== null` and silently stops catching `undefined`. So assistants get this wrong in both directions: emitting `==` where coercion bites, and "fixing" the deliberate `== null` where it doesn't.

`==` is all over training data because it's all over the web's JavaScript. The model also ports intuitions from Python and Java, where the double-equals operator compares values without type coercion.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### JS Strict Equality Only

Use `===` and `!==` for every comparison in JavaScript and TypeScript. The loose operators (`==`, `!=`) coerce types before comparing, producing results like `"" == 0` (true), `"0" == false` (true), and `null == 0` (false) that change behavior the moment a value's type drifts.

- Wrong: `if (status == 200)`, `if (input != "")` — use `===` / `!==`.
- One sanctioned exception: `value == null` is the standard idiom for "null or undefined" in one check. If a codebase uses it, keep it; if you write it, you may instead write the explicit `value === null || value === undefined`. NEVER mechanically rewrite `== null` to `=== null` — that drops the `undefined` case and changes behavior.
- Don't rely on coercion to compare across types. If one side is a string and the other a number, convert explicitly first (`Number(param)`, `String(id)`) and then use `===`.
- `NaN === NaN` is false; test with `Number.isNaN(x)`, never with equality.
- For objects and arrays, neither operator compares contents — both compare references. Use a deep-equality helper when you mean contents.
- In TypeScript, `===` plus narrowed types catches at compile time what `==` hides at runtime; don't silence the compiler with `as any` to make a loose comparison typecheck.

**Red flags that you're about to violate this:**

- "`==` handles the string-vs-number case for me automatically."
- "I'll normalize this `== null` to `=== null` while I'm here."
- "The query param is always a number in practice, so coercion is harmless."
- "Two equals signs compare values in every other language I know."
- "This comparison has worked in production for years, so the operator is fine."

---

## Why It Works

1. **It blocks both failure directions.** Most lint advice only bans `==`; the explicit carve-out for `== null` stops the equally common AI error of "fixing" deliberate idioms into bugs.
2. **It replaces coercion with explicit conversion.** Telling the model to convert *then* compare gives it a legal way to handle mixed types, so it isn't tempted back to `==` as the path of least resistance.
3. **It names concrete absurd cases.** `"" == 0` being true is more memorable and more binding than "coercion is confusing."

## Origin

A permissions check compared a role ID from a JWT (string) against a config value (number) with `==`. It worked — until a refactor introduced an "unset" state encoded as `null`, and `null == 0` being false meant unset users fell through to the *default-allow* branch. The fix was three characters; finding it took a weekend because everyone was reading the auth logic, not the operator.
