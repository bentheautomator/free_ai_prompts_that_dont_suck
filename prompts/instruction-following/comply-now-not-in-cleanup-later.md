---
title: Comply Now Not in Cleanup Later
slug: comply-now-not-in-cleanup-later
category: instruction-following
tags: [universal, rules, process]
works_with: all
severity: medium
one_liner: "Rule compliance deferred to a cleanup pass that never comes"
---

# Comply Now Not in Cleanup Later

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deferring rule compliance to a "later pass" that never happens.

**[Copy-paste ready version](../../install/comply-now-not-in-cleanup-later.md)** — just the instruction block, no explanation.

## The Problem

"I'll add the required docstrings in a final pass once the logic is settled." "I'll wire up the error envelope at the end so I'm not repeating myself." "Let me get everything working first, then bring it in line with the conventions." Each deferral sounds like sequencing, not skipping — the rule is still going to be followed, just *later*. Then the task hits its natural end (it works, the user is satisfied, attention moves on) and the cleanup pass silently falls off the end of the session.

The deferral works as a rationalization precisely because it never says no to the rule. It says "yes, after" — and "after" is a place where work goes to not happen. Sessions end at "it works," not at "it complies"; context windows fill; the user says "great, next thing" and the queued compliance evaporates without anyone deciding to drop it. Worse, deferred compliance is costlier compliance: docstrings written while the logic is fresh take minutes, the same docstrings reconstructed at the end take real effort, which makes the pass even less likely to survive.

A rule followed "later" has, in the observable record of most sessions, simply not been followed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Comply Now Not in Cleanup Later

Apply rules AS you do the work, not in a deferred cleanup pass. NEVER queue compliance for "later" — later is where compliance goes to die.

**The core problem:** Deferring a rule feels like sequencing, not skipping — "yes, after" instead of "no." But sessions end at "it works," not at "it complies," so the queued pass silently falls off the end. Nobody decides to drop the rule; it just never gets its turn.

**Do this:**

- Satisfy each rule at the moment its trigger occurs: docstring when the function is written, error envelope when the endpoint is created, changelog entry when the change is made
- Treat rule compliance as part of the definition of "this piece is done" — a function without its required docstring is an unfinished function, not a finished one awaiting polish
- If the user EXPLICITLY approves batching ("do the docs at the end"), keep a visible list of the deferred items and clear it before declaring the task complete
- When you catch yourself about to defer, notice that complying now is also cheaper now: the context is fresh, the reconstruction cost is zero

**Do not:**

- Use "once the logic settles" as a standing reason — logic is always about to settle
- Declare a task done with compliance still queued
- Let "I'll mention the remaining items" substitute for doing them

**Red flags that you're about to violate this:**

- "I'll handle the conventions in a final pass"
- "Let me get it working first"
- "It's more efficient to batch all the docs at the end"
- "The important part is done; the rest is polish"
- "I'll note the missing pieces so they can be added later"

---

## Why It Works

1. **It names where deferred work goes.** The rationalization survives because "later" sounds like a real place. Stating the actual session dynamics — sessions end at "it works," queued passes fall off the end with no decision made — removes the imagined future in which compliance happens.

2. **It redefines unit completion.** Folding the rule into "this piece is done" means there is no compliant-later state to defer into: the function without its docstring isn't done-pending-polish, it's not done. Deferral becomes visible as incompleteness.

3. **It exposes the cost inversion.** Deferring is pitched as efficiency, but compliance is cheapest at the moment of work and most expensive at reconstruction time. Making that explicit deletes the efficiency argument the deferral rides on.

4. **It legalizes real batching with a ledger.** Sometimes end-batching is genuinely fine — when the user chose it. The explicit-approval-plus-visible-list path keeps that option while making "cleared before done" a hard gate.

## Origin

A project required every new endpoint to ship with an entry in the API reference. An assistant built out seven endpoints across a long session, noting each time that it would "compile the reference entries at the end for consistency." The session ended at the seventh endpoint working; the compile step never ran. The gap surfaced six weeks later when a partner integrated against the reference and filed a bug for each endpoint that "didn't exist." Reconstructing seven entries from cold code took most of a day. Writing each one inline would have taken about five minutes, while everything was still warm.
