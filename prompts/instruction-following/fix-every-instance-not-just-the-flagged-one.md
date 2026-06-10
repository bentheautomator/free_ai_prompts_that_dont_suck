---
title: Fix Every Instance Not Just the Flagged One
slug: fix-every-instance-not-just-the-flagged-one
category: instruction-following
tags: [universal, rules, compliance]
works_with: all
severity: medium
one_liner: "AI fixes the violation you pointed at and leaves its twins alone"
---

# Fix Every Instance Not Just the Flagged One

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from treating your correction as being about one line when the same violation exists throughout its work.

**[Copy-paste ready version](../../install/fix-every-instance-not-just-the-flagged-one.md)** — just the instruction block, no explanation.

## The Problem

You review the AI's change and point at line 52: "We don't swallow exceptions — re-raise with context." The AI fixes line 52, thanks you for the catch, and moves on — past the identical swallowed exceptions on lines 88, 130, and in the second file it touched. You flagged one instance as an *example* of a problem. The AI processed it as the *extent* of the problem.

The mechanics are literal-minded in a specific way: the correction arrived with a location attached, so the fix gets scoped to the location. Searching the rest of the work for the same pattern would require treating your comment as a rule with instances rather than an instance with a fix — an inference step that doesn't happen by default. The cost structure is brutal for the user: they must either re-review everything after each comment (defeating the point of delegating) or play whack-a-mole, flagging the same violation once per occurrence while the AI cheerfully fixes exactly what's pointed at, every time.

A reviewer who flags one swallowed exception has told you something about all swallowed exceptions. The location was a courtesy, not a boundary.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Fix Every Instance Not Just the Flagged One

When the user flags a violation at one location, ALWAYS search your work for other instances of the same violation and fix them all. The flagged line is an example, not the extent.

**The core problem:** Corrections arrive with a location attached, so you scope the fix to the location. But the user flagged one instance of a *pattern* — they're telling you about the pattern, and they expect you to find its other occurrences, not to flag each one individually.

**Do this:**

- On any correction, first extract the pattern behind it ("swallowed exceptions" — not "line 52")
- Then sweep everything you've touched this session for the same pattern: other lines, other functions, other files — and fix every instance
- Report the sweep with your fix: "Fixed on line 52, plus 3 more instances of the same pattern (lines 88, 130, and in payments.py)"
- Check near-variants too: if bare `except: pass` was flagged, `except Exception: return None` deserves a look — flag-worthy patterns have cousins

**Do not:**

- Fix exactly the flagged location and stop
- Assume the user reviewed everything and flagged all instances — finding one is usually when they stopped reading and told you
- Wait to be asked "are there others?" — the sweep is part of the fix

**Red flags that you're about to violate this:**

- "Fixed the line they pointed at — done"
- "If the other spots were a problem, they'd have flagged those too"
- "Their comment was specifically about this function"
- "Searching the whole change for this pattern wasn't requested"
- "I'll fix others if they come up"

---

## Why It Works

1. **It re-types the correction.** The failure comes from classifying the comment as "an instance with a fix" instead of "a rule with instances." Mandating pattern extraction *before* fixing forces the correct classification at the moment it goes wrong.

2. **It corrects the model of the reviewer.** "They'd have flagged the others too" assumes complete review. Stating the truer dynamic — finding one instance is typically when the user stopped reading — removes the assumption that silence about lines 88 and 130 means approval.

3. **It builds the sweep into the deliverable.** When the fix report must include "plus N more instances," a location-scoped fix becomes structurally incomplete — the AI can't write the sentence without having done the search.

4. **It extends to cousins.** Pattern violations rarely repeat verbatim; near-variants are how they escape a literal search. The explicit nudge toward variants closes the gap between "same string" and "same problem."

## Origin

During review of an AI-written data importer, a developer flagged one spot where a parse failure was logged and skipped: "Bad rows must go to the dead-letter file, not just the log." The AI fixed that spot impeccably. The importer had five other catch blocks with the same log-and-skip behavior, all untouched. In the first production run, twelve thousand unparseable rows vanished into logs nobody read, discovered only during a reconciliation audit a month later. The developer had described the policy precisely. The AI had applied it to one of six doors.
