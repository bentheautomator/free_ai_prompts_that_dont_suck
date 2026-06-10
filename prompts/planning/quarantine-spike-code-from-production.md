---
title: Quarantine Spike Code From Production
slug: quarantine-spike-code-from-production
category: planning
tags: [universal, planning]
works_with: all
severity: medium
one_liner: "The proof-of-concept that got promoted to production by inertia"
---

# Quarantine Spike Code From Production

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents exploratory throwaway code from quietly becoming the shipped implementation.

**[Copy-paste ready version](../../install/quarantine-spike-code-from-production.md)** — just the instruction block, no explanation.

## The Problem

Spikes are good planning: write something quick and dirty to answer "can the PDF library handle our templates?" before committing to an approach. The failure is what happens after the answer comes back yes. The spike — hardcoded paths, swallowed exceptions, no tests, a TODO that says "obviously rewrite this" — is sitting right there, and it *works*. So instead of writing the real implementation informed by the spike, the assistant starts patching the spike. Rename a variable here, extract a function there, and the proof-of-concept has been promoted to production without anyone deciding to do that.

The promotion happens by inertia because deleting working code feels wasteful and rewriting feels redundant. But spike code carries its origin everywhere: it was written to answer one question on one happy path, so its structure ignores every concern the question excluded — errors, concurrency, configuration, the second use case. Patching adds those concerns onto a skeleton that wasn't shaped for them, which is how you get production code where error handling is visibly bolted on.

The fix is deciding the spike's fate at birth: it exists to produce an answer, and the answer — not the code — is the deliverable.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Quarantine Spike Code From Production

ALWAYS declare exploratory code as a spike before writing it, and treat the spike's output as knowledge, not code. The deliverable of a spike is an answer; the code is the wrapper it came in.

The core problem: a working spike is sitting right there when implementation starts, and patching it forward feels cheaper than rewriting — so the throwaway version ships, structurally shaped by everything the exploration ignored.

- Before exploratory coding, say what question the spike answers and what "answered" looks like. A spike without a question is just coding without standards.
- Keep spikes physically separate: a scratch directory, a clearly named branch, anywhere that isn't the real module layout. Code in the right place gravitates into the product.
- When the question is answered, state the answer explicitly ("yes, the library handles nested tables, but only via the streaming API") — that sentence is what the spike was for.
- Then write the production version fresh, informed by the spike. Reuse the knowledge freely; reuse lines of code only when a line would be identical in a from-scratch version.
- If you find yourself adding error handling, config, or tests to spike code, stop — you are renovating a tent. Build the building.

**Red flags that you're about to violate this:**
- "The prototype basically works, I'll just clean it up..."
- "Rewriting this would be wasted effort..."
- "I'll productionize it incrementally..."
- "It's already passing the manual test..."
- "I'll add proper error handling to the spike later..."

---

## Why It Works

1. **It assigns the spike a deliverable that isn't code.** When the answer is the output, throwing away the code is completing the spike, not wasting it. Without that frame, deletion feels like loss and inertia wins.

2. **It uses physical separation as friction.** Spike code in `scratch/` requires a deliberate act to ship; spike code in `src/services/` ships by staying put. The directory is the decision.

3. **It names the structural defect, not just the cosmetic one.** Cleanup fixes naming and style; it cannot fix that the skeleton was shaped by a single happy path. "Renovating a tent" gives the assistant a reason rewrites aren't redundant.

## Origin

A spike to test whether a vendor's OCR API could read invoice line items answered the question in ninety minutes — yes, with preprocessing. The spike script then absorbed a retry loop, then S3 paths, then a queue consumer wrapper, and shipped. Six months on, it was the invoice pipeline: no timeout handling (the spike never needed one), credentials in a constant (the spike ran locally), and a hardcoded `pages=[0]` from the original test invoice that silently dropped page two of every multi-page invoice in production.
