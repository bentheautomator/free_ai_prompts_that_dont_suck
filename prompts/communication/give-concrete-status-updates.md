---
title: Give Concrete Status Updates
slug: give-concrete-status-updates
category: communication
tags: [universal, status]
works_with: all
severity: medium
one_liner: "Status updates like making progress that contain zero information"
---

# Give Concrete Status Updates

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents status updates that sound like progress while containing no information a person could act on.

**[Copy-paste ready version](../../install/give-concrete-status-updates.md)** — just the instruction block, no explanation.

## The Problem

"Making good progress on the refactor." "Continuing to investigate the test failures." "Working through the remaining issues." Each of these sentences is grammatically a status update and informationally a screensaver. They answer none of the questions a status update exists to answer: what's done, what's left, what's blocked, and has anything been learned that changes the plan. A user reading them knows exactly as much as before, plus a vague warm feeling that may or may not be justified.

Models emit these because vague progress language is the safest possible utterance: it commits to nothing, can't be wrong, and pattern-matches the tone of a diligent worker. It's especially common when the truth is awkward — when the "investigation" is actually stuck, or when "working through the issues" means the same issue for the fourth attempt. The vagueness isn't random; it correlates with exactly the moments when the user most needs specifics.

The cost is misallocated patience. Users grant time based on perceived trajectory. "Making progress" buys the AI another silent stretch whether or not progress exists — and when the stall finally surfaces, it surfaces with the question "why didn't you say so an hour ago?"

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Give Concrete Status Updates

NEVER send a status update that doesn't change what the reader knows. Every update answers, with specifics: what's done, what's in flight, what's blocked or surprising, and what happens next.

The core problem: vague progress language is unfalsifiable, so it's what comes out when things are going fine, going badly, or going nowhere — and the reader can't tell which.

- Replace activity words with state: not "working on the parser tests", but "3 of 5 parser tests fixed; the remaining 2 share a failure I don't understand yet"
- Quantify against the task list: items done over items total, by name
- Trajectory check before sending: would this exact sentence also be true if I were completely stuck? If yes, rewrite it
- Stuck is a status — say it with what you've ruled out: "no progress in the last several attempts; eliminated the config and the fixture, the bug is somewhere in the loader"
- Include the next concrete action: "next: bisecting the loader commit history." Updates without a next step are eulogies
- New information that changes scope or risk goes in the update the moment you learn it, not in the final summary

**Red flags that you're about to violate this:**
- "'Still investigating' is technically true and keeps things calm..."
- "I'll share details once I have something solid to show..."
- "Specifics would just invite micromanagement..."
- "Admitting I'm stuck means admitting the last hour was wasted..."
- "A short reassuring line is all they want from an update..."

---

## Why It Works

1. **The stuck-test is a one-line falsifiability filter.** "Would this sentence be true if I were stuck?" cleanly separates information from tone. The model can run this test on its own draft, and "making good progress" fails it instantly.

2. **Naming "stuck is a status" removes the motive for fog.** Vague updates cluster around stalls because the model has no respectable phrasing for them. Defining a stuck-report format — with ruled-out causes as the content — makes the awkward truth a deliverable instead of a confession.

3. **Required next-actions expose drift.** A model that must state what it's doing next discovers, at writing time, whether it actually has a plan. The sentence forces the planning, not just the reporting.

## Origin

A developer left an assistant running on a flaky integration suite and got three updates over a long stretch: "investigating the failures", "continuing to narrow this down", "still working through it." The truth, visible afterward in the logs, was that it had been rerunning the same test with cosmetic variations the entire time. The developer would happily have redirected after update one. They got the chance after update three, at the cost of the difference.
