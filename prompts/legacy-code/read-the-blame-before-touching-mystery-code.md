---
title: Read the Blame Before Touching Mystery Code
slug: read-the-blame-before-touching-mystery-code
category: legacy-code
tags: [universal, legacy, foundational]
works_with: all
severity: high
one_liner: "Requires git archaeology before edits to code nobody on the team understands"
---

# Read the Blame Before Touching Mystery Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from editing code nobody understands using only what's visible in the file, when the explanation is sitting in git history.

**[Copy-paste ready version](../../install/read-the-blame-before-touching-mystery-code.md)** — just the instruction block, no explanation.

## The Problem

Every legacy codebase has modules nobody currently on the team understands. When an AI assistant is asked to change one, its default move is to read the file, build a mental model from the code as written, and edit based on that model. The file, though, is the artifact with the least context: comments rotted away, the variable names lie, and the reasons live elsewhere — in commit messages, in the PR thread where two engineers argued about the locking order, in the incident that produced the hotfix. The repository's history is a second codebase made of explanations, and the AI ignores it because reading the present is faster than reading the past.

Editing mystery code from the file alone means re-deriving the module's constraints from scratch and hoping you derive all of them. The constraints you miss are by definition the ones that aren't visible in the code — ordering requirements, timing assumptions, agreements with other systems. Those are exactly the ones that page someone at 3 a.m.

This is archaeology before surgery: not optional reverence for old code, but the cheapest available source of facts about it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read the Blame Before Touching Mystery Code

ALWAYS read the history of code before modifying it when the code's purpose or structure is not obvious. The file shows you what the code does; only the history shows you why. Editing "why-less" is how invisible constraints get broken.

Minimum archaeology before editing code you don't fully understand:

- `git log --follow` on the file: how old is it, how often does it change, what do the commit messages say the changes were for? A file with twelve commits titled "fix race" is telling you what it's defending against.
- `git blame` on the specific lines you'll modify: find the commit that created them and read its full message. Follow ticket or PR numbers if the messages reference them.
- Note hotfix signatures: tiny commits, urgent wording, off-hours timestamps. Lines born in an incident encode that incident.
- If history is uninformative (squashed away, imported from another repo, messages like "wip"), say so explicitly and treat the code as higher-risk: smaller changes, more validation, flag uncertainty to the user.
- Summarize what you learned in one or two lines before proposing the change: "History: added 2016 for X, last meaningful change 2021 for Y." If you can't fill in that sentence, you're not ready to edit.

Budget guidance: this costs two to five minutes. The bugs it prevents cost days.

**Red flags that you're about to violate this:**
- "I can see what this code does, that's enough to change it."
- "The history is probably just noise anyway."
- "This change is small enough that context doesn't matter."
- "Reading old commits is a waste of the user's time."
- "The code is self-explanatory even though nobody understands it."

---

## Why It Works

1. **It reclassifies history as a data source, not a courtesy.** Commit messages and PR threads are where dead teams left their reasoning; reading them is information retrieval, not ritual.
2. **The summary requirement is a forcing function.** Having to state "added for X in year Y" makes skipped archaeology visible — the AI can't silently pretend it looked.
3. **Hotfix signatures are a learnable pattern.** Teaching the AI to spot incident-born lines gives it a concrete trigger for extra caution instead of a general mood of carefulness.
4. **The uninformative-history clause prevents the loophole** where bad commit messages become an excuse to proceed at full confidence rather than reduced confidence.

## Origin

A queue consumer contained an acknowledgment call placed before the processing step — backwards by every tutorial. An assistant asked to add a metrics hook reordered it to the "correct" sequence while it was in there. The blame on that line pointed to a commit titled "ack first: broker redelivers on slow processing and we double-send notifications," written during an incident four years earlier by an engineer who had since left. Nobody on the current team knew. The reorder shipped, the broker did what the commit said it would, and customers got duplicate notifications for six hours — an incident whose complete root-cause analysis already existed, one `git blame` away, the whole time.
