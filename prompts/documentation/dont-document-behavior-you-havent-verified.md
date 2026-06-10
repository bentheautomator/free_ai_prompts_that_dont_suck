---
title: Don't Document Behavior You Haven't Verified
slug: dont-document-behavior-you-havent-verified
category: documentation
tags: [universal, docs]
works_with: all
severity: high
one_liner: "Confidently documenting behavior the AI assumed but never actually checked"
---

# Don't Document Behavior You Haven't Verified

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing authoritative-sounding documentation for behavior it inferred, assumed, or hallucinated rather than verified.

**[Copy-paste ready version](../../install/dont-document-behavior-you-havent-verified.md)** — just the instruction block, no explanation.

## The Problem

Asked to "document the caching layer," the AI produces a beautiful page: TTL is 5 minutes, entries are evicted LRU, cache keys include the tenant ID. It reads like the work of someone who knows the system. Except the TTL is configurable and defaults to 30 seconds, eviction is FIFO, and tenant ID was removed from the key two refactors ago. The AI didn't read the eviction code; it wrote what caching layers *usually* do, in the register of someone who checked.

This is the documentation-specific version of hallucination, and it's nastier than hallucinated code. Hallucinated code fails to compile or fails a test. Hallucinated docs pass every check a doc can face, because docs face none. The model's fluency works against the reader: plausible-sounding specifics ("5 minutes," "LRU") are precisely the details people copy into design docs and incident timelines.

Docs written this way are pre-stale: wrong from the moment of writing, with the authority of the repo behind them.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Document Behavior You Haven't Verified

NEVER write documentation stating how the system behaves unless you verified that behavior against the actual code, config, or output. Plausible is not verified.

The problem: documentation hallucination produces confident, specific, wrong claims that readers treat as ground truth precisely because they are written down.

Rules:
- Before documenting a default, limit, timeout, ordering, or format, find the line of code or config that defines it, and document what that line says
- Before documenting what a command or endpoint returns, run it or read the code path that produces the response; do not document from the function name
- Distinguish your sources in your own head: read-the-code facts, ran-it facts, and assumed facts. Only the first two go in docs as statements
- If something can't be verified right now (external service, missing credentials), either omit it or mark it visibly: "Unverified: appears to retry 3 times based on `MAX_ATTEMPTS`"
- Never let general knowledge fill gaps. What caching layers, queues, or ORMs "usually do" is not what this one does
- Specific numbers are the highest-risk claims. Every concrete value in your doc needs a concrete source in the repo

**Red flags that you're about to violate this:**
- "This is how these systems typically work..."
- "The function name implies it returns JSON..."
- "I'll fill in a reasonable default value..."
- "Checking the actual code would take too long for a doc..."
- "It almost certainly retries; everything retries..."
- "The doc reads better with a specific number..."

---

## Why It Works

1. **It requires a source per claim, not a vibe per section.** "Verify the doc" is too coarse to act on; "every concrete value needs a defining line in the repo" is a per-fact discipline the model can actually execute.

2. **It separates the three knowledge tiers.** Models blend read, ran, and assumed into one confident voice. Forcing the distinction makes assumed facts visible before they're laundered into prose.

3. **It legitimizes marked uncertainty.** Models hallucinate partly because gaps feel like failures. An approved "Unverified:" escape hatch makes honesty cheaper than invention.

4. **It flags numbers as the threat surface.** Specific values are what readers copy and act on, and they're also what models most readily invent. Concentrating verification there buys the most safety per check.

## Origin

An onboarding doc written by an assistant stated that the message bus guaranteed at-least-once delivery with ordering per partition key. The bus in question guaranteed neither; the doc described a different, more famous product. A new engineer designed a billing consumer around the documented guarantees, and the missing-message bug it shipped took two weeks to trace because everyone debugging it had read the same doc and ruled out the bus first.
