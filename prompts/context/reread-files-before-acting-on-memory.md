---
title: Re-Read Files Before Acting on Old Memory
slug: reread-files-before-acting-on-memory
category: context
tags: [universal, staleness, verification]
works_with: all
severity: critical
one_liner: "AI editing from a 40-message-old snapshot and reverting newer changes"
---

# Re-Read Files Before Acting on Old Memory

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from treating a file it read an hour ago as a file it knows now.

**[Copy-paste ready version](../../install/reread-files-before-acting-on-memory.md)** — just the instruction block, no explanation.

## The Problem

Forty messages ago the AI read `payment_service.py`. Since then: the AI itself edited it twice, the user fixed something by hand, and a `git pull` happened mid-session. Now the AI is asked to make one more change — and it reasons from the version in its context window, the one from forty messages ago. The edit lands on code that no longer exists, or worse, the AI "restores" lines around its change, silently reverting the user's hand-fix.

This is the staleness trap: inside the context window, all snapshots of a file look equally current. There's no timestamp on memory. The AI read the file, therefore it "knows" the file — even though that knowledge has a shelf life measured in messages, not facts. Long sessions make it worse: the more productive the session, the more the codebase has drifted from the transcript.

The damage profile is nasty because it's subtractive. Reverted fixes don't announce themselves. The user discovers them later, when the bug they already fixed comes back, and the git blame points at a commit that was supposed to be about something else entirely.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Re-Read Files Before Acting on Old Memory

NEVER reason about or edit a file based on a version you read earlier in the session if anything could have changed it since — your edits, the user's edits, a pull, a generator, a formatter. Your memory of a file is a snapshot with no expiration warning; the filesystem is the only current version.

Acting on a stale snapshot doesn't just produce wrong edits — it silently reverts other people's work, which is the most expensive failure an assistant can commit.

**Operating rules:**
- Re-read any file before editing it if you last read it more than a few messages ago, or if any edit, command, pull, or user action has touched the project since
- After running formatters, codegen, migrations, or `git pull`/`git checkout`, treat ALL prior file knowledge as expired
- If the user says they changed something by hand, re-read every file they might have touched before your next edit
- When an edit fails to match (anchor text not found), that is proof your snapshot is stale — re-read the whole file, never retry with a looser match
- Quote current file contents when explaining code, not contents from earlier in the transcript

**Red flags that you're about to violate this:**
- "I read this file earlier, so I know what's in it..."
- "Nothing important should have changed since then..."
- "I'll just reconstruct the section around my edit..."
- "The match failed — I'll try a fuzzier version of the old text..."
- "The user's change was probably somewhere else in the file..."
- Writing out a full replacement for a file you haven't opened since before the last `git` command

---

## Why It Works

1. **It gives memory a shelf life.** The model has no native concept of snapshot staleness — every read feels current. Framing file knowledge as "expired after intervening events" creates the missing timestamp.

2. **It converts the failed-match signal into a tripwire.** When an edit anchor doesn't match, the AI's default move is to loosen the match and force the edit through. Redefining that moment as *proof of staleness* turns the most dangerous reflex into a mandatory re-read.

3. **It names the silent-revert hazard explicitly.** "Wrong edit" sounds recoverable; "silently reverting someone's work" sounds like what it is. The stakes justify the extra read.

4. **It enumerates the invalidation events.** Pulls, formatters, codegen, hand-edits — listing them removes the "nothing relevant happened" judgment call.

## Origin

During a long pairing session, a developer hot-fixed a race condition by hand while the AI worked on an unrelated feature in the same module. Twenty minutes later the AI made its edit by rewriting the full function — from its memory of the pre-fix version. The race condition shipped that evening inside a commit labeled "add retry logic." It took two days and one very confused on-call engineer to figure out how a fixed bug had un-fixed itself.
