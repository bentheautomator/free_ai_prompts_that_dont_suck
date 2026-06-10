---
title: No CLI Flags for a One-Line Change
slug: no-cli-flags-for-a-one-line-change
category: scope
tags: [universal, scope, over-engineering]
works_with: all
severity: medium
one_liner: "AI bolting an argument parser onto a script that needed one value changed"
---

# No CLI Flags for a One-Line Change

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding command-line flags and argument parsing when you asked it to change a hardcoded value.

**[Copy-paste ready version](../../install/no-cli-flags-for-a-one-line-change.md)** — just the instruction block, no explanation.

## The Problem

"Change the timeout in this script from 30 to 60." That's the request. The response: an `argparse` setup, a `--timeout` flag with a default, help text, a `main()` function to house it all, and sometimes a usage example in a comment. One line was requested. Forty lines arrived, and the script now has a public interface someone has to remember exists.

AI assistants do this because hardcoded values pattern-match to "code smell," and parameterizing one feels like fixing the root cause instead of the symptom. But the user hardcoded that value on purpose, or at least lives with it on purpose. A script that three people run from cron does not need a CLI surface. Every flag is documentation debt, a new way to invoke the script wrong, and a thing that must keep working forever.

The deeper cost is trust: when a one-line request produces a forty-line diff, the reviewer has to figure out whether the other thirty-nine lines changed behavior. Usually they did — default handling, type coercion, and exit codes all shift when an argument parser moves in.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No CLI Flags for a One-Line Change

When asked to change a hardcoded value, change the value. NEVER convert it into a command-line flag, environment variable, or function parameter unless that conversion was explicitly requested.

The core problem: parameterizing a value the user wanted edited replaces a zero-risk one-line diff with a new public interface that must be reviewed, documented, and supported.

- "Change X from A to B" means exactly that: the diff is the value changing, nothing more
- Do not add argument parsing, flag definitions, help text, or a `main()` wrapper to host them
- Do not introduce a default-plus-override pattern "so it's easy to change next time"
- Do not move the value to a constants section, settings object, or config file as part of the change
- If you genuinely believe the value should be configurable, finish the one-line change first, then say so in one sentence: "Want me to make this a flag instead?" Let the user decide
- A hardcoded value that someone asked you to edit is a value under control, not a defect

**Red flags that you're about to violate this:**
- "Instead of hardcoding this, I'll make it configurable..."
- "While I'm changing this value, a flag would make future changes easier..."
- "This really should be a parameter, so I'll do it properly..."
- "I'll add argparse so the user can override it without editing code..."
- "Hardcoded values are bad practice, this is my chance to fix it..."
- "It's only a few extra lines and it's strictly more flexible..."

---

## Why It Works

1. **It reframes "root cause."** The AI treats the hardcoded value as the problem; the rule states the value is under deliberate control and the edit IS the fix, removing the justification for parameterizing.

2. **It names the hidden cost.** "Strictly more flexible" ignores that every flag is interface surface with documentation, support, and misuse costs. Making that explicit breaks the "more options is free" assumption.

3. **It routes the idea instead of suppressing it.** The AI gets a sanctioned move (one-sentence offer), so it doesn't have to smuggle the flag into the diff to feel useful.

4. **It closes the constants-file loophole.** Without the explicit ban, the AI substitutes a "lighter" version of the same creep: moving the value somewhere else counts as not changing it in place.

## Origin

A data engineer asked an assistant to bump a batch size from 500 to 2000 in a nightly ETL script. The assistant delivered the bump wrapped in a new argument parser with three flags, a restructured entrypoint, and a changed exit-code convention. The cron job that ran the script passed a positional argument the new parser rejected, and the nightly load silently failed for two days before anyone checked. The requested change was one digit.
