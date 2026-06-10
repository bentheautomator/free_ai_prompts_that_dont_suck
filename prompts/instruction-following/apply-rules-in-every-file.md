---
title: Apply Rules in Every File
slug: apply-rules-in-every-file
category: instruction-following
tags: [universal, rules, compliance]
works_with: all
severity: high
one_liner: "AI obeys a rule in some files and forgets it exists in others"
---

# Apply Rules in Every File

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents patchy compliance where a rule gets applied only in the files the AI associates with it.

**[Copy-paste ready version](../../install/apply-rules-in-every-file.md)** — just the instruction block, no explanation.

## The Problem

The rule says all database access goes through the repository layer. In the files where the AI first applied that rule — the main service modules — it complies every time. Then it touches a cron script, a test helper, a one-off admin endpoint, and writes raw queries in all three. The rule didn't decay over time. It decayed over *space*: it got mentally attached to certain files and contexts, and everywhere else reverted to defaults.

This happens because rules get encoded as associations rather than as universals. "Use the repository layer" becomes "use the repository layer *in files like the ones where I've been using it*." New files, unfamiliar directories, different file types (scripts, tests, configs, docs) don't trigger the association, so the rule silently fails to fire. The AI would pass a quiz about the rule while violating it in the file currently open.

The result is a codebase that's consistent exactly where you'd have checked and inconsistent everywhere you wouldn't — the worst possible distribution of violations.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Apply Rules in Every File

Rules apply to EVERY file you touch, not just the files where you've applied them before. NEVER let a rule's coverage shrink to the contexts you associate it with.

**The core problem:** You encode rules as associations — "this rule fires in files like these" — instead of universals. New files, scripts, tests, and unfamiliar directories don't trigger the association, so the rule silently fails to fire there, and your compliance becomes patchy in exactly the places no one is watching.

**Do this:**

- When entering ANY file — new, old, test, script, config — run the standing rules against it before editing, as if it were the first file of the session
- Treat "different kind of file" as a reason to check the rules MORE carefully, not a reason to assume they don't apply
- If a rule's scope is genuinely unclear ("does the no-raw-SQL rule cover test fixtures?"), ask; until answered, apply it
- When creating a new file, apply every rule from the very first line — new files are where association-based compliance fails hardest

**Do not:**

- Assume tests, scripts, tooling, or "non-production" code are exempt unless the rule says so
- Carry compliance only in the files where the rule was first discussed or enforced
- Use unfamiliarity with a directory as an implicit rule-free zone

**Red flags that you're about to violate this:**

- "This is just a script, conventions don't really apply"
- "The rule was about the service layer, and this is a helper"
- "I've never worked in this directory; I'll do it the normal way"
- "It's a test file, so the production rules are off"
- "This file predates the rule, so I'll match its existing style"

---

## Why It Works

1. **It names the encoding error.** The AI doesn't decide tests are exempt — the rule simply never fires there. Describing the association-vs-universal mechanism lets the model recognize the silent non-firing rather than just promising to "follow rules."

2. **It inverts the unfamiliarity heuristic.** Unfamiliar contexts currently lower rule application; the instruction makes unfamiliarity a trigger for *extra* checking, flipping the failure condition into a safeguard.

3. **It targets file creation explicitly.** New files have no existing patterns to cue the rule, making them the highest-risk location. Calling that out installs the check exactly where association-based compliance has nothing to grab onto.

4. **It separates scope questions from scope assumptions.** "Ask, and apply until answered" handles the genuinely ambiguous cases without leaving a gap the AI can default through.

## Origin

A team's rules file required every outbound HTTP call to go through their instrumented client wrapper — and in the API codebase, the AI complied flawlessly for weeks. Then it wrote a data backfill script with twelve raw HTTP calls, no timeouts, no instrumentation. The script hammered a partner API past its rate limit during the backfill, got the team's credentials temporarily suspended, and took production integrations down with it. The rule was known, quoted, and followed — in the directories the AI had associated it with.
