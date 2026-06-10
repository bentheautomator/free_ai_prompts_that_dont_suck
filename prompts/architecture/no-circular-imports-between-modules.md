---
title: No Circular Imports Between Modules
slug: no-circular-imports-between-modules
category: architecture
tags: [universal, architecture, coupling]
works_with: all
severity: high
one_liner: "AI adding the one import that turns two modules into a dependency cycle"
---

# No Circular Imports Between Modules

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from closing a dependency cycle between modules just because the symbol it needs happens to live on the other side.

**[Copy-paste ready version](../../install/no-circular-imports-between-modules.md)** — just the instruction block, no explanation.

## The Problem

The AI is editing `orders` and needs a type that lives in `billing`. It adds the import. What it never checks is that `billing` already imports `orders`, so the codebase now has a cycle. In Python that surfaces as an `ImportError` that only fires under one import order, so it passes locally and explodes in production. In JavaScript it's an export that's mysteriously `undefined` at module load. In Go the compiler refuses outright and the AI "fixes" it by mashing both packages into one.

The reason this happens constantly: from inside a single file, the dependency graph is invisible. The AI sees "symbol I need, module that has it" and the editor autocompletes the import. It compiles, tests pass on the AI's machine in the order tests happen to import things, and the task is done. The cycle is a property of the whole graph, and nobody asked the AI to look at the whole graph.

Once a cycle exists it metastasizes. Two cyclic modules are effectively one module: you can't test, extract, or reason about either independently, and every "quick fix" inside the cycle (lazy imports, imports inside function bodies, re-export shims) adds another landmine.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Circular Imports Between Modules

NEVER add an import that creates a dependency cycle between modules or packages. Before importing from module B while editing module A, check whether B (directly or transitively) already imports A.

Cycles fuse two modules into one untestable blob, and in Python/JavaScript they cause load-order bugs that pass locally and fail in production.

- Before adding a cross-module import, grep the target module for imports of the module you are editing; if any exist, stop and restructure instead
- If both modules need the same type or helper, move it DOWN into a module both can depend on (`shared`, `core`, `types`), never sideways
- If A needs to trigger behavior in B and B already depends on A, invert it: B passes a callback, B subscribes to an event A emits, or A exposes an interface that B implements
- Do not "fix" a cycle with a lazy import, an import inside a function body, a deferred `require()`, or a type-only import that hides a real runtime dependency; these conceal the cycle, they don't remove it
- In Go or other languages where the compiler rejects cycles, do not merge the two packages to make the error go away; restructure the dependency instead

**Red flags that you're about to violate this:**
- "The type I need is right there in billing, one import won't hurt..."
- "I'll just import it inside the function so it resolves at call time..."
- "It's only a type import, that doesn't really count as a dependency..."
- "The compiler complains about the cycle, so I'll combine the packages..."
- "Tests pass, so the import order must be fine..."

---

## Why It Works

1. **It adds the missing check at decision time.** The cycle is invisible from one file; "grep the target for imports of you" is a five-second action that makes the graph visible exactly when the import is being typed.

2. **It closes the lazy-import loophole by name.** Function-body imports are the AI's favorite cycle "fix" because they make the error disappear; naming them as concealment removes the easy out.

3. **It gives the structurally-correct moves.** "Move it down or invert it" replaces the vague "avoid cycles" with two concrete actions, so the AI doesn't have to invent a fix and pick the wrong one.

4. **It blocks the Go-specific failure.** When the compiler enforces the rule, the path of least resistance is merging packages, which is worse than the cycle; the rule forecloses it explicitly.

## Origin

An assistant needed an enum from the `notifications` package while editing `accounts`, and `notifications` already imported `accounts` for user lookups. It resolved the resulting Python `ImportError` by moving the import inside a function. That worked until a background worker imported the modules in the opposite order six weeks later and crashed on startup, taking queue processing down for a morning. Unwinding the cycle properly meant touching eleven files that had grown around it.
