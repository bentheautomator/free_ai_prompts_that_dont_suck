---
title: Flag Risks Before They Bite
slug: flag-risks-before-they-bite
category: communication
tags: [universal, risk]
works_with: all
severity: high
one_liner: "Delivering risky changes without telling the user where they can blow up"
---

# Flag Risks Before They Bite

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from handing over a change without mentioning the conditions under which it explodes.

**[Copy-paste ready version](../../install/flag-risks-before-they-bite.md)** — just the instruction block, no explanation.

## The Problem

An AI assistant knows things about its own changes that it doesn't say. It knows the migration it wrote locks the table while it runs. It knows the regex it tightened will now reject inputs that used to pass. It knows the retry logic it added could hammer a downstream service if that service starts erroring. This knowledge is sitting right there in the context that produced the code — and the handoff message says "Migration script ready to run!" The risk wasn't hidden; it was simply never promoted from the model's working state into a sentence.

Tradeoffs are the costs an approach pays by design; risks are the conditional failures — things that go wrong only if the table is big, the traffic is high, the input is weird, the rollback is needed. Models under-report them for a structural reason: a risk is a hypothetical, and summaries are built from actuals. Nothing in "describe what you did" prompts the model to enumerate the futures in which what it did goes badly.

The person running the migration is the last line of defense, and they can only defend against risks they've heard of. "Locks the table — run it during the maintenance window" costs one sentence to say and an outage not to.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Flag Risks Before They Bite

ALWAYS deliver risky work with its warning label attached. Anything you produce that can fail conditionally — under load, at scale, on bad input, during rollout, on rollback — gets those conditions stated when you hand it over, not after they trigger.

The core problem: you know the failure conditions of your own changes while writing them, but summaries report actuals, not hypotheticals, so the warning never becomes a sentence.

- For any operational change (migrations, scripts, config, infra), state: what can go wrong, under what conditions, how bad, and what to do about it. One line per risk is enough
- Good: "Heads up: this migration rewrites the orders table and will lock it — at your row count, likely minutes. Run in a maintenance window. It is not reversible after step 2"
- Bad: "Migration script ready to run!"
- Flag behavior-tightening especially: anything that now rejects, blocks, expires, or rate-limits what previously passed. Name who hits the new wall
- State the rollback story explicitly: "reversible via X" or "not reversible past Y" — never leave it implied
- Scale-sensitivity counts as a risk: "fine at thousands of rows, untested logic at millions"
- Don't drown the signal: two or three real risks, ranked. A twenty-item boilerplate risk list is its own way of hiding the one that matters

**Red flags that you're about to violate this:**
- "The lock only matters on huge tables, theirs is probably fine..."
- "They're experienced, they know migrations lock things..."
- "Listing failure modes makes my work look fragile..."
- "It worked in my run, the edge conditions are speculative..."
- "I'll cover risks if they ask what to watch out for..."
- "The deadline pressure means they want go, not caution..."

---

## Why It Works

1. **It adds a hypotheticals pass to a process that only reports actuals.** The model's summary generator answers "what happened." The four-part risk template — what, when, how bad, what to do — is a different question the model demonstrably can answer, but only when asked. The instruction is the asking.

2. **The required rollback sentence converts silence into a claim.** "Reversible or not" left implied defaults to the reader assuming reversible. Forcing one of two explicit statements means the dangerous case can no longer be communicated by omission.

3. **The two-or-three cap blocks the compliance-theater failure.** Risk instructions often produce CYA lists that bury the real hazard under boilerplate. Capping and ranking makes the list a judgment, not a disclaimer — and judgments get read.

## Origin

A developer asked an assistant for a script to backfill a new column from an events archive. The script was correct, and the handoff note was a single proud sentence. Unsaid: the script held the full archive in memory, fine on the staging dataset, and on production's archive it OOM-killed the box that also ran the job scheduler. "This loads everything into RAM — for production, stream it or run it somewhere disposable" was knowledge the model had and a sentence it never wrote.
