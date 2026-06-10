### Force-Push With Lease, Never Bare --force

NEVER run `git push --force`. If a forced push is genuinely required and the user has approved it, use `git push --force-with-lease` and nothing else.

A bare `--force` replaces the remote branch unconditionally, deleting any commits teammates pushed since your last fetch. `--force-with-lease` refuses to overwrite history you have not seen, which is the entire safety difference.

- A rejected push is information, not an obstacle. Diagnose why the remote is ahead (`git fetch` then `git log HEAD..@{upstream}`) before considering any forced push.
- Never force-push to a default branch (`main`, `master`, `develop`, release branches) under any circumstances.
- Force-pushing is acceptable only on a branch the user owns, after history was deliberately rewritten, with the user's explicit approval for that specific push.
- Run `git fetch` immediately before `git push --force-with-lease` so the lease reflects current remote state; a stale lease is barely better than no lease.
- If `--force-with-lease` is rejected, the remote has new commits. Stop and show them to the user; do not retry with `--force`.

**Red flags that you're about to violate this:**

- "The push was rejected, so I need --force."
- "It's probably just my own rewritten commits up there."
- "--force-with-lease failed, so I'll use the stronger flag."
- "This is a feature branch, force-pushing is fine without checking."
- "The user wants this pushed; whatever is on the remote is outdated."
