---
title: Don't Swap Hand-Rolled Code for a Library
slug: dont-swap-handrolled-code-for-a-library
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: high
one_liner: "Keeps hand-rolled code that handles edge cases the shiny library does not"
---

# Don't Swap Hand-Rolled Code for a Library

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from replacing a battle-tested in-house implementation with a modern library that covers the general case and none of the local ones.

**[Copy-paste ready version](../../install/dont-swap-handrolled-code-for-a-library.md)** — just the instruction block, no explanation.

## The Problem

A 400-line hand-rolled CSV parser is an affront to everything an AI assistant believes. There's a library for that. The library is maintained, documented, tested by thousands of users — replacing the artisanal version is the obvious modernization, and the assistant will propose it unprompted.

What the assistant can't see is why the parser is 400 lines. It started as 40. The other 360 accumulated one production incident at a time: the partner whose exports use a BOM and a nonstandard delimiter on Tuesdays, the legacy system that escapes quotes wrong, the encoding fallback for files from an acquisition's mainframe, the size guard from the day someone uploaded 9GB. The hand-rolled code isn't a worse implementation of the general problem. It's the only implementation of the *local* problem — the actual, cursed inputs this system receives. The general-purpose library handles the spec beautifully and chokes on the partner's Tuesday exports, because the spec never met that partner.

This isn't a rule against libraries. It's a rule against assuming feature parity from category parity: "both parse CSV" doesn't mean "both parse our CSV."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Swap Hand-Rolled Code for a Library

NEVER replace a long-lived hand-rolled implementation with a library on the assumption that the library does the same job. The in-house version's extra bulk is usually accumulated edge-case handling for this system's actual inputs — coverage the general-purpose library does not have and does not advertise lacking.

Before proposing or performing such a swap:

- Inventory the hand-rolled version's behavior, branch by branch. Every conditional that looks paranoid is a candidate edge case someone hit. `git log` on the file usually maps branches to incidents.
- Diff that inventory against the library's documented behavior. The question is not "does the library parse CSV" but "does the library reproduce these 17 specific behaviors," answered one by one.
- Pay attention to the unglamorous parts: encoding fallbacks, size limits, malformed-input tolerance, locale handling, error messages other code may parse. Libraries are strict where battle-tested code learned to be lenient.
- If the swap is requested and the inventory checks out, keep the old implementation callable behind a flag or in history-recoverable form for one release, and run both against real recorded inputs where possible.
- If you can't verify parity, say exactly that: "The library covers the standard cases; I cannot confirm it handles X, Y, Z, which the current code explicitly does."

Age plus production exposure is test coverage that no library changelog can match.

**Red flags that you're about to violate this:**
- "There's a well-maintained library for this; hand-rolling it is NIH syndrome."
- "This 400-line parser can be replaced with three lines."
- "The library passes its own test suite, so it's safe."
- "All this extra handling is probably for inputs that never happen."
- "Modern libraries handle edge cases better than old custom code."
- "If an edge case breaks, we'll find out quickly and patch it."

---

## Why It Works

1. **It reframes line count as evidence.** The AI reads 400 lines as bloat; the instruction reads it as a ledger of incidents, which makes "replace with 3 lines" sound like what it is — deleting 397 lines of answers.
2. **Branch-by-branch parity is falsifiable.** "The library does the same thing" is a vibe; "the library reproduces behaviors 1 through 17" is a checklist the AI can actually fail, and failing it stops the swap.
3. **It names where libraries lose:** leniency. General-purpose code rejects what battle-tested code learned to accept, and telling the AI this asymmetry exists makes it look for exactly those branches.
4. **Replay against real inputs beats both test suites,** because the local quirks live in the local data, not in anyone's fixtures.

## Origin

A team's hand-rolled retry-and-parse layer for a logistics vendor's API was replaced with a popular HTTP client's built-in retry plus a standard parser — a diff that deleted 600 lines and got an enthusiastic review. The old code had silently tolerated the vendor's habit of returning HTTP 200 with an HTML error page during their nightly maintenance window, retrying after a parse sniff. The library saw a 200, parsed garbage, and propagated it. Shipment statuses went quietly wrong between 2 and 3 a.m. for a week before a warehouse called. The 600 lines came back, this time with a comment block titled "READ THIS BEFORE REPLACING WITH A LIBRARY."
