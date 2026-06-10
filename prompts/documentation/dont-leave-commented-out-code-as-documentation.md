---
title: Don't Leave Commented-Out Code as Documentation
slug: dont-leave-commented-out-code-as-documentation
category: documentation
tags: [universal, docs, comments]
works_with: all
severity: medium
one_liner: "Blocks of dead commented-out code left behind as a substitute for explanation"
---

# Don't Leave Commented-Out Code as Documentation

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from leaving blocks of commented-out code behind as a stand-in for actually explaining what changed and why.

**[Copy-paste ready version](../../install/dont-leave-commented-out-code-as-documentation.md)** — just the instruction block, no explanation.

## The Problem

The AI replaces a retry implementation and leaves the old one behind in a forty-line comment block, sometimes garnished with `// Old implementation kept for reference:`. The intent reads as documentation — here's what this used to do — but a fossilized code block documents nothing. It doesn't say *why* the old approach was replaced, whether it was broken or just superseded, or whether it's safe to delete. It just sits there, rotting at a different rate than the live code around it, until nobody can tell whether it's history, an alternative, or a warning.

Models leave these blocks for two reasons. First, deletion anxiety: commenting out feels reversible, deleting feels destructive, and the model doesn't trust (or doesn't think about) version control, which already makes every deletion reversible. Second, it's a cheap simulation of diligence — preserving the old code *looks* careful while skipping the genuinely careful act, which is writing one sentence about why the change happened.

Readers pay for it forever: every commented-out block is a question ("is this important?") that each new reader answers from scratch, usually by nervously leaving it alone. Some blocks survive years this way, outliving the functions they were commented out of.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Leave Commented-Out Code as Documentation

NEVER leave commented-out code behind as a record of what used to be there. Delete the old code and, if the history matters, document it in words. Version control is the archive; comments are not.

The problem: a commented-out block preserves the code but loses the context, leaving future readers a riddle that rots silently next to the live implementation.

Rules:
- When you replace code, delete the old code. Git remembers it perfectly; the comment block remembers it misleadingly, with no author, date, or reason attached
- If the replacement rationale matters to future readers, write it as prose: "// Switched from polling to webhooks; polling hit rate limits above 50 tenants" beats forty lines of dead polling code
- If an alternative was considered and rejected, document the rejection and the reason, not the corpse: "// Don't 'optimize' this to a single query; it deadlocks under load (see #341)"
- Never comment out code as a way of disabling it "for now." Use a feature flag, config, or an explicit revert; commented-out code re-enables by copy-paste, untested
- When you encounter existing commented-out blocks in code you're editing, don't extend or mimic them. Flag them to the user as deletion candidates
- The exception: short illustrative snippets inside doc comments (usage examples in a docstring) are documentation, not dead code, and are fine

**Red flags that you're about to violate this:**
- "I'll keep the old version around just in case..."
- "Deleting it feels too destructive..."
- "It shows the reader what the code used to do..."
- "Someone might want to switch back..."
- "It's only commented out temporarily..."
- "Git history is hard to find; the comment is right here..."

---

## Why It Works

1. **It names the working archive.** Deletion anxiety persists because the model doesn't weigh version control. Stating "git remembers it perfectly, with author, date, and message" makes the comment block strictly inferior, not cautiously safe.

2. **It converts code-shaped history into reader-shaped history.** The questions future readers have — why changed, is the old way dangerous, can I delete this — are answered by one prose sentence and by zero lines of dead code.

3. **It distinguishes the warning use-case and serves it better.** "Rejected alternative" is the one legitimate instinct behind these blocks; documenting the rejection *reason* delivers that value, where the bare corpse delivers a trap.

4. **It blocks the disable-by-comment pattern.** Code disabled by commenting gets re-enabled by paste, months later, against a changed codebase, with no tests in between. Naming the safer mechanisms closes that path.

## Origin

A pricing module carried a sixty-line commented-out block headed "old discount logic" through four years and two team turnovers. During a margin investigation, an engineer concluded it was the intended logic that had been accidentally disabled, uncommented it, and shipped stacked discounts to a customer segment for a weekend. The original author, long gone, had replaced it on purpose for exactly that reason. One sentence saying so would have cost nothing; the dead code cost a weekend of revenue and an apology email.
