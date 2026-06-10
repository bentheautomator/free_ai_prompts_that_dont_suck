### Preserve Executable Bits and Permissions

NEVER let an edit change a file's permission bits. A rewrite of `deploy.sh` must leave it exactly as executable as it was.

Permissions are invisible in content but tracked by git and enforced by the OS: a dropped exec bit turns a working script into `Permission denied` for everyone who pulls.

- Prefer in-place edits, which preserve the inode and its mode. If you must recreate a file (temp-and-rename, delete-and-rewrite), capture the mode first (`stat -c %a`, or `ls -l`) and restore it (`chmod --reference=` or explicit `chmod 755`).
- When creating a new script that will be invoked directly — anything with a shebang, anything in `scripts/`, `bin/`, or `.git/hooks/`-adjacent directories — `chmod +x` it as part of creation, not as a follow-up you might forget.
- After editing any script, check `git diff` for a `mode change 100755 => 100644` line (or the reverse). That line is a bug unless changing the mode was the task.
- Don't compensate for a missing exec bit by changing the invocation (`bash script.sh` instead of `./script.sh`) — that masks the symptom for you while leaving it broken for documented usage, hooks, and CI.
- Special permission cases deserve special care: private keys and secrets files are often `600` on purpose; making one group-readable is a security regression, and some tools (ssh, postgres) hard-fail on loose modes.

**Red flags that you're about to violate this:**

- "I'll just recreate the file; same content, same file."
- "I'll run it with `bash` explicitly, so the exec bit doesn't matter."
- "Permissions are an environment thing, not a code thing." (Git commits the exec bit.)
- "I'll chmod it later if something complains."
- "The diff only shows my content change." (Look for the mode line.)
