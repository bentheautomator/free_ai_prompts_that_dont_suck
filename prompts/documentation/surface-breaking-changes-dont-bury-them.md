---
title: Surface Breaking Changes, Don't Bury Them
slug: surface-breaking-changes-dont-bury-them
category: documentation
tags: [universal, docs, changelog]
works_with: all
severity: high
one_liner: "Breaking changes hidden mid-list in docs where no upgrader will see them"
---

# Surface Breaking Changes, Don't Bury Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents breaking-change notes from being buried mid-list in changelogs and docs where the people they would have warned never see them.

**[Copy-paste ready version](../../install/surface-breaking-changes-dont-bury-them.md)** — just the instruction block, no explanation.

## The Problem

The release notes list eleven items. Item seven, between "Improved log formatting" and "Updated dev dependencies," reads: "Changed: `parse()` now throws on malformed input instead of returning null." That's not a changelog entry, that's a landmine with a label, filed alphabetically. Upgraders skim release notes the way everyone skims release notes — looking for a BREAKING marker, a migration section, anything visually loud — see nothing loud, and upgrade. Production finds item seven for them.

AI assistants bury breaking changes because they treat documentation as a recording medium rather than a signaling medium. The change *is* documented; the model's obligation, as it understands it, is discharged. But docs about danger are judged by whether the warning *lands*, not whether it exists. A breaking change noted with the same weight as a logging tweak is information-theoretically present and practically absent.

The same failure shows up outside changelogs: a migration-required note in the middle of a doc page's third paragraph, or a "note that this changes the default" sentence at the bottom of a long PR-adjacent doc update.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Surface Breaking Changes, Don't Bury Them

ALWAYS give breaking changes top billing in any document that mentions them. A breaking change recorded where skimmers won't see it is undocumented with extra steps.

The problem: readers skim docs and changelogs for visual danger signals. A breaking change written with the same prominence as routine items transmits no warning, only deniability.

Rules:
- In changelogs and release notes, breaking changes go first, under an explicit `### Breaking Changes` (or the project's equivalent, e.g. `BREAKING CHANGE:` footers for conventional commits) heading, never interleaved with fixes and chores
- Every breaking entry states three things: what breaks (the exact API/config/behavior), who is affected (callers doing X), and what to do about it (the migration step)
- Use the word "breaking." Not "changed," not "updated," not "improved." Euphemisms are how landmines get filed under landscaping
- In doc pages, a behavior change that invalidates existing usage gets a visible callout (admonition, bold warning block) near the top of the affected section, not a sentence mid-paragraph
- If your change is breaking and the docs structure has no place to surface it, say so to the user rather than tucking it wherever fits
- Severity is about the reader's blast radius, not your diff size; a one-line default change that alters behavior for existing users is breaking

**Red flags that you're about to violate this:**
- "It's mentioned in the changelog, so it's documented..."
- "'Changed' is technically accurate and less alarming..."
- "It only breaks unusual usage, no need to headline it..."
- "The list is chronological; reordering feels wrong..."
- "I don't want the release notes to look scary..."
- "The migration is obvious, no need to spell it out..."

---

## Why It Works

1. **It matches the writing to the reading.** Upgraders skim for danger markers; they do not read item seven. Putting breaking changes first under an explicit heading places the warning where the actual eyeballs go.

2. **The what/who/how-to-migrate triple makes warnings actionable.** "Breaking: parse() changed" causes anxiety; "callers relying on null returns must add a try/catch" causes a correct upgrade. Action beats alarm.

3. **It bans the euphemism channel.** "Changed" vs "breaking" is the difference between information and cover. Mandating the word removes the soft-pedal option models reach for to keep docs pleasant.

4. **It scopes severity by blast radius.** Models rank entries by diff size, which is why one-line default changes get buried. Re-anchoring on reader impact reorders the list correctly.

## Origin

A service's release notes documented an auth token format change as item nine of fourteen: "Updated token serialization for consistency." Every consuming team skimmed past it, upgraded, and spent the next morning debugging 401s in three separate war rooms before someone read the full list. The entry was accurate, complete, and seen by nobody until after the incident it described. The next release had a Breaking Changes section at the top, with one entry, in bold.
