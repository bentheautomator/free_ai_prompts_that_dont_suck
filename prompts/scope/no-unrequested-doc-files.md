---
title: No Unrequested Doc Files
slug: no-unrequested-doc-files
category: scope
tags: [universal, scope]
works_with: all
severity: medium
one_liner: "AI generating README and docs files nobody asked for"
---

# No Unrequested Doc Files

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from depositing README, summary, and architecture documents into the repo as a side effect of coding tasks.

**[Copy-paste ready version](../../install/no-unrequested-doc-files.md)** — just the instruction block, no explanation.

## The Problem

The feature is done — and so, apparently, is `FEATURE_NOTES.md`, a fresh `docs/architecture-overview.md`, an updated README section describing the change, and sometimes a `CHANGES.md` summarizing what the AI did, written in the repo as if the repo were a chat window. None of these were requested. Agentic assistants are especially prone to this: finishing a task and "documenting the work" by creating Markdown files feels like wrapping up professionally.

Every one of these files is repo litter with a long half-life. Unlike a chat summary, a committed document persists, shows up in searches, and speaks with the repo's authority — so when it drifts (and unmaintained docs always drift), it actively misleads. The generated content is also the weakest kind of documentation: descriptions of what the code does, inferred from the code, adding no intent, no decisions, no why. Teams end up with a `docs/` directory where three AI-generated overviews of different vintages disagree with each other and with the code, and the genuinely curated README has new sections nobody owns.

Documentation has an audience and a maintainer or it shouldn't exist. A task summary belongs in the task's final message, the commit message, or the PR description — places designed for ephemeral context — not in version control.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Unrequested Doc Files

NEVER create documentation files (README, notes, summaries, architecture docs, changelogs) unless the user explicitly asked for documentation. Report your work in your reply, not in the repo.

The core problem: a committed document persists and speaks with the repo's authority, so unrequested docs become unowned, drifting artifacts that mislead long after the task that excreted them.

- Finishing a task does not include creating a Markdown file about the task; the summary goes in your final message, the commit message, or the PR description
- No new README.md, NOTES.md, TODO.md, CHANGELOG entries, or `docs/` files as a byproduct of feature or fix work
- Do not append "what changed" sections to existing READMEs or docs uninvited
- If your code change makes an existing document factually wrong (a renamed command, a changed setup step), updating that specific passage is in scope; keeping docs true is maintenance, creating docs is scope
- When documentation genuinely seems needed (a gnarly setup, a non-obvious invariant), offer it: "Want me to document X in the README?" One line, user decides
- If explicitly asked to document, write for the stated audience and put it where the project already keeps docs, rather than inventing a new location

**Red flags that you're about to violate this:**
- "I'll create a summary document of the changes I made..."
- "This deserves an architecture overview for future contributors..."
- "Adding a README section so people know about the new feature..."
- "I'll leave a notes file explaining my implementation decisions..."
- "Good projects document everything, this one's missing docs..."

---

## Why It Works

1. **It redirects the completion ritual.** The AI wants a "deliverable" that marks the work done; naming the final message, commit, and PR description as the proper homes satisfies the ritual without committing artifacts.

2. **It contrasts persistence with authority.** A chat summary expires harmlessly; a committed file misleads forever; making that asymmetry explicit shows why the repo is the wrong place for ephemera.

3. **It keeps the true-docs duty.** Correcting passages your change falsified is required, which prevents the rule from rotting into "never touch documentation" and keeps existing docs from silently going stale.

4. **It exposes the docs' weakness.** Code-derived descriptions add no intent; saying so deflates the sense that generating them is a contribution.

## Origin

After a quarter of heavy assistant use, a team found nine AI-generated Markdown files in their repo: three overlapping architecture overviews, two "implementation notes" files, and four feature summaries, no two consistent. A new hire followed the most confident-looking overview and spent two days building against a module structure that had been refactored away months earlier. The cleanup PR deleting all nine files was the easiest approval in the repo's history.
