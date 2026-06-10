---
title: Summarize in Plain Language
slug: summarize-in-plain-language
category: communication
tags: [universal, clarity]
works_with: all
severity: medium
one_liner: "Jargon-dense summaries the person who asked cannot actually act on"
---

# Summarize in Plain Language

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents summaries written in implementation jargon that the person who asked can't act on.

**[Copy-paste ready version](../../install/summarize-in-plain-language.md)** — just the instruction block, no explanation.

## The Problem

"Refactored the auth flow to use a memoized JWKS resolver with stale-while-revalidate semantics, eliminating the N+1 introspection calls on the hot path." If you're the person who wrote that subsystem, great sentence. If you're the founder who asked "can you make login less slow?", you have just been told nothing — except, implicitly, that follow-up questions will be answered in the same dialect. The summary is correct, complete, and useless to its actual audience.

Models default to insider register because their training data does: code comments, PRs, and engineering docs are written by implementers for implementers. The model also has a subtle incentive problem — jargon *sounds* competent, and a summary stuffed with precise terminology reads as more skilled than "login was slow because we checked the same thing five times; now we check once and remember the answer." So the dial drifts toward density, regardless of who's reading.

The cost is decisions made on vibes. A reader who can't parse the summary doesn't say so; they nod, extract a sentiment ("sounds like it's fixed"), and move on. The details that needed their judgment — that "stale-while-revalidate" means briefly accepting outdated keys, say — sail past unexamined.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Summarize in Plain Language

ALWAYS write the first paragraph of any summary so a technical outsider could act on it. Plain language first; jargon and precision below, for those who want it.

The core problem: a summary in implementation dialect transmits competence signals instead of information, and readers who can't parse it don't ask — they nod and decide on vibes.

- Open with what changed in cause-and-effect terms: "Login was slow because we re-verified the same keys on every request. Now we verify once and reuse the result for a few minutes"
- State consequences a non-implementer cares about: what gets faster or slower, what now behaves differently, what could break, what it costs
- Then a detail section with the real terminology for technical readers — plain-first does not mean dumbed-down-only
- Every term of art you keep in the opening must pay rent: if "memoized" can be "remembered", it's "remembered"
- Translate the tradeoff, not just the win: "reusing the result for a few minutes means a revoked key works for up to that long — tell me if that's unacceptable"
- Calibrate to the audience you actually have: if the user has been writing systems code at you all session, plain means uncluttered, not babyish

**Red flags that you're about to violate this:**
- "The precise term is more accurate, so I'll use it everywhere..."
- "Anyone working on this project surely knows what JWKS is..."
- "Explaining it simply will come across as condescending..."
- "The technical summary IS the summary, details are what they want..."
- "If they don't understand a term, they'll ask..."

---

## Why It Works

1. **The layering removes the precision objection.** The model resists plain language because it loses information. Plain-first-details-below loses nothing — it just sequences registers — so the model's accuracy instinct stops fighting the instruction.

2. **"Could act on it" is a sharper test than "could understand it."** Understanding is unfalsifiable; action is concrete. A sentence the reader could make a decision from forces consequences into the prose, which is exactly what jargon abbreviates away.

3. **The pay-rent rule operationalizes "plain."** Vague register instructions die at generation time. A word-level test — does this term survive substitution by an everyday phrase? — runs per token, where the failure actually happens.

## Origin

A product manager asked an assistant whether a proposed change to session handling was safe to ship before a marketing launch. The reply discussed idempotent token rotation, refresh skew windows, and clock-drift tolerances for three paragraphs. The PM read it twice, concluded "sounds handled," and approved. The skew-window detail meant some users would be logged out once during the rollout — exactly the kind of thing a launch should schedule around, and exactly the sentence that never appeared in any language the decision-maker spoke.
