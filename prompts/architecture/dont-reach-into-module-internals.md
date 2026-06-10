---
title: Don't Reach Into Module Internals
slug: dont-reach-into-module-internals
category: architecture
tags: [universal, architecture, boundaries]
works_with: all
severity: high
one_liner: "Deep imports of another module's private guts instead of its public API"
---

# Don't Reach Into Module Internals

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from importing another module's private functions, internal files, or underscore-prefixed helpers instead of going through its public interface.

**[Copy-paste ready version](../../install/dont-reach-into-module-internals.md)** — just the instruction block, no explanation.

## The Problem

The AI needs to normalize a phone number. Grep finds `_normalize_phone()` inside `billing/internal/validators.py`. It works, it's importable, and the AI imports it — from a private file, in another module, three directories deep. The function's author considered it an implementation detail, free to rename, reshape, or delete. It is now load-bearing for a module its author has never heard of.

This is how module boundaries die: not by decision but by a hundred convenient imports. Once internals have external callers, the owning team can no longer refactor anything without a codebase-wide impact search. The "public API" stops meaning anything, because the real API is whatever anyone ever imported. In ecosystems with enforcement (Go's `internal/`, Java modules) the AI gets blocked and routes around it — copying the private code or moving it somewhere importable, which can be even worse.

AI assistants do this because search results are flat. `_normalize_phone` and a public `normalize_phone` look identical in a grep listing, and the private one is the one that exists. The naming convention, the directory named `internal`, the absence from `__init__.py` exports — all the signals humans use are visible to the AI too. It just isn't told they're load-bearing.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Reach Into Module Internals

NEVER import another module's internals: underscore-prefixed names, files under `internal/` or `_private/` paths, symbols absent from the module's `__init__.py`/`index.ts` exports, or anything the module's public surface doesn't offer. Use the public interface or change it — never tunnel under it.

Every external import of an internal converts an implementation detail into an unbreakable contract the owner doesn't know they've signed.

- The public surface is what the module exports at its top level (its `__init__.py`, `index.ts`, package API, or documented entry points); if you'd need a deep path like `other_module/internal/helpers` to reach a symbol, that symbol is off-limits
- If the capability you need exists only as an internal, do one of: (a) add it to the module's public exports if it genuinely belongs to that module's job, (b) move it down into a shared module if it's generic, or (c) write your own — for small helpers, duplication beats a boundary violation
- Don't dodge enforcement: no copying a private function verbatim "to avoid the import," no re-exporting someone's internal through your own module, no reflection/dynamic import tricks
- Test code gets no exemption for other modules' internals; test through the public API or the tests will fossilize the implementation
- When you promote an internal to public (option a), you're changing that module's contract — name it in your summary so the owner sees it

**Red flags that you're about to violate this:**
- "The function I need already exists, it's just in their private file..."
- "The underscore is only a convention, the import works fine..."
- "Adding it to their public API means modifying their module..."
- "I'll copy the private helper so I'm not technically importing it..."
- "It's just a test, reaching into internals doesn't count there..."

---

## Why It Works

1. **It defines "public" mechanically.** Exports lists, underscore prefixes, and `internal/` paths are checkable at the import site — the AI doesn't need tribal knowledge to know which side of the line a symbol is on.

2. **It supplies three legal alternatives.** Promote, move down, or duplicate covers every real case; without named outs, the AI concludes the deep import was necessary.

3. **It re-prices small duplication.** Engineers (and AIs) treat duplication as the cardinal sin; for a five-line helper, the boundary is worth more than the dedup, and the rule says so out loud.

4. **It closes the copy-paste escape hatch.** Copying an internal preserves the coupling (the copy drifts from the original) while hiding it from grep — naming the move as a violation removes its appeal.

## Origin

A search team rewrote their query parser and broke checkout. The connection: two years earlier, an assistant had imported the parser's internal tokenizer into the cart module for coupon-code parsing — a deep import nobody reviewed closely because the diff was two lines. The parser team's refactor was textbook-safe with respect to their public API, which is exactly why their test suite caught nothing. The incident review's enduring quote: "our public API was a suggestion."
