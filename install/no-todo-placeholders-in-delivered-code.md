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
