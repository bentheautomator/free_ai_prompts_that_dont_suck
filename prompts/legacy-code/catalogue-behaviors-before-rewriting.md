---
title: Catalogue Behaviors Before Rewriting
slug: catalogue-behaviors-before-rewriting
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: high
one_liner: "Forces a behavior inventory of the old stack before any rewrite begins"
---

# Catalogue Behaviors Before Rewriting

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from rewriting legacy code in a new stack from its apparent intent, instead of from an inventory of what the old code observably does.

**[Copy-paste ready version](../../install/catalogue-behaviors-before-rewriting.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant to port a legacy module to a new stack and it does something subtle: it reads the old code, forms an idea of what the module is *for*, and implements that idea cleanly in the new stack. The rewrite captures the module's intent and discards its behavior — and consumers integrate against behavior. The old endpoint set a quirky header, returned errors in a particular shape, sorted results as a side effect of its query, trimmed whitespace on one field, and emitted an event nobody documented. The rewrite does "the same thing" at the intent level and differs in nine observable ways, each one somebody's integration.

This is rewriting from memory of a thing the AI never actually measured. The old system's spec doesn't live in anyone's head or any document; after enough years, the code's observable behavior *is* the spec, and the only way to preserve it is to enumerate it first. Skipping the enumeration doesn't skip the work — it moves it after the deploy, where each missed behavior is discovered by the consumer that depended on it, one incident at a time.

The fix is sequencing, not effort: the same attention spent cataloguing before writing costs a fraction of what it costs as post-launch bug reports.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Catalogue Behaviors Before Rewriting

NEVER begin reimplementing legacy code in a new stack, framework, or language until you have produced a written inventory of the old code's observable behaviors. The rewrite's spec is what the old code does, not what it appears to be for — and "what it does" must be enumerated, not intuited.

Before writing any replacement code:

- Build the behavior inventory from the old implementation: inputs accepted (including malformed ones it tolerates), outputs produced (exact shapes, formats, field names, ordering), side effects (writes, events, logs, metrics, emails), error behavior (which failures produce which statuses, messages, and partial states), and timing characteristics consumers may rely on.
- Read the old code's tests as recorded behavior, but don't trust them as complete — legacy test suites cover what once broke, not what consumers use.
- Mark every inventory entry as preserve, change deliberately, or unknown. "Unknown" entries get investigated or flagged to the user — they don't get silently resolved by whatever the new stack does by default.
- Present the inventory before the rewrite for anything non-trivial, so the user can veto wrong assumptions while they're still cheap.
- Implement against the inventory and verify against it: each preserved behavior should be checked in the new implementation, ideally by running old and new against the same recorded inputs.

If the inventory feels tedious, that's the tedium of the spec you were about to skip.

**Red flags that you're about to violate this:**
- "I understand what this module is supposed to do, I'll build that."
- "The new framework handles errors better, consumers won't mind the new shape."
- "These quirks are implementation details, not behavior anyone uses."
- "The old tests pass against my rewrite, so it's equivalent."
- "I'll handle discrepancies as they come up after the switch."
- "The cleanest design in the new stack is close enough to the old one."

---

## Why It Works

1. **It replaces intent with inventory as the rewrite's input.** Intent is a lossy summary the AI generated; the inventory is enumerated fact. Building from the second makes behavior preservation a checklist instead of an aspiration.
2. **The preserve/change/unknown triage makes drops deliberate.** Behaviors can still be changed in a rewrite — but each change becomes a marked decision someone approved, not a silent casualty of the new stack's defaults.
3. **It exploits Hyrum's Law proactively:** since consumers depend on observable quirks, the inventory deliberately includes quirks — headers, ordering, error strings — that an intent-level reading classifies as noise.
4. **Pre-rewrite presentation moves the review to where it's cheap.** A wrong assumption costs a sentence to fix in an inventory and an incident to fix in production.

## Origin

A legacy PHP order-export endpoint was rewritten as a service in the new stack. The rewrite was faithful to the endpoint's purpose and diverged in details nobody catalogued: date fields gained timezone suffixes, the CSV column order changed, and a failure mid-export now returned an error instead of the old behavior — a truncated file with the rows completed so far. One partner's nightly import parsed columns by position; another had built its resume logic around truncated files. Both integrations failed the first night. The post-incident fix began with what should have been the first deliverable: a list, two pages long, of everything the old endpoint actually did.
