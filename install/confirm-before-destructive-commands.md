
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
