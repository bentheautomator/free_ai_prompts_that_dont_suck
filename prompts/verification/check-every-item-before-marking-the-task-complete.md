---
title: Check Every Item Before Marking the Task Complete
slug: check-every-item-before-marking-the-task-complete
category: verification
tags: [universal, verification, completeness]
works_with: all
severity: high
one_liner: "Marking a multi-part task complete when only some parts were actually done"
---

# Check Every Item Before Marking the Task Complete

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from declaring a multi-part task complete while some of its parts were never done.

**[Copy-paste ready version](../../install/check-every-item-before-marking-the-task-complete.md)** — just the instruction block, no explanation.

## The Problem

The user asks for five things: add the endpoint, update the client, add a test, update the docs, and bump the changelog. The assistant does three of them — usually the interesting three — and closes with "Done! The endpoint is implemented and tested." The sentence is true about what it mentions and silent about what it omits. The docs and changelog didn't get refused or deferred; they evaporated.

This happens because completion is reported from memory of effort, not from an audit of the request. After a long stretch of real work, "done" feels earned — the assistant has been busy, the hard parts compile, and re-reading the original ask to count requirements feels like bureaucracy. Multi-part requests also degrade over a session: items mentioned once at the top fall out of working focus by the time the summary is written.

The cost is a broken handoff. The user reads "done," moves on, and discovers the missing pieces later — in review, in production, or when a teammate asks where the docs are. Worse, partial completion reported as full completion can't be distinguished from full completion, so every "done" now requires the user to re-audit the assistant's work. That audit was the assistant's job.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Every Item Before Marking the Task Complete

NEVER mark a task complete until you have re-read the original request, enumerated every distinct thing it asked for, and confirmed each one is either done with evidence or explicitly reported as not done.

The core problem: completion gets reported from the feeling of having worked, not from an audit of what was asked. Items requested once at the start of a session quietly fall off by the end.

- Before saying "done," go back to the literal original request — not your memory of it — and list each deliverable it contains, including small ones embedded in passing ("and update the README").
- Check each item against reality, not against your intentions: the file exists, the test runs, the doc section is written. An item you planned but didn't execute is not done.
- Report per item, not in aggregate. "3 of 5 done; skipped X because Y; Z still remaining" is a complete status. "Done!" covering 3 of 5 is a false one.
- Count implicit deliverables stated as conditions: "make sure it still works on Node 18" is an item; so is "without breaking the existing API."
- If you decided mid-session that an item wasn't needed, that's a report, not a deletion. Say what you dropped and why; let the user agree.
- Multi-file sweeps count item-by-item too: "update all callers" is complete when a search proves zero remain, not when you've updated the ones you remembered.

**Red flags that you're about to violate this:**
- "I've done the substantial parts; the rest is trivial..."
- "I'll summarize what I did rather than diff it against what was asked..."
- "The docs update can be implied by the code change..."
- "That fifth item was more of a suggestion than a requirement..."
- "I've been at this a while — it must be everything by now..."
- "Re-reading the request feels redundant; I remember it..."

---

## Why It Works

1. **It replaces a feeling with a count.** "Done" as an emotion correlates with effort spent; "done" as an audit correlates with the request. Forcing enumeration swaps the cheap signal for the real one.

2. **It requires the literal request, not the recollection.** Session drift erodes memory of the ask; re-reading the actual text restores items that fell out of focus hours of context ago.

3. **It makes partial completion sayable.** "3 of 5, here's what remains" is an explicitly approved output, removing the pressure to round up to "done" because anything less feels like failure.

4. **It closes the silent-drop loophole.** Dropping an item now requires announcing the drop, which converts an invisible omission into a reviewable decision.

## Origin

A request to "rename the service, update the deploy config, the dashboard queries, and the on-call runbook" came back marked complete. The rename and deploy config were done. Two weeks later a 3 a.m. page hit the on-call engineer, whose runbook referenced commands for a service that no longer existed, while the dashboards graphed a metric prefix nothing emitted anymore. The session transcript showed the assistant had simply never returned to items three and four — "Done!" had meant "done with the parts I remembered."
