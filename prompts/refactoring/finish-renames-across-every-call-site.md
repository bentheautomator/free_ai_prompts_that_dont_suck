---
title: Finish Renames Across Every Call Site
slug: finish-renames-across-every-call-site
category: refactoring
tags: [universal, refactoring, naming]
works_with: all
severity: high
one_liner: "Stops renames that update the definition but miss call sites"
---

# Finish Renames Across Every Call Site

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from renaming a symbol at its definition while leaving callers pointing at a name that no longer exists.

**[Copy-paste ready version](../../install/finish-renames-across-every-call-site.md)** — just the instruction block, no explanation.

## The Problem

A rename is the most atomic-looking refactor there is, which is exactly why assistants botch it. The model renames `getUserData` to `fetchUserProfile` in the file it's looking at, updates the two callers in that same file, and declares victory. The five callers in other files, the mock in the test suite, and the re-export in the package's `index` file all still say `getUserData`. In a compiled language this fails loudly at build time, which is merely annoying. In Python, Ruby, or JavaScript without strict tooling, it fails at runtime, in whichever code path happens to call the old name, possibly days later.

The root cause is context scope. The model's working set is the files it has open, and it confuses "all the call sites I can see" with "all the call sites." A rename is a whole-repository operation being performed by something with a keyhole view, and unless it's forced to widen the view, it won't.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Finish Renames Across Every Call Site

A rename is atomic: NEVER rename a function, class, method, or variable at its definition without updating every reference in the same change. A half-done rename is a broken build at best and a latent runtime crash at worst.

The references you can see in the current file are not all the references.

- Before renaming, search the entire repository for the old name, not just open files. Check: imports and re-exports, call sites, subclass overrides, test files, mocks and patch targets (`patch("module.getUserData")`), fixtures, and type annotations.
- Count the matches before, perform the rename, then search for the old name again. The second search must return zero hits (or only hits you can justify one by one, such as an unrelated symbol that shares the name).
- Watch for dynamic and indirect references that a compiler won't catch: `getattr`, `send`, string-keyed dispatch tables, dependency-injection registrations, and serializer configs that name methods as strings.
- Method renames must include every override in subclasses and every implementation of the same interface, or polymorphic dispatch silently splits in two.
- If the symbol is exported from a package boundary where external callers may exist, do not rename it outright; flag it and ask (see public-API rules).
- If the rename turns out to touch more files than expected, that is not a reason to stop halfway. Either complete it everywhere or revert it entirely. Never leave both names live.

**Red flags that you're about to violate this:**

- "I've updated the callers in this file; that should be all of them."
- "The tests will catch any references I missed."
- "I'll rename the definition now and fix stragglers if something breaks."
- "This is a private helper; nothing else could be using it."
- "The old name only appears in comments now, probably."

---

## Why It Works

1. **It converts "rename" from an edit into a search-edit-verify loop.** The zero-hits-after check is mechanical and unambiguous, so the model can't substitute confidence for verification.
2. **It enumerates the reference types models forget.** Mocks, patch targets, and string-keyed dispatch are systematically missed because they don't look like call sites; naming them moves them into the checklist.
3. **The complete-or-revert clause kills the worst end state.** A model that discovers mid-rename that the job is bigger than expected will otherwise stop halfway, leaving two names live, which is strictly worse than not starting.

## Origin

An assistant renamed a billing helper for clarity and updated all callers the type checker could see. It missed a `unittest.mock.patch` string in the test suite and a string-keyed handler registration in a task queue. Tests stayed green because the stale mock silently patched nothing, and the nightly invoice job crashed on its first run with a `KeyError` on the old handler name. Invoices went out a day late.
