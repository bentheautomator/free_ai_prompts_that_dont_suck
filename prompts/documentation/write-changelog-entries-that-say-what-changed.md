---
title: Write Changelog Entries That Say What Changed
slug: write-changelog-entries-that-say-what-changed
category: documentation
tags: [universal, docs, changelog]
works_with: all
severity: medium
one_liner: "Changelog entries like 'various improvements' that tell upgraders nothing"
---

# Write Changelog Entries That Say What Changed

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents changelog entries so vague that the person upgrading learns nothing from reading them.

**[Copy-paste ready version](../../install/write-changelog-entries-that-say-what-changed.md)** — just the instruction block, no explanation.

## The Problem

"Improved error handling." Improved how? For which errors? Does my retry wrapper still work? "Fixed an issue with date parsing." Which issue? The one I have? "Updated dependencies." Which ones, and did any of them drop Node 16? A vague changelog entry has the cost of writing and the value of whitespace: it occupies the line where the answer should be.

AI assistants write these because vagueness is the safe-sounding default. A specific claim ("dates without timezones are now parsed as UTC instead of local time") can be wrong; "improved date handling" cannot. The model optimizes for an entry that no one can object to, which is exactly the entry no one can use. It also mimics the genre: real-world changelogs are full of "minor fixes and improvements," so the training distribution rewards mush.

The reader of a changelog has one question: *do I need to do anything when I upgrade?* Every entry that doesn't help answer that question is noise wearing documentation's clothes.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Write Changelog Entries That Say What Changed

NEVER write a changelog entry that an upgrading user can't act on. Every entry must say what concretely changed and, where relevant, what was true before.

The problem: vague entries ("improved X", "fixed an issue", "various updates") read as documentation but carry zero information, so upgraders either re-test everything or get surprised.

Rules:
- State the observable change: "Retries now use exponential backoff (was: fixed 1s delay)" not "Improved retry logic"
- For bug fixes, name the broken behavior: "Fixed crash when config file is empty" not "Fixed a config bug"
- For behavior changes, include the before and the after; the delta is the entire point of the entry
- Name affected surfaces specifically: the flag, the endpoint, the function, the config key
- If the change can require user action (migration, re-config, re-run), say so in the entry itself
- Write for someone who has never seen the code or the ticket; "Fixed #482" alone is a pointer, not an entry. Linking the issue is good; relying on it is not
- One specific entry per change beats one summary entry per release

**Red flags that you're about to violate this:**
- "'Various improvements' covers it safely..."
- "Anyone curious can read the diff..."
- "Being specific might overstate the change..."
- "The issue link has all the details..."
- "I'll keep it short and high-level like the other entries..."
- "I don't fully remember what changed, so I'll keep it general..."

---

## Why It Works

1. **It anchors entries to the upgrader's single question.** "Do I need to do anything?" is answerable only from specifics. Framing the reader makes the model generate facts instead of genre.

2. **The before/after format forces a falsifiable claim.** "Was X, now Y" cannot be written without knowing the change, which flushes out the cases where the model is summarizing without understanding.

3. **It severs the dependency on external context.** Issue trackers go private, tickets get deleted, diffs require expertise. An entry that stands alone keeps its value when everything around it rots.

4. **It removes the safety incentive for vagueness.** Naming that "unfalsifiable" equals "useless" flips the model's instinct that hedged entries are the responsible choice.

## Origin

A team upgraded an internal SDK across forty services after reading a changelog whose longest entry was "improvements to connection management." The improvement was that idle connections now closed after 60 seconds instead of never, which broke two services that held connections across long batch jobs. The change was deliberate, correct, and documented in six words that communicated none of it. The incident review's first action item was a changelog format with a mandatory was/now clause.
