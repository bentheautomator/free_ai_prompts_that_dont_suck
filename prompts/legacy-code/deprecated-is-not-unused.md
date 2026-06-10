---
title: Deprecated Is Not Unused
slug: deprecated-is-not-unused
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: high
one_liner: "Stops deletion of deprecated code that production callers still depend on"
---

# Deprecated Is Not Unused

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from reading a deprecation marker as a deletion ticket while live callers still run through the deprecated path.

**[Copy-paste ready version](../../install/deprecated-is-not-unused.md)** — just the instruction block, no explanation.

## The Problem

Deprecation is a message to future callers: don't build on this. AI assistants routinely read it as a message about current callers: nothing depends on this. The two claims are nearly opposites. Code gets deprecated *because* it has callers — if it had none, it would simply be deleted. An `@deprecated` annotation, a `Deprecated:` docstring, or a `legacy_` prefix is a promise that the thing keeps working while consumers migrate at their own pace. Deleting it mid-migration converts a polite warning into an outage.

The misreading is understandable: deprecation markers cluster with genuinely removable code, and tooling reinforces it — IDEs strike through deprecated symbols like they're already gone. An assistant doing cleanup sees the strikethrough aesthetic and finishes the job. But the deprecation date tells you when the warning started, not when the callers left. Some deprecated APIs carry more production traffic than their replacements for years, because the replacement is worse, the migration is expensive, or the consumers belong to other teams with other priorities.

The result of premature deletion is the worst kind of breakage: every consumer who did the responsible thing — kept using the supported-but-deprecated path while planning migration — breaks at once.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Deprecated Is Not Unused

NEVER treat a deprecation marker as evidence that code is unused or removable. Deprecated means "stop adding callers"; it does not mean the existing callers left. Code is deprecated precisely because it still has consumers who need time to migrate.

When you encounter deprecated code:

- Do not delete it, even during cleanup tasks, unless the user explicitly asked for its removal.
- If removal is requested, enumerate the callers first: search the repo, search for the symbol name as a string (configs, templates, serialized data), and ask about consumers outside the repo — other services, other teams, public API users.
- Check the deprecation's terms. Annotations, docstrings, and changelogs often state a removal version or date ("removed in v5"). Removing earlier than the stated promise breaks consumers who planned around it.
- Distinguish the two ends of deprecation: marking something deprecated is cheap and safe; removing something deprecated is a breaking change that needs the same care as deleting any live API.
- Never route around deprecation the other way either: don't "fix" callers of deprecated code as a side effect of unrelated work. Migration to the replacement is its own task with its own risks.

If you need a mental model: deprecated code is on notice, not on the curb.

**Red flags that you're about to violate this:**
- "It's marked deprecated, so removing it is just finishing the process."
- "The replacement has existed for three years; everyone's migrated by now."
- "The IDE shows it struck through, it's basically dead already."
- "Deleting deprecated code is what cleanup means."
- "If callers still existed, the deprecation would have been reverted."
- "I'll remove it now and callers can switch to the new API when they notice."

---

## Why It Works

1. **It corrects a definitional error at the root.** The failure isn't recklessness, it's a wrong dictionary entry; redefining deprecated as "has callers, by construction" fixes every downstream decision.
2. **It splits marking from removing.** The AI's cleanup energy gets a clear boundary: one side of deprecation is hygiene, the other is a breaking change with a caller-enumeration cost.
3. **The stated-terms check exploits existing promises.** Deprecation notices usually contain their own removal schedule; making the AI read it replaces guesswork with the original author's contract.
4. **The side-effect ban covers the quiet path:** half of premature removals happen as riders on other work, where "while I'm here" skips every check above.

## Origin

An internal SDK kept a deprecated `fetchAll()` alongside its paginated replacement, with the deprecation notice promising removal "no earlier than the next major version." An assistant asked to tidy the module deleted it nine months ahead of that promise, reasoning that two release cycles of warning was plenty. Fourteen internal services were still calling it — every one of them tracking the migration in their backlog, exactly as the deprecation process intended. The deploy broke three of them in production within the hour, and the SDK team spent the next day shipping a restore release and apologizing for breaking their own published contract.
