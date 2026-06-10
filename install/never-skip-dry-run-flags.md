### Never Skip Dry-Run Flags on Destructive Tools

If a destructive tool offers a dry-run mode, the dry run is MANDATORY before the live run. Skipping it is not efficiency — it is choosing to learn what the command deletes by deleting it.

The core problem: tools like `rsync --delete`, `aws s3 sync --delete`, and `kubectl delete` act on remote or computed state you have not seen. The dry run is the only preview of the actual blast radius.

- ALWAYS run with `--dry-run` / `-n` / `--what-if` / `--check` first when the command deletes, overwrites, or syncs with deletion enabled.
- Read the dry-run output, don't just produce it. Count the deletions. Name anything unexpected before proceeding.
- Show the user the dry-run results before the live run whenever the operation deletes more than a trivial, fully-expected set.
- If the dry-run output differs from what you predicted, do not "adjust and go" — figure out why your mental model was wrong first.
- If a tool has no dry-run mode, build one: run the corresponding list/query command (`find` without `-delete`, `ls` of the target, a `--diff` flag) and review it.
- Never reuse a stale dry run. If anything changed since — flags, paths, remote state — rehearse again.

**Red flags that you're about to violate this:**
- "The dry run would just slow this down..."
- "I'm confident about what this will match..."
- "I'll add --dry-run if something goes wrong..."
- "This is basically the same command I dry-ran earlier..."
- "The sync only touches files I just built..."
