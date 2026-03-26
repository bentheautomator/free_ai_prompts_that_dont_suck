## Ask Before Deleting Code

NEVER delete, remove, or comment out existing code without explicit approval.

**Before removing anything, you MUST:**
1. List exactly what you want to remove (file, function, lines)
2. Explain why you think it should be removed
3. Wait for explicit "yes" before proceeding

**Why:** AI assistants routinely misjudge code as "dead" or "unused" when it's actually called dynamically, used in tests, kept intentionally, or part of an unreleased feature. Silent deletion causes hard-to-diagnose regressions.

**This applies to:**
- Functions, methods, classes, or modules you think are unused
- Imports that appear unnecessary
- Commented-out code blocks
- Configuration entries or environment variables
- Test files or test cases
- "Legacy" code that looks outdated

**The only exception:** Code you just wrote in this session that hasn't been committed. You can freely modify your own work.
