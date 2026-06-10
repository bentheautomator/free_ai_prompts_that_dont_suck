---
title: Debug One Bug at a Time
slug: debug-one-bug-at-a-time
category: debugging
tags: [universal, debugging]
works_with: all
severity: high
one_liner: "AI interleaving two bug hunts until neither has clean evidence"
---

# Debug One Bug at a Time

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from chasing a second bug mid-investigation and contaminating the evidence for both.

**[Copy-paste ready version](../../install/debug-one-bug-at-a-time.md)** — just the instruction block, no explanation.

## The Problem

Halfway through investigating why the search results are stale, the AI notices the pagination is also off by one — and starts fixing that too, in the same session, in the same working tree, with the same test runs serving both hunts. Now every observation is ambiguous: did the result change because of the staleness experiment or the pagination edit? Which bug does this new log line belong to? When one of them stops reproducing, which change gets the credit? Two investigations sharing one working tree don't run in parallel — they corrupt each other's lab.

This is different from shotgun-debugging one bug with many changes; this is *two targets*, interleaved. The pull is real: bugs cluster, and an investigation naturally turns over rocks with other bugs under them. Following the new bug feels responsive — it's right there, it's real, ignoring it feels negligent. But debugging is fundamentally differential measurement (what changed between this run and the last?), and a second concurrent hunt injects uncontrolled changes into every differential. The original investigation also quietly starves: half the attention, half the iterations, and frequently no conclusion at all — sessions that open on bug A and close on bug C, with A still broken and nobody noticing.

The discipline isn't ignoring the second bug. It's *parking* it: record it, finish the current hunt, then come back.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Debug One Bug at a Time

NEVER actively investigate two bugs in the same working tree at the same time. When a second bug surfaces mid-hunt, park it — write it down, leave it alone, finish the current investigation first.

Debugging is differential measurement: each run is compared against the last to see what your change did. A second concurrent hunt injects its own changes into every comparison, corrupting the evidence for both bugs.

- Keep an explicit statement of which bug is the current target; every change and every run in the session should serve that target
- When you discover another bug mid-investigation, park it: record the symptom, the reproduction (if you have one), and where you saw it — in your notes and in your eventual summary — then return to the target
- Exception one: the new bug *blocks* the investigation (you can't reach the failing path). Then it becomes the target, explicitly — announce the switch, stash the current state, and return afterward
- Exception two: investigation reveals the "two bugs" are one bug — the same root cause producing both symptoms. Say so, with the shared mechanism, and proceed against the root
- Never fix the parked bug "real quick while I'm here": even a small fix changes the system mid-experiment and lands in the same diff, where it muddies what the eventual fix-for-the-target actually was
- At session end, the parked list is a deliverable: bugs found but not pursued, stated plainly so they don't evaporate

**Red flags that you're about to violate this:**
- "While investigating this, I noticed another issue — let me fix that too..."
- "This is a quick one, I'll knock it out and get back to the main bug..."
- "I'm in this file anyway, might as well address both..."
- Unable to say, mid-session, which bug the last three changes were for
- A test run whose result you can't attribute to one investigation
- A session that opened on one bug and is now three bugs deep with zero closed

---

## Why It Works

1. **It names the contamination mechanism.** "Differential measurement with injected changes" explains *why* interleaving fails — not a neatness preference but corrupted evidence — which outcompetes the responsiveness instinct that drives the detour.

2. **It makes parking cheaper than chasing.** The found bug's value is preserved (recorded, reported) at near-zero cost, removing the "ignoring it feels negligent" pressure that justifies the mid-hunt switch.

3. **It handles the legitimate switches explicitly.** Blocking bugs and shared-root-cause discoveries are real; giving each a sanctioned, announced path prevents the rule from being broken silently whenever it's inconvenient.

4. **It bans the "real quick" fix specifically.** The smallest version of the violation is the most common one; naming it closes the gap between the rule and the habit.

## Origin

A session opened on a memory leak in a worker process. Twenty minutes in, the assistant noticed a misconfigured log level and fixed it; that exposed verbose output, in which it spotted a deprecation warning, and migrated the deprecated call; the migration broke a test, which it then investigated. The session ended with three incidental changes shipped, a summary describing the deprecation work — and the memory leak untouched and unmentioned. It OOM-killed the worker fleet that weekend. The on-call engineer, reading the session transcript afterward, described it as "watching someone leave the house to fight a fire and come home with groceries."
