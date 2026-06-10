---
title: Estimate Blast Radius Before Starting
slug: estimate-blast-radius-before-starting
category: planning
tags: [universal, planning, risk]
works_with: all
severity: medium
one_liner: "The 'small change' that turned out to have forty callers"
---

# Estimate Blast Radius Before Starting

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents starting a change without knowing how much of the system it touches — and finding out one broken caller at a time.

**[Copy-paste ready version](../../install/estimate-blast-radius-before-starting.md)** — just the instruction block, no explanation.

## The Problem

"Just change the return type of `getUser` to include the profile" sounds like a one-file edit, so the assistant makes the one-file edit. Then the build breaks in eleven places. It fixes those, which breaks four tests, two of which reveal callers that depended on the old shape in ways that need design decisions, one of which is in a package that other teams consume. What was started as a touch-up is now an unplanned cross-cutting migration, being discovered incrementally, mid-flight, with the codebase red the whole time.

The assistant never asked the question that takes ninety seconds to answer: who uses this thing? A grep for callers, a check of what's exported publicly, a look at whether serialized forms of the type exist in storage or over the wire. Without that, the decision to start was made on the size of the edit, not the size of the consequence — and those differ by an order of magnitude exactly when it matters.

Knowing the blast radius before starting changes the plan itself. Forty callers might mean adding a new method instead of changing the old one, or doing the change behind an adapter, or telling the user this is a bigger job than it looks. All of those options exist only before the first edit.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Estimate Blast Radius Before Starting

ALWAYS measure who depends on a thing before changing it. The size of an edit and the size of its consequences are different numbers, and only the second one matters.

The core problem: changes get green-lit based on how small the diff looks, then the dependents are discovered one breakage at a time, mid-flight, with no plan for them.

- Before modifying a function, type, schema, endpoint, config key, or event: search for its callers/consumers and count them. Actually run the search.
- Check the boundaries: is it exported from the package? Serialized to disk, DB, or wire? Referenced by name in strings, configs, or other repos? Those dependents won't show up as compile errors.
- State the radius in one line before starting: "`getUser` has 23 call sites in 9 files, plus a JSON shape stored in the sessions table."
- Let the radius shape the approach. Many dependents may mean: add-don't-change, adapter layer, staged migration, or flagging to the user that the small request is a large change.
- If the radius is much larger than the user's framing implied ("just change..."), say so before proceeding, not after the build is red.

**Red flags that you're about to violate this:**
- "This is a one-line change..."
- "I'll fix the call sites as the compiler finds them..."
- "It's probably only used in this module..."
- "The type checker will catch everything that breaks..." (not the serialized data, it won't)
- "I'll deal with downstream effects when I see them..."

---

## Why It Works

1. **It replaces guessed radius with measured radius.** "Probably only used here" is a prior; a grep is a fact. The two diverge most on old, central code — exactly the code where divergence hurts.

2. **It moves the consequences into the plan.** Discovered-incrementally dependents get patched however keeps the build green. Known-up-front dependents get a designed migration. Same callers, very different outcomes.

3. **It checks the dark dependents.** Compile errors only reveal statically-linked consumers. Serialized shapes, string references, and external repos fail at runtime, later, in production — the explicit boundary checklist is the only thing that finds them in advance.

## Origin

A request to "rename the `status` field to `state` on the job record" was executed as a find-and-replace plus migration. The grep-for-callers that nobody ran would have shown `status` also flowing into webhook payloads consumed by customer integrations and into JSON blobs already stored in a history table. Internal code was fixed in an afternoon; the webhook breakage surfaced as customer tickets, and the history table needed a backfill script written under pressure. The rename itself was trivial — its radius was the entire week.
