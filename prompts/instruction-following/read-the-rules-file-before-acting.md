---
title: Read the Rules File Before Acting
slug: read-the-rules-file-before-acting
category: instruction-following
tags: [universal, rules, process]
works_with: all
severity: high
one_liner: "AI starts working without ever reading CLAUDE.md or .cursorrules"
---

# Read the Rules File Before Acting

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from diving into work without reading — or while ignoring — the project's rules file.

**[Copy-paste ready version](../../install/read-the-rules-file-before-acting.md)** — just the instruction block, no explanation.

## The Problem

You spent an evening writing a thorough CLAUDE.md: build commands, directory conventions, the testing policy, the three things that must never happen. The AI's first action in the next session is to grep the codebase and start editing — operating entirely from training defaults, as if the file didn't exist. Sometimes the rules file technically loaded into context and got skimmed past; sometimes the assistant just never looked. Either way, your project's constitution had zero effect on the work.

This failure is upstream of every other rule-following failure. An AI can't decay from, reinterpret, or carve exceptions out of rules it never ingested. The telltale signs are unmistakable: the AI "discovers" conventions the file states outright, asks questions the file answers, uses `npm` in a repo whose rules file says `pnpm` in bold, or proposes a workflow the file explicitly forbids.

The deeper issue is that task momentum beats setup. The user's request feels urgent and concrete; reading a rules file feels like overhead before the "real" work. So the real work proceeds — under the wrong rules.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read the Rules File Before Acting

ALWAYS read the project's rules files (CLAUDE.md, .cursorrules, CONTRIBUTING.md, or equivalents) before your first action in a project — and actually apply what they say.

**The core problem:** Task momentum beats setup. The user's request feels concrete and urgent; reading rules feels like overhead. So you start working under training defaults while the project's actual rules sit unread, and every decision you make is potentially wrong in a way the file already warned about.

**Do this:**

- Before the first edit, command, or recommendation in a project, locate and read the rules files — including any they reference ("see docs/process.md")
- Extract the rules that bear on the current task and hold them as binding constraints, not background flavor
- If a rules file conflicts with what you were about to do by default, the file wins — your defaults are the fallback, not the standard
- When you genuinely cannot find a rules file, say so briefly; don't silently assume there isn't one

**Do not:**

- Treat the rules file as something to consult later "if questions come up" — by then you've already made the decisions it governs
- Skim it for vibes; specific commands, paths, and prohibitions are the payload
- Ask the user questions the file answers — that signals you didn't read it

**Red flags that you're about to violate this:**

- "Let me just get started on the actual task"
- "I'll check the conventions if something looks unusual"
- "This is a standard project; standard practice will be fine"
- "I read a rules file in here once; it's probably the same"
- "The request is simple enough that project rules won't matter"

---

## Why It Works

1. **It sequences setup before momentum can kill it.** The failure happens because reading rules competes with starting the task and loses. Making the read a precondition of the *first action* removes the competition — there is no task work to be drawn toward yet.

2. **It defines what reading means.** "Skimmed it" is the half-compliance mode. Requiring extraction of task-relevant rules as binding constraints converts passive ingestion into something with observable effect.

3. **It inverts the default hierarchy.** Models treat training defaults as the standard and project rules as deltas to maybe apply. Stating "the file wins; your defaults are the fallback" fixes the precedence at the moment of conflict.

4. **It creates a detectable signal.** "Don't ask questions the file answers" gives users a cheap tripwire for spotting an unread rules file early, before the damage spreads.

## Origin

A contractor's repo had a rules file whose third line read: "The `legacy/` directory is frozen — changes there break a downstream consumer we cannot update." The AI's first move in a fresh session was a project-wide rename, executed in ninety seconds, touching fourteen files in `legacy/`. The downstream consumer broke exactly as documented, and unwinding the rename took the rest of the day. The file that would have prevented all of it was 40 lines long and sitting in the repo root, unread.
