---
title: Clean Up Now-Unused Symbols
slug: clean-up-now-unused-symbols
category: code-quality
tags: [universal, dead-code, edits]
works_with: all
severity: medium
one_liner: "AI edits that orphan variables, params, and helpers and leave them behind"
---

# Clean Up Now-Unused Symbols

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from leaving behind the variables, parameters, and helper functions its own edit just orphaned.

**[Copy-paste ready version](../../install/clean-up-now-unused-symbols.md)** — just the instruction block, no explanation.

## The Problem

An edit rarely just adds or removes — it reroutes. The AI changes a function to compute totals from the database instead of in memory, and the in-memory accumulator variable, the `items` parameter that fed it, and the little `sumLineItems` helper two screens down are all suddenly jobless. The edit works. The orphans stay, because the model's change was scoped to the lines that needed to *change*, and the lines that needed to *go* weren't on that list.

Each orphan is a small lie about the code. An unused parameter tells every caller they must supply something that does nothing — and callers will keep constructing that argument, sometimes expensively, forever. An unused variable implies state that matters. A jobless helper invites the next developer to maintain, test, and even extend it. Sufficiently old orphans become load-bearing in people's mental models: "careful, that function also computes the line-item sum" — no, it doesn't, not since March. Strict linters and compilers catch some of this (Go won't even build), but parameters, exported helpers, and dynamic languages slip through everywhere.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Clean Up Now-Unused Symbols

After every edit, ALWAYS check what your change just orphaned — and remove it. An edit that reroutes logic strands the variables, parameters, helpers, and fields that served the old route; deleting them is part of the edit, not optional cleanup.

Every orphan misleads: an unused parameter forces callers to keep supplying it, an unused helper invites future maintenance of dead weight, an unused variable implies state that no longer exists.

**After changing any logic, sweep for what no longer earns its place:**
- Local variables whose value is now never read (including ones still being *assigned* — assignment isn't use)
- Parameters your change made meaningless — remove them *and* update the call sites (and if the language complains about unused args in interfaces/overrides, use its idiom: `_`, `_unused`, per convention)
- Private helpers, methods, and small functions whose only caller your edit just removed or rewrote — then check whether *their* removal orphans anything further down; follow the chain
- Class fields, struct members, and state entries that nothing reads anymore
- Constants and config values that only the removed code consumed
- Scope check before deleting: confirm the symbol is truly unreferenced project-wide, not just in this file — exported names need a real search, not a glance
- Symbols that were already unused before your session: mention them, don't silently delete unrelated code

**Red flags that you're about to violate this:**
- "The function works now; the rest of the file is unchanged..." (unchanged is not the same as still-needed)
- "That variable might still be useful to someone..."
- "Removing the parameter means touching the callers — too invasive..."
- "I'll leave the helper; it's harmless..."
- "The linter would have flagged it if it were a problem..." (parameters and exports usually aren't flagged)
- Finishing an edit without asking "what did my change just make pointless?"

---

## Why It Works

1. **It frames orphaning as a property of the edit, not the file.** The AI doesn't scan whole files for dead code, and shouldn't have to. Asking "what did *my change* strand" scopes the sweep to exactly the symbols the edit touched indirectly — small, tractable, complete.

2. **It names assignment-isn't-use.** Half of orphaned variables survive because they're still being written to, which pattern-matches as "in use." Making the read/write distinction explicit catches them.

3. **It follows the chain.** Removing a helper's last caller orphans the helper; removing the helper orphans *its* private dependency. One-level sweeps miss the cascade; the instruction makes the recursion explicit.

4. **It separates your orphans from pre-existing ones.** Without that line, the AI either ignores everything (safe, useless) or strips the whole file (unreviewable). Owning exactly the mess you made is both bounded and right.

## Origin

A pricing function was changed to take a precomputed tax rate instead of computing one from an address. The AI made the change cleanly — and left the `address` parameter in place. For over a year afterward, every caller kept building a full address object (one did a geocoding lookup to get it) to pass into a function that never read it. The dead parameter was found during a latency investigation, where removing it and the geocoding call shaved more off p95 than the optimization actually being investigated.
