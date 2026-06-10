---
title: Prototype Means Prototype
slug: prototype-means-prototype
category: scope
tags: [universal, scope, over-engineering]
works_with: all
severity: medium
one_liner: "AI production-hardening a throwaway prototype with auth and rate limits"
---

# Prototype Means Prototype

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from burying a quick prototype or demo under production hardening nobody wanted yet.

**[Copy-paste ready version](../../install/prototype-means-prototype.md)** — just the instruction block, no explanation.

## The Problem

"Throw together a quick prototype that fetches the feed and renders it, just to see if the idea works." What comes back: the fetch and render, plus an auth middleware, request rate limiting, input validation on every boundary, structured logging, a Dockerfile, health-check endpoints, and graceful shutdown handling. The idea being tested is now 80 lines somewhere inside 600 lines of operational armor.

The AI does this because "production-ready" is its default register for code that looks serious, and words like "quick," "rough," "spike," and "just to test" don't reliably switch it off. But a prototype's entire value is speed and legibility: it exists to answer a question cheaply. Hardening it makes the answer slower to get and harder to see — reviewers can't find the experiment inside the boilerplate, and iterating means dragging the armor along through every pivot. Worse, polish creates false signals: a demo with auth and health checks reads as further along than it is, and more than one prototype has been promoted to production precisely because it looked ready.

The skill being requested is restraint: build the smallest thing that answers the question, so it can be judged, changed, or deleted in an afternoon.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Prototype Means Prototype

When the user signals throwaway intent ("prototype," "spike," "quick demo," "proof of concept," "just to test"), build the minimum that answers their question. NEVER add production hardening they didn't request.

The core problem: a prototype exists to answer a question cheaply, and every layer of unrequested armor makes the answer slower to reach, harder to see, and falsely production-shaped.

- Happy path only: no auth, rate limiting, input validation, retry logic, logging infrastructure, or graceful shutdown unless the question being tested involves them
- No deployment apparatus: no Dockerfiles, CI configs, health endpoints, or environment-variable plumbing for a script someone will run by hand five times
- Hardcode freely: URLs, credentials placeholders, sample data, and sizes can be literals with a `# placeholder` comment where it matters
- Keep it in as few files as the idea allows; a prototype you can read top to bottom in one sitting is the deliverable
- State the cut corners in one short list at the end ("skipped: auth, error handling, pagination") so nobody mistakes the prototype for more than it is
- If you believe some hardening is genuinely needed even for the test (e.g., the API requires auth to respond at all), include only that piece and say why

**Red flags that you're about to violate this:**
- "Even a prototype should handle errors properly..."
- "I'll add auth now so it's ready when this goes to production..."
- "A Dockerfile makes it easy for anyone to run..."
- "Doing it right from the start saves rework later..."
- "Rate limiting protects the API even during testing..."
- "It only takes a few more minutes to make this robust..."

---

## Why It Works

1. **It defines the prototype's success metric.** The AI optimizes for code quality; restating the goal as "answers the question cheaply and legibly" makes hardening a failure against the actual metric, not a bonus.

2. **It names the false-readiness hazard.** Polish signals maturity; pointing out that hardened prototypes get mistaken for production candidates turns the AI's instinct for polish into a recognized risk.

3. **It legitimizes the shortcuts explicitly.** Permission to hardcode and skip validation removes the quality anxiety that drives armor-plating, and the cut-corners list keeps those shortcuts honest.

4. **It allows need-driven exceptions with justification.** Some hardening is sometimes genuinely required to run the test; demanding a stated reason separates "the API requires it" from "production code should have it."

## Origin

An engineer asked for a quick proof of concept to see whether a vendor's API returned usable category data, expecting fifty lines by lunch. The assistant delivered a containerized service with auth scaffolding, retries, structured logs, and config management; it took the rest of the day to review, and the category data turned out to be unusable, which fifty lines would have revealed by 11 a.m. The entire deliverable was deleted, as prototypes should be, but it cost a day instead of an hour.
