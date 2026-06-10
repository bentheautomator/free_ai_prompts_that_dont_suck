---
title: Don't Re-Read Unchanged Files
slug: dont-reread-unchanged-files
category: agents-and-automation
tags: [universal, agents, context]
works_with: all
severity: medium
one_liner: "Reading the same large file for the fifth time in one session"
---

# Don't Re-Read Unchanged Files

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from repeatedly re-reading files it already has in context, stacking duplicate copies until the window is full of déjà vu.

**[Copy-paste ready version](../../install/dont-reread-unchanged-files.md)** — just the instruction block, no explanation.

## The Problem

Midway through a long session, the agent wants to confirm a function signature, so it reads the file. The same file it read twenty minutes ago. And fifteen minutes before that. Each read is a fresh, full copy appended to the context window — three copies of an 800-line module now sit in the transcript, two of them byte-identical to the third. The agent isn't being careless within any single step; re-reading feels like rigor. Across the session, it's hoarding.

The reflex comes from a mismatch between how agents experience memory and how they trust it. The earlier copy of the file is still right there in context, but retrieving from mid-transcript feels less certain than a fresh read, so the agent reaches for the tool. There's also a habit-transfer problem: rules like "read before edit" are good defaults that agents over-apply into "re-read before every edit, even the one I made thirty seconds ago."

Note the boundary: if the user may have edited the file, or another process writes to it, re-reading is correct and required. The waste is re-reading files that nothing has touched — and in a single-writer session where the only writer is you, that's most files, most of the time.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Re-Read Unchanged Files

NEVER re-read a file that is already in your context unless something could have changed it since you read it. A second full read of an unchanged file adds a duplicate copy to your context window and zero information.

The core problem: a fresh read feels more trustworthy than your own transcript, so you keep re-fetching what you already have — paying full context price for déjà vu.

- Before reading any file, check: have I already read this in this session? Has anything written to it since — me, the user, a generator, a formatter? If no writer exists, use the copy you have.
- After your own edit, you know the resulting state: the prior content plus your change. You do not need a confirmation read after every successful edit; the edit result already told you it applied.
- DO re-read when there is a plausible writer: the user said they changed something, you ran a code generator or formatter, another agent shares the workspace, or significant time passed in an environment you don't control.
- When you only need to confirm one detail (a signature, an export, a constant), search for that symbol or read a 20-line slice — never the whole file again.
- If you find yourself unable to recall a file's contents that you read earlier, that's a sign your context is already strained: read back the specific slice you need, and tighten read discipline from here on rather than re-dumping files whole.

**Red flags that you're about to violate this:**
- "Let me re-read the file to refresh my memory..."
- "I'll read it once more just to be safe..."
- "Before editing, I should read the file again..." (you read it two minutes ago and nothing else writes to it)
- "Let me verify my edit landed by reading the whole file..."
- "It's quicker to re-read than to scroll back..."

---

## Why It Works

1. **It legitimizes trusting the transcript.** The agent re-reads because a tool call feels more authoritative than its own context. Stating explicitly that an unchanged file's earlier copy is fully valid removes the anxiety that drives the reflex.

2. **It scopes the rule with a "plausible writer" test.** A blanket "don't re-read" would cause stale-state bugs. Tying re-reads to the existence of another writer keeps the safety cases (user edits, generators, sibling agents) intact while cutting the waste.

3. **It offers the cheap substitute.** Most re-reads are motivated by one uncertain detail. "Search for the symbol, read 20 lines" satisfies the need at one-fortieth the cost.

## Origin

A session log review found an agent had read the same 1,100-line service module seven times during a two-hour task — once legitimately, then six more times "to refresh context" before successive edits, despite being the file's only writer. The duplicates accounted for roughly a third of everything in the context window at the point where the session hit its limit and lost the user's acceptance criteria to compaction.
