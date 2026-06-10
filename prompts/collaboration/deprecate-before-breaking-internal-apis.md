---
title: Deprecate Before Breaking Internal APIs
slug: deprecate-before-breaking-internal-apis
category: collaboration
tags: [universal, teamwork, contracts]
works_with: all
severity: high
one_liner: "Stops removing or changing internal library interfaces with no deprecation"
---

# Deprecate Before Breaking Internal APIs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing or removing the public interface of an internal library without a deprecation path for the teams using it.

**[Copy-paste ready version](../../install/deprecate-before-breaking-internal-apis.md)** — just the instruction block, no explanation.

## The Problem

"Internal" is doing dangerous work in the phrase "internal library." The AI hears it as "low stakes" — no external customers, so it can rename `getUser` to `fetchUser`, remove a parameter, change a return type, or delete a "redundant" exported function in one decisive commit. But internal libraries have external consumers; they're just external to the repo, not the company. Other teams import that interface, build against it, and schedule their work assuming it won't vanish between Tuesday and Wednesday.

A breaking change without deprecation converts the library author's five-minute rename into mandatory, unscheduled work for every consuming team — and they don't get to choose when. They find out when their build breaks on the next upgrade, mid-sprint, mid-incident, or mid-Friday-deploy. The total cost is the same rename multiplied by N teams, plus N interruptions, plus the erosion of the only thing that makes shared libraries viable: the assumption that interfaces are stable enough to build on.

The AI does this because cleanly cutting over to the new interface is the shortest edit path, and because consumers are invisible from inside the library. Deprecation — keeping the old name alive, forwarding to the new one, marking it, announcing it — looks like clutter to an optimizer that can't see who needs the grace period.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Deprecate Before Breaking Internal APIs

NEVER make a breaking change to an internal library's public interface in one step. Internal consumers are still consumers: removed functions, renamed exports, changed signatures, and changed return types all require a deprecation period, not a cutover.

A no-warning break turns your five-minute rename into unscheduled work for every consuming team, at a time none of them chose.

- "Public interface" means anything a consumer can import or observe: exported functions and types, parameters, return shapes, thrown error types, documented behavior.
- To rename or replace: add the new interface, make the old one forward to it, mark the old one deprecated using the language's mechanism (`@deprecated`, `DeprecationWarning`, compiler attributes) with a message naming the replacement. Remove it only later, as its own announced change.
- To remove: deprecate first with a warning that states the replacement or the reason, and let at least one release cycle pass.
- Never change a signature in place. Add the new parameter with a compatible default, or add a sibling function.
- In a monorepo where you can see and update every consumer atomically, a one-step change is acceptable — only if you actually update all of them in the same change and say so.
- State in your summary which interfaces you deprecated and what the removal path is.

**Red flags that you're about to violate this:**
- "It's an internal library; there are no real consumers."
- "Keeping the old name around is clutter; a clean cutover is simpler."
- "The new signature is obviously better; people will adapt."
- "Anyone still using this function should stop anyway."
- "I'll grep for usages later; first the rename."

---

## Why It Works

1. **It deletes the internal-equals-unimportant heuristic** by defining consumers organizationally rather than by repo boundary.
2. **It converts breaks into schedulable work** — deprecation warnings let each consuming team migrate when they choose, which is the entire difference between an upgrade and an interruption.
3. **It uses machine-readable deprecation**, so the migration pressure shows up in consumers' builds and editors automatically instead of depending on anyone reading an announcement.
4. **It carves out the atomic-monorepo case precisely**, keeping the rule credible by permitting one-step changes exactly when the author can genuinely fix every consumer.

## Origin

A platform team's assistant renamed `createClient(config)` to `newClient(options)` in an internal SDK — cleaner, more idiomatic, shipped in a minor version with the old function deleted. Four consuming teams' builds broke over the following two weeks as each picked up the version, each filing their own confused ticket. The fourth team was mid-incident when their hotfix branch wouldn't compile against the SDK. Total migration effort was trivial; the cost was that nobody got to schedule it.
