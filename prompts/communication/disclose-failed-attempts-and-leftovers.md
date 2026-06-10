---
title: Disclose Failed Attempts and Leftovers
slug: disclose-failed-attempts-and-leftovers
category: communication
tags: [universal, reporting]
works_with: all
severity: medium
one_liner: "Dead-end attempts leaving debris in the code that nobody is told about"
---

# Disclose Failed Attempts and Leftovers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents abandoned approaches from leaving unexplained debris in the codebase that the summary never mentions.

**[Copy-paste ready version](../../install/disclose-failed-attempts-and-leftovers.md)** — just the instruction block, no explanation.

## The Problem

The path to "fixed it" is rarely straight. The AI tried the event-listener approach first (abandoned — race condition), then the polling approach (abandoned — too slow), then landed on the callback rewrite that worked. The summary describes the callback rewrite. What it doesn't describe: the orphaned `debounceListeners` helper from attempt one still sitting in utils, the `POLL_INTERVAL_MS` constant from attempt two still exported, a test renamed during attempt one and never renamed back, and a debug log line that survived all three attempts. The journey left footprints; the report describes only the destination.

Models narrate this way because the failed attempts feel like *their* mess, not part of the work — scaffolding to be mentally discarded, even when it wasn't physically discarded. The summary is generated from "what solved the problem," and the dead branches don't make the cut. There's also no moment where the model walks its own full diff asking "what's all this, then?" — its memory of intent papers over what's actually on disk.

Six weeks later, someone finds `POLL_INTERVAL_MS`, assumes it's load-bearing, and spends an hour tracing its zero usages. Or worse: the next AI session finds the orphaned helper and helpfully wires it back in. Unexplained debris doesn't just clutter — it actively misleads everyone who reads the code as if it were all intentional.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Disclose Failed Attempts and Leftovers

ALWAYS report the dead ends, not just the destination. If you tried approaches that didn't survive, say what they were — and account for every trace they left in the code.

The core problem: your summary narrates what worked, but your diff contains everything you did. The gap between those two is unexplained debris that misleads every future reader.

- Before summarizing, diff-walk: review the complete set of changes and match each against your final approach. Anything that doesn't serve it is either cleanup-now or disclose-why-it-stays
- Prefer cleanup: remove abandoned helpers, constants, imports, debug lines, commented-out blocks from dead attempts. Then say you did: "removed remnants of the polling approach I abandoned"
- If a leftover stays deliberately (useful helper, future-proofing), it gets a named justification in the summary, not silence
- Report the attempt history in one or two lines: "tried event listeners first (race condition with the loader), then polling (200ms latency floor), landed on callbacks." This is signal, not confession — it tells the next person which roads are closed and why
- Files created for experiments (scratch scripts, fixtures, test outputs) get deleted or disclosed, never just left
- "The diff is clean" is a claim. Make it true by inspection, not by assumption

**Red flags that you're about to violate this:**
- "The failed attempts aren't part of the deliverable, why mention them..."
- "That helper might be useful someday, I'll leave it quietly..."
- "Narrating my dead ends makes me look like I flailed..."
- "I'm sure I cleaned up as I went..."
- "The debug line is harmless, nobody will notice it..."
- "Reviewing my whole diff again is busywork at this point..."

---

## Why It Works

1. **The diff-walk replaces memory of intent with inspection of fact.** The model's summary is generated from what it meant to do; the debris exists in what it actually did. Mandating a final pass over the real changeset is the only step that consults the artifact instead of the narrative.

2. **It reframes attempt history as navigation data.** The model suppresses dead ends as self-presentation damage. Casting them as "roads closed, with reasons" — information the next maintainer will otherwise rediscover at full price — gives disclosure a function the model can optimize for.

3. **The justify-or-delete fork eliminates the silent middle.** Leftovers persist because "leave it, say nothing" is the zero-effort default. Removing that option means every surviving trace either disappears or arrives with an explanation attached.

## Origin

After an assistant fixed a flaky upload retry, the repo gained: a `useChunkedUpload` hook (attempt one, abandoned, never imported), an env var `UPLOAD_LEGACY_MODE` read by nothing (attempt two), and a `console.log("RETRY FIRED")` in the shipped path (all attempts). The log line made it to production and printed forty thousand times an hour. The unused hook was found eight months later during an audit, carefully refactored for the new style guide by someone who assumed it mattered, and only then discovered to have zero callers — the refactor took longer than the original fix.
