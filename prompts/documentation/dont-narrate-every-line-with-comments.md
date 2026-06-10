---
title: Don't Narrate Every Line With Comments
slug: dont-narrate-every-line-with-comments
category: documentation
tags: [universal, docs, comments]
works_with: all
severity: medium
one_liner: "Play-by-play comment spam on every line of generated code"
---

# Don't Narrate Every Line With Comments

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from carpet-bombing generated code with a comment per line like a cooking show host.

**[Copy-paste ready version](../../install/dont-narrate-every-line-with-comments.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI for a 30-line function and you frequently get 30 lines of code interleaved with 25 comments: `// Initialize the client`, `// Build the request`, `// Send the request`, `// Parse the response`, `// Return the data`. It reads like subtitles for people who can already hear. The function is now twice as long, the signal-to-noise ratio has cratered, and the one comment that actually mattered — if there was one — is buried in the laugh track.

This is a density problem distinct from comment *quality*. Even when individual comments are harmless, blanket narration imposes a real cost: reviewers must read twice as many lines, diffs double in size, and every future edit must either maintain the narration or leave it desynchronized. Codebases with narrated AI output develop a distinctive bloat that humans then have to strip out by hand.

Assistants narrate because they generate code top-to-bottom and comments function as a thinking-out-loud scaffold — useful to the generation process, useless to the reader. The scaffold gets shipped because nothing tells the model to remove it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Narrate Every Line With Comments

NEVER ship code where comments narrate the sequence of steps. Comments are exceptional annotations for surprising lines, not subtitles for ordinary ones.

The core problem: per-line narration doubles file length, buries the few comments that matter, and creates prose that must be maintained in lockstep with code forever.

Rules:
- Default comment count for generated code is zero. Add a comment only when a specific line would mislead or surprise a competent reader without one
- Never mark phases of a function with step comments (`// Step 1: validate input`). If a function has phases worth naming, extract named functions instead
- Never comment variable declarations, returns, imports, or straightforward conditionals
- If you used comments while drafting to organize your own thinking, delete them before presenting the code — scaffolding is not documentation
- A rough budget: in routine code, more than one comment per 15 lines means you are narrating
- When in doubt, ask: "would a reviewer learn anything from this comment that the line itself doesn't say?" If no, cut it

**Red flags that you're about to violate this:**
- "I'll comment each section so the structure is clear..."
- "Step comments will help the user follow my implementation..."
- "Generated code should be extra well-commented..."
- "These comments show my reasoning..."
- "It's a long function, so it needs comments throughout..."
- "Comments make the code beginner-friendly..."

---

## Why It Works

1. **It sets the default to zero.** Without an explicit baseline, the model treats "some comments" as safe and "many comments" as generous. A zero default with a surprise-based exception inverts the burden of proof per comment.

2. **It separates scaffold from artifact.** Naming the real cause — comments as a generation-time thinking aid — gives the model a concrete final step: delete the scaffolding, the way a human deletes their debug prints.

3. **It offers structure an outlet.** The urge behind `// Step 1` is real (the function has phases); redirecting it to extraction ("name the function, not the step") satisfies the urge without the noise.

4. **It quantifies "too many."** A measurable heuristic (one per ~15 lines in routine code) is checkable during generation; "don't over-comment" is not.

## Origin

A team measured why their AI-assisted PRs took longer to review than hand-written ones despite being functionally simpler. The biggest factor was raw line count: generated files ran 40 to 60 percent longer than equivalent human code, almost entirely from narration comments. Reviewers were reading every comment line in case one of them mattered. The team added a no-narration rule, files shrank back to normal size, and review times followed.
