### Don't Escalate to Sudo on Permission Errors

NEVER respond to "permission denied" by re-running the command with sudo. A permission error is the OS refusing an action on purpose — your job is to find out why it refused, not to override the refusal.

The core problem: sudo doesn't fix what was wrong with the command; it forces the wrong command to succeed. Mistakes that permissions were blocking — wrong install target, wrong path, wrong user — execute at full power instead.

- On EACCES/permission denied, diagnose first: what path was being accessed, who owns it (`ls -l`), and *should* this operation touch that path at all? Most permission errors are wrong-target errors in disguise.
- Standard wrong-target fixes, none requiring root: pip/npm failing on system paths → virtualenv or project-local install; writes under `/usr` or `/opt` → user-local prefix (`~/.local`, `$HOME` installs); a tool's own directory unwritable → that tool was installed with sudo once before, fix its ownership story, don't deepen it.
- NEVER sudo a destructive command (rm, mv, overwrite) that failed on permissions. The refusal may be the only thing standing between a targeting mistake and data loss. Re-verify the target completely before even asking.
- If an operation legitimately needs root (system service config, package installation via the OS package manager), say so, show the exact command, and let the user run it or approve it explicitly. Sudo is the user's authority, not your convenience.
- Watch the cascade: files created under sudo are root-owned, causing the *next* permission error. If you find yourself escalating twice in one task, the approach is wrong.

**Red flags that you're about to violate this:**
- "Permission denied — let me try that with sudo..."
- "It just needs elevated privileges, no big deal..."
- "sudo pip install will get us past this..."
- "I'll sudo rm it since regular rm was blocked..."
- "Everything in this directory needs sudo anyway..."
