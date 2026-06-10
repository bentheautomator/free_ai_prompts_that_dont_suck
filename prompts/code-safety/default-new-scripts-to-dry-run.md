---
title: Default New Scripts to Dry-Run
slug: default-new-scripts-to-dry-run
category: code-safety
tags: [universal, automation]
works_with: all
severity: high
one_liner: "AI writing cleanup scripts whose default behavior is to destroy things"
---

# Default New Scripts to Dry-Run

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from authoring scripts where the destructive path is the default and the safe path is opt-in.

**[Copy-paste ready version](../../install/default-new-scripts-to-dry-run.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI to "write a script that removes old report files," and you'll get a script that removes old report files — immediately, on every invocation, with no preview mode, because that's the literal spec. Run it to see what it does? It does it. Run it later with a half-remembered purpose, from the wrong directory, with a mistyped argument? It does it. The AI built a tool where the most dangerous behavior is the default and the only behavior, and every future execution — by you, by cron, by a coworker who found it in `scripts/` — inherits that design.

Hand-written destructive scripts accumulate guardrails over time because their authors get scared by near-misses. AI-written scripts are born guardrail-free: no dry-run mode, no confirmation, no logging of what was deleted, `rm` instead of a quarantine move, and silent success either way. The failure isn't one bad execution — it's manufacturing an unsafe tool. A deletion script is a small product, and products whose default mode is "destroy" are recalled.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Default New Scripts to Dry-Run

When writing any script that deletes, overwrites, or modifies data in bulk, ALWAYS make the safe path the default and the destructive path opt-in. Dry-run is the default mode; real execution requires an explicit flag.

The core problem: a script whose default behavior is destruction will eventually run by accident — wrong directory, wrong argument, curious coworker, cron — and the design decision you made at authoring time decides what that accident costs.

- Default to preview: invoked with no flags, the script prints what it *would* delete/modify (full paths, counts, total size) and exits. Destruction requires `--execute` or `--force` explicitly.
- Make it loud: in execute mode, log every path acted on, and print a summary ("deleted 34 files, 1.2 GB, list saved to cleanup-2026-06-10.log"). Silent destruction is undebuggable destruction.
- Prefer reversible mechanics inside the script: move to a quarantine/trash directory rather than `rm`; the script can have a `--purge-quarantine` for later. Two-stage deletion survives mistakes; one-stage doesn't.
- Validate inputs defensively: refuse empty or root-ish path arguments, resolve and print the absolute target directory before acting, require the target to match an expected pattern. Fail closed on anything surprising.
- Bound the blast radius: a `--limit N` default or a sanity check ("refusing: would delete 4,000+ files, expected <100") catches wrong-directory invocations.
- These rules apply even for "one-off" scripts. One-off scripts get reused; design them like they'll outlive the session, because they will.

**Red flags that you're about to violate this:**
- "It's a simple cleanup script, flags would be over-engineering..."
- "The user will only ever run this on the right directory..."
- "I'll write the quick version now and harden it if needed..."
- "Adding dry-run doubles the code for a ten-line script..."
- "It's one-off, it'll be deleted after this task anyway..."

---

## Why It Works

1. **It shifts safety from execution-time to design-time.** Most safety rules try to make the AI careful when *running* things; this one makes carelessness survivable by ensuring the artifacts it produces are safe by default — covering every future execution, including ones the AI never sees.

2. **It exploits accident asymmetry.** An accidental dry-run prints a list; an accidental execution deletes files. Defaulting to the cheap accident is pure win, and stating that asymmetry makes "flags are over-engineering" untenable.

3. **It kills the one-off exemption.** "One-off scripts get reused" preempts the rationalization the AI uses to skip every guardrail, by naming the empirical reality that scripts in repos outlive their intent.

## Origin

An assistant wrote a "quick script" to delete generated thumbnails older than a week — no dry-run, no logging, path taken as a bare argument. It worked at delivery. A month later a teammate ran it against what they believed was the thumbnail directory; the argument pointed one level up, and the script deleted week-old *originals* along with thumbnails, silently, exiting zero. A default dry-run would have printed the originals' paths and ended the story there.
