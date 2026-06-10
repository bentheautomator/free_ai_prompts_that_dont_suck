---
title: Don't Add a Second Pattern for a Solved Problem
slug: dont-add-a-second-pattern-for-a-solved-problem
category: collaboration
tags: [universal, teamwork, conventions]
works_with: all
severity: medium
one_liner: "Stops a second way of doing something the team already standardized"
---

# Don't Add a Second Pattern for a Solved Problem

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from introducing a parallel mechanism for something the codebase already has one standard way of doing.

**[Copy-paste ready version](../../install/dont-add-a-second-pattern-for-a-solved-problem.md)** — just the instruction block, no explanation.

## The Problem

The team standardized on one HTTP client wrapper, one validation library, one way to define feature flags, one pattern for background jobs. The AI, asked to add a feature, doesn't know any of that. It reaches for whatever it considers idiomatic and introduces pattern number two: a raw `fetch` call next to the team's instrumented client, a hand-rolled retry loop next to the shared one, `zod` in a codebase that standardized on `joi`. The feature works. The codebase now does the same thing two ways.

Two patterns is not twice as expensive as one — it's worse. Every future reader has to know both. Every cross-cutting change (add tracing, change timeouts, swap a dependency) now has two implementations to find and update, and the second one gets missed because nobody knew it existed. The team's standard stops being a standard the moment a second pattern survives review, and each new instance makes the next one easier to justify.

The AI defaults to this because it optimizes for the task in front of it using patterns from its training data, not patterns from this repo. The team's convention is discoverable — it's sitting right there in the neighboring files — but discovering it requires looking before writing, which is exactly the step the AI skips.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Add a Second Pattern for a Solved Problem

NEVER introduce a new way of doing something the codebase already does one way. Before writing any infrastructure-flavored code — HTTP calls, validation, config access, logging, queues, caching, dependency injection — find how this codebase already does it, and do that.

A second pattern doubles maintenance forever: every reader learns both, every sweep updates both, and one of them always gets missed.

- Search for existing usage first. If three files make HTTP calls through `lib/http.ts`, your fourth file does too — even if you'd have built it differently.
- Match the existing pattern even when it's mediocre. Mediocre-and-uniform beats good-and-fragmented in shared code.
- Do not add a dependency that duplicates an existing one's job (a second validation lib, a second date lib, a second test mocking tool). Use the incumbent.
- If the existing pattern genuinely cannot do what the task needs, say so explicitly and propose extending the standard pattern — don't quietly route around it.
- If you believe the standard is bad enough to replace, that's a proposal for the team, not a decision to make inside a feature branch.

**Red flags that you're about to violate this:**
- "The idiomatic way to do this is X, regardless of what's here."
- "Their wrapper is clunky; calling the library directly is cleaner."
- "It's just one place, it doesn't need the full standard setup."
- "I'll add this small library; it's better than the one they use."
- "The existing pattern doesn't quite fit, so I'll roll my own here."

---

## Why It Works

1. **It forces a search-before-write step**, which is the only point where the team's convention can actually influence the AI — after the code exists, the second pattern is already born.
2. **It names the real cost function** — patterns are priced by how many exist, not how good each one is, and the AI's "cleaner" alternative is a net loss the moment it's pattern number two.
3. **It gives disagreement a legal exit** (propose extending the standard) so the AI isn't choosing between "use a pattern I dislike" and "sneak in my own."
4. **It covers dependencies, not just code**, closing the common loophole where the second pattern arrives via `package.json`.

## Origin

A codebase had a shared API client that attached auth, tracing, and retries. An assistant adding a small integration used raw `fetch` because the wrapper "wasn't needed for one call." Eight months later there were eleven raw calls copied from that first one. When the auth token format changed, the wrapper was updated in one place — and the eleven copies failed in production over the following week, one integration at a time, each looking like a fresh incident.
