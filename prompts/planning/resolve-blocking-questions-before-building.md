---
title: Resolve Blocking Questions Before Building
slug: resolve-blocking-questions-before-building
category: planning
tags: [universal, planning]
works_with: all
severity: high
one_liner: "Building on top of a question that's still waiting for an answer"
---

# Resolve Blocking Questions Before Building

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents starting work whose shape depends on a question that hasn't been answered yet.

**[Copy-paste ready version](../../install/resolve-blocking-questions-before-building.md)** — just the instruction block, no explanation.

## The Problem

The assistant asks a good question — "should deleted users keep their audit history, or should it cascade?" — and then, without waiting for the answer, keeps building. It picks an answer provisionally ("I'll assume we keep history for now") and constructs the deletion flow, the queries, the tests on top of the assumption. When the real answer arrives and it's "cascade, for GDPR reasons," the provisional work isn't a head start. It's a liability with tests.

The behavior comes from treating idle time as the enemy. Stopping to wait feels like wasted turns, so the assistant fills them with motion — but motion conditioned on an open question isn't progress, it's a bet at even odds with the user's answer as the coin. Worse, the built code becomes gravity: when the answer finally arrives and contradicts the assumption, there's now a sunk implementation arguing for itself, and the assistant (or the user, presented with "I've already built it the first way") gets nudged toward ratifying the guess instead of answering the question on the merits.

The discipline is to sort questions honestly: blocking questions change the shape of the work; non-blocking ones change details that can be swapped later. Blocked work waits or routes around. Only genuinely independent work continues.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Resolve Blocking Questions Before Building

NEVER build on top of an unanswered question that determines the shape of what you're building. Asking a question and then proceeding as if it were answered is worse than not asking — it manufactures sunk cost that lobbies against the real answer.

The core problem: waiting feels like wasted time, so open questions get filled with provisional guesses and the work built on them becomes an argument for ratifying the guess.

- When a question arises, classify it: blocking (the answer changes structure, data model, or user-visible behavior) or cosmetic (the answer swaps a detail). Be honest — "what should happen to the data" is never cosmetic.
- For blocking questions: ask, then *stop building the dependent part*. State clearly what's blocked and why: "Deletion flow is blocked on the audit-history question."
- Fill the wait with genuinely independent work — other tasks, the parts of this task that are identical under every answer — and say that's what you're doing.
- If you must proceed (user unavailable, deadline), say which answer you're assuming, build the minimum that depends on it, and isolate the dependency so it's cheap to flip.
- When the answer arrives, check it against anything built in the meantime instead of checking it against your hopes.

**Red flags that you're about to violate this:**
- "While I wait for the answer, I'll just build it the likely way..."
- "I'll assume yes for now, it's probably yes..."
- "It'd be inefficient to sit idle..."
- "If I'm wrong I'll adjust later..." (you'll have tests defending the wrong version)
- "I've already built option A, so maybe we should just go with A..." (the guess is now lobbying)

---

## Why It Works

1. **It names the sunk-cost manufacturing.** Provisional building doesn't just risk rework — it creates an artifact that biases the eventual decision toward whatever got built. Recognizing the lobbying effect is what makes "just keep moving" stop looking free.

2. **The blocking/cosmetic sort makes waiting selective.** A blanket "wait for all answers" rule would die of impracticality. Classifying questions lets independent work continue honestly while only the genuinely conditioned work pauses.

3. **Isolation caps the bet when proceeding is forced.** Sometimes you must move without the answer. Stating the assumption and confining its tendrils to one swappable spot turns an unbounded rewrite risk into a bounded one.

## Origin

An assistant asked whether a new billing plan should apply to existing subscribers or only new signups, flagged it as important — and then implemented the "existing subscribers too" version over the rest of the session, including a migration that rewrote subscription rows. The answer, next morning, was "new signups only; existing contracts are legally locked." The migration had already run in staging against a copy of production data, and unwinding the proration logic took longer than the original build. The question had been asked correctly. Everything after the question mark was the incident.
