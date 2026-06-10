---
title: Check History Before Deleting Commented-Out Code
slug: check-history-before-deleting-commented-code
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: medium
one_liner: "Preserves the why behind commented-out code instead of erasing the record"
---

# Check History Before Deleting Commented-Out Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from sweeping away commented-out blocks without first learning why they were commented out instead of deleted.

**[Copy-paste ready version](../../install/check-history-before-deleting-commented-code.md)** — just the instruction block, no explanation.

## The Problem

"Delete commented-out code, that's what version control is for" is good advice that AI assistants apply with zero judgment. The advice assumes the commented block is lazy clutter. Often it isn't. Someone chose to comment it out rather than delete it, and that choice is a signal: the block is disabled pending a vendor fix, it's the next approach someone half-validated, it's a trap documented in place ("we tried this, it corrupts the cache"), or it's toggled back on during specific operational events. The comment-instead-of-delete decision encoded information; deleting the block destroys it.

The standard rebuttal — "it's in git history" — is technically true and practically false. Code that exists in a file gets read by everyone who opens the file. Code that exists only in history gets read by nobody, because nobody knows to look for it. A warning that's been moved to git history has been moved to /dev/null with extra steps.

AI assistants delete these blocks eagerly because commented-out code is a textbook smell, the deletion can't break the build, and the diff looks like pure hygiene. The cost is invisible: it's paid months later by whoever re-attempts the documented dead end.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check History Before Deleting Commented-Out Code

NEVER delete a commented-out block without first finding out why it was commented out rather than deleted. Someone made that choice deliberately; your job is to learn the reason before destroying the record.

For each commented-out block you want to remove:

- Run `git log -p` or `git blame` on those lines. Find the commit that commented them out and read its message. "Disable retry until vendor fixes rate limiting" means the block is dormant, not dead.
- Read any prose comment attached to the block. "DO NOT re-enable, corrupts session cache" is documentation of a landmine — deleting it re-arms the landmine for the next person.
- Check whether the block references things that still exist: live config keys, current endpoints, active feature names. A commented block full of live references is more likely paused than abandoned.
- If the history shows it was commented out as a quick disable during an incident, flag it to the user — the right fix may be re-enabling or properly removing, and that's their call.
- If the history shows pure clutter (commented out in the same commit that replaced it, years ago, no explanation needed), delete it freely. That's the case the hygiene rule was written for.

When you do delete, put the why in the commit message so the record survives in a findable form.

**Red flags that you're about to violate this:**
- "Commented-out code is always safe to delete, it's not even running."
- "If it mattered, it wouldn't be commented out."
- "Git history has it if anyone ever needs it."
- "I'll clean up all the commented blocks in this file in one pass."
- "There's no explanation, so it's clearly just clutter."

---

## Why It Works

1. **It distinguishes dormant from dead.** The hygiene rule treats all commented code as one category; the instruction splits it into "paused," "warning," and "clutter," and only the last is deletable on sight.
2. **It targets the actual information channel.** Commented-out code works as documentation precisely because it's in the file; the instruction makes the AI account for what's lost when that channel is cut.
3. **The git-blame step is cheap and decisive.** The commit that commented the block out almost always says why, turning a judgment call into a lookup.
4. **It still permits real cleanup.** By defining the genuinely-deletable case, the rule avoids becoming "never touch comments," which nobody would keep enabled.

## Origin

A cleanup pass removed a commented-out block in a job scheduler along with its one-line note: re-enable during regional failover only. The block was the manual failover path, kept commented because running it during normal operation double-scheduled jobs. At the next failover drill, the runbook said "uncomment the failover block" and the block did not exist. The drill failed, the block was reconstructed from history under time pressure, and the reconstruction had a typo that the original, battle-tested version did not.
