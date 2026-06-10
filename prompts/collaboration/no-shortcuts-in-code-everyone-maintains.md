---
title: No Shortcuts in Code Everyone Maintains
slug: no-shortcuts-in-code-everyone-maintains
category: collaboration
tags: [universal, teamwork, shared-code]
works_with: all
severity: medium
one_liner: "Stops quick hacks in shared code that the whole team inherits as debt"
---

# No Shortcuts in Code Everyone Maintains

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from taking shortcuts in shared code that every other developer will have to live with and work around.

**[Copy-paste ready version](../../install/no-shortcuts-in-code-everyone-maintains.md)** — just the instruction block, no explanation.

## The Problem

In a personal script, a hack costs you. In shared code, a hack costs everyone — forever, with interest. The AI under pressure to finish a task takes the shortcut: a special-case `if` bolted into a shared function, a copy-pasted block instead of an extraction, a magic sleep that makes the flaky thing pass, a swallowed exception, a `// TODO: handle properly` on a path that absolutely will be hit. The task completes. The shortcut becomes load-bearing.

Here's the asymmetry that makes this a collaboration failure and not just a quality failure: the person who takes the shortcut gets the entire benefit (task done faster), and the people who maintain the code pay the entire cost (every future reader decodes the special case, every future change works around it, someone eventually debugs the swallowed exception at 2 a.m.). Shared code is exactly the place where that trade is worst, because the cost is multiplied by every developer who touches the file — and shortcuts in shared code get copied, because shared code is what people read to learn how things are done here.

The AI defaults to shortcuts because its horizon ends when the task does. It will never be the one maintaining this function, so the maintenance cost is, from where it stands, zero.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Shortcuts in Code Everyone Maintains

NEVER take a shortcut in shared code that you wouldn't defend to the person maintaining it in six months. The more callers, readers, and teams a file has, the higher the bar — not lower because you're in a hurry.

You get the time saved; everyone else inherits the cost, multiplied by every developer who touches the file. Shared code also gets imitated, so your shortcut becomes tomorrow's pattern.

- No caller-specific special cases inside shared functions (`if (callerIsReports) ...`). If one caller needs different behavior, that logic belongs in the caller.
- No swallowed errors, bare excepts, or empty catch blocks in shared paths. Someone else will spend a night discovering what you silenced.
- No magic sleeps, retries-until-it-works, or timing hacks to get past flakiness in shared code. Flag the flakiness instead.
- No copy-pasting a shared block to avoid touching the original. Divergent copies are the slowest-burning fire in a codebase.
- No `TODO: do this properly` as a substitute for doing it properly in code with multiple consumers. If a genuine stopgap is required, say so in your summary so a human can accept the debt knowingly.
- It's fine to cut corners in genuinely throwaway code — scratch scripts, spikes, your own sandbox. The rule is about code other people must maintain.

**Red flags that you're about to violate this:**
- "I'll special-case my caller inside the helper; it's the fastest fix."
- "Catching and ignoring this error gets the task done."
- "A 500ms sleep fixes the race well enough."
- "I'll copy this function rather than risk changing the shared one."
- "TODO-properly-later is fine; someone will get to it."

---

## Why It Works

1. **It names the asymmetry** — benefit to the author, cost to the maintainers — which is precisely the externality the AI's task-scoped objective can't see on its own.
2. **It scales the bar with sharedness** instead of applying one standard everywhere, so the rule spends its strictness where the multiplication factor is highest.
3. **It enumerates the actual shortcut taxonomy** (special cases, swallowed errors, sleeps, copies, TODOs) rather than saying "write good code," which an AI under pressure will always interpret charitably.
4. **It keeps an honest escape valve** — declared, human-approved stopgaps — so the rule doesn't collapse the first time a real deadline shows up.

## Origin

To make one report render, an assistant added a special case to a shared serializer: if the object had no owner, substitute an empty string instead of raising. Four other teams used that serializer; the raise was how two of them detected orphaned records. Over the next quarter, orphans accumulated silently until a data-quality audit found eleven thousand of them. The remediation took three weeks. The original shortcut had saved roughly twenty minutes.
