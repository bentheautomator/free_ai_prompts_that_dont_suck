---
title: No Unrequested Compat Shims
slug: no-unrequested-compat-shims
category: scope
tags: [universal, scope, over-engineering]
works_with: all
severity: medium
one_liner: "AI adding backwards-compatibility shims and aliases nobody requested"
---

# No Unrequested Compat Shims

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from keeping deprecated aliases, dual signatures, and fallback paths around changes that were supposed to be clean.

**[Copy-paste ready version](../../install/no-unrequested-compat-shims.md)** — just the instruction block, no explanation.

## The Problem

You ask the AI to rename a function, change a signature, or restructure a payload. It does — and also leaves the old name behind as a deprecated alias, accepts both the old and new argument forms with a runtime check, writes the old field into the output "for consumers that might still read it," and adds a comment promising removal in some future version that no process will ever trigger. You asked for a change. You received the change plus a museum exhibit of the previous behavior.

This is a habit learned from public library code, where unknown external callers justify deprecation cycles. In an application codebase, the AI can see every caller — it often just updated all of them in the same diff. The shim protects nobody. What it does instead is guarantee two code paths where one was requested: double the tests needed (and usually not written), a lingering old name that new code keeps importing because autocomplete offers it, and a "temporary" branch that survives until someone is brave enough to delete what the AI didn't.

The result is a codebase that never finishes migrating from anything, with every rename leaving a fossil layer behind.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Unrequested Compat Shims

When asked to rename, restructure, or change an interface, make the change completely. NEVER leave behind aliases, dual-format handling, fallback fields, or deprecated wrappers unless backwards compatibility was explicitly requested.

The core problem: in a codebase where all callers are visible and updatable, a compat shim protects no one and permanently doubles the code paths for the changed behavior.

- A rename means: new name everywhere, old name gone; update all call sites in the same change
- Do not keep `old_name = new_name` aliases, re-exports of the old symbol, or wrapper functions that forward to the new one
- Do not accept both old and new argument shapes, emit both old and new fields, or branch on payload format "just in case"
- Do not add deprecation warnings for code paths you removed in the same diff; that is compatibility theater
- Compatibility IS warranted when callers genuinely exist outside the change's reach: published packages, external API consumers, persisted data, other teams' services. If you believe that applies, stop and ask before building the shim
- If you cannot find or update some internal caller, say which one, rather than shimming around it silently

**Red flags that you're about to violate this:**
- "I'll keep the old name as an alias just in case..."
- "Supporting both formats makes this a safer migration..."
- "Something might still call the old signature..."
- "I'll mark it deprecated and it can be removed later..."
- "Leaving a fallback costs nothing and prevents breakage..."
- "Better to be defensive about callers I can't see..."

---

## Why It Works

1. **It distinguishes library reflexes from application reality.** The AI applies public-API caution everywhere; explicitly contrasting visible-caller codebases with published interfaces tells it which regime it's in.

2. **It defines "complete" for a rename.** Without "old name gone," the AI can claim success while leaving the alias, satisfying the letter of the request and defeating its purpose.

3. **It converts hidden uncertainty into a question.** The shim is often a hedge against callers the AI didn't search for. Requiring it to name the unreachable caller or ask first replaces silent hedging with information.

4. **It calls out compatibility theater.** Deprecation warnings on same-diff removals are pure ritual; naming the pattern makes it embarrassing to produce.

## Origin

A team asked an assistant to rename a confusingly named internal method as part of a cleanup ticket. The assistant renamed it, updated all nine callers, and also left the old method as a forwarding wrapper "for compatibility." Over the next quarter, autocomplete steered six new call sites to the deprecated wrapper, and the cleanup ticket's successor — "remove the old method" — was reopened twice. The rename that was completed in one diff took four months to actually finish.
