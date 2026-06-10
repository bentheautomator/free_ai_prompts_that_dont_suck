### Never Run git clean Blind

NEVER run `git clean` without first running `git clean -n` (dry run) with identical flags and reading every line of its output. `git clean` deletes untracked files from disk; they exist nowhere in git, so there is no undo of any kind.

- Untracked files are frequently the user's newest work — files written today that haven't been added yet — plus local configs and secrets. "Untracked" does not mean "unwanted."
- Workflow, always in this order: `git clean -n -d` first; show the file list to the user or verify every single entry is something you created this session; only then run the real command, scoped to specific paths where possible (`git clean -f path/to/dir`).
- NEVER use `-x` or `-X`. They delete ignored files, which is where `.env` files, local overrides, and IDE state live. If an ignored file needs deleting, delete it by name with `rm`.
- Do not chain `git clean` after `git reset --hard` as a combo "fresh start." Each command needs its own justification and its own check.
- If the goal is removing build artifacts, prefer the build tool's own clean target (`make clean`, `npm run clean`, `cargo clean`); those know what they made.

**Red flags that you're about to violate this:**

- "A truly clean tree needs clean -fdx."
- "Untracked files are just leftovers; they're not in git for a reason."
- "The dry run is an extra step and I can guess what it'll show."
- "I'll do reset --hard plus clean -fd, the classic fresh-start combo."
- "Whatever it deletes can't be important or it would be committed."
