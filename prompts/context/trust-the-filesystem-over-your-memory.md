---
title: Trust the Filesystem Over Your Memory
slug: trust-the-filesystem-over-your-memory
category: context
tags: [universal, grounding, verification]
works_with: all
severity: high
one_liner: "AI overriding what tools just showed it because memory insists otherwise"
---

# Trust the Filesystem Over Your Memory

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from explaining away fresh tool output that contradicts what it expected to find.

**[Copy-paste ready version](../../install/trust-the-filesystem-over-your-memory.md)** — just the instruction block, no explanation.

## The Problem

The AI greps for a function it's certain exists. Zero matches. Now comes the fork in the road: update the belief, or explain away the evidence. Too often it's the latter — "the search tool must not have indexed it," "it's probably generated at build time," "let me look in a different way" (then quietly proceeding as if it exists anyway). The expectation came from pattern-matching; the grep came from the actual repo; and the AI sided with the pattern. Fresh evidence lost to stale conviction.

This shows up wherever expectation and observation collide: a file read that doesn't contain the "remembered" code, an `ls` missing the directory the AI was sure existed, a config file shorter than expected, a command output that contradicts the narrative. The signature move is rationalizing the discrepancy instead of updating on it — inventing tool failures, partial reads, and indexing problems to protect the prior. Then actions proceed on the imagined version: editing toward code that isn't there, importing what grep said doesn't exist.

Tools are occasionally wrong — wrong scope, wrong flags. But the legitimate response to suspicion is a *better look*, not a conclusion that the look can be skipped because memory knows best.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Trust the Filesystem Over Your Memory

ALWAYS treat fresh tool output as overriding your expectations, however confident those expectations feel. When a read, search, or listing contradicts what you believed, the belief is what's wrong — your expectations come from patterns, the output comes from this repo, and only one of those is evidence.

The failure isn't holding a wrong expectation; it's explaining away the observation that just corrected it.

**When observation contradicts expectation:**
- Update immediately: zero grep matches means it's not where you searched, not "the tool missed it"; a file without the remembered code means the memory was wrong or stale
- Suspect the tool only via a better observation, never via your prior: re-run with broader scope, different casing, the repo root — if the better look also says no, the answer is no
- Never proceed on the expected version: don't write imports for symbols the search didn't find, don't edit toward file contents the read didn't show, don't describe structure the listing didn't contain
- Say the surprising thing out loud: "I expected a helper here and there isn't one" — surfacing the delta beats silently splitting the difference between memory and disk
- Treat each contradiction as information about your other beliefs: if you were wrong about this file's contents, your unverified beliefs about its neighbors deserve checking too
- Do not invent mechanisms to reconcile the gap — "probably generated at build time," "maybe gitignored" are hypotheses to *check* (look at the codegen config, read `.gitignore`), not blankets to proceed under

**Red flags that you're about to violate this:**
- "The search must have missed it..."
- "It's probably generated, so it not existing is fine..."
- "I clearly remember this file containing..."
- "The read may have been truncated; I'll go with what I remember..."
- "Odd that it's not there — anyway, as I was saying..."
- Acting on the version of reality from before the tool output that contradicted it

---

## Why It Works

1. **It assigns evidential rank.** "Expectations come from patterns, output comes from this repo" gives a strict ordering for conflicts, removing the discretion the AI currently uses to let confident memories outvote observations.

2. **It relocates legitimate doubt.** Tools *are* sometimes misused, and the AI knows it — that's the loophole. Routing all suspicion into "a better observation" keeps the healthy skepticism while closing the proceed-on-memory exit.

3. **It converts reconciliation stories into checkable hypotheses.** "Probably generated" with a pointer to the codegen config is investigation; without one, it's anesthesia. The rule preserves the first and bans the second.

4. **It propagates the update.** One disproven belief is evidence about the belief-forming process; prompting a check of neighboring assumptions turns each surprise into calibration instead of an isolated patch.

## Origin

An AI was sure a service had a `RetryPolicy` class — it had "seen" it while reasoning about the architecture. Grep found nothing. The AI concluded the class was "likely generated from the proto definitions" and wrote three call sites against it. Nothing generated it; the class existed only in the AI's pattern-memory of how services like this usually look. The build failed, and the fix-it session that followed nearly created `RetryPolicy` from scratch to satisfy the phantom call sites — fiction bootstrapping itself into the codebase, stopped only by a reviewer asking where the class was supposed to come from.
