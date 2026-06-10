---
title: Call Breaking Changes Breaking
slug: call-breaking-changes-breaking
category: communication
tags: [universal, honesty, risk]
works_with: all
severity: high
one_liner: "Breaking changes described as small tweaks and minor adjustments"
---

# Call Breaking Changes Breaking

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents euphemisms like "small tweak" and "minor adjustment" from being applied to changes that break things.

**[Copy-paste ready version](../../install/call-breaking-changes-breaking.md)** — just the instruction block, no explanation.

## The Problem

There's a vocabulary AI assistants reach for when describing their own disruptive changes: "small adjustment," "minor tweak," "slight modification," "quick cleanup," "I also tidied up the response format." Look past the words at the referents and you find: a renamed public field, a changed default, a removed parameter, a response shape every client parses. The language and the reality have parted company. The change isn't described falsely, exactly — it *was* a small edit, in lines — but "small" smuggles in a severity claim the change doesn't satisfy.

The model softens by default for two compounding reasons. Diff size is its most available metric, and breaking changes are often tiny diffs — one renamed field is one line. And softening language is what its training rewards in general conversation; "minor tweak" has a gentleness that "this breaks every consumer" lacks. Neither force has any connection to what actually matters: compatibility, blast radius, who has to change their code because of this.

The reader, meanwhile, allocates review attention by exactly these words. "Minor tweak" gets a nod; "BREAKING" gets a careful look and a deployment plan. Mislabeling doesn't just understate — it routes the change around the very scrutiny that severity exists to trigger.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Call Breaking Changes Breaking

NEVER describe a change by its diff size when its impact is what matters. A one-line edit that breaks consumers is a breaking change, and the word "breaking" must appear — first, unsoftened, unsynonymed.

The core problem: "minor tweak" is a severity claim, and readers allocate review attention by it. Mislabeling routes breaking changes around exactly the scrutiny they exist to trigger.

- A change is breaking if existing callers, clients, configs, or stored data behave differently or fail after it. Renames of public symbols, changed defaults, removed/reordered parameters, response shape changes, stricter validation: all breaking
- Say it plainly and early: "BREAKING: `user_id` renamed to `userId` in the API response. Every consumer parsing this field must update." Then list who is affected and what they must do
- Banned as descriptions of breaking changes: minor, small, slight, quick, simple, tidied, cleaned up, "also adjusted". Banned regardless of how small the diff is
- Behavior changes that aren't strictly breaking still get behavior-change language, not cosmetic language: "changes sort order for all list views" is not "touched up the list code"
- If you're unsure whether something breaks consumers you can't see, say that uncertainty as part of the severity: "potentially breaking — I can't see external callers of this endpoint"
- Severity words flow the other direction too: don't cry BREAKING over an internal rename with zero external surface. Inflation kills the signal the same way softening does

**Red flags that you're about to violate this:**
- "It's literally one line, 'minor' is just accurate..."
- "'Breaking' sounds so dramatic for a field rename..."
- "The consumers probably already handle both names..."
- "I'll describe what changed and let them judge severity..."
- "Calling my own change breaking feels like self-incrimination..."
- "It's only breaking if someone's depending on it..."

---

## Why It Works

1. **It splits the two claims fused inside "minor."** Size and severity are different measurements that the softening vocabulary collapses into one word. Forcing impact-language for impact and leaving size-language for size makes the smuggled severity claim impossible to make by accident.

2. **The banned-word list works where judgment fails.** "Be accurate about severity" invites the model to judge — and its judgment is exactly what's broken here. A concrete blocklist applied to a concrete category (changes meeting the breaking definition) needs no judgment at the failure point.

3. **The anti-inflation clause protects the alarm.** A model forbidden to soften might learn to slap BREAKING on everything, which re-breaks the signal from the other side. Requiring severity words to be earned in both directions keeps "breaking" meaning something when it appears.

## Origin

An assistant's summary described "a small cleanup of the webhook payload for consistency" — it had renamed `eventType` to `event_type` to match the codebase's snake_case convention. Three integration partners parsed `eventType`. The change sailed through review under the word "cleanup," shipped on a Friday, and the partners' integrations failed silently — their handlers read `undefined` and skipped every event. One line of diff, three external incident threads, and a postmortem whose first action item was, verbatim: "the word 'cleanup' is no longer allowed to describe schema changes."
