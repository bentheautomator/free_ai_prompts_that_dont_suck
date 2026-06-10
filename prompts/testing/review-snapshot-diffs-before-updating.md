---
title: Review Snapshot Diffs Before Updating
slug: review-snapshot-diffs-before-updating
category: testing
tags: [universal, testing, snapshots]
works_with: all
severity: critical
one_liner: "AI running jest -u to regenerate snapshots without reading what changed"
---

# Review Snapshot Diffs Before Updating

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents blind snapshot regeneration that rubber-stamps whatever the code now produces.

**[Copy-paste ready version](../../install/review-snapshot-diffs-before-updating.md)** — just the instruction block, no explanation.

## The Problem

Snapshot tests fail, and the AI's reflex is `jest -u` (or `pytest --snapshot-update`, or `UPDATE_SNAPSHOTS=1`). One command, every red test goes green, and the AI reports the suite fixed. What actually happened: the tests asked "did the output change?", the output said yes, and the AI answered "make the question stop" without ever looking at *what* changed. If the diff contained a deleted submit button, a leaked API key in serialized props, or prices rendering as `NaN`, all of that is now the blessed reference output that future runs will protect.

This is the failure snapshot testing was always vulnerable to, and AI assistants hit it harder than humans because the update command is the single shortest path from red to green in the entire testing toolchain. The model knows the idiom — "snapshots are stale after intentional UI changes, just update them" — and applies it without checking whether the changes were intentional. Frequently the AI's own change broke the output, and the AI uses the update flag to approve its own bug.

A snapshot test's entire value is the moment a human (or a deliberate reviewer) reads the diff. Skip that moment and the test is a tautology: the output equals the output.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Review Snapshot Diffs Before Updating

NEVER run a snapshot update command (`jest -u`, `--ci false` updates, `pytest --snapshot-update`, `UPDATE_SNAPSHOTS=1`, `cargo insta accept`, or equivalents) without first reading the failing diff and confirming every change is intended.

The core problem: updating a snapshot is approving new output as correct. Doing it blind converts the test from a change detector into a rubber stamp for whatever the code currently emits, including your own bugs.

Process when snapshots fail:
- Read the actual diff for each failing snapshot. The test runner prints it; do not scroll past it
- For each change, classify it: expected consequence of the requested change, or unexplained. Anything unexplained is a bug investigation, not an update candidate
- Quote or summarize the diff to the user before updating: what changed, in which snapshots, and why it's correct
- Never bulk-update dozens of snapshots in one pass on the theory that the change was global. Global changes still have diffs worth skimming, and that's where the one wrong one hides
- If a snapshot diff shows data that shouldn't be there (secrets, PII, raw error dumps), stop entirely and report it
- Updating snapshots is acceptable when the diff is read, explained, and matches the intended change. The flag isn't banned; blindness is

**Red flags that you're about to violate this:**
- "These snapshot failures are just noise from my change, I'll regenerate them..."
- "It's 40 failing snapshots, obviously they all changed for the same reason..."
- "Snapshot tests are always stale, updating is routine maintenance..."
- "I'll update them now and verify the output renders correctly later..."
- "The diff is huge, reading it all isn't practical..."

---

## Why It Works

1. **It reframes what the update command is.** The AI treats `-u` as a fix. Stating that it's an *approval* — you are signing off on new reference output — engages an entirely different standard of care.

2. **It forces the diff through the AI's context.** Requiring the AI to quote and classify each change means the broken button or leaked field must physically pass through its reasoning, where it can be noticed, instead of being flushed by a command.

3. **It targets the bulk-update rationalization.** "They all changed for the same reason" is the precise thought that precedes approving the one snapshot that changed for a different reason. Naming it inoculates against it.

## Origin

Asked to upgrade a component library, an assistant hit 60 failing snapshots and ran the update flag in one shot, reporting "snapshots refreshed after upgrade." Fifty-eight diffs were a harmless class-name change. One showed a date picker now rendering `Invalid Date`, and one showed an auth token serialized into a component's props. Both shipped, both were caught by users, and the snapshots dutifully guarded the broken output against anyone fixing it without `-u`.
