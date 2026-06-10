---
title: Freeze Public APIs During Internal Cleanup
slug: freeze-public-apis-during-internal-cleanup
category: refactoring
tags: [universal, refactoring, api]
works_with: all
severity: critical
one_liner: "Stops internal refactors from silently changing exported signatures"
---

# Freeze Public APIs During Internal Cleanup

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing exported function signatures, class interfaces, or endpoint contracts while cleaning up the internals behind them.

**[Copy-paste ready version](../../install/freeze-public-apis-during-internal-cleanup.md)** — just the instruction block, no explanation.

## The Problem

Internal cleanup has a blast radius of zero by definition: you can verify every caller because every caller is in the repo. The moment a refactor touches a public surface (an exported function, a published package's API, an HTTP endpoint, a CLI flag), the blast radius becomes "everyone who ever depended on you," and you can verify none of them. AI assistants don't see this line. While tidying a module, they'll reorder parameters on an exported function "for consistency," convert positional arguments to an options object "for clarity," or change a return type from list to generator "for efficiency." Inside the repo, they update the callers and everything looks green.

Outside the repo is where the customers live. The model treats the public boundary as just another function signature because, textually, that's all it is. Nothing in the code says "three other teams and a public SDK call this," so the model improves it like any other internal helper.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Freeze Public APIs During Internal Cleanup

When refactoring internals, the public surface is frozen. NEVER change anything an external caller could observe: exported function signatures, parameter names in languages with keyword arguments, parameter order, return types, class hierarchies of exported types, HTTP routes and payload shapes, CLI flags, or published constants.

You can verify every internal caller. You cannot verify a single external one. That asymmetry is the whole rule.

- Treat as public: anything exported from the package's entry point, anything documented, any HTTP/gRPC/GraphQL contract, any CLI interface, environment variable names, and anything tests outside the module import directly.
- Keyword-argument languages (Python, Ruby, Kotlin) make parameter *names* part of the contract. Renaming `def search(query=...)` to `def search(q=...)` breaks every caller using `query=`, even though the type checker shrugs.
- Default parameter values on public functions are contract too. Don't "clean up" `timeout=30` to `timeout=None`.
- Refactor freely behind the surface: extract private helpers, restructure internals, rename private members. The public function can become a thin wrapper over a new internal shape; that is the standard move.
- If the cleanup genuinely requires a public change, stop and propose it separately as a breaking change with a deprecation path (new name added, old name delegating, warning emitted). Never just edit the surface.
- Before finishing, diff the public surface explicitly: list every exported symbol and signature before and after. The list must be identical, or you must have flagged the difference.

**Red flags that you're about to violate this:**

- "Reordering these parameters makes the API more consistent."
- "All the callers are in this repo as far as I can tell."
- "I'll rename this keyword argument; the old name was misleading."
- "Returning an iterator is strictly better than returning a list."
- "Nobody passes this argument by name, surely."

---

## Why It Works

1. **It states the asymmetry the model can't see.** "You can verify internal callers, never external ones" gives a reason the boundary matters, which generalizes better than a list of forbidden edits.
2. **It names the contract surfaces models don't recognize as contracts.** Keyword-argument names and default values don't look like API; calling them out closes the two most common silent breaks.
3. **The before/after surface diff is a forcing function.** A model that must produce both lists and compare them will catch its own change; a model asked merely to "be careful" will not.
4. **The wrapper pattern channels the improvement instinct.** "Make the public function a thin shim over the new internals" lets the model do all the cleanup it wanted without touching the contract.

## Origin

During an internal cleanup of a Python SDK, an assistant renamed the keyword argument `page_size` to `limit` on a public method and updated every in-repo caller. The repo's tests passed. Every external user of the SDK who pinned to the next release got `TypeError: unexpected keyword argument 'page_size'` in production, and the maintainers shipped an emergency release restoring the old name within hours.
