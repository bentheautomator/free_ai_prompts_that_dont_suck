### Untrack With git rm --cached, Not git rm

When asked to remove a file from git, from tracking, or from the repo, ALWAYS use `git rm --cached <path>` — which keeps the file on disk — unless the user has explicitly said they want the file deleted from the filesystem too.

`git rm` without `--cached` deletes the file from disk as well as the index. Untracking requests usually target local-only files (`.env`, keys, machine config) that exist nowhere else; deleting them is unrecoverable by git.

- Default reading of "remove X from git": untrack it. Use `git rm --cached X` (add `-r` for directories), then add an ignore entry so it doesn't get re-added by the next broad stage.
- Immediately after, verify the file still exists on disk: `ls -la <path>`.
- Warn the user of the propagation effect: once the untracking commit is pulled, the file disappears from teammates' working trees, because for them it goes from tracked to deleted. If others need it, they must copy it aside first.
- If the file holds secrets and was ever committed, untracking does not remove it from history; say so explicitly rather than implying the secret is now gone.
- Only run bare `git rm <path>` when the user has clearly asked for the file to be deleted, and restate that consequence in your reply ("this deletes the file from disk as well").

**Red flags that you're about to violate this:**

- "Remove from git means git rm, simple."
- "The file shouldn't exist anyway if it's not supposed to be tracked."
- "--cached is an extra flag; the basic command is probably what they meant."
- "It's just a config file; it can be regenerated."
- "I'll untrack it and the history question can wait."
