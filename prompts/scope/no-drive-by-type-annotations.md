---
title: No Drive-By Type Annotations
slug: no-drive-by-type-annotations
category: scope
tags: [universal, scope, focus]
works_with: all
severity: medium
one_liner: "AI adding type annotations to untyped code it was only supposed to edit"
---

# No Drive-By Type Annotations

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from running an impromptu typing pass over untyped code while doing unrelated work.

**[Copy-paste ready version](../../install/no-drive-by-type-annotations.md)** — just the instruction block, no explanation.

## The Problem

The task was to change one function's behavior in a loosely typed Python module. The diff annotates every function in the file: parameters, returns, a few `TypedDict`s invented for dictionaries the AI passed by, an `Optional` sprinkled wherever it wasn't sure. In TypeScript codebases the same instinct shows up as `any` being "upgraded" to invented interfaces, or `@ts-ignore` lines getting resolved with guessed types.

The trouble is that annotations on code the AI didn't write are claims about contracts it inferred from one reading. Some of those guesses are wrong — the function that "returns dict" sometimes returns None on a path the AI didn't trace; the field typed as `int` arrives as a string from one legacy caller. Wrong annotations are worse than none: they tell the type checker and every future reader a confident lie. And in gradually typed codebases, new annotations can change tooling behavior — a checker that ignored the untyped module now reports errors in it, breaking CI for code nobody touched behaviorally.

Typing a module properly means tracing its real contracts, running the checker, and fixing what surfaces. That's a typing migration task, with its own scope. It is not a garnish for an unrelated fix.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Drive-By Type Annotations

Do not add type annotations to existing code unless typing is the task. Annotate what you write; leave the typing state of what you visit unchanged.

The core problem: annotations on code you didn't write are inferred contracts presented as declared ones, and a wrong annotation lies to the type checker and every future reader with full confidence.

- New functions and variables you create may be annotated to match the project's prevailing style and strictness
- Do not annotate existing unannotated functions, parameters, or returns in files you pass through
- Do not invent interfaces, TypedDicts, or type aliases to describe data structures the task didn't require you to formalize
- Do not narrow existing loose types (`any`, `object`, `dict`) or resolve suppression comments (`# type: ignore`, `@ts-ignore`) in passing; suppressions often guard known checker limitations
- If your change makes an existing annotation wrong, fixing that annotation is in scope and required
- If the module's untyped state genuinely hinders the task or hides a likely bug, say so in a sentence and offer a separate typing pass with checker verification, which is what a real one needs

**Red flags that you're about to violate this:**
- "I'll add type hints while I'm in this file..."
- "Annotating these functions improves the developer experience..."
- "This `any` is lazy, I can write the real interface..."
- "Type coverage is low here, easy win..."
- "I'm confident what this returns, the hint is free..."

---

## Why It Works

1. **It distinguishes inferred from declared contracts.** The AI experiences its type guess as knowledge; naming the gap between "what I inferred in one reading" and "what the author guarantees" deflates that confidence where it isn't earned.

2. **It protects suppressions as information.** `type: ignore` comments read as debt to the AI; explaining they often encode known checker limitations stops the helpful-seeming cleanup that reintroduces solved problems.

3. **It keeps the genuine duty.** Annotations invalidated by your own change must be fixed; carving this out prevents overcorrection into leaving stale types behind.

4. **It defines what a real typing pass requires.** "With checker verification" makes clear why drive-by annotation is not a smaller version of the real task but a different, worse thing.

## Origin

An assistant editing one function in an untyped module annotated the rest of the file as a courtesy, typing a parser's return as `dict[str, str]`. It also returned lists for repeated keys, a case one downstream consumer depended on. Six weeks later another engineer, trusting the annotation, "simplified" that consumer and broke handling of multi-value fields in a way that surfaced only with a specific customer's data. The bug hunt kept circling the consumer, because who suspects the type hints?
