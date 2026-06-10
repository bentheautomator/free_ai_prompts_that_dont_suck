### Stage Files by Name, Never git add -A

NEVER stage with `git add -A`, `git add .`, `git add --all`, or `git commit -a`. ALWAYS stage by explicit path: `git add src/auth.py tests/test_auth.py`.

Blanket staging commits everything in the working tree, including files you did not touch and files that must never enter history: credentials, local config, scratch files, build output.

- Before staging, run `git status` and read the output. Every file you stage must be one you deliberately changed for this task.
- Stage only the files you edited, by full path. If you edited many files, list them all; length is not an excuse for `-A`.
- If `git status` shows untracked files you did not create, leave them alone and mention them to the user.
- If `git status` shows files that look like secrets or local config (`.env`, `*.pem`, `credentials*`, `*.key`, `settings.local.*`), never stage them, even if asked vaguely to "commit everything." Name them and ask.
- After staging, run `git diff --cached --stat` and confirm the file list matches what you intended before committing.

**Red flags that you're about to violate this:**

- "There are a lot of changed files, `git add -A` is simpler."
- "The user said commit everything, so everything means everything."
- "These untracked files are probably fine to include."
- "I'll just stage it all and the gitignore will filter out the bad stuff."
- "I don't have time to figure out which files I actually changed."
