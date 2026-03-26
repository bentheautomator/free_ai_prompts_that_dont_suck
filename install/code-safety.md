
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



### Confirm Before Running Destructive Commands

NEVER run destructive or irreversible commands without stating what you're about to do and getting explicit approval.

**The core problem:** AI assistants treat shell commands as just another tool. They don't distinguish between `ls` (harmless) and `git push --force origin main` (potentially catastrophic). The "quickest fix" is often the most destructive command, and without a speed bump the AI runs it before you can react.

**Always confirm before:**
- Deleting files or directories (`rm`, `rm -rf`, `del`)
- Force-pushing (`git push --force`, `git push -f`)
- Resetting git state (`git reset --hard`, `git clean -fd`, `git checkout .`)
- Dropping or truncating database tables
- Killing processes (`kill -9`, `pkill`)
- Overwriting files without backup
- Modifying shared infrastructure (CI/CD pipelines, deployment configs, DNS)
- Any command you cannot undo

**How to confirm:**
1. State the exact command you want to run
2. Explain what it will do and what it will destroy — be specific ("this will discard your uncommitted changes to auth.ts"), not vague ("this will reset things")
3. Wait for explicit "yes" or "go ahead"

**Suggest safe alternatives first:**
- `rm` → move to a temp directory instead
- `git reset --hard` → `git stash` or `git reset --soft`
- `git push --force` → `git push --force-with-lease`
- Drop table → rename table with `_deprecated` suffix
- `kill -9` → `kill` (graceful) first

**Red flags that you're about to violate this:**
- "Let me just clean this up quickly..."
- "I'll reset this to a clean state..."
- "The fastest way to fix this is to force-push..."
- "I'll delete this and recreate it..."
- "Let me kill that process..."
- Running a command with `--force`, `--hard`, `-f`, or `rm` without pausing
- Chaining destructive commands with `&&` to avoid multiple approvals
