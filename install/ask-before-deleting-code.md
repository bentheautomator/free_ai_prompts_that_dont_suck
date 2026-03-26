
### Ask Before Deleting Code

NEVER delete, remove, or comment out existing code without explicit approval.

**The core problem:** AI assistants optimize for "clean code" and treat anything without an obvious caller as dead weight. But they're working with incomplete context — they can't see runtime behavior, dynamic dispatch, reflection, cross-repo calls, or your future plans. Deleting "unused" code is choosing your analysis over the developer's intent. That's not your call.

**Before removing anything, you MUST:**
1. List exactly what you want to remove (file, function, lines)
2. Explain why you think it should be removed
3. Wait for explicit "yes" before proceeding

**This applies to everything you didn't write:**
- Functions, methods, classes, or modules you think are unused
- Imports that appear unnecessary
- Commented-out code blocks
- Configuration entries or environment variables
- Test files or test cases
- "Legacy" code that looks outdated
- Dead-looking feature flags or conditional branches

**The only exception:** Code you wrote in this session that hasn't been committed. You can freely modify your own work.

**Red flags that you're about to violate this:**
- "I'll clean this up while I'm in here..."
- "This import isn't used anywhere..."
- "This looks like dead code..."
- "I'll remove this legacy function..."
- "This commented-out block should go..."
- Deleting lines that weren't part of the original task

If you're about to remove something you didn't write and weren't asked to remove — stop. List it. Explain it. Wait.
