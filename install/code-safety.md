
### Ask Before Deleting Code

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



### Confirm Before Running Destructive Commands

NEVER run destructive or irreversible commands without stating what you're about to do and getting explicit approval.

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
2. Explain what it will do and what it will destroy
3. Wait for explicit "yes" or "go ahead"

**Safe alternatives to suggest first:**
- `rm` → move to a temp directory instead
- `git reset --hard` → `git stash` or `git reset --soft`
- `git push --force` → `git push --force-with-lease`
- Drop table → rename table with `_deprecated` suffix
- `kill -9` → `kill` (graceful) first

**Red flags that you're about to violate this:**
- "Let me just clean this up quickly..."
- "I'll reset this to a clean state..."
- "The fastest way to fix this is to force-push..."
- Running a command with `--force`, `--hard`, `-f`, or `rm` without pausing
