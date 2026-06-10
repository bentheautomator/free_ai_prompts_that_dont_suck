---
title: Cap Command Output Before You Run It
slug: cap-command-output-in-agent-sessions
category: agents-and-automation
tags: [universal, agents, context]
works_with: all
severity: medium
one_liner: "Verbose build and test output flooding the context window"
---

# Cap Command Output Before You Run It

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from running commands whose unbounded output floods the context window with thousands of lines it can't use.

**[Copy-paste ready version](../../install/cap-command-output-in-agent-sessions.md)** — just the instruction block, no explanation.

## The Problem

`npm install` prints 400 lines of progress bars. A test suite in verbose mode prints 3,000 lines of dots, timings, and per-case logs to deliver one number the agent cares about. A `find` over the home directory returns 80,000 paths. Agents run these commands the way a human would — except a human's terminal scrolls and forgets, while the agent's context window keeps every line forever, or until compaction throws out the valuable stuff along with the noise.

The pattern compounds in long sessions because the noisiest commands are the ones run most often. An edit-test loop with verbose test output pays the flood on every single iteration; ten cycles in, the window holds ten near-identical copies of the suite's chatter and has evicted the design discussion from an hour ago. The agent didn't decide to forget the design discussion — it decided, ten times, not to add `--quiet`.

Unlike file reads, output floods can't be undone by reading more carefully next time. Once the command runs, the lines are in the transcript. The filtering has to happen before execution, in the command itself.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Cap Command Output Before You Run It

ALWAYS bound a command's output before running it, not after. Once a flood of output is in your context, it cannot be unread — the filtering must be part of the command.

The core problem: terminals scroll, but your context window doesn't. Every line a command prints stays in the session, displacing instructions and decisions you'll need later.

- Before running any command, ask: how many lines could this print? If the honest answer is "hundreds or unbounded," add a filter: `| tail -50`, `| head -50`, `| grep` for what you're seeking, or redirect to a file and inspect it with targeted reads.
- Prefer quiet modes by default: `--quiet`, `--silent`, `-q`, reporter flags that summarize. Use verbose flags only when diagnosing one specific case, never as the loop default.
- In repeated cycles (edit-test, edit-build), output discipline matters most: you pay the flood every iteration. Run the targeted subset with a summary reporter; print full failure detail for one failing case at a time.
- For searches and listings, constrain at the source: limit the path, limit the depth, cap matches. A `find` or recursive grep from a broad root is a flood with extra steps.
- When a long-running command's output matters but is huge (build logs, CI output), redirect it to a file, then grep the file for errors and read those regions only.
- After an accidental flood, do not re-run for "cleaner output" — that doubles the damage. Extract what you need from what you have.

**Red flags that you're about to violate this:**
- "I'll run the full suite in verbose mode to see everything..."
- "Let me list all the files to get an overview..."
- "More output means more information..."
- "I'll just scroll past the noise..." (you can't — it stays)
- "Running it again with -v will make this clearer..."

---

## Why It Works

1. **It corrects a false mental model.** The agent inherits the human intuition that output scrolls away. Stating "your terminal doesn't scroll — every line persists" reframes verbose flags from harmless to costly.

2. **It moves filtering to before execution.** The unique property of this failure is irreversibility: post-hoc care can't fix it. Making the bound part of the command is the only point of intervention that works.

3. **It targets the loop multiplier.** One flood is friction; a flood inside a ten-iteration cycle is a context catastrophe. Calling out repeated cycles applies the rule hardest where the damage compounds.

4. **It blocks the re-run reflex.** "Run it again with cleaner flags" feels like remediation but doubles the cost. Naming it closes the trap.

## Origin

During a long refactor, an agent ran a 2,400-test suite in verbose mode after every change — fourteen times. Each run added several thousand lines of per-test output to the session. By run nine, the architecture constraints the user had spelled out at the start had been compacted out of context, and the agent began re-introducing the exact pattern the refactor existed to remove. The fix it needed all along was one reporter flag: `--reporter=summary`.
