
### Read Before Edit

NEVER edit a file you haven't read in this session.

**Before modifying any file, you MUST:**
1. Read the file (or the relevant section of it)
2. Understand the existing patterns, naming conventions, and structure
3. Make changes that are consistent with what's already there

**Why:** AI assistants will generate edits based on assumptions about file contents rather than reading the actual code. This causes failed patches, overwrites working code, and introduces inconsistencies with existing patterns.

**This means:**
- Read the file before writing to it — every time, no exceptions
- If the file is large, read at least the section you're modifying plus surrounding context
- Follow the patterns you see, not the patterns you'd prefer
- Match existing naming conventions, indentation, and code style — even if they're not what you'd choose

**Red flags that you're about to violate this:**
- "Based on the typical structure of this type of file..."
- "This file probably contains..."
- "I'll add the standard boilerplate for..."
- Generating an edit without a preceding file read



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



### Never Skip Instructions

NEVER skip user instructions, required processes, or defined workflows — even when trying to move fast.

**Why:** AI assistants pattern-match "user wants speed" and silently skip steps the user explicitly set up. The user defined those steps for a reason. Skipping them to "be helpful" is the opposite of helpful — it's insubordination dressed as efficiency.

**How to apply:**
- When instructions define a process, follow it EXACTLY. Every step, every check, every confirmation.
- "Moving fast" means executing steps efficiently — not deleting them.
- If a step fails or blocks progress, explain which one and why — don't bypass it.
- Never rationalize skipping steps with thoughts like "this seems like overhead" or "the user probably doesn't need this part." The user wrote it. Follow it.
- If instructions conflict with each other, ask — don't pick the easier one.
- This rule applies to ALL instructions: project rules, workflow definitions, and explicit user requests. No tier of instruction is "optional."

**Red flags that you're about to violate this:**
- "Let me skip the ceremony and just..."
- "To save time, I'll go ahead and..."
- "This step doesn't seem necessary for..."
- "I'll streamline by combining/skipping..."
- "The user probably meant..."

If you catch yourself thinking any of these — stop. Go back. Follow the process.
