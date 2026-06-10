---
title: No Kitchen-Sink Snapshots
slug: no-kitchen-sink-snapshots
category: testing
tags: [universal, testing, snapshots]
works_with: all
severity: medium
one_liner: "Snapshotting entire pages and objects instead of asserting what matters"
---

# No Kitchen-Sink Snapshots

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents giant whole-tree snapshots that fail on everything, specify nothing, and train everyone to update on red.

**[Copy-paste ready version](../../install/no-kitchen-sink-snapshots.md)** — just the instruction block, no explanation.

## The Problem

Asked to test a dashboard component, the AI writes `expect(render(<Dashboard />).container).toMatchSnapshot()` and calls it a day. The resulting `.snap` file is nine hundred lines of serialized DOM: every wrapper div, every generated class name, every aria attribute of every child component, frozen in amber. This "test" now fails whenever *anything* in that tree changes — a padding tweak, a library upgrade, a renamed CSS module — and says nothing about which of those nine hundred lines actually mattered. Nobody can read the diff, so nobody does; the team's reflex calcifies into "snapshot failed, run `-u`," and the test's effective assertion becomes "the output is whatever the output is."

The same abuse happens off the UI: snapshotting whole API responses (timestamps and all), entire config objects, full error structures. AI assistants love the pattern because one line generates the appearance of total coverage with zero thought about what the component promises — no need to identify the contract when you can pickle the universe. But a test that fails for a hundred irrelevant reasons and one relevant one is, in practice, a test that gets updated without reading — which is to say, no test at all.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Kitchen-Sink Snapshots

NEVER snapshot an entire rendered tree, full API response, or large object as a substitute for deciding what the test should assert. A snapshot that captures everything specifies nothing — it fails on every irrelevant change until people reflexively update it without reading.

The core problem: a giant snapshot has no intent. When it goes red, nobody can tell the meaningful line from the noise, so the diff goes unread and the update flag becomes the team's muscle memory — at which point the test enforces nothing.

Rules:
- Assert the contract explicitly: the heading text, the row count, the formatted total, the disabled state — `expect(screen.getByRole('button')).toBeDisabled()` beats 900 lines of serialized DOM
- If you must snapshot, snapshot small and targeted: a single element's text, one extracted subobject, an inline snapshot (`toMatchInlineSnapshot`) short enough to live readably in the test file. If it doesn't fit inline comfortably, it's too big
- Never snapshot trees containing volatile data (timestamps, IDs, versions, generated class names) without normalizing or masking those fields — volatile snapshots are pre-scheduled false alarms
- Don't snapshot other components' internals: a Dashboard snapshot that serializes every child widget makes every child team's change your test failure
- For full API responses, assert the fields the consumer relies on; if schema stability itself is the contract, use a schema validation, not a byte-for-byte freeze
- Before writing `toMatchSnapshot()`, answer: which specific lines of this output am I protecting? If you can name them, assert them directly; if you can't, you're not ready to write the test

**Red flags that you're about to violate this:**
- "One snapshot covers the whole component, very thorough..."
- "Snapshotting everything means we'll catch any regression..."
- "I don't know exactly what matters here, the snapshot captures it all..."
- "It's just one line of test code for full coverage..."
- "The diff will show reviewers what changed..."

---

## Why It Works

1. **It reframes coverage-of-everything as specification-of-nothing.** The AI believes bigger snapshots catch more. Walking through the actual lifecycle — unreadable diffs, reflexive updates, dead test — shows the breadth is what destroys the value.

2. **It forces the contract question.** "Which lines am I protecting?" is the question snapshot one-liners exist to avoid. Making it a precondition converts the snapshot from a thought-substitute into a deliberate choice.

3. **It permits the good version.** Small, targeted, inline snapshots are genuinely useful. Keeping them legal — with a concrete size heuristic — stops the rule from being discarded as anti-snapshot dogma.

## Origin

A product team's component suite contained 212 snapshot tests, median size around 400 lines, nearly all generated in bulk by an assistant told to "add tests for the component library." A routine design-token update turned 198 of them red; the diff totaled forty thousand lines, so it was updated wholesale — along with, it later emerged, a regression that dropped the error banner from the payment form. The banner's disappearance was on line 11,304 of the diff. Nobody made it past line fifty.
