---
title: Shrink the Reproduction Before Debugging
slug: shrink-the-reproduction-before-debugging
category: debugging
tags: [universal, debugging, root-cause]
works_with: all
severity: medium
one_liner: "AI debugging inside the whole app when a 10-line repro would isolate the bug"
---

# Shrink the Reproduction Before Debugging

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from hunting a bug across an entire application when the failing behavior could be isolated to a few lines first.

**[Copy-paste ready version](../../install/shrink-the-reproduction-before-debugging.md)** — just the instruction block, no explanation.

## The Problem

The bug reproduces by clicking through four screens of the full app, with the real database, behind login. So the AI debugs *there* — re-running the whole flow after every theory, reading code across a dozen modules because any of them is technically in the loop, drowning in variables that have nothing to do with the failure. Every iteration costs minutes, every observation is contaminated by a hundred moving parts, and the search space stays the size of the application.

Experienced debuggers shrink first: cut the repro down until removing anything more makes the bug disappear. Same failing payload, but fed straight into the parsing function in a five-line script. Same query, run directly instead of through three service layers. Each component you remove without losing the failure is a component *proven innocent* — shrinking isn't preparation for the diagnosis, it largely *is* the diagnosis. When a 200,000-line repro becomes a 10-line one, the bug has maybe two places left to hide.

AI assistants skip this because shrinking feels like overhead — building a harness instead of "actually debugging" — and because the full repro already exists while the minimal one must be made. So they pay the full-app iteration tax twenty times instead of building the fast loop once.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Shrink the Reproduction Before Debugging

Before deep-diving a bug that reproduces only through a large system, ALWAYS try to shrink the reproduction: strip away components, steps, and data until what remains is the smallest thing that still fails.

Every element you remove without losing the failure is an element proven innocent. Minimization is not prep work before the diagnosis; it is the diagnosis, running at high speed.

- Ask of the current repro: what can I delete? The UI (call the function directly), the network (use the captured payload), the database (use the literal failing row), auth, middleware, the other 95% of the input file
- Shrink the data too: cut the failing input in half repeatedly, keeping whichever half still fails; a 4MB "bad file" usually reduces to one bad line
- Keep the failure identical while shrinking — same error, same wrong value; if the symptom changes, you've cut something load-bearing, so put it back
- A fast repro changes everything downstream: aim for one command, seconds to run, so each later hypothesis costs seconds instead of minutes
- Know when to stop: if an hour of shrinking isn't converging, debug with what you have — minimization serves the investigation, not the other way around
- Keep the minimal repro when done; it's the regression test waiting to be committed

**Red flags that you're about to violate this:**
- "I'll just re-run the full flow each time to test theories..."
- "Too many layers are involved to isolate this; I'll read through all of them..."
- "Setting up a minimal case is overhead; let me start hypothesizing..."
- "The bug needs the whole app running..." (have you tried without?)
- Five debugging iterations done, each costing minutes of full-system setup
- Reading your eighth file while the failing function could be called directly with the failing input

---

## Why It Works

1. **It reframes shrinking as elimination.** "Each removed component is proven innocent" converts minimization from perceived overhead into visible progress on the actual question, which is what the AI thought it was skipping toward.

2. **It attacks the iteration tax.** Debugging cost is hypothesis count times repro cost; the instruction targets the multiplier the AI never thinks to optimize because the existing repro "already works."

3. **It includes data minimization.** Half the wins come from cutting the input, not the system — a step assistants almost never take unprompted because the input feels like a given.

4. **It bounds the technique.** The stop condition prevents the failure mode from inverting into endless harness-polishing, which keeps the rule credible enough to follow.

## Origin

A document-import feature corrupted certain uploads, and an assistant spent a long session theorizing across the upload controller, the queue, the storage layer, and the parser — re-running the full import flow each time. A developer took the one failing document and cut it in half until a single paragraph still triggered the corruption: it contained a right-to-left override character that the sanitizer mangled. From first cut to root cause took twenty minutes, and the minimal file went straight into the test suite.
