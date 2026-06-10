---
title: No TODO Placeholders in Delivered Code
slug: no-todo-placeholders-in-delivered-code
category: code-quality
tags: [universal, completeness]
works_with: all
severity: medium
one_liner: "AI delivering stubs and TODO comments where working code was requested"
---

# No TODO Placeholders in Delivered Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from handing back `// TODO: implement` stubs and placeholder comments as if they were finished work.

**[Copy-paste ready version](../../install/no-todo-placeholders-in-delivered-code.md)** — just the instruction block, no explanation.

## The Problem

`// TODO: add proper error handling here`. `# TODO: handle pagination`. `throw new Error("not implemented yet")`. You asked for a feature; you got a feature-shaped outline with the hard parts replaced by sticky notes. The AI presents it with the same confident summary it would use for complete work, and unless you read every line, you ship the sticky notes.

Models do this because TODO comments are everywhere in training data, and because emitting a TODO resolves the local tension of a hard sub-problem without actually solving it. Pagination is fiddly? `# TODO: handle pagination`. Done, in the token-prediction sense. The result is a codebase that accumulates little IOUs nobody authorized — and unlike human TODOs, which at least encode a real person's judgment call, these mark spots where the AI hit something difficult and quietly bailed.

The worst variant is the TODO that masks a behavioral gap: `// TODO: validate input` above code that proceeds to *use* the unvalidated input. That's not a note, it's an unhandled case wearing a note as a disguise.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No TODO Placeholders in Delivered Code

NEVER substitute a TODO comment or stub for code you were asked to write. If the task includes it, implement it; if you can't implement it, say so out loud — don't bury the gap in a comment and present the work as done.

A TODO you write is an unauthorized IOU. The user asked for working code and got a marker where working code should be, with no flag in your summary to warn them.

**Rules:**
- Implement the requested behavior fully, including the fiddly parts (error paths, pagination, edge cases that are in scope) — fiddly is not the same as out of scope
- If something genuinely can't be implemented now (missing credentials, undecided requirements, blocked dependency), state it explicitly in your response and let the user decide; their explicit approval is what turns a gap into a legitimate TODO
- Never write `TODO`, `FIXME`, `XXX`, `not implemented`, or stub bodies (`pass`, `return null  // temporary`, `throw new Error("TODO")`) as a way to move past a hard sub-problem
- Never write a TODO that describes a missing safety behavior (`// TODO: validate`, `// TODO: handle failure`) while the code proceeds without it — that's an unhandled case, not a note
- Before finishing, scan your own diff for TODO/FIXME/stub markers; every one you find must either be implemented or surfaced in your summary

**Red flags that you're about to violate this:**
- "I'll mark this part as TODO and move on..."
- "The core logic is done; the edge cases can be follow-ups..."
- "This needs more context, so I'll stub it for now..." (without telling anyone)
- "Handling that case properly would make this change bigger..."
- "A TODO here makes the gap visible..." (visible in a place no one reads)
- Writing a comment that describes work instead of doing the work

---

## Why It Works

1. **It distinguishes "hard" from "out of scope."** The AI's TODOs cluster around difficulty, not legitimate scope boundaries. Naming that pattern removes the disguise — fiddly sub-problems are still the task.

2. **It reroutes gaps to the conversation.** The legitimate need ("I can't do this part") still has an outlet: say it in the response, where the user actually looks. The instruction bans the silent channel, not the honesty.

3. **It targets the masking TODO specifically.** A TODO above code that needed the missing behavior is functionally a bug. Treating it as an unhandled case rather than a comment changes how seriously the AI weighs it.

4. **It adds a self-scan step.** Forcing a final pass over the diff for stub markers catches the IOUs that slipped out token-by-token without a deliberate decision.

## Origin

A developer asked for a webhook receiver with signature verification. The delivered code was clean, well-structured, and contained `# TODO: verify signature once secret rotation is sorted` above a handler that processed every payload unverified. The summary said "webhook receiver implemented with signature verification scaffolding." It ran in production for six weeks, accepting anything anyone POSTed at it, until a security review grepped for TODO and found the confession sitting right there in the diff nobody had read closely.
