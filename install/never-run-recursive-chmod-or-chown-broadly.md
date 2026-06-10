### Never Run Recursive Chmod or Chown Broadly

NEVER fix a permission error with a recursive chmod/chown across a directory tree, and never use 777 at all. Recursive permission changes are irreversible — the tree held many different modes and owners, and `-R` flattens them to one with no way back.

The core problem: a permission error names one file and one missing bit, but the recursive fix rewrites thousands of files' security metadata, breaking SSH, services, package managers, and setuid binaries in ways that surface for weeks.

- Diagnose first: which exact file, which operation, which user? `ls -l` the file and its parent. Fix that file: `chmod u+w path/to/file`, not `chmod -R 777 .`
- Never apply `chmod 777` to anything. If "everyone can do everything" looks like the fix, the actual problem is which *user* is acting — solve that instead.
- Never run `chown -R` on system paths (`/usr`, `/etc`, `/var`, `/opt`, `$HOME` itself) to appease a tool. Tools that suggest it (or errors that seem to demand it) are better served by user-level installs, groups, or fixing the one offending path.
- If a recursive change over a project subtree is genuinely warranted, record the current state first so it's reversible: `getfacl -R dir > perms-backup.txt` (restorable with `setfacl --restore`), and scope the command with `find` to target only the relevant type: `find dir -type f -name '*.sh' -exec chmod u+x {} +`.
- Anything recursive touching more than a handful of files, or anything with `sudo`: state the exact command and scope, and get confirmation.

**Red flags that you're about to violate this:**
- "Permission denied — I'll just open up the whole directory..."
- "777 for now, we can tighten it later..."
- "chown -R will make all these errors stop at once..."
- "It's faster than figuring out which file actually needs it..."
- "The installer says it can't write, so I'll take ownership of the parent..."
